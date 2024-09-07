CH_DAT:	    .EQU	$70		; CH376 Data Port
CH_CMD:	    .EQU	$71		; CH376 Command Port

BNKSEL:	    .EQU	$64		; Bank Sel register in PicoROM

            .ORG  $A000

Start_RomWBW:
            LD  HL,Load_RomWBW
            LD  (Loader),HL
            JP  AppStrt

            .ORG  $A010
Start_Cpm:
            LD  HL,Load_Cpm
            LD  (Loader),HL
            JP  AppStrt

AppStrt:   
            LD   DE,szStartup       ;message
            call OutputZString
            JP   CH_Reset

Load_Cpm:
            ld   a, $00
            call Bnk_Sel
            LD   DE,szCpmBin
            call CH_OpenFile
            JP  Exit

Load_RomWBW:
            ld   a, $00
            call Bnk_Sel
            LD   DE,szBootBin0
            call CH_OpenFile

            ld   a, $01
            call Bnk_Sel
            LD   DE,szBootBin1
            call CH_OpenFile

            ld   a, $02
            call Bnk_Sel
            LD   DE,szBootBin2
            call CH_OpenFile

            ld   a, $03
            call Bnk_Sel
            LD   DE,szBootBin3
            call CH_OpenFile

            ld   a, $04
            call Bnk_Sel
            LD   DE,szBootBin4
            call CH_OpenFile

            ld   a, $05
            call Bnk_Sel
            LD   DE,szBootBin5
            call CH_OpenFile

            ld   a, $06
            call Bnk_Sel
            LD   DE,szBootBin6
            call CH_OpenFile

            ld   a, $07
            call Bnk_Sel
            LD   DE,szBootBin7
            call CH_OpenFile

            ld   a, $00
            call Bnk_Sel
            jp   Exit


Exit:
            LD   DE,szExit          ;message
            call OutputZString

            JP   $0000
            ret

Bnk_Sel:
            ld   bc, BNKSEL
            out  (c),a
            ret

CH_Reset:
            ld   a, RESET_ALL
            call CH_Send_Cmd        ; send
            call CH_Busy_Wait

            call CH_Exists

CH_Host_Mode:
            ld   a, SET_USB_MODE
            call CH_Send_Cmd        ; send
            ld   a, 6
            call CH_Send_Data
            call CH_Busy_Wait
            call CH_Read_Data
            cp   CMD_RET_SUCCESS
            jr   z, CH_Disk_Conect
            JP   Exit


CH_Disk_Conect:
            ld   a, DISK_CONNECT
            call CH_Send_Cmd        ; send
            call CH_Chk_Success
            jr   z, CH_Disk_Mount
            LD   DE,szErrDisk
            call OutputZString      ; Output message at DE
            JP   Exit

CH_Disk_Mount:
        	ld   a, DISK_MOUNT
            call CH_Send_Cmd        ; send
            call CH_Chk_Success
            jp   z, LoadEmup
            LD   DE,szErrDisk
            call OutputZString      ; Output message at DE
            JP   Exit

LoadEmup:
            LD   HL,(Loader)
            JP   (HL)
            HALT

CH_OpenFile:
        	ld   a, SET_FILE_NAME
            call CH_Send_Cmd        ; send
CH_OpenFile1:
            LD   A,(DE)             ; Get character from string
            call CH_Send_Data       ; Send char (inc NULL)
            INC  DE                 ; Point to next character
            OR   A                  ; Null terminator?
            JR   Z,CH_OpenFile2     ; Yes, so we've finished
            JR   CH_OpenFile1       ; Go process next character
CH_OpenFile2:
        	ld   a, FILE_OPEN
            call CH_Send_Cmd        ; send
            call CH_Chk_Success
            jr   z, CH_Read_File
            LD   DE,szErrFile
            call OutputZString      ; Output message at DE
            RET

CH_Read_File:
        	ld hl, $0000            ; We're reading to 0000

            ld a, BYTE_READ
            call CH_Send_Cmd
            ld a, 255               ; Request all of the file
            call CH_Send_Data
            ld a, 255               ; Yes, all!
            call CH_Send_Data

CH_Read_Chunk:
            call CH_Chk_Success     ; USB_INT_SUCCESS here means the file is finished
            jr   z, CH_CloseFile    ; We could check for USB_INT_DISK_READ here?

            ld a, RD_USB_DATA0
            call CH_Send_Cmd
            call CH_Read_Data       ; A = Length of chunk

            ld b, a                 ; number of bytes in B
            ld c, CH_DAT            ; Port to read from 
            inir                    ; A rare use of In, Increase & Repeat!!!

        	ld a, BYTE_RD_GO        ; Next chunk please
            call CH_Send_Cmd
            jr   CH_Read_Chunk

CH_CloseFile:
            ld a, FILE_CLOSE
            call CH_Send_Cmd
            ld a, 0                 ; 0 = dont update file size (should be read-only)
            call CH_Send_Data
            call CH_Chk_Success     ; Do we care?
            ret
            
CH_Exists:
            LD   A,GET_IC_VER       ; Get Ver
            call CH_Send_Cmd        ; send
            call CH_Read_Data

            LD   A,CHECK_EXIST      ; CHK
            call CH_Send_Cmd        ; send
            LD   A,$03              ; data
            call CH_Send_Data
            call CH_Read_Data
            ret

CH_Busy_Wait:
            IN   A,(CH_CMD)         ; read
            BIT  CHBZ,A             ; Busy?
            JR   NZ,CH_Busy_Wait
            ret

CH_Chk_Success:
            call CH_Busy_Wait
            ld   a, GET_STATUS
            OUT  (CH_CMD),A         ; send
            ; ld   a, '?'
            ; call OutputChar
            IN   A,(CH_DAT)         ; read
            ; call PrintHexByte
            cp   USB_INT_SUCCESS
            ret

CH_Send_Cmd:
            ; push DE
            ; LD   DE,szNL            ; New Line
            ; call OutputZString      ; Output message at DE
            ; call PrintHexByte
            OUT (CH_CMD),A          ; send
            ; pop DE
            ret

CH_Send_Data:
            ; call PrintHexByte
            OUT  (CH_DAT),A         ; send
            ret

CH_Read_Data:
            call CH_Busy_Wait
            IN   A,(CH_DAT)         ; read
            ; call PrintHexByte
            ret

; Write hex byte
;   On entry: A = Hex byte
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
PrintHexByte:
            PUSH AF
            RRA                 ; Shift top nibble to
            RRA                 ;  botom four bits..
            RRA
            RRA
            call PrintHexNibble
            POP  AF
            call PrintHexNibble
            RET


; Write hex nibble
;   On entry: A = Hex nibble
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
PrintHexNibble:
            PUSH AF
            AND  $0F           ;Mask off nibble
            CP   $0A           ;Nibble > 10 ?
            JR   C,Skip        ;No, so skip
            ADD  A,7           ;Yes, so add 7
Skip:       ADD  A,$30         ;Add ASCII '0'
            call OutputChar    ;Write character
            POP  AF
            RET

; Write char to console
;   On entry: A = Char to output
OutputChar:
            push bc
            push hl
            LD   C,2                ;API 6
            call $8030             ;  = Output message at DE
            pop  hl
            pop  bc
            ret

; Write string to console
;   On entry: DE = Null Terminated String
OutputZString:
            push bc
            push hl
            LD   C,6                ;API 6
            call $8030             ;  = Output message at DE
            pop  hl
            pop  bc
            ret

            HALT

CHBZ:       .EQU 4              ;CH376 Busy Flag

Loader:     .DW 0               ; The routine to call after initialising CH376

szNL:       .DB 13,10,0
szStartup:  .DB "RomWbW Loading...",13,10,0
szExit:     .DB "Finished",13,10,0
szErrDisk:  .DB "Disk?",13,10,0
szErrFile:  .DB "File?",13,10,0
szBootBin0: .DB "/ROMWBW0.BIN",0
szBootBin1: .DB "/ROMWBW1.BIN",0
szBootBin2: .DB "/ROMWBW2.BIN",0
szBootBin3: .DB "/ROMWBW3.BIN",0
szBootBin4: .DB "/ROMWBW4.BIN",0
szBootBin5: .DB "/ROMWBW5.BIN",0
szBootBin6: .DB "/ROMWBW6.BIN",0
szBootBin7: .DB "/ROMWBW7.BIN",0
szCpmBin:   .DB "/CPM.BIN",0

GET_IC_VER: .equ $01
SET_BAUDRATE: .equ $02
RESET_ALL: .equ $05
CHECK_EXIST: .equ $06
GET_FILE_SIZE: .equ $0C
SET_USB_MODE: .equ $15
GET_STATUS: .equ $22
RD_USB_DATA0: .equ $27
WR_USB_DATA: .equ $2C
WR_REQ_DATA: .equ $2D
WR_OFS_DATA: .equ $2E
SET_FILE_NAME: .equ $2F
DISK_CONNECT: .equ $30
DISK_MOUNT: .equ $31
FILE_OPEN: .equ $32
FILE_ENUM_GO: .equ $33
FILE_CREATE: .equ $34
FILE_ERASE: .equ $35
FILE_CLOSE: .equ $36
DIR_INFO_READ: .equ $37
DIR_INFO_SAVE: .equ $38
BYTE_LOCATE: .equ $39
BYTE_READ: .equ $3A
BYTE_RD_GO: .equ $3B
BYTE_WRITE: .equ $3C
BYTE_WR_GO: .equ $3D
DISK_CAPACITY: .equ $3E
DISK_QUERY: .equ $3F
DIR_CREATE: .equ $40


; Statuses
USB_INT_SUCCESS: .equ $14
USB_INT_CONNECT: .equ $15
USB_INT_DISCONNECT: .equ $16
USB_INT_BUF_OVER: .equ $17
USB_INT_USB_READY: .equ $18
USB_INT_DISK_READ: .equ $1D
USB_INT_DISK_WRITE: .equ $1E
USB_INT_DISK_ERR: .equ $1F
YES_OPEN_DIR: .equ $41
ERR_MISS_FILE: .equ $42
ERR_FOUND_NAME: .equ $43
CMD_RET_SUCCESS: .equ $51
ERR_DISK_DISCON: .equ $82
ERR_LARGE_SECTOR: .equ $84
ERR_TYPE_ERROR: .equ $92
ERR_BPB_ERROR: .equ $A1
ERR_DISK_FULL: .equ $B1
ERR_FDT_OVER: .equ $B2
ERR_FILE_CLOSE: .equ $B4
THE_END:
            .END


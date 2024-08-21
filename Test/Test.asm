
PIO_A:	    .EQU	$74		; CA80 user 8255 base address 	  (port A)
PIO_B:	    .EQU	$75		; CA80 user 8255 base address + 1 (port B)
PIO_C:	    .EQU	$76		; CA80 user 8255 base address + 2 (port C)
PIO_M:	    .EQU	$77		; CA80 user 8255 control register
PIO_CFG:	.EQU	$82	    ; Active, Mode 0, A & C Outputs. B Left as Input

kSIOAConT3: .EQU    $61     ; I/O address of control register A
kSIOADatT3: .EQU    $60     ; I/O address of data register A
kSIOBConT3: .EQU    $63     ; I/O address of control register B
kSIOBDatT3: .EQU    $62     ; I/O address of data register B

CH_DAT:	    .EQU	$70		; CH376 Data Port
CH_CMD:	    .EQU	$71		; CH376 Command Port

BNKSEL:	    .EQU	$64		; Bank Sel register in PicoROM

            .ORG  $0000

ColdStrt:   DI                  ; Disable interrupts
            LD   SP, $FFFF      ; Initialise system stack pointer
            LD   A,PIO_CFG 		; 
            OUT  (PIO_M),A		; Configure PIO
            LD   A,$00  		; Ensure we're in bank 0
            LD   C,BNKSEL       ; 
            OUT  (C),A		    ; don't use out (nn),a as upper bits aren't 0

            LD   C,kSIOAConT3   ;SIO/2 channel A control port
            call RC2014_SerialSIO2_IniSend
            LD   C,kSIOBConT3   ;SIO/2 channel B control port
            call RC2014_SerialSIO2_IniSend

Loop:
            LD   A,$08              ; flash
            OUT  (PIO_C),A		    ; Set port A 
            call medium_delay
            LD   A,$00              ; all off
            OUT  (PIO_C),A		    ; Set port A 
            call medium_delay

            LD   DE,szStartup
            call OutputZString      ; Output message at DE

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
            JP   Loop


CH_Disk_Conect:
            ld   a, DISK_CONNECT
            call CH_Send_Cmd        ; send
            call CH_Chk_Success
            jr   z, CH_Disk_Mount
            LD   DE,szErrDisk
            call OutputZString      ; Output message at DE
            JP   Loop

CH_Disk_Mount:
        	ld   a, DISK_MOUNT
            call CH_Send_Cmd        ; send
            call CH_Chk_Success
            jr   z, CH_OpenFile
            LD   DE,szErrDisk
            call OutputZString      ; Output message at DE
            JP   Loop

CH_OpenFile:
        	ld   a, SET_FILE_NAME
            call CH_Send_Cmd        ; send
            LD   DE,szBootBin
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
            JP   Loop

CH_Read_File:
        	ld hl, $8000            ; We're reading to bottom of RAM

            ld a, BYTE_READ
            call CH_Send_Cmd
            ld a, 255               ; Request all of the file
            call CH_Send_Data
            ld a, 255               ; Yes, all!
            call CH_Send_Data

CH_Read_Chunk:
            call CH_Chk_Success     ; USB_INT_SUCCESS here means the file is finished
            jr   z, CH_CloseFile    ; We could check for USB_INT_DISK_READ here?

            ld   a, '.'
            call OutputChar_T3

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
            call CH_Chk_Success
            jP   nz, Loop           ; Do we care?

;             LD   DE,szNL            ; New Line
;             call OutputZString      ; Output message at DE
;             LD   HL, $8000
;             LD   b, 16
; Prloop:            
;             LD   a,(HL)
;             CALL PrintHexByte
;             inc  HL
;             djnz Prloop

            JP   $8000              ; Boot, baby!

; Hang_Around:
;             LD   A,$0F              ; flash
;             OUT  (PIO_C),A		    ; Set port A 
;             call medium_delay
;             LD   A,$00              ; all off
;             OUT  (PIO_C),A		    ; Set port A 
;             call medium_delay

;             JP   Hang_Around

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
            ; call OutputChar_T3
            IN   A,(CH_DAT)         ; read
            ; call PrintHexByte
            cp   USB_INT_SUCCESS
            ret

CH_Send_Cmd:
            ; LD   DE,szNL            ; New Line
            ; call OutputZString      ; Output message at DE
            ; call PrintHexByte
            OUT (CH_CMD),A          ; send
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


; RC2014 serial SIO/2 write initialisation data 
;   On entry: C = Address of SIO control register
;   On exit:  DE IX IY I AF' BC' DE' HL' preserved
; Send initialisation data to specied control register
RC2014_SerialSIO2_IniSend:
            LD   HL,SIOIni     ;Point to initialisation data
            LD   B,SIOIniEnd-SIOIni ;Length of ini data
            OTIR                ;Write data to output port C
            XOR  A              ;Return Z flag as device found
            RET
; SIO channel initialisation data
SIOIni:    .DB  %00011000     ; Wr0 Channel reset
;           .DB  %00000010     ; Wr0 Pointer R2
;           .DB $00           ; Wr2 Int vector
            .DB  %00010100     ; Wr0 Pointer R4 + reset ex st int
            .DB  %01000100     ; Wr4 /16, async mode, no parity
            .DB  %00000011     ; Wr0 Pointer R3
            .DB  %11000001     ; Wr3 Receive enable, 8 bit 
            .DB  %00000101     ; Wr0 Pointer R5
;           .DB  %01101000     ; Wr5 Transmit enable, 8 bit 
            .DB  %11101010     ; Wr5 Transmit enable, 8 bit, flow ctrl
            .DB  %00010001     ; Wr0 Pointer R1 + reset ex st int
            .DB  %00000000     ; Wr1 No Tx interrupts
SIOIniEnd:

; Lottery type 3 serial SIO/2 channel A & B output character
;   On entry: A = Character to be output to the device
;   On exit:  NZ flagged and A != 0
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
OutputChar_T3:
            PUSH BC
Wait1:      LD   C,kSIOAConT3   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            JR   Z,Wait1
            POP  BC
            OUT  (kSIOADatT3),A ;Write data byte
            OR   $FF           ;Return success A=0xFF and NZ flagged
            RET


; Console output: Output a zero (null) terminated string
;   On entry: DE= Start address of string
;   On exit:  DE= Address after null
;             AF BC HL IX IY I AF' BC' DE' HL' preserved
;             Interrupts enabled during this call
; Supports \n for new line
OutputZString:
            PUSH AF
Next:       LD   A,(DE)         ;Get character from string
            INC  DE             ;Point to next character
            OR   A              ;Null terminator?
            JR   Z,Finished     ;Yes, so we've finished
            call OutputChar_T3  ;Output character
            JR   Next           ;Go process next character
Finished:   POP  AF
            RET

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
            ADD  A,7            ;Yes, so add 7
Skip:       ADD  A,$30         ;Add ASCII '0'
            call OutputChar_T3  ;Write character
            POP  AF
            RET

long_delay:
	        ld   bc, 65000
	        jr   delay
medium_delay:
	        ld   bc, 45000
	        jr   delay
short_delay:
	        ld   bc, 200
; INPUT: Loop count in BC
delay:
            NOP
            DEC  BC
            LD   A,B
            OR   C
            JR   NZ,delay
            RET

            HALT


kSIOTxRdy:  .EQU 2              ;Transmit data empty bit number
CHBZ:       .EQU 4              ;CH376 Busy Flag

szNL:       .DB 13,10,0
szStartup:  .DB 13,10,"Z80-Lottery",13,10,0
szErrDisk:  .DB "Disk?",13,10,0
szErrFile:  .DB "File?",13,10,0
szBootBin:  .DB "/BOOT.BIN",0

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
            .FILL $200-THE_END
            .END


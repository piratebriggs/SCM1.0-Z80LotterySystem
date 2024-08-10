
PIO_A:	.EQU	$74		; CA80 user 8255 base address 	  (port A)
PIO_B:	.EQU	$75		; CA80 user 8255 base address + 1 (port B)
PIO_C:	.EQU	$76		; CA80 user 8255 base address + 2 (port C)
PIO_M:	.EQU	$77		; CA80 user 8255 control register
PIO_CFG:	.EQU	$82	; Active, Mode 0, A & C Outputs. B Left as Input

kSIOAConT3: .EQU $61        ;I/O address of control register A
kSIOADatT3: .EQU $60        ;I/O address of data register A
kSIOBConT3: .EQU $63        ;I/O address of control register B
kSIOBDatT3: .EQU $62        ;I/O address of data register B

CH_DAT:	.EQU	$70		; CH376 Data Port
CH_CMD:	.EQU	$71		; CH376 Command Port

            .ORG  $0000

ColdStrt:   DI                  ;Disable interrupts
            LD   SP, $FFFF     ;Initialise system stack pointer
            LD A,PIO_CFG 		; 
            OUT (PIO_M),A		; 

            LD   C,kSIOAConT3   ;SIO/2 channel A control port
            CALL RC2014_SerialSIO2_IniSend
            LD   C,kSIOBConT3   ;SIO/2 channel B control port
            CALL RC2014_SerialSIO2_IniSend

Loop:
           LD   DE,szStartup   ;="Devices:"
           CALL OutputZString  ;Output message at DE

            ; LD A,$01           ; Get Ver
            ; OUT (CH_CMD),A      ; send
            ; IN A,(CH_DAT)       ; read
            ; CALL PRINT8

            ; LD A,$06           ; CHK
            ; OUT (CH_CMD),A      ; send
            ; LD A,$A5           ; data
            ; OUT (CH_CMD),A      ; send
            ; IN A,(CH_DAT)       ; read
            ; CALL PRINT8

            LD A,$01           ; bit 5
            OUT (PIO_C),A		; Set port A 
            LD BC,$6666   ; short second delay
            CALL DELAY

            LD A,$02           ; all off
            OUT (PIO_C),A		; Set port A 
            LD BC,$FFFF   ; long second delay
            CALL DELAY

            LD A,$04           ; bit 1+5
            OUT (PIO_C),A		; Set port A 
            LD BC,$6666   ; short second delay
            CALL DELAY

            LD A,$08           ; all off
            OUT (PIO_C),A		; Set port A 
            LD BC,$FFFF   ; long second delay
            CALL DELAY

            LD A,$00           ; all off
            OUT (PIO_C),A		; Set port A 
            LD BC,$FFFF   ; long second delay
            CALL DELAY

            JP Loop

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
;   On exit:  If character output successful (eg. device was ready)
;               NZ flagged and A != 0
;             If character output failed (eg. device busy)
;               Z flagged and A = Character to output
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
OutputChar_T3:
            PUSH BC
            LD   C,kSIOAConT3   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            POP  BC
            RET  Z              ;Return Z as character not output
            OUT  (kSIOADatT3),A ;Write data byte
            OR   $FF           ;Return success A=0xFF and NZ flagged
            RET

; Console output: Output character to console output device
;   On entry: A = Character to output
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
; This is the only place the actual new line codes (eg. CR/LF) are used
OutputChar:
            PUSH AF
            CP   kNewLine       ;New line character?
            JR   NZ,NotNL      ;No, so skip
            LD   A,kReturn      ;Yes, so output physical new line
Wait1:     CALL OutputChar_T3       ;  to console..
            JR   Z,Wait1
            LD   A,kLinefeed
NotNL:
Wait2:     CALL OutputChar_T3       ;Output character to console
            JR   Z,Wait2
Exit:      POP  AF
            RET

; Console output: Output a zero (null) terminated string
;   On entry: DE= Start address of string
;   On exit:  DE= Address after null
;             AF BC HL IX IY I AF' BC' DE' HL' preserved
;             Interrupts enabled during this call
; Supports \n for new line
OutputZString:
            PUSH AF
Next:      LD   A,(DE)         ;Get character from string
            INC  DE             ;Point to next character
            OR   A              ;Null terminator?
            JR   Z,Finished    ;Yes, so we've finished
            CALL OutputChar     ;Output character
            JR   Next          ;Go process next character
Finished:  POP  AF
            RET

PRINT8:
            OUT (PIO_C),A		; Write low nibble
            PUSH AF

            LD BC,$6666         ; short second delay
            CALL DELAY
            LD  A,$00          
            OUT (PIO_C),A		; all off
            LD BC,$6666         ; short second delay
            CALL DELAY
            POP AF
            RRA
            RRA
            RRA
            RRA
            OUT (PIO_C),A		; write high nibble
            LD BC,$FFFF         ; long second delay
            CALL DELAY
            OUT (PIO_C),A		; all off
            LD BC,$6666         ; short second delay
            CALL DELAY
            RET

; INPUT: Loop count in BC
DELAY:
            NOP
            DEC BC
            LD A,B
            OR C
            JR NZ,DELAY
            RET


            HALT

kNull       .EQU 0              ;Null character/byte (0x00)
kNewLine    .EQU 5              ;New line character (0x05)
kLinefeed:  .EQU 10             ;Line feed character (0x0A)
kReturn:    .EQU 13             ;Return character (0x0D)

kSIOTxRdy:  .EQU 2              ;Transmit data empty bit number

szStartup:  .DB "Z80-Lottery",kNewLine,0

               .END


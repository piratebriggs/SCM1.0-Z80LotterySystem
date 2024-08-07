            .PROC Z80           ;<SCC> SCWorkshop select processor
            .HEXBYTES 0x18      ;<SCC> SCWorkshop Intel Hex output format

PIO_A:	.EQU	0x74		; CA80 user 8255 base address 	  (port A)
PIO_B:	.EQU	0x75		; CA80 user 8255 base address + 1 (port B)
PIO_C:	.EQU	0x76		; CA80 user 8255 base address + 2 (port C)
PIO_M:	.EQU	0x77		; CA80 user 8255 control register
PIO_CFG:	.EQU	0x82	; Active, Mode 0, A & C Outputs. B Left as Input

kSIOAConT3: .EQU 0x61        ;I/O address of control register A
kSIOADatT3: .EQU 0x60        ;I/O address of data register A
kSIOBConT3: .EQU 0x63        ;I/O address of control register B
kSIOBDatT3: .EQU 0x62        ;I/O address of data register B

CH_DAT:	.EQU	0x70		; CH376 Data Port
CH_CMD:	.EQU	0x71		; CH376 Command Port

            .CODE
            .ORG  0x0000

ColdStrt:   DI                  ;Disable interrupts
            LD   SP, 0xFFFF     ;Initialise system stack pointer
            LD A,PIO_CFG 		; 
            OUT (PIO_M),A		; 

Loop:

            LD A,0x01           ; Get Ver
            OUT (CH_CMD),A      ; send
            IN A,(CH_DAT)       ; read
            CALL PRINT8

            LD A,0x06           ; CHK
            OUT (CH_CMD),A      ; send
            LD A,0xA5           ; data
            OUT (CH_CMD),A      ; send
            IN A,(CH_DAT)       ; read
            CALL PRINT8

            LD A,0x01           ; bit 5
            OUT (PIO_C),A		; Set port A 
            LD BC,$6666   ; short second delay
            CALL DELAY

            LD A,0x02           ; all off
            OUT (PIO_C),A		; Set port A 
            LD BC,$FFFF   ; long second delay
            CALL DELAY

            LD A,0x04           ; bit 1+5
            OUT (PIO_C),A		; Set port A 
            LD BC,$6666   ; short second delay
            CALL DELAY

            LD A,0x08           ; all off
            OUT (PIO_C),A		; Set port A 
            LD BC,$FFFF   ; long second delay
            CALL DELAY

            LD A,0x00           ; all off
            OUT (PIO_C),A		; Set port A 
            LD BC,$FFFF   ; long second delay
            CALL DELAY

            JP Loop

PRINT8:
            OUT (PIO_C),A		; Write low nibble
            PUSH AF

            LD BC,$6666         ; short second delay
            CALL DELAY
            LD  A,0x00          
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

szStartup:  .DB "Z80-Lottery",0

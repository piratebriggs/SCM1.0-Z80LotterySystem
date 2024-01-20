            .PROC Z80           ;<SCC> SCWorkshop select processor
            .HEXBYTES 0x18      ;<SCC> SCWorkshop Intel Hex output format

PIO_A:	.EQU	0x14		; CA80 user 8255 base address 	  (port A)
PIO_B:	.EQU	0x15		; CA80 user 8255 base address + 1 (port B)
PIO_C:	.EQU	0x16		; CA80 user 8255 base address + 2 (fport C)
PIO_M:	.EQU	0x17		; CA80 user 8255 control register
PIO_CFG:	.EQU	0x80	; Active, Mode 0, A & B & C Outputs

            .CODE
            .ORG  0x0000

ColdStrt:   DI                  ;Disable interrupts
            LD   SP, 0xFFFF     ;Initialise system stack pointer

            LD A,PIO_CFG 		; 
            OUT (PIO_M),A		; 

Loop:
            LD A,0x00           ; all off
            OUT (PIO_A),A		; Set port A 

            LD BC,$6666   ;1~ second delay
DELAY1:
            NOP
            DEC BC
            LD A,B
            OR C
            JR NZ,DELAY1

            LD A,0x10           ; bit 5
            OUT (PIO_A),A		; Set port A 

            LD BC,$6666   ;1~ second delay
DELAY2:
            NOP
            DEC BC
            LD A,B
            OR C
            JR NZ,DELAY2

            JR Loop

            HALT

szStartup:  .DB "Z80-Lottery",0

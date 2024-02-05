            .PROC Z80           ;<SCC> SCWorkshop select processor
            .HEXBYTES 0x18      ;<SCC> SCWorkshop Intel Hex output format

PIO_A:	.EQU	0x74		; CA80 user 8255 base address 	  (port A)
PIO_B:	.EQU	0x75		; CA80 user 8255 base address + 1 (port B)
PIO_C:	.EQU	0x76		; CA80 user 8255 base address + 2 (fport C)
PIO_M:	.EQU	0x77		; CA80 user 8255 control register
PIO_CFG:	.EQU	0x80	; Active, Mode 0, A & B & C Outputs

kSIOAConT3: .EQU 0x61        ;I/O address of control register A
kSIOADatT3: .EQU 0x60        ;I/O address of data register A
kSIOBConT3: .EQU 0x63        ;I/O address of control register B
kSIOBDatT3: .EQU 0x62        ;I/O address of data register B


            .CODE
            .ORG  0x8000

Loop:
            LD A,0x10           ; bit 5
            OUT (PIO_B),A		; Set port A 
            LD BC,$6666   ; short second delay
            CALL DELAY

            LD A,0x00           ; all off
            OUT (PIO_B),A		; Set port A 
            LD BC,$FFFF   ; long second delay
            CALL DELAY

            JP Loop


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

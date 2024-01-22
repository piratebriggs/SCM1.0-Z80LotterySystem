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
            .ORG  0x0000

ColdStrt:   DI                  ;Disable interrupts
            LD   SP, 0xFFFF     ;Initialise system stack pointer

            LD A,PIO_CFG 		; 
            OUT (PIO_M),A		; 

Loop:
            LD A,0x00           ; all off
            OUT (PIO_B),A		; Set port A 

A_RTS_OFF:
            LD A,0x05 ;write into WR0: select WR5
            OUT (kSIOAConT3),A
            LD A,0xE8 ;
            OUT (kSIOAConT3),A
B_RTS_ON:
            LD A,0x05 ;write into WR0: select WR5
            OUT (kSIOBConT3),A
            LD A,0xEA ;
            OUT (kSIOBConT3),A


            LD BC,$FFFF   ;1~ second delay
            CALL DELAY

BIT5_ON:
            LD A,0x10           ; bit 5
            OUT (PIO_B),A		; Set port A 

A_RTS_ON:
            LD A,0x05 ;write into WR0: select WR5
            OUT (kSIOAConT3),A
            LD A,0xEA ;
            OUT (kSIOAConT3),A
B_RTS_OFF:
            LD A,0x05 ;write into WR0: select WR5
            OUT (kSIOBConT3),A
            LD A,0xE8 ;
            OUT (kSIOBConT3),A

            LD BC,$6666   ;~0.3 second delay
            CALL DELAY
            
            JR Loop

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

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

ColdStrt:   DI                  ;Disable interrupts
            LD   SP, 0xFFFF     ;Initialise system stack pointer
            ; Need to do this in RAM or else we can't boot from bank F0
            ; Copy the code to a high ish address (0xA00)  so it can run from ROM or RAM
            LD A,PIO_CFG 		; 
            OUT (PIO_M),A		; 

    LD A, 0x85
    BIT	7,A			; BIT 7 SET REQUESTS RAM PAGE
	JR	Z,HBX_ROM		; NOT SET, SELECT ROM PAGE
	RES	7,A			; RAM PAGE REQUESTED: CLEAR ROM BIT
	RLA				; Rotate left 4 times
	RLA
	RLA
	RLA
    RET
HBX_ROM:
	RET				; DONE

 	xor a
loopy:
	xor 10000000B	;PA7 = beeper
	out (PIO_A),a		;Port 0x14 = Port A
	ld bc,30000	;Lower number=higher pitch
pausey:
	dec c
	jr nz,pausey
	dec b
	jr nz,pausey		
	jr loopy



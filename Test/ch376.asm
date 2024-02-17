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

        LD c,0x16

        ld a,0xc0
        out (0x17),a  ; Mode
        ld a,0x80
        out (0x15),a  ; CS#=1
        ld a,7
        out (c),a  ; 1, 1, 1
        ld a,00
        out (0x15),a  ; CS#=0

        ld a,06
        out (0x14),a  ; data=06
        ld a,7
        out (c),a  ; a0=1
        ld a,6
        out (c),a  ; wr#=0
        ld a,7
        out (c),a  ; wr#=1

        ld a,0x55
        out (0x14),a  ; data = 55
        ld a,3
        out (c),a  ; a0=0
        ld a,2
        out (c),a  ; wr = 0
        ld a,3
        out (c),a  ; wr = 1

        ld a,1
        out (c),a  ; rd = 0
        ld a,3
        out (c),a  ; rd = 1
        in a,(0x14)
        ld hl,0x8100
        ld (hl),a

        ld a,06
        out (0x14),a  ; data=06
        ld a,7
        out (c),a  ; a0=1
        ld a,6
        out (c),a  ; wr#=0
        ld a,7
        out (c),a  ; wr#=1

        ld a,0xf0
        out (0x14),a  ; data = aa
        ld a,3
        out (c),a  ; a0=0
        ld a,2
        out (c),a  ; wr = 0
        ld a,3
        out (c),a  ; wr = 1
        
        ld a,1
        out (c),a  ; rd = 0
        ld a,3
        out (c),a  ; rd = 1
        in a,(0x14)
        ld hl,0x8101
        ld (hl),a

        ld a,7
        out (c),a  ; a0=1
        ld a,5
        out (c),a  ; rd = 0
        ld a,7
        out (c),a  ; rd = 1
        in a,(0x14)
        ld hl,0x8102
        ld (hl),a

        ld a,01
        out (0x14),a  ; data=01
        ld a,7
        out (c),a  ; a0=1
        ld a,6
        out (c),a  ; wr#=0
        ld a,7
        out (c),a  ; wr#=1
      
        ld a,3
        out (c),a  ; a0=0
        ld a,1
        out (c),a  ; rd = 0
        ld a,3
        out (c),a  ; rd = 1
        in a,(0x14)
        ld hl,0x8103
        ld (hl),a


        ld a,7
        out (c),a  ; a0=1
        ld a,5
        out (c),a  ; rd = 0
        ld a,7
        out (c),a  ; rd = 1
        in a,(0x14)
        ld hl,0x8104
        ld (hl),a

        ret

szStartup:  .DB "Z80-Lottery",0

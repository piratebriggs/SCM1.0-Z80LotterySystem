; **********************************************************************
; **  Z180 Support                              by Stephen C Cousins  **
; **  Hardware: Generic Z180                                          **
; **********************************************************************


; **********************************************************************
; **  Public functions                                                **
; **********************************************************************

            .CODE

; Position Z180 internal I/O at 0xC0 to 0xFF
; First copy code to RAM and then execute it
; Must be in RAM as RC2014 paged ROM board pages out when writing to 
; I/O address 0x3F
Z180Init:   LD   HL,Z180Start   ;Source: start of code to copy
            LD   DE,kPassCode   ;Destination: transient code area
            LD   BC,Z180End-Z180Start ;Length of copy
            LDIR                ;Copy (HL) to (DE) and repeat x BC
            JP   kPassCode      ;Set Z180 I/O start address

; Z180 internal I/O address set up code
; Write twice to re-enable ROM on RC2014 paged ROM board
Z180Start:  LD   A,0xC0         ;Start of Z180 internal I/O
            DB   0xED,0x39,0x3F ;OUT0 (0x3F), A
            DB   0xED,0x39,0x3F ;OUT0 (0x3F), A
            RET
Z180End:


; **********************************************************************
; **  Public workspace (in RAM)                                       **
; **********************************************************************

            .DATA


; **********************************************************************
; **  End of Z180 Support                                             **
; **********************************************************************



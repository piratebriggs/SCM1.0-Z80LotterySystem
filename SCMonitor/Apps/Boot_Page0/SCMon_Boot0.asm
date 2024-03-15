; **********************************************************************
; **  Utility to boot from ROM Page 0               by Antony Briggs  **
; **********************************************************************


            .PROC Z80           ;SCWorkshop select processor

            .ORG 0x8000         ;This needs to run from upper bank
                                ;as we'll be paging between ROM banks

kPII_A:     .EQU 0x14           ;PII Port A
kPII_B:     .EQU 0x15           ;PII Port B
kPII_C:     .EQU 0x16           ;PII Port C
kPII_M:     .EQU 0x17           ;PII Config

Start:
            LD A,0x80   	    ; Bit 7 set (CS#), lower nibble = ROM bank 0
            OUT (kPII_B),A  	; Write it out

            JP 0x0000







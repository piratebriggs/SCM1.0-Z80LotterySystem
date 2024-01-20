; **********************************************************************
; **  ROM info: L* = LiNC80                     by Stephen C Cousins  **
; **********************************************************************

            .CODE

#IF         BUILD = "L0"
#Include    Hardware\LiNC80\ROM_Info_L1_Bank1.asm
;#Include   Hardware\LiNC80\ROM_Info_L1_Bank2.asm
#INSERTHEX  Hardware\LiNC80\GSL.hex
#ENDIF

#IF         BUILD = "L1"
#Include    Hardware\LiNC80\ROM_Info_L1_Bank1.asm
;#Include   Hardware\LiNC80\ROM_Info_L1_Bank2.asm
#INSERTHEX  Hardware\LiNC80\GSL.hex
#ENDIF

; **********************************************************************
; **  End of ROM information module                                   **
; **********************************************************************






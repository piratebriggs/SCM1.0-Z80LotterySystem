; **********************************************************************
; **  ROM info: Z1 = Z280RC                     by Stephen C Cousins  **
; **********************************************************************

            .CODE

#IF         BUILD = "Z0"
#Include    Hardware\Z280RC\ROM_Info_T1_Bank1.asm
;#Include    Hardware\Z280RC\ROM_Info_T1_Bank2.asm
#ENDIF

#IF         BUILD = "Z1"
#Include    Hardware\Z280RC\ROM_Info_T1_Bank1.asm
;#Include    Hardware\Z280RC\ROM_Info_T1_Bank2.asm
#ENDIF

; **********************************************************************
; **  End of ROM information module                                   **
; **********************************************************************





; **********************************************************************
; **  ROM info: T* = TomsSBC                    by Stephen C Cousins  **
; **********************************************************************

            .CODE

#IF         BUILD = "T0"
#Include    Hardware\TomsSBC\ROM_Info_T1_Bank1.asm
;#Include    Hardware\TomsSBC\ROM_Info_T1_Bank2.asm
#ENDIF

#IF         BUILD = "T1"
#Include    Hardware\TomsSBC\ROM_Info_T1_Bank1.asm
;#Include    Hardware\TomsSBC\ROM_Info_T1_Bank2.asm
#ENDIF

; **********************************************************************
; **  End of ROM information module                                   **
; **********************************************************************






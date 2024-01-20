; **********************************************************************
; **  ROM info: 0* = Custom                     by Stephen C Cousins  **
; **********************************************************************

            .CODE

#IF         BUILD = "00"
#Include    Hardware\Custom\ROM_Info_00_Bank1.asm
#ENDIF

#IF         BUILD = "01"
#Include    Hardware\Custom\ROM_Info_01_Bank1.asm
#ENDIF

; **********************************************************************
; **  End of ROM information module                                   **
; **********************************************************************


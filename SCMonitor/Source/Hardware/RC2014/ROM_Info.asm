; **********************************************************************
; **  ROM info: R* = Z80-Lottery                by Stephen C Cousins  **
; **********************************************************************

            .CODE

#IF         BUILD = "R0"
#Include    Hardware\RC2014\ROM_Info_R1_Bank1.asm
#ENDIF

#IF         BUILD = "R1"
#Include    Hardware\RC2014\ROM_Info_R1_Bank1.asm
#ENDIF

#IF         BUILD = "R2"
#Include    Hardware\RC2014\ROM_Info_R2_Bank1.asm
#ENDIF

#IF         BUILD = "R3"
#Include    Hardware\RC2014\ROM_Info_R3_Bank1.asm
#ENDIF

#IF         BUILD = "R4"
#Include    Hardware\RC2014\ROM_Info_R4_Bank1.asm
#ENDIF

; **********************************************************************
; **  End of ROM information module                                   **
; **********************************************************************
















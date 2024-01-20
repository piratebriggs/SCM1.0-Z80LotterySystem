; **********************************************************************
; **  Build Small Computer Monitor Configuration S4 (SC_S4 32k ROM)   **
; **********************************************************************

#IFNDEF     BUILD
#DEFINE     BUILD S4
#ENDIF

#INCLUDE    Monitor\Begin.asm

#INCLUDE    Hardware\SC_S4\Config.asm

#INCLUDE    Monitor\Core.asm

#INCLUDE    Hardware\SC_S4\!Manager.asm

#INCLUDE    Monitor\End.asm

#INCLUDE    Hardware\SC_S4\ROM_Info.asm



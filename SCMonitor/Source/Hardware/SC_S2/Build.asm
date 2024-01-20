; **********************************************************************
; **  Build Small Computer Monitor Configuration S2 (SC_S2 32k ROM)   **
; **********************************************************************

#IFNDEF     BUILD
#DEFINE     BUILD S2
#ENDIF

#INCLUDE    Monitor\Begin.asm

#INCLUDE    Hardware\SC_S2\Config.asm

#INCLUDE    Monitor\Core.asm

#INCLUDE    Hardware\SC_S2\!Manager.asm

#INCLUDE    Monitor\End.asm

#INCLUDE    Hardware\SC_S2\ROM_Info.asm




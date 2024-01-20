; **********************************************************************
; **  Build Small Computer Monitor Configuration Z1 (Z280RC)          **
; **********************************************************************

#IFNDEF     BUILD
#DEFINE     BUILD Z1
#ENDIF

#INCLUDE    Monitor\Begin.asm

#INCLUDE    Hardware\Z280RC\Config.asm

#INCLUDE    Monitor\Core.asm

#INCLUDE    Hardware\Z280RC\!Manager.asm

#INCLUDE    Monitor\End.asm

#INCLUDE    Hardware\Z280RC\ROM_Info.asm




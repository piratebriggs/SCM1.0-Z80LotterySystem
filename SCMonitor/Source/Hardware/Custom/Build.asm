; **********************************************************************
; **  Build Small Computer Monitor Configuration 0# (Custom)          **
; **********************************************************************

#IFNDEF     BUILD
#DEFINE     BUILD 00
#ENDIF

#INCLUDE    Monitor\Begin.asm

#INCLUDE    Hardware\Custom\Config.asm

#INCLUDE    Monitor\Core.asm

#INCLUDE    Hardware\Custom\!Manager.asm

#INCLUDE    Monitor\End.asm

#INCLUDE    Hardware\Custom\ROM_Info.asm



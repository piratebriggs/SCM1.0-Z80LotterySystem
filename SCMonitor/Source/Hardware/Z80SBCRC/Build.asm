; **********************************************************************
; **  Build Small Computer Monitor Configuration Z2 (Z80SBCRC)        **
; **********************************************************************

#IFNDEF     BUILD
#DEFINE     BUILD Z2
#ENDIF

#INCLUDE    Monitor\Begin.asm

#INCLUDE    Hardware\Z80SBCRC\Config.asm

#INCLUDE    Monitor\Core.asm

#INCLUDE    Hardware\Z80SBCRC\!Manager.asm

#INCLUDE    Monitor\End.asm

#INCLUDE    Hardware\Z80SBCRC\ROM_Info.asm






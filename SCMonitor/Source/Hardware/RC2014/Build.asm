; **********************************************************************
; **  Build Small Computer Monitor Configuration R# (RC2014 32k ROM)  **
; **********************************************************************

#IFNDEF     BUILD
#DEFINE     BUILD R1
#ENDIF

#INCLUDE    Monitor\Begin.asm

#INCLUDE    Hardware\RC2014\Config.asm

#INCLUDE    Monitor\Core.asm

#INCLUDE    Hardware\RC2014\!Manager.asm

#INCLUDE    Monitor\End.asm

#INCLUDE    Hardware\RC2014\ROM_Info.asm


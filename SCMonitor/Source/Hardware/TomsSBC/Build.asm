; **********************************************************************
; **  Build Small Computer Monitor Configuration T1 (TomsSBC 16k ROM) **
; **********************************************************************

#IFNDEF     BUILD
#DEFINE     BUILD T1
#ENDIF

#INCLUDE    Monitor\Begin.asm

#INCLUDE    Hardware\TomsSBC\Config.asm

#INCLUDE    Monitor\Core.asm

#INCLUDE    Hardware\TomsSBC\!Manager.asm

#INCLUDE    Monitor\End.asm

#INCLUDE    Hardware\TomsSBC\ROM_Info.asm



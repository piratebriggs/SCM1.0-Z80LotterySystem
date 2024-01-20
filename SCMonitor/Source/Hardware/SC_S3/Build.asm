; **********************************************************************
; **  Build Small Computer Monitor Configuration S3 (SC type S3)      **
; **********************************************************************

#IFNDEF     BUILD
#DEFINE     BUILD S3
#ENDIF

#INCLUDE    Monitor\Begin.asm

#INCLUDE    Hardware\SC_S3\Config.asm

#INCLUDE    Monitor\Core.asm

#INCLUDE    Hardware\SC_S3\!Manager.asm

#INCLUDE    Monitor\End.asm

#INCLUDE    Hardware\SC_S3\ROM_Info.asm




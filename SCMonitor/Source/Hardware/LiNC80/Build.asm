; **********************************************************************
; **  Build Small Computer Monitor Configuration L# (LiNC80 32k ROM)  **
; **********************************************************************

#IFNDEF     BUILD
#DEFINE     BUILD L1
#ENDIF

#INCLUDE    Monitor\Begin.asm

#INCLUDE    Hardware\LiNC80\Config.asm

#INCLUDE    Monitor\Core.asm

#INCLUDE    Hardware\LiNC80\!Manager.asm

#INCLUDE    Monitor\End.asm

#INCLUDE    Hardware\LiNC80\ROM_Info.asm



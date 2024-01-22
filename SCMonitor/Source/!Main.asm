; **********************************************************************
; **  Small Computer Monitor (SCMonitor)        by Stephen C Cousins  **
; **                                                                  **
; **  Developed with Small Computer Workshop (IDE)     www.scc.me.uk  **
; **********************************************************************

; Only one build can be defined so comment out the others
; 1st character (major identifier): letter=official, number=user/custom
; 2nd character (minor identifier): 1-9=official, 0=user/custom
;
;#DEFINE    BUILD 00            ;Complete custom/user build

;#DEFINE    BUILD L1            ;LiNC80 SBC1 standard 32k ROM

#DEFINE     BUILD R1            ;RC2014 08K ROM 32K RAM standard
;#DEFINE    BUILD R2            ;RC2014 16K ROM 48K RAM standard
;#DEFINE    BUILD R3            ;RC2014 32K ROM 32/64K RAM paged
;#DEFINE    BUILD R4            ;RC2014 16K ROM 32/64K RAM paged

;#DEFINE    BUILD S1            ;SC_S1  standard ROM (SC101)
;#DEFINE    BUILD S2            ;SC_S2  standard ROM (SC114 etc)
;#DEFINE    BUILD S3            ;SC_S3  standard ROM (SC108 etc)
;#DEFINE    BUILD S4            ;SC_S4  standard ROM (SC111 etc)
;
;#DEFINE    BUILD T1            ;TomsSBC standard ROM

;#DEFINE    BUILD W1            ;SCWorkshop simulator - standard

;#DEFINE    BUILD Z1            ;Z280RC by Bill Shen 
;#DEFINE    BUILD Z2            ;Z80SBCRC by Bill Shen (framework only)


; **********************************************************************
; For each value of BUILD include a suitable Build.asm file

#IF         BUILD = "0*"
#INCLUDE    Hardware\Custom\Build.asm
#ENDIF

#IF         BUILD = "L*"
#INCLUDE    Hardware\LiNC80\Build.asm
#ENDIF

#IF         BUILD = "R*"
#INCLUDE    Hardware\RC2014\Build.asm
#ENDIF

#IF         BUILD = "S2"
#INCLUDE    Hardware\SC_S2\Build.asm
#ENDIF

#IF         BUILD = "S3"
#INCLUDE    Hardware\SC_S3\Build.asm
#ENDIF

#IF         BUILD = "S4"
#INCLUDE    Hardware\SC_S4\Build.asm
#ENDIF

#IF         BUILD = "T1"
#INCLUDE    Hardware\TomsSBC\Build.asm
#ENDIF

#IF         BUILD = "W1"
#INCLUDE    Hardware\Workshop\Build.asm
#ENDIF

#IF         BUILD = "Z1"
#INCLUDE    Hardware\Z280RC\Build.asm
#ENDIF

#IF         BUILD = "Z2"
#INCLUDE    Hardware\Z80SBCRC\Build.asm
#ENDIF








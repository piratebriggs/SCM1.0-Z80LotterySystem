; **********************************************************************
; **  Small Computer Monitor (SCMonitor)        by Stephen C Cousins  **
; **                                                                  **
; **  Developed with Small Computer Workshop (IDE)     www.scc.me.uk  **
; **********************************************************************

; Configure assembler to generate Z80 code from Zilog mnemonics
            .PROC Z80           ;Select processor for SCWorkshop

; **********************************************************************
; **  Build options                                                   **
; **********************************************************************

; Only one build can be defined so comment out the others
; 1st character (major identifier): letter=official, number=user/custom
; 2nd character (minor identifier): 1-9=official, 0=user/custom
;
;#DEFINE    BUILD 00            ;Complete custom/user build

;#DEFINE    BUILD L0            ;LiNC80 SBC1 custom/user build
;#DEFINE    BUILD L1            ;LiNC80 SBC1 standard 32k ROM

;#DEFINE    BUILD R0            ;RC2014 custom/user build
;#DEFINE    BUILD R1            ;RC2014 08K ROM 32K RAM standard
;#DEFINE    BUILD R2            ;RC2014 16K ROM 48K RAM standard
;#DEFINE    BUILD R3            ;RC2014 32K ROM 32/64K RAM paged
;#DEFINE    BUILD R4            ;RC2014 16K ROM 32/64K RAM paged

;#DEFINE    BUILD S0            ;SCxxx  custom/user build
;#DEFINE    BUILD S1            ;SC101  standard ROM
;#DEFINE    BUILD S2            ;SC114  standard ROM
#DEFINE     BUILD S3            ;SC_S4  standard ROM
;#DEFINE    BUILD S4            ;SC111  standard ROM (Z180)
;
;#DEFINE    BUILD T0            ;TomsSBC custom/user build
;#DEFINE    BUILD T1            ;TomsSBC standard ROM

;#DEFINE    BUILD W0            ;SCWorkshop simulator - custom/user
;#DEFINE    BUILD W1            ;SCWorkshop simulator - standard

;#DEFINE    BUILD Z0            ;Zxxx   custom/user build
;#DEFINE    BUILD Z1            ;Z280RC by Bill Shen 
;#DEFINE    BUILD Z2            ;Z80SBCRC by Bill Shen 



; Source code version number: Major.Minor.Revision (.Touch)
; This is the version number of the core code and does not include
; the hardware drivers. 
; This version number is only changed when the source code no longer
; produces the same binary code for all existing builds.
; Cosmetic changes to the source and changes only affecting new
; hardware do not require the version number to change, only the
; 'Touch' date (which is an invisible part of the version number).
; Hardware drivers have their own configuration code and revision
; numbers: kConfMajor, kConfMinor and kConfRevis
kVersMajor: .EQU 1
kVersMinor: .EQU 0
kVersRevis: .EQU 0
;VersTouch: .EQU 20181212       ;Last date core code touched

; **********************************************************************
; **  Include configuration file                                      **
; **********************************************************************

#IF         BUILD = "0*"
#INCLUDE    Hardware\Custom\Config_00.asm
#ENDIF

#IF         BUILD = "L*"
#IF         BUILD = "L0"
#INCLUDE    Hardware\Custom\Config_L0.asm
#ELSE
#INCLUDE    Hardware\LiNC80\Config.asm
#ENDIF
#ENDIF

#IF         BUILD = "R*"
#IF         BUILD = "R0"
#INCLUDE    Hardware\Custom\Config_R0.asm
#ELSE
#INCLUDE    Hardware\RC2014\Config.asm
#ENDIF
#ENDIF

#IF         BUILD = "S*"
#IF         BUILD = "S0"
#INCLUDE    Hardware\Custom\Config_S0.asm
#ENDIF
#IF         BUILD = "S1"
#INCLUDE    Hardware\SC101\Config.asm
#ENDIF
#IF         BUILD = "S2"
#INCLUDE    Hardware\SC114\Config.asm
#ENDIF
#IF         BUILD = "S3"
#INCLUDE    Hardware\SC_S3\Config.asm
#ENDIF
#IF         BUILD = "S4"
#INCLUDE    Hardware\SC111\Config.asm
#ENDIF
#ENDIF

#IF         BUILD = "T*"
#IF         BUILD = "T0"
#INCLUDE    Hardware\Custom\Config_T0.asm
#ELSE
#INCLUDE    Hardware\TomsSBC\Config.asm
#ENDIF
#ENDIF

#IF         BUILD = "W*"
#IF         BUILD = "W0"
#INCLUDE    Hardware\Custom\Config_W0.asm
#ELSE
#INCLUDE    Hardware\Workshop\Config.asm
#ENDIF
#ENDIF

#IF         BUILD = "Z*"
#IF         BUILD = "Z0"
#INCLUDE    Hardware\Custom\Config_Z0.asm
#ENDIF
#IF         BUILD = "Z1"
#INCLUDE    Hardware\Z280RC\Config.asm
#ENDIF
#IF         BUILD = "Z2"
#INCLUDE    Hardware\Z80SBCRC\Config.asm
#ENDIF
#ENDIF


; **********************************************************************
; **  Configuration file requirements                                 **
; **********************************************************************

; The configuration file (included just above) must contain the 
; following details:
;
; Target hardware
;#DEFINE    LiNC80              ;Determines hardware support included 
;
; Configuration identifiers
;kConfMajor: .EQU 'W'           ;Config: Letter = official, number = user
;kConfMinor: .EQU '1'           ;Config: 1 to 9 = official, 0 = user
;
; Code assembled here (ROM or RAM)
; Address assumed to be on a 256 byte boundary
; Space required currently less than 0x1E00 bytes
;kCode:     .EQU 0x0000         ;Typically 0x0000 or 0xE000

; Data space here (must be in RAM)
; Address assumed to be on a 256 byte boundary
; Space required currently less 0x0400 bytes
;kData:     .EQU 0xFC00         ;Typically 0xFC00 (to 0xFFFF)

; Default values written to fixed locations in ROM for easy modification
;kConDef:   .EQU 2              ;Console device 1 is SIO port B
;kBaud1Def: .EQU 0x96           ;Console device 1 default baud rate 
;kBaud2Def: .EQU 0x96           ;Console device 2 default baud rate 

; ROM Filing System
;kROMBanks: .EQU 1              ;Number of software selectable ROM banks
;kROMTop:   .EQU 0x3F           ;Top of banked ROM (hi byte only)

; Timing
;kDelayCnt:  .EQU 306            ;Loop count for 1 ms delay at 7.3728 MHz

; Optional ROM filing system information
;#DEFINE    ROMFS_Monitor_EXE   ;Monitor.EXE

; Optional features (comment out or rename unwanted features)
; Excluding any of these may result in bugs as I don't test every option
; Exporting functions:
;#DEFINE    IncludeAPI          ;Application Programming Interface (API)
;#DEFINE    IncludeFDOS         ;Very limited CP/M style FDOS support
; Support functions:
;#DEFINE    IncludeStrings      ;String support (needs utilities)
;#DEFINE    IncludeUtilities    ;Utility functions (needs strings)
; Monitor functions:
;#DEFINE    IncludeMonitor      ;Monitor essentials
;#DEFINE    IncludeAssembler    ;Assembler (needs disassembler)
;#DEFINE    IncludeBaud         ;Baud rate setting
;#DEFINE    IncludeBreakpoint   ;Breakpoint and single stepping
;#DEFINE    IncludeCommands     ;Command Line Interprester (CLI)
;#DEFINE    IncludeDisassemble  ;Disassembler 
;#DEFINE    IncludeHelp         ;Extended help text
;#DEFINE    IncludeHexLoader    ;Intel hex loader
;#DEFINE    IncludeMiniTerm     ;Mini terminal support
;#DEFINE    IncludeTrace        ;Trace execution
; Extensions:
;#DEFINE    IncludeRomFS        ;ROM filing system
;#DEFINE    IncludeScripting    ;Simple scripting (needs monitor)
;#DEFINE    IncludeSelftest     ;Self test at reset


; **********************************************************************
; **  The following section should not be edited                      **
; **********************************************************************

StartOfMonitor:
            .EQU kCode          ;Start of monitor code

; Essential modules

; Core OS functions
#INCLUDE    Alpha.asm           ;This must be the first #include
#INCLUDE    Console.asm         ;Console support
#INCLUDE    Idle.asm            ;Idle events
#INCLUDE    Ports.asm           ;Port functions

; Optional modules (see #DEFINEs above)

; Exporting functions
#IFDEF      IncludeAPI
#INCLUDE    API.asm             ;Application Programming Interface (API)
#ENDIF
#IFDEF      IncludeFDOS
#INCLUDE    FDOS.asm            ;Very limited CP/M style FDOS support
#ENDIF

; Support functions
#IFDEF      IncludeStrings
#INCLUDE    Strings.asm         ;String support
#ENDIF
#IFDEF      IncludeUtilities
#INCLUDE    Utilities.asm       ;Utility functions (needs strings)
#ENDIF

; Monitor functions
#IFDEF      IncludeMonitor
#INCLUDE    Monitor.asm         ;Minitor essentials
#ENDIF
#IFDEF      IncludeAssembler
#INCLUDE    Assembler.asm       ;In-line assembler (needs disassembler)
#ENDIF
#IFDEF      IncludeBreakpoint
#INCLUDE    Breakpoint.asm      ;Breakpoint handler
#ENDIF
#IFDEF      IncludeCommands
#INCLUDE    Commands.asm        ;Command Line Interprester (CLI)
#ENDIF
#IFDEF      IncludeDisassemble
#INCLUDE    Disassembler.asm    ;In-line disassembler
#ENDIF
#IFDEF      IncludeHexLoader
#INCLUDE    HexLoader.asm       ;Intel hex loader
#ENDIF
#IFDEF      IncludeScripting
#INCLUDE    Script.asm          ;Simple scripting language
#ENDIF

; Extensions
#IFDEF      IncludeTrace
#INCLUDE    Trace.asm           ;Trace execution (needs disassembler)
#ENDIF
#IFDEF      IncludeRomFS
#INCLUDE    RomFS.asm           ;ROM filing system
#ENDIF


; Optionally hardware
#IFDEF      Custom
kHardID:    .EQU 0              ;Hardware ID number
#INCLUDE    Hardware\Custom\!Manager.asm
#ENDIF
#IFDEF      Simulated_Z80
kHardID:    .EQU 1              ;Hardware ID number
#INCLUDE    Hardware\Workshop\!Manager.asm
#ENDIF
#IFDEF      SCDevKit01_Z80
kHardID:    .EQU 2              ;Hardware ID number
#INCLUDE    Hardware\SCDevKit\!Manager.asm
#ENDIF
#IFDEF      RC2014_Z80
kHardID:    .EQU 3              ;Hardware ID number
#INCLUDE    Hardware\RC2014\!Manager.asm
#ENDIF
#IFDEF      SC101_Z80
kHardID:    .EQU 4              ;Hardware ID number
#INCLUDE    Hardware\SC101\!Manager.asm
#ENDIF
#IFDEF      LiNC80_Z80
kHardID:    .EQU 5              ;Hardware ID number
#INCLUDE    Hardware\LiNC80\!Manager.asm
#ENDIF
#IFDEF      TomsSBC_Z80
kHardID:    .EQU 6              ;Hardware ID number
#INCLUDE    Hardware\TomsSBC\!Manager.asm
#ENDIF
#IFDEF      Z280RC_Z280
kHardID:    .EQU 7              ;Hardware ID number
#INCLUDE    Hardware\Z280RC\!Manager.asm
#ENDIF
#IFDEF      SC114_Z80
kHardID:    .EQU 8              ;Hardware ID number
#INCLUDE    Hardware\SC114\!Manager.asm
#ENDIF
#IFDEF      Z80SBCRC_Z80
kHardID:    .EQU 9              ;Hardware ID number
#INCLUDE    Hardware\Z80SBCRC\!Manager.asm
#ENDIF
#IFDEF      SC_S3_Z80
kHardID:    .EQU 10             ;Hardware ID number
#INCLUDE    Hardware\SC_S3\!Manager.asm
#ENDIF
#IFDEF      SC111_Z180
kHardID:    .EQU 11             ;Hardware ID number
#INCLUDE    Hardware\SC111\!Manager.asm
#ENDIF


            .CODE
EndOfMonitor:                   ; End of monitor code


; **********************************************************************
; **  Include ROM filing system information                           **
; **********************************************************************

#IF         BUILD = "0*"
#INCLUDE    Hardware\Custom\ROM_Info_00.asm
#ENDIF

#IF         BUILD = "L*"
#IF         BUILD = "L0"
#INCLUDE    Hardware\Custom\ROM_Info_S0.asm
#ELSE
#INCLUDE    Hardware\LiNC80\ROM_Info.asm
#ENDIF
#ENDIF

#IF         BUILD = "R*"
#IF         BUILD = "R0"
#INCLUDE    Hardware\Custom\ROM_Info_R0.asm
#ELSE
#INCLUDE    Hardware\RC2014\ROM_Info.asm
#ENDIF
#ENDIF

#IF         BUILD = "S*"
#IF         BUILD = "S0"
#INCLUDE    Hardware\Custom\ROM_Info_S0.asm
#ENDIF
#IF         BUILD = "S1"
#INCLUDE    Hardware\SC101\ROM_Info.asm
#ENDIF
#IF         BUILD = "S2"
#INCLUDE    Hardware\SC114\ROM_Info.asm
#ENDIF
#IF         BUILD = "S3"
#INCLUDE    Hardware\SC_S3\ROM_Info.asm
#ENDIF
#IF         BUILD = "S4"
#INCLUDE    Hardware\SC111\ROM_Info.asm
#ENDIF
#ENDIF

#IF         BUILD = "T*"
#IF         BUILD = "T0"
#INCLUDE    Hardware\Custom\ROM_Info_T0.asm
#ELSE
#INCLUDE    Hardware\TomsSBC\ROM_Info.asm
#ENDIF
#ENDIF

#IF         BUILD = "W*"
#IF         BUILD = "W0"
#INCLUDE    Hardware\Custom\ROM_Info_W0.asm
#ELSE
#INCLUDE    Hardware\Workshop\ROM_Info.asm
#ENDIF
#ENDIF

#IF         BUILD = "Z*"
#IF         BUILD = "Z0"
#INCLUDE    Hardware\Custom\ROM_Info_Z0.asm
#ENDIF
#IF         BUILD = "Z1"
#INCLUDE    Hardware\Z280RC\ROM_Info.asm
#ENDIF
#IF         BUILD = "Z2"
#INCLUDE    Hardware\Z80SBCRC\ROM_Info.asm
#ENDIF
#ENDIF


; **********************************************************************
; **  End of Small Computer Monitor (SCMonitor) by Stephen C Cousins  **
; **********************************************************************

;     **************************************************************
;     **                     Copyright notice                     **
;     **                                                          **
;     **  This software is very nearly 100% my own work so I am   **
;     **  entitled to claim copyright and to grant licences to    **
;     **  others.                                                 **
;     **                                                          **
;     **  You are free to use this software for non-commercial    **
;     **  purposes provided it retains this copyright notice and  **
;     **  is clearly credited to me where appropriate.            **
;     **                                                          **
;     **  You are free to modify this software as you see fit     **
;     **  for your own use. You may also distribute derived       **
;     **  works provided they remain free of charge, are          **
;     **  appropriately credited and grant the same freedoms.     **
;     **                                                          **
;     **                    Stephen C Cousins                     **
;     **************************************************************
;
; Thanks to all those who have contributed to this software, 
; particularly:
;
; Jon Langseth for all the input, testing and encouragement during
; the conversion and extension for the LiNC80 SBC1.
;
; Bill Shen for porting to his Z280RC system.
;






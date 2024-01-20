; **********************************************************************
; **  Config: T* = TomsSBC                      by Stephen C Cousins  **
; **********************************************************************

; Target hardware
;#DEFINE    TomsSBC_Z80         ;Determines hardware support included 
kHardID:    .EQU 6              ;Hardware ID number

; Build variations:

; Standard build: 32k ROM
#IF         BUILD = "T1"
kConfMinor: .EQU '1'            ;Config: 1 to 9 = official, 0 = user
#ENDIF

; Common to all builds for this hardware:

; Configuration identifiers
kConfMajor: .EQU 'T'            ;Config: Letter = official, number = user
;kConfMinor: .EQU '1'           ;Config: 1 to 9 = official, 0 = user

; Code assembled here (ROM or RAM)
; Address assumed to be on a 256 byte boundary
; Space required currently less than 0x1E00 bytes
kCode:      .EQU 0x0000         ;Typically 0x0000 or 0xE000

; Data space here (must be in RAM)
; Address assumed to be on a 256 byte boundary
; Space required currently less 0x0400 bytes
kData:      .EQU 0xFC00         ;Typically 0xFC00 (to 0xFFFF)

; Default values written to fixed locations in ROM for easy modification
kConDef:    .EQU 1              ;Console device 1 is SIO port A
kBaud1Def:  .EQU 0x11           ;Console device 1 default baud rate 
kBaud2Def:  .EQU 0x11           ;Console device 2 default baud rate 

; ROM Filing System
; Always set for 4 banks in order to successfully search 28C256
kROMBanks:  .EQU 4              ;Number of software selectable ROM banks
kROMTop:    .EQU 0x3F           ;Top of banked ROM (hi byte only)

; Timing
kDelayCnt:  .EQU 306            ;Loop count for 1 ms delay at 7.3728 MHz

; Optional features (comment out or rename unwanted features)
; Excluding any of these may result in bugs as I don't test every option
; Exporting functions:
#DEFINE     IncludeAPI          ;Application Programming Interface (API)
#DEFINE     IncludeFDOS         ;Very limited CP/M style FDOS support
; Support functions:
#DEFINE     IncludeStrings      ;String support (needs utilities)
#DEFINE     IncludeUtilities    ;Utility functions (needs strings)
; Monitor functions:
#DEFINE     IncludeMonitor      ;Monitor essentials
#DEFINE     IncludeAssembler    ;Assembler (needs disassembler)
;#DEFINE    IncludeBaud         ;Baud rate setting
#DEFINE     IncludeBreakpoint   ;Breakpoint and single stepping
#DEFINE     IncludeCommands     ;Command Line Interprester (CLI)
#DEFINE     IncludeDisassemble  ;Disassembler 
#DEFINE     IncludeHelp         ;Extended help text
#DEFINE     IncludeHexLoader    ;Intel hex loader
#DEFINE     IncludeMiniTerm     ;Mini terminal support
;#DEFINE    IncludeTrace        ;Trace execution
; Extensions:
#DEFINE     IncludeRomFS        ;ROM filing system
;#DEFINE    IncludeScripting    ;Simple scripting (needs monitor)
#DEFINE     IncludeSelftest     ;Self test at reset

; DEFINES for any hardware options would go here

; **********************************************************************
; **  End of configuration details                                    **
; **********************************************************************










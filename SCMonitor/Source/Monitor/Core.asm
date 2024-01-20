; **********************************************************************
; **  Include SCM core modules                  by Stephen C Cousins  **
; **********************************************************************

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
;VersTouch: .EQU 20190124       ;Last date core code touched



StartOfMonitor:
            .EQU kCode          ;Start of monitor code

; Essential modules

; Core OS functions
#INCLUDE    Monitor\Alpha.asm   ;This must be the first #include
#INCLUDE    Monitor\Console.asm ;Console support
#INCLUDE    Monitor\Idle.asm    ;Idle events
#INCLUDE    Monitor\Ports.asm   ;Port functions

; Optional modules (see #DEFINEs above)

; Exporting functions
#IFDEF      IncludeAPI
#INCLUDE    Monitor\API.asm     ;Application Programming Interface (API)
#ENDIF
#IFDEF      IncludeFDOS
#INCLUDE    Monitor\FDOS.asm    ;Very limited CP/M style FDOS support
#ENDIF

; Support functions
#IFDEF      IncludeStrings
#INCLUDE    Monitor\Strings.asm ;String support
#ENDIF
#IFDEF      IncludeUtilities
#INCLUDE    Monitor\Utilities.asm ;Utility functions (needs strings)
#ENDIF

; Monitor functions
#IFDEF      IncludeMonitor
#INCLUDE    Monitor\Monitor.asm ;Minitor essentials
#ENDIF
#IFDEF      IncludeAssembler
#INCLUDE    Monitor\Assembler.asm ;In-line assembler (needs disassembler)
#ENDIF
#IFDEF      IncludeBreakpoint
#INCLUDE    Monitor\Breakpoint.asm  ;Breakpoint handler
#ENDIF
#IFDEF      IncludeCommands
#INCLUDE    Monitor\Commands.asm  ;Command Line Interprester (CLI)
#ENDIF
#IFDEF      IncludeDisassemble
#INCLUDE    Monitor\Disassembler.asm  ;In-line disassembler
#ENDIF
#IFDEF      IncludeHexLoader
#INCLUDE    Monitor\HexLoader.asm ;Intel hex loader
#ENDIF
#IFDEF      IncludeScripting
#INCLUDE    Monitor\Script.asm  ;Simple scripting language
#ENDIF

; Extensions
#IFDEF      IncludeTrace
#INCLUDE    Monitor\Trace.asm   ;Trace execution (needs disassembler)
#ENDIF
#IFDEF      IncludeRomFS
#INCLUDE    Monitor\RomFS.asm   ;ROM filing system
#ENDIF

; **********************************************************************
; **  End of Include SCM core modules                                 **
; **********************************************************************




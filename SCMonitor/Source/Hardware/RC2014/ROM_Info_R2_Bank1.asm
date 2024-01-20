; **********************************************************************
; **  ROM info: R2-Bank1                        by Stephen C Cousins  **
; **********************************************************************

; Standard 16K ROM
; Requires:
;   ROM from 0x0000 to 0x3FFF   eg. Paged ROM board
;   RAM from 0x4000 to 0xFFFF   eg. 64K RAM board

            .CODE

            .ORG 0x2000         ;Inserted files start here

; Executable: BASIC.COM
BasicCode:
#INSERTHEX  ..\Apps\MSBASIC_adapted_by_GSearle\SCMon_BASIC_code2000_data4000.hex
BasicCodeEnd:
BasicCodeW: .EQU BasicCode+3    ;Warm start entry 

; Help extension: BASIC.HLP
BasicHelp:  .DB  "BASIC    Grant Searle's adaptation of Microsoft BASIC",0x0D,0x0A
            .DB  "WBASIC   Warm start BASIC (retains BASIC program)",0x0D,0x0A
            .DB  0
BasicHelpEnd:

            .ORG 0x3FC0         ;File references downwards from 0x3FF0 

            .DW  0xAA55         ;Identifier
            .DB  "BASIC   "     ;File name ("BASIC.HLP")
            .DB  0x03           ;File type 3 = Help
            .DB  0              ;Not used
            .DW  BasicHelp      ;Start address
            .DW  BasicHelpEnd-BasicHelp ;Length

            .DW  0xAA55         ;Identifier
            .DB  "WBASIC  "     ;File name ("WBASIC.COM")
            .DB  0x01           ;File type 1 = Monitor command
            .DB  0              ;Not used
            .DW  BasicCodeW     ;Start address
            .DW  BasicCodeEnd-BasicCodeW  ;Length

            .DW  0xAA55         ;Identifier
            .DB  "BASIC   "     ;File name ("BASIC.COM")
            .DB  0x01           ;File type 1 = Monitor command
            .DB  0              ;Not used
            .DW  BasicCode      ;Start address
            .DW  BasicCodeEnd-BasicCode ;Length

#INCLUDE    Monitor/MonitorInfo.asm
; Include Monitor.EXE information at top of bank 1. eg:
;           .ORG 0x1FF0         ;First ROMFS file in 8k bank
;           .DW  0xAA55         ;Identifier
;           .DB  "Monitor "     ;File name ("Monitor.EXE")
;           .DB  2              ;File type 2 = Executable from ROM
;           .DB  0              ;Not used
;           .DW  0x0000         ;Start address
;           .DW  0x2000         ;Length

; **********************************************************************
; **  End of ROM information module                                   **
; **********************************************************************




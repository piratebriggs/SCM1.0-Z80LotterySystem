; **********************************************************************
; **  ROM info: R2-Bank1                        by Stephen C Cousins  **
; **********************************************************************

; Standard 16K ROM
; Requires:
;   ROM from 0x0000 to 0x3FFF
;   RAM from 0x8000 to 0xFFFF

            .CODE

            .ORG 0x2000         ;Inserted files start here

; Executable: BASIC.COM
BasicCode:
#INSERTHEX  ..\Apps\MSBASIC_adapted_by_GSearle\SCMon_BASIC_code2000_data8000.hex
BasicCodeEnd:
BasicCodeW: .EQU BasicCode+3    ;Warm start entry 

; Executable: BOOT0.COM
BootZeroCode:
#INSERTHEX  ..\Apps\Boot_Page0\SCMon_Boot0_code8000.hex
BootZeroCodeEnd:

; Executable: D1216C.COM
D1216CCode:
#INSERTHEX  ..\Apps\D1216C\SCMon_DS1216C_code8000.hex
D1216CCodeEnd:

; Help extension: BASIC.HLP
BasicHelp:  .DB  "BASIC    Grant Searle's adaptation of Microsoft BASIC",0x0D,0x0A
            .DB  "WBASIC   Warm start BASIC (retains BASIC program)",0x0D,0x0A
            .DB  0
BasicHelpEnd:

            .ORG 0x3FA0         ;File references downwards from 0x3FF0 

            .DW  0xAA55         ;Identifier
            .DB  "BASIC   "     ;File name ("BASIC.HLP")
            .DB  0x03           ;File type 3 = Help
            .DB  0              ;Not used
            .DW  BasicHelp      ;Start address
            .DW  BasicHelpEnd-BasicHelp ;Length

            .DW  0xAA55         ;Identifier
            .DB  "BOOT0   "     ;File name ("BOOT0.COM")
            .DB  0x41           ;File type 1 = Monitor command, moved to RAM
            .DB  0x80           ;Run in RAM at 0x8000
            .DW  BootZeroCode        ;Start address
            .DW  BootZeroCodeEnd-BootZeroCode ;Length

            .DW  0xAA55         ;Identifier
            .DB  "DS1216C "     ;File name ("DS1216C.COM")
            .DB  0x41           ;File type 1 = Monitor command, moved to RAM
            .DB  0x80           ;Run in RAM at 0x8000
            .DW  D1216CCode        ;Start address
            .DW  D1216CCodeEnd-D1216CCode ;Length

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




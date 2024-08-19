; **********************************************************************
; **  ROM info: R3-Bank1                        by Stephen C Cousins  **
; **********************************************************************

; Custom 8K ROM for use in upper 32k
; Requires:
;   RAM from 0x8000 to 0xFFFF

            .CODE

            .ORG 0xa000         ;Inserted files start here

; Executable: RomWBW.COM
RomWBWCode:
#INSERTHEX  ..\..\Test\RomWbw_load.hex
RomWBWCodeEnd:


            .ORG 0xBFE0         

            .DW  0xAA55         ;Identifier
            .DB  "RomWBW  "     ;File name ("BOOT0.COM")
            .DB  0x01           ;File type 1 = Monitor command
            .DB  0xA0           ;Run in RAM at 0xA000
            .DW  RomWBWCode        ;Start address
            .DW  RomWBWCodeEnd-RomWBWCode ;Length


#INCLUDE    Monitor\MonitorInfo.asm
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




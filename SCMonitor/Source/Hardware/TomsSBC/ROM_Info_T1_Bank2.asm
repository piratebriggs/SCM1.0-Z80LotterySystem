; **********************************************************************
; **  ROM info: T1_Bank2                         by Stephen C Cousins **
; **********************************************************************

; Standard 32k byte distribution ROM bank 2

            .CODE

            .ORG 0x4000         ;Additional ROM files go here

; Executable: BOOT.EXE
BootCode:
;#INSERTHEX Hardware\LiNC80\ROM_Files\Boot.hex
;#INSERTHEX Hardware\LiNC80\ROM_Files\BASIC.hex
;#INSERTHEX Hardware\LiNC80\ROM_Files\CPM.hex
            NOP
            RET
BootCodeEnd:

; Help extension: BOOT.HLP
BootHelp:   .DB  "BOOT     Boot....<TODO>",0x0D,0x0A
            .DB  0
BootHelpEnd:


            .ORG 0x7FE0         ;File references downwards from 0x7FF0 

            .DW  0xAA55         ;Identifier
            .DB  "BOOT    "     ;File name ("BOOT.HLP")
            .DB  0x03           ;File type 3 = Help
            .DB  0              ;Not used
            .DW  BootHelp       ;Start address
            .DW  BootHelpEnd-BootHelp ;Length

            .DW  0xAA55         ;Identifier
            .DB  "BOOT    "     ;File name ("BOOT.EXE")
            .DB  0x41           ;File type 2 = Command, moved to RAM
            .DB  0xF0           ;Move code to 0xF000 to run it
            .DW  BootCode       ;Start address
            .DW  BootCodeEnd-BootCode ;Length

;           .DATA               ;DO NOT INCLUDE ".DATA" or ".CODE"

; **********************************************************************
; **  End of ROM information module                                   **
; **********************************************************************














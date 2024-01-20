; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware:  Z280RC                                               **
; **  Interface: Paging                                               **
; **********************************************************************

; ROM paging is controlled by writing a '1' (disable ROM) or a 0 (enable 
; ROM) to I/O address 0x38. With address 0x3F controlling the ROM's A14
; line and address 0x3E controlling the ROM's A15 line.
;

kConfigReg: .EQU 0x38           ;ROM paging register

; Fixed address to allow external code to use it
kTransCode: .EQU kPassCode      ;Transient code area (typically 0xFF80)

; Fixed address to allow external code to use this data
iConfigCpy: .EQU kPassCtrl+0    ;Configure register shadow copy (0xFFF0)
iConfigPre: .EQU kPassCtrl+1    ;Config register previous copy (0xFFF1)


            .CODE


; Initialise ROM paging
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
RomPageInit:
            XOR  A
            LD   (iConfigCpy),A ;We must be in bank zero
            OUT  (kConfigReg),A ;Initialise register
            RET


; Execute code in ROM bank
;   On entry: A = ROM bank number (0 to 3)
;             DE = Absolute address to execute
;   On exit:  IX IY I AF' BC' DE' HL' preserved
; WARNING: Not safe against interrupt changing config register
; First copy required utility function to RAM and then run it
; The ROM bank is selected and the code executed
RomExec:    PUSH DE
            LD   HL,@TransExec  ;Source: start of code to copy
            LD   DE,kTransCode  ;Destination: transient code area
            LD   BC,@TransExecEnd-@TransExec  ;Length of copy
            LDIR                ;Copy (HL) to (DE) and repeat x BC
            POP DE
            JP  kTransCode
; Transient code copied to RAM before being executed
@TransExec: LD   B,A            ;Store new ROM bank number
            LD   A,(iConfigCpy) ;Get current ROM bank
            LD   (iConfigPre),A ;Store as 'previous' ROM bank
            LD   A,B            ;Restore new ROM bank number
            LD   (iConfigCpy),A ;Get current ROM bank number
            OUT  (0x3E),A       ;Set ROM's A15 so bank bit 0
            RRCA                ;Rotate bank bit 1 to bit 0
            OUT  (0x3F),A       ;Set ROM's A14 so bank bit 0
            LD   BC,kTransCode+@TransRet-@TransExec
            PUSH BC             ;Push return address onto stack
            PUSH DE             ;Jump to DE by pushing on
            RET                 ;  to stack and 'returning'
@TransRet:  LD   A,(iConfigPre) ;Get previous ROM bank number
            LD   (iConfigCpy),A ;Write current ROM bank shadow copy
            OUT  (0x3E),A       ;Set ROM's A15 so bank bit 0
            RRCA                ;Rotate bank bit 1 to bit 0
            OUT  (0x3F),A       ;Set ROM's A14 so bank bit 0
            RET
@TransExecEnd:


; Copy from ROM bank to RAM
;   On entry: A = ROM bank number (0 to 3)
;             HL = Source start address (in ROM)
;             DE = Destination start address (in RAM)
;             BC = Number of bytes to copy
;   On exit:  IX IY I AF' BC' DE' HL' preserved
; WARNING: Not safe against interrupt changing config register
; First copy required utility function to RAM and then run it
RomCopy:    PUSH BC
            PUSH DE
            PUSH HL
            LD   HL,TransCopy   ;Source: start of code to copy
            LD   DE,kTransCode  ;Destination: transient code area
            LD   BC,TransCopyEnd-TransCopy  ;Length of copy
            LDIR                ;Copy (HL) to (DE) and repeat x BC
            POP  HL
            POP  DE
            POP  BC
            JP   kTransCode
; Transient code copied to RAM before being executed
TransCopy:  OUT  (0x3F),A       ;Set ROM's A14 to bank bit 0
            RRCA                ;Rotate bank bit 1 to bit 0
            OUT  (0x3E),A       ;Set ROM's A15 to bank bit 0
            LDIR                ;Copy (HL) to (DE) and repeat x BC
            LD   A,(iConfigCpy) ;Restore ROM page...
            OUT  (0x3F),A       ;Set ROM's A14 to bank bit 0
            RRCA                ;Rotate bank bit 1 to bit 0
            OUT  (0x3E),A       ;Set ROM's A15 to bank bit 0
            RET
TransCopyEnd:


; **********************************************************************
; **  Private workspace (in RAM)                                      **
; **********************************************************************

            .DATA

; **********************************************************************
; **  End of driver: Z280RC, Paging                                   **
; **********************************************************************






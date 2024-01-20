; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware:  LiNC80                                               **
; **  Interface: Configuration register                               **
; **********************************************************************

; Configuration register at 0x38, hardware reset to 0x00
;
;  Address 0x38      +---------------+-----------------------+
;                    |   ROM Bank    |       RAM Bank        |
;  +--------+--------+-------+-------+-------+-------+-------+--------+
;  | /INTEN | CFG6   | ROS1  | ROS0  | BKS2  | BKS1  | BKS0  | /ROMEN |
;  +--------+--------+-------+-------+-------+-------+-------+--------+
;  | Bit 7  | Bit 6  | Bit 5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0  |
;  +--------+--------+-------+-------+-------+-------+-------+--------+
;
; CFG6 is not currently used and is reserved for future assignment.


kConfigReg: .EQU 0x38           ;LiNC80 SBC1 configuration register

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
@TransExec: RLCA                ;Shift requested ROM bank number
            RLCA                ;  from  0b000000NN
            RLCA                ;  to    0b00NN0000
            RLCA
            LD   B,A            ;Store new ROM bank bits
            LD   A,(iConfigCpy) ;Get current config byte
            LD   (iConfigPre),A ;Store as 'previous' config byte
            AND  0b11001111     ;Clear ROM bank bits
            OR   B              ;Include new ROM bank bits
            LD   (iConfigCpy),A ;Write config byte to shadow copy
            OUT  (kConfigReg),A ;Write config byte to register
            LD   BC,kTransCode+@TransRet-@TransExec
            PUSH BC             ;Push return address onto stack
            PUSH DE             ;Jump to DE by pushing on
            RET                 ;  to stack and 'returning'
@TransRet:  LD   A,(iConfigPre) ;Get previous ROM page
            LD   (iConfigCpy),A ;Write config byte to shadow copy
            OUT  (kConfigReg),A ;Write config byte to register
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
TransCopy:  PUSH BC             ;Preserve number of bytes to copy
            RLCA                ;Shift requested ROM bank number
            RLCA                ;  from  0b000000NN
            RLCA                ;  to    0b00NN0000
            RLCA
            LD   B,A            ;Store new ROM bank bits
            LD   A,(iConfigCpy) ;Get current config byte
            LD   C,A            ;Store as 'previous' config byte
            AND  0b11001111     ;Clear ROM bank bits
            OR   B              ;Include new ROM bank bits
            OUT  (kConfigReg),A ;Write new config byte to register
            LD   A,C            ;Get 'previous' config byte
            POP  BC             ;Restore number of bytes to copy
            LDIR                ;Copy (HL) to (DE) and repeat x BC
            OUT  (kConfigReg),A ;Restore 'previous' config byte
            RET
TransCopyEnd:


; **********************************************************************
; **  Private workspace (in RAM)                                      **
; **********************************************************************

            .DATA

; **********************************************************************
; **  End of driver: LiNC80, Configuration register                   **
; **********************************************************************








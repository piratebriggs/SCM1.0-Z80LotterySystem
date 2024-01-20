; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware:  SC_S3                                                **
; **  Interface: Banked RAM                                           **
; **********************************************************************

; This module is the driver for the SC_S3 compatible banked RAM
;
; The hardware inferface consists of:
; Bank select bit          port 0x38  bit 7
;
; When bank select is low, the primary 64k RAM bank is selected.
; When bank select is high, the secondary 64k RAM bank is selected.
; As this code runs in ROM, only the top half of each RAM bank is 
; accessable with these functions.
;
; These functions can be used to install more sophisticated banks 
; management code into RAM.


; **********************************************************************
; **  Constants
; **********************************************************************

; Must be defined in hardware manager module. eg:
;kBankPrt:  .EQU 0x38           ;Bank select port address


; **********************************************************************
; **  Driver code
; **********************************************************************

            .CODE


; BankedRAM: Read banked RAM
;   On entry: DE = Address in secondary RAM bank (0x8000 to 0xFFFF)
;   On exit:  A = Byte read from secondary RAM bank
;             DE HL IX IY I AF' BC' DE' HL' preserved
RdBankedRAM:
            LD   C,kBankPrt     ;Bank select port address
            LD   B,0x80         ;Data to select secondary RAM bank
            OUT  (C),B          ;Select secondary RAM bank
            LD   A,(DE)         ;Read from RAM
            LD   B,0x00         ;Data to select primary RAM bank
            OUT  (C),B          ;Select primary RAM bank
            RET


; BankedRAM: Write banked RAM
;   On entry: A = Byte to be written to secondary RAM bank
;             DE = Address in secondary RAM bank (0x8000 to 0xFFFF)
;   On exit:  A = Byte written to secondary RAM bank
;             A DE HL IX IY I AF' BC' DE' HL' preserved
WrBankedRAM:
            LD   C,kBankPrt     ;Bank select port address
            LD   B,0x80         ;Data to select secondary RAM bank
            OUT  (C),B          ;Select secondary RAM bank
            LD   (DE),A         ;Write to RAM
            LD   B,0x00         ;Data to select primary RAM bank
            OUT  (C),B          ;Select primary RAM bank
            RET


; **********************************************************************
; **  End of driver: Banked RAM                                       **
; **********************************************************************


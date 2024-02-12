; **********************************************************************
; **  Hardware Manager                          by Stephen C Cousins  **
; **  Hardware: RC2014                                                **
; **********************************************************************

; This module is responsible for:
;   Any optional hardware detection
;   Setting up drivers for all hardware
;   Initialising hardware

; Global constants
kSIO2:      .EQU 0x60           ;Base address of SIO/2 chip
kPrtIn:     .EQU 0x14           ;General input port  (PIO Port A)
kPrtOut:    .EQU 0x14           ;General output port (PIO Port A)
kPIO_C:     .EQU 0x16           ;Memory Bank port  (PIO Port C)
kPIO_M:     .EQU 0x17           ;General input port  (PIO Config)
kPIO_CFG:	.EQU	0x80	; Active, Mode 0, A & B & C Outputs

; Include device modules
#INCLUDE    Hardware\RC2014\SerialSIO2.asm


; **********************************************************************
; **  Public functions                                                **
; **********************************************************************

            .CODE

; Startup message
szStartup:  .DB "Z80-Lottery",kNull

PII_Initialise:
            LD A,kPIO_CFG 		; Load PIO Config vakue
            OUT (kPIO_M),A		; Set PIO Config
            ; PORT C will now be set to 0x00 = Bank 0
            LD A,0xF0 		    ; Select Bank F (1111)
            OUT (kPIO_C),A  	; Write it out
        	RET				    ; AND DONE
PII_Initialise_SZ	.EQU	$-PII_Initialise	; SIZE OF ROUTINE


; Hardware initialise
;   On entry: No parameters required
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; Identify and initialise console devices:
;   Console device 1 = Serial device at $80 (SIO port A or ACIA #1)
;   Console device 2 = Serial device at $80 (SIO port B)
;   Console device 3 = Serial device at $40 (ACIA #2)
; Sets up hardware device flags:
;   Bit 0 = Serial 6850 ACIA #1 detected
;   Bit 1 = Serial Z80 SIO   #1 detected
;   Bit 2 = Serial 6850 ACIA #2 detected
Hardware_Initialise:
            XOR  A
            LD   (iHwFlags),A   ;Clear hardware flags
; Init PIO - performed in Alpha.asm
            ; LD A,kPIO_CFG 		; Load PIO Config vakue
            ; OUT (kPIO_M),A		; Set PIO Config
; Look for SIO2 type 3 (lottery addressing scheme)
            CALL RC2014_SerialSIO2_Initialise_T3
            JR   NZ,@NoSIO2T3   ;Skip if SIO2 not found
            LD   HL,iHwFlags    ;Get hardware flags
            SET  1,(HL)         ;Set SIO2 present flag
            LD   HL,@PtrSIO2T3  ;Pointer to vector list
@Serial4:   LD   B,4            ;Number of jump vectors
; Set up jump table for serial device #1 or #1+#2
@Serial:    LD   A,kFnDev1In    ;First device jump entry
            CALL InitJumps      ;Set up serial vectors
@NoSIO2T3:
; Test if any console devices have been found
            LD   A,(iHwFlags)   ;Get device detected flags
            OR   A              ;Any found?
            RET  NZ             ;Yes, so return
; Indicate failure by turning on Bit 0 LED at the default port
            XOR  A              ;Output bit number zero (A=0)
            JP   PrtOSet        ;Turn on specified output bit
; Jump table enties
@PtrSIO2T1: ; Device #1 = Serial SIO/2 channel A
            .DW  RC2014_SerialSIO2A_InputChar_T1
            .DW  RC2014_SerialSIO2A_OutputChar_T1
            ; Device #2 = Serial SIO/2 channel B
            .DW  RC2014_SerialSIO2B_InputChar_T1
            .DW  RC2014_SerialSIO2B_OutputChar_T1
@PtrSIO2T2: ; Device #1 = Serial SIO/2 channel A
            .DW  RC2014_SerialSIO2A_InputChar_T2
            .DW  RC2014_SerialSIO2A_OutputChar_T2
            ; Device #2 = Serial SIO/2 channel B
            .DW  RC2014_SerialSIO2B_InputChar_T2
            .DW  RC2014_SerialSIO2B_OutputChar_T2
@PtrSIO2T3: ; Device #1 = Serial SIO/2 channel A
            .DW  RC2014_SerialSIO2A_InputChar_T3
            .DW  RC2014_SerialSIO2A_OutputChar_T3
            ; Device #2 = Serial SIO/2 channel B
            .DW  RC2014_SerialSIO2B_InputChar_T3
            .DW  RC2014_SerialSIO2B_OutputChar_T3


; Hardware: Set baud rate
;   On entry: No parameters required
;   On entry: A = Baud rate code
;             C = Console device number (1 to 6)
;   On exit:  IF successful: (ie. valid device and baud code)
;               A != 0 and NZ flagged
;             BC HL not specified
;             DE? IX IY I AF' BC' DE' HL' preserved
Hardware_BaudSet:
            XOR  A              ;Return failure (A=0 and Z flagged)
            RET                 ;Abort as invalid baud rate


; Hardware: Poll timer
;   On entry: No parameters required
;   On exit:  If 1ms event to be processed NZ flagged and A != 0
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
; Poll software generated timer to see if a 1ms event has occurred.
; We have to estimate the number of clock cycles used since the last
; call to this routine. When the system is waiting for a console input
; character this will be the time it takes to call here plus the time 
; to poll the serial input device. Lets call this the loop time.
; The rest of the time we don't know so the timer events will probably 
; run slow.
; We generate a 1000 Hz event (every 1,000 micro seconds) by 
; counting processor clock cycles.
; With a 7.3728 Hz CPU clock, 1,000 micro seconds is 7,373 cycles
Hardware_PollTimer:
            LD   A,(iHwIdle)    ;Get loop counter
            ADD  A,7            ;Add to loop counter
            LD   (iHwIdle),A    ;Store updated counter
            JR   C,@RollOver    ;Skip if roll over (1ms event)
            XOR   A             ;No event so Z flagged and A = 0
            RET
@RollOver:  OR    0xFF          ;1ms event so NZ flagged and A != 0
            RET


; Hardware: Output signon info
;   On entry: No parameters required
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
Hardware_Signon:
            LD   DE,@szHardware ;Pointer to start up message
            JP   OutputZString  ;Output start up message
@szHardware:
            .DB  "Z80 based RC2014 systems",kNewLine,kNull


; Hardware: Output devices info
;   On entry: No parameters required
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
Hardware_Devices:
            LD   HL,iHwFlags    ;Get hardware present flags
            LD   DE,@szHwSIO2   ;Serial SIO/2 message
            BIT  1,(HL)         ;Serial SIO/2 present?
            CALL NZ,OutputZString ;Yes, so list it
            RET
@szHwSIO2:  .DB  "1 = Z80 SIO port A (@80)",kNewLine
            .DB  "2 = Z80 SIO port B (@82)",kNewLine,kNull



; Initialise ROM paging
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
RomPageInit:
            RET

; Fixed address to allow external code to use it
kTransCode: .EQU 0xFF80         ;Transient code area

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
@TransExec: ;RLCA               ;Shift requested ROM bank number
            ;RLCA               ;  from  0b000000NN
            ;RLCA               ;  to    0b00NN0000
            ;RLCA
            ;LD   B,A           ;Store new ROM bank bits
            ;LD   A,(iConfigCpy)  ;Get current config byte
            ;LD   (iConfigPre),A  ;Store as 'previous' config byte
            ;AND  0b11001111    ;Clear ROM bank bits
            ;OR   B             ;Include new ROM bank bits
            ;LD   (iConfigCpy),A  ;Write config byte to shadow copy
            ;OUT  (kConfigReg),A  ;Write config byte to register
            LD   BC,kTransCode+@TransRet-@TransExec
            PUSH BC             ;Push return address onto stack
            PUSH DE             ;Jump to DE by pushing on
            RET                 ;  to stack and 'returning'
@TransRet:  ;LD   A,(iConfigPre)  ;Get previous ROM page
            ;LD   (iConfigCpy),A  ;Write config byte to shadow copy
            ;OUT  (kConfigReg),A  ;Write config byte to register
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
TransCopy:  ;PUSH BC            ;Preserve number of bytes to copy
            ;RLCA               ;Shift requested ROM bank number
            ;RLCA               ;  from  0b000000NN
            ;RLCA               ;  to    0b00NN0000
            ;RLCA
            ;LD   B,A           ;Store new ROM bank bits
            ;LD   A,(iConfigCpy)  ;Get current config byte
            ;LD   C,A           ;Store as 'previous' config byte
            ;AND  0b11001111    ;Clear ROM bank bits
            ;OR   B             ;Include new ROM bank bits
            ;OUT  (kConfigReg),A  ;Write new config byte to register
            ;LD   A,C           ;Get 'previous' config byte
            ;POP  BC            ;Restore number of bytes to copy
            LDIR                ;Copy (HL) to (DE) and repeat x BC
            ;OUT  (kConfigReg),A  ;Restore 'previous' config byte
            RET
TransCopyEnd:


; **********************************************************************
; **  Public workspace (in RAM)                                       **
; **********************************************************************

            .DATA

; Hardware flags
; Bit 0 = Serial 6850 ACIA #1 detected
; Bit 1 = Serial Z80 SIO   #1 detected
; Bit 2 = Serial 6850 ACIA #2 detected
; Bit 3 to 7 = Not defined, all cleared to zero
iHwFlags:   .DB  0x00           ;Hardware flags

iHwIdle:    .DB  0              ;Poll timer count

; **********************************************************************
; **  End of Hardware manager for RC2014                              **
; **********************************************************************

















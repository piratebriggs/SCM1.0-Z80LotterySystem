; **********************************************************************
; **  Hardware Manager                          by Stephen C Cousins  **
; **  Hardware: SC_S3                                                 **
; **********************************************************************

; This module is responsible for:
;   Any optional hardware detection
;   Setting up drivers for all hardware
;   Initialising hardware

; Global constants
kSIO:       .EQU 0x80           ;Base address of SIO/2 chip
kCTC:       .EQU 0x88           ;Base address of CTC chip
kACIA1:     .EQU 0x80           ;Base address of serial ACIA #1
kACIA2:     .EQU 0x40           ;Base address of serial ACIA #2
kPrtIn:     .EQU 0x00           ;General input port
kPrtOut:    .EQU 0x00           ;General output port
kBankPrt:   .EQU 0x38           ;Bank select port address

; Include device modules
#INCLUDE    Hardware\SC_S3\Serial6850.asm
#INCLUDE    Hardware\SC_S3\Z80_SIO.asm
#INCLUDE    Hardware\SC_S3\Z80_CTC.asm
#INCLUDE    Hardware\SC_S3\BankedRAM.asm


; **********************************************************************
; **  Public functions                                                **
; **********************************************************************

            .CODE

; Startup message
szStartup:  .DB "S3",kNull
;szStartup: .DB "RC2014",kNull


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
;   Bit 3 = Serial Z80 SIO in RC2014 compatibility mode
;   Bit 4 = Counter/timer Z80 CTC #1 detected
Hardware_Initialise:
            XOR  A
            LD   (iHwFlags),A   ;Clear hardware flags
; Look for SIO type 2 (official addressing scheme)
            CALL Z80_SIO_Initialise_T2
            JR   NZ,@NoSIOT2    ;Skip if SIO not found
            LD   HL,iHwFlags    ;Get hardware flags
            SET  1,(HL)         ;Set SIO present flag
            SET  3,(HL)         ;Set RC2014 compatibility
            LD   HL,@PtrSIOT2   ;Pointer to vector list
            JR   @Serial4       ;Set up serial vectors
@NoSIOT2:
; Look for SIO type 1 (original addressing scheme)
            CALL Z80_SIO_Initialise_T1
            JR   NZ,@NoSIOT1    ;Skip if SIO not found
            LD   HL,iHwFlags    ;Get hardware flags
            SET  1,(HL)         ;Set SIO present flag
            LD   HL,@PtrSIOT1   ;Pointer to vector list
@Serial4:   LD   B,4            ;Number of jump vectors
            JR   @Serial        ;Set up serial vectors
@NoSIOT1:
; Look for 6850 ACIA #1
            CALL RC2014_SerialACIA1_Initialise
            JR   NZ,@NoACIA1    ;Skip if 6850 not found
            LD   HL,iHwFlags    ;Get hardware flags
            SET  0,(HL)         ;Set 6850 present flag
            LD   HL,@PtrACIA1   ;Pointer to vector list
            LD   B,2            ;Number of jump vectors
            ;JR   @Serial       ;Set up serial vectors
; Set up jump table for serial device #1 or #1+#2
@Serial:    LD   A,kFnDev1In    ;First device jump entry
            CALL InitJumps      ;Set up serial vectors
@NoACIA1:
; Look for 6850 ACIA #2
            CALL RC2014_SerialACIA2_Initialise
            JR   NZ,@NoACIA2    ;Skip if 6850 not found
            LD   HL,iHwFlags    ;Get hardware flags
            SET  2,(HL)         ;Set 6850 present flag
            LD   HL,@PtrACIA2   ;Pointer to vector list
            LD   B,2            ;Number of jump vectors
            LD   A,kFnDev3In    ;First device jump entry
            CALL InitJumps      ;Set up serial vectors
@NoACIA2:
; Look for Z80 CTC
            LD   HL,iHwFlags    ;Get oddress of device detected flags
            BIT  1,(HL)         ;SIO detected
            JR   Z,@NoCTC       ;No, so skip CTC test
            CALL CTC_Test       ;Test if CTC present
            JR   Z,@NoCTC       ;Skip if CTC not detected
            SET  4,(HL)         ;Flag CTC detected
            CALL CTC_Initialise ;Initialise CTC
; Set SIO port A baud rate with CTC channel 0
            LD   A,(kaBaud1Def) ;Baud rate code, eg. 0x96 = 9600
            LD   C,1            ;Console device number (SIO port A)
            CALL Hardware_BaudSet
; Set SIO port B baud rate with CTC channel 1
            LD   A,(kaBaud2Def) ;Baud rate code, eg. 0x96 = 9600
            LD   C,2            ;Console device number (SIO port B)
            CALL Hardware_BaudSet
@NoCTC:
; Test if any console devices have been found
            LD   A,(iHwFlags)   ;Get device detected flags
            OR   A              ;Any found?
            RET  NZ             ;Yes, so return
; Indicate failure by turning on Bit 0 LED at the default port
            XOR  A              ;Output bit number zero (A=0)
            JP   PrtOSet        ;Turn on specified output bit
; Jump table enties
@PtrSIOT1:  ; Device #1 = Serial SIO/2 channel A
            .DW  Z80_SIOA_InputChar_T1
            .DW  Z80_SIOA_OutputChar_T1
            ; Device #2 = Serial SIO/2 channel B
            .DW  Z80_SIOB_InputChar_T1
            .DW  Z80_SIOB_OutputChar_T1
@PtrSIOT2:  ; Device #1 = Serial SIO/2 channel A
            .DW  Z80_SIOA_InputChar_T2
            .DW  Z80_SIOA_OutputChar_T2
            ; Device #2 = Serial SIO/2 channel B
            .DW  Z80_SIOB_InputChar_T2
            .DW  Z80_SIOB_OutputChar_T2
@PtrACIA1:  ; Device #1 = Serial ACIA #1 module
            .DW  RC2014_SerialACIA1_InputChar
            .DW  RC2014_SerialACIA1_OutputChar
@PtrACIA2:  ; Device #3 = Serial ACIA #2 module
            .DW  RC2014_SerialACIA2_InputChar
            .DW  RC2014_SerialACIA2_OutputChar


; Hardware: Set baud rate
;   On entry: No parameters required
;   On entry: A = Baud rate code or zero to set default
;             C = Console device number (1 to 6)
;   On exit:  IF successful: (ie. valid device and baud code)
;               A != 0 and NZ flagged
;             BC HL not specified
;             DE? IX IY I AF' BC' DE' HL' preserved
; A test is made for valid a device number and baud code.
; It is assumed the SIO and CTC clock source is 7.3728 MHz.
; The default is 9600 baud when the SIO channel is connected
; via the matching CTC channel. If the CTC channel is not 
; connected to the SIO the result is the SIO divider = 64, 
; giving 115200 baud.
;
; SC110 only connects SIO port B via the CTC, so port A must 
; always be 115200 baud (the default value when register A=0).
; Calling this routine for port A with baud rate code other 
; than zero will give incorrect baud rates.
;
; SC102+SC104 is configurable but is assumed to have port B
; connected via the CTC, with port A connected to a 7.3728
; MHz clock. If port A is using CTC channel 0 as its source
; then call this function with A != 0 to set the baud rate. 
;
;  +----------+--------------+---------------+---------------+
;  |  Serial  |   Baud rate  |  CTC setting  |  CTC setting  |
;  |    Baud  |        code  |   SIO div 16  |   SIO div 64  |
;  +----------+--------------+---------------+---------------+
;  |  230400  |   1 or 0x23  |            1  |               |
;  |  115200  |   2 or 0x11  |            2  |               |
;  |   57600  |   3 or 0x57  |            4  |               |
;  |   38400  |   4 or 0x38  |            6  |               |
;  |   19200  |   5 or 0x19  |           12  |               |
;  |   14400  |   6 or 0x14  |           16  |               |
;  |    9600  |   7 or 0x96  |               |            6  |
;  |    4800  |   8 or 0x48  |               |           12  |
;  |    2400  |   9 or 0x24  |               |           24  |
;  |    1200  |  10 or 0x12  |               |           48  |
;  |     600  |  11 or 0x60  |               |           96  |
;  |     300  |  12 or 0x30  |               |          192  |
;  +----------+--------------+---------------+---------------+
Hardware_BaudSet:
; Check for default rate request
; A = Baud rate code  (not verified, 0 = default)
; C = Console device number (1 to 6)  (not verified)
; The default is 9600 baud, but if the CTC channel is not connected
; to the SIO this results in SIO divider = 64, giving 115200 baud
            OR   A              ;Test for zero (set default)
            JR   NZ,@NotZero    ;Not zero, so skip
            LD   A,0x96         ;set 9600 (with CTC) or 115200 (no CTC)
; Search for baud rate in table
; A = Baud rate code  (not verified)
; C = Console device number (1 to 6)  (not verified)
@NotZero:   LD   HL,Hardware_BaudTable
            LD   B,12           ;Number of table entries
@Search:    CP   (HL)           ;Record for required baud rate?
            INC  HL             ;  and point to time constant value
            JR   Z,@Found       ;Yes, so go get time constant
            CP   B              ;Record number = baud rate code?
            JR   Z,@Found       ;Yes, so go get time constant
            INC  HL             ;Point to next record
            DJNZ @Search        ;Repeat until end of table
@Failed:    XOR  A              ;Return failure (A=0 and Z flagged)
            RET                 ;Abort as invalid baud rate
; Found location in table
; B = Baud code (1 to 11)  (verified)
; C = Console device number (1 to 6)  (not verified)
; (HL) = Time constant value for CTC  (verified)
@Found:     DEC  C              ;Decrement device to range 0 to 5
            LD   A,C            ;Get device number (0 to 5)
            CP   2              ;Valid device number? (0 to 1)
            JR   NC,@Failed     ;No, so abourt
; Port verified, so check for CTC
; B = Baud code (1 to 11)  (verified)
; C = Console device number (0 to 1)  (verified)
; (HL) = Time constant value for CTC  (verified)
            LD   A,(iHwFlags)   ;Get hardware flags
            BIT  1,A            ;Z80 SIO found?
            JR   Z,@Failed      ;No, so abort
            BIT  4,A            ;Z80 CTC found?
            JR   Z,@Failed      ;No, so abort
; CTC found, so set up CTC
; B = Baud code (1 to 11)  (verified)
; C = Console device number (0 to 1)  (verified)
; (HL) = Time constant value for CTC  (verified)
            LD   A,(HL)         ;Get time constant
            PUSH BC             ;Preserve channel number and baud code
            CALL CTC_Setup      ;Set device C (0 to 1) to time const A
            POP  BC             ;Restore channel number and baud code
; Set up SIO
; B = Baud code (1 to 11)  (verified)
; C = Console device number (0 to 1)  (verified)
            LD   A,(iHwFlags)   ;Get hardware flags
            BIT  3,A            ;SIO in RC2014 compatibility mode?
            PUSH AF
            CALL Z,Z80_SIO_GetCtrlPort_T1 ;Zilog standard mode
            POP  AF 
            CALL NZ,Z80_SIO_GetCtrlPort_T2  ;Compatibility mode
; Set up SIO
; B = Baud code (1 to 11)  (verified)
; C = SIO control port address  (verified)
            LD   A,B            ;Get baud rate code (1 to 11)
            CP   7              ;Less than 7? (= baud rate > 9600)
            PUSH AF
            CALL C,SIO_Set16    ;Set up SIO with divide 16
            POP  AF
            CALL NC,SIO_Set64   ;Set up SIO with divide 64
            OR   0xFF           ;Return success (A=0xFF and NZ flagged)
            RET
; Baud rate table 
; Position in table matches value of short baud rate code (1 to 11)
; First column in the table is the long baud rate code
; Second column is the CTC time constant value
Hardware_BaudTable:
            .DB  0x30,192       ;12 =    300 baud
            .DB  0x60, 96       ;11 =    600 baud
            .DB  0x12, 48       ;10 =   1200 baud
            .DB  0x24, 24       ; 9 =   2400 baud
            .DB  0x48, 12       ; 8 =   4800 baud
            .DB  0x96,  6       ; 7 =   9600 baud
            .DB  0x14, 16       ; 6 =  14400 baud
            .DB  0x19, 12       ; 5 =  19200 baud
            .DB  0x38,  6       ; 4 =  38400 baud
            .DB  0x57,  4       ; 3 =  57600 baud
            .DB  0x11,  2       ; 2 = 115200 baud
            .DB  0x23,  1       ; 1 = 230400 baud


; Hardware: Poll timer
;   On entry: No parameters required
;   On exit:  If 1ms event to be processed NZ flagged and A != 0
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
; If a CTC is found then thjis routine polls channel 2 to detect
; 1ms events. Otherwise...
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
            LD   A,(iHwFlags)   ;Get device detected flags
            BIT  4,A            ;CTC detected?
            JR   NZ,@PollCTC    ;Yes, so go poll CTC
; Poll software timer
            LD   A,(iHwIdle)    ;Get loop counter
            ADD  A,9            ;Add to loop counter
            LD   (iHwIdle),A    ;Store updated counter
            JR   C,@RollOver    ;Skip if roll over (1ms event)
            XOR   A             ;No event so Z flagged and A = 0
            RET
@RollOver:  OR    0xFF          ;1ms event so NZ flagged and A != 0
            RET
; Poll hardware timer (CTC)
@PollCTC:   PUSH HL
            LD   HL,iHwPrevTim  ;Point to previous (down counter)
            IN   A,(kCTC+2)     ;A = current (down counter)
            CP   (HL)           ;Compare (current - previous)
            LD   (HL),A         ;Update previous value
            LD   HL,iHwBacklog  ;Point to backlog (of 1ms events)
            LD   A,(HL)         ;Get backlog (of 1ms events)
            JR   C,@NoRoll      ;Skip if current < previous
            JR   Z,@NoRoll      ;Skip if current = previous
            ADD  A,5            ;Add 5ms to backlog (of 1ms events)
@NoRoll:    OR   A              ;Any backlog of events to process?
            JR   Z,@NoEvent     ;No, so skip
            PUSH AF             ;Preserve Z flag and A register
            DEC  A              ;Decrement backlog (of 1ms events)
            LD   (HL),A         ;Update backlog (of 1ms events)
            POP  AF             ;Restore Z flag and A register
@NoEvent:   POP  HL
            RET



; Hardware: Output signon info
;   On entry: No parameters required
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
Hardware_Signon:
            LD   DE,@szHardware ;Pointer to start up message
            JP   OutputZString  ;Output start up message
@szHardware:
            .DB  "SC-S3 compatible systems",kNewLine,kNull
            ;.DB  "Z80 based RC2014 systems",kNewLine,kNull


; Hardware: Output devices info
;   On entry: No parameters required
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
Hardware_Devices:
            LD   HL,iHwFlags    ;Get hardware present flags
            LD   DE,@szHw6850   ;Serial 6850 message
            BIT  0,(HL)         ;Serial 6850 present?
            CALL NZ,OutputZString ;Yes, so list it
            LD   DE,@szHwSIO    ;Serial SIO/2 message
            BIT  1,(HL)         ;Serial SIO/2 present?
            CALL NZ,OutputZString ;Yes, so list it
            LD   DE,@szHw6850B  ;Serial 6850 message
            BIT  2,(HL)         ;Serial 6850 present?
            CALL  NZ,OutputZString  ;Yes, so list it
            LD   DE,@szHwCTC    ;Z80 CTC message
            BIT  4,(HL)         ;Z80 CTC present?
            CALL  NZ,OutputZString  ;Yes, so list it
            RET
@szHw6850:  .DB  "1 = 6850 ACIA #1   (@80)",kNewLine,kNull
@szHwSIO:   .DB  "1 = Z80 SIO port A (@80)",kNewLine
            .DB  "2 = Z80 SIO port B (@82)",kNewLine,kNull
@szHw6850B: .DB  "3 = 6850 ACIA #2   (@40)",kNewLine,kNull
@szHwCTC:   .DB  "Z80 Counter/timer  (@88)",kNewLine,kNull



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

iHwIdle:    ;Poll timer count, or..
iHwPrevTim: .DB  0              ;Timer polling, previous timer reading
iHwBacklog: .DB  0              ;Timer polling, backlog of 1ms events

; **********************************************************************
; **  End of Hardware manager for RC2014                              **
; **********************************************************************






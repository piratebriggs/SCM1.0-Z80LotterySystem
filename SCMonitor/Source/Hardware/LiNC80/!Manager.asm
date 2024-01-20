; **********************************************************************
; **  Hardware Manager                          by Stephen C Cousins  **
; **  Hardware: LiNC80 SBC1                                           **
; **********************************************************************

; This module is responsible for:
;   Any optional hardware detection
;   Setting up drivers for all hardware
;   Initialising hardware

; Global constants
kSIO2:      .EQU 0x00           ;Base address of SIO/2 chip
kCTC:       .EQU 0x08           ;Base address of CTC chip
kPrtIn:     .EQU 0x30           ;General input port
kPrtOut:    .EQU 0x30           ;General output port

; Include device modules
;#INCLUDE   Hardware\LiNC80\Serial6850.asm
#INCLUDE    Hardware\LiNC80\Z80_SIO.asm
#INCLUDE    Hardware\LiNC80\Z80_CTC.asm
#INCLUDE    Hardware\LiNC80\ConfigReg.asm

; Common baud rates:
; 115200, 57600, 38400, 19200, 9600, 4800, 2400, 1200, 600, 300
;
; Possible baud rates and dividers based on 7.3728 MHz clock:
;  +----------+-----------+-----------+-----------+-------------+
;  |  Serial  |    Total  |     SIO   |      CTC  |  CTC count  |
;  |    Baud  |  Divider  |  Divider  |  Divider  |    setting  |
;  +----------+-----------+-----------+-----------+-------------+
;  |  115200  |       64  |       64  |  Jumpered to CPU clock  |
;  +----------+-----------+-----------+-----------+-------------+
;  |  230400  |       32  |       16  |        2  |          1  |
;  |  115200  |       64  |       16  |        4  |          2  |
;  |   57600  |      128  |       16  |        8  |          4  |
;  |   38400  |      192  |       16  |       12  |          6  |
;  |   19200  |      384  |       16  |       24  |         12  |
;  |   14400  |      512  |       16  |       32  |         16  |
;  |    9600  |      768  |       16  |       48  |         24  |
;  |    4800  |     1536  |       16  |       96  |         48  |
;  |    2400  |     3072  |       16  |      192  |         96  |
;  |    1200  |     6144  |       16  |      384  |        192  |
;  |     600* |    12288  |       16  |      768  |        n/a  |
;  |     300* |    24576  |       16  |     1536  |        n/a  |
;  +----------+-----------+-----------+-----------+-------------+
;  |  230400* |       32  |       64  |      0.5  |        n/a  |
;  |  115200* |       64  |       64  |        1  |        n/a  |
;  |   57600  |      128  |       64  |        2  |          1  |
;  |   38400* |      192  |       64  |        3  |        n/a  |
;  |   19200  |      384  |       64  |        6  |          3  |
;  |   14400  |      512  |       64  |        8  |          4  |
;  |    9600  |      768  |       64  |       12  |          6  |
;  |    4800  |     1536  |       64  |       24  |         12  |
;  |    2400  |     3072  |       64  |       48  |         24  |
;  |    1200  |     6144  |       64  |       96  |         48  |
;  |     600  |    12288  |       64  |      192  |         96  |
;  |     300  |    24576  |       64  |      384  |        192  |
;  +----------+-----------+-----------+-----------+-------------+
; * = Can not be generated baud rate in this configuration.
; The CTC's count setting is half the divider value as it is clocked 
; from the CPU clock and has to wait until the next clock to count,
; so alternate clock edges are ignored and count rate halves.
; SIO x1 divider not used due to synchronisation issues.


; **********************************************************************
; **  Public functions                                                **
; **********************************************************************

            .CODE

; Startup message
szStartup:  .DB "LiNC80",kNull


; Hardware initialise
;   On entry: No parameters required
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; Identify and initialise console devices:
;   Console device 1 = Serial device at $00 (SIO port A)
;   Console device 2 = Serial device at $00 (SIO port B)
; Sets up hardware device flags:
;   Bit 0 = Serial Z80 SIO   #1 detected
Hardware_Initialise:
            XOR  A
            LD   (iHwFlags),A   ;Clear hardware flags
; Look for SIO2 type 1 (original addressing scheme)
            CALL LiNC80_SerialSIO2_Initialise_T1
            JR   NZ,@NoSIO2T1   ;Skip if SIO2 not found
            LD   HL,iHwFlags    ;Get hardware flags
            SET  0,(HL)         ;Set SIO2 present flag
            LD   HL,@PtrSIO2T1  ;Pointer to vector list
            LD   B,4            ;Number of jump vectors
; Set up jump table for serial device #1+#2
            LD   A,kFnDev1In    ;First device jump entry
            CALL InitJumps      ;Set up serial vectors
; Initialise CTC
            CALL CTC_Initialise
; Set SIO port A to 9600 baud with clock source from CTC channel 0
; This causes SIO to divide by 64 giving 115200 baud when jumpered to CPU clock
            LD   A,(kaBaud1Def) ;Baud rate code, eg. 0x96 = 9600
            LD   C,1            ;Console device number (SIO port A)
            CALL Hardware_BaudSet
; Set SIO port B to 9600 baud with clock source from CTC channel 1
; This causes SIO to divide by 64 giving 115200 baud when jumpered to CPU clock
            LD   A,(kaBaud2Def) ;Baud rate code, eg. 0x96 = 9600
            LD   C,2            ;Console device number (SIO port B)
            JP   Hardware_BaudSet
; Test if any console devices have been found
;           LD   A,(iHwFlags)   ;Get device detected flags
;           OR   A              ;Any found?
;           RET  NZ             ;Yes, so return
; Indicate failure by turning on Bit 0 LED at the default port
@NoSIO2T1:  XOR  A              ;Output bit number zero (A=0)
            JP   PrtOSet        ;Turn on specified output bit
; Jump table enties
@PtrSIO2T1: ; Device #1 = Serial SIO/2 channel A
            .DW  LiNC80_SerialSIO2A_InputChar_T1
            .DW  LiNC80_SerialSIO2A_OutputChar_T1
            ; Device #2 = Serial SIO/2 channel B
            .DW  LiNC80_SerialSIO2B_InputChar_T1
            .DW  LiNC80_SerialSIO2B_OutputChar_T1


; Hardware: Set baud rate
;   On entry: No parameters required
;   On entry: A = Baud rate code
;             C = Console device number (1 to 6)
;   On exit:  IF successful: (ie. valid device and baud code)
;               A != 0 and NZ flagged
;             BC HL not specified
;             DE? IX IY I AF' BC' DE' HL' preserved
; A test is made for valid a device number and baud code.
; The LiNC80 SBC 1 provides optional baud rate control for
; device 1 (SIO port A) and device 2 (SIO port B).
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
; Search for baud rate in table
; A = Baud rate code  (not verified)
; C = Console device number (1 to 6)  (not verified)
            LD   HL,Hardware_BaudTable
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
            LD   A,(HL)         ;Get time constant
            PUSH BC             ;Preserve channel number and baud code
            CALL CTC_Setup      ;Set device C (0 or 1) to time const A
            POP  BC             ;Restore channel number and baud code
            LD   A,B            ;Get baud rate code (1 to 11)
            CP   7              ;Less than 7? (= baud rate > 9600)
            PUSH AF
            CALL C,SIO_Set16    ;Set device C (0 or 1) with divide 16
            POP  AF
            CALL NC,SIO_Set64   ;Set device C (0 or 1) with divide 64
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
; This function polls a hardware timer and returns a flag is a
; 1ms event needs processing.
Hardware_PollTimer:
            PUSH HL
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
            .DB  "Z80 based LiNC80 systems",kNewLine,kNull


; Hardware: Output devices info
;   On entry: No parameters required
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
Hardware_Devices:
            LD   HL,iHwFlags    ;Get hardware present flags
            LD   DE,@szHwSIO2   ;Serial SIO/2 message
            BIT  0,(HL)         ;Serial SIO/2 present?
            CALL NZ,OutputZString ;Yes, so list it
            RET
@szHwSIO2:  .DB  "1 = Z80 SIO port A (@00)",kNewLine
            .DB  "2 = Z80 SIO port B (@01)",kNewLine,kNull


; **********************************************************************
; **  Public workspace (in RAM)                                       **
; **********************************************************************

            .DATA

; Hardware flags
; Bit 0 = Serial Z80 SIO   #1 detected
; Bit 1 to 7 = Not defined, all cleared to zero
iHwFlags:   .DB  0x00           ;Hardware flags

iHwPrevTim: .DB  0              ;Timer polling, previous timer reading
iHwBacklog: .DB  0              ;Timer polling, backlog of 1ms events

; **********************************************************************
; **  End of Hardware manager for LiNC80                              **
; **********************************************************************








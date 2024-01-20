; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware:  Generic Z80                                          **
; **  Interface: Z80_CTC                                              **
; **********************************************************************

; This module is the driver for a Z80 CTC interface.
;
; Channel 0:
;    CLK/TRG0   input    = Typically processor clock (7.3728 MHz)
;    ZC/TO0     output   = SIO port A clock input        (optional)
;
; Channel 1:
;    CLK/TRG1   input    = Typically processor clock (7.3728 MHz)
;    ZC/TO1     output   = SIO port B clock input        (optional)
;
; Channel 2:
;    CLK/TRG2   input    = Typically processor clock (7.3728 MHz)
;    ZC/TO2     output   = Programmable clock tick       (optional)
;
; Channel 2:
;    CLK/TRG2   input    = Typically processor clock (7.3728 MHz)
;    ZC/TO2     output   = not availalble
;
; This module assumes the following:
;    Channel 0 is used to generate the clock for SIO port A 
;    Channel 1 is used to generate the clock for SIO port B
;    Channel 2 is used to generate 200Hz tick
;    Channel 3 not currently used
; Clock source assumed to be 7.3728 MHz
;
; Addressing: CS0=A0, CS1=A1, Base address = <kCTC>
; BaseAddress+0   Channel 0 (read and write)
; BaseAddress+1   Channel 1 (read and write)
; BaseAddress+2   Channel 2 (read and write)
; BaseAddress+3   Channel 3 (read and write)
;
; Channel control register:
; Bit 7 = Interrupt: 1 = enable, 0 = disable
; Bit 6 = Mode: 1 = counter, 0 = timer
; Bit 5 = Prescaler (timer mode only): 1 = 256, 0 = 16
; Bit 4 = Edge selection: 1 = rising, 0 = falling
; Bit 3 = Time trigger (timer mode only): 1 = input, 0 = auto
; Bit 2 = Time constant: 1 = value follow, 0 = does not
; Bit 1 = Reset: 1 = software reset, 0 = continue
; Bit 0 = Control/vector: 1 = control, 0 = vector

; Setup for 9600 baud with SIO divider at 64:
; Write to CTC channel 0 or 1: 0x55 (0101 0101) then 0x06
;

; Base address externally defined. eg:
;kCTC:      .EQU 0x08           ;Base address of CTC chip

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

kCTC_ctrl:  .EQU 0x55           ;Control register for baud rates

            .CODE


; Z80 CTC test
;   On entry: No parameters required
;   On exit:  NZ flagged if CTC present
;             A BC not specified
;             DE HL IX IY I AF' BC' DE' HL' preserved
; This routine tests in a CTC is present at the address kCTC. The
; test sets CTC channel 3 for fast counting and checks the counter
; changes within a limited time.
CTC_Test:   LD   C,kCTC+3       ;Channel 3's address
            LD   A,0b0010101    ;Timer: 7372800Hz/16 = 460kHz (2.2us)
            OUT  (C),A          ;Write to channel's control register
;           LD   A,<n>          ;460kHz/n = ? (n > 10 or so will do)
            OUT  (C),A          ;Write to channel's time base
            IN   A,(C)          ;Get 1st timer value
            LD   B,20           ;Delay
@Wait:      DJNZ @Wait          ;  by 10us or so
            LD   B,A            ;Store 1st timer value
            IN   A,(C)          ;Get 2nd timer value
            CP   B              ;Same? (same = no count occured)
            RET                 ;Return NZ if count changed


; Z80 CTC initialise
;   On entry: No parameters required
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; Channel 2 set for 200Hz interval but interrupt not enabled
CTC_Initialise:
            LD   A,0b00110101   ;Timer: 7372800Hz/256 = 28800Hz
            OUT  (kCTC+2),A     ;Write channel 2's control register
            LD   A,144          ;28800Hz/144 = 200 Hz
            OUT  (kCTC+2),A     ;Write channel 2's time base
            RET


; Z80 CTC setup
;   On entry: A = Time constant value
;             C = Channel number (0 to 3)
;   On exit:  DE HL IX IY I AF' BC' DE' HL' preserved
; Set up CTC time constant for specified channel
CTC_Setup:  LD   B,A            ;Preserve time constant value
            LD   A,kCTC         ;Get CTC base address
            ADD  A,C            ;Add channel number (0 to 3)
            LD   C,A            ;Store CTC channel register address
            LD   A,kCTC_ctrl    ;Control register for baud rates
            OUT  (C),A          ;Write to CTC control register
            OUT  (C),B          ;Write to time constant register
            RET


; **********************************************************************
; **  End of driver: Z80_CTC                                          **
; **********************************************************************




; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware:  LiNC80                                               **
; **  Interface: Z80_CTC                                              **
; **********************************************************************

;#TARGET     Simulated_Z80

; This module is the driver for Z80 CTC interface on the LiNC80 SBC1.
;
; Channel 0:
;    CLK/TRG0   input    = Processor clock (7.3728 MHz)
;    ZC/TO0     output   = SIO port A clock input        (optional)
;
; Channel 1:
;    CLK/TRG1   input    = Processor clock (7.3728 MHz)
;    ZC/TO1     output   = SIO port B clock input        (optional)
;
; Channel 2:
;    CLK/TRG2   input    = Processor clock (7.3728 MHz)
;    ZC/TO2     output   = Clock source for channel 3    (optional)
;
; Channel 2:
;    CLK/TRG2   input    = Channel 2 output or Sync      (optional)
;    ZC/TO2     output   = not availalble
;
; This module assumes the following:
;    Channel 0 is used to generate the clock for SIO port A 
;    Channel 1 is used to generate the clock for SIO port B
;    Channel 2 is used to generate 200Hz tick
;    Channel 3 not currently used
;
; LiNC80 addressing: CS0=A0, CS1=A1, Base address = 0x08
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
; Bit 0 = Control/vestor: 1 = control, 0 = vector

; Setup for 9600 baud with SIO divider at 64:
; Write to CTC channel 0 or 1: 0x55 (0101 0101) then 0x06
;

; Base address externally defined. eg:
;kCTC:      .EQU 0x08           ;Base address of CTC chip

kCTC_ctrl:  .EQU 0x55           ;Control register for baud rates

            .CODE


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
; **  End of driver: LiNC80, Z80_CTC                                  **
; **********************************************************************








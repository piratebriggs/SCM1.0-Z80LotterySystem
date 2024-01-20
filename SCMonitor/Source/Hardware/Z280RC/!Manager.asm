; **********************************************************************
; **  Hardware Manager                          by Stephen C Cousins  **
; **  Hardware: Z280RC                                                **
; **********************************************************************

; This module is responsible for:
;   Any optional hardware detection
;   Setting up drivers for all hardware
;   Initialising hardware

; Global constants
kSIO2:      .EQU 0x00           ;Base address of SIO/2 chip
kPrtIn:     .EQU 0xFF           ;General input port
kPrtOut:    .EQU 0xFF           ;General output port

; Include device modules
#INCLUDE    Hardware\Z280RC\Z80_SIO.asm
#INCLUDE    Hardware\Z280RC\Paging.asm


; **********************************************************************
; **  Public functions                                                **
; **********************************************************************

            .CODE

; Startup message
szStartup:  .DB "Z280RC",kNull


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
            CALL Z280RC_SerialSIO2_Initialise_T1
            JR   NZ,@NoSIO2T1   ;Skip if SIO2 not found
            LD   HL,iHwFlags    ;Get hardware flags
            SET  0,(HL)         ;Set SIO2 present flag
            LD   HL,@PtrSIO2T1  ;Pointer to vector list
            LD   B,4            ;Number of jump vectors
; Set up jump table for serial device #1+#2
            LD   A,kFnDev1In    ;First device jump entry
            CALL InitJumps      ;Set up serial vectors
; Test if any console devices have been found
;           LD   A,(iHwFlags)   ;Get device detected flags
;           OR   A              ;Any found?
;           RET  NZ             ;Yes, so return
; Indicate failure by turning on Bit 0 LED at the default port
@NoSIO2T1:  XOR  A              ;Output bit number zero (A=0)
            JP   PrtOSet        ;Turn on specified output bit
; Jump table enties
@PtrSIO2T1: ; Device #1 = Serial SIO/2 channel A
            .DW  Z280RC_SerialSIO2A_InputChar_T1
            .DW  Z280RC_SerialSIO2A_OutputChar_T1
            ; Device #2 = Serial SIO/2 channel B
            .DW  Z280RC_SerialSIO2B_InputChar_T1
            .DW  Z280RC_SerialSIO2B_OutputChar_T1


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
            ADD  A,6            ;Add to loop counter
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
            .DB  "Bill Shen's Z280 based Z280RC system",kNewLine,kNull


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

iHwIdle:    .DB  0              ;Poll timer count

; **********************************************************************
; **  End of Hardware manager for Z280RC                              **
; **********************************************************************












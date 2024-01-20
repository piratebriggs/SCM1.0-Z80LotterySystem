; **********************************************************************
; **  Hardware Manager                          by Stephen C Cousins  **
; **  Hardware: SCWorkshop simulator                                  **
; **********************************************************************

; This module is responsible for:
;   Any optional hardware detection
;   Setting up drivers for all hardware
;   Initialising hardware

; Global constants
kPrtIn:     .EQU 0x00           ;General input port
kPrtOut:    .EQU 0x00           ;General output port

; Include device modules
#INCLUDE    Hardware\Workshop\Terminal.asm
#INCLUDE    Hardware\Workshop\Printer.asm
#INCLUDE    Hardware\Workshop\ConfigReg.asm


; **********************************************************************
; **  Public functions                                                **
; **********************************************************************

            .CODE

; Startup message
szStartup:  .DB "Simulated",kNull


; Hardware: Initialise
;   On entry: No parameters required
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
Hardware_Initialise:
            LD   A,6            ;Output bit number 7 
            CALL PrtOSet        ;Turn on specified output bit
            XOR  A
            LD   (iHwFlags),A   ;Clear hardware flags
            CALL Simulated_Terminal_Initialise
            CALL Simulated_Printer_Initialise
            LD   HL,@Pointers
            LD   B,4
            LD   A,kFnDev1In
            JP   InitJumps
@Pointers:
            ; Device 1 = Serial terminal
            .DW  Simulated_Terminal_InputChar
            .DW  Simulated_Terminal_OutputChar
            ; Device 2 = Printer
            .DW  Simulated_Terminal_InputChar
            .DW  Simulated_Printer_OutputChar


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
            .DB  "Small Computer Simulator (Z80)",kNewLine,kNull


; Hardware: Output devices info
;   On entry: No parameters required
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
Hardware_Devices:
            LD   DE,@szHwList   ;Simulated hardware list message
            JP   OutputZString  ;Output string
            RET
@szHwList:  .DB  "Simulated serial, printer, timer, etc.",kNewLine,kNull


; **********************************************************************
; **  Public workspace (in RAM)                                       **
; **********************************************************************

            .DATA

; Hardware flags
; Bit 0 to 7 = Not defined, all cleared to zero
iHwFlags:   .DB  0x00           ;Hardware flags

iHwIdle:    .DB  0              ;Poll timer count

; **********************************************************************
; **  End of Hardware manager for SCWorkshop simulator                **
; **********************************************************************




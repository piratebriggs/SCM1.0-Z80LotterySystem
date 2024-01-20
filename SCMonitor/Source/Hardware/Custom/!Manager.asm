; **********************************************************************
; **  Hardware Manager                          by Stephen C Cousins  **
; **  Hardware: Custom                                                **
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


; **********************************************************************
; **  Public functions                                                **
; **********************************************************************

            .CODE

; Startup message
szStartup:  .DB "Custom",kNull


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
            RET


; Hardware: Set baud rate
;   On entry: No parameters required
;   On entry: A = Baud rate code
;             C = Console device number (1 to 6)
;   On exit:  IF successful: (ie. valid device and baud code)
;               A != 0 and NZ flagged
;             BC HL not specified
;             DE? IX IY I AF' BC' DE' HL' preserved
; A test is made for valid a device number and baud code.
Hardware_BaudSet:
; Search for baud rate in table
; A = Baud rate code  (not verified)
; C = Console device number (1 to 6)  (not verified)
            RET                 ;Abort as invalid baud rate


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
            .DB  "Z80 based custom system",kNewLine,kNull


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
            .DB  "2 = Z80 SIO port B (@00)",kNewLine,kNull


; Initialise ROM paging
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
RomPageInit:
            RET


; Execute code in ROM bank
;   On entry: A = ROM bank number (0 to 3)
;             DE = Absolute address to execute
;   On exit:  IX IY I AF' BC' DE' HL' preserved
RomExec:    RET


; Copy from ROM bank to RAM
;   On entry: A = ROM bank number (0 to 3)
;             HL = Source start address (in ROM)
;             DE = Destination start address (in RAM)
;             BC = Number of bytes to copy
;   On exit:  IX IY I AF' BC' DE' HL' preserved
; WARNING: Not safe against interrupt changing config register
; First copy required utility function to RAM and then run it
RomCopy:    RET


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



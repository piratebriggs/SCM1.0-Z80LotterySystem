; **********************************************************************
; **  Self test at reset                        by Stephen C Cousins  **
; **********************************************************************

; This module provides a self test function that runs at reset.
;
; The code is written to be INCLUDED in-line during the early stages
; following a reset. It therefore does not end in a RET instruction.
;
; Initially the digital status port LEDs each flash in turn. This 
; will run even if there is no RAM.
;
; A very simple RAM test using just location 0xFFFE and 0xFFFF is then
; performed. If it fails the self test repeats from the beginning, so
; the LEDs keep flashing if the RAM fails.
;

; Must be defined in hardware manager module. eg:
;kPrtOut:    .EQU 0              ;Assume digital status port is present


; **********************************************************************
; **  Public functions                                                **
; **********************************************************************

            .CODE

; Initialially we assume that there is no RAM so we avoid subroutines.

; Flash LEDs in turn to show we get as far as running code
Selftest:   LD   DE,1           ;Prepared for delay loop
            LD   B,0b00010000   ;First bit to write to LEDs
@Loop1:     IN   A,(kPrtOut)    ;Read Port
            AND  0b10001111     ;Mask off 3 bits
            OR   B              ;Set bits
            OUT  (kPrtOut),A    ;Write to LEDs
            LD   HL,0xE1C0      ;Set delay time (approx 8000 loops)
@Delay1:    ADD  HL,DE          ;Delay loop increments HL until
            JR   NC,@Delay1     ;  it reaches zero
            RLC  B              ;Rotate LED bit left
            JR   NC,@Loop1      ;Repeat until last LED cleared
            IN   A,(kPrtOut)
            AND  0b10001111     ;Clear 3 bits
            OUT  (kPrtOut),A    ;Write it out

; Very brief RAM test
            LD   HL,0xFFFF      ;Location to be tested
            LD   A,0x55         ;Test pattern 01010101
            LD   (HL),A         ;Store 01010101 at 0xFFFF
            DEC  HL             ;HL = 0xFFFE
            CPL                 ;Invert bits to 10101010
            LD   (HL),A         ;Store 10101010 at 0xFFFE
            INC  HL             ;HL = 0xFFFF
            CPL                 ;Invert bits to 01010101
            CP   (HL)           ;Test 01010101 at 0xFFFF
            JR   NZ,Selftest    ;Failed, so restart
            DEC  HL             ;HL = 0xFFFE
            CPL                 ;Invert bits to 10101010
            CP   (HL)           ;Test 10101010 at 0xFFFE
            JR   NZ,Selftest    ;Failed so restart
; Repeat with all tests inverted
            CPL                 ;Invert bits to 01010101
            LD   (HL),A         ;Store 01010101 at 0xFFFE
            INC  HL             ;HL = 0xFFFF
            CPL                 ;Invert bits to 10101010
            LD   (HL),A         ;Store 10101010 at 0xFFFF
            DEC  HL             ;HL = 0xFFFE
            CPL                 ;Invert bits to 01010101
            CP   (HL)           ;Test 01010101 at 0xFFFE
            JR   NZ,Selftest    ;Failed, so restart
            INC  HL             ;HL = 0xFFFF
            CPL                 ;Invert bits to 10101010
            CP   (HL)           ;Test 10101010 at 0xFFFF
            JR   NZ,Selftest    ;Failed, so restart

SelftestEnd:
            IN   A,(kPrtOut)
            AND  0b10001111     ;Clear 3 bits
            OUT  (kPrtOut),A    ;Write it out


; **********************************************************************
; **  End of Self test module                                         **
; **********************************************************************




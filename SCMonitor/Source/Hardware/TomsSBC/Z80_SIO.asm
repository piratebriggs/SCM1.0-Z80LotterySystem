; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware:  TomsSBC                                              **
; **  Interface: Serial SIO/2                                         **
; **********************************************************************

; This module is the driver for Z80 SIO/2 serial interface.
;
; Supports Grant Searle's addressing scheme:
;    SIO B/A line = A0, SIO C/D line = A1
;
; Tom's SBC standard addresses for Grant's original SIO/2: (type 1)
; BaseAddress+0   Channel A data registers (read and write)
; BaseAddress+1   Channel B data registers (read and write)
; BaseAddress+2   Channel A control registers (read and write)
; BaseAddress+3   Channel B control registers (read and write)
;
; Too complex to reproduce technical info here. See SIO datasheet

; Base address externally defined. eg:
;kSIO2:     .EQU 0x80           ;Base address of SIO/2 chip

; SIO/2 type 1 registers derived from base address (above)
kSIOAConT1: .EQU kSIO2+2        ;I/O address of control register A
kSIOADatT1: .EQU kSIO2+0        ;I/O address of data register A
kSIOBConT1: .EQU kSIO2+3        ;I/O address of control register B
kSIOBDatT1: .EQU kSIO2+1        ;I/O address of data register B
;
; Status (control) register bit numbers
kSIORxRdy:  .EQU 0              ;Receive data available bit number
kSIOTxRdy:  .EQU 2              ;Transmit data empty bit number

; Device detection, test 1
; This test just reads from the devices' status (control) register
; and looks for register bits in known states:
; CTS input bit = high
; DCD input bit = high
; Transmit data register empty bit = high
kSIOMask1:  .EQU  0b00101100    ;Mask for known bits in control reg
kSIOTest1:  .EQU  0b00101100    ;Test value following masking


            .CODE

; **********************************************************************
; **  Type 1 (Grant's original addressing scheme)                     **
; **********************************************************************


; TomsSBC type 1 serial SIO/2 initialise
;   On entry: No parameters required
;   On exit:  Z flagged if device is found and initialised
;             AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; If the device is found it is initialised
TomsSBC_SerialSIO2_Initialise_T1:
; First look to see if the device is present
            IN   A,(kSIOAConT1) ;Read status (control) register A
            AND  kSIOMask1      ;Mask for known bits in control reg
            CP   kSIOTest1      ;Test value following masking
            RET  NZ             ;Return not found NZ flagged
            IN   A,(kSIOBConT1) ;Read status (control) register B
            AND  kSIOMask1      ;Mask for known bits in control reg
            CP   kSIOTest1      ;Test value following masking
            RET  NZ             ;Return not found NZ flagged
; Device present, so initialise it
            LD   C,kSIOAConT1   ;SIO/2 channel A control port
            CALL TomsSBC_SerialSIO2_IniSend
            LD   C,kSIOBConT1   ;SIO/2 channel B control port
            JP   TomsSBC_SerialSIO2_IniSend


; TomsSBC type 1 serial SIO/2 channel A & B input character
;   On entry: No parameters required
;   On exit:  A = Character input from the device
;             NZ flagged if character input
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
TomsSBC_SerialSIO2A_InputChar_T1:
            IN   A,(kSIOAConT1) ;Address of status register
            BIT  kSIORxRdy,A    ;Receive byte available
            RET  Z              ;Return Z if no character
            IN   A,(kSIOADatT1) ;Read data byte
            RET
TomsSBC_SerialSIO2B_InputChar_T1:
            IN   A,(kSIOBConT1) ;Address of status register
            BIT  kSIORxRdy,A    ;Receive byte available
            RET  Z              ;Return Z if no character
            IN   A,(kSIOBDatT1) ;Read data byte
            RET


; TomsSBC type 1 serial SIO/2 channel A & B output character
;   On entry: A = Character to be output to the device
;   On exit:  If character output successful (eg. device was ready)
;               NZ flagged and A != 0
;             If character output failed (eg. device busy)
;               Z flagged and A = Character to output
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
TomsSBC_SerialSIO2A_OutputChar_T1:
            PUSH BC
            LD   C,kSIOAConT1   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            POP  BC
            RET  Z              ;Return Z as character not output
            OUT  (kSIOADatT1),A ;Write data byte
            OR   0xFF           ;Return success A=0xFF and NZ flagged
            RET
TomsSBC_SerialSIO2B_OutputChar_T1:
            PUSH BC
            LD   C,kSIOBConT1   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            POP  BC
            RET  Z              ;Return Z as character not output
            OUT  (kSIOBDatT1),A ;Write data byte
            OR   0xFF           ;Return success A=0xFF and NZ flagged
            RET


; Z80 SIO initialisation
;   On entry: C = Device number (0 or 1, for SIO A or B)
;   On exit:  DE IX IY I AF' BC' DE' HL' preserved
; Send initialisation data to specified channel
TomsSBC_SerialSIO2_IniSend:
            LD   HL,@SIOIni     ;Point to initialisation data
            LD   B,@SIOIniEnd-@SIOIni ;Length of ini data
            OTIR                ;Write data to output port C
            XOR  A              ;Return Z flag as device found
            RET
; SIO channel initialisation data
@SIOIni:    .DB  0b00011000     ; Wr0 Channel reset
;           .DB  0b00000010     ; Wr0 Pointer R2
;           .DB  0x00           ; Wr2 Int vector
            .DB  0b00010100     ; Wr0 Pointer R4 + reset ex st int
            .DB  0b11000100     ; Wr4 /64, async mode, no parity
            .DB  0b00000011     ; Wr0 Pointer R3
            .DB  0b11000001     ; Wr3 Receive enable, 8 bit 
            .DB  0b00000101     ; Wr0 Pointer R5
;           .DB  0b01101000     ; Wr5 Transmit enable, 8 bit 
            .DB  0b11101010     ; Wr5 Transmit enable, 8 bit, flow ctrl
            .DB  0b00010001     ; Wr0 Pointer R1 + reset ex st int
            .DB  0b00000000     ; Wr1 No Tx interrupts
@SIOIniEnd:


; **********************************************************************
; **  End of driver: Tom's SBC, Serial SIO/2                          **
; **********************************************************************




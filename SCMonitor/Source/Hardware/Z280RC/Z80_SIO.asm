; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware:  Z280RC                                               **
; **  Interface: Serial SIO/2                                         **
; **  Modifications for Z280RC by Bill Shen <hcs>                     **
; **********************************************************************

; This module is the driver for Z80 SIO/2 serial interface.
;
; Supports Grant Searle's addressing scheme:
;    SIO B/A line = A0, SIO C/D line = A1
;
; Z280RC standard addresses for Grant's original SIO/2: (type 1)
; BaseAddress+0   Channel A data registers (read and write)
; BaseAddress+1   Channel B data registers (read and write)
; BaseAddress+2   Channel A control registers (read and write)
; BaseAddress+3   Channel B control registers (read and write)
;
; Too complex to reproduce technical info here. See SIO datasheet

; Base address externally defined. eg:
;kSIO2:     .EQU 0x80           ;Base address of SIO/2 chip

RxData      equ 16h             ;hcs on-chip UART receive register
TxData      equ 18h             ;hcs on-chip UART transmit register
RxStat      equ 14h             ;hcs on-chip UART transmitter status/control register
TxStat      equ 12h             ;hcs 0n-chip UART receiver status/control register


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


; Z280RC type 1 serial SIO/2 initialise
;   On entry: No parameters required
;   On exit:  Z flagged if device is found and initialised
;             AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; If the device is found it is initialised
Z280RC_SerialSIO2_Initialise_T1:

;hcs init page i/o reg to point to UART
UARTPage:   ;hcs
            push bc             ;hcs save register
            push hl             ;hcs
            ld c,08h            ;hcs reg c points to I/O page register
            ld l,0feh           ;hcs set I/O page register to 0xFE
            db 0edh,6eh         ;hcs this is the op code for LDCTL (C),HL
;           ldctl (c),hl        ;hcs write to I/O page register
;           ld a,0e2h             ;hcs initialize the UART configuration register
;           out (UARTconf),a  ;hcs
;           ld a,80h              ;hcs enable UART transmit and receive
;           out (TxStat),a    ;hcs
;           out (RxStat),a    ;hcs
            pop hl              ;hcs restore reg
            pop bc              ;hcs

            xor a               ;hcs set zero flag
            ret                 ;hcs return with zero flag
            
; First look to see if the device is present
;hcs            IN   A,(kSIOAConT1) ;Read status (control) register A
;hcs            AND  kSIOMask1      ;Mask for known bits in control reg
;hcs            CP   kSIOTest1      ;Test value following masking
;hcs            RET  NZ             ;Return not found NZ flagged
;hcs            IN   A,(kSIOBConT1) ;Read status (control) register B
;hcs            AND  kSIOMask1      ;Mask for known bits in control reg
;hcs            CP   kSIOTest1      ;Test value following masking
;hcs            RET  NZ             ;Return not found NZ flagged
; Device present, so initialise it
;hcs            LD   C,kSIOAConT1   ;SIO/2 channel A control port
;hcs            CALL Z280RC_SerialSIO2_IniSend
;hcs            LD   C,kSIOBConT1   ;SIO/2 channel B control port
;hcs            JP   Z280RC_SerialSIO2_IniSend


; Z280RC type 1 serial SIO/2 channel A & B input character
;   On entry: No parameters required
;   On exit:  A = Character input from the device
;             NZ flagged if character input
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
Z280RC_SerialSIO2A_InputChar_T1:
;hcs            IN   A,(kSIOAConT1) ;Address of status register
;hcs            BIT  kSIORxRdy,A    ;Receive byte available
;hcs            RET  Z              ;Return Z if no character
;hcs            IN   A,(kSIOADatT1) ;Read data byte
;hcs            RET
            in a,(RxStat)       ;hcs read on-chip UART receive status
            and 10h             ;hcs data available?
            ret z               ;hcs  return Z if no character
            in a,(RxData)       ;hcs read data byte to register
            ret                 ;hcs
Z280RC_SerialSIO2B_InputChar_T1:
            IN   A,(kSIOBConT1) ;Address of status register
            BIT  kSIORxRdy,A    ;Receive byte available
            RET  Z              ;Return Z if no character
            IN   A,(kSIOBDatT1) ;Read data byte
            RET


; Z280RC type 1 serial SIO/2 channel A & B output character
;   On entry: A = Character to be output to the device
;   On exit:  If character output successful (eg. device was ready)
;               NZ flagged and A != 0
;             If character output failed (eg. device busy)
;               Z flagged and A = Character to output
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
Z280RC_SerialSIO2A_OutputChar_T1:
;hcs            PUSH BC
;hcs            LD   C,kSIOAConT1   ;SIO control register
;hcs            IN   B,(C)          ;Read SIO control register
;hcs            BIT  kSIOTxRdy,B    ;Transmit register full?
;hcs            POP  BC
;hcs            RET  Z              ;Return Z as character not output
;hcs            OUT  (kSIOADatT1),A ;Write data byte
;hcs            OR   0xFF           ;Return success A=0xFF and NZ flagged
;hcs            RET

            push bc             ;hcs save reg
            ld c,TxStat         ;hcs transmit status register
            in b,(c)            ;hcs read transmit status
            bit 0,b             ;hcs transmit reg full?
            pop bc              ;hcs restore register
            ret z               ;hcs return z as character not output
            out (TxData),a      ;hcs write data byte
            or 0xff             ;hcs return success A=0xFF and NZ flagged
            ret                 ;hcs

Z280RC_SerialSIO2B_OutputChar_T1:
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
Z280RC_SerialSIO2_IniSend:
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
; **  End of driver: Z280RC, Serial SIO/2                             **
; **********************************************************************








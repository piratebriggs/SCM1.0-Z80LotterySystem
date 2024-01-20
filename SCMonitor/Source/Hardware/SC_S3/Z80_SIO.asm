; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware:  SC_S3                                                **
; **  Interface: Z80_SIO                                              **
; **********************************************************************

; This module is the driver for Z80 SIO/2 serial modules. It supports
; both Grant's original and Spencer's official addresing schemes.
;
; WARNING: the official SIO/2 module is not compatible with Grant
; Searle's original design (later used by Dr. S Baker's module).
; Addresses used:
; Original: SIOA-C=0x82, SIOA-D=0x80, SIOB-C=0x83, SIOB-D=0x81
; Official: SIOA-C=0x80, SIOA-D=0x81, SIOB-C=0x82, SIOB-D=0x83
; Address signals:
; Original: SIO C/D line = A1,  SIO B/A line = A0
; Official: SIO C/D line = /A0, SIO B/A line = A1
;
; RC2014 standard addresses for Grant's original SIO/2: (type 1)
; 0x82   Channel A control registers (read and write)
; 0x80   Channel A data registers (read and write)
; 0x83   Channel B control registers (read and write)
; 0x81   Channel B data registers (read and write)
;
; RC2014 standard addresses for Spencer's official SIO/2: (type 2)
; 0x80   Channel A control registers (read and write)
; 0x81   Channel A data registers (read and write)
; 0x82   Channel B control registers (read and write)
; 0x83   Channel B data registers (read and write)
;
; Too complex to reproduce technical info here. See SIO datasheet

; Base address for SIO externally defined. eg:
;kSIO:      .EQU 0x80           ;Base address of SIO/2 chip

; SIO/2 type 1 registers derived from base address (above)
kSIOAConT1: .EQU kSIO+2         ;I/O address of control register A
kSIOADatT1: .EQU kSIO+0         ;I/O address of data register A
kSIOBConT1: .EQU kSIO+3         ;I/O address of control register B
kSIOBDatT1: .EQU kSIO+1         ;I/O address of data register B
;
; SIO/2 type 2 registers derived from base address (above)
kSIOAConT2: .EQU kSIO+0         ;I/O address of control register A
kSIOADatT2: .EQU kSIO+1         ;I/O address of data register A
kSIOBConT2: .EQU kSIO+2         ;I/O address of control register B
kSIOBDatT2: .EQU kSIO+3         ;I/O address of data register B

; Status (control) register bit numbers
kSIORxRdy:  .EQU 0              ;Receive data available bit number
kSIOTxRdy:  .EQU 2              ;Transmit data empty bit number

; Device detection, test 1
; This test just reads from the devices' status (control) register
; and looks for register bits in known states:
; Bit 7 = Break/abort
; Bit 6 = Transmit underrun
; Bit 5 = CTS input bit = high
; Bit 4 = Sync / hunt empty
; Bit 3 = DCD input bit = high
; Bit 2 = Transmit data register empty bit = high
; Bit 1 = Interrupt pending
; Bit 0 = Receive character available
; After reset the following is known: ?1x? x100 (x = external input)
; With SC104 and SC110 the CTC bit can be zero if an FTDI cable is
; connected but not initialised for serial, so don't test this bit.
kSIOMask1:  .EQU  0b01001100    ;Mask for known bits in control reg
kSIOTest1:  .EQU  0b01001100    ;Test value following masking
; RC2014 version
;kSIOMask1: .EQU  0b00101100    ;Mask for known bits in control reg
;kSIOTest1: .EQU  0b00101100    ;Test value following masking


            .CODE


; **********************************************************************
; **  Type 1 (Grant's original addressing scheme)                     **
; **********************************************************************


; RC2014 type 1 serial SIO/2 initialise
;   On entry: No parameters required
;   On exit:  Z flagged if device is found and initialised
;             AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; If the device is found it is initialised
Z80_SIO_Initialise_T1:
; First look to see if the device is present
            IN   A,(kSIOAConT1) ;Read status (control) register A
            AND  kSIOMask1      ;Mask for known bits in control reg
            CP   kSIOTest1      ;Test value following masking
            RET  NZ             ;Return not found NZ flagged
            IN   A,(kSIOBConT1) ;Read status (control) register B
            AND  kSIOMask1      ;Mask for known bits in control reg
            CP   kSIOTest1      ;Test value following masking
            RET  NZ             ;Return not found NZ flagged
; Device present, so initialise A
            LD   C,kSIOAConT1   ;SIO/2 channel A control port
            CALL Z80_SIO_IniSend
            LD   C,kSIOBConT1   ;SIO/2 channel B control port
            JP   Z80_SIO_IniSend


; RC2014 type 1 serial SIO/2 channel A & B input character
;   On entry: No parameters required
;   On exit:  A = Character input from the device
;             NZ flagged if character input
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
Z80_SIOA_InputChar_T1:
            IN   A,(kSIOAConT1) ;Address of status register
            BIT  kSIORxRdy,A    ;Receive byte available
            RET  Z              ;Return Z if no character
            IN   A,(kSIOADatT1) ;Read data byte
            RET
Z80_SIOB_InputChar_T1:
            IN   A,(kSIOBConT1) ;Address of status register
            BIT  kSIORxRdy,A    ;Receive byte available
            RET  Z              ;Return Z if no character
            IN   A,(kSIOBDatT1) ;Read data byte
            RET


; RC2014 type 1 serial SIO/2 channel A & B output character
;   On entry: A = Character to be output to the device
;   On exit:  If character output successful (eg. device was ready)
;               NZ flagged and A != 0
;             If character output failed (eg. device busy)
;               Z flagged and A = Character to output
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
Z80_SIOA_OutputChar_T1:
            PUSH BC
            LD   C,kSIOAConT1   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            POP  BC
            RET  Z              ;Return Z as character not output
            OUT  (kSIOADatT1),A ;Write data byte
            OR   0xFF           ;Return success A=0xFF and NZ flagged
            RET
Z80_SIOB_OutputChar_T1:
            PUSH BC
            LD   C,kSIOBConT1   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            POP  BC
            RET  Z              ;Return Z as character not output
            OUT  (kSIOBDatT1),A ;Write data byte
            OR   0xFF           ;Return success A=0xFF and NZ flagged
            RET


; Z80 SIO type 1 get control port address for channel A or B
;   On entry: C = Port number (0=A, 1=B)
;   On exit:  C = Control port address
;             AF = Not specified
;             B DE HL IX IY I AF' BC' DE' HL' preserved
Z80_SIO_GetCtrlPort_T1:
            LD   A,kSIOAConT1   ;Zilog std addressing control port A
            BIT  0,C            ;Port B?
            JR   Z,@Skip        ;No, so skip
            LD   A,kSIOBConT1   ;Zilog std addressing control port B
@Skip:      LD   C,A            ;Get port's control register address
            RET


; **********************************************************************
; **  Type 2 (Spencer's original addressing scheme)                   **
; **********************************************************************

; RC2014 type 2 serial SIO/2 initialise
;   On entry: No parameters required
;   On exit:  Z flagged if device is found and initialised
;             AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; If the device is found it is initialised
Z80_SIO_Initialise_T2:
; First look to see if the device is present
            IN   A,(kSIOAConT2) ;Read status (control) register A
            AND  kSIOMask1      ;Mask for known bits in control reg
            CP   kSIOTest1      ;Test value following masking
            RET  NZ             ;Return not found NZ flagged
            IN   A,(kSIOBConT2) ;Read status (control) register B
            AND  kSIOMask1      ;Mask for known bits in control reg
            CP   kSIOTest1      ;Test value following masking
            RET  NZ             ;Return not found NZ flagged
; Device present, so initialise 
            LD   C,kSIOAConT2   ;SIO/2 channel A control port
            CALL Z80_SIO_IniSend
            LD   C,kSIOBConT2   ;SIO/2 channel B control port
            JP   Z80_SIO_IniSend


; RC2014 type 2 serial SIO/2 channel A & B input character
;   On entry: No parameters required
;   On exit:  A = Character input from the device
;             NZ flagged if character input
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
Z80_SIOA_InputChar_T2:
            IN   A,(kSIOAConT2) ;Address of status register
            BIT  kSIORxRdy,A    ;Receive byte available
            RET  Z              ;Return Z if no character
            IN   A,(kSIOADatT2) ;Read data byte
            RET
Z80_SIOB_InputChar_T2:
            IN   A,(kSIOBConT2) ;Address of status register
            BIT  kSIORxRdy,A    ;Receive byte available
            RET  Z              ;Return Z if no character
            IN   A,(kSIOBDatT2) ;Read data byte
            RET


; RC2014 type 2 serial SIO/2 channel A & B output character
;   On entry: A = Character to be output to the device
;   On exit:  If character output successful (eg. device was ready)
;               NZ flagged and A != 0
;             If character output failed (eg. device busy)
;               Z flagged and A = Character to output
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
Z80_SIOA_OutputChar_T2:
            PUSH BC
            LD   C,kSIOAConT2   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            POP  BC
            RET  Z              ;Return Z as character not output
            OUT  (kSIOADatT2),A ;Write data byte
            OR   0xFF           ;Return success A=0xFF and NZ flagged
            RET
Z80_SIOB_OutputChar_T2:
            PUSH BC
            LD   C,kSIOBConT2   ;SIO control register
            IN   B,(C)          ;Read SIO control register
            BIT  kSIOTxRdy,B    ;Transmit register full?
            POP  BC
            RET  Z              ;Return Z as character not output
            OUT  (kSIOBDatT2),A ;Write data byte
            OR   0xFF           ;Return success A=0xFF and NZ flagged
            RET


; Z80 SIO type 2 get control port address for channel A or B
;   On entry: C = Port number (0=A, 1=B)
;   On exit:  C = Control port address
;             AF = Not specified
;             B DE HL IX IY I AF' BC' DE' HL' preserved
Z80_SIO_GetCtrlPort_T2:
            LD   A,kSIOAConT2   ;RC2014 std addressing control port A
            BIT  0,C            ;Port B?
            JR   Z,@Skip        ;No, so skip
            LD   A,kSIOBConT2   ;RC2014 std addressing control port B
@Skip:      LD   C,A            ;Get port's control register address
            RET


; **********************************************************************
; **  Private functions                                               **
; **********************************************************************


; Z80 SIO initialisation
;   On entry: C = Control register address
;   On exit:  DE IX IY I AF' BC' DE' HL' preserved
; Send initialisation data to specified channel
Z80_SIO_IniSend:
SIO_Set64:  LD   HL,SIO_Data64  ;Point to initialisation data
            JR   SIO_Init
SIO_Set16:  LD   HL,SIO_Data16  ;Point to initialisation data
SIO_Init:
;           Old code: C = Device number (0 or 1, for SIO A or B)
;           LD   A,kSIOAConT1   ;Get SIO control reg base address
;           ADD  A,C            ;Add console device number (0 or 1)
;           LD   C,A            ;Store SIO channel register address
            LD   B,SIO_Data64End-SIO_Data64 ;Length of init data
            OTIR                ;Write data to output port C
            RET
; SIO channel initialisation data
SIO_Data64: .DB  0b00011000     ; Wr0 Channel reset
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
SIO_Data64End:
SIO_Data16: .DB  0b00011000     ; Wr0 Channel reset
;           .DB  0b00000010     ; Wr0 Pointer R2
;           .DB  0x00           ; Wr2 Int vector
            .DB  0b00010100     ; Wr0 Pointer R4 + reset ex st int
            .DB  0b01000100     ; Wr4 /16, async mode, no parity
            .DB  0b00000011     ; Wr0 Pointer R3
            .DB  0b11000001     ; Wr3 Receive enable, 8 bit 
            .DB  0b00000101     ; Wr0 Pointer R5
;           .DB  0b01101000     ; Wr5 Transmit enable, 8 bit 
            .DB  0b11101010     ; Wr5 Transmit enable, 8 bit, flow ctrl
            .DB  0b00010001     ; Wr0 Pointer R1 + reset ex st int
            .DB  0b00000000     ; Wr1 No Tx interrupts


; **********************************************************************
; **  End of driver: Z80_SIO                                          **
; **********************************************************************




; **********************************************************************
; **  DS1216C Utility                               by Antony Briggs  **
; **********************************************************************


            .PROC Z80           ;SCWorkshop select processor

Location:   .EQU 0x001B         ;unused address in low ROM space

            .ORG 0x8000         ;This needs to run from upper bank
                                ;Or else the pattern will be interrupted
                                ;By Z80 instruction reads
Start:
            LD   HL,Location    ;Any RAM location mapped to the appropriate chip will do
            JR   @ReadTime      ;Comment this out to set date/time

@SetTime:
            LD   A,(HL)                 ;Start with a RAM Read

            LD   DE,@Pattern            ;Address of pattern data
            LD   B,@PatternEnd-@Pattern ;Length of pattern data
            CALL @WriteData             ;Write it out

            ; DS1216 should have found a match now

            ; Set time (and enable osc)
            LD   DE,@DSData             ;Address of data
            LD   B,@DSDataEnd-@DSData   ;Length of data to write
            CALL @WriteData             ;Write it out

@ReadTime:
            LD   A,(HL)                 ;Start with a RAM Read

            LD   DE,@Pattern            ;Address of pattern data
            LD   B,@PatternEnd-@Pattern ;Length of pattern data
            CALL @WriteData             ;Write it out

            ; DS1216 should have found a match now

            ; Read back
            LD   DE,@DSData             ;Buffer for data
            LD   B,@DSDataEnd-@DSData   ;Length of data to read
            CALL @ReadData              ;Write it out

@End:
            LD   DE,@Msg        ;Message
            LD   C,6            ;API 6
            RST  0x30           ;  = Output message at DE
            RET

; HL = Location to write
; DE = data to write
; B = length of data
@WriteData:            
@OuterLoop:
            LD   A,(DE)         ; Read data value
@InnerLoop:
            LD   (HL),A         ;Write value (only bit0 matters)
            RRA                 ;Rotate to bit 1
            LD   (HL),A         ;Write value (only bit0 matters)
            RRA                 ;Rotate to bit 2
            LD   (HL),A         ;Write value (only bit0 matters)
            RRA                 ;Rotate to bit 3
            LD   (HL),A         ;Write value (only bit0 matters)
            RRA                 ;Rotate to bit 4
            LD   (HL),A         ;Write value (only bit0 matters)
            RRA                 ;Rotate to bit 5
            LD   (HL),A         ;Write value (only bit0 matters)
            RRA                 ;Rotate to bit 6
            LD   (HL),A         ;Write value (only bit0 matters)
            RRA                 ;Rotate to bit 7
            LD   (HL),A         ;Write value (only bit0 matters)

            INC  DE             ;next byte in pattern
            DJNZ @OuterLoop
            RET

; HL = Location to write
; DE = data to write
; B = length of data
@ReadData:
            LD   C,B            ;Move byte count to C
@OuterReadLoop:
            LD   A,0            ;clear accumulator
            LD   B,8            ;Read 8 bits
@InnerReadLoop:
            RRA                 ;Rotate bits right (only need to do this 7 times, not 8!)
            BIT 0, (HL)         ;Read value (only bit0 matters)
            JR  Z,@Skip         ;Zero?
            SET 7,A             ;Set bit 7
@Skip:
            DJNZ @InnerReadLoop

            LD  (DE), a         ;Save data byte
            INC DE              ;Next location in read buffer
            DEC C               
            JR NZ,@OuterReadLoop ;loop until c is zero
            RET

@Msg:      .DB  "Finished",0x0D,0x0A,0

;  SmartWatch Comparison Register Definition 
@Pattern:   .DB  0xC5
            .DB  0x3A
            .DB  0xA3
            .DB  0x5C
            .DB  0xC5
            .DB  0x3A
            .DB  0xA3
            .DB  0x5C
@PatternEnd:

@ID:        .DB  0x55,0xAA  ; Pattern to look for in memory dump

; Data Buffer
; Initial values here can be written to set date/time/osc enable
@DSData:    .DB  0x01   ; 0.1 sec      | 0.01 sec (00-99)
            .DB  0x00   ; 10 sec       | seconds = (00-59)
            .DB  0x30   ; 10 mins      | mins = (00-59)
            .DB  0x15   ; bit 7 = 24 hour mode (0), bits 5,4 = 10 hours | hours (00-23) = 0 
            .DB  0x14   ; OSC=0, RST=1 | Day = (1-7)
            .DB  0x14   ; 10 date      | date = (01-31)
            .DB  0x03   ; 10 month     | month = (01-12)
            .DB  0x14   ; 10 year      | year = (00-99)
@DSDataEnd:








; **********************************************************************
; **  DS1216C Utility                           by Stephen C Cousins  **
; **********************************************************************


            .PROC Z80           ;SCWorkshop select processor

Location:   .EQU 0x001B         ;unused address in low ROM space

            .ORG 0x8000         ;This needs to run from upper bank
                                ;Or else the pattern will be interrupted
                                ;By Z80 instruction reads
Start:
            LD   HL,Location
            LD   DE,@Pattern
            LD   B,@PatternEnd-@Pattern ;Length of pattern data
            LD   A,(HL)        ;Start with a RAM Read
@OuterLop:
            LD   A,(DE)         ; Read pattern value
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
            DJNZ @OuterLop

            ; DS1216 should have found a match now, time to read data

            LD   DE,@DSData     ;Buffer for data
            LD   C,@DSDataEnd-@DSData ;Length of data to read
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

@End:
            LD   DE,@Msg        ;Pass message
            LD   C,6            ;API 6
            RST  0x30           ;  = Output message at DE
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

@DSData:    .DB  0x00
            .DB  0x00
            .DB  0x00
            .DB  0x00
            .DB  0x00
            .DB  0x00
            .DB  0x00
            .DB  0x00
@DSDataEnd:








; **********************************************************************
; **  Memory test for RC2014 etc                by Stephen C Cousins  **
; **********************************************************************

; Lower 32K memory test:
; The ROM is paged out so there is RAM from 0x0000 to 0x7FFF
; This RAM is then tested
; If a failure is found the faulty address is stored at <result>
; otherwise <result> contains 0x8000
;
; Upper 32K memory test:
; If a failure is found the faulty address is stored at <result>
; otherwise <result> contains 0x0000


            .PROC Z80           ;SCWorkshop select processor

Result:     .EQU 0x8070
Start:      .EQU 0x4000

            .ORG 0x8000


Test:       

; Test writing to two banks quickly

            LD   HL,Start      ;Start location
            LD   C, 0x16

@Upper:     
            LD   A, 0x55         
            LD   B, 0x00
            OUT  (C),B       ; Bank 0
            LD   (HL),A         ;Write test pattern

            LD   A, 0xAA
            LD   B, 0x10
            OUT  (C),B       ; Bank 1
            LD   (HL),A         ;Write test pattern

            LD   A, 0x55         
            LD   B, 0x00
            OUT  (C),B       ; Bank 0
            CP   (HL)           ;Read back and compare
            JR   NZ,@HiEnd      ;Abort if not the same

            LD   A, 0xAA
            LD   B, 0x10
            OUT  (C),B       ; Bank 1
            CP   (HL)           ;Read back and compare
            JR   NZ,@HiEnd      ;Abort if not the same

            INC  HL             ;Point to next location
            LD   A,H
            CP   0x7f           ;Have we finished?
            JR   NZ,@Upper

@HiEnd:     LD   (Result),HL    ;Store current address
            LD   A,H
            CP   0x7f           ;Pass?
            JR   NZ,@Failed     ;No, so go report failure


            LD   A, 0xF0
            OUT  (0x16),A       ; Bank F

            LD   DE,@Pass       ;Pass message
            LD   C,6            ;API 6
            RST  0x30           ;  = Output message at DE

            LD   C,3            ;API 3
            RST  0x30           ;  = Test for input character
            JR   Z,Test         ;None, so repeat test

            LD   C,1            ;API 1
            RST  0x30           ;  = Input character (flush it)

            LD   C,7            ;API 7
            RST  0x30           ;  = Output new line

            RET

@Failed:    LD   A, 0xF0
            OUT  (0x16),A       ; Bank F

            LD   DE,@Fail       ;Fail message
            LD   C,6            ;API 6
            RST  0x30           ;  = Output message at DE
            RET

@Pass:      .DB  "Pass ",0
@Fail:      .DB  "Fail",0x0D,0x0A,0

BeginTest:  ; Upper memory test begins here









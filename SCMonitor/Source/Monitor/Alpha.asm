; **********************************************************************
; **  Alpha module                              by Stephen C Cousins  **
; **********************************************************************

; This module provides the following:
;   Defines the memory map (except kCode and kData)
;   Reset code / Cold start command line interpreter
;   Warm start command line interpreter
;
; Public functions provided:
;   ColdStart             Cold start monitor
;   WarmStart             Warm start monitor
;   InitJumps             Initialise jump table with vector list
;   ClaimJump             Claim jump table entry
;   ReadJump              Read jump table entry
;   MemAPI                Call API with parameters in RAM
;   SelConDev             Select console in/out device
;   SelConDevI            Select console input device
;   SelConDevO            Select console output device
;   DevInput              Input from specified console device
;   DevOutput             Output to specified console device
;   Delay                 Delay by sepecified number of millseconds
;   GetConDev             Get current console device numbers
;   GetMemTop             Get top of free memory
;   SetMemTop             Set top of free memory
;   GetVersion            Get version and configuration details
;   OutputMessage         Output specified embedded message
;   SetBaud               Set baud rate for console devices
;   SysReset              System reset


; **********************************************************************
; **  Constants                                                       **
; **********************************************************************

; Memory map (ROM or RAM)
Reset:      .EQU 0x0000         ;Z80 reset location

; Memory map (RAM)
; 0xFC00 to 0xFCBF  User stack
; 0xFCC0 to 0xFCFF  System stack
; 0xFD00 to 0xFD7F  Line input buffer
; 0xFD80 to 0xFDFF  String buffer
; 0xFE00 to 0xFE5F  Jump table
; 0xFE60 to 0xFEFF  Workspace (currently using to about 0xFEAF)
; 0xFF00 to 0xFFFF  Pass info between apps and memory banks:
; 0xFF00 to 0xFF7F    Transient data area
; 0xFF80 to 0xFFEF    Transient code area
; 0xFFD0 to 0xFFDF    ROMFS file info block 2
; 0xFFE0 to 0xFFEF    ROMFS file info block 1
; 0xFFF0 to 0xFFFF    System variables
kSPUsr:     .EQU kData+0x00C0   ;Top of stack for user program
kSPSys:     .EQU kData+0x0100   ;Top of stack for system
kInputBuff: .EQU kData+0x0100   ;Line input buffer start    (to +0x017F)
kInputSize: .EQU 128            ;Size of input buffer
kStrBuffer: .EQU kData+0x0180   ;String buffer              (to +0x01FF)
kStrSize:   .EQU 128            ;Size of string buffer
kJumpTab:   .EQU kData+0x0200   ;Redirection jump table     (to +0x025F)
;kWorkspace:                    .EQU kData+0x0260;Space for data & variables (to +0x02FF)
; Pass information between apps and memory banks 0xFF00 to 0xFFFF
kPassData   .EQU 0xFF00         ;0xFF00 to 0xFF7F Transient data area
kPassCode:  .EQU 0xFF80         ;0xFF80 to 0xFFEF Transient code area
kPassInfo:  .EQU 0xFFF0         ;0xFFF0 to 0xFFFF Variable passing area
kPassCtrl:  .EQU kPassInfo+0x00 ;Pass control / paging information
kPassAF:    .EQU kPassInfo+0x02 ;Pass AF to/from API
kPassBC:    .EQU kPassInfo+0x04 ;Pass BC to/from API
kPassDE:    .EQU kPassInfo+0x06 ;Pass DE to/from API
kPassHL:    .EQU kPassInfo+0x08 ;Pass HL --/from API
kPassDevI:  .EQU kPassInfo+0x0A ;Pass current input device
kPassDevO:  .EQU kPassInfo+0x0B ;Pass current output device


; Common constants
kNull       .EQU 0              ;Null character/byte (0x00)
kNewLine    .EQU 5              ;New line character (0x05)
kBackspace: .EQU 8              ;Backspace character (0x08)
kLinefeed:  .EQU 10             ;Line feed character (0x0A)
kReturn:    .EQU 13             ;Return character (0x0D)
kEscape:    .EQU 27             ;Escape character (0x1B)
kSpace:     .EQU 32             ;Space character (0x20)
kApostroph: .EQU 39             ;Apostrophe character (0x27)
kComma:     .EQU 44             ;Comma character (0x2C)
kPeriod:    .EQU 46             ;Period character (0x2E)
kColon:     .EQU 58             ;Colon character (0x3A)
kSemicolon: .EQU 59             ;Semicolon character (0x3B)
kDelete:    .EQU 127            ;Delete character (0x7F)

; The jump table contains a number of "JP nn" instructions which are
; used to redirect functions. Each entry in the table takes 3 bytes.
; The jump table is created in RAM on cold start of the monitor.
; Jump table constants - jump number (0 to n)
kFnNMI:     .EQU 0x00           ;Fn 0x00: non-maskable interrupt handler
kFnRST08:   .EQU 0x01           ;Fn 0x01: restart 08 handler
kFnRST10:   .EQU 0x02           ;Fn 0x02: restart 10 handler
kFnRST18:   .EQU 0x03           ;Fn 0x03: restart 18 handler
kFnRST20:   .EQU 0x04           ;Fn 0x04: restart 20 handler
kFnRST28:   .EQU 0x05           ;Fn 0x05: restart 18 breakpoint
kFnRST30:   .EQU 0x06           ;Fn 0x06: restart 30 API handler
kFnINT:     .EQU 0x07           ;Fn 0x07: restart 38 interrupt handler
kFnConIn:   .EQU 0x08           ;Fn 0x08: console input character
kFnConOut:  .EQU 0x09           ;Fn 0x09: console output character
;FnConISta: .EQU 0x0A           ;Fn 0x0A: console get input status
;FnConOSta: .EQU 0x0B           ;Fn 0x0B: console get output status
kFnIdle:    .EQU 0x0C           ;Fn 0x0C: Jump to idle handler
kFnTimer1:  .EQU 0x0D           ;Fn 0x0D: Jump to timer 1 handler
kFnTimer2:  .EQU 0x0E           ;Fn 0x0E: Jump to timer 2 handler
kFnTimer3:  .EQU 0x0F           ;Fn 0x0F: Jump to timer 3 handler
;FnDevN:    .EQU 0x10           ;Fn 0x10: device 1 to n input & output
kFnDev1In:  .EQU 0x10           ;Fn 0x10: device 1 input
kFnDev1Out: .EQU 0x11           ;Fn 0x11: device 1 output
;kFnDev2In: .EQU 0x12           ;Fn 0x12: device 2 input
;FnDev2Out: .EQU 0x13           ;Fn 0x13: device 2 output
kFnDev3In:  .EQU 0x14           ;Fn 0x14: device 3 input
;FnDev3Out: .EQU 0x15           ;Fn 0x15: device 3 output
;FnDev4In:  .EQU 0x16           ;Fn 0x16: device 4 input
;FnDev4Out: .EQU 0x17           ;Fn 0x17: device 4 output
;FnDev5In:  .EQU 0x18           ;Fn 0x18: device 5 input
;FnDev5Out: .EQU 0x19           ;Fn 0x19: device 5 output
kFnDev6In:  .EQU 0x1A           ;Fn 0x1A: device 6 input
;FnDev6Out: .EQU 0x1B           ;Fn 0x1B: device 6 output

; Message numbers
kMsgNull:   .EQU 0              ;Null message
kMsgProdID: .EQU 1              ;Product identifier
kMsgDevice: .EQU 2              ;="Devices:"
kMsgAbout:  .EQU 3              ;About SCMonitor inc version
kMsgDevLst: .EQU 4              ;Device list
kMsgLstSys: .EQU 4              ;Last system message number

; Page zero use 
; SCMonitor: page zero can be in RAM or ROM
; CP/M: page zero must be in RAM
; <Address>   <Z80 function>   <Monitor>   <CP/M 2>
; 0000-0002   RST 00 / Reset   Cold start  Warm boot
; 0003-0004                    Warm start  IOBYTE / drive & user
; 0005-0007                    As CP/M     FDOS entry point
; 0008-000B   RST 08           Char out    Not used
; 000C-000F                    CstartOld   Not used
; 0010-0013   RST 10           Char in     Not used
; 0014-0017                    WstartOld   Not used
; 0018-001F   RST 18           In status   Not used
; 0020-0027   RST 20           Not used    Not used
; 0028-002F   RST 28           Breakpoint  Debugging
; 0030-0037   RST 30           API entry   Not used
; 0038-003F   RST 38 / INT     Interrupt   Interrupt mode 1 handler
; 0040-005B                    Options     Not used
; 005C-007F                    As CP/M     Default FCB
; 0066-0068   NMI              or Non-maskable interrupt (NMI) handler
; 0080-00FF                    As CP/M     Default DMA


; **********************************************************************
; **  Initialise memory sections                                      **
; **********************************************************************

; Initialise data section
            .DATA

            .ORG  kData

            .ORG kJumpTab

JpNMI:      JP   0              ;Fn 0x00: Jump to non-maskable interrupt
JpRST08:    JP   0              ;Fn 0x01: Jump to restart 08 handler
JpRST10:    JP   0              ;Fn 0x02: Jump to restart 10 handler
JpRST18:    JP   0              ;Fn 0x03: Jump to restart 18 handler
JpRST20:    JP   0              ;Fn 0x04: Jump to restart 20 handler
JpBP:       JP   0              ;Fn 0x05: Jump to restart 28 breakpoint
JpAPI:      JP   0              ;Fn 0x06: Jump to restart 30 API handler
JpINT:      JP   0              ;Fn 0x07: Jump to restart 38 interrupt handler
JpConIn:    JP   0              ;Fn 0x08: Jump to console input character
JpConOut:   JP   0              ;Fn 0x09: Jump to console output character
            JP   0              ;Fn 0x0A: Jump to console get input status
            JP   0              ;Fn 0x0B: Jump to console get output status
JpIdle:     JP   0              ;Fn 0x0C: Jump to idle handler
JpTimer1:   JP   0              ;Fn 0x0D: Jump to timer 1 handler
JpTimer2:   JP   0              ;Fn 0x0E: Jump to timer 2 handler
JpTimer3:   JP   0              ;Fn 0x0F: Jump to timer 3 handler
            ;Fn 0x10: Start of console device jumps
            JP   0              ;Jump to device 1 input character
            JP   0              ;Jump to device 1 output character
            JP   0              ;Jump to device 2 input character
            JP   0              ;Jump to device 2 output character
            JP   0              ;Jump to device 3 input character
            JP   0              ;Jump to device 3 output character
            JP   0              ;Jump to device 4 input character
            JP   0              ;Jump to device 4 output character
            JP   0              ;Jump to device 5 input character
            JP   0              ;Jump to device 5 output character
            JP   0              ;Jump to device 6 input character
            JP   0              ;Jump to device 6 output character

            .DS   12            ;Workspace starts at kJumpTab + 0x60
;           .ORG  kWorkspace

; Initialise code section
            .CODE
            .ORG  kCode


; **********************************************************************
; **  Page zero default vectors etc, copied to RAM if appropriate     **
; **********************************************************************

; Reset / power up here
Page0Strt:
ColdStart:  JP   ColdStrt       ;0x0000  CP/M 2 Warm boot
WarmStart:  JR   WStrt          ;0x0003  CP/M 2 IOBYTE / drive & user
            JP   FDOS           ;0x0005  CP/M 2 FDOS entry point
            JP   JpRST08        ;0x0008  RST 08 Console character out
            .DB  0              ;0x000B
            JP   ColdStrt       ;0x000C  Cold start (unofficial entry)
            .DB  0              ;0x000F
            JP   JpRST10        ;0x0010  RST 10 Console character in
            .DB  0              ;0x0013
WStrt:      JP   WarmStrt       ;0x0014  Warm start (unofficial entry)
            .DB  0              ;0x0017
            JP   JpRST18        ;0x0018  RST 18 Console input status
            .DB  0,0,0,0,0      ;0x001B
            JP   JpRST20        ;0x0020  RST 20 Not used
            .DB  0,0,0,0,0      ;0x0023
            JP   JpBP           ;0x0028  RST 28 Our debugging breakpoint
            .DB  0,0,0,0,0      ;0x002B         and CP/M debugging tools
            JP   JpAPI          ;0x0030  RST 30 API entry point
            .DB  0              ;0x0033         parameters in registers
            JP   MemAPI         ;0x0034  API call with
            .DB  0              ;0x0037         parameters in memory 
            JP   JpINT          ;0x0038  RST 38 Interrupt mode 1 handler
            .DB  0,0,0,0,0      ;0x003B
kaConDev:   .DB  kConDef        ;0x0040  Default console device (1 to 6)
kaBaud1Def: .DB  kBaud1Def      ;0x0041  Default device 1 baud rate
kaBaud2Def: .DB  kBaud2Def      ;0x0042  Default device 2 baud rate
            .DB  0              ;0x0043  Not used
            .DW  0,0            ;0x0044  Not used
            .DW  0,0,0,0        ;0x0048  Not used
            .DW  0,0,0,0        ;0x0050  Not used
            .DW  0,0            ;0x0058  Not used
            .DW  0,0            ;0x005C  CP/M 2 Default FCB
            .DW  0,0,0          ;0x0060         from 0x005C to 0x007F
            JP   JpNMI          ;0x0066  Non-maskable interrupt handler
Page0End:


; **********************************************************************
; **  Jump table defaults to be copied to RAM                         **
; **********************************************************************

JumpStrt:   JP   TrapNMI        ;Fn 0x00: non-maskable interrupt
            JP   OutputChar     ;Fn 0x01: restart 08 output character
            JP   InputChar      ;Fn 0x02: restart 10 input character
            JP   InputStatus    ;Fn 0x03: restart 18 get input status
            JP   TrapCALL       ;Fn 0x04: restart 20 handler
            JP   BPHandler      ;Fn 0x05: restart 28 breakpoint handler
            JP   APIHandler     ;Fn 0x06: restart 30 API handler
            JP   TrapINT        ;Fn 0x07: restart 38 interrupt handler
            JP   TrapCALL       ;Fn 0x08: console input character
            JP   TrapCALL       ;Fn 0x09: console output character
            JP   TrapCALL       ;Fn 0x0A: console get input status
            JP   TrapCALL       ;Fn 0x0B: console get output status
            JP   TrapCALL       ;Fn 0x0C: Jump to idle handler
            JP   TrapCALL       ;Fn 0x0D: Jump to timer 1 handler
            JP   TrapCALL       ;Fn 0x0E: Jump to timer 2 handler
            JP   TrapCALL       ;Fn 0x0F: Jump to timer 3 handler
            JP   DevNoIn        ;Fn 0x10: Device 1 input character
            JP   DevNoOut       ;Fn 0x11: Device 1 output character
            JP   DevNoIn        ;Fn 0x10: Device 2 input character
            JP   DevNoOut       ;Fn 0x11: Device 2 output character
            JP   DevNoIn        ;Fn 0x10: Device 3 input character
            JP   DevNoOut       ;Fn 0x11: Device 3 output character
            JP   DevNoIn        ;Fn 0x10: Device 4 input character
            JP   DevNoOut       ;Fn 0x11: Device 4 output character
            JP   DevNoIn        ;Fn 0x10: Device 5 input character
            JP   DevNoOut       ;Fn 0x11: Device 5 output character
            JP   DevNoIn        ;Fn 0x10: Device 6 input character
            JP   DevNoOut       ;Fn 0x11: Device 6 output character
JumpEnd:


; **********************************************************************
; **  Reset code                                                      **
; **********************************************************************

; Cold start Command Line Interpreter
ColdStrt:   DI                  ;Disable interrupts
            LD   SP,kSPSys      ;Initialise system stack pointer
; Self test included?
#IFDEF      IncludeSelftest
; This indicates status on the default output port (LEDs)
; At the end of a sucessful self test the default output port is cleared 
; to zero, otherwise the default output port indicates the failure
#IF         BUILD = "R1"
            ; Need to init the PII in RAM as it will enable outputs on PORT C (And other ports)
            ; And the weak pullup boot bank selection will be overwritten
            ; Copy the code to a high ish address (0xA00)  so it can run from ROM or RAM
            ; COPY ROUTINE TO UPPER RAM
            LD	HL,PII_Initialise
            LD	DE,$F000
            LD	BC,PII_Initialise_SZ
            LDIR
        	CALL	$F000			; Init the PII/PIO
;
#INCLUDE    Monitor\Selftest.asm  ;Include self test functions
#DEFINE     CUSTOM_SELFTEST
#ENDIF
#IF         BUILD = "S2"
#INCLUDE    Hardware\SC_S2\Selftest.asm
#DEFINE     CUSTOM_SELFTEST
#ENDIF
#IFNDEF     CUSTOM_SELFTEST
#INCLUDE    Monitor\Selftest.asm  ;Include self test functions
#ENDIF
#ENDIF
; Copy vectors etc to page zero in case code is elsewhere
            ; LD   DE,0x0000      ;Copy vectors etc to here
            ; LD   HL,Page0Strt   ;Copy vectors etc from here
            ; LD   BC,Page0End-Page0Strt  ;Number of bytes to copy
            ; LDIR                ;Copy bytes
; Initialise jump table, other than console devices
            LD   DE,kJumpTab    ;Copy jump table to here
            LD   HL,JumpStrt    ;Copy jump table from here
            LD   BC,JumpEnd-JumpStrt  ;Number of bytes to copy
            LDIR                ;Copy bytes
; Initialise top of memory value
            LD   HL,kData-1     ;Top of free memory
            LD   (iMemTop),HL   ;Set top of free memory
; Initialise ports module for default I/O ports
; This will turn off all outputs at the default output port (LEDs)
            LD   A,kPrtOut      ;Default output port address
            CALL PrtOInit       ;Initialise output port
            LD   A,kPrtIn       ;Default input port address
            CALL PrtIInit       ;Initialise input port
; Initialise hardware and set up required jump table entries
; This may indicate an error at the default output port (LEDs)
            CALL Hardware_Initialise
; Initialise default console device to first physical device
            LD   A,(kaConDev)   ;Default device number
            CALL SelConDev      ;Select console device
; Initialise rest of system
            CALL ConInitialise  ;Initialise the console
#IFDEF      IncludeScripting
            CALL ScrInitialise  ;Initialise script language
#ENDIF
#IFDEF      IncludeRomFS
            CALL RomInitialise  ;Initialise ROM filing system
#ENDIF
; Output sign-on message
            CALL OutputNewLine  ;Output new line
            CALL OutputNewLine  ;Output new line
            LD   A,kMsgProdID   ;="Small Computer Monitor"
            CALL OutputMessage  ;Output message
            LD   A,'-'          ;="-"
            CALL OutputChar     ;Output character
            LD   A,kSpace       ;=" "
            CALL OutputChar     ;Output character
            LD   DE,szStartup   ;="<hardware>"
            CALL OutputZString  ;Output message at DE
            CALL OutputNewLine  ;Output new line
#IFNDEF     IncludeCommands
            CALL OutputNewLine  ;Output new line
            LD   A,kMsgAbout    ;="Small Computer Monitor ..."
            CALL OutputMessage  ;Output message A
            CALL OutputNewLine  ;Output new line
            LD   A,kMsgDevice   ;="Devices:"
            CALL OutputMessage  ;Output message A
            LD   A,kMsgDevLst   ;="<device list>"
            CALL OutputMessage  ;Output message A
#ENDIF

; Warm start Command Line Interpreter
WarmStrt:
            LD   SP,kSPSys      ;Initialise system stack pointer
#IFDEF      IncludeBreakpoint
            CALL BPInitialise   ;Initialise breakpoint module
#ENDIF
#IFDEF      IncludeCommands
            JP   CLILoop        ;Command Line Interpreter main loop
#ELSE
@Halt:      JR   @Halt          ;Halt here if no CLI
#ENDIF

; Trap unused entry points
#IFNDEF     IncludeAPI
API:
#ENDIF
#IFNDEF     IncludeFDOS
FDOS:
#ENDIF
#IFNDEF     IncludeBreakpoint
BPHandler:
#ENDIF
TrapCALL:   RET                 ;Return from entry point

; Trap unused mode 1 interrupt
TrapINT:    RETI                ;Return from interrupt

; Trap unused non-maskabler interrupt
TrapNMI:    RETN                ;Return from interrupt

; Default console device routines
DevNoIn:
DevNoOut:   XOR   A             ;Z flagged as no input or output
            RET                 ;Return have done nothing


; **********************************************************************
; **  Public functions                                                **
; **********************************************************************


; System: Initialise jump table entries
;   On entry: A = First jump table entry to initialise
;             B = Number of entries to be initialised
;             HL = Pointer to list of vectors
;   On exit:  C IX IY I AF' BC' DE' HL' preserved
InitJumps:  LD   E,(HL)         ;Get lo byte of vector
            INC  HL             ;Point to hi byte of vector
            LD   D,(HL)         ;Get lo byte of vector
            INC  HL             ;Point to next vector
            CALL ClaimJump      ;Claim jump table entry
            INC  A              ;Increment entry number
            DJNZ InitJumps      ;Repeat until done
            RET


; System: Claim system jump table entry
;   On entry: A = Entry number (0 to n)
;             DE = Address of function
;   On exit:  No parameters returned
;             AF BC DE HL IX IY I AF' BC' DE' HL' preserved
; Some system functions, such as console in and console out, are 
; redirected through a jump table. By claiming a jump table entry the
; function can be handled by any required code. This might allow
; swapping output to a different device, such as a printer.
ClaimJump:  PUSH AF
            PUSH BC
            PUSH HL
            LD   HL,kJumpTab    ;Start of jump table
            LD   B,0            ;Calculate offset and store in BC..
            LD   C,A            ;C = 3 times A..
            ADD  A              ;x2
            ADD  C              ;x3
            LD   C,A
            ADD  HL,BC          ;Find location in table...
; Write jump table entry to memory
            LD   (HL),0xC3      ;Store jump instruction
            INC  HL
            LD   (HL),E         ;Store routine address lo byte
            INC  HL
            LD   (HL),D         ;Store routine address hi byte
            POP  HL
            POP  BC
            POP  AF
            RET


; System: API call with parameters passed via memory
;   On entry: Memory locations kPassXX contain register values
;   On exit:  Memory locations kPassXX contain register values
MemAPI:     LD   HL,(kPassAF)   ;Get AF parameter from RAM
            PUSH HL             ;Pass AF parameter via stack
            POP  AF             ;Get AF parameter from stack
            LD   BC,(kPassBC)   ;Get BC parameter from RAM
            LD   DE,(kPassDE)   ;Get DE parameter from RAM
            LD   HL,(kPassHL)   ;Get HL parameter from RAM
            RST  0x30           ;Call API
            PUSH AF             ;Pass AF result via stack
            POP  HL             ;Get AF result from stack
            LD   (kPassAF),HL   ;Store AF result in RAM
            LD   (kPassHL),HL   ;Store HL result in RAM
            LD   (kPassDE),DE   ;Store DE result in RAM
            LD   (kPassBC),BC   ;Store BC result in RAM
            RET


; System: Read system jump table entry
;   On entry: A = Entry number (0 to n)
;   On exit:  DE = Address of function
;             AF BC HL IX IY I AF' BC' DE' HL' preserved
; Some system functions, such as console in and console out, are 
; redirected through a jump table. By claiming a jump table entry the
; function can be handled by any required code. This might allow
; swapping output to a different device, such as a printer.
ReadJump:   PUSH AF
            PUSH BC
            PUSH HL
            LD   HL,kJumpTab+1  ;Start of jump table + 1
            LD   B,0            ;Calculate offset and store in BC..
            LD   C,A            ;C = 3 times A..
            ADD  A              ;x2
            ADD  C              ;x3
            LD   C,A
            ADD  HL,BC          ;Find location in table...
; Write jump table entry to memory
            LD   E,(HL)         ;Store routine address lo byte
            INC  HL
            LD   D,(HL)         ;Store routine address hi byte
            POP  HL
            POP  BC
            POP  AF
            RET


; System: Select console device
;   On entry: A = New console device number (1 to n)
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
; The console device list starts at jump table entry kFnDevN.
; Each device has two entries: input and output
; SelConDev  = Select both input and output device
; SelConDevO = Select output device only
; SelConDevI = Select input device only
SelConDev:  CALL SelConDevI     ;Select console input device
;           JP   SelConDevO     ;Select console output device
; Select output device
SelConDevO: PUSH AF
            PUSH DE
            LD   (kPassDevO),A  ;Store output device number
            ADD  A,A            ;Double as two entries each
            ADD  kFnDev1Out-2   ;Function number for device zero
            CALL ReadJump       ;Read source entry
            LD   A,kFnConOut    ;Destination device entry number
            CALL ClaimJump      ;Write destination entry
            POP  DE
            POP  AF
            RET
; Select input device
SelConDevI: PUSH AF
            PUSH DE
            LD   (kPassDevI),A  ;Store input device number
            ADD  A,A            ;Double as two entries each
            ADD  kFnDev1In-2    ;Function number for device zero
            CALL ReadJump       ;Read source entry
            LD   A,kFnConIn     ;Destination device entry number
            CALL ClaimJump      ;Write destination entry
            POP  DE
            POP  AF
            RET


; System: Input from specified console device
;   On entry: E = Console device number (1 to n)
;   On exit:  A = Character input 9if there is one ready)
;             NZ flagged if character has been input
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
DevInput:   LD   A,E            ;Get console device number
            ADD  A,A            ;Double as two entries each
            ADD  kFnDev1In-2    ;Function number for device zero
            CALL ReadJump       ;Read table entry
            EX   DE,HL          ;Get routine address in HL
            JP   (HL)           ;Jump to input routine


; System: Output to specified console device
;   On entry: A = Character to be output
;             E = Console device number (1 to n)
;   On exit:  IX IY I AF' BC' DE' HL' preserved
DevOutput:  PUSH AF             ;Store character to be output
            LD   A,E            ;Get console device number
            ADD  A,A            ;Double as two entries each
            ADD  kFnDev1Out-2   ;Function number for device zero
            CALL ReadJump       ;Read table entry
            EX   DE,HL          ;Get routine address in HL
            POP  AF             ;Restore character to be output
            JP   (HL)           ;Jump to output routine


; System: Delay by specified number of millseconds
;   On entry: DE = Delay time in milliseconds
;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
; Clock =  1.0000 MHz,  1 ms =  1,000 TCy =  40 * 24 - 36 
; Clock =  4.0000 MHz,  1 ms =  4,000 TCy = 165 * 24 - 36
; Clock =  7.3728 MHz,  1 ms =  7,373 TCy = 306 * 24 - 36
; Clock = 12.0000 MHz,  1 ms = 12,000 TCy = 498 * 24 - 36
; Clock = 20.0000 MHz,  1 ms = 20,000 TCy = 831 * 24 - 36
Delay:      PUSH BC
            PUSH DE
; 1 ms loop, DE times... (overhead = 36 TCy)
@LoopDE:    LD   BC,kDelayCnt   ;[10]  Loop counter
; 26 TCy loop, BC times...
@LoopBC:    DEC  BC             ;[6]
            LD   A,C            ;[4]
            OR   B              ;[4]
            JP   NZ,@LoopBC     ;[10]
            DEC  DE             ;[6]
            LD   A,E            ;[4]
            OR   D              ;[4]
            JR   NZ,@LoopDE     ;[12/7]
            POP  DE
            POP  BC
            RET


; System: Get current console device numbers
;   On entry: No parameters required
;   On exit:  D = Current console output device number
;             E = Current console input device number
;   On exit:  AF BC HL IX IY I AF' BC' DE' HL' preserved
GetConDev:  LD   DE,(kPassDevI) ;Get console device numbers
            RET


; System: Get top of free memory
;   On entry: No parameters required
;   On exit:  DE = Top of free memory
;   On exit:  AF BC HL IX IY I AF' BC' DE' HL' preserved
GetMemTop:  LD   DE,(iMemTop)   ;Get top of free memory
            RET


; System: Set top of free memory
;   On entry: DE = Top of free memory
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
SetMemTop:  LD   (iMemTop),DE   ;Set top of free memory
            RET


; System: Get version details
;   On entry: No parameters required
;   On exit:  D,E and A = Monitor code version
;               D = kVersMajor
;               E = kVersMinor
;               A = kVersRevis(ion)
;             B,C = Configuration ID
;               B = kConfMajor ('R'=RC2014, 'L'=LiNC80, etc)
;               C = kConfMinor (sub-type '1', '2', etc)
;             H,L = Target hardware ID
;               H = kHardID (1=Simulator, 2=,SCDevKt, 3=RC2014, etc)
;               L = Hardware option flags (hardware specific)
;             IX IY I AF' BC' DE' HL' preserved
GetVersion:
            LD  H,kHardID       ;H = Hardware ID
            LD  A,(iHwFlags)    ;Get hardware option flags
            LD  L,A             ;L = Hardware option flags
            LD  B,kConfMajor    ;B = Major configuration
            LD  C,kConfMinor    ;C = Minor configuration 
            LD  D,kVersMajor    ;D = Major version number
            LD  E,kVersMinor    ;E = Minor version number
            LD  A,kVersRevis    ;A = Revision number
            RET


; System: Output message
;  On entry:  A = Message number (0 to n)
;   On exit:  BC DE HL IX IY I AF' BC' DE' HL' preserved
OutputMessage:
            OR   A              ;Null message?
            RET  Z              ;Yes, so abort
            PUSH DE             ;Preserve DE
            PUSH HL             ;Preserve HL
; Monitor message?
#IFDEF      IncludeMonitor
            CALL MonOutputMsg   ;Offer message number to monitor
            OR   A              ;Message still needs handling?
            JR   Z,@Exit        ;No, so exit
#ENDIF
; Add any other message generating modules here
; ...........
; System message?
            CP   kMsgLstSys+1   ;Valid system message number?
            JR   NC,@Exit       ;No, so abort
; About message?
            CP   kMsgAbout      ;About message?
            JR   NZ,@NotAbout   ;No, so skip
            LD   DE,szProduct   ;="Small Computer Monitor"
            CALL OutputZString  ;Output message at DE
            LD   DE,szAbout     ;="<about this configuration>"
            CALL OutputZString  ;Output message at DE
            CALL Hardware_Signon  ;Hardware signon message
            JR   @Exit
@NotAbout:
; Device list message?
            CP   kMsgDevLst     ;Device list message?
            JR   NZ,@NotDevLst  ;No, so skip
;           LD   DE,szDevices   ;="Devices:"
;           CALL OutputZString  ;Output message at DE
            CALL Hardware_Devices ;Output device list
            JR   @Exit
@NotDevLst:
; Other system message?
            LD   E,A            ;Get message number
            LD   D,0
            LD   HL,MsgTabSys   ;Get start of message table
            ADD  HL,DE          ;Calculate location in table
            ADD  HL,DE
            LD   A,(HL)         ;Get address from table...
            INC  HL
            LD   D,(HL)
            LD   E,A
            CALL OutputZString  ;Output message as DE
@Exit:      POP  HL             ;Restore HL
            POP  DE             ;Restore DE
            RET


; System: Set baud rate
;  On entry:  A = Device identifier (0x01 to 0x06, or 0x0A to 0x0B)
;             E = Baud rate code 
;   On exit:  IF successful: (ie. valid device and baud code)
;               A != 0 and NZ flagged
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
SetBaud:    CP   0x0A           ;Identifier is a hex letter?
            JR   C,@GotNum      ;No, so skip
            SUB  0x09           ;Convert 0x0A/B to 0x01/2
@GotNum:    LD   C,A            ;Get device identifier (0x01 to 0x06)
            LD   A,E            ;Get baud rate code
; Set baud rate for device C (1 to 6) to baud code A
            JP   Hardware_BaudSet ;Failure: A=0 and Z flagged


; System: System reset
;  On entry:  A = Reset type: 
;               0 = Cold start monitor
;               1 = Warm start monitor
;   On exit:  System resets
SysReset:   CP   0x01           ;Warm start monitor
            JP   Z,WarmStart    ;Yes, so warm start monitor
            RST  0              ;Cold start monitor


; **********************************************************************
; **  Constant data                                                   **
; **********************************************************************

; Message strings (zero terminated)
szNull:     .DB  kNull
szProduct:  .DB  "Small Computer Monitor ",kNull
szDevices:  .DB  "Devices detected:",kNewLine,kNull
szAbout:
            .DB  "by Stephen C Cousins (www.scc.me.uk)",kNewLine
            .DB  "Version "
            .DB  '0'+kVersMajor,'.'
            .DB  '0'+kVersMinor,'.'
            .DB  '0'+kVersRevis
            .DB  " configuration ",kConfMajor,kConfMinor
#IFDEF      SHOW_CONFIG_REVISION
            .DB  '.',kConfRevis
#ENDIF
            .DB  " for ",kNull
            .DB  kNull

; Message table
MsgTabSys:  .DW  szNull
            .DW  szProduct
            .DW  szDevices
;           .DW  szAbout        ;Handled in code
;           .DW  szDevList      ;Handled in code 


; **********************************************************************
; **  Private workspace (in RAM)                                      **
; **********************************************************************

            .DATA

iMemTop:    .DW  0              ;Top of free memory address

; **********************************************************************
; **  End of Alpha module                                             **
; **********************************************************************


















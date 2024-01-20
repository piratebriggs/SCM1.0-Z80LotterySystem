; **********************************************************************
; **  String support                            by Stephen C Cousins  **
; **********************************************************************

; This module provides a group of functions to handle strings. Strings
; are build in buffers using various functions, such as StrWrChar,
; which writes the specified character to the end of the currently 
; selected string. The string can then be 'printed' to the current 
; output device with the StrPrint function.
;
; Ensure StrInitialise or StrInitDefault is called before any other 
; string function as these finctions select and initialise a string 
; buffer.
;
; Strings are stored in buffers where the first byte of the buffer
; contains the string length. A value of zero therefore indicates
; an empty (or null) string. 
;
; Public functions provided
;   StrAppend             Append specified string to current buffer
;   StrAppendZ            Append specified zero terminated string
;   StrClear              Clear the current string buffer
;   StrConvUpper          Convert string to upper case
;   StrCopyToZ            Copy to zero (null) terminated string
;   StrGetLength          Get length of string in current string buffer
;   StrInitDefault        Initialise and select the default buffer
;   StrInitialise         Initialise default or supplied string buffer
;   StrPrint              Print string in current string buffer
;   StrPrintDE            Print string in string buffer at DE
;   StrWrAddress          Write address, colon, space to buffer
;   StrWrAsciiChar        Write ascii character to string buffer
;   StrWrBackspace        Write backspace to string buffer
;   StrWrBinaryByte       Write binary byte to string buffer
;   StrWrBinaryWord       TODO write binary byte
;   StrWrChar             Write character to string buffer
;   StrWrDecByte          TODO write decimal byte
;   StrWrDecWord          TODO write decimal word
;   StrWrHexByte          Write byte to buffer as 2 hex characters
;   StrWrHexNibble        Write nibble to buffer as 1 hex character
;   StrWrHexWord          Write word to buffer as 4 hex characters
;   StrWrNewLine          Write new line to string buffer
;   StrWrPadding          Write padding (spaces) to specified length
;   StrWrSpace            Write space character to string buffer
;   StrWrSpaces           Write specified spaces to string buffer
; Unless otherwise stated these functions have no return values and 
; preserved the registers: AF BC DE HL IX IY I AF' BC' DE' HL'


; **********************************************************************
; **  Public functions                                                **
; **********************************************************************

            .CODE

; String: Append specified string to current string buffer
;   On entry: DE = Start of string to be appended
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrAppend:
            PUSH AF
            PUSH BC
            PUSH DE
            LD   A,(DE)         ;Get length of specified string
            OR   A              ;Null string?
            JR   Z,@Done        ;Yes, so we're done
            LD   B,A            ;Store length of string
@Next:      INC  DE             ;Point to next character to append
            LD   A,(DE)         ;Get character from specified string
            CALL StrWrChar      ;Write character to current string
            DJNZ @Next          ;Loop back if more character
@Done:      POP  DE
            POP  BC
            POP  AF
            RET


; String: Append specified zero (null) terminated string
;   On entry: DE = Start of string to be appended
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
; Appends specified zero (null) terminated string to current string 
; buffer. The string does not have the usual length prefix but 
; instead is terminated with a zero (null).
StrAppendZ:
            PUSH AF
            PUSH DE
@Next:      LD   A,(DE)         ;Get length of specified string
            OR   A              ;Null string?
            JR   Z,@Done        ;Yes, so we're done
            CALL StrWrChar      ;Write character to current string
            INC  DE             ;Point to next character
            JR   @Next          ;Loop back if more character
@Done:      POP  DE
            POP  AF
            RET


; String: Clear string in current string buffer
;   On entry: No parameters required
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrClear:
            PUSH HL
            LD   HL,(iStrStart) ;Get start of current string buffer
            LD   (HL),0         ;Initialise string with length zero
            POP  HL
            RET


; String: Convert string to upper case
;   On entry: No parameters required
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrConvUpper:
            PUSH AF
            PUSH HL
            LD   HL,(iStrStart) ;Get start of current string buffer
            LD   A,(HL)         ;Get length of string
            OR   A              ;Null string?
            JR   Z,@Done        ;Yes, so we're done here
            PUSH BC
            LD   B,A            ;Store length of string
@Loop:      INC  HL             ;Point to next character in string
            LD   A,(HL)         ;Get character from string
            CALL ConvertCharToUCase
            LD   (HL),A         ;Write upper case char to string
            DJNZ @Loop          ;Loop until end of string
            POP  BC
@Done:      POP  HL
            POP  AF
            RET


; String: Copy to zero (null) terminated string
;   On entry: DE = Location to store Z string
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrCopyToZ:
            PUSH AF
            PUSH DE
            PUSH HL
            LD   HL,(iStrStart) ;Get start of current string buffer
            LD   A,(HL)         ;Get length of string
            OR   A              ;Null string?
            JR   Z,@Done        ;Yes, so we're done here
            INC  HL             ;Point to first character in string
            PUSH BC
            LD   C,A            ;Store length of string
            LD   B,0
            LDIR                ;Copy string from HL to DE
            POP  BC
@Done:      XOR  A
            LD   (DE),A         ;Terminate string with null
            POP  HL
            POP  DE
            POP  AF
            RET


; String: Get length of string in current string buffer
;   On entry: No parameters required
;   On exit:  A = Length in characters
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
StrGetLength:
            PUSH HL
            LD   HL,(iStrStart) ;Get start of current string buffer
            LD   A,(HL)         ;Get length of string in buffer
            POP  HL
            RET


; String: Initialise and select default string buffer
;   On entry: No parameters required
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrInitDefault:
            PUSH AF
            XOR  A              ;Select default string buffer (0)
            CALL StrInitialise  ;Select and initialise buffer
            POP  AF
            RET


; String: Initialise default or supplied string buffer
;   On entry: A = Size of buffer or zero to restore defaults
;             DE = Start address of string buffer
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
; Size includes the string's length byte so needs to be one byte
; longer than the largest string it can hold.
StrInitialise:
            PUSH AF
            PUSH DE
            OR   A              ;Buffer length zero?
            JR   NZ,@Init       ;No, so go use supplied values
            LD   DE,kStrBuffer  ;Get start of default buffer
            LD   A,kStrSize     ;Get size of default buffer
@Init:      LD   (iStrStart),DE ;Store start of string buffer
            LD   (iStrSize),A   ;Store size of string buffer
            XOR  A              ;Prepare for length zero
            LD   (DE),A         ;Initialise string with length zero
            POP  DE
            POP  AF
            RET


; String: Print string in current string buffer
;   On entry: No parameters required
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
; The string is printed to the current output device
; Supports \n for new line
StrPrint:
            PUSH DE
            LD   DE,(iStrStart) ;Get start of current string buffer
            CALL StrPrintDE     ;Print string at DE
@Done:      POP  DE
            RET


; String: Print string in current string buffer
;   On entry: DE = Address of string
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
; The string is printed to the current output device
StrPrintDE:
            PUSH AF
            PUSH BC
            PUSH DE
            LD   A,(DE)         ;Get length of specified string
            OR   A              ;Null string?
            JR   Z,@Done        ;Yes, so we're done
            LD   B,A            ;Store length of string
@Next:      INC  DE             ;Point to next character to append
            LD   A,(DE)         ;Get character from specified string
            CALL OutputChar     ;Output character to output device
            DJNZ @Next          ;Loop back if more character
@Done:      POP  DE
            POP  BC
            POP  AF
            RET


; String: Write address, colon, space to string buffer
;   On entry: DE = Address
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
; Example output: "1234: "
StrWrAddress:
            PUSH AF
            CALL StrWrHexWord   ;Write start address of this line
            LD   A,':'
            CALL StrWrChar      ;Write colon
            CALL StrWrSpace     ;Write space
            POP  AF
            RET


; String: Write ascii character to string buffer
;   On entry: A = ASCII character
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
; If the character is not printable then a dot is written instead
StrWrAsciiChar:
            PUSH AF
            CALL ConvertByteToAscii
            CALL StrWrChar      ;Write character or a dot
            POP  AF
            RET


#IFDEF      kIncludeUnusedCode
; String: Write backspace to string buffer
;   On entry: No parameters required
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
; Writeing backspace deletes the last character in the buffer
StrWrBackspace:
            PUSH AF
            PUSH HL
            LD   HL,(iStrStart) ;Pointer to start of string buffer
            LD   A,(HL)         ;Get length of string in buffer
            OR   A              ;Null terminator?
            JR   Z,@Skip        ;Yes, so skip as null string
            DEC  HL             ;Decrement string length
@Skip:      POP  HL
            POP  AF
            RET
#ENDIF


#IFDEF      kIncludeUnusedCode
; String: Write binary byte
;   On entry: A = Binary byte
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrBinaryByte:
            PUSH AF
            PUSH BC
            LD   B,8            ;Set for 8-bits
            LD   C,A            ;Store binary byte
@NextBit:   LD   A,'1'          ;Default to '1'
            RL   C              ;Rotate data byte
            JR   C,@One         ; result in Carry
            LD   A,'0'          ;Select '0'
@One:       CALL StrWrChar      ;Output '1' or '0'
            DJNZ @NextBit       ;Loop until done
            POP  BC
            POP  AF
            RET
#ENDIF


; String: Write character
;   On entry: A = Character to write to string buffer
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
; The specified character is writted to the string buffer and a null
; terminator added.
StrWrChar:
            PUSH AF
            PUSH DE
            PUSH HL
            LD   E,A            ;Store character to write
            LD   HL,(iStrStart) ;Start of current string buffer
            LD   A,(HL)         ;Get length of string in buffer
; TODO >>>>> Trap strings too long for the buffer
            INC  (HL)           ;Increment string length
            INC  A              ;Inc to skip length byte
            ADD  A,L            ;Add A to start of buffer...
            LD   L,A            ;  to get address for next character
            JR   NC,@Store
            INC  H
@Store:     LD   (HL),E         ;Store character in buffer
            POP  HL
            POP  DE
            POP  AF
            RET


; TODO >>>>> WriteDecimalByte


; TODO >>>>> WriteDecimalByteWithZero


; String: Write hex byte to string buffer
;   On entry: A = Hex byte
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrHexByte:
            PUSH AF
            PUSH DE
            CALL ConvertByteToNibbles
            LD   A,D
            CALL StrWrHexNibble
            LD   A,E
            CALL StrWrHexNibble
            POP  DE
            POP  AF
            RET


; String: Write hex nibble to string buffer
;   On entry: A = Hex nibble
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrHexNibble:
            PUSH AF
            AND  0x0F           ;Mask off nibble
            CP   0x0A           ;Nibble > 10 ?
            JR   C,@Skip        ;No, so skip
            ADD  A,7            ;Yes, so add 7
@Skip:      ADD  A,0x30         ;Add ASCII '0'
            CALL StrWrChar      ;Write character
            POP  AF
            RET


; String: Write hex word to string buffer
;   On entry: DE = Hex word
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrHexWord:
            PUSH AF
            LD   A,D            ;Get hi byte
            CALL StrWrHexByte   ;Write as two hex digits
            LD   A,E            ;Get lo byte
            CALL StrWrHexByte   ;Write as two hex digits
            POP  AF
            RET


; String: Write new line to string buffer
;   On entry: No parameters
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrNewLine:
            PUSH AF
            LD   A,kNewLine     ;Get new line character
            CALL StrWrChar      ;Write character to string
            POP  AF
            RET


; String:  Write padding (spaces) to specified length
;   On entry: A = Required length of string
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrPadding:
            PUSH AF
            PUSH BC
            PUSH HL
            LD   B,A
            LD   HL,(iStrStart) ;Get start of current string buffer
            SUB  (HL)           ;Compare required length to current
            JR   C,@End         ;End now if already too long
            JR   Z,@End         ;End now if already required length
            CALL StrWrSpaces    ;Write required number of spaces
@End:       POP  HL
            POP  BC
            POP  AF
            RET


; String: Write space character to string buffer
;   On entry: No parameters
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrSpace:
            PUSH AF
            LD   A,kSpace       ;Space character
            CALL StrWrChar      ;Write space character
            POP  AF
            RET


; String: Write spaces to string buffer
;   On entry: A = Number of spaces to write
;   On exit:  AF BC DE HL IX IY I AF' BC' DE' HL' preserved
StrWrSpaces:
            PUSH AF
@Loop:      CALL StrWrSpace     ;Print one space character
            DEC  A              ;Written all required spaces?
            JR   NZ,@Loop       ;No, so go write another
            POP  AF
            RET


; **********************************************************************
; **  Private workspace (in RAM)                                      **
; **********************************************************************

            .DATA

iStrStart:  .DW  0x0000         ;Start of current string buffer
iStrSize:   .DB  0x00           ;Size of current string buffer (0 to Len-1)


; **********************************************************************
; **  End of String support module                                    **
; **********************************************************************


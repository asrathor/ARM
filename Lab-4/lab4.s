	AREA  GPIO, CODE, READWRITE    
    EXPORT lab4
	IMPORT output_character
	IMPORT uart_init
    IMPORT read_character
    IMPORT read_string
    IMPORT output_string
    IMPORT Illuminate_RGB_LED
	IMPORT illuminateLEDs
	IMPORT read_from_push_btns
	IMPORT display_digit_on_7_seg
PIODATA EQU 0x8 			;Offset to parallel I/O data register
PINSEL0 EQU 0xE002C000		;base address of pins 15-16 port 0 for setup
PINSEL1 EQU 0xE002C004		;base address of pins 16-31 port 0 for setup
IO0PIN EQU 0xE0028000		;base address for gpio port0 pin value register
IO1PIN EQU 0xE0028010		;base address for gpio port1 pin value register
IO0DIR EQU 0xE0028008 		;base address for port0 direction register
IO1DIR EQU 0xE0028018 		;base address for port1 direction register
IO0SET EQU 0xE0028004		;base address for port0 output register
IO1SET EQU 0xE0028014		;base address for port1 set register
IO0CLR EQU 0xE002800C		;base address for port0 clear register
IO1CLR EQU 0xE002801C		;base address for port1 clear register
RED EQU 0x00020000			;make LED red
BLUE EQU 0x00040000			;make LED Blue
GREEN EQU 0x00200000		;make LED green
PURPLE EQU 0x00060000		;make LED purple
YELLOW EQU 0x00220000		;make LED yellow
WHITE EQU 0x00260000		;make LED white
STRINGOFFSET EQU 130		;free digit for read string
Menu      = "\n\rWelcome to lab #4, enter one of the following a number commands \n\r 0: Display a binary value on LEDs \n\r 1: Read a value from push buttons \n\r 2: Illuminate a hexadecimal digit \n\r 3: Illuminate or turn off the RGB LED \n\r 4: Quit program \n\r",0     ; Text to be sent to PuTTy
LEDprompt = "Enter number from 0-f to display on the LEDs: ",0
Pushbuttonprompt = "Push buttons and press enter to return a number: ",0
Digitprompt = "Enter number 0-f to display on the 7 segment display: ",0
RGBprompt = "Enter one of the following number commands \n\r 0: Red \n\r 1: Blue \n\r 2: Green \n\r 3: Purple \n\r 4: Yellow \n\r 5: White \n\r 6: Off \n\r" ,0
      ALIGN 

digits_SET  
		DCD 0x00001F80  ; 0
		DCD 0x00000300  ; 1
		DCD 0x00002D80 ; 2
		DCD 0x00002780 ; 3
		DCD 0x00003300 ; 4
		DCD 0x00003680 ; 5
		DCD 0x00003E80 ; 6
		DCD 0x00000380 ; 7
		DCD 0x00003F80 ; 8
		DCD 0x00003380 ; 9
      ; Place other display values here
		DCD 0x00003B80 ; A
		DCD 0x00003E00 ; B
		DCD 0x00001C80 ; C
		DCD 0x00002F00 ; D
		DCD 0x00003C80 ; E  
		DCD 0x00003880  ; F   
            
      ALIGN 
lab4 
    STMFD SP!,{lr}    	;Store register lr on stack
    BL uart_init		;branch and link to uart init
    BL InitializePins	;branch and link to initialize gpio to output or input 
MainMenu
    LDR r9, =Menu 		;output menu
    BL output_string	;branch and link to output menu
    LDR r9, =RGBprompt	;position to store read string
	ADD r9, r9, #STRINGOFFSET	 ;beginning of empty memory
    BL read_string		;branch and link to read input (0, 1, 2, or 3)
	LDR r9, =RGBprompt	;position to store read string
	ADD r9, r9, #STRINGOFFSET	 ;beginning of empty memory
	LDRB r6, [r9]		;load r9 into r6
    CMP r6, #0x30		;compare r6 to 0x30
    BEQ LED				;branch on equal to LED
    CMP r6, #0x31		;compare r6 to 0x31
    BEQ Pushbutton		;branch on equal to Pushbutton
    CMP r6, #0x32		;compare r6 to 0x32
    BEQ Digit			;branch on equal to Digit
    CMP r6, #0x33		;compare r6 to 0x33
    BEQ RGB				;branch on equal to RGB
	CMP r6, #0x34		;compare r6 to 0x34
    BEQ QUIT			;branch on equal to QUIT
	B MainMenu			;branch to MainMenu
InitializePins
	STMFD sp!,{lr,r6,r5};
	LDR r6, =IO0DIR		;load base address of direction register port 0
    LDR r5, =0x00263F80 ;set values to output for port 0
    STR r5, [r6]		;store the value set above in direction register
    LDR r6, =IO1DIR		;load base address of direction register port 1	
    MOV r5, #0x000F0000 ;set values to output for port 1
    STR r5, [r6]		;store the value set above in direction register
	LDR r9, =IO0SET		;load base address of set register port 0
	LDR r1, [r9]		;load into r1, the value in set register
	LDR r0, =0x0002000	;load r0 to set 13 bit to 1
	ORR r0,r1, r0 		;take the OR of r1 and r0
	STR r0, [r9]		;store the value calculated above into r9
	LDMFD sp!,{lr,r6,r5};
    BX LR
LED
    LDR r9, =LEDprompt	;position of LEDprompt
    BL output_string	;output prompt
    LDR r9, =RGBprompt	;position to store read string
	ADD r9, r9, #STRINGOFFSET	 ;beginning of empty memory
    BL read_string		;branch and link to read input (0-f)
	LDR r9, =RGBprompt	;position to store read string
	ADD r9, r9, #STRINGOFFSET	 ;beginning of empty memory
	LDRB r0, [r9]		;load r0 into r9
    SUB r0, r0, #0x30	;convert from ascii if value is 0-9
    CMP r0, #10			;convert from ascii if value is a-f
    BLT lessthan10		;branch on less than to convert from ascii if value is a-f
    SUB r0, r0, #39 	;convert from ascii if value is a-f
lessthan10
    BL illuminateLEDs	;branch and link to illuminateLEDs
    B MainMenu			;restart menu
Pushbutton
    LDR r9, =Pushbuttonprompt	
    BL output_string	;branch on less than to output menu
    BL read_from_push_btns	;branch on less than to push_btns
	ADD r0, r0, #0x30	;convert from ascii if value is 0-9
    CMP r0, #0x39		;convert from ascii if value is a-f
    BLT lessthan10c		;branch on less than to convert from ascii if value is a-f
    ADD r0, r0, #39 	;convert from ascii if value is a-f
lessthan10c
    MOV r6, r0			;copy r0 to r6
    BL output_character	;branch and link to output character
    B MainMenu			;branch to MainMenu
Digit
    LDR r9, =Digitprompt;position of RGBprompt
    BL output_string	;branch and link to output menu
    LDR r9, =RGBprompt	;position to store read string
	ADD r9, r9, #STRINGOFFSET	 ;beginning of empty memory
    BL read_string		;branch and link to read input (0, 1, 2, 3,4,5)
	LDR r9, =RGBprompt	;position to store read string
	ADD r9, r9, #STRINGOFFSET	 ;beginning of empty memory
	LDRB r6, [r9]		;load r9 into r6
	MOV r0, r6			;set r6 to r0
    SUB r0, r0, #0x30	;convert from ascii if value is 0-9
    CMP r0, #10			;convert from ascii if value is a-f
    BLT lessthan10b		;branch on less than convert from ascii if value is a-f
    SUB r0, r0, #39 	;convert from ascii if value is a-f
lessthan10b
    BL display_digit_on_7_seg	;branch and link to display_digit_on_7_seg
    B MainMenu					;branch to MainMenu
RGB
    LDR r9, =RGBprompt	;position of RGBprompt
    BL output_string	;branch and link to output menu
    LDR r9, =RGBprompt	;position to store read string
	ADD r9, r9, #STRINGOFFSET	 ;beginning of empty memory
    BL read_string		;branch and link to read input (0, 1, 2, 3,4,5)
	LDR r9, =RGBprompt	;position to store read string
	ADD r9, r9, #STRINGOFFSET	 ;beginning of empty memory
	LDRB r6, [r9]		;load r9 into r6
    MOV r0, #RED		;set r0 to #RED
    CMP r6, #0x30		;compare r6 to 0x30
    BEQ GoToRGB			;branch on equal to GoToRGB
    MOV r0, #BLUE		;set r0 to #BLUE
    CMP r6, #0x31		;compare to 0x31
    BEQ GoToRGB			;branch on equal to GoToRGB
    MOV r0, #GREEN		;set r0 to GREEN
    CMP r6, #0x32		;compare to 0x32
    BEQ GoToRGB			;branch on equal to GoToRGB
    MOV r0, #PURPLE		;set r0 to PURPLE
    CMP r6, #0x33		;compare to 0x33
    BEQ GoToRGB			;branch on equal to GoToRGB
    MOV r0, #YELLOW		;set r0 to YELLOW
    CMP r6, #0x34		;compare to 0x34
    BEQ GoToRGB			;branch on equal to GoToRGB
    MOV r0, #WHITE		;set r0 to WHITE
    CMP r6, #0x35		;compare r6 to 0x35
    BEQ GoToRGB			;branch on equal to GoToRGB
    MOV r0, #0   		;turn LED off
    CMP r6, #0x36		;compare r6 to 0x36
    BEQ GoToRGB			;branch on equal to GoToRGB
GoToRGB
    BL Illuminate_RGB_LED	;branch and link to Illuminate_RGB_LED
    B MainMenu			;branch to MainMenu
QUIT
    LDMFD SP!, {lr}   ; Restore register lr from stack     
    BX LR
	END
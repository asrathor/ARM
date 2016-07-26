	AREA interrupts, CODE, READWRITE
	EXPORT lab7
	EXPORT FIQ_Handler
	IMPORT display_digit_on_7_seg
	IMPORT uart_init
	IMPORT read_character
	IMPORT output_character
	IMPORT illuminateLEDs
	IMPORT read_string
	IMPORT output_string
    IMPORT div_and_mod
	IMPORT div_and_mod1
	IMPORT Illuminate_RGB_LED
score DCW 0x0000 	;score of the player during the gameplay
snake DCW 0x0000	;for representing the snake on the board
blinkcounter DCW 0x00	;blinkcounter if 0 then RGB=green or else if 1 then RGB=red
Index DCB 0x00		; 0-300 (offset of prompt2. halfword) starts at 32 so random doesnt bug initially
X DCB 0x00 			;x coordinate of Qbert
Y DCB 0x00 			;y coordinate of Qbert
lives DCB 0x0F 		;number of lives players has, 0x0F representing 4 lives initially
ballindex DCB 0x00	;denotes the index of the enemy that will be launched on board
pad DCB 0x00		;random variable that can be used for anything
time DCW 0x00		;representing the time of gameplay
direction DCB 0x00 	;direction of character movement
RGBstate DCB 0x00 	;represents the current state of RGB led
balltimer DCB 0x01	;denotes the time until next enemy appears, only place enemy if balltimer is 0
snakeballtimer DCB 0x00	;denotes the time until next snake appears, only place snake if snaketimer is 0
level DCB 0x00		;denotes the level that the player has reached
squarecounter  DCB 0x00	;denotes the number of spaces discovered by the player on the board
snakeballcounter  DCB 0x01	;for making the enemies go half the speed of Q for balancing of the game
pad1 DCB 0x00		;random variable that can be used for anything
prompt = "\n\rPress any key to Start\n\r",0
prompt1 = "\n\rGAME IS PAUSED\n\r",0
prompt2 = "\n\r           __          \n\r          /  /|          \n\r         /__/ |__        \n\r         |  | /  /|        \n\r         |__|/__/ |__      \n\r         /  /|  | /  /|      \n\r        /__/ |__|/__/ |__    \n\r        |  | /  /|  | /  /|    \n\r        |__|/__/ |__|/__/ |__  \n\r        /  /|  | /  /|  | /  /|  \n\r       /__/ |__|/__/ |__|/__/ |__\n\r       |  | /  /|  | /  /|  | /  /|\n\r       |__|/__/ |__|/__/ |__|/__/ |\n\r      /  /|  | /  /|  | /  /|  | /\n\r     /__/ |__|/__/ |__|/__/ |__|/ \n\r    |  | /  /|  | /  /|  | /     \n\r    |__|/__/ |__|/__/ |__|/      \n\r   /  /|  | /  /|  | /             \n\r  /__/ |__|/__/ |__|/             \n\r  |  | /  /|  | /                 \n\r  |__|/__/ |__|/                  \n\r /  /|  | /                      \n\r/__/ |__|/                       \n\r|  | /                           \n\r|__|/                            \n\r",0
prompt3 = "\n\rWelcome to Qbert\n\r",0
prompt4 = "\n\r1. Press i to show instructions\n\r2. Press s to start the game.\n\r3. Press q to Quit\n\r",0
prompt5 = "\n\rInstructions:1. Use w(up),a(left),s(down),d(right) to move around the Q.\n\r2.The enemies will be denoted by O,C and S that will come after you.\n\r3.Your score is increased upon discovering new places. Note that going to same place wont increase your score.\n\r4.Player will level up if all places on the pyramid are discovered.\n\rPress s to start the game or Q to quit\n\r",0
prompt6 = "\n\rScore:        Time:    \n\r",0
prompt7 = "\n\rScore:        PAUSED      Time:    \n\r",0
prompt8 = "\n\rPress r to restart the game or q to end the game\n\r",0
Balls
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
        DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
        DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
        DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
		DCW 0x0000
        DCW 0x0000
Board  
;Bit 0-3: Y
;4-7:X 
;8:set if square has been stepped on
;9-10:type of enemy 
	;00=no enemy 
	;01=CBall 
	;10=OBall 
	;11=Snake 
;11:is Q on this square?
;16-25: Memory offset
;these value may have to change
		DCD 0x00260800  ; 0,0
		DCD 0x00950001  ; 0,1
		DCD 0x00600011 ; 1,1
		DCD 0x01140002 ; 0,2
		DCD 0x00D70012 ; 1,2
		DCD 0x009E0022 ; 2,2
		DCD 0x01A20003 ; 0,3
		DCD 0x015E0013 ; 1,3
		DCD 0x011D0023 ; 2,3
		DCD 0x00E00033 ; 3,3
      ; Place other display values here
		DCD 0x022D0004 ; 0,4
		DCD 0x01ED0014 ; 1,4
		DCD 0x01AB0024 ; 2,4
		DCD 0x01670034 ; 3,4
		DCD 0x01260044 ; 4,4
		DCD 0x02BC0005  ; 0,5
		DCD 0x027A0015 ; 1,5
		DCD 0x02360025 ; 2,5
		DCD 0x01F60035 ; 3,5
		DCD 0x01B40045  ; 4,5
		DCD 0x01700055 ; 5,5
	ALIGN

lab7	 	
	STMFD sp!, {lr}
	; Your lab 7 code goes here...
	BL uart_init			;branch and link to uart_init to set up baud rate
	BL InitializePins		;branch and link to InitializePins for setting up direction, set and clear register		
	BL timer_init			;branch and link to timer_init to set and enable timer1
	MOV r6, #12				;set r6 to 12
	BL output_character		;branch and link to output_character to clear the screen
	LDR r4, =prompt3		;load prompt3 (opening message) to r4
	BL output_string		;branch and link to output_string to show prompt3 on putty
	LDR r4, =prompt			;load prompt to r4
	BL output_string		;branch and link to output_string to show prompt on putty
	LDR r4, =prompt4		;load prompt4 (menu) to r4
	BL output_string		;branch and link to output_string to show prompt4 on putty
read
	LDR r3,=0xE000C000		;load address E000C000 in r3
	LDR r6, [r3]			;load the contents in r6
	CMP r6, #0x73			;check the user input to s
	BEQ start				;branch on equal to start
   	CMP r6, #0x69			;check the user input to i
	BEQ instructions		;branch on equal to instructions
	CMP r6, #0x71			;check the user input to q
	BEQ QUIT				;branch on equal to QUIT
	B read
InitializePins
	;Set the pins in direction register for port 0 and 1, set register port 0 for
	;displaying anything that programmer wants on RGB led, seven-seg display, illuminate leds 
	STMFD sp!,{lr,r6,r5,r9,r1};
	LDR r6, =0xE0028008		;load base address of direction register port 0
    LDR r5, =0x00263F80 	;set values to output for port 0
    STR r5, [r6]			;store the value set above in direction register
    LDR r6, =0xE0028018		;load base address of direction register port 1	
    MOV r5, #0x000F0000 	;set values to output for port 1
    STR r5, [r6]			;store the value set above in direction register
	LDR r9, =0xE0028004		;load base address of set register port 0
	LDR r1, [r9]			;load into r1, the value in set register
	LDR r0, =0x00001F80		;load r0 to set 13 bit to 1
	ORR r0,r1, r0 			;take the OR of r1 and r0
	STR r0, [r9]			;store the value calculated above into r9
	LDMFD sp!,{lr,r6,r5,r9,r1}
    BX LR
	LTORG

instructions
	;To show the instructions prompt on putty and asking user to whether to play or quit
	LDR r4, =prompt5		;load the instructions prompt in r4
	BL output_string		;branch and link to output_string
	B read					;branch to read
	BEQ QUIT				;branch on equal to QUIT
	 
start
	;To start the game for the first time increasing the level from 0 to 1 
	BL levelup				;branch and link to levelup to increase the level from 0 to 1
	BL updatemap			;branch and link to update the pyramid
	LDR r4, =prompt6		;load the prompt6 containing score and time in r4
	BL output_string		;branch and link to f to show score and time
	MOV r0, r0				;NOP
	LDR r4, =prompt2		;load the prompt2 containing pyramid structure in r4
	BL output_string		;branch and link to output_string to show the pyramid
	;BL updatemap
	BL interrupt_init		;branch and link to interrupt_init to set interrupts and timer0
	MOV r0, #0				;set r0 to 0
	LDR r4, =time			;load time in r4
	STRB r0, [r4]			;set the time to 0
	B keepreading			;branch to keepreading


keepreading
	;BL read_string			;branch and link to read_string
	B keepreading			;branch to keepreading (loop again)
	LDMFD sp!,{lr}
	BX lr

start2
	;Currently not used but can be used if programmer just wants to update map and initialize interrupts
	BL updatemap			;branch and link to updatemap to update the pyramid
	LDR r4, =prompt6		;load the score and time prompt in r4
	BL output_string		;branch and link to output_string to show score and time on putty
	MOV r0, r0				;NOP
	LDR r4, =prompt2		;load the board prompt on r4
	BL output_string		;branch and link to output_string to show pyramid on putty
	;BL updatemap
	BL interrupt_init		;branch and link to interrupt_init to set interrupt and timer0
	B keepreading			;branch to keepreading

uart0_interrupt_init
	

timer_init
        ;For set timer1 period, reseting when timer1 = match register, and enabling timer1 
        STMFD SP!, {r0-r1, lr}  ; Save registers
        ;set timer period

		;set timer period
		LDR r0, =0xE000801C		;load address MR1
		LDR r1, =0x1194000		;set r1 to 0x1194000
		STR r1, [r0]			;store r1 back in MR1

		;when TC == MR1 reset
		LDR r0, =0xE0008014		;load address in r0
		LDR r1, [r0]			;load the contents in r1
		ORR r1, r1, #0x18		;set the 3rd and 4th bit to 1
		STR r1, [r0]			;store it back in r0

        ;enable TCR
		LDR r0, =0xE0008004		;load timer1 in r0
		LDR r1, [r0]			;load the contents in r1
		ORR r1, r1, #0x1		;set the last bit to 1
		STR r1, [r0]			;store it back in r0

        LDMFD SP!, {r0-r1, lr} ; Restore registers
		BX lr

interrupt_init  
		;initialize and enable the interrupts and timer0      
		STMFD SP!, {r0-r1, lr}  ; Save registers
		;This section of code sets up uart0 interrupt when THRE (output character) is set
		LDR r0, =0xE000C004		;address of UOIER
		LDR r1, [r0]			;load the contents of UOIER in a register
		ORR r1, r1, #1			;set the second bit to 2
		STR r1, [r0]			;load the updated register back into UOIER
        ;This section of code makes the interrupt FIQ
		LDR r0, =0xFFFFF00C		;address of interrupt select register 
		LDR r1, [r0]			;load the contents into register r1
		ORR r1, r1, #0x70		;set the 6th bit to 1
		STR r1, [r0]			;load the updated register back to set as FIQ
        ;This section enables the interrupt
		LDR r0, =0xFFFFF010		;address of interrupt enable register
		LDR r1, [r0]			;load the contents into register r1
		ORR r1, r1, #0x70		;set the 6th, 5th, 4th bit to 1
		STR r1, [r0]			;load the updated register back to set for interrupts

		LDR r0, =0xE000401C		;MR1
		LDR r1, =0x0008CA000	;set the timer period
		STR r1, [r0]			;load the timer period in timer1
		
		;create interrupt when TC == MR1 and resets
		LDR r0, =0xE0004014		;load the address in r0
		LDR r1, [r0]			;load the contents in r1
		ORR r1, r1, #0x18		;set 3rd and 4th bit to 1
		STR r1, [r0]			;store it back in r0

		;enable TCR
		LDR r0, =0xE0004004		;load address of timer0
		LDR r1, [r0]			;load the contents in r1
		ORR r1, r1, #0x1		;set the last bit to 1
		STR r1, [r0]			;store it back in r1

		; Push button setup		 
		LDR r0, =0xE002C000
		LDR r1, [r0]
		ORR r1, r1, #0x20000000
		BIC r1, r1, #0x10000000
		STR r1, [r0]  ; PINSEL0 bits 29:28 = 10

		; Classify sources as IRQ or FIQ
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0xC]
		ORR r1, r1, #0x8000 ; External Interrupt 1
		STR r1, [r0, #0xC]

		; Enable Interrupts
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0x10] 
		ORR r1, r1, #0x8000 ; External Interrupt 1
		STR r1, [r0, #0x10]

		; External Interrupt 1 setup for edge sensitive
		LDR r0, =0xE01FC148
		LDR r1, [r0]
		ORR r1, r1, #2  ; EINT1 = Edge Sensitive
		STR r1, [r0]

		; Enable FIQ's, Disable IRQ's
		MRS r0, CPSR
		BIC r0, r0, #0x40
		ORR r0, r0, #0x80
		MSR CPSR_c, r0

		LDMFD SP!, {r0-r1, lr} ; Restore registers
		BX lr             	   ; Return



FIQ_Handler
		STMFD SP!, {r0-r4,r6, lr}   	; Save registers 
EINT1										; Check for EINT1 interrupt
		LDR r0, =0xE01FC140					
		LDR r1, [r0]
		TST r1, #2
		BEQ CheckInterrupt
		B push_button 						;go here if push button is pressed 
			
		; Push button EINT1 Handling Code
CheckInterrupt
		 ;check when the interrupt occurs and branch to respective handler
		 LDR r2, =0xE000C008	;load address of UART0 Interrupt identification register
		 LDR r1, [r2]			;load the contents of above address
		 AND r1,r1, #0x00000001	;check for the 0 bit
		 CMP r1, #0				;if bit 0 = 0
		 BEQ UART0handler		;branch on not equal to UART0handler
		 
		 LDR r2, =0xE0004000	;load the address of timer0
		 LDR r1, [r2]			;load the contents in r1
		 AND r1, r1, #0x2		;check for the second last bit
		 CMP r1, #2				;compare to 2
		 BEQ Timer0handler		;branch on equal to Timer0handler
		 ;B FIQ_Exit1			;branch to FIQ_Exit1

         LDR r2, =0xE0008000	;load the address of timer0
		 LDR r1, [r2]			;load the contents in r1
		 AND r1, r1, #0x2		;check for the second last bit
		 CMP r1, #2				;compare to 2
		 BEQ Timer1handler		;branch on equal to Timer0handler
		 B FIQ_Exit1			;branch to FIQ_Exit1

UART0handler
		;check what direction key is pressed by user to move the Q in that direction
		LDR r3,=0xE000C000		;load address E000C000 in r3
		LDR r6, [r3]			;load the contents in r6
        CMP r6, #97             ;compare r6 to 197(a)
        BEQ storedirection		;branch on equal to storedirection
        CMP r6, #115			;compare r6 to 115(s)
        BEQ storedirection		;branch on equal to storedirection
        CMP r6, #100			;compare r6 to 100(d)
        BEQ storedirection		;branch on equal to storedirection
        CMP r6, #119			;compare r6 to 119(w)
        BEQ storedirection		;branch on equal to storedirection
		CMP r6, #113			;compare r6 to 113(q)
		BEQ QUIT				;branch on equal to QUIT
        B FIQ_Exit1 			;exit to FIQ_Exit1 if no valid input
storedirection
		;store the direction pressed by user to move Q in direction variable
        LDR r3, =direction		;load r3 with address of direction
        STRB r6, [r3]			;direction will be 100, 108, 114, or 117 for down left right up
		B FIQ_Exit1				;branch to FIQ_Exit1

push_button
		;when the momentary push button of interrupt (p.14) on arm board is pressed
        LDR r0, =0xE01FC140		;load address of external interrupt flag register
		LDR r1, [r0]			;load the contents of above address
		ORR r1, r1, #0x2		;set the 1st bit to 1
		STR r1, [r0]			;store the updated result back in address

        ;enable TCR
		LDR r0, =0xE0008004		;load timer1 in r0
		LDR r1, [r0]			;load the contents in r1
		EOR r1, r1, #0x1		;set the last bit to 1
		STR r1, [r0]			;store it back in r0

        LDR r0, =0xE0004004		;load timer1 in r0
		LDR r1, [r0]			;load the contents in r1
		EOR r1, r1, #0x1		;set the last bit to 1
		STR r1, [r0]			;store it back in r0

        MOV r0, #0x00040000		;set r0 to 0x40000 (18th bit to 1)
        BL Illuminate_RGB_LED	;branch and link to Illuminate_RGB_LED to display blue
		MOV r6, #12				;set r6 to 12
		BL output_character		;branch and link to output_character to clear the putty
		LDR r4, =prompt1		;load the prompt of game paused in r4
		BL output_string		;branch and link to show the that game is paused 
		LDR r4, =prompt6		;load the score and time prompt in r4
		BL output_string		;branch and link to show score and time on putty
		LDR r4, =prompt2		;load the board prompt on r4
		BL output_string		;branch and link to output_string to show pyramid or board
		B FIQ_Exit1				;branch to FIQ_Exit1
Timer0handler
		;create interrupt when TC == MR1 and resets
        LDR r2, =0xE0004000		;load address in r2
		LDR r1,[r2]				;load the contents in r1
		ORR r1, #2				;set the 1st bit to 1
		STR r1,[r2]				;store it back in r2
        BL placeballs			;branch and link to place balls on board
		BL moveballs			;branch and link to move enemies on the board
        BL movesnake			;branch and link to move the snake on board
		BL incrementcounter		;branch and link to increment the counter for enemies
		BL CheckDeath			;branch and link to check if player has lost a life
        BL MoveQBert			;branch and link to move the Q on board
		MOV r6, r6				;NOP
		BL CheckDeath			;branch and link to check if player has lost a life
        BL CheckLivesLeft		;branch and link to check if any lives are left
		BL CheckLevelup			;branch and link to check if all places discovered for leveling up
        BL updatemap			;branch and link to update the board when all Q and enemies are updated
        BL checkblink			;branch and link to check blink for RGB led to display 
		BL printmap				;branch and link to print the score, time and board on putty
        B FIQ_Exit1				;branch to FIQ_Exit1
Timer1handler
		;load the time in timer1 and quit if 2 minutes of gameplay has occurred
        LDR r2, =0xE0008000		;load address in r2
		LDR r1,[r2]				;load the contents in r1
		ORR r1, #2				;set the 1st bit to 1
		STR r1,[r2]				;store it back in r2
        LDR r1, =time			;load the time variable in r1
        LDRB r2, [r1]			;get the time that has passed since gameplay
        ADD r2, r2, #1			;increase the timer by 1
		STRB r2, [r1]			;store the time in the time variable
        CMP r2, #120			;if 2 minutes have passed
        BNE FIQ_Exit1			;branch on not equal to FIQ_Exit1

		LDR r7, =RGBstate		;load RGBstate in r7
        MOV r0, #0x00060000		;set r0 to 0x60000
        STRB r0, [r7]			;store r0 in r7
        BL Illuminate_RGB_LED	;branch and link to Illuminate_RGB_LED
        BL ClearEnemys			;branch and link to ClearEnemys
		BL incrementscoreEnd	;branch and link to incrementscoreEnd
		BL updatemap			;branch and link to updatemap
		BL printmap				;branch and link to printmap

        BL restart				;branch and link to restart

        B FIQ_Exit1				;branch to FIQ_Exit1
FIQ_Exit1
		LDMFD SP!, {r0-r4,r6,lr}
		SUBS pc, lr, #4			;return to interrupted instruction
decrementtimer
		;decrement the match register timer0 by half the time
		STMFD SP!, {r0,r1,r2,lr}
		LDR r0, =0xE000401C		;load match register address in r0
		LDR r1, [r0]			;load contents in r1
		LDR r2, =0x1C2000		;load r2 to 0x1C2000
		CMP r2, r1				;compare r2 to r1
		BEQ enddecrementtimer 	;branch on equal to enddecrementtimer
        SUB r1, r1, r2			;subtact MR1 by r2 and store it back in r1
		STR r1, [r0]			;store the new time back in MR1
enddecrementtimer
		LDMFD SP!, {r0,r1,r2,lr}
		BX lr
restart
		;decrement the match register timer0 by half the time
		STMFD SP!, {lr}
		LDR r0, =0xE000401C		;load match register address in r0
		LDR r2, =0x0008CA000	;load r2 with 0x8CA000
		STR r2, [r0]			;load r2 in match register
		MOV r1, #21				;set r1 to 21 (number of spaces on board)
		LDR r7, =Board			;load Board array in r7
CheckLivesLeftloop1
		SUB r1, r1, #1			;decrement r1 by 1
		LSL r2, r1, #2			;left shift r1 by 2 and store it in r2
		LDR r3, [r7,r2]			;add r2 as offset to Board and load the content in r3
		BIC r3, r3, #0xF00		;bit clear 8-11th bit
		STR r3, [r7,r2]			;add r2 as offset to Board and store the contents from r3
		CMP r1, #0				;compare r1 to 0
		BNE CheckLivesLeftloop1	;branch on not equal to CheckLivesLeftloop1 (loop again)

        MOV r9, #0				;set r9 to 0
		LDR r8, =score			;load score in r8
		STRH r9, [r8]			;set score to 0
		LDR r8, =blinkcounter	;load blinkcounter in r8
		STRB r9, [r8]			;set blinkcounter to 0
		LDR r8, =Index			;load Index in r8
		STRB r9, [r8]			;set Index to 0
		LDR r8, =X				;load X in r8
		STRB r9, [r8]			;set X to 0
		LDR r8, =Y				;load Y in r8
		STRB r9, [r8] 			;set Y to 0
		LDR r8, =snake			;load snake in r8
		STRH r9, [r8]			;set snake to 0
		MOV r9, #0x0F			;set r9 to 0x0F
		LDR r8, =lives 			;load lives in r8
		STRB r9, [r8]			;set lives to 0x0F (all lives remaining)
		MOV r9, #1				;set r9 to 1
		LDR r8, =level			;load level in r8
		STRB r9, [r8]			;set level to 1
		MOV r9, #0				;set r9 to 0
		LDR r8, =ballindex		;load ballindex in r8
		STRB r9, [r8]			;set ballindex in r9
		LDR r8, =time			;load time in r8
		STR r9, [r8]			;set time to 0
		LDR r8, =direction		;load direction in r8
		STRB r9, [r8]			;set direction to 0
		LDR r8, =RGBstate		;load RGBstate to 0
		STRB r9, [r8]			;set RGBstate to 0
		MOV r9, #0x01			;set r9 to 0x02
		LDR r8, =balltimer		;load balltimer in r8
		STRB r9, [r8]			;set balltimer to 2
		MOV r9, #0x00			;set r9 to 0
		LDR r8, =snakeballtimer	;load snakeballtimer in r8
		STRB r9, [r8]			;set snakeballtimer to 0
		MOV r9, #0				;set r9 to 0
		LDR r8, =squarecounter	;load squarecounter in r8
		STRB r9, [r8]			;set squarecounter to 0

        LDR r4, =prompt8		;load prompt8 in r4 to ask user whether to restart
        BL output_string		;branch and link to output_string
LivesLeftloop1
        LDR r3,=0xE000C000		;load address E000C000 in r3
		LDR r6, [r3]			;load the contents in r6
        CMP r6, #113			;check if user wants to quit
        BEQ QUIT				;branch on equal to QUIT
        CMP r6, #114			;check if user wants to restart
        BNE LivesLeftloop1		;branch on not equal to LivesLeftloop1
		CMP r6, #0				;if r6=0? enter was hit
		BEQ LivesLeftloop1		;branch on equal to LivesLeftloop1
		MOV r0, #0x00040000		;set r0 to 0x40000
		BL Illuminate_RGB_LED	;branch and link to Illuminate_RGB_LED
		MOV r0, #0xF			;set r0 to 0xF
		BL illuminateLEDs		;branch and link to illuminateLEDs (all of them)
		MOV r0, #0x1			;set r0 to 1
		BL display_digit_on_7_seg	;branch and link to display_digit_on_7_seg to show level 1
		LDR r8, =Board			;load Board in r8
		MOV r0, #0x800			;set r0 to 0x800
		LDR r1, [r8]			;load the contents of Board array in r1
		ORR r1, r1, r0			;Set 11th bit to 1
		STR r1, [r8]			;store the updated value back in board
		LDMFD SP!, {lr}
		BX lr
incrementtime
		;increment period by 0.1 every time player levels up
		STMFD SP!, {r0-r2,r4,lr}
		LDR r0, =0xE000801C		;load MR1 of timer1 in r0
		LDR r1, [r0]			;get contents in r1
        MOV r0, r1				;move r1 to r0 (dividend)
		LDR r1, =0x1194000		;load r1 (divisor) with 0x1194000
        BL div_and_mod1			;branch and link to div_and_mod1 to perform division
        LDR r4, =time			;load the time in r4
        STRB r0, [r4]			;store the updated time in r4
		LDMFD SP!, {r0-r2,r4,lr}
		BX lr
CheckLevelup
		STMFD SP!, {r0,r1,r2,r3,r7,lr}
		LDR r7, =squarecounter
		LDRB r0, [r7]
		CMP r0, #21				;compare to see if all places are visited
		BNE endCheckLevelup		;branch on equal to start2 to levelup
		BL levelup				;branch and link to levelup
		MOV r1, #21				;set r1 to 21 (number of spaces on board)
		LDR r7, =Board			;load Board array in r7
CheckLeveluploop
		SUB r1, r1, #1			;decrement r1 by 1 (one place visited on board)
		LSL r2, r1, #2			;left shift r1 by 2 (r1x4) and place result in r2
		LDR r3, [r7,r2]			;add r2 offset to Board and load the contents in r3
		BIC r3, r3, #0xF00		;bit clear 8-11th bits 
		STR r3, [r7,r2]			;add r2 offset to Board and store the updated r3
		CMP r1, #0				;is r1=0? (all places on board checked)
		BNE CheckLeveluploop	;branch on not equal to CheckLeveluploop (loop again)
		LDR r3, [r7]			;load the contents of board in r3
		ORR r3, #0x800			;set 11th bit to 1
		STR r3, [r7]			;store updated r3 in r7
		BL ClearEnemys			;branch and link to ClearEnemys
		MOV r0, #0				;set r0 to 0
		LDR r7, =squarecounter	;load squarecounter to r7
		STRB r0, [r7]			;set squarecounter to 0
		LDR r7, =X				;load X in r7
		STRB r0, [r7]			;set X to 0
		LDR r7, =Y				;load Y in r7
		STRB r0, [r7]			;set Y to 0
		LDR r7, =Index			;load Index in r7
		STRB r0, [r7]			;set Index to 0
		LDR r7, =snake			;load snake in r7
		STRH r0, [r7]			;set snake to 0
		LDR r7, =ballindex		;load ballindex in r7
		STRB r0, [r7]			;set ballindex to 0
		LDR r7, =snakeballtimer	;load snakeballtimer in r7
		STRB r0, [r7]			;set snakeballtimer to 0
		MOV r0, #1				;set r0 to 3
		LDR r7, =snakeballcounter	;load snakeballcounter in r7
		STRB r0, [r7]			;set snakeballcounter to 0
		MOV r0, #3				;set r0 to 3
		LDR r7, =balltimer		;load balltimer to r7
		STRB r0, [r7]			;set balltimer to 3
endCheckLevelup
		LDMFD SP!, {r0,r1,r2,r3,r7,lr}
        BX LR
CheckLivesLeft
        STMFD SP!, {r0-r9,lr}
        LDR r7, =lives			;load lives in r7
        LDRB r3, [r7]			;load the contents in r3
        CMP r3, #0				;compare r3 to 0
        BNE endCheckLivesLeft	;branch on not equal to endCheckLivesLeft
		BL restart				;branch and link to restart the game

endCheckLivesLeft
        LDMFD SP!, {r0-r9,lr}
        BX LR
checkblink
		;check blinkcounter variable to check which color should be displayed on RGB led
        STMFD SP!, {r0,r3,r4,lr}
        LDR r4, =blinkcounter	;load the blinkcounter in r4
        LDRB r3, [r4]			;get the contents in r3
        CMP r3, #0				;compare to see whether the counter is equal to 0
        BEQ makegreen			;branch and link to makegreen (game is in play)
        SUB r3, r3, #1			;subtract the counter by 1
        STRB r3, [r4]			;store the counter back in blinkcounter variable
        AND r3, r3, #1			;check the last bit and store it in r3
        CMP r3, #1				;compare the counter to 1 
        BEQ makered				;branch on equal to makered (life is lost)
        MOV r0, #0				;set r0 to 0
        BL Illuminate_RGB_LED	;branch and link to Illuminate RGB leds (turn it off)
        B endcheckblink			;branch to end the color check
makered
        MOV r0, #0x00020000		;set r0 to 0x20000 (set 17th to 1) 
        BL Illuminate_RGB_LED	;branch and link to illuminate RGB to display red color
        B endcheckblink			;branch to end color check
makegreen
        MOV r0, #0x00200000		;set r0 to 0x200000 (set 21th to 1)
        BL Illuminate_RGB_LED	;branch and link to illuminate RGB to display green color
endcheckblink
        LDR r4, =RGBstate		;load RGBstate variable in r4
        STRB r0, [r4]			;store the color representing the color currently on in r4
        LDMFD SP!, {r0,r4,r3,lr}
        BX LR

moveballs
		;move the enemies around the board randomly and remove enemies when they exit
		STMFD SP!, {r0-r9,lr}
		LDR r5, =snakeballcounter	;load snakeballcounter in r5
		LDRB r4, [r5]			;get the contents of r5 in r4
		AND r4, #1				;check for the last bit
		CMP r4, #1				;is last bit = 1?
		BEQ endmoveloop			;branch on equal to endmoveloop
		MOV R4, #0 				;set r4(counter) to 0
moveloop
        LSL r3, r4, #1			;left shift r4 by 1 and store it in r4
        LDR r5, =Balls			;load Balls address (representing enemies) in r5
        LDRH r2, [r5,r3]		;increment address above by offset and load contents in r2
        AND r1, r2, #0x1000		;check if the enemy ball is active by checking 12th bit
        CMP r1,#0				;compare r1 to 0 
        BEQ nextmoveloop		;branch on equal to nextmoveloop to check for next enemy 

        AND r5,r2, #0x00F0 		;check 4-7th bits and set everthing else to 0(x axis)
        LSR r5, r5, #4			;get the X coordinate by setting the coordinate in the last 4 bits
        AND r6, r2, #0x000F 	;check 0-3rd bits and set everthing else to 0(y axis)
        BL getindex				;branch and link to getindex
        LSL r0, r0, #2			;left shift r0 (offset to latest coordinate) by 2 (r0x4)
        LDR r3, =Board			;load board in r3
        LDR r7, [r3, r0]		;get board position of the latest coordinate
        BIC r7, r7, #0x00000600	;bit clear 10th bit to clear the enemy
        STR r7, [r3,r0]			;store the r7 back at the coordinate on board

        BL randomgenerator		;branch and link to randomgenerator for generating random
        AND r0, r0, #1			;check the last bit
        ADD r6, r6, #1			;increment r6 by 1
changepath1
        ADD r5, r5, r0			;increment r5 by r0 (add either 1 for right 0 for left)
        MOV r2, r0				;set r2 to r0 

        BL getindex				;branch and link to getindex (get latest coordinate)
        LDR r3, =Board			;load the board array in r3
        LSL r1, r0, #2			;left shift r0 by 2(r0x4) and store result in r1
        LDR r7, [r3, r1]		;add the offset r1 to board to get contents of latest coordinate 
        AND r7, r7, #0x600		;check the 10th bit for check what enemy it is
        CMP r7, #0x600;if snake	;check to see if it is a snake
        BEQ changepath			;branch and link to change path to change path of enemy since in front theres snake
        B dontchangepath		;branch to dontchangepath since no enemy is in front
changepath
        MOV r0, #-1				;set r0 to -1
        CMP r2, #1				;compare r2 to 1
        BEQ changepath1			;branch on equal to changepath1
        MOV r0, #1				;set r0 to 1
        CMP r2, #0				;compare r2 to 0
        BEQ changepath1			;branch on equal to changepath1
dontchangepath
        LDR r1, =Balls			;load the Balls address containing enemies in r1
        LSL r3, r4, #1			;left shift r4 (r4x2) and load result in r3
        LDRH r9, [r1,r3]		;add the offset to Balls to get latest enemy 
        BIC r9,r9, #0xFF		;bit clear last 2 bytes to clear x and y
        LSL r5, r5, #4			;left shift r5 by 4 (r5x16)
        ORR r9, r9, r5			;update the X coordinate
        ORR r9, r9, r6			;update the Y coordinate 
        STRH r9, [r1,r3]		;store x and y of enemies back in Balls array
        AND r1,r9,#0x0F00		;check the 8-11th to get enemy type

        CMP r6, #6				;is the Y value 6? remove ball
        BEQ removeball			;branch and link to removeball from the board

		LSR r5, r5, #4			;right shift X coordinate by 4 (r5x16)
        BL getindex				;branch and link to getindex to lastest coordinate
        LDR r3, =Board			;load the address of Board in r3
        LSL r0, r0, #2			;left shift r0 (offset) by 2(r0x4)
        LDR r7, [r3, r0]		;add the offset to board and load that position in r7
        BIC r7, r7, #0x600		;bit clear to clear enemy
        ORR r7, r7, r1			;set the bits by r1 to store enemy
        STR r7, [r3, r0]		;store new enemy back inside at board latest offset
nextmoveloop
        ADD r4, r4, #1			;increment counter by 1
        CMP r4, #28				;compare counter to 14 to check all enemies are placed
        BNE moveloop			;branch on not equal to moveloop to move the enemy
        B endmoveloop			;branch to endmoveloop since all enemies are placed
removeball
        LDR r7, =Balls			;load the Balls arrays containing enemies in r7
        MOV r0, #0				;set r0 to 0
        LSL r3, r4, #1			;left shift counter by 1(r4x2) and load result in r3
        STRH r0, [r7, r3]		;clear the enemy ball from the array since already played
        CMP r1, #0x0200			;compare to see if r1=0x200
        BEQ makesnake			;branch on equal to launch snake on the board
        B nextmoveloop			;branch to nextmoveloop to play next enemy ball
makesnake
		;create a snake enemy ball and place it on board
        SUB r9, r9, #0x0001		;make y address 5 again
		SUB r5, r5, r2			;subtract X coordinate by r2
		LSL r2, r2, #4			;left shift r2 by 4(r2x16)
		SUB r9, r9, r2			;subtract r9 by r2
		SUB r6, r6, #1			;subtract 1 from y
        ORR r9, r9, #0x0400		;make it a snake by setting 10th bit to 1
        LDR r7, =snake			;load snake in r7
        STRH r9, [r7]			;get the contents in r9
        LSR r5, r5, #4			;right shift by 4 to get memory address of X
        BL getindex				;branch and link to getindex to get the coordinate of board
        LDR r3, =Board			;load the Board array in r3
        LSL r0, r0, #2			;left shift r0 by 2(r0x4)
        LDR r7, [r3, r0]		;load the snake at the latest address on Board increased with offset
        ORR r7, r7, #0x600		;make snake by setting 10th bit to 1
        STR r7, [r3, r0]		;store snake back at the Board with the added offset
        B nextmoveloop			;branch to nextmoveloop to move the enemy
endmoveloop
		LDMFD SP!, {r0-r9,lr}
		BX LR

movesnake
        ;move the snake on the board and make it so that it will move towards Q
        STMFD SP!, {r0-r8,r10,r11,lr}
        LDR r4, =snake			;load the snake in r4
        LDRH r3, [r4]			;get the contents of snake in r4
        AND r2, r3, #0x1000		;check the 12th bit and place that bit in r2
        AND r6, r3, #0xF		;check the last 4 bits and store Y coordinate in r6
        AND r5, r3, #0xF0		;check the 4-7th bits and store X coordinate in r5
        LSR r5, #4				;right shift X coordinate by 4
        CMP r2, #0				;compare to 0 (no valid snake)
        BEQ endmovesnake		;branch on equal to endmovesnake
        LDR r4, =snakeballcounter	;load snakeballcounter to r4
        LDRB r2, [r4]			;get the contents of counter and place it in r2
        AND r2, r2, #1			;check the last bit
        CMP r2, #1				;compare to see if the last bit is 1
        BEQ endmovesnake		;branch on equal to endmovesnake
        LDR r4, =X				;Load the X coordinate of Q
        LDRB r7, [r4]			;get the X coordinate of Q in r7
        LDR r4, =Y				;load the Y coordinate of Q
        LDRB r8, [r4];QY		;get the Y coordinate of Q in r8

        CMP r5, r7		  		;compare to X coordinates of snake and Q
        BEQ snakehasequalx		;branch on equal to if X coordinates are equal
        CMP r6, r8				;compare to Y coordinates of snake and Q
        BGT snakehasgreatery	;branch on greater if Y coordinate of snake is greater than Q 
        CMP r6, r8				;compare if Y coordinates of snake and Q
        BLT snakehaslessy		;branch on less of Y coordinate of snake is less than Q
        CMP r6, r8				;compare the Y coordinates of snake and Q
        BEQ snakehasequaly		;branch on equal if Y coordinates are equal
snakehasgreatery
        MOV r10, #-1			;set r10 to -1
        MOV r11, #-1			;set r11 to -1
        CMP r5, r7				;compare the X coordinates of snake and Q
        BGT snakemove			;branch on greater to move the snake
        MOV r10, #0				;set r10 to 0
        MOV r11, #-1			;set r11 to -1
        CMP r5, r7				;compare the X coordinates of snake and Q
        BLT snakemove			;branch on less than to move the snake
snakehaslessy
        MOV r10, #0				;set r10 to 0
        MOV r11, #1				;set r11 to 1
        CMP r5, r7				;compare the X coordinate of snake and Q
        BGT snakemove			;branch on greater to move the snake
        MOV r10, #1				;set r10 to 1
        MOV r11, #1				;set r11 to 1
        CMP r5, r7				;compare the X coordinate of snake and Q
        BLT snakemove			;branch on less than to move the snake
snakehasequalx
        MOV r10, #0				;set r10 to 0
        MOV r11, #-1			;set r11 to -1
        CMP r6, r8				;compare the Y coordinate of snake and Q
        BGT snakemove			;branch on greater to move the snake 
        MOV r10, #0				;set r10 to 0
        MOV r11, #1				;set r11 to 1
        CMP r6, r8				;compare the Y coordinate of snake and Q
        BLT snakemove			;branch on less than to move the snake
snakehasequaly
        MOV r10, #-1			;set r10 to -1
        MOV r11, #-1			;set r11 to -1
        CMP r5, r7				;compare the Y coordinates of snake and Q
        BGT snakemove			;branch on greater than to move the snake
        MOV r10, #0				;set r10 to 0
        MOV r11, #-1			;set r11 to -1
        CMP r5, r7				;compare the X coordinates of snake and Q
        BLT snakemove			;branch on less than to move the snake
snakemove
        ;clear the previous snake and update the position of snake on the board 
        BL getindex				;branch and link to getindex 
        LSL r0, r0, #2			;get the offset by left shifting r0 by 2 to get latest coordinate
        LDR r4, =Board			;load the Board array in r4
        LDR r2, [r4,r0]			;add the offset to Board to get coordinate and load it in r2
        BIC r2,r2, #0x600		;bit clear r2 by 0x600 to clear 10th bit
        STR r2, [r4,r0]			;clear snake from previous spot

        ADD r6, r6, r11			;increment Y coordinate by r11 (either 1 or -1)
        ADD r5, r5, r10			;increment X coordinate by r10 (either 0 or -1)
        LDR r4, =snake			;load the snake address in r4
        LDRH r3, [r4]			;load the contents in r3
        BIC r3, r3, #0xFF		;bit clear the 8 bits of r3
        LSL r7, r5, #4			;left shift X coordinate by 4
        ORR r3, r3, r7			;set bit cleared value by left shifted X coordinate
		ORR r3, r3, r6			;set r3 by Y coordinate
        STRH r3, [r4]			;update spot of snake by storing it back in r4

        BL getindex				;branch and link to getindex
        LSL r0, r0, #2			;left shift r0 by 2 to get offset
        LDR r4, =Board			;load the board array in r4
        LDR r2, [r4,r0]			;add the offset to board and load the coordinate in r2
        ORR r2, r2, #0x600		;put snake into board by setting 10th bit to 1
        STR r2, [r4,r0]			;store the snake on the latest coordinate on board
endmovesnake
        LDMFD SP!, {r0-r8,r10,r11,lr}
		BX LR

incrementcounter
		;increment the snake ball counter by 1
		STMFD SP!, {r3,r4,lr}
		LDR r4, =snakeballcounter	;load the snakeballcounter by 1
		LDRB r3, [r4]			;get the contents of counter in r3
		ADD r3, r3, #1			;increment the counter by 1
		STRB r3, [r4]			;store the updated counter back in r4
		LDMFD SP!, {r3,r4,lr}
		BX LR

placeballs
		;check to see if it is time to place an enemy ball. If not, update the balltimer
		STMFD SP!, {r0-r6,lr}
		LDR r5, =snakeballcounter	;load snakeballcounter in r5
		LDRB r4, [r5]			;get the contents of r5 in r4
		AND r4, #1				;check for the last bit
		CMP r4, #1				;is last bit = 1?
		BEQ endplaceballs		;branch on equal to endplaceballs
		LDR r4, =balltimer		;amount of time until another ball is dropped
		LDRB r3, [r4]			;load the time in r3
		CMP r3,	#0				;compare to 0 if the ball is to be dropped
		BEQ placeballs1			;only place a ball if the balltimer is 0, otherwise decrement balltimer and store it
		SUB r3, r3, #1			;decrement balltimer by 1
		STRB r3, [r4]			;store the updated time back in balltimer
		B endplaceballs			;branch to endplaceballs
placeballs1
        ;Set another ball timer and store it back
        BL randomgenerator		;branch and link to randomgenerator
        MOV r1, #3				;set divisor to 3
        BL div_and_mod			;branch and link to div_and_mod1
        ADD r1, r1, #1			;increment remainder by 1
        STRB r1, [r4] 			;update ball timer by storing remainder in balltimer

		LDR r4, =snakeballtimer	;load the snakeballtimer
		LDRB r3, [r4]			;get the contents in r3
		ADD r3, r3, #1			;increment the timer by 1
		STRB r3, [r4]			;store the updated timer back in snakeballtimer
		LDR r5, =0x1400 		;value of a normal ball on 0,0
		CMP r3, #2				;compare r3 to 2
		BNE notsnake			;branch on not equal if not a snake
		MOV r5, #0x1200			;value of snake ball on 0,0
notsnake
		LDR r4, =ballindex		;load the ballindex in r4
		LDRB r0, [r4]			;get the contents in r0
        CMP r0, #28				;7 total indexes
        BNE notsix				;branch on not equal to notsix
        MOV r0, #0				;set r0 to 0
        STRB r0, [r4]			;next index is stored back in r4
        LDR r4, =Balls			;load the Balls array address in r4
        STRH r5, [r4, r0]		;increase the array by r0 offset and store the updated snake ball
notsix
        ADD r1, r0, #1			;increment offset by 1 and store value in r1
        STRB r1, [r4]			;next index is stored back in ballindex
        LSL r0,r0, #1			;left shit r0 by 1, previous index is used to acess balls
        LDR r4, =Balls			;load the address of Balls array
        STRH r5, [r4, r0]		;increase the array bu r0 offset and store the updated snake ball
endplaceballs
		LDMFD SP!, {r0-r6,lr}
		BX LR

printmap
        ;Clear the putty screen, and output the prompts containing score, time and board
        STMFD SP!, {r0,r1,r3,r4,r6,r9,lr}
		MOV r6, #12				;set r6 to 12 to clear the screen
		BL output_character		;branch and link to output_character
		;LDR r4, =prompt1		;load address of prompt1 in r4
		;BL output_string		;branch and link to output_string
		LDR r3, =score			;get the score address
		LDRH r0, [r3]			;load the contents
		LDR r9, =prompt6		;load the address of prompt6
		ADD r9, r9, #9			;increment r9 by 9
		BL Divide				;convert the score back in ascii
		LDR r3, =time			;load timer0 (check address!)
		LDRB r0, [r3]			;load the timer0
		LDR r9, =prompt6		;load the address of prompt again
		ADD r9, r9, #21			;get to pointer after time:
		BL Divide				;covert the time back to ascii
		LDR r4, =prompt6		;load the prompt6 address
		BL output_string 		;branch and link to show prompt6

		LDR r4, =prompt2		;load address of prompt2 in r4
        BL output_string		;branch and link to output_string
		
        LDMFD SP!, {r0,r1,r3,r4,r6,r9,lr}
		BX lr
MoveQBert
		;check the user input to move the Q in that direction
        STMFD SP!, {r0,r2,r3,r4,r5,r6,r7,r8,r9,lr}
        LDR r3, =direction		;load r3 with address of direction
        LDRB r6, [r3]			;get the contents in r6
        CMP r6, #97             ;compare r6 to 97(a)
        BEQ upleft				;branch on equal to move up left
        CMP r6, #115			;compare r6 to 115(s)
        BEQ downleft			;branch on equal to move down left
        CMP r6, #100			;compare r6 to 100(d)
        BEQ downright			;branch on equal to move down right
        CMP r6, #119			;compare r6 to 119(w)
        BEQ upright				;branch on equal to move up right
		CMP r6, #00				;compare r6 to 0
        BEQ endmove				;branch on equal to end move
upleft
        LDR r4, =X				;load the X coordinate address of Q
        LDRB r5, [r4]			;get the X coordinate in r5
        LDR r3, =Y				;load the Y coordinate address of Q
        LDRB r6, [r3]			;get the Y coordinate in r6
        CMP r5, #0				;compare X to 0, will die if X is 0
        BEQ deathhandleredge	;branch on equal to deathhandleredge(player fell off the map)
        SUB r5, r5, #1			;decrement X coordinate by 1
        SUB r6, r6, #1			;decrement Y coordinate by 1
        STRB r5, [r4]			;store updated X back in X
        STRB r6, [r3]			;store updated Y back in Y
        BL storeQ				;branch and link to storeQ
        B endmove				;branch to endmove
storeQ
        ;Clear the previous Q and store the Q on the board at updated position
        STMFD SP!, {lr,r2,r3,r6,r7,r4,r0,r5,r8,r9}
        LDR r2, =Board			;load the Board array in r2
        LDR r3, =Index			;load the Index in r3
        LDRB r5, [r3]			;r5 is index
        LSL r5, r5, #2			;left shift index by 2 (r5x4)
        LDR r6, [r2, r5]		;increase the board by offset r5 and load the coordinate in r6
        BIC r6, r6, #0x00000800	;bit clear to clear 11th bit
        STR r6, [r2,r5]			;clear previous Q
		LDR r6, =X				;load the X coordinate address in r6
		LDRB r5, [r6]			;load X coordinate in r5
		LDR r7, =Y				;load the Y coordinate address in r7
		LDRB r6, [r7]			;load the Y coordinate in r6
        BL getindex				;branch and link to getindex
        STRB r0, [r3]			;store index
        LSL r0, r0, #2			;left shift r0 by 2(r0x4)
        LDR r4, [r2,r0]			;r0 is index from getindex
		;AND r6, r4, #0x00000100
        ;MOV r0, #10 ;argument to increment score by 10
        ;CMP r6, #0
        ;BLEQ incrementscore
        ORR r4, r4, #0x00000900	;Set Q on that sport and mark as stepped on
		LDR r5, [r2, r0]		;load the updated value at latest position on board
		AND r5, r5, #0x00000100	;check the 8th bit
		;LDRB r5, [r2, r0]
		CMP r5, #0				;compare the 8th bit to 0
		BNE sco					;branch on not equal to sco
		BL incrementscore		;branch and link to increment score by 10
		LDR r8, =squarecounter	;load the address of squarecounter in r8
		LDRB r9, [r8]			;load contents of squarecounter in r9
		ADD r9, r9, #1			;increment r9 by 1
		STRB r9, [r8]			;store the updated value back in squarecounter
sco
		STR r4, [r2,r0]			;r0 as index is added to board where r4 is stored
        LDMFD SP!, {lr,r2,r3,r6,r7,r4,r0,r5,r8,r9}
        BX LR
downleft
        LDR r4, =X				;load the X coordinate address of Q
        LDRB r5, [r4]			;get the X coordinate in r5
        LDR r3, =Y				;load the Y coordinate address of Q
        LDRB r6, [r3]			;get the Y coordinate in r6
        CMP r6, #5				;compare X to 5, will die if X is 5
        BEQ deathhandleredge	;branch on equal to deathhandleredge(player fell off the map)
        ADD r6, r6, #1			;increment Y coordinate by 1
        STRB r6, [r3]			;store updated Y back in Y
        BL storeQ				;branch and link to storeQ
        B endmove				;branch to endmove
downright
        LDR r4, =X				;load the X coordinate address of Q
        LDRB r5, [r4]			;get the X coordinate in r5
        LDR r3, =Y				;load the Y coordinate address of Q
        LDRB r6, [r3]			;get the Y coordinate in r6
        CMP r6, #5				;compare Y to 5, will die if Y is 5
        BEQ deathhandleredge	;branch on equal to deathhandleredge(player fell off the map)
        ADD r6, r6, #1			;increment Y coordinate by 1
        ADD r5, r5, #1			;decrement X coordinate by 1
        STRB r6, [r3]			;store updated Y back in Y
        STRB r5, [r4]			;store updated X back in X
        BL storeQ				;branch and link to storeQ
        B endmove				;branch to endmove
upright
        LDR r4, =X				;load the X coordinate address of Q
        LDRB r5, [r4]			;get the X coordinate in r5
        LDR r3, =Y				;load the Y coordinate address of Q
        LDRB r6, [r3]			;get the Y coordinate in r6
        CMP r6, r5				;does x=y?
        BEQ deathhandleredge	;branch on equal to deathhandleredge(player fell off the map)
        SUB r6, r6, #1			;decrement Y coordinate by 1
        ;ADD r5, r5, #1
        STRB r6, [r3]			;store updated Y back in Y
        ;STRB r5, [r4];store X
        BL storeQ				;branch and link to storeQ
		B endmove				;branch to endmove
deathhandleredge
		;deathhandler for life lost due to player falling off the map 
		LDR r4, =lives			;load the lives
		LDRB r0, [r4]			;get the number of lives
		LSR r0, r0, #1			;decrement the number of lives by 1 (right shift by 1)
		STRB r0, [r4]  			;store the updated value back in lives
		BL illuminateLEDs		;branch and link to illumnateLEDs to show led
		MOV r4, #10				;set r4 to 10
		LDR r0, =blinkcounter	;load the blinkcounter in r0
		STRB r4, [r0]			;update the blinkcounter to 10
		BL ClearEnemys			;branch and link to clear enemies off the board
		MOV r6, #0				;set Y coordinate of Q to 0
		MOV r5, #0				;set X coordinate of Q to 0
		LDR r4, =X				;load the X coordinate address of Q
        STRB r5, [r4]			;set the X coordinate in r5
        LDR r3, =Y				;load the Y coordinate address of Q
        STRB r6, [r3] 			;set Y coordinate to 0
		BL storeQ				;branch and link to storeQ to update position of Q
        B endmove				;branch to endmove
endmove
		;end player movement
		LDR r4, =direction		;load the direction in r4
		MOV r3, #0				;set r3 to 0
		STRB r3, [r4]			;set direction to 0
        LDMFD SP!, {r0,r2,r3,r4,r5,r6,r7,r8,r9,lr}
        BX lr
getindex
		;get the index of coordinate of the board
        STMFD SP!, {r1-r4,lr}
        MOV r3, r6				;set r3 to r6
		MOV r0, #0				;set r0 to 0
		CMP r3, #0				;compare r3 to 0
		BEQ endloop1			;branch on equal to endloop1
loop1
		;algorithm for converting X and Y to index
        ADD r0, r6, r0			;increment r0 by r6 and place value in r0
        SUB r3, r3, #1			;decrement r3 by 1
        SUB r0, r0, r3			;decement r0 by r3
        CMP r3, #0				;compare r3 to 0
        BNE loop1				;branch on not equal to loop1 to loop again
endloop1
        ADD r0, r0, r5			;increment r0 by r5 and place result in r0
        LDMFD SP!, {r1-r4,lr}
        BX lr
CheckDeath
		;check whether player has died due to collision with enemy
        STMFD SP!, {r0-r5,lr}
        LDR r4, =Board			;load the Board array in r4
        MOV r3, #21				;set r3 to 21(21 coordinates on board)
Cleardeathloop
        SUB r3, r3, #1			;decrement r3 by 1
		CMP r3, #-1				;compare r3 to -1
		BEQ endcheckdeath		;branch on equal to end checking for death
		LSL r5, r3, #2 			;left shift r3 by 2(r3x4)
        LDR r2, [r4,r5]			;add the offset to board and load from the latest position
        AND r1, r2, #0x00000600	;check the 10th bit
        CMP r1, #0				;compare 10th bit to 0
        BEQ Cleardeathloop		;branch on equal to Cleardeathloop 
        AND r1, r2, #0x00000800	;check the 11th bit
        CMP r1, #0				;check 11th bit to 0
        BEQ Cleardeathloop		;branch on equal to Cleardeathloop
        LDR r4, =lives			;load the lives in r4
		LDRB r0, [r4]			;get the number of lives
		LSR r0, r0, #1			;reduce the number of lives by 1
		STRB r0, [r4] 			;stored the updated lives to lives variable
		BL illuminateLEDs		;branch and link to illuminateLEDs on ARM board
		MOV r4, #10				;set r4 to 10
		LDR r0, =blinkcounter	;load the blinkcounter
		STRB r4, [r0]			;make the blinkcounter as 10
		BL ClearEnemys			;branch and link to clear enemies from board 
endcheckdeath
        LDMFD SP!, {r0-r5,lr}
        BX lr
ClearEnemys
        ;clear enemies on the board
        STMFD SP!, {r0-r4,lr}
        LDR r4, =Board			;load Board in r4
        MOV r3, #21				;set r3 to 21
Clearenemyloop
        SUB r3, r3, #1			;decrement r3 by 1
        LDR r2, [r4]			;load board contents in r2
        BIC r2, #0x00000600		;bit clear 9th bit
        STR r2, [r4],#4			;increment board address by 4 and store r2 in r4
        CMP r3, #0				;compare r3 to 0
        BNE Clearenemyloop		;branch on not equal clearenemyloop
		LDR r4, =Balls			;load Balls array in r4
		MOV r3, #28				;set r3 to 14
Clearballloop
		SUB r3, r3, #1			;decrement r3 by 1
        MOV r2, #0				;set r2 of 0
        STRH r2, [r4],#2		;update r4 by 2 and store r2 in r4
        CMP r3, #0				;compare r3 to 0
		BNE Clearballloop		;branch on not equal to clear ball loop
		LDR r4, =snake			;load snake in r4
		STRH r3, [r4]			;store r3 in snake
		LDR r4, =snakeballcounter	;load snakeballcounter in r4
		STRB r3, [r4]			;store r3 in r4
        LDR r4, =snakeballtimer	;load snakeballcounter in r4
		STRB r3, [r4]			;store r3 in r4
        LDMFD SP!, {r0-r4,lr}
        BX lr
updatemap
		;update the map to clear positions and fill positions
		STMFD SP!, {r0-r12,lr}
		MOV r4, #21 			;set r4 to 21 (counter)
		LDR r3, =Board			;load board array in r3
ClearLoop
		SUB r4, r4,#1			;decrement r4 by 1
		LDR r2, [r3]			;load board
		LDR r7, =0x003FF0000	;load 0x3FF0000 in r7	
		AND r2, r2, r7			;Anding r2 to r7 (Memory Offset bits)
		LSR r2, #16				;load first Memory offset by right shifting 16 places
		LDR r5, =prompt2		;load prompt2 in r5
		ADD r5, r2, r5			;add offset to r5
		MOV r1, #32				;set r1 to 32
		STRB r1, [r5],#1		;store space in r5 increment address by 1
		STRB r1, [r5]			;store space in r5
		ADD r3, r3, #4			;increment r3 by 4
		CMP r4, #0				;compare r4 to 0
		BNE ClearLoop			;branch on not equal to clear loop (loop again)
		MOV r4, #21 			;r4 is counter (21)
		LDR r3, =Board			;load Board array in r3
FillLoop
		SUB r4, r4, #1			;decrement r4 by 1
		LDR r2, [r3]			;load contents of Board array in r2
		AND r2, r2, #0x0000100	;check space has been stepped on
		CMP r2, #0				;compare r2 to 0
		BEQ notpressed			;branch on equal to notpressed
		MOV r1, #42				;set r1 to 42 (ascii *)	
		LDR r2, [r3]			;load board
		LDR r7, =0x003FF0000	;load r7 to 0x3FF0000
		AND r2, r2, r7			;Anding r2 to r7 (Memory Offset bits)
		LSR r2, #16				;load first Memory offset by right shifting 16 places
		LDR r5, =prompt2		;load prompt2 by r5
		ADD r5, r5, r2			;add offset to r5
		STRB r1, [r5]			;store *
		;BL incrementscore
notpressed
		LDR r2, [r3]			;load r3 in r2
		AND r2, r2, #0x0000600	;check space has been stepped on
		CMP r2, #0x00			;compare r2 to 0
		BEQ noenemy				;branch on equal to noenemy
		CMP r2, #0x600			;compare r2 to 0x600
		BEQ snake1				;branch on equal to snake1
		CMP r2, #0x200			;compare r2 to 0x200
		BEQ CBall				;branch on equal to CBall
		CMP r2, #0x400			;compare r2 to 0x400
		BEQ OBall				;branch on equal to OBall
snake1
		;snake enemy on board
		MOV r1, #83				;set r1 to 83, ascii S
		LDR r2, [r3]			;load board
		LDR r7, =0x003FF0000	;load r7 to 0x3FF0000
		AND r2, r2, r7			;Anding r2 to r7, Memory Offset bits
		LSR r2, #16				;load first Memory offset by left shifting 16 places
		LDR r5, =prompt2		;load prompt2 in r5
		ADD r5, r5, r2			;add offset
		STRB r1, [r5,#1]		;store *
		B noenemy				;branch to noenemy
CBall
		;C enemy on board
		MOV r1, #67				;set r1 to 67, ascii C
		LDR r2, [r3]			;load board
		LDR r7, =0x003FF0000	;load r7 to 0x3FF0000
		AND r2, r2, r7			;Anding r2 to r7, Memory Offset bits
		LSR r2, #16				;load first Memory offset by left shifting 16 places
		LDR r5, =prompt2		;load prompt2 in r5
		ADD r5, r5, r2			;add offset
		STRB r1, [r5,#1]		;store *
		B noenemy				;branch to noenemy
OBall
		;O enemy on board
		MOV r1, #79				;ascii O
		LDR r2, [r3]			;load board
		LDR r7, =0x003FF0000	;load r7 to 0x3FF0000
		AND r2, r2, r7			;Anding r2 to r7, Memory Offset bits
		LSR r2, #16				;load first Memory offset by left shifting 16 places
		LDR r5, =prompt2		;load prompt2 in r5
		ADD r5, r5, r2			;add offset
		STRB r1, [r5,#1]		;store *
		;B noenemy
noenemy
		;no enemy is on the board
		LDR r2, [r3]			;load board
		AND r2, r2, #0x00000800	;check space has been stepped on
		CMP r2, #0x00			;compare r2 to 0
		BEQ noQ					;branch on equal to noQ
		MOV r1, #81				;set r1 to 81, ascii Q
		LDR r2, [r3]			;load board
		LDR r7, =0x003FF0000	;load r7 to 0x3FF0000
		AND r2, r2, r7			;Anding r2 to r7, Memory Offset bits
		LSR r2, #16				;load first Memory offset by left shifting 16 places
		LDR r5, =prompt2		;load prompt2 in r5
		ADD r5, r5, r2			;add offset
		STRB r1, [r5]			;store Q, dont overwrite an *
noQ
		;no Q is on board
		ADD r3, r3, #4			;increment r3 by 4
		CMP r4, #0				;compare r4 to 0
		BNE FillLoop			;branch to not equal to FillLoop
		;BL printmap
		LDMFD SP!, {r0-r12,lr}
		BX lr
randomgenerator
		;random number in r0 by using Timer1
        STMFD SP!, {r1,r4,lr}
        LDR r1, =0xE0008008		;load address of TC1 in r1
        LDR r0, [r1]			;load the contents in r0
        LDMFD SP!, {r1,r4,lr}
		BX lr

levelup
		;only execute if all * are changed to space or vice versa, keep count in fillloop i guess
		;start the level with level 0 and increase it 1 by 1
		;can increase opponents speed if level increases
		STMFD SP!, {r0-r3,lr}
		;make sure that r0 is -1 at first
		LDR r1, =level				;load current level in r1 
		LDRB r0, [r1]				;load r1 to r0
		CMP r0, #0					;compare r0 to 0
		BEQ lev						;branch on equal to lev
		BL incrementscoreL			;branch and link to incrementscoreL
lev
		ADD r0, r0, #1				;initially before game starts r0=-1 (before this instruction executes) 
		STRB r0, [r1]				;store r0 to r1
		
		BL display_digit_on_7_seg	;branch to display display_digit_on_7_seg
		;decrease the period by 0.1 seconds, once rate becomes 0.1 seconds it is capped
		BL decrementtimer
		;BL incrementscoreL
		;i think we dont need BX lr since when it levels up, it should go to start
		;B start
		LDMFD SP!, {r0-r3,lr}
		BX lr

incrementscore
		;for score of Q discovering new tiles
		STMFD SP!, {r0-r2,r9,lr}
		LDR r2, =score			;load the count address in r2
		LDRH r1, [r2]			;load(half word) count in r1 
		ADD r1, r1, #10			;increase the score by 10 for discovering new place				
		STRH r1, [r2]			;store the count back in the score variable
		;jump to divide over here to change the score to ascii and put it back in variable
		LDR r2, =score			;load score address
		LDRH r0, [r2]			;load the contents
		LDR r9, =prompt6		;load the prompt6
		ADD r9, r9, #9			;get to the pointer after score:
		BL Divide				;convert to ascii and store it in prompt  
		;note that Divide will automatically store in prompt
		LDMFD SP!, {r0-r2,r9,lr}
		BX LR
incrementscoreL
		;for score after every level
		STMFD SP!, {r0-r2,r9,lr}
		LDR r2, =score			;load the score
		LDRH r1, [r2]			;load the contents
		ADD r1, r1, #100		;increment the score by 100
		STRH r1, [r2]			;store the score back in the variable
		;jump to divide over here to change the score to ascii and put it back in variable
		LDR r2, =score			;load score address
		LDRH r0, [r2]			;load the contents
		LDR r9, =prompt6		;load the prompt6
		ADD r9, r9, #9			;get to the pointer after score:
		BL Divide				;convert to ascii and store it in prompt  
		LDMFD SP!, {r0-r2,r9,lr}
		BX LR
incrementscoreEnd
		;for score after the game ends
		STMFD SP!, {r0-r5,r9,lr}
		LDR r2, =score			;load the score
		LDRH r1, [r2]			;load the contents
		LDR r4, =lives			;load the number of lives
		LDRB r3, [r4] 			;load the contents
		AND r5, r3, #0x01		;check for last bit
		CMP r5, #1				;if last bit=1
		BEQ incScore1			;branch to incScore1 to increase score
		B incScore2				;or else branch to incScore2

incScore1
		ADD r1, r1, #25			;add the score by 25 for each life

incScore2		
		LSR r3, r3, #1			;right shift by 1
		AND r5, r3, #0x01		;check for last bit
		CMP r3, #0				;if last bit=0
		BEQ incScore3			;branch to incScore3
		CMP r5, #1				;if last bit=1
		BEQ incScore1			;increase score by 25
		

incScore3
		STRH r1, [r2]			;store the score back in variable
		;jump here to Divide to convert score in ascii and display it back on screen
		LDR r2, =score			;load score address
		LDRH r0, [r2]			;load the contents
		LDR r9, =prompt6		;load the prompt6
		ADD r9, r9, #9			;get to the pointer after score:
		BL Divide				;convert to ascii and store it in prompt  
		LDMFD SP!, {r0-r5,r9,lr}
		BX LR


Divide
		STMFD SP!, {r1-r8,r10-r12,lr}
		MOV r1, #1000
		MOV r6, #0
DIV
		CMP r6, #0				;compare r6 to 0
		BNE DIV0				;branch on not equal to DIV1
		;LDR r2, =score			;load address of count in r2
		;LDRH r0, [r2]			;load(half word) count in r0
		BL div_and_mod1			;branch and link to div_and_mod
		MOV r7, r0				;store quotient in r7
		ADD r7, r7, #48			;covert to ascii
		;CMP r7, #0x30
		;BEQ nonzero
		;LDR r9, =prompt1		;load address of prompt1 in r9
		;ADD r9, r9, #20			;to get to end of the string add 20
		STRB r7, [r9], #1		;store ascii in memory
		ADD r6, r6, #1			;increment the flag by 1
		B DIV					;branch to DIV

DIV0
		CMP r6, #1				;compare r6 to 1
		BNE DIV1				;branch on not equal to DIV2
		MOV r0, r1				;r0=dividend
		MOV r1, #100				;divisor=10
		BL div_and_mod1			;branch and link to div_and_mod
		MOV r7, r0				;store quotient in r7
		ADD r7, r7, #48			;covert to ascii
		STRB r7, [r9], #1		;store ascii in memory
		ADD r6, r6, #1			;increment flag by 1
		B DIV					;branch to DIV

DIV1
		CMP r6, #2				;compare r6 to 1
		BNE DIV2				;branch on not equal to DIV2
		MOV r0, r1				;r0=dividend
		MOV r1, #10				;divisor=10
		BL div_and_mod1			;branch and link to div_and_mod
		MOV r7, r0				;store quotient in r7
		ADD r7, r7, #48			;covert to ascii
		STRB r7, [r9], #1		;store ascii in memory
		ADD r6, r6, #1			;increment flag by 1
		B DIV					;branch to DIV

DIV2
		CMP r6, #3				;compare r6 to 1
		BNE DIV3				;branch on not equal to DIV2
		MOV r0, r1				;r0=dividend
		MOV r1, #1				;divisor=10
		BL div_and_mod1			;branch and link to div_and_mod
		MOV r7, r0				;store quotient in r7
		ADD r7, r7, #48			;covert to ascii
		STRB r7, [r9], #1		;store ascii in memory
		ADD r6, r6, #1			;increment flag by 1
		B DIV					;branch to DIV

DIV3
		LDMFD SP!, {r1-r8,r10-r12,lr}
		BX LR
		LTORG

QUIT
		BL incrementscoreEnd	;increment the score based on lives left
		MOV r0, #0x00060000		;make LED purple
		BL Illuminate_RGB_LED	;branch and link to Illuminate_RGB_LED
		BL printmap				;branch and link to printmap
		MOV r0, r0				;NOP
		END	
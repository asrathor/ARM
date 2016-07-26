	AREA interrupts, CODE, READWRITE
	EXPORT lab6
	EXPORT FIQ_Handler
	IMPORT display_digit_on_7_seg
	IMPORT uart_init
	IMPORT read_character
	IMPORT output_character
	IMPORT read_string
	IMPORT output_string
    IMPORT div_and_mod
RV DCW 0x0000; 0-230 in grid (1 byte)
MP DCW 0x0020; 0-300 (offset of prompt2. halfword) starts at 32 so random doesnt bug initially
X DCB 0x00 ;x coordinate
Y DCB 0x00 ;y coordinate
symbol DCB 0x00 ;symbol of character in prompt
direction DCB 0x00 ;direction of character
count DCW 0x0000 ;count of walls hit
promptt = "\n\rLets fucking play Q'bert!!\n\r",0
promptt1 = "\n\rPress Enter to Continue\n\r",0
promptt2 = "\n\rWhat you wanna do?\n\r-> Press i for instructions\n\r-> Press enter to start the game\n\r-> Press Q to quit\n\r",0
promptt3 = "\n\rInstructions:\n\r1. Control the Q'bert with keys w,a,s,d\n\r2. Convert all the * to space before the timer runs out.\n\r3. o and c are your enemies. Dont let them catch you!\n\r",0
promptt4 = "\n\r           __          \n\r          /  /|          \n\r         /__/ |__        \n\r         |  | /  /|        \n\r         |__|/__/ |__      \n\r         /  /|  | /  /|      \n\r        /__/ |__|/__/ |__    \n\r        |  | /  /|  | /  /|    \n\r        |__|/__/ |__|/__/ |__  \n\r        /  /|  | /  /|  | /  /|  \n\r       /__/ |__|/__/ |__|/__/ |__\n\r       |  | /  /|  | /  /|  | /  /|\n\r       |__|/__/ |__|/__/ |__|/__/ |\n\r      /  /|  | /  /|  | /  /|  | /\n\r     /__/ |__|/__/ |__|/__/ |__|/ \n\r    |  | /  /|  | /  /|  | /     \n\r    |__|/__/ |__|/__/ |__|/      \n\r   /  /|  | /  /|  | /             \n\r  /__/ |__|/__/ |__|/             \n\r  |  | /  /|  | /                 \n\r  |__|/__/ |__|/                  \n\r /  /|  | /                      \n\r/__/ |__|/                       \n\r|  | /                           \n\r|__|/                            \n\r",0
prompt = "\n\rPress Enter to Start\n\r",0
prompt1 = "\n\rWalls Encountered:000\n\r",0
prompt2 = "\n\r|---------------------|\n\r|                     |\n\r|                     |\n\r|                     |\n\r|                     |\n\r|                     |\n\r|                     |\n\r|                     |\n\r|                     |\n\r|                     |\n\r|                     |\n\r|                     |\n\r|---------------------|\n\r",0	
    ALIGN

lab6	 	
	STMFD sp!, {lr}
	; Your lab 5 code goes here...
	BL uart_init			;branch and link to uart_init
	BL timer_init			;branch and link to timer_init
	LDR r4, =promptt		;load promptt in r4
	BL output_string
	LDR r4, =promptt1
	BL output_string
	BL read_string
	LDRB r6, [r4]
	CMP r6, #10
	BNE read_string
menu	
	LDR r4, =promptt2
	BL output_string
	BL read_string	
	LDRB r6, [r4, #-2]
	CMP r6, #115
	BEQ displaypyramid
	CMP r6, #113
	BEQ QUIT
	CMP r6, #105
	BEQ displayinstruction
	BL read_string

displayinstruction	
	LDR r4, =promptt3
	BL output_string
	B menu

displaypyramid
	LDR r4, =promptt4		;load prompt in r4
	BL output_string		;branch and link to output_string
	B menu
	
	BL read_string			;branch and link to read_string
	LDR r4,=prompt1			;load register r4 with prompt1
	BL output_string		;branch and link to output_string
	BL interrupt_init		;branch and link to interrupt_init
    BL random				;branch and link to random
    BL randomdirection
	MOV r6, #12				;set r6 to 12 to clear the screen
	BL output_character		;branch and link to output_character
    LDR r4, =prompt1		;load r4 with prompt1
	BL output_string		;branch and link to output_string
	LDR r4, =prompt2		;load r4 with prompt2
    BL output_string		;branch and link to output_string
			
keepreading
	;BL read_string			;branch and link to read_string
	B keepreading			;branch to keepreading (loop again)
	LDMFD sp!,{lr}
	BX lr

uart0_interrupt_init
	

timer_init
        STMFD SP!, {r0-r2, lr}  ; Save registers
        ;set timer period

		;set timer period
		LDR r0, =0xE000801C		;load address MR1
		MOV r1, #230			;set r1 to 230
		STR r1, [r0]			;store r1 back in MR1

		;when TC == MR1 reset
		LDR r0, =0xE0008014		;load address in r0
		LDR r1, [r0]			;load the contents in r1
		ORR r1, r1, #0x10		;set the 4th bit to 1
		STR r1, [r0]			;store it back in r0

        ;enable TCR
		LDR r0, =0xE0008004		;load timer1 in r0
		LDR r1, [r0]			;load the contents in r1
		ORR r1, r1, #0x1		;set the last bit to 1
		STR r1, [r0]			;store it back in r0

        LDMFD SP!, {r0-r2, lr} ; Restore registers
		BX lr             	   ; Return

interrupt_init       
		STMFD SP!, {r0-r2, lr}  ; Save registers 
		;This section of code sets up uart0 interrupt when THRE (output character) is set
		LDR r0, =0xE000C004		;address of UOIER
		LDR r1, [r0]			;load the contents of UOIER in a register
		ORR r1, r1, #1			;set the second bit to 2
		STR r1, [r0]			;load the updated register back into UOIER
        ;This section of code makes the interrupt FIQ
		LDR r0, =0xFFFFF00C		;address of interrupt select register 
		LDR r1, [r0]			;load the contents into register r1
		ORR r1, r1, #0x50		;set the 6th bit to 1
		STR r1, [r0]			;load the updated register back to set as FIQ
        ;This section enables the interrupt
		LDR r0, =0xFFFFF010		;address of interrupt enable register
		LDR r1, [r0]			;load the contents into register r1
		ORR r1, r1, #0x50		;set the 6th, 5th, 4th bit to 1
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

		LDMFD SP!, {r0-r2, lr} ; Restore registers
		BX lr             	   ; Return



FIQ_Handler
		STMFD SP!, {r0-r4,r5,r6-r12, lr}   	; Save registers 

EINT1										; Check for EINT1 interrupt
		LDR r0, =0xE01FC140					
		LDR r1, [r0]
		TST r1, #2
		BEQ CheckInterrupt
		B push_button 						;go here if push button is pressed 
			
		; Push button EINT1 Handling Code
CheckInterrupt
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
		 B FIQ_Exit1			;branch to FIQ_Exit1

UART0handler
		LDR r3,=0xE000C000		;load address E000C000 in r3
		LDR r6, [r3]			;load the contents in r6
        CMP r6, #32				;quit if space, make sure to disable uart0 interrupts when printing prompt2
        BEQ QUIT				;branch on equal to QUIT
        CMP r6, #100			;compare r6 to 100(d)
        BEQ storedirection		;branch on equal to storedirection
        CMP r6, #108			;compare r6 to 108(l)
        BEQ storedirection		;branch on equal to storedirection
        CMP r6, #114			;compare r6 to 114(r)
        BEQ storedirection		;branch on equal to storedirection
        CMP r6, #117			;compare r6 to 117(u)
        BEQ storedirection		;branch on equal to storedirection
        B FIQ_Exit1 			;exit to FIQ_Exit1 if no valid input
storedirection
        LDR r3, =direction		;load r3 with address of direction
        STRB r6, [r3]			;direction will be 100, 108, 114, or 117 for down left right up
		B FIQ_Exit1				;branch to FIQ_Exit1

push_button
        LDR r0, =0xE01FC140		;load address of external interrupt flag register
		LDR r1, [r0]			;load the contents of above address
		ORR r1, r1, #0x2		;set the 1st bit to 1
		STR r1, [r0]			;store the updated result back in address
        BL random				;branch and link to random
		MOV r6, #12				;set r6 to 12
		BL output_character		;branch and link to output_character
        LDR r4, =prompt1		;load r4 with address prompt1
		BL output_string		;branch and link to output_string
		LDR r4, =prompt2		;load r4 with prompt2
        BL output_string		;branch and link to output_string
		B FIQ_Exit1				;branch to FIQ_Exit1
Timer0handler
		;create interrupt when TC == MR1 and resets
        LDR r2, =0xE0004000		;load address in r2
		LDR r1,[r2]				;load the contents in r1
		ORR r1, #2				;set the 1st bit to 1
		STR r1,[r2]				;store it back in r2

changedirection
		LDR r2, =direction		;load r2 with address direction
		LDRB r1,[r2]			;load the contents in r1
		CMP r1, #100			;compare r1 with 100(d)
		BEQ godown				;branch on equal to godown
		CMP r1, #108			;compare r1 with 108(l)
		BEQ goleft				;branch on equal to goleft
		CMP r1, #114			;compare r1 with 114(r)
		BEQ goright				;branch on equal to goright
		CMP r1, #117			;compare r1 with 117(u)
		BEQ goup				;branch on equal to goup
godown
		LDR r2, =Y				;load the Y address in r2
		LDRB r1, [r2]			;load the Y coordinate in r1
		CMP r1, #10				;compare r1 with 10
		BEQ wallhitdown			;branch on equal to wallhitdown
		ADD r1, r1, #1			;increment r1 by 1
		STRB r1, [r2] 			;store new Y value into Y
		MOV r0, #25				;argument passed into updatemap by setting r0 to 25
		BL updatemap			;branch and link to updatemap
		B FIQ_Exit1				;branch to FIQ_Exit1
goleft
		LDR r2, =X				;load the X address in r2 
		LDRB r1, [r2]			;load the X coordinate in r1
		CMP r1, #0				;compare r1 with 0
		BEQ wallhitleft			;branch on equal to wallhitleft
		ADD r1, r1, #-1			;decrement the coordinate by 1
		STRB r1, [r2] 			;store new Y value into Y
		MOV r0, #-1				;argument passed into updatemap by setting r0 to -1
		BL updatemap			;branch and link to updatemap
		B FIQ_Exit1				;branch to FIQ_Exit1
goright
		LDR r2, =X				;load the X address in r2
		LDRB r1, [r2]			;load the X coordinate in r1
		CMP r1, #20				;compare r1 with 20
		BEQ wallhitright		;branch on equal to wallhitright
		ADD r1, r1, #1			;increment r1 by 1
		STRB r1, [r2] 			;store new Y value into Y
		MOV r0, #1				;argument passed into updatemap by setting r0 to 1
		BL updatemap			;branch and link to updatemap
		B FIQ_Exit1				;branch to FIQ_Exit1
goup
		LDR r2, =Y				;load the Y address in r2
		LDRB r1, [r2]			;load the Y coordinate in r1
		CMP r1, #0				;compare r1 with 0
		BEQ wallhitup			;branch on equal to wallhitup
		SUB r1, r1, #1			;subtract r1 by 1
		STRB r1, [r2] 			;store new Y value into Y
		MOV r0, #-25			;argument passed into updatemap by setting r0 to -25
		BL updatemap			;branch and link to updatemap
		B FIQ_Exit1				;branch to FIQ_Exit1
wallhitdown
		BL incrementcount		;branch and link to incrementcount
		LDR r2, =direction		;load direction in r2
		MOV r1, #117 			;set r1 to 117(u)		
		STRB r1, [r2]			;store it back in direction address
		BL halvetimer			;branch and link to halvetimer
		B changedirection		;branch to changedirection
wallhitup
		BL incrementcount		;branch and link to incrementcount
		LDR r2, =direction		;load direction address in r2
		MOV r1, #100 			;set r1 to 100(d)	
		STRB r1, [r2]			;store it back in direction address
		BL halvetimer			;branch and link to halvetimer
		B changedirection		;branch to changedirection
wallhitleft
		BL incrementcount		;branch and link to incrementcount
		LDR r2, =direction		;load direction address in r2
		MOV r1, #114 			;set r1 to 114(r)
		STRB r1, [r2]			;store it back in direction address
		BL halvetimer			;branch and link to halvetimer
		B changedirection		;branch to changedirection
wallhitright
		BL incrementcount		;branch and link to incrementcount
		LDR r2, =direction		;load direction address in r2
		MOV r1, #108 			;set r1 to 108(l)	
		STRB r1, [r2]			;store it back in direction address
		BL halvetimer			;branch and link to halvetimer
		B changedirection 		;branch to changedirection
        ;handle timer below
				;branch to FIQ_Exit1
FIQ_Exit1
		LDMFD SP!, {r0-r4,r5,r6-r12, lr}
		SUBS pc, lr, #4			;return to interrupted instruction
halvetimer
		STMFD SP!, {r0,r1,lr}
		LDR r0, =0xE000401C		;load address in r0
		LDR r1, [r0]			;load contents in r1
		LSR r1, #1				;right shift r1 by 1 to half the time
		STR r1, [r0]			;store the new time back in r0
		LDMFD SP!, {r0,r1,lr}
		BX lr
random
        STMFD SP!, {r0,r1,r2,r3,r4,lr}
        LDR r3, =MP				;load memory pointer(MP) in r3
        LDRH r1, [r3]			;load(half word) memory pointer offset in r1
        MOV r2, #32 			;set r2 to 32(ascii space)
        LDR r3, =prompt2		;load address of prompt2 in r3
        ADD r3, r3, r1			;position of memory to update
        STRB r2, [r3]			;put space at spot of old MP

        BL randomgenerator		;branch and link to randomgenerator
        LDR r3, =RV				;load r3 with address of random variable(RV)
		STRH r0, [r3]			;store(half word) r0(random variable) in r3
        MOV r1, #21 			;set r1(divisor) to 21
        BL div_and_mod			;branch and link to div_and_mod
        LDR r3, =Y				;load r3 with address of Y
        STRB r0, [r3]			;store quotient in Y
        LDR r3, =X				;load r3 with address of X
        STRB r1, [r3]			;store remainder in X
        LSL r0, r0, #2 			;multiply quotient by 4
        LDR r3, =RV				;load r3 with address RV
		LDRH r4, [r3]			;load(half word) the random variable in r4
        ADD r0, r0, r4			;add RV to quotient
        ADD r0, r0, #28			;add 28 to r0
        LDR r3, =MP				;load r3 with address of MP
        STRH r0, [r3]			;store(half word) quotient back in MP
        BL randomgenerator		;branch and link to randomgenerator
        MOV r1, #4				;set r1 to 4(1 of 4 possible symbols)
        BL div_and_mod			;branch and link to div_and_mod
        CMP r1, #0				;compare r1 to 0(@)
        BEQ atsymbol			;branch on equal to atsymbol
        CMP r1, #1				;compare r1 to 1(*)
        BEQ starsymbol			;branch on equal to starsymbol
        CMP r1, #2				;compare r1 to 2(+)
        BEQ plussymbol			;branch on equal to plussymbol
        CMP r1, #3				;compare r1 to 3(X)
        BEQ Xsymbol				;branch on equal to Xsymbol
atsymbol
        MOV r0, #64				;set r0 to 64(@)
        B store					;branch to store
starsymbol
        MOV r0, #42				;set r0 to 42(*)
        B store					;branch to store
plussymbol
        MOV r0, #43				;set r0 to 43(+)
        B store					;branch to store
Xsymbol
        MOV r0, #88				;set r0 to 88
        B store					;branch to store
store
        LDR r3, =symbol			;load r3 with address symbol
        STRB r0, [r3]			;store symbol 
        LDR r3, =MP				;load r3 with address MP
        LDRH r4, [r3]			;load(half word) MP
        LDR r3, =prompt2		;load address of prompt2 in r3
        ADD r3, r3, r4			;address to store symbol (prompt2 + MP)
        STRB r0, [r3]			;store symbol

		LDMFD SP!, {r0,r1,r2,r3,r4,lr}
		BX lr
randomdirection
        STMFD SP!, {r0,r1,r2,r3,r4,lr}
        BL randomgenerator		;branch and link to randomgenerator
        MOV r1, #4				;set r1 to 4(1 of 4 possible symbols)
        BL div_and_mod			;branch and link to div_and_mod
        CMP r1, #0				;compare r1 to 0
        BEQ up					;branch on equal to up
        CMP r1, #1				;compare r1 to 1
        BEQ down				;branch on equal to down
        CMP r1, #2				;compare r1 to 2
        BEQ left				;branch on equal to left
        CMP r1, #3				;compare r1 to 3
        BEQ right				;branch on equal to right
up
        MOV r0, #117			;set r0 to 117(u)
        B store1				;branch to store1
down
        MOV r0, #100			;set r0 to 100(d)
        B store1				;branch to store1
left
        MOV r0, #108			;set r0 to 108(l)
        B store1				;branch to store1
right
        MOV r0, #114			;set r0 to 114(r)
        B store1				;branch to store1
store1
        LDR r3, =direction		;load the direction address in r3
        STRB r0, [r3]			;store direction

		LDMFD SP!, {r0,r1,r2,r3,r4,lr}
		BX lr
printmap
        STMFD SP!, {r0,r1,r4,r6,lr}

		MOV r6, #12				;set r6 to 12 to clear the screen
		BL output_character		;branch and link to output_character

        ;disable uart0
        LDR r0, =0xFFFFF010		;address of interrupt enable register
		LDR r1, [r0]			;load the contents into register r1
		BIC r1, r1, #0x40		;set the 6th, 5th, 4th bit to 1
		STR r1, [r0]			;store it back in interrupt enable register

		LDR r4, =prompt1		;load address of prompt1 in r4
		BL output_string		;branch and link to output_string

		LDR r4, =prompt2		;load address of prompt2 in r4
        BL output_string		;branch and link to output_string

        ;enable uart0
        LDR r0, =0xFFFFF010		;address of interrupt enable register
		LDR r1, [r0]			;load the contents into register r1
		ORR r1, r1, #0x40		;set the 6th, 5th, 4th bit to 1
		STR r1, [r0]			;store r1 back in interrupt enable register

        LDMFD SP!, {r0,r1,r4,r6,lr}
		BX lr
updatemap
		STMFD SP!, {r0,r1,r2,r3,r4,lr}
		LDR r2, =MP				;load address MP in r2
		LDRH r1, [r2]			;load(half word) previous MP in r1
		MOV r3, #32 			;set r3 to 32(ASCII space)
		LDR r4, =prompt2		;load address prompt2 in r4
		ADD r4, r4, r1			;increment r4 by 1
		STRB r3, [r4]			;erase previous symbol
		ADD r1, r1, r0	 		;add argument
		STRH r1, [r2]			;store(half word) MP in r2
		LDR r4, =prompt2		;load the address of prompt2 in r4
		ADD r4, r4, r1			;increment the address by r1
		LDR r1, =symbol			;load address of symbol in r1
		LDRB r3, [r1]			;load symbol in r3
		STRB r3, [r4]			;store the symbol in prompt2
		MOV r6, #12				;set r6 to 12 to clear the screen
		BL output_character		;branch and link to output_character
		LDR r4, =prompt1		;load address of prompt1 in r4
		BL output_string		;branch and link to output_string
		LDR r4, =prompt2		;load address of prompt2 in r4
        BL output_string		;branch and link to output_string
		LDMFD SP!, {r0,r1,r2,r3,r4,lr}
		BX lr
randomgenerator;random number in r0
        STMFD SP!, {r1,r4,lr}
        LDR r1, =0xE0008008		;load address of TC1 in r1
        LDR r0, [r1]			;load the contents in r0
        LDMFD SP!, {r1,r4,lr}
		BX lr
incrementcount
		STMFD SP!, {r0-r12,lr}
		LDR r2, =count			;load the count address in r2
		LDRH r1, [r2]			;load(half word) count in r1
		ADD r1, r1, #1			;increase count by 1
		STRH r1, [r2]			;store the count back in address
		
Divide
		MOV r1, #100			;divisor=100
		MOV r6, #0				;set r6(flag) to 0

DIV
		CMP r6, #0				;compare r6 to 0
		BNE DIV1				;branch on not equal to DIV1
		LDR r2, =count			;load address of count in r2
		LDRH r0, [r2]			;load(half word) count in r0
		BL div_and_mod			;branch and link to div_and_mod
		MOV r7, r0				;store quotient in r7
		ADD r7, r7, #48			;covert to ascii
		LDR r9, =prompt1		;load address of prompt1 in r9
		ADD r9, r9, #20			;to get to end of the string add 20
		STRB r7, [r9], #1		;store ascii in memory
		ADD r6, r6, #1			;increment the flag by 1
		B DIV					;branch to DIV

DIV1
		CMP r6, #1				;compare r6 to 1
		BNE DIV2				;branch on not equal to DIV2
		MOV r0, r1				;r0=dividend
		MOV r1, #10				;divisor=10
		BL div_and_mod			;branch and link to div_and_mod
		MOV r7, r0				;store quotient in r7
		ADD r7, r7, #48			;covert to ascii
		STRB r7, [r9], #1		;store ascii in memory
		ADD r6, r6, #1			;increment flag by 1
		B DIV					;branch to DIV
		
DIV2
		CMP r6, #2				;compare r6 to 2
		BNE DIV3				;branch on not equal to DIV3
		MOV r0, r1				;r0=dividend
		MOV r1, #1				;set the divisor to 1
		BL div_and_mod			;branch and link to div_and_mod
		MOV r7, r0				;set r7 as quotient
		ADD r7, r7, #48			;convert to ascii
		STRB r7, [r9], #1		;store ascii in memory
		ADD r6, r6, #1			;increment flag by 1
		B DIV					;branch to DIV

DIV3
		MOV r10, #0				;set r10 to 0
		STRB r10, [r9], #1		;store null pointer at the end
		
		LDMFD SP!, {r0-r12,lr}
		BX LR
QUIT
		MOV r0, r0				;NOP
		END	
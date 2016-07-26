	AREA interrupts, CODE, READWRITE
	EXPORT lab5
	EXPORT FIQ_Handler
	IMPORT display_digit_on_7_seg
	IMPORT uart_init
	IMPORT read_character
	IMPORT output_character
	IMPORT read_string
	IMPORT output_string
IO0DIR EQU 0xE0028008		;base address of port0 direction register
IO0CLR EQU 0xE002800C 		;base address for port0 clear register
prompt = "\n\rEnter characters, characters 0-f, (-0)-(-f) C and pushing the user interupt button will change the display. Press Q to end the program.\n\r",0
	
    ALIGN

lab5	 	
	STMFD sp!, {lr}

	; Your lab 5 code goes here...
	BL uart_init			;branch and link to uart_init
	BL InitializePins		;branch and link to InitializePins
	LDR r4,=0x40000000		;load register r4 with address 0x40000000
	BL output_string		;branch and link to output_string
	BL interrupt_init		;branch and link to interrupt_init
	LDR r9, =0x4000007D		;address of digit display
	MOV r8, #0				;set r8 to 0
	STR r8, [r9]			;load content of digit display in r8
    LDR r9, =0x40000082		;address of on/off indicator
	MOV r8, #0				;set r8 to 0 
	STR r8, [r9]			;load content of indicator in r8
	LDR r4,=0x40000000		;load register r4 back with address 0x40000000
keepreading
	BL read_string			;branch and link to read_string
	B keepreading			;branch to keepreading (loop again)
	LDMFD sp!,{lr}
	BX lr

InitializePins
	STMFD sp!,{lr,r6,r5};
	LDR r6, =IO0DIR		;load base address of direction register port 0
    LDR r5, =0x00003F80 ;set values to output for port 0
    STR r5, [r6]		;store the value set above in direction register
	LDMFD sp!,{lr,r6,r5}
    BX lr
uart0_interrupt_init
	

interrupt_init       
		STMFD SP!, {r0-r1, lr}  ; Save registers 
		
		LDR r0, =0xE000C004		;address of UOIER
		LDR r1, [r0]			;load the contents of UOIER in a register
		ORR r1, r1, #2			;set the second bit to 1
		STR r1, [r0]			;load the updated register back into UOIER

		LDR r0, =0xFFFFF00C		;address of interrupt select register 
		LDR r1, [r0]			;load the contents into register r1
		ORR r1, r1, #0x40		;set the 6th bit to 1
		STR r1, [r0]			;load the updated register back to set as FIQ

		LDR r0, =0xFFFFF010		;address of interrupt enable register
		LDR r1, [r0]			;load the contents into register r1
		ORR r1, r1, #0x40		;set the 6th bit to 1
		STR r1, [r0]			;load the updated register back to set for interrupts

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
		STMFD SP!, {r0-r4,r5,r6-r12, lr}   	; Save registers 

EINT1										; Check for EINT1 interrupt
		LDR r0, =0xE01FC140					
		LDR r1, [r0]
		TST r1, #2
		BEQ FIQ_Exit
		B push_button 						;go here if push button is pressed
		STMFD SP!, {r0-r4,r5,r6-r12, lr}   	; Save registers 
			
		; Push button EINT1 Handling Code
seven_seg
		CMP r6, #0				;compare r6 to 0
		BEQ FIQ_Exit1			;branch on equal to FIQ_Exit1
		;LDR r9, =0x40000064	;memory address of pointer to what r8 should be
		;LDR r8, [r9]
		LDR r9, =0x4000007D		;load the address of digit display
		LDR r5, [r9]			;load the contents of the above address in r5
		LDRB r0, [r4,#-2]  		;look for negative 2 spots back and load the contents of that address
		CMP r0, #45				;compare r0 to 45 (check for negative)
		BNE notnegative			;branch on not equal to notnegative
		MOV r7, #1				;set r7 to 1
notnegative
		LDRB r0,[r4, #-1] 		;look for one spot back and load the contents of that address
		CMP r0, #81				;compare to 81 (Q)			
		BEQ QUIT				;branch on equal to QUIT
		CMP r0, #113			;compare to 113 (q)
		BEQ QUIT				;branch on equal to QUIT

        LDR r9, =0x40000082		;load the address of on/off indicator
        LDRB r1, [r9]			;load the contents in a register
        CMP r1, #0				;compare that register to 0
        BEQ FIQ_Exit1 			;branch on equal to FIQ_Exit1 (display is off)

		CMP r0, #65		  		;compare to 65 (A) (convert capitol letters)
		BEQ CAPITOL				;branch on equal to CAPITOL
		CMP r0, #66				;compare to 66 (B)
		BEQ CAPITOL				;branch on equal to CAPITOL
        CMP r0, #67				;compare to 67 (C)
		BEQ CAPITOL				;branch on equal to CAPITOL
		CMP r0, #68				;compare to 68 (D)
		BEQ CAPITOL				;branch on equal to CAPITOL
		CMP r0, #69				;compare to 69 (E)
		BEQ CAPITOL				;branch on equal to CAPITOL
		CMP r0, #70				;compare to 70 (F)
		BEQ CAPITOL				;branch on equal to CAPITOL
		 
		CMP r0, #90				;compare to 90 (Z)
		BEQ EqualsZ				;branch on equal to EqualsZ
		CMP r0, #122			;compare to 122 (z)
		BEQ EqualsZ				;branch on equal to EqualsZ
back
		SUB r0, r0, #0x30		;convert from ascii if value is 0-9
    	CMP r0, #10				;convert from ascii if value is a-f
    	BLT lessthan10b			;branch on less than convert from ascii if value is a-f
    	SUB r0, r0, #39 		;convert from ascii if value is a-f
		CMP r0, #15				;convert from ascii if value is a-f
    	BGT FIQ_Exit1			;branch on greater than to check if value is a-f
		CMP r0, #10				;check if value is a-f is a-f
    	BLT FIQ_Exit1			;branch on less than to stop if it is not a-f
lessthan10b
		CMP r0, #0				;make sure is 0-9 (compare to 0)
		BLT FIQ_Exit1			;branch on less than to FIQ_Exit1
		CMP r7, #1			 	;compare to 1 to check for negative flag
		BEQ negative			;branch on equal to negative
		ADD r0, r5, r0			;add the previous to next 
		B next					;branch to next
negative
		SUB r0, r5, r0			;subtract the previous to next
next
		AND r0, r0, #0xF		;AND to check fo the last 4 bits
		LDR r9, =0x4000007D		;load the address of digit display
		STRB r0, [r9]			;store the updated number to display
    	BL display_digit_on_7_seg	;branch and link to display_digit_on_7_seg
		B FIQ_Exit1				;branch to FIQ_Exit1
EqualsZ
		MOV r0, #0				;set r0 to 0
		MOV r5, #0				;set r5 to 0
		LDR r9, =0x4000007D		;load the address of digit display
		STRB r0, [r9]			;store the updated number (zero) to display
		BL display_digit_on_7_seg	;branch and link to display_digit_on_7_seg
		B FIQ_Exit1				;branch to FIQ_Exit1
push_button
		LDR r9, =0x40000082		;load the address of on/off indicator
        LDRB r0, [r9]			;load the contents of the above address
        EOR r0, r0, #1			;use exclusive or for taking complement of above
		STRB r0, [r9]			;stores a 1 if display turns on, 0 if display turns off
		CMP r0, #1				;compare to 1 (turn 7seg off)
        BEQ turnon				;branch on equal to turnon
        ;the following code turns the 7 seg off
        LDR r9, =IO0CLR			;load base address of set register port 0
        LDR r1, [r9]			;load into r1, the value in set register
        LDR r0, =0x0003F80		;load r0 to set 13 bit to 1
        ORR r0,r1, r0 			;take the OR of r1 and r0
        STR r0, [r9]			;store the value calculated above into r9
		B FIQ_Exit1				;branch to FIQ_Exit1
turnon
        LDR r9, =0x4000007D		;load the address of digit display
		LDR r0, [r9]			;load the contents of above address
		;STRB r0, [r9]
    	BL display_digit_on_7_seg	;branch and link to display_digit_on_7_seg
        B FIQ_Exit1				;branch to FIQ_Exit1
		
		ldr r0, =prompt			;load address of prompt in r0
		ldr r1, =0x01234567		;load 0x01234567 in r1
		str r1, [r0]			;store r1 into prompt
		
		; End My code

		LDMFD SP!, {r0-r4,r5,r6-r12, lr}   ; Restore registers
		
		ORR r1, r1, #2			; Clear Interrupt
		STR r1, [r0]			;store the updated value in prompt
	
FIQ_Exit
		 LDR r2, =0xE000C008	;load address of UART0 Interrupt identification register
		 LDR r1, [r2]			;load the contents of above address
		 AND r1,r1, #0x00000001	;check for the 0 bit
		 CMP r1, #0				;if bit 0 = 0
		 BNE FIQ_Exit1			;branch on not equal to FIQ_Exit1
		 B seven_seg			;branch to seven_seg
FIQ_Exit1
		LDMFD SP!, {r0-r4,r5,r6-r12, lr}
		LDR r0, =0xE01FC140		;load address of external interrupt flag register
		LDR r1, [r0]			;load the contents of above address
		ORR r1, r1, #0x2		;set the 1st bit to 1
		STR r1, [r0]			;store the updated result back in address
		SUBS pc, lr, #4			;return to interrupted instruction
CAPITOL
		ADD r0, r0, #32			;make capital letters to small letters
		B back					;branch back
QUIT
		MOV r0, r0				;NOP
		END			
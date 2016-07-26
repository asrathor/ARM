	AREA    lib, CODE, READWRITE
	EXPORT uart_init
	EXPORT read_character
	EXPORT output_character
	EXPORT read_string
	EXPORT output_string
	EXPORT pin_connect_block_setup_for_uart0
    EXPORT Illuminate_RGB_LED
	EXPORT illuminateLEDs
    EXPORT div_and_mod
	EXPORT read_from_push_btns
	EXPORT display_digit_on_7_seg
PINSEL0 EQU 0xE002C000		;base address of pins 15-16 port 0 for setup
PINSEL1 EQU 0xE002C004		;base address of pins 16-31 port 0 for setup
IO0PIN EQU 0xE0028000		;base address of gpio port0 pin value register
IO1PIN EQU 0xE0028010		;base address of gpio port1 pin value register
IO0DIR EQU 0xE0028008 		;base address for port0 direction register
IO1DIR EQU 0xE0028018 		;base address for port1 direction register
IO0SET EQU 0xE0028004		;base address for port0 output register
IO1SET EQU 0xE0028014		;base address for port1 set register
IO0CLR EQU 0xE002800C		;base address for port0 clear register
IO1CLR EQU 0xE002801C		;base address for port1 clear register
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
uart_init
    STMFD sp!, {r0, r3, lr}
    LDR r0, =0xE000C00C		;enable divisor latch access
    MOV r3, #131;
    STRB r3,[r0]
    LDR r0, =0xE000C000		;set lower divisor latch for 9600 baud
    MOV r3, #1;	  baud rate = 1152000
    STRB r3,[r0]  
    LDR r0, =0xE000C004		;set upper divisor latch for 9600 baud
    MOV r3, #0;
    STRB r3,[r0]
    LDR r0, =0xE000C00C		;8bit word length 1 stop bit no parity
    MOV r3, #3;
    STRB r3,[r0]
    LDMFD sp!, {r0, r3, lr}
	BX lr 					;link back to program
read_character				;will overwrite r0, r1,r3, r5, r6
	STMFD sp!, {r3,r0,r1,r5,lr}
read_character1
    LDR r3,=0xE000C000    	;load the number into r0
    LDR r0,=0xE000C014    	;status register
    LDRB r1, [r0]			;read the byte entered by the user
    AND r5, r1, #0x0001     ;read the last byte or 8000 if the RDR is most significant
    CMP r5, #0            	;is r5==0? can you use LDRB and just compare then
    BEQ read_character1    	;branch back to main
    LDRB r6, [r3]        	;read byte from receive register
    BL output_character		;output character
	LDMFD sp!, {r3,r0,r1,r5,lr}
	BX lr
output_character 			;outputs character in r6
	STMFD sp!,{lr,r6}
output_character1
    LDR r3,=0xE000C000    	;load the number into r0
    LDR r0,=0xE000C014    	;status register
    LDRB r1, [r0]			;load status byte into r1 THRE is in position 5/7
    AND r2, r1, #32 		;test byte 5/7
    CMP r2, #0 				;compare with 0
    BEQ output_character1	;go back to
    STRB r6, [r3]			;store byte in transmit register
	LDMFD sp!,{lr,r6}
	BX lr
read_string
	STMFD sp!,{lr,r6}
read_string1
    BL read_character    	;read the incoming character
    STRB r6, [r4],#1    	;save the contents of the r4 in memory
    CMP r6,    #13          ;compare whether the character is enter character
    BNE read_string1        ;loop the read string again if enter was not hit
    MOV r6, #0    			;add null character to memory instead of enter character
    STRB r6, [r4,#-1]		;add null character to memory instead of enter character
    MOV r6, #10             ;go to next line
    BL output_character		;output character
	LDMFD sp!,{lr,r6}
    BX lr 					;go back
output_string				;input is r9 is pointer to first position in memory
	STMFD sp!,{lr,r6}
output_string1
    LDRB r6, [r4],#1		;load the byte from the address in r6 and increment the r9
    BL output_character		;output character
	LDRB r6, [r4]			;load the byte again from r9 into r6
	CMP r6, #0				;compare r6 to 0
	BNE output_string1		;branch on not equal to output_string1
	LDMFD sp!,{lr,r6}
    BX lr;
Illuminate_RGB_LED			;r0 is input
	STMFD sp!,{lr,r5,r6}
	MOV r5, #0x00260000		;r5 has bits 17, 18 and 21, 1
	LDR r6, =IO0SET			;set turns them off (using IO0SET)
	STR r5, [r6]			;turn them all off by storing r5 into IOSET
	LDR r6, =IO0CLR			;clear turns them on (using IO0CLR)
	STR r0, [r6]			;turn the selected LEDs on
	LDMFD sp!,{lr,r5,r6}
    BX LR
pin_connect_block_setup_for_uart0
    STMFD sp!, {r0, r1, lr}
    LDR r0, =0xE002C000  ; PINSEL0
    LDR r1, [r0]
    ORR r1, r1, #5
    BIC r1, r1, #0xA
    STR r1, [r0]
    LDMFD sp!, {r0, r1, lr}
    BX lr
illuminateLEDs
	STMFD sp!,{lr,r1,r6,r7,r3}
	LDR r1, =0x000F0000		;r1 has bits 16-19, 1
 	LDR r6, =IO1SET 		;address for port 1 set register
 	STR r1, [r6]  			;for setting the number of bits
	LDR r7, =IO1CLR  		;address for port 1 clear register
	CMP r0, #0				;compare r0 to 0
	BEQ zerob				;branch on equal to zerob
	CMP r0,#8				;convert to 1 
	BEQ	oneb				;branch on equal to oneb	
	CMP r0,#4				;convert to 2 
	BEQ	twob				;branch on equal to twob
	CMP r0,#12				;convert to 3 
	BEQ	threeb				;branch on equal to threeb
	CMP r0,#2				;convert to 2 
	BEQ	fourb				;branch on equal to fourb
	CMP r0,#10				;compare to 10 
	BEQ	fiveb				;branch on equal to fiveb
	CMP r0,#6				;compare to 6 			
	BEQ	sixb				;branch on equal to sixb
	CMP r0,#14				;compare to 14 	
	BEQ	sevenb				;branch on equal to sevenb
	CMP r0,#1				;compare to 1 
	BEQ	eightb				;branch on equal to eightb
	CMP r0,#9				;compare to 9 
	BEQ	nineb				;branch on equal to nineb
	CMP r0,#5				;compare to 5 
	BEQ	tenb				;branch on equal to tenb
	CMP r0,#13				;compare to 13 
	BEQ	elevenb				;branch on equal to elevenb
	CMP r0,#3				;compare to 3 
	BEQ	twelveb				;branch on equal to twelveb
	CMP r0,#11				;compare to 11 
	BEQ	thirteenb			;branch on equal to thirteenb
	CMP r0,#7				;compare to 7 
	BEQ	fourteenb			;branch on equal to fourteenb
	CMP r0,#15				;compare to 15	 
	BEQ	fifteenb			;branch on equal to fifteenb
	STMFD sp!,{lr,r6,r9}
	BX lr
zerob
	B next					;branch to next
oneb
	MOV r0, #1				;set r0 to 1
	B next					;branch to next	
twob
	MOV r0, #2				;set r0 to 2
	B next					;branch to next
threeb
	MOV r0, #3				;set r0 to 3
	B next					;branch to next
fourb
	MOV r0, #4				;set r0 to 4
	B next					;branch to next
fiveb
	MOV r0, #5				;set r0 to 5
	B next					;branch to next
sixb
	MOV r0, #6				;set r0 to 6
	B next					;branch to next
sevenb
	MOV r0, #7				;set r0 to 7
	B next					;branch to next
eightb
	MOV r0, #8				;set r0 to 8
	B next					;branch to next
nineb
	MOV r0, #9				;set r0 to 9
	B next					;branch to next
tenb
	MOV r0, #10				;set r0 to 10
	B next					;branch to next
elevenb
	MOV r0, #11				;set r0 to 11
	B next					;branch to next
twelveb
	MOV r0, #12				;set r0 to 12
	B next					;branch to next
thirteenb
	MOV r0, #13				;set r0 to 13
	B next					;branch to next
fourteenb
	MOV r0, #14				;set r0 to 14
	B next					;branch to next
fifteenb
	MOV r0, #15				;set r0 to 15
	B next					;branch to next
 	;MOV r8, #0x0F  		;only concerned about the last 4 bits that is port 16-19
 	;EOR r3, r1, r8  		;only need the last 4 bits
next
	LSL r0, #16				;left shift r0 by 16 bits
 	STR r0, [r7]  			;for clearing the complement of r1 and storing in the clear register
 	LDMFD sp!,{lr,r1,r6,r7,r3}
	BX lr
read_from_push_btns
	STMFD sp!,{lr,r6,r9}
	LDR r6, =IO1PIN			;set r6 as address of gpio pin port 1 value register
	LDR r9, =0x4000020a		;position to store read string
	STMFD sp!,{lr,r6}
    BL read_string			;read input (0, 1, 2, 3,4,5)
	LDMFD sp!,{lr,r6}		;after enter was hit
	LDR r0, [r6]			;load r6 to r0
	AND r0, #0x00F00000		;AND to make everything except 20-23, 0
	EOR r0,	#0x00F00000		;take complement of r0 by using exclusive OR
	LSR r0,#20				;right shift 20 places
	CMP r0, #0				;compare r0 to 0
	BEQ zero				;branch on equal to zero 
	CMP r0,#8				;convert to 1 (compare to 8) 
	BEQ	one					;branch on equal to one
	CMP r0,#4				;convert to 2 (compare to 4) 
	BEQ	two					;branch on equal to two
	CMP r0,#12				;convert to 3 (compare to 12) 
	BEQ	three				;branch on equal to three
	CMP r0,#2				;convert to 2 (compare to 2) 
	BEQ	four				;branch on equal to four
	CMP r0,#10				;compare to 10 
	BEQ	five				;branch on equal to five
	CMP r0,#6				;compare to 6 
	BEQ	six					;branch on equal to six
	CMP r0,#14				;compare to 14 
	BEQ	seven				;branch on equal to seven
	CMP r0,#1				;compare to 1 
	BEQ	eight				;branch on equal to eight
	CMP r0,#9				;compare to 9 
	BEQ	nine				;branch on equal to nine
	CMP r0,#5				;compare to 5 
	BEQ	ten					;branch on equal to ten
	CMP r0,#13				;compare to 13 
	BEQ	eleven				;branch on equal to eleven
	CMP r0,#3				;compare to 3 
	BEQ	twelve				;branch on equal to twelve
	CMP r0,#11				;compare to 11 
	BEQ	thirteen			;branch on equal to thirteen
	CMP r0,#7				;compare to 7 
	BEQ	fourteen			;branch on equal to fourteen
	CMP r0,#15				;compare to 15 
	BEQ	fifteen				;branch on equal to fifteen
	STMFD sp!,{lr,r6,r9}
	BX lr
zero
	STMFD sp!,{lr,r6,r9}
	BX LR
one
	MOV r0, #1				;set r0 to 1
	STMFD sp!,{lr,r6,r9}
	BX LR
two
	MOV r0, #2				;set r0 to 2
	STMFD sp!,{lr,r6,r9}
	BX LR
three
	MOV r0, #3				;set r0 to 3
	STMFD sp!,{lr,r6,r9}
	BX LR
four
	MOV r0, #4				;set r0 to 4
	STMFD sp!,{lr,r6,r9}
	BX LR
five
	MOV r0, #5				;set r0 to 5
	STMFD sp!,{lr,r6,r9}
	BX LR
six
	MOV r0, #6				;set r0 to 6
	STMFD sp!,{lr,r6,r9}
	BX LR
seven
	MOV r0, #7				;set r0 to 7
	STMFD sp!,{lr,r6,r9}
	BX LR
eight
	MOV r0, #8				;set r0 to 8
	STMFD sp!,{lr,r6,r9}
	BX LR
nine
	MOV r0, #9				;set r0 to 9
	STMFD sp!,{lr,r6,r9}
	BX LR
ten
	MOV r0, #10				;set r0 to 10
	STMFD sp!,{lr,r6,r9}
	BX LR
eleven
	MOV r0, #11				;set r0 to 11
	STMFD sp!,{lr,r6,r9}
	BX LR
twelve
	MOV r0, #12				;set r0 to 12
	STMFD sp!,{lr,r6,r9}
	BX LR
thirteen
	MOV r0, #13				;set r0 to 13
	STMFD sp!,{lr,r6,r9}
	BX LR
fourteen
	MOV r0, #14				;set r0 to 14
	STMFD sp!,{lr,r6,r9}
	BX LR
fifteen
	MOV r0, #15				;set r0 to 15
	STMFD sp!,{lr,r6,r9}
	BX LR
display_digit_on_7_seg
	STMFD sp!,{lr,r5,r1,r3,r2,r10,r7}
    LDR r1, =0xE0028000 	;base address for gpio port0 pin value register
    LDR r3, =digits_SET 	;base address for the array
 							;r0 should contain the number inputted by the user (not in ascii)
    MOV r0, r0, LSL #2 		;each stored value is 32 bits
    LDR r2, [r3, r0] 		;Load IOSET for digit pattern in r0
    ;AND r2, r2, #0x3F80
 	STR r2, [r1, #4] 		;Display (0x4 = offset to IOSET)
    LDR r6, =IO0CLR  		;base address for gpio pin clear register
    MOV r10, #0x3F80		;set r10 to 0x3F80
    EOR r7, r2, r10 		;take complement of r2 and store it in r7
    STR r7, [r6]  			;store the complement into clear register
    ;LDMFD sp!, {lr}  		;restore register lr from stack
	LDMFD sp!,{lr,r5,r1,r3,r2,r10,r7}
    BX lr
div_and_mod
	STMFD r13!, {r2-r12, lr};divisor is in r1, dividend/remainder in r0
	MOV r4, #0 ;r4 is 0 if you operands have same sign
	CMP r0, #0; compart dividend to r0
	BGT NEXT;
	RSB r0, r0, #0; #make dividend positive
	ADD r4, r4, #1;
NEXT
	CMP r1, #0;
	BGT NEXT1;
	RSB r1, r1, #0;#make divisor positive
	SUB r4, r4, #1;
NEXT1	
	MOV r2, #16 ;r12 is counter
	MOV r3, #0 ;initialize quotient to 0
	LSL r1, r1, #15;left shit divisor
LOOP
	SUB r2,r2,#1 ;decrement counter
	SUB r0, r0, r1;
	CMP r0, #0;
	BLT LOOP2;
	LSL r3, r3, #1; left shift quotient 1
	ADD r3, r3, #1 ; add 1 to quotiest so LSB is 1
	LSR r1, r1, #1; right shift divisor 1
	CMP r2, #0
	BGT LOOP
	BAL STOP
LOOP2
	ADD r0, r0, r1; add remainder to divisor
	LSL r3, r3, #1; left shift quotient
	LSR r1, r1, #1; right shift divisor 1
	CMP r2, #0
	BGT LOOP
STOP
	MOV r1, r0;remainder
	MOV r0, r3;quotient
	CMP r4, #0;
	BEQ NEXT3;
	RSB r0, r0, #0;negate quotient if r4 is not 0
NEXT3
	; Your code for the signed division/mod routine goes here.
	; The dividend is passed in r0 and the divisor in r1.
	; The quotient is returned in r0 and the remainder in r1.
	LDMFD r13!, {r2-r12, lr}
	BX lr ; Return to the C program
	END 
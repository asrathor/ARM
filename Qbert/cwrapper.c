extern int lab7(void);	
extern int pin_connect_block_setup_for_uart0(void);


int main()
{ 	
   pin_connect_block_setup_for_uart0();
   lab7();
}

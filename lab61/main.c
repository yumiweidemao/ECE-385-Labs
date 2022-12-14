// Main.c - makes LEDG0 on DE2-115 board blink if NIOS II is set up correctly
// for ECE 385 - University of Illinois - Electrical and Computer Engineering
// Author: Zuofu Cheng
/*
int main()
{
	unsigned int i = 0;

	volatile unsigned int *LED_PIO = (unsigned int*)0x70; //make a pointer to access the PIO block
	volatile unsigned int *SW_PIO = (unsigned int*)0x60;
	volatile unsigned int *Accumulate_PIO = (unsigned int*)0x50;

	*LED_PIO = 0; //clear all LEDs

	while ( (1+1) != 3) //infinite loop
	{	// during one button press
		if ( (*Accumulate_PIO) == 0 ) {
			// accumulate from switch
			i = ( i + (*SW_PIO) ) % 256 ;

			// run once
			while ( (*Accumulate_PIO == 0) ){}
		}

		// output to LED
		*LED_PIO = i;
	}

	return 1; //never gets here
}
*/


int main()
{
	int i = 0;
	volatile unsigned int *LED_PIO = (unsigned int*)0x70; //make a pointer to access the PIO block

	*LED_PIO = 0; //clear all LEDs
	while ( (1+1) != 3) //infinite loop
	{
		for (i = 0; i < 100000; i++); //software delay
		*LED_PIO |= 0x1; //set LSB
		for (i = 0; i < 100000; i++); //software delay
		*LED_PIO &= ~0x1; //clear LSB
	}
	return 1; //never gets here
}



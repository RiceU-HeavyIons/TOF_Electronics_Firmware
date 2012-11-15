/* $Id$ */
/**********************************************************************
*
* FileName:        main.c
* Dependencies:    Header (.h) files if applicable, see below
*
* REVISION HISTORY:
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* Author          	Date      Comments on this revision
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* Jatinder Gharoo 	10/30/08  First release of source file from Microchip
* JS 				5/25/2010 Modified for TOCK card
* 
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*
* HARDWARE USED: 
* PIC24HJ64GP502
* 
* SOFTWARE USED: 
* MPLAB IDE v8.53
* MPLAB C Compiler for PIC24 MCUs and dsPIC DSCs v 3.23b 
* 
* CAN CONFIGURATION USED:
* Bit Time = (Sync Segment + Propagation Delay + Phase Segment 1 + Phase Segment 2)=20TQ
* Phase Segment 1 = 8TQ
* Phase Segment 2 = 6Tq
* Propagation Delay = 5Tq
* Sync Segment = 1TQ
* BIT RATE OF 500kbps
* 
*	
* ADDITIONAL NOTES:
* Board Oscillator: 40 Mhz 
* CAN Bus speed: 500khz
* Filter for CAN messages with "standard" ID = 0x41X (X = don't care)
* 
*************************************************************************************************/

#include <p24HJ64GP502.h>

#include "ecan.h"
#include "delay.h"
#include "CAN_HLP3.h"

/*****************************************************************************************************
Configuration bits: 
_FOSCSEL: Start up with the FRC oscillator 
_FOSC: Use Primary oscillator EC w/ PLL, Two-speed Oscillator Startup enabled 
_FWDT: Watch dog timer is off
_FPOR: Power-on Reset Value disabled, Alternate I2C pins mapped to SDA1/SCL1
_FICD: JTAG is disabled,  communicate on PGC3/EMUC3 and PGD3/EMUD3 for explorer 16 development board  	
*****************************************************************************************************/
_FOSCSEL(FNOSC_FRC) 
_FOSC(FCKSM_CSECMD & POSCMD_EC)
_FWDT(FWDTEN_OFF)
_FPOR(FPWRT_PWR1)
_FICD(JTAGEN_OFF & ICS_PGD1)
        
/*****************************************************************************************************
Function Prototypes  
*****************************************************************************************************/
void oscConfig(void);

/*****************************************************************************************************
Globals   
*****************************************************************************************************/
mID canTxMessage;
mID canRxMessage;

/* Define ECAN Message Buffers */
ECAN1MSGBUF ecan1msgBuf __attribute__((space(dma),aligned(ECAN1_MSG_BUF_LENGTH*16)));


/*****************************************************************************************************
main() function 
*****************************************************************************************************/
int main ( void )
{	
	unsigned int j;

	/* Configure Oscillator Clock Source */
	oscConfig();

	/* unlock peripheral pin assignment registers */
	__builtin_write_OSCCONL(OSCCON & 0xBF) ; // set IOLOCK = 0

	/* Assign peripheral pins: ECAN1_Rx = RP4 */
	RPINR26bits.C1RXR = 4;

	/* Assign peripheral pins: ECAN1_Tx = RP3 */
	RPOR1bits.RP3R = 0x10;

	/* lock peripheral pin assignment registers */
	__builtin_write_OSCCONL(OSCCON | 0x40) ; // set IOLOCK = 1

	/* Configure ADC pins: AN4=analog, all others = digital */
	AD1PCFGL = 0x1fef;

	/* port A has nothing on it, configure as output, driving 0 */
	LATA = 0;
	TRISA = 0;

	/* Port B:
	* RB0  : Programmer (PGED1): output (doesn't matter?)
	* RB1  : Programmer (PGEC1): output (doesn't matter?)
	* RB2  : Temperature sensor (AN4): input
	* RB3  : CanTx: output
	* RB4  : CanRx: input
	* RB5  : Clock select: output (=1 for on-board osc.)
	* RB6  : nothing: output = 0
	* RB7  : nothing: output = 0
	* RB8  : nothing: output = 0
	* RB9  : nothing: output = 0
	* RB10 : nothing: output = 0
	* RB11 : nothing: output = 0
	* RB12 : reset out: output
	* RB13 : nothing: output = 0
	* RB14 : nothing: output = 0
	* RB15 : reset in: input
	*/
	
	LATB = 0x20; // clock select = 1
	TRISB = 0x8014;
	


	/* initialise CANbus and DMA for CANbus */				
	initECAN();
	initDMAECAN();
		
	/* Enable ECAN1 Interrupt */     	
	IEC2bits.C1IE=1;	
	/* enable Transmit interrupt */
	C1INTEbits.TBIE=1;
	/* Enable Receive interrupt */
	C1INTEbits.RBIE=1;
	
	/* configure and send a welcome alert message */
	canTxMessage.message_type=CAN_MSG_DATA;
	//canTxMessage.message_type=CAN_MSG_RTR;
	//canTxMessage.frame_type=CAN_FRAME_EXT;
	canTxMessage.frame_type=CAN_FRAME_STD;
	canTxMessage.buffer=0;
	canTxMessage.id = C_BOARD | C_ALERT;
	canTxMessage.data[0]=0xff;
	canTxMessage.data[1]=0x00;
	canTxMessage.data[2]=0x00;
	canTxMessage.data[3]=0x00;
	//canTxMessage.data[4]=0xab;
	//canTxMessage.data[5]=0xcd;
	//canTxMessage.data[6]=0xef;
	//canTxMessage.data[7]=0x55;
	canTxMessage.data_length=4;
	
	/* Delay for a second */
	Delay(Delay_1S_Cnt);
		
	/* send a CAN message */
	sendECAN(&canTxMessage);
		
	while(1)
	{
		//Delay(Delay_1S_Cnt);
		
		/* send a CAN message */
		//sendECAN(&canTxMessage);

		/* check to see when a message is received and move the message 
		into RAM and parse the message */ 
		if(canRxMessage.buffer_status==CAN_BUF_FULL)
		{
			rxECAN(&canRxMessage);

			if ( (canRxMessage.id & C_CODE_MASK) == C_WRITE ) { // WRITE command
				canTxMessage.id = C_BOARD | C_WRITE_REPLY;
				canTxMessage.data[0] = canRxMessage.data[0];
				canTxMessage.data[1] = C_STATUS_OK;
				canTxMessage.data_length = 2;

				switch (canRxMessage.data[0]) {
                    case C_WS_BUNCHRST:       // issue bunch reset
						j = PORTB;      // get current PORTB bits
						// these following 2 statements make the pulse about 50ns (2 clocks) wide
						LATB |= 0x1000;	// turn on "Reset Out" bit
						//__asm__ volatile ("nop");   // add this for another clock cycle
						LATB = j;       // turn off "Reset Out" bit
						break;

					default:
						canTxMessage.data[1] = C_STATUS_INVALID;       // ERROR REPLY
						break;
				}

			}
			else if ( (canRxMessage.id & C_CODE_MASK) == C_READ ) { // READ command
				canTxMessage.id = C_BOARD | C_READ_REPLY;
				canTxMessage.data[0] = canRxMessage.data[0];
				canTxMessage.data_length = 1;

				switch (canRxMessage.data[0]) {
					default:
						break;
				}
			}
			else {
				// otherwise: copy message to Tx buffer and echo
				canTxMessage.id = canRxMessage.id;
				canTxMessage.data_length = canRxMessage.data_length;
				int i;
				for (i=0; i<canRxMessage.data_length; i++)
					canTxMessage.data[i] = canRxMessage.data[i];
			}

			/* reset the flag when done */
			canRxMessage.buffer_status=CAN_BUF_EMPTY;

			// send the response
			sendECAN(&canTxMessage);
		}
		else
		;
		/*
		{
			// Test messages:
			// delay for one second 
			Delay(1);
			// send another message 
			canTxMessage.id++;
			sendECAN(&canTxMessage);
		}
		*/
	}
}

/*****************************************************************************************************
oscConfig() function 
*****************************************************************************************************/
void oscConfig(void){

	/*  Configure Oscillator to operate the device at 40MIPS
 	Fosc= Fin*M/(N1*N2), Fcy=Fosc/2
 	Fosc= 40M*32/(8*2)=80Mhz for 40Mhz input clock */

	PLLFBD=0x1e;				/* M=32 */
	CLKDIVbits.PLLPOST=0;		/* N2=2 */
	CLKDIVbits.PLLPRE=6;		/* N1=8 */
	OSCTUN=0;					/* Tune FRC oscillator, if FRC is used */
	
	/* Disable Watch Dog Timer */
	RCONbits.SWDTEN=0;
	
	/* Clock switch to incorporate PLL*/
	__builtin_write_OSCCONH(0x03);		// Initiate Clock Switch to Primary
										// Oscillator with PLL (NOSC=0b011)
	__builtin_write_OSCCONL(0x01);		// Start clock switching
	while (OSCCONbits.COSC != 0b011);	// Wait for Clock switch to occur

	/* Wait for PLL to lock */
	while(OSCCONbits.LOCK!=1) {};
}

/****** START OF INTERRUPT SERVICE ROUTINES *********/

/* Replace the interrupt function names with the    */
/* appropriate names depending on interrupt source. */

/* The names of various interrupt functions for     */
/* each device are defined in the linker script.    */


/* Interrupt Service Routine 1                      */
/* No fast context save, and no variables stacked   */
void __attribute__((interrupt,no_auto_psv))_C1Interrupt(void)  
{
	/* check to see if the interrupt is caused by receive */     	 
    if(C1INTFbits.RBIF)
    {
	    /* check to see if buffer 1 is full */
	    if(C1RXFUL1bits.RXFUL1)
	    {			
			/* set the buffer full flag and the buffer received flag */
			canRxMessage.buffer_status=CAN_BUF_FULL;
			canRxMessage.buffer=1;	
		}		
		/* check to see if buffer 2 is full */
		else if(C1RXFUL1bits.RXFUL2)
		{
			/* set the buffer full flag and the buffer received flag */
			canRxMessage.buffer_status=CAN_BUF_FULL;
			canRxMessage.buffer=2;					
		}
		/* check to see if buffer 3 is full */
		else if(C1RXFUL1bits.RXFUL3)
		{
			/* set the buffer full flag and the buffer received flag */
			canRxMessage.buffer_status=CAN_BUF_FULL;
			canRxMessage.buffer=3;					
		}
		else;
		/* clear flag */
		C1INTFbits.RBIF = 0;
	}
	else if(C1INTFbits.TBIF)
    {
	    /* clear flag */
		C1INTFbits.TBIF = 0;	    
	}
	else;
	
	/* clear interrupt flag */
	IFS2bits.C1IF=0;
}

/********* END OF INTERRUPT SERVICE ROUTINES ********/

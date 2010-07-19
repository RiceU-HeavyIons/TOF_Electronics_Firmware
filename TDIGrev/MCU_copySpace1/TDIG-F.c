// $Id: TDIG-F.c,v 1.2 2010-07-19 15:51:36 jschamba Exp $

// TDIG-F.c

/*	Copy 0x4000 addresses of Flash memory from location 0x6000 to 0x0 (code space 1) */

// Define implementation on the TDIG board (I/O ports, etc)
#define TDIG 1              // This is a TDIG board.
#define CONFIG_CPU 1		// Make TDIG-F_Board.h define the CPU options
#include "TDIG-F_Board.h"


// Define the library includes
#include "stddef.h"         // Standard definitions
#include "string.h"         // Definitions for string functions

// Define our routine includes
#include "rtspApi.h"		// Definitions of reprogramming routines



// Routines Defined in this module:
// MCU configuration / control
void clearIntrflags(void);	// Clear interrupt flags
void writePMRow(unsigned char *, unsigned long);
void read_MCU_pm (unsigned char *, unsigned long);
void writeConfRegByte(unsigned char, unsigned char);

/* MCU Memory and Reprogramming */
typedef unsigned short UWord16;
typedef unsigned long  UWord32;
typedef union tureg32 {
    UWord32 Val32;         // 32 bit value
    struct {
        UWord16 LW;         // 16 bit value lower
        UWord16 HW;         // 16 bit value upper
    } Word;
    unsigned char Val[4];            // array of chars
} UReg32;


// main routine
int main()
{
    unsigned long int lwork;
   	unsigned long int laddrs;
    unsigned int save_SR;           // image of status register while we block interrupts
    unsigned int i;        			// working indexes
	unsigned char readback_buffer[2048];        // readback general buffer

// be sure we are running from standard interrupt vector
    save_SR = INTCON2;
    save_SR &= 0x7FFF;  // clear the ALTIVT bit
    INTCON2 = save_SR;  // and restore it.

// We will want to run at priority 0 mostly
    SR &= 0x011F;          // Lower CPU priority to allow interrupts
    CORCONbits.IPL3=0;     // Lower CPU priority to allow user interrupts


/* 03-Jan-2007
** Initialize PORTD bits[4..9] pins [52, 53, 54, 55, 42, 43]
** for control of JTAG and EEPROM
*/
// Make D0 an output (pin 46 = MCU_TDC_TDI) initialize 0
// Make D1 an input  (pin 49 = MCU_TDC_TDO)
// Make D2 an output (pin 50 = MCU_TDC_TCK) initialize 0
// Make D3 an output (pin 51 = MCU_TDC_TMS) initialize 0
// Make D4 an input  (pin 52 = MCU_EE_DATA)
// Make D5 an output (pin 53 = MCU_EE_DCLK) initialize 0
// Make D6 an output (pin 54 = MCU_EE_ASDO) initialize 0
// Make D7 an output (pin 55 = MCU_EE_NCS)  initialize 1
// Make D8 an output (pin 42 = MCU_SEL_EE2) initialize 0
// Make D9 an output (pin 43 = MCU_CONFIG_PLD)  initialize 1
	LATD  = (0xFFFF & MCU_EE_initial & MCU_TDC_initial); // Initial bits
    TRISD = (0xFFFF & MCU_EE_dirmask & MCU_TDC_dirmask); // I/O configuration

/* this gives the following configuration
    MCU_EE_DCLK = 0;
    MCU_EE_ASDO = 0;
    MCU_EE_NCS = 1;
    MCU_SEL_EE2 = 0;
    MCU_CONFIG_PLD = 1;
*/
/* Port G bits used for various control functions
** Pin Port.Bit Dir'n Initial Signal Name
**   1    G.15  Out     1     MCU_TEST
**  62    G.14  Out     1     PLD_RESETB
**  64    G.13  Out     0     USB_RESETB
**  63    G.12  Out     1     PLD_DEVOE
**   8    G.9   Out     0     MCU_SEL_TERM
**   6    G.8   Out     1     MCU_SEL_LOCAL_OSC
**   5    G.7   Out     1     MCU_EN_LOCAL_OSC
**   4    G.6   Out     1     I2CA_RESETB
*/
    LATG = PORTG_initial;       // Initial settings port G (I2CA_RESETB must be Hi)
    TRISG = PORTG_dirmask;      // Directions port G
    MCU_SEL_TERM = 0;           // CAN terminator OFF

/* Initialize Port F bits for UCONFIG_IN, DCONFIG_OUT */
    TRISF = PORTF_dirmask;      // bit 3 is output
    DCONFIG_OUT = UCONFIG_IN;   // Bit 2 copied to output

/* Initialize Port B bits for output */
    AD1PCFGH = ANALOG1716;  // ENABLE analog 17, 16 only (RC1 pin 2, RC2 pin 3)
    AD1PCFGL = ALLDIGITAL;  // Disable Analog function from B-Port Bits 15..0

    LATB = 0x0000;          // All zeroes
    TRISB = 0xDFE0;         // Set directions

// Clear all interrupts
	clearIntrflags();
	

	unsigned int nvmAdru, nvmAdr;
	int temp;


    save_SR = SR;           // save the Status Register
    SR |= 0xE0;             // Raise CPU priority to lock out  interrupts

	// set watchdog timer configuration register to:
	// FWDTEN_OFF & WINDIS_OFF & WDTPRE_PR32 & WDTPOST_PS32768
	writeConfRegByte(0x6F, 0x0A);

	for (laddrs = 0; laddrs < 0x4000; laddrs += PAGE_ADDRESSES) {

		lwork = laddrs + 0x6000;
   		for (i=0; i<PAGE_BYTES; i+=4) {
    		read_MCU_pm ((unsigned char *)&readback_buffer[i], lwork);
        	lwork += 2;
    	} // end for loop over all bytes in save block

		//JS20090821: new routine to erase the page
		nvmAdru = (laddrs&0xffff0000) >> 16;
		nvmAdr = laddrs&0x0000ffff;
		temp = flashPageErase(nvmAdru, nvmAdr);


		lwork = laddrs;
		//JS20090821: here is the new row wise programming
		for(i=0; i<8; i++) {
			// each row is 256 bytes in the buffer, 
			// each instruction word is 24 bit instruction plus 8 bits dummy (0)
			writePMRow((unsigned char *)(readback_buffer + (i*256)), lwork);
			lwork += 128; // 2 * 64 instructions addresses, address advances by  2
		}
	}
    
	SR = save_SR;           // restore the saved status register

   	__asm__ volatile ("reset");  // do "reset" (_resetPRI)

	return 0;
}

void clearIntrflags(void){
/* Clear Interrupt Flag Status Registers */
// DMA1, ADC1, UART1, SP1, Timer3,2, OC2, IC2, DMA0, Timer1, OC1, IC1, INT0
    IFS0=0;                             // Interrupt flag Status Register 0

// UART2, INT2, Timer5,4, OC4,3, DMA2, IC8,7, AD2, INT1, CN1, I2C1M, I2C1S
    IFS1=0;                             // Interrupt flag Status Register 1

// Timer6, DMA4, OC8,7,6,5,4,3, DMA3, CAN1, SPI2, SPI2E
    IFS2=0;                             // Interrupt flag Status Register 2

// DMA5, CAN2, INT4, INT3, Timer9,8, I2C2M, I2C2S, Timer7
    IFS3=0;                             // Interrupt flag Status Register 3

// CAN2tx, CAN1tx, DMA7,6, UART2e, UART1e
    IFS4=0;                             // Interrupt flag Status Register 4
}


unsigned long get_MCU_pm (UWord16, UWord16); //JS: in rtspApi.s

void read_MCU_pm (unsigned char *buf, unsigned long addrs){
/* Read from MCU program memory address "addrs"
** and return value to "buf" buffer array of chars
** Uses W0, W1, and TBLPAG
*/
    unsigned long retval;
    retval = get_MCU_pm ((unsigned)(addrs>>16), (unsigned)(addrs&0xFFFF));
    *buf = retval & 0xFF;   // LSByte
    retval>>= 8;
    *(buf+1) = retval & 0xFF; // 2nd Byte
    retval>>= 8;
    *(buf+2) = retval & 0xFF; // 3rd Byte
    retval>>= 8;
    *(buf+3) = retval & 0xFF;  // MSByte
}

//JS20090821: new routine to write a whole row, with workaround from errata
#define PM_ROW_WRITE 		0x4001
#define CFG_BYTE_WRITE 		0x4000

extern void WriteLatch(UWord16, UWord16, UWord16, UWord16);
extern void WriteMem(UWord16);

void writePMRow(unsigned char * ptrData, unsigned long sourceAddr)
{
	int    size,size1;
	UReg32 temp;
	UReg32 tempAddr;
	UReg32 tempData;

	for(size = 0,size1=0; size < 64; size++) // one row of 64 instructions (256 bytes)
	{
		
		temp.Val[0]=ptrData[size1+0];
		temp.Val[1]=ptrData[size1+1];
		temp.Val[2]=ptrData[size1+2];
		temp.Val[3]=0; // MSB always 0
		size1+=4;

	   	WriteLatch((unsigned)(sourceAddr>>16), (unsigned)(sourceAddr&0xFFFF), temp.Word.HW, temp.Word.LW);

		/* Device ID errata workaround: Save data at any address that has LSB 0x18 */
		if((sourceAddr & 0x0000001F) == 0x18)
		{
			tempAddr.Val32 = sourceAddr;
			tempData.Val32 = temp.Val32;
		}
		sourceAddr += 2;
	}

	/* Device ID errata workaround: Reload data at address with LSB of 0x18 */
	WriteLatch(tempAddr.Word.HW, tempAddr.Word.LW, tempData.Word.HW, tempData.Word.LW);

	WriteMem(PM_ROW_WRITE);
}

void writeConfRegByte(unsigned char data, unsigned char cfgRegister)
{
	int     ret;
	UWord16 sourceAddr;
	UWord16 val;

	sourceAddr = (UWord16)cfgRegister;
	val = 0xFF00 | (UWord16)data;

	ret = confByteErase(0xF8, sourceAddr);

	WriteLatch(0xF8, sourceAddr, 0xFFFF, val);
	WriteMem(CFG_BYTE_WRITE);
}







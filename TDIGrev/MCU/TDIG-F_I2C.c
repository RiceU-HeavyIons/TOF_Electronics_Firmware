// $Id: TDIG-F_I2C.c,v 1.3 2009-05-18 20:17:53 jschamba Exp $

/* TDIG-F_I2C.c ---------------------------------------------------------------------
**
** Routines to support I2C devices on TDIG-F board
**
** These SBIR data are furnished with SBIR/STTR rights under Grant No. DE-FG03-02ER83373 and
** BNL Contract No. 79217.  For a period of 4 years after acceptance of all items delivered
** under this Grant, the Government, BNL and Rice agree to use these data for the following
** purposes only: Government purposes, research purposes, research publication purposes,
** research presentation purposes and for purposes of Rice to fulfill its obligations to
** provide deliverables to BNL and DOE under the Prime Award; and they shall not be disclosed
** outside the Government, BNL or Rice (including disclosure for procurement purposes) during
** such period without permission of Blue Sky, LLC except that, subject to the foregoing use
** and disclosure prohibitions, such data may be disclosed for use by support contractors.
** After the aforesaid 4-year period the Government has a royalty-free license to use, and to
** authorize others to use on its behalf, these data for Government purposes, and the
** Government, BNL and Rice shall be relieved of all disclosure prohibitions and have no
** liability for unauthorized use of these data by third parties.
** This Notice shall be affixed to any reproductions of these data in whole or in part.
**
** Modified:
**      19-Feb-2009, W. Burton (WB-11X)
**      "Alarm" is now "Alert" for consistency.
**      12-Dec-2008, W. Burton
**      Added routines Read16_Temp() and Write16_Temp() to support temperature alert (WB-11X).
**      08-Sep-2007, W. Burton
**      Updated filenames for RevF boards
**      29-Jun-2007, W. Burton
**      Updated include file processing.
**
** Routines defined here:
**		I2C_Setup() -- Set up configuration of I2C
**
*/
    #include "TDIG-F_Board.h"
//	#include "p24HJ128GP506.h"
//	#include "p24HJ64GP506.h"

	#include "I2C.h"
// Define implementation on the TDIG board (I/O ports, etc)

	#include "TDIG-F_I2C.h"

// AND the following to address to make the command a "write"
    #define I2C_WRITE 0xFE
// OR  the following to address to make the command a "read"
    #define I2C_READ 0x1


/* I2C_Setup() ----------------------------------------------------------------------
** This routine disables I2C Interrupts and sets up the configuration of the I2C #1
** Baud rate is set on the basis of constants defined in file TDIG-D_Board.h
** Call with: nothing
** Returns: nothing
** Hardware effects: I2C #1 Interrupts are disabled;
**		I2C port is opened with baud rate computed from TDIG-D_Board.h
**		I2C is left "Idle"
*/
extern void I2C_Setup() {
	DisableIntMI2C1;				// we will poll master
	DisableIntSI2C1;				// we will poll slave
	OpenI2C1 ( (unsigned int)(I2C1_ON &
               I2C1_IDLE_CON &
               I2C1_CLK_HLD &
               I2C1_IPMI_DIS &
               I2C1_7BIT_ADD &
               I2C1_SLW_DIS &
               I2C1_SM_DIS &
               I2C1_GCALL_DIS &
               I2C1_STR_DIS &
               I2C1_NACK &
               I2C1_ACK_DIS &
               I2C1_RCV_EN &
               I2C1_STOP_DIS &
               I2C1_RESTART_DIS &
               I2C1_START_DIS
              ),
              (unsigned int)I2C_BAUD_DIV );         // 81. = ((20MHz/200KHz)-(20MHz/1,111,111))-1

    IdleI2C1();
}
/* ----------------------------------------------------------------------------------------------- */


extern unsigned int Write_DAC(unsigned char *dvp) {
/* This routine writes a value to the DAC at address DAC_ADDR from TDIG-D_Board.h
** Call with: pointer to LSB of value to write to the DAC
** Returns: value actually written.
** Hardware effects: DAC is set to value given; exact scaling depends on board implementation.
** This routine is a NO-OP if DAC_ADDR is not #defined (usually in TDIG-D_BOARD.H)
*/
    unsigned int dv=0;
#if defined (DAC_ADDR)      // Conditionalize the whole routine
// Wait for Bus IDLE
	IdleI2C1();
// Start the bus
    StartI2C1();
    while (I2C1CONbits.SEN);         // wait for Start Sequence to complete
// Write Slave address and set Master to transmit
    MasterWriteI2C1((unsigned char)DAC_ADDR);
// Wait for address to transmit
	while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Transmit the MSByte of the value
//    MasterWriteI2C1((unsigned char)((dacval>>8)&0xFF));
    MasterWriteI2C1(((unsigned char)*(dvp+1)&0x0F)); // Mask off PwrDown bits
    dv = (unsigned char)*(dvp+1);
// Wait for register to transmit
    while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Transmit the LSbyte of the value
//    MasterWriteI2C1((unsigned char)(dacval&0xFF));
    MasterWriteI2C1((unsigned char)*dvp);
    dv<<=8;
    dv |= (unsigned char)*dvp;  // save the LSB part
// Wait for register to transmit
    while ( I2C1STATbits.TBF);
// Wait for acknowledgement
	while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// done
    StopI2C1();
#endif // defined (DAC_ADDR)
    return (dv);
}
/* ------------------------------------------------------------------------------------------------ */


/* Initialize Temperature Monitor Configuration of MCP9801 temperature sensor
** Call with: Integer configuration word for MCP9801 sensor
** Returns: nothing
** Hardware effects: Temperature monitor chip is configured.
*/
	extern void Initialize_Temp (int config) {
/* -------------------------------------------------
This routine initializes MCP9801 Temperature Sensor
  --------------------------------------------------*/
    Write_device_I2C1 (TMPR_ADDR, MCP9801_CFGR, config);
}


/* ------------------------------------------------------------------------------------------------ */
extern void Initialize_ECSR(){
// This routine initializes CSR at address ECSR_ADDR
//  initialize_MCP23008 (     addr,     (0)iodir,      (1)ipol,    (2)gpinten,     (3)defval,     (4)intcon,      (5)iocon,      (6)gppu)
    Initialize_MCP23008 (ECSR_ADDR,   ECSR_IODIR, MCP23008_NONE, MCP23008_NONE, MCP23008_NONE, MCP23008_NONE, MCP23008_ALL, MCP23008_ALL);
    Write_device_I2C1 (ECSR_ADDR, MCP23008_OLAT, ~ECSR_TDC_POWER);     // led_off(NO_LEDS);
}


extern void Initialize_Switches(){
/* -----------------------------------------------------------------------------------------------
** this routine initializes MCP23008 for Header/Switch/Pushbutton.
** Call with: nothing
** Returns: nothing
** Hardware effects: MCP23008 I/O Expander is initialized as needed for use by header, switch pushbutton
*/
//  initialize_MCP23008 (     addr, iodir(all in), ipol(all invert),       gpinten,        defval,        intcon,         iocon,         gppu)
    Initialize_MCP23008 (SWCH_ADDR,  MCP23008_ALL,     MCP23008_ALL, MCP23008_NONE, MCP23008_NONE, MCP23008_NONE, MCP23008_NONE, MCP23008_ALL);
}


extern void Initialize_LEDS() {
/* -------------------------------------------------
this routine initializes MCP23008 for LEDs and turns them all off.
** Call with: nothing
** Returns: nothing
** Hardware effects: MCP23008 I/O Expander is initialized as needed for use as LED output drive

  --------------------------------------------------*/
//  initialize_MCP23008 (    addr,        iodir,         ipol,       gpinten,        defval,        intcon,         iocon,         gppu)
    Initialize_MCP23008 (LED_ADDR,         0x00, MCP23008_ALL, MCP23008_NONE, MCP23008_NONE, MCP23008_NONE, MCP23008_NONE, MCP23008_ALL);
    Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, NO_LEDS);     // led_off(NO_LEDS);
}

extern void Initialize_MCP23008 (i2caddr, iodir, ipol, gpinten, defval, intcon, iocon, gppu) {
/* This routine initializes the MCP23008
** Call with:
** 		I2C addrs "i2caddr" of chip to be initialized
**		for direction mask "iodir" (1 = input)
**		with inversion mask "ipol" (1 = inverted)
** 		with interrupt mask "gpinten" (1 = interrupt-on change)
**		with comparison default mask "defval"
**  	with interrupt control mask "intcon" (1 = compare to defval)
** 		with I/O Control mask "iocon"
**		with pull-up mask "gppu" (1 = enable pull-up)
** Returns: nothing
** Hardware effects: MCP23008 I/O Expander is initialized as described by control words
*/
 // write via I2C address "i2caddr", to specific registers, with contents

    Write_device_I2C1 (i2caddr, MCP23008_IODIR, iodir);
    Write_device_I2C1 (i2caddr, MCP23008_IPOL,  ipol);
    Write_device_I2C1 (i2caddr, MCP23008_GPINTEN, gpinten);
    Write_device_I2C1 (i2caddr, MCP23008_DEFVAL, defval);
    Write_device_I2C1 (i2caddr, MCP23008_INTCON, intcon);
    Write_device_I2C1 (i2caddr, MCP23008_IOCON, iocon);
    Write_device_I2C1 (i2caddr, MCP23008_GPPU, gppu);
}

/* -------------------------------------------------
** write to I2C device
** Call with: "i2caddr" I2C address of chip to be accessed
** 				"reg" is register within chip
** 				"val" is value to be written.
**  I2C must have been "Opened" prior to this call
*/
void Write_device_I2C1 (i2caddr, reg, val) {
// Wait for Bus IDLE
	IdleI2C1();
// Start the bus
    StartI2C1();
    while (I2C1CONbits.SEN);         // wait for Start Sequence to complete
// Write Slave address and set Master to transmit
    MasterWriteI2C1((unsigned char)i2caddr);
// Wait for address to transmit
	while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Transmit the Register Number
    MasterWriteI2C1((unsigned char)reg);
// Wait for register to transmit
    while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Transmit the value
    MasterWriteI2C1((unsigned char)val);
// Wait for register to transmit
    while ( I2C1STATbits.TBF);
// Wait for acknowledgement
	while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// done
    StopI2C1();
}




/* -------------------------------------------------
Read from I2C device at "addr",
 from its internal register "reg"
 returns resulting 8-bit value
 I2C must have been "Opened" prior to this call
 --------------------------------------------------*/
unsigned int Read_MCP23008 (int i2caddr, int reg) {
	unsigned char retval = 0;
/* 1) Write the Register Address we want */
// Wait for Bus IDLE
	IdleI2C1();
// Start the bus
    StartI2C1();
    while (I2C1CONbits.SEN);         // wait for Start Sequence to complete
// Write Slave address and set Master to transmit
    MasterWriteI2C1((unsigned char)i2caddr);
// Wait for address to transmit
	while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Transmit the Register Number
    MasterWriteI2C1((unsigned char)reg);
// Wait for register to transmit
    while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();

/* 2) Re-Address the Chip and Read the value */
// ReStart the bus
    RestartI2C1();
    while (I2C1CONbits.RSEN);         // wait for ReStart Sequence to complete
// Write Slave address and set Master to transmit
    MasterWriteI2C1((unsigned char)(i2caddr|1));
// Wait for address to transmit
	while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Get the returned value
    retval = MasterReadI2C1();
// done
    StopI2C1();
	return (retval);
}

/* -------------------------------------------------
Read from I2C Temperature device at I2C address MCP9801
 from its internal register MCP9801_TMPR (temperature)
 returns resulting 16-bit value
 I2C must have been "Opened" prior to this call
 --------------------------------------------------*/
int Read_Temp () {
	int retval = 0;
/* 1) Write the Register Address we want */
// Wait for Bus IDLE
	IdleI2C1();
// Start the bus
    StartI2C1();
    while (I2C1CONbits.SEN);         // wait for Start Sequence to complete
// Write Slave address and set Master to transmit
    MasterWriteI2C1((unsigned char)TMPR_ADDR);
// Wait for address to transmit
	while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Transmit the Register Number
    MasterWriteI2C1((unsigned char)MCP9801_TMPR);
// Wait for register to transmit
    while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();

/* 2) Re-Address the Chip and Read the value */
// ReStart the bus
    RestartI2C1();
    while (I2C1CONbits.RSEN);         // wait for ReStart Sequence to complete
// Write Slave address and set Master to transmit
    MasterWriteI2C1((unsigned char)(TMPR_ADDR|1));
// Wait for address to transmit
	while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Get the returned value (MSByte)
    retval = MasterReadI2C1();
	retval <<= 8;		// shift up.
	AckI2C1();			// Master issues ACK
//    RestartI2C();
//    while (I2C1CONbits.RSEN);         // wait for ReStart Sequence to complete
// Write Slave address and set Master to transmit
//    MasterWriteI2C((unsigned char)(i2caddr|1));
// Wait for address to transmit
//	while ( I2C1STATbits.TBF);
// Wait for acknowledgement
//    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Get the returned value
    retval |= (unsigned char)MasterReadI2C1();
// Signal the end of data
	NotAckI2C1();		// issue a NAK
// Wait for Bus IDLE
	IdleI2C1();
// done
    StopI2C1();
	return (retval);
}

/* -------------------------------------------------
Read 16-bit register from I2C Temperature device at I2C address MCP9801
 returns resulting 16-bit value
 I2C must have been "Opened" prior to this call
 --------------------------------------------------*/
int Read16_Temp (int reg) {
	int retval = 0;
/* 1) Write the Register Address we want */
// Wait for Bus IDLE
	IdleI2C1();
// Start the bus
    StartI2C1();
    while (I2C1CONbits.SEN);         // wait for Start Sequence to complete
// Write Slave address and set Master to transmit
    MasterWriteI2C1((unsigned char)TMPR_ADDR);
// Wait for address to transmit
	while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Transmit the Register Number
    MasterWriteI2C1((unsigned char)reg);
// Wait for register to transmit
    while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();

/* 2) Re-Address the Chip and Read the value */
// ReStart the bus
    RestartI2C1();
    while (I2C1CONbits.RSEN);         // wait for ReStart Sequence to complete
// Write Slave address and set Master to transmit
    MasterWriteI2C1((unsigned char)(TMPR_ADDR|I2C_READ));
// Wait for address to transmit
	while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Get the returned value (MSByte)
    retval = MasterReadI2C1();
	retval <<= 8;		// shift up.
	AckI2C1();			// Master issues ACK
//    RestartI2C();
//    while (I2C1CONbits.RSEN);         // wait for ReStart Sequence to complete
// Write Slave address and set Master to transmit
//    MasterWriteI2C((unsigned char)(i2caddr|1));
// Wait for address to transmit
//	while ( I2C1STATbits.TBF);
// Wait for acknowledgement
//    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// Get the returned value (LSByte)
    retval |= (unsigned char)MasterReadI2C1();
// Signal the end of data
	NotAckI2C1();		// issue a NAK
// Wait for Bus IDLE
	IdleI2C1();
// done
    StopI2C1();
	return (retval);
}

/* -------------------------------------------------
Write 16-bit register to I2C Temperature device at I2C address MCP9801
  into register "reg" with value "val"
  I2C must have been "Opened" prior to this call
 --------------------------------------------------*/
void Write16_Temp (int reg, int val) {
// Wait for Bus IDLE
	IdleI2C1();
// 1. Start the bus
    StartI2C1();
    while (I2C1CONbits.SEN);         // wait for Start Sequence to complete
// 2. Write Slave address (chip address) and set Master to transmit
    MasterWriteI2C1((unsigned char)TMPR_ADDR);
// Wait for address to transmit
	while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// 3. Transmit the Register Number (internal Register pointer)
    MasterWriteI2C1((unsigned char)(reg&0x3));
// Wait for register to transmit
    while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// 4. Send the Data MSByte
    MasterWriteI2C1((unsigned char)((val>>8)&0xFF));
// Wait for MSByte to transmit
    while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// 5. Send the Data LSByte
    MasterWriteI2C1((unsigned char)(val&0xFF));
// Wait for register to transmit
    while ( I2C1STATbits.TBF);
// Wait for acknowledgement
    while ( I2C1STATbits.ACKSTAT);
// Wait for Bus IDLE
	IdleI2C1();
// 6. done
    StopI2C1();
	return;
}

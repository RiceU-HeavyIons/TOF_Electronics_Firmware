// $Id: TCPU-B_I2C.h,v 1.1 2008-02-13 17:44:42 jschamba Exp $

/* TCPU-B_I2C.h ----------------------------------------------
**
** Header file defining prototypes for routines in TCPU-B_I2C.c
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
*/
	extern void I2C_Setup (void);		// set up I2C configuration
    extern unsigned int Write_DAC (unsigned char *dvp); // Set a value into the DAC
	extern void Initialize_Temp (int config); // Configure M9801 Temperature Sensor
	extern void Initialize_ECSR (void);	// Initialize External CSR
	extern void Initialize_Switches (void); // Set up Header/Switch/Button
	extern void Initialize_LEDS (void);	// Initialize LED port and turn off
	extern void Initialize_MCP23008 (int i2caddr, int iodir, int ipol, int gpinten, int defval, int intcon, int iocon, int gppu);
	extern void Write_device_I2C1 (int i2caddr, int reg, int val); // write I2C #1
	extern unsigned int Read_MCP23008 (int i2caddr, int reg); // Read from I2C #1
	extern int Read_Temp (void); // Read temperature sensor

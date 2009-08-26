// $Id: TCPU-C_Board.h,v 1.10 2009-08-26 20:39:56 jschamba Exp $

/* TCPU-C_Board.h
** This header file defines the TCPU-C rev 0 board layout per schematic
**  dated March 20, 2007.
**  It defines:
**  a) overall characteristics of the MCU interface to board hardware;
**  b) Symbolic names
**  c) Interfaces to MCU modules used.
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
**
**  Modified:
**     12-Aug-2009, W. Burton (WB-2P)
**          Fix TEMP_OFF, update FUID version ID to 2P
**     27-Feb-2009, W. Burton (WB-2J)
**          FUID bits updated to indicate version 2J
**     17-Dec-2008, W. Burton
**          Initialization of register 12 is now conditional on TRAY_GEOGRAPHIC symbol
**     15-Dec-2008, W. Burton
**          This is for version 2G
**          Define MCP9801_CFGR_FQUEx bits for temperature alarm "Fault Queue"
**          Define MCU_HEAT_ALERT in register F
**          Firmware ID is now 2G
**     29-Aug-2008, W. Burton
**          This is for version 2F
**          Adjusted magic number location for large-memory processor
**     27-Aug-2008, W. Burton
**          This is version 2E for TCPU-C
**          Made a symbolic name for the magic number location
**     29-Feb-2008, W. Burton
**          Changed version to 2.A for TCPU-C
**     28-Feb-2008, W. Burton
**          Added more control over Clock/PLL Selection:
**          JU2 pins 1-2 Jumper Installed =
**          JU2 pins 3-4 Jumper Installed =
**     27-Feb-2008, W. Burton
**          Revised for TCPU-C board.
**               Changed RD0 thru RD3 direction assignments and intitalizations.
**               EN_LOCAL_OSC    =1 == U25 oscillator ON;
**               SEL_LOCAL_CLOCK =0 == U101 selects Local Clock;
**               SEL_BYPASS      =0 == U102 selects NON-PLL (bypass) mode.
**     15-Oct-2007, W. Burton
**          Add definitions for Oscillator Selections
**          Change CPU configuration to support clock switching
**     11-Oct-2007, W. Burton
**          for Version 1L added initialization of PORTF to safe condition
**
**  Written:
**     04-Apr-2007, W. Burton
**         Based on TDIG-D_Board.h 19-Feb-07 and modified for board configuration.
**  --------------------------------------------------*/

//	#define RC15_IO 1		// Make RC15 a CLOCK/2 port

//Uncomment this for version to be downloaded via CANbus
//    #define DOWNLOAD_CODE 1

    #include "P24HJ256GP610.h"
//
// Define some characteristics
// Base address of second code image (for download)
    #define MCU2ADDRESS 0x4000          // second image lower limit
    #define MCU2IVTL    0x100           // Interrupt Vector table Lower Limit
    #define MCU2IVTH    0x200           // Interrupt Vector table Upper limit
    #define MCU2CODEL   0x4000          // Second-image Code space start
//    #if defined (__24HJ256GP610_H)      // IF using 256K processor
//        #define MCU2UPLIMIT 0x2ABFD     // Second-image Code space upper end of physical memory not including magic
//        #define MAGICADDRESS 0x2ABFE    // Jo's Magic Number Location
//    #else
	#define MCU2UPLIMIT 0xABFD      // Second-image Code space upper end
    #define MAGICADDRESS 0xABFE     // Jo's Magic Number Location
//    #endif

// External oscillator frequency
	#define SYSCLK          40000000

# if defined (CONFIG_CPU)
// Set up Configuration Registers for what I want for the test
// Symbolic names are found in p24HJ256GP610.h file
//   Flash boot and write-protect
//	_FBS( RBS_NO_RAM & BSS_NO_FLASH & BWRP_WRPROTECT_OFF)
//	Secure Segment options (all turned off)
//	_FSS( RSS_NO_RAM & SSS_NO_FLASH & SWRP_WRPROTECT_OFF)
//	Code Protect Off / Write Protect Off
//	_FGS( GSS_OFF & GWRP_OFF)
//  Oscillator Selections:
// 	          FastRC & 2-Speed OFF & Temp Protect OFF
//	_FOSCSEL( FNOSC_FRC & IESO_OFF & TEMP_OFF )
//	          Primary withOUT PLL & 2-Speed OFF & Temp Protect OFF
//	_FOSCSEL( FNOSC_PRI & IESO_OFF & TEMP_OFF );
//          Fast RC w/ PLL & 2-Speed OFF
	_FOSCSEL( FNOSC_FRCPLL & IESO_OFF);	    // details set later initialize_OSC()

// WB-1L
#if defined (RC15_IO)
//  Clock Switching and Monitor (Disabled) & OSCIO pin is I/O & Primary Disabled
//	_FOSC( OSCIOFNC_ON & POSCMD_NONE )
//  Clock Switching Enabled and Monitor Disabled & OSCIO pin is I/O & Primary External
	_FOSC( FCKSM_CSECMD & OSCIOFNC_ON & POSCMD_EC )
//  Clock Switching Enabled and Monitor ENABLED & OSCIO pin is I/O & Primary External
//    _FOSC( FCKSM_CSECME & OSCIOFNC_ON & POSCMD_EC )
#else
//  Clock Switching and Monitor (Disabled) & OSCIO pin is Clock & Primary Disabled
//	_FOSC( OSCIOFNC_OFF & POSCMD_NONE )
//  Clock Switching Enabled and Monitor Disabled & OSCIO pin is Clock & Primary External
    _FOSC( FCKSM_CSECMD & OSCIOFNC_OFF & POSCMD_EC )
//  Clock Switching Enabled and Monitor Enabled & OSCIO pin is Clock & Primary External
//    _FOSC( FCKSM_CSECME & OSCIOFNC_OFF & POSCMD_EC )
#endif

// WB-1L
/* Clock Selector Bits */
    #define MCU_FRCPLL 1
    #define MCU_EXTERN 2
// WB-1L end

//  Watchdog disabled & Windowed Disabled
	_FWDT( FWDTEN_OFF & WINDIS_ON )
//  Power-On Reset 2msec
	_FPOR( FPWRT_PWR2 )
//  User IDs
    _FUID0( 'P')        // 'P' = 0x50
	_FUID1( 0x02)       // WB-2A 0x02
	_FUID2( 0xFF)
	_FUID3( 0xFF)

/* Register CONFIG3 (0xf8000E) Debug / No JTAG / Reset
** USE EXTREME CARE HERE OR CONTROL OF THE CHIP CAN BE LOST FOREVER! */
#define _CONFIG3(x) __attribute__((section("__CONFIG3.sec,code"))) int _CONFIG3 = (x); //JS
//    _CONFIG3 (0x42)        // set up for PGC2/PGD2 EMUC2/EMUD2
    _CONFIG3 (0xC2)        // set up for PGC2/PGD2 EMUC2/EMUD2 //JS

#undef CONFIG_CPU
#endif // (CONFIG_CPU)


// I2C Baud Rate Configuration Divisor
	#define I2C_BAUD 200000
	#define I2C_BAUD_DIV (((SYSCLK/2)/I2C_BAUD)-((SYSCLK/2)/1111111)-1)
// I2C Bus Map
// U#  Address Chip      Port            Schematic Signal   Initialize As
// 60  0xA0x   DS28CM00                  <none>            Read for Silicon Serial Number
    #define SN_ADDR 0xA0            // I2C Addrs of chip
	#if defined (SN_ADDR)
    	#define CM00_CTRL 0x8           // Control Register in 28CM00
     	#define CM00_CTRL_I2C 0x1       // I2C mode bit in Control
	#endif // defined (SN_ADDR)

// 38  0x98x   DAC7571                   THRESHHOLD         Write DAC voltage
//     #define DAC_ADDR 0x98           // I2C Addrs of chip (NOT ON TCPU-C)
	#if defined (DAC_ADDR)
     	#define DAC_REFV 3300           // DAC Reference in millivolts
     	#define DAC_MASK 0x0FFF            // Mask everything but data bits
                                        // We do not define bits for power-down, we will not be using it.
        #define DAC_INITIAL 124         // = 4096/3300mV x 100mV
	#endif


// 37  0x94x   MCP9801                   <none>             Write Temperature Threshhold for Interrupt
// 37  0x94x   MCP9801                   MCU_HEAT_ALERT     Check status and reset interrupt
     #define TMPR_ADDR 0x94          // I2C Addrs of chip
     #define MCP9801_TMPR 0x0           // Temperature Register
     #define MCP9801_CFGR 0x1           // Configuration register
     #define MCP9801_CFGR_1SHOT 0x80    // Config bit 7 = One Shot enabled
     #define MCP9801_CFGR_RES9  0x00    // Config bit 6,5 = Resolution 9-bits
     #define MCP9801_CFGR_RES10 0x20    // Config bit 6,5 = Resolution 10-bits
     #define MCP9801_CFGR_RES11 0x40    // Config bit 6,5 = Resolution 11-bits
     #define MCP9801_CFGR_RES12 0x60    // Config bit 6,5 = Resolution 12-bits
     #define MCP9801_CFGR_FQUE1 0x00    // Fault Queue = 1 (default)
     #define MCP9801_CFGR_FQUE2 0x08    // Fault Queue = 2
     #define MCP9801_CFGR_FQUE4 0x10    // Fault Queue = 4
     #define MCP9801_CFGR_FQUE6 0x18     // Fault Queue = 6
     #define MCP9801_CFGR_ALTH  0x4     // Config bit 2 = Alert Polarity active high
     #define MCP9801_CFGR_INTM  0x2     // Config bit 1 = Alert is Interrupt Mode
     #define MCP9801_CFGR_SHDN  0x1     // Config bit 0 = Shutdown
     #define MCP9801_HYST 0x2           // Temperature Hysteresis
     #define MCP9801_LIMT 0x3           // Temperature Limit
//
// 36  0x44x   MCP23008                  <none>             Extended Control-Status Register
// 36  0x44x   MCP23008  GP.7            Jumper 1-2         Input, Invert, Pull-Up
// 36  0x44x   MCP23008  GP.6            Jumper 3-4         Input, Invert, Pull-Up
// 36  0x44x   MCP23008  GP.5            Jumper 5-6         Input, Invert, Pull-Up
// 36  0x44x   MCP23008  GP.4            Button SW1         Input, Invert, Pull-Up
// 36  0x44x   MCP23008  GP.3            PLD_nSTATUS        input
// 36  0x44x   MCP23008  GP.2            PLD_CRC_ERROR      input, state change cause interrupt (later)
// 36  0x44x   MCP23008  GP.1            PLD_INIT_DONE      input
// 36  0x44x   MCP23008  GP.0            PLD_CONFIG_DONE    input
// 36  0x44x   MCP23008  INT             EXPANDER_INT       output, interrupt generated when change-of-state on GP2
     #define ECSR_ADDR 0x44          // I2C Addrs of chip    Extended Control-Status Register
     #define MCP23008_IODIR   0x0    // I/O Direction Control Register Address
     #define ECSR_IODIR 0xFF         // 1111 1111 1=in, 0=out
     #define ECSR_IOINV 0xF0         // Invert the Jumper/Button bits (JMPR IN=1)
     #define ECSR_IOPUP 0xF0         // Enable Pull_up on jumpers & button
     #define JUMPER_MASK 0xF0        // Mask Jumpers
     #define JUMPER_1_2 0x80         // Jumper 1-2 in
     #define JUMPER_3_4 0x40         // Jumper 3-4 in
     #define JUMPER_5_6 0x20         // Jumper 5-6 in
     #define BUTTON 0x10             // Button Press bit
     #define ECSR_PLD_NSTATUS 0x08        // PLD Status
     #define ECSR_PLD_CRC_ERROR 0x04        // PLD CRC Error Detect
     #define ECSR_PLD_INIT_DONE 0x02        // PLD Initialization Done
     #define ECSR_PLD_CONFIG_DONE 0x01        // PLD Configuration Done
     #define PLD_READY (ECSR_PLD_INIT_DONE | ECSR_PLD_CONFIG_DONE)
     #define MCP23008_ALL     0xFF       // All GP bits
     #define MCP23008_NONE    0x00       // None
     #define MCP23008_IPOL    0x1        // Input Polarity Control 1=invert, 0=normal
     #define MCP23008_GPINTEN 0x2        // Interrupt on Change 1=enable, 0=disable
     #define MCP23008_DEFVAL  0x3        // Default Value for Interrupt-on-Change
     #define MCP23008_INTCON  0x4        // Interrupt comparison control 1=DEFVAL, 0=prev-pin val
     #define MCP23008_IOCON   0x5        // Control bits
     #define MCP23008_GPPU    0x6        // Pull Up control
     #define MCP23008_INTF    0x7        // Interrupt Status
     #define MCP23008_INTCAP  0x8        // Input Capture at Interrupt
     #define MCP23008_GPIO    0x9        // Port I/O
     #define MCP23008_OLAT    0xA        // Output Latch

// 35  0x42x   MCP23008  GP.7 thru GP.4  <unnamed>          Inputs with Pull-Up, read board position SW5
// 35  0x42x   MCP23008  GP.3 thru GP.0  <unnamed>          Inputs with Pull-Up, read board position SW4
     #define SWCH_ADDR 0x42          // I2C Addrs of chip
     #define BOARDSW5_MASK 0xF0      // Mask Board Position Switch SW5
     #define BOARDSW4_MASK 0x0F      // Mask Board Position Switch SW4

// 34  0x40x   MCP23008  GP.7 thru GP.0  <unnamed>          Outputs, Inverting, set to all-0 (LEDs off)
     #define LED_ADDR 0x40            // I2C Addrs of chip
     #define LED0 0x1                // Symbolic names of LEDs mapped to bits
     #define LED1 0x2
     #define LED2 0x4
     #define LED3 0x8
     #define LED4 0x10
     #define LED5 0x20
     #define LED6 0x40
     #define LED7 0x80
     #define LEDWARNING 0x80         // LED 7 is Amber
     #define NO_LEDS 0xFF           // Bit pattern for All LEDs Off

/* PLL Controls/Monitors in PORT D */
    #define MCU_PLL_dirmask (0xFFFE)    // Bit 0 is output
    #define MCU_PLL_initial (0xFFFE)    // Bit 0 is low
    #define PLL_RESET (LATDbits.LATD0) // PLL_RESET when hi.
    #define PLL_LOS  (PORTDbits.RD1)    // Bit 1 monitors PLL_LOS
    #define DH_ACTV  (PORTDbits.RD2)    // Bit 2 monitors DH_ACTV
    #define CAL_ACTV (PORTDbits.RD3)    // Bit 3 monitors CAL_ACTV

/*  ByteBlaster-like Ports and Bits */
	#define MCU_EE_dirmask (0xFC1F)
	#define MCU_EE_initial (0xFE8F)
    #define MCU_EE_DATA (PORTDbits.RD4)
    #define MCU_EE_DCLK (LATDbits.LATD5)
    #define MCU_EE_ASDO (LATDbits.LATD6)
    #define MCU_EE_NCS  (LATDbits.LATD7)
    #define MCU_SEL_EE2 (LATDbits.LATD8)
    #define MCU_CONFIG_PLD (LATDbits.LATD9)

/* Use of B-port for MCU-to-FPGA communication
** Port B[0..7] == MCU_PLD_DATA[0..7]  (Data)
** Port B[8..11] == MCU_PLD_CTRL[0..3] (Address)
** Port B[12] == MCU_PLD_CTRL[4] (read/Write)
** Port B[14] == MCU_PLD_SPARE[1] (Strobe)
*/
    #define PLD_BDATA_OUTPUT 0x8000
    #define PLD_BDATA_INPUT 0x80FF

    #define MCU_PLD_READ 0x1000
    #define MCU_PLD_STROBE (LATBbits.LATB14)

/* These are the TCPU FPGA-MCU interface registers as defined by spreadsheet
** "TDIG FPGA - MCU interface registers.xls"
** dated 17-Apr-2007
**   _RW have both Write and Read function
**   _W  has Write function
**   _R  has Read function
*/

    #define CONFIG_0_RW 0               // Configuration Reg. 0
        #define CONFIG_0_TEST 0x1       // Test input to MCU FIFO
        #define CONFIG_0_FIRSTR 0x2     // This board is 1st in readout
        #define CONFIG_0_SSTROBE0 0x4
        #define CONFIG_0_TSTROBE1 0x8
        #define CONFIG_0_TRIGS2 0x10
        #define CONFIG_0_TBUNCHRST 0x20
        #define CONFIG_O_TEVENTRST 0x40
    #define CONFIG_1_RW 1               // Configuration Reg. 1
        #define CONFIG_1_TDCMASK 0x3    // Mask for selected TDC
        #define CONFIG_1_MCUJTAG 0x4    // MCU is controlling JTAG
    #define CONFIG_2_RW 2
        #define CONFIG_2_TDCRESET 0x1   // TDC Hardware Reset
    #define CONFIG_3_RW 3
    #define STROBE_4_W 4
    #define STROBE_5_W 5
    #define STROBE_6_W 6
    #define STROBE_7_W 7
    #define IDENT_7_R  7                // Fixed Identification (Read)
    #define STROBE_8_W 8
    #define STROBE_9_W 9
    #define STROBE_10_W 10
    #define STROBE_11_W 11
    #define FIFO_BYTE0_R 11             // FIFO LSbyte
    #define FIFO_BYTE1_R 12
    #define CONFIG_12_W 12              // Board ID configuration
//    #define TRAY_GEOGRAPHIC CONFIG_12_W // Defined for forcing initialization
    #define FIFO_BYTE2_R 13
    #define FIFO_BYTE3_R 14             // FIFO MSbyte
    #define FIFO_STATUS_R 15            // FIFO Status
        #define FIFO_EMPTY_BIT 0x80
        #define FIFO_FULL_BIT 0x40
        #define FIFO_PARITY_BIT 0x20
        #define FIFO_WORDS_MASK 0x1F



// WB-1L
/* Port F bits default to inputs */
//    #define PORTF_dirmask 0x31FF        // all live bits are input
    #define PORTF_dirmask 0x31BF        // WB-2G RF6 is output for heat alert
    #define PORTF_initial 0x0           // initial value doesn't really matter
// WB-1L end
/* WB-2G: Port F bit used for overtemperature alert (U37 MCP9801)        */
        #define MCU_HEAT_ALERT (PORTFbits.RF6)
// WB-2G end

/* Port G bits used for various control functions */
    #define MCU_TEST (LATGbits.LATG15)
    #define PLD_RESETB (LATGbits.LATG14)
//    #define MCU_SEL_TERM2 (LATGbits.LATG13) // no-connect TCPU-C
    #define PLD_DEVOE (LATGbits.LATG12)
    #define MCU_SEL_BYPASS (LATGbits.LATG9) // TCPU-C Bypass PLL when lo; select PLL when hi.
    #define MCU_SEL_LOCAL_CLK (LATGbits.LATG8) // TCPU-C Select local clock when lo, Ext Clk when hi
    #define MCU_EN_LOCAL_OSC (LATGbits.LATG7) // TCPU-C Turns on local oscillator when hi.
    #define I2CA_RESETB (LATGbits.LATG6)
    // we will set up CAN2 on bits RG2 and RG3
    #define PORTG_dirmask 0x0C3F  // (15..12, and 9..6 == OUTPUT)
    #define PORTG_initial 0xDC3F  // (15=1, 14=1, 13=0, 12=1, 9=0, 8=0, 7=0, 6=0)

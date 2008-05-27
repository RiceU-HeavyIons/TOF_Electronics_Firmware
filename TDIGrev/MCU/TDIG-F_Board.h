// $Id: TDIG-F_Board.h,v 1.6 2008-05-27 16:00:00 jschamba Exp $

/* TDIG-D_Board.h
** This header file defines the TDIG-D rev 0 board layout per schematic
**  dated September 29, 2006.  Also applies to TDIG-E rev 0 board layout
**
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
**     15-Oct-07, W. Burton
**         Default build with REVTDCNBR defined.
**     08-Sep-07, W. Burton
**         Add definition for UCONFIG_IN and DCONFIG_OUT bits
**     06-Sep-07, W. Burton
**         Add definition for Pass-thru bit in FPGA reg 14 (Write)
**     03-Jul-07, W. Burton
**         Add definitions for Oscillator Selections
**         Add definition for CANBus Termination On/Off Select
**     02-Jul-07, W. Burton
**         Fix FUID0, FUID1 to reflect configuration.
**     29-Jun-07, W. Burton
**         Conditionalize MCU definition/includes
**         Conditionalize A/D channel assignments and setups.
**     06-Jun-07, W. Burton
**         Define MCU2ADDRESS address for second code image.  NOTE THIS DEFINITION MUST AGREE
**         with the corresponding definition of _resetPRI in the linker file used (.GLD file)
**     21-May-07, W. Burton
**         Modify CAN1 for 500Kbits/Sec
**     15-May-07, W. Burton
**         Add symbolic names for CAN1 timing parameters.
**     17-Apr-07, W. Burton
**         Update symbolic locations in MCU-PLD interface per today's discussion.
**     16-Apr-07, W. Burton
**         Update symbolic locations in MCU-PLD interface per spreadsheet 4/3/2007.
**     19-Feb-07, W. Burton
**         Initialization of PORTG.9 = 0 (CANBus Termination OFF).  Sometime later we will want
**         to turn ON if this is "first" or "last" board on bus.
**     15-Feb-07, W. Burton
**         Add PORTG stuff and more bits in ECSR
**     14-Feb-07, W. Burton
**         Add CONFIG3 definition for debugger.
**     08-Feb-07, W. Burton
**         Start DEFINE registers for MCU-to-FPGA FIFO reading.
**     02-Feb-07, W. Burton
**         DEFINE bit patterns for MCU-to-FPGA (MCU_PLD_) usage.
**     15-Jan-07, W. Burton
**         DEFINE HPTDC_RESET bit for power-on reset sequence
**     06-Jan-07, W. Burton
**         DEFINE RC15_IO for blinking LED D9 of boards w/out MCU_TEST LED.
**         DEFINE ECO14_SW4 to fix board ID bit swap (SW4)
**     02-Jan-07, W. Burton
**         UN-define SN_ADDR to match boards without U60 (DS28CM00 serial nbr)
**     12-Dec-06, W. Burton
**         Define ports and bits for JTAG used for TDC configuration
**     07-Dec-06, W. Burton
**         Use 40 MHz (PLL'd) clock
**     05-Dec-06, W. Burton
**         Conditionalize usage of RC15/OSC2 pin 40.
**         Pin will be I/O if RC15_IO is DEFINED, otherwise it will be Clock output
**  Written:
**     02-Nov-06, W. Burton
**  --------------------------------------------------*/
/* **************************************************************************
** Define the Processor
** THIS MUST BE DONE BEFORE the #INCLUDES
*/
    #define PIC24HJ64GP506 1
//  #define PIC24HJ128GP506 1

#if defined (PIC24HJ64GP506)
    #include "p24HJ64GP506.h"
#else
    #include "p24HJ128GP506.h"
#endif

	#define ECO14_SW4 1		// Enable Software ECO14 for board posn
//	#define RC15_IO 1		// Make RC15 an I/O port

//
// Define some characteristics
// Base address of second code image (for download)
    #define MCU2ADDRESS 0x4000

// External oscillator frequency
	#define SYSCLK          40000000

// Setup configuration bits
// This is what was set on the Explorer board for the PIC24FJ...
// #include "system.h"
// system.h defines:
// 		SYSCLK 16000000
//		BOARD_VERSION4
// #include "p24fj128ga010.h"
// #include "spimpol.h"
// #include "eeprom.h"
// #include "adc.h"
// #include "timer.h"
// #include "lcd.h"
// #include "rtcc.h"
// #include "buttons.h"
// #include "uart2.h"
// _CONFIG1( JTAGEN_OFF & GCP_OFF & GWRP_OFF & COE_OFF & FWDTEN_OFF & ICS_PGx2)
// _CONFIG2( FCKSM_CSDCMD & OSCIOFNC_ON & POSCMOD_HS & FNOSC_PRI )
// End of what was set on the Explorer board for the PCI24FJ

// This is what was set in Justin's code for the PIC18F8720
// _CONFIG1H, _OSCS_OFF_1H & _ECIO_OSC_1H
// _CONFIG2L, _BOR_OFF_2L & _BORV_20_2L & _PWRT_OFF_2L
// _CONFIG2H, _WDT_OFF_2H & _WDTPS_128_2H
// _CONFIG3L, _XMC_MODE_3L
// _CONFIG3H, _CCP2MX_ON_3H
// _CONFIG4L, _STVR_OFF_4L & _LVP_OFF_4L & _DEBUG_ON_4L
// _CONFIG5L, _CP0_OFF_5L & _CP1_OFF_5L & _CP2_OFF_5L & _CP3_OFF_5L & _CP4_OFF_5L & _CP5_OFF_5L & _CP6_OFF_5L & _CP7_OFF_5L
// _CONFIG5H, _CPB_OFF_5H & _CPD_OFF_5H
// _CONFIG6L, _WRT0_OFF_6L & _WRT1_OFF_6L & _WRT2_OFF_6L & _WRT3_OFF_6L & _WRT4_OFF_6L & _WRT5_OFF_6L & _WRT6_OFF_6L & _WRT7_OFF_6L
// _CONFIG6H, _WRTC_OFF_6H & _WRTB_OFF_6H & _WRTD_OFF_6H
// _CONFIG7L, _EBTR0_OFF_7L & _EBTR1_OFF_7L & _EBTR2_OFF_7L & _EBTR3_OFF_7L &  _EBTR4_OFF_7L & _EBTR5_OFF_7L & _EBTR6_OFF_7L & _EBTR7_OFF_7L
// _CONFIG7H, _EBTRB_OFF_7H
// End of what was set in Justin's code for the PIC18F8720

# if defined (CONFIG_CPU)
// Set up Configuration Registers for what I want for the test
// Symbolic names are found in p24HJ128GP506.h file
//   Flash boot and write-protect
//	_FBS( RBS_NO_RAM & BSS_NO_FLASH & BWRP_WRPROTECT_OFF)
//  Secure Segment options (all turned off)
//	_FSS( RSS_NO_RAM & SSS_NO_FLASH & SWRP_WRPROTECT_OFF)
//	Code Protect Off / Write Protect Off
//	_FGS( GSS_OFF & GWRP_OFF)

//  Oscillator Selections:
// 	          FastRC & 2-Speed OFF & Temp Protect OFF
//	_FOSCSEL( FNOSC_FRC & IESO_OFF & TEMP_OFF )
//	          Primary withOUT PLL & 2-Speed OFF & Temp Protect OFF
//	_FOSCSEL( FNOSC_PRI & IESO_OFF & TEMP_OFF );
//          Fast RC w/ PLL & 2-Speed OFF & Temp Protect OFF
	_FOSCSEL( FNOSC_FRCPLL & IESO_OFF & TEMP_OFF );	// details set later initialize_OSC()

#if defined (RC15_IO)
//  Clock Switching and Monitor (Disabled) & OSCIO pin is I/O & Primary Disabled
//    _FOSC( OSCIOFNC_ON & POSCMD_NONE )
//  Clock Switching Enabled and Monitor Disabled & OSCIO pin is I/O & Primary External
    _FOSC( FCKSM_CSECMD & OSCIOFNC_ON & POSCMD_EC )
//  Clock Switching Enabled and Monitor ENABLED & OSCIO pin is I/O & Primary External
//    _FOSC( FCKSM_CSECME & OSCIOFNC_ON & POSCMD_EC )
#else
//  Clock Switching and Monitor (Disabled) & OSCIO pin is Clock & Primary Disabled
//    _FOSC( OSCIOFNC_OFF & POSCMD_NONE )
//  Clock Switching Enabled and Monitor Disabled & OSCIO pin is Clock & Primary External
    _FOSC( FCKSM_CSECMD & OSCIOFNC_OFF & POSCMD_EC )
//  Clock Switching Enabled and Monitor Enabled & OSCIO pin is Clock & Primary External
//    _FOSC( FCKSM_CSECME & OSCIOFNC_OFF & POSCMD_EC )
#endif
/* Clock Selector Bits */
    #define MCU_FRCPLL 1
    #define MCU_EXTERN 2

//  Watchdog disabled & Windowed Disabled
	_FWDT( FWDTEN_OFF & WINDIS_ON )
//  Power-On Reset 2msec
	_FPOR( FPWRT_PWR2 )
//  User IDs
    _FUID0( 'M' )       // "M" = 0x4D
    _FUID1( 0x11)       // 0x11
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
     #define DAC_ADDR 0x98           // I2C Addrs of chip
	#if defined (DAC_ADDR)
     	#define DAC_REFV 3300           // DAC Reference in millivolts
     	#define DAC_MASK 0x0FFF            // Mask everything but data bits
                                        // We do not define bits for power-down, we will not be using it.
        #define DAC_INITIAL 3102         // = 4096/3300mV x 2500mV
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
     #define MCP9801_CFGR_ALTH  0x4     // Config bit 2 = Alert Polarity active high
     #define MCP9801_CFGR_INTM  0x2     // Config bit 1 = Alert is Interrupt Mode
     #define MCP9801_CFGR_SHDN  0x1     // Config bit 0 = Shutdown
     #define MCP9801_HYST 0x2           // Temperature Hysteresis
     #define MCP9801_LIMT 0x3           // Temperature Limit
//
// 36  0x44x   MCP23008                  <none>             Extended Control-Status Register
// 36  0x44x   MCP23008  GP.7            SPARE_PLD
// 36  0x44x   MCP23008  GP.6            TINO_TEST_MCU      output, 0
// 36  0x44x   MCP23008  GP.5            ENABLE_TDC_POWER   output, 0
// 36  0x44x   MCP23008  GP.4            TDC_POWER_ERROR_B  input
// 36  0x44x   MCP23008  GP.3            PLD_nSTATUS        input
// 36  0x44x   MCP23008  GP.2            PLD_CRC_ERROR      input, state change cause interrupt
// 36  0x44x   MCP23008  GP.1            PLD_INIT_DONE      input
// 36  0x44x   MCP23008  GP.0            PLD_CONFIG_DONE    input
// 36  0x44x   MCP23008  INT             EXPANDER_INT       output, interrupt generated when change-of-state on GP2
     #define ECSR_ADDR 0x44          		// I2C Addrs of chip    Extended Control-Status Register
     #define MCP23008_IODIR   0x0        	// I/O Direction Control 1=in, 0=out
	 #define ECSR_IODIR 0x9F             	// 1001 1111 1=in, 0=out
     #define ECSR_SPARE_PLD 0x80        	// Spare bit
     #define ECSR_TINO_TEST_MCU 0x40        // Test Pulse to TINO
     #define ECSR_TDC_POWER 0x20        	// enable TDC power bit
     #define ECSR_TDC_POWER_ERROR_B 0x10    // TDC power error status
     #define ECSR_PLD_NSTATUS 0x08        	// PLD (FPGA) nSTATUS bit
     #define ECSR_PLD_CRC_ERROR 0x04        // PLD (FPGA) CRC Error bit
     #define ECSR_PLD_INIT_DONE 0x02        // PLD (FPGA) INIT_DONE bit
     #define ECSR_PLD_CONFIG_DONE 0x01      // PLD (FPGA) CONFIG_DONE bit
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
// 35  0x42x   MCP23008  GP.7 thru GP.0  <unnamed>          Turn on Pull-Ups
// 35  0x42x   MCP23008  GP.3 thru GP.1  <unnamed>          Inputs with Pull-Up, read board position
// 35  0x42x   MCP23008  GP.0            <unnamed>          Inputs with Pull-Up, read pushbutton status
     #define SWCH_ADDR 0x42          // I2C Addrs of chip
     #define BUTTON 0x1             // Button Press bit
     #define BOARDSW4_MASK 0xE      // Mask Board Position Switch
     #define BOARDSW4_SHIFT 1       // Shift >> to align board_position switch (SW4)
     #define JUMPER_MASK 0xF0      // Mask Jumpers
     #define JUMPER_SHIFT 4        // number of bits to shift>> to align jumpers
     #define JUMPER_1_2 0x8        // Jumper 1-2 in
     #define JUMPER_3_4 0x4        // Jumper 3-4 in
     #define JUMPER_5_6 0x2        // Jumper 5-6 in
     #define JUMPER_7_8 0x1        // Jumper 7-8 in

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

/*  JTAG Ports and Bits */
    #define MCU_TDC_dirmask (0xFFF2)    // TDO is really an input (Out from other chip)
	#define MCU_TDC_initial (0xFFF0)	// Initialize MCU-to-TDC JTAG
    #define MCU_TDC_TDI (LATDbits.LATD0)
    #define MCU_TDC_TDO (PORTDbits.RD1)
    #define MCU_TDC_TCK (LATDbits.LATD2)
    #define MCU_TDC_TMS (LATDbits.LATD3)
    // macros wiggling these bits are defined in TDIG-D_JTAG.h
    // callable routines are defined in TDIG-D_JTAG.c

/*  ByteBlaster-like Ports and Bits */
	#define MCU_EE_dirmask (0xFC1F)
	#define MCU_EE_initial (0xFE8F)
    #define MCU_EE_DATA (PORTDbits.RD4)
    #define MCU_EE_DCLK (LATDbits.LATD5)
    #define MCU_EE_ASDO (LATDbits.LATD6)
    #define MCU_EE_NCS  (LATDbits.LATD7)
    #define MCU_SEL_EE2 (LATDbits.LATD8)
    #define MCU_CONFIG_PLD (LATDbits.LATD9)

    #define NBR_HPTDCS 3     // 3 hptdc chips per board

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

/* These are the TDIG FPGA-MCU interface registers as defined by spreadsheet
** TDIG FPGA - MCU IF registers.xls) dated 9/6/2007
**   _RW have both Write and Read function
**   _W  has Write function
**   _R  has Read function
*/
    #define CONFIG_0_RW 0               // Configuration Reg. 0
        #define CONFIG_0_TEST 0x1       // Test input to FIFO
        #define CONFIG_0_FIRSTR 0x2     // This board is 1st in readout
        #define CONFIG_0_TSTROBE0 0x4
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
    #define STROBE_4_W 4                // Generate test token if enabled by CONFIG_0.2
    #define STROBE_5_W 5                // Generate test data if enabled by CONFIG_0.3
    #define STROBE_6_W 6                // Generate test trigger if enabled by CONFIG_0.4
    #define STROBE_7_W 7                // Generate test bunch reset if enabled by CONFIG_0.5
    #define IDENT_7_R  7                // Fixed Identification (Read)
    #define STROBE_8_W 8                // Generate test event reset (Write) if enabled by CONFIG_0.5
//  #define STATUS_0_R 8                // Status Register 0 (Read)
    #define STROBE_9_W 9                // Reset readout state machine (Write)
//  #define STATUS_1_R 9                // Status Register 1 (Read)
    #define STROBE_10_W 10              // Reset MCU FIFO
    #define STROBE_11_W 11              // Clocks test data counter and writes to MCU FIFO
    #define FIFO_BYTE0_R 11             // FIFO LSbyte
    #define FIFO_BYTE1_R 12
    #define CONFIG_12_W 12              // Board ID configuration
    #define FIFO_BYTE2_R 13
    #define FIFO_BYTE3_R 14             // FIFO MSbyte
    #define CONFIG_14_W 14              // Configuration 14
        #define PASSTHRU_BIT 0x1        // Turns on FPGA signal pass-thru function for testing
    #define FIFO_STATUS_R 15            // FIFO Status
        #define FIFO_EMPTY_BIT 0x80
        #define FIFO_FULL_BIT 0x40
        #define FIFO_PARITY_BIT 0x20
        #define FIFO_WORDS_MASK 0x1F

/* Port F bits used for config in and out (not fully implemented) */
    #define PORTF_dirmask 0x31F7        //
        #define UCONFIG_IN (PORTFbits.RF2)
        #define DCONFIG_OUT (LATFbits.LATF3)

/* Port G bits used for various control functions */
    #define MCU_TEST (LATGbits.LATG15)
    #define PLD_RESETB (LATGbits.LATG14)
    #define USB_RESETB (LATGbits.LATG13)
    #define PLD_DEVOE (LATGbits.LATG12
    #define MCU_SEL_TERM (LATGbits.LATG9)
    #define MCU_SEL_LOCAL_OSC (LATGbits.LATG8)
    #define MCU_EN_LOCAL_OSC (LATGbits.LATG7)
    #define I2CA_RESETB (LATGbits.LATG6)
    #define PORTG_dirmask 0x0C3F
    #define PORTG_initial 0xDDFF;   // Default NO CAN TERM.

/* CAN1 TIMING PARAMETERS */
    #define CAN1_CANCKS 0x1         // FCAN = FCY == 20 MHZ
    #define CAN1_BRP 0x0            // Baud Rate Prescaler (1 M bits/sec)
    #define CAN1_SJW 0x1            // Synchronization Jump Width 1 TQ
    #define CAN1_PRSEG 0x2          // Propagation Segment time is 3 TQ (N+1)
    #define CAN1_SEG1PH 0x2         // Phase Segment 1 is 8 TQ (N+1)
    #define CAN1_SEG2PHTS 0x1       // Phase Segment 2 is programmable
    #define CAN1_SEG2PH 0x2         // Phase Segment 2 is 8 TQ (N+1)
    #define CAN1_SAM 0x0            // Sample one time at sample point

/* CANBus Termination Defines */
    #define CAN_TERM_ON 1           // CANBus terminator is ON
    #define CAN_TERM_OFF 0          // CANBUS terminator is OFF
    #define CAN_TERM_INIT CAN_TERM_OFF  // Initial state is OFF

/* A/D Converter Setups */
    #define ALLDIGITAL 0xFFFF       // All Digital I/O (15..0)
    #define ANALOG1716 0xFFFC       // Analog I/O for (17..16)

// 15-Oct-07
// Default to the Revised TDC numbering scheme:
    #define REVTDCNUMBER 1
//  #if defined (REVTDCNUMBER)  // if defined, use revised method (J.Schambach 6-Sep-07)
                                // Fix up HPTDC ID byte in working initialization (Revised method)
                                // board_posn 0,4 have TDCs 0x0,0x1,0x2
                                // board_posn 1,5 have TDCs 0x4,0x5,0x6
                                // board_posn 2,6 have TDCs 0x8,0x9,0xA
                                // board_posn 3,7 have TDCs 0xC,0xD,0xE
                                // ((lo 2 bits of board posn) << 2 bits) or'd with (lo 2 bits of (index-1))
//  #else
                                // Fix up HPTDC ID byte in working initialization
                                // board_posn 0,4 have TDCs 0x0,0x1,0x2
                                // board_posn 1,5 have TDCs 0x3,0x4,0x5
                                // board_posn 2,6 have TDCs 0x6,0x7,0x8
                                // board_posn 3,7 have TDCs 0x9,0xA,0xB
// #endif  // Not NEWTDCNUMBER (old method)

// Default to turn on local header for Boards 0,4 TDC 1
//	#define LOCAL_HEADER_BOARD0

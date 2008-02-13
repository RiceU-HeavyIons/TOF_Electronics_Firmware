// $Id: TDIG-F.c,v 1.1 2008-02-13 17:16:11 jschamba Exp $

// TDIG-F.c
/*
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
*/

// main program for PIC24HJxxGP506 as used on TDIG-D rev 0 board
//      15-Oct-2007, W. Burton, Firmware ID is 0x11 x48 (11H)
//          Use read_hptdc_status() routine instead of duplicate code.
//          Rename OSCCONH to OSCCON+1 and OSCCONL to OSCCON (in routine switch_osc()) so we don't need modified .GLD
//          Changes marked //WB-11H
//          TDIG-Board.h file edited to default use "new" tdc numbering scheme.
//      11-thru-13-Oct-2007, W. Burton.  Firmware ID is 0x11 0x48 (11H)
//          If the second (download) image is running, we do not want to download over it.
//          CPU starts up using internal oscillator; then examines jumpers and changes to Board or Tray external Oscillator.
//          CLOCK JUMPER (PINS 1-2) IS EXAMINED ONLY ONCE AT START-UP TO DETERMINE CLOCK SOURCE!
//          For DOWNLOADED code (second image), the OSCILLATOR IS NOT CHANGED
//          Added reset_TAP() before and after HPTDC JTAG access.
//          Set CPU priority=0 and select interrupt vector depending on DOWNLOAD_CODE
//             "normal" code = standard interrupts; "DOWNLOAD_CODE" = alternate interrupts.
//          "Download" code has id 0x91 0x48 (91H)
//          Changes marked //WB-11H
//      10-Oct-2007, J. Schambach Firmware ID is 0x11 0xFA
//			Fixed DMA initialization
//			Added spin(0) after first message in response to get status
//			Mask of the length field properly in decoding received CAN messages
//			Add ifdef statements around all sections of the code that shouldn't be part
//				of downloaded code (conditional: DOWNLOAD_CODE)
//			All changes are marked by "//JS"
//      19-Sep-2007, W. Burton Firmware ID is 0x11 0xF
//          Revised HPTDC reset sequence in TDIG-F_JTAG.c
//      08-Sep-2007, W. Burton Firmware ID is 0x11 0xF
//          Delayed power-on is defined (approx 1 second per board position)
//          Updated filenames for RevF boards in preparation for new release
//          Fixed DCONFIG_OUT not functioning as expected.
//          Fixed false reports of reconfiguration readback error.
//      07-Sep-2007, W. Burton, Version 11E
//      06-Sep-2007, W. Burton, Version 11E
//          Copy UCONFIGI bit to DCONFIGO bit to allow testing of corresponding LVDS signals (define UDCONFIGBITS)
//          Alternate JTAG timing (conditional SLOWERJTAG in tdig-d-jtag.h - defined 9/7/07)
//          Revised HPTDC numbering scheme per Jo Schambach 6-Sep-07 email (conditional REVTDCNUMBER)
//          Conditional code for delayed TDC power-on (conditional on DELAYPOWER definition)
//          Correct reply message for Read Temperature and Get Status TDC.
//          CANBus termination state must be OFF.
//      29-Jun-2007, W. Burton
//          Add FPGA read ID register to "Request Firmware Identifiers" (C_RS_FIRMWID) reply.
//          Add defining conditionals for type of PIC chip to be used
//          Move CAN Bus High Level Protocol (HLP) codes and defines to #include file TDIG-D_CAN_HLP3.h
//          Remove FPGA Ident byte from MCU startup Alert message.
//          Make sure "ALT" interrupt vector selector set in INTCON2 prior to jump to image 2;
//          Make sure to use "Standard" interrupt vector table in this image.
//      19-Jun-2007, W. Burton
//          Fix HPTDC Configuration/Reset indexing which caused "parity error" when getting
//              HPTDC status
//      09-Jun-2007, W. Burton
//          More work on MCU reprogram/reset
//          Ease restriction on EEPROM programming, 0 < bytes <= 256 is OK.
//      07-Jun-2007, W. Burton
//          Work on MCU erase function.
//          Add C_RS_MCUMEM (Read, len:5, msg: 0x4C <adrL> <adr2> <adr3> <adrM>)
//          to read and report 4 bytes from MCU address specified.
//          Reply is (Read Reply, len: 5, msg: 0x4C <memL> <mem2> <mem3> <mem4=00>)
//          This can also be used to read the MCU ID bytes from F80010 thru F80016.
//      06-Jun-2007, W. Burton
//          Added routine jumpto() to give this code a link into MCU2 code; Added definition
//          of MCU2ADDRESS in tdig-d_board.h to define the MCU2 entry point start address
//      19-May-2007, W. Burton
//          Reset MCU message added.
//          Reconfigure FPGA payload code changed.
//      18-May-2007, W. Burton
//          FIRMWARE ID added; Read FPGA Regs fixed.
//      17-May-2007, W. Burton
//          Work on MCU Reprogramming begins.
//      14-May-2007, W. Burton
//          Implement TDC Write Control Word (40 bits) C_WS_CONTROLTDCx messages.
//          Migrate CAN parameters for long-cable from TCPU.
//          EEPROM #2 Altera and STMicro.
//      11-May-2007, W. Burton
//          Implement FPGA Reset and FPGA Write Register messages.
//      10-May-2007, W. Burton
//          Corrected status return from FPGA Reconfiguration command.
//      04-May-2007, W. Burton
//          Reworked SPI write.  Enabled Reconfiguration commands.
//      03-May-2007, W. Burton
//          Make sure HPTDC is selected via jumpers.
//          LED D6 is now HPTDCs config readback OK when on.
//      30-Apr-2007, W. Burton
//          Make sure FPGA "MCU_PLD" registers are initialized.
//          Rework EEPROM write sequence.
//  Program #11B -
//      27-Apr-2007, W. Burton
//          More work on TDIG-D EEPROM #2 Write
// Program # 11A -
//      22-Apr-2007, W. Burton
//          Convert to use new TDIG-D_SPI.c routines
//      19-Apr-2007
//          More work on EEPROM #2 Write
//      18-Apr-2007
//      Add double-read for FIFO status during data readout transfer
//      ADD CONDITIONALS:
//         DODATATEST if defined, tries to read-out data.
//         SENDCAN if defined, sends CAN messages
//      13-Apr-2007
//      Add ability to read out data via CAN bus.
//          After initialization of HPTDC, Issue the FIFO Reset stuff (Strobe_10, Strobe_9)
//          In "idle" loop, check for data available and send it.
//          Code is conditionalized on DODATATEST being defined.
//      IF Board ID= 0 or 4 then Select this board as First in readout chain (Config_0 bit 1)
//      Fix use of FPGA CONFIG_1 register for selection of MCU or BBlaster in control of JTAG.
//      Changed "write config_1" to select_hptdc();
//      Update Local Oscillator and JTAG HPTDC # selection on change during Idle loop, Display JUMPERS in LEDs (0..3)
//      12-Apr-2007
//      Read and report MCU_PLD ID register (7) in 1 byte of startup message
//      11-Apr-2007
//      Add C_RS_functions for Read Serial Number, Switches, ECSR.
//      10-Apr-2007
//      Confirm operation of MCU-controlled CAN termination (MCU_SEL_TERM)
//      29-Mar-2007
//      Move HPTDC/JTAG routines to TDIG-D_JTAG.c file; restructure .H files; add symbolic names for some magic numbers.
//      27-Mar-2007
//      Restructure send_CAN1_message() and decode "writes"
//      26-Mar-2007
//      Bring into agreement (more or less) with ver10K
//      13-Feb-2007
//      Begin implementation of CANbuf HLP version 3.0 download protocols.
// Program #10F (still) - 14-Feb-2007
//      Fix problem with HPTDC configuration array indexing.
//      Turn on LED 0 when HPTDC configuration complete
//      Wait for button press after intitializing HPTDC power and before doing configuration.
//      Be sure to copy jumper settings to config_1 bits when done with program configuration
// Program #10F (still) - 10-Feb-2007
//      Change control words to only enable channel 1
//      FIFO test now writes 64, then reads 64.
//      CAN Data messages get sent AND Diagnostic message gets sent each cycle.
//      We will probably want this as part of Self-Test with an alert if it does not
//      work correctly.
// Program #10F (still) - 09-Feb-2007
//      Added pushbutton (SW1) to:
//          1. First push after initialization, triggers start of FIFO loop.
//          2. During FIFO loop, pressing button causes STROBE_12 (after read cycle)
//      CAN messages inhibited.
// Program #10F - 8-Feb-2007
//      MCU FIFO self test with CAN diagnostic
// Program #10E - 31-Jan-2007 thru 2-Feb-2007, WDB
//      Conditionalize EEPROM #2 stuff and JTAG stuff
//      Add first test of MCU-to-FPGA code.
//      define FPGA_WRITE_ADDRA as the first FPGA address to write to.
//      define FPGA_WRITE_ADDRB as the second FPGA address to write to.
//      define FPGA_WRITE_ADDRC as the third FPGA address to write to.
//      define FPGA_READ_ADDRA as the first FPGA address to read from.
//      define FPGA_READ_ADDRB as the second FPGA address to read from.
//      define FPGA_READ_ADDRC as the third FPGA address to read from.
//      Program writes/reads, and compares.  DIFFERENCE is reported in LEDs
//
// Program #10d - 23-Jan-2007, WDB
//      Try reading out the EEPROM #2 ID code.
//      Was the DAC change really beneficial?
//      Convert DAC setting routine to use ADDRESS of value to be set; initialization
//      changed to copy constant to "current value".
// Program #10c - 17-Jan thru 23-Jan-2007, WDB
//      Take HPTDC Configuration (Setup) from Include file.
//         To Incorporate new HPTDC Setup (Configuration) information:
//          1) Use the spreadsheet "HPTDC JTAG configurator_PIC24.xls" to manipulate
//             the configuration and format bits for inclusion.
//          2) COPY the cells I3 through I43 from the spreadsheet.
//          3) PASTE the cells (as text) into the file "HPTDC.INC".
//          4) Recompile (BUILD ALL) the TDIG project.
//             After download and release of reset, the configuration will be loaded into
//             the 3 HPTDCs.//      Inhibit CAN messages for bench testing.
//      CAN messages are inhibited for bench testing.
//      Configure and Control HPTDCs is working.
//		Add routine fixup_parity to scan bitstream and set parity.
//		Continue working on "Configuring HPTDCs"
// Program #10c - 16-Jan-2007, WDB
//		Add code to read "STATUS" of HPTDCs.
//		Rearrange startup code and process CAN message to set threshhold
// Program #10b - 15-Jan-2007, WDB
//      ID Code finally works.
// Program #10b - 6-Jan-2007, WDB
//      Now try getting HPTDC ID code thru JTAG for all 3 HPTDCs
//      Parameterize CAN messages.
//      Simplify CAN transmit message assembly.
//      Rename send_CAN_alert() to send_CAN1_alert()
//		Echo matching input messages.
//		Add conditional code based on ECO14_SW4 to compensate for bit-swap in Board ID switch.
// Program #10b1 - 4-Jan-2007, WDB
//      20MHz internal clocking
//      Incorporate changes from "Program 7k thru Program 7n"
//      This takes care of small CPLD enable requirement.
//		Reformat Startup CAN message per HLP_2 document (adds routine send_CAN_alert).
// Program #10a - Begin implementing JTAG configuration of TDC chips.
// Program #9e - Interpret and process the "THRESHHOLD" command
// 		Startup messge includes board-id in 1st word.
//		This amounts to: Spinning until we have a message.
//		Examining the message ID
//			If it is the Threshhold message, write the value to the DAC
//			Set up and send the response.
//		Include "board number" in message mask / filter.
//		Send "ERROR" message to all unrecognized messages.
// Program #9d - Loopback
// Program #9c -
//		Try changing the CAN data transmitted.
// Program #9b -
//		Move board-specific I2C stuff into TDIG-D_I2C.c
//		CAN initialization so CAN Receive doesn't crash.
//		CAN send a message!
// Program #8j -
//      Redo local clock for 40 MHz. check timing using RC15/Osc2 pin 40.
// Program #8h -
//		I2C spin(delay) are commented out so they take place very fast.
//		TDIG power-on request is disabled.
//      MCU-Test blink is also on D9 (RC15/Osc2, pin 40)
//      CAN bus:
//			Set up.
// Program #7g - Add "Reset" pulse delayed after enabling TDC power
// Program #6f - Changed constant names to the form _I2Cx
//      for use with new C30 and libraries.
//      Change routine write_MCP23008() to write_device_I2C1();
//		16-Nov-06, WDB
// Program #6 - Set RB[0..3] to Outputs.
//		Read jumpers and copy the settings to LEDs and
//      MCU_PLD_DATA[0..3] == RB[0..3].
// Program #5 - Read and display User ID bytes from hardware.
//      Then use "amber" led (D7) to indicate TDC Power status
// Program #4 - Read Silicon Serial Number and display in LEDs (slowly) and
//      Configure and read Temperature Monitor (U37).
//		6-Nov-06, WDB Converted from Program #3
// Program #3 - Initialize Header/Switch/Button input (I2C Device)
//		Read rotary switch and copy to corresponding LED output.
//		Check pushbutton for set and count when set.
//      When count reaches BUTTONLIMIT, toggle TDC power.
//   4-Nov-06, WDB Converted from Program #2
// Program #2 - Initialize and ramp-up DAC
//   4-Nov-06, WDB Converted from Program #1
// Program #1 - Initialize I2C, I2C Device, and cycle LEDs thru U34
//   1-Nov-06, WDB Converted from Program #0
// Program #0 - blink the LED (D9) associated with RC15/OSC2

//JS: Uncomment this, if this is to be donwloaded via CANbus
//JS	#define DOWNLOAD_CODE

// Define the FIRMWARE ID
//    #define FIRMWARE_ID_0 0xFA  //JS: to distinguish it from Bill's version
    #define FIRMWARE_ID_0 0x48    //WB-11H
// WB-11H make downloaded version have different ID
#ifdef DOWNLOAD_CODE
    #define FIRMWARE_ID_1 0x91
#else
    #define FIRMWARE_ID_1 0x11
#endif
// WB-11H end

// Define implementation on the TDIG board (I/O ports, etc)
	#define CONFIG_CPU 1		// Make TDIG-D_Board.h define the CPU options
    #include "TDIG-F_Board.h"

	#define RC15_TOGGLE 1		// Make a toggle bit on RC15/OSC2

// Define the library includes
    #include "ecan.h"           // Include for E-CAN peripheral
    #include "i2c.h"            // Include for I2C peripheral library
    #include "stddef.h"         // Standard definitions
    #include "string.h"         // Definitions for string functions

// Define our routine includes
	#include "TDIG-F_I2C.h"		// Include prototypes for our I2C routines

    #include "TDIG-F_JTAG.h"    // Include for our JTAG macros

    #include "TDIG-F_SPI.h"     // Include for our SPI (EEPROM) macros

    #include "TDIG-F_MCU_PLD.h" // Include for our parallel interface to FPGA

/* define the CAN HLP Packet Format and function codes */
    #include "TDIG-F_CAN_HLP3.h"

/* This conditional determines whether to actually send CAN packets */
    #define SENDCAN 1           // Define to send


// Define the cycle count for toggling TDC Power.
// Button S1 must be pressed for BUTTONLIMIT trips thru main loop before
// ENABLE_TDC_POWER bit is toggled
    #define BUTTONLIMIT 6

// Spin Counter
	#define SPINLIMIT 20

/* ECAN1 stuff */
	#define NBR_ECAN_BUFFERS 4

    typedef unsigned int ECAN1MSGBUF [NBR_ECAN_BUFFERS][8];
    ECAN1MSGBUF  ecan1msgBuf __attribute__((space(dma)));  // Buffer to TRANSMIT

    void ecan1Init(unsigned int board_id);
    void dma0Init(void);
    void dma2Init(void);
//	void ecan1WriteRxAcptFilter(int n, long identifier, unsigned int exide,
//    	unsigned int bufPnt,unsigned int maskSel);
//	void ecan1WriteRxAcptMask (int m, long identifier, unsigned int mide);
//    void ecan1WriteMessage (unsigned int word);
//	void ecan1WriteTxMsgBufId (unsigned int buf, long txIdentifier,
//    	unsigned int ide, unsigned int remoteTransmit);
//	void ecan1WriteTxMsgBufData (unsigned int buf, unsigned int dataLength,
//    	unsigned int data1, unsigned int data2, unsigned int data3,
//    	unsigned int data4);


// Routines Defined in this module:
// MCU configuration / control
// WB-11H
// void Initialize_OSC();                  // initialize the CPU oscillator
int Initialize_OSC(unsigned int oscsel);              // initialize the CPU oscillator
void Switch_OSC(unsigned int mcuoscsel);               // Switch CPU oscillator (low level)
// WB-11H end
void spin(int cycle);		// delay
void clearIntrflags(void);	// Clear interrupt flags
// CAN message routines
// Send a CAN message - fills in     board id               message type  number of payload bytes    &payload[0]
void send_CAN1_message (unsigned int board_id, unsigned int message_type, unsigned int bytes, unsigned char *bp);
void send_CAN1_alert   (unsigned int board_id);
void send_CAN1_diagnostic (unsigned int board_id, unsigned int bytes, unsigned char *buf);
// void send_CAN1_write_reply (unsigned int board_id);
void send_CAN1_hptdcmismatch (unsigned int board_id, unsigned int tdcno, unsigned int index, unsigned char expectedbyte, unsigned char gotbyte);
void send_CAN1_data (unsigned int board_id, unsigned int bytes, unsigned char *bp);

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

UReg32 temp;

void read_MCU_pm (unsigned char *, unsigned long);
void write_MCU_pm (unsigned char *, unsigned long);
void erase_MCU_pm (unsigned long);
// Dummy routine defined here to allow us to run the "alternate" code (downloaded)
void __attribute__((__noreturn__, __weak__, __noload__, address(MCU2ADDRESS) )) jumpto(void);

// HPTDC and JTAG routines
unsigned char basic_setup[J_HPTDC_SETUPBYTES] = {
//    The HPTDC-specific array gets JTAG'd to the desired HPTDC.
//    See HPTDC Manual Version 2.2, Section 17.5, pages 30-37.
//   [7]    [0] [15]    [8] = bit position
//    |      |    |      |
    #include "HPTDC.inc"
//     |     |
//  [646] [640]              = bit position
//   646=parity gets overwritten by insert_parity()
};

unsigned char enable_final [J_HPTDC_CONTROLBYTES] = {
//    The HPTDC-specific control-word array gets JTAG'd to the desired HPTDC.
//    See HPTDC Manual Version 2.2, Section 17.6, page 37.
//   [7]    [0] [15]    [8] = bit position
//    |      |    |      |
    #include "HPTDC_ctrl.inc"
//  [40]   [32]              = bit position
//   40 = parity must be included (it is not recomputed)
};



unsigned char readback_control[J_HPTDC_CONTROLBYTES];
unsigned char readback_setup  [J_HPTDC_SETUPBYTES];

unsigned char hptdc_setup  [NBR_HPTDCS+1][J_HPTDC_SETUPBYTES];
unsigned char hptdc_control[NBR_HPTDCS+1][J_HPTDC_CONTROLBYTES];

unsigned char readback_buffer[2048];        // readback general buffer

// Large-Block Download Buffer
#define BLOCK_BUFFERSIZE 256                // NEVER MAKE THIS LESS THAN 8
unsigned char block_buffer [BLOCK_BUFFERSIZE];

unsigned int block_bytecount;
unsigned int block_status;
unsigned long int block_checksum;
unsigned long int eeprom_address;

// Current DAC setting
unsigned int current_dac;

unsigned int pld_ident; // will get identification byte from PLD
unsigned int board_posn = 0;    // Gets board-position from switch

main()
{
    unsigned long int laddrs, lwork, lwork2;
    unsigned int i, j, k, l;        // working indexes
    unsigned int save_SR;           // image of status register while we block interrupts
	unsigned int tglbit = 0x0;
	unsigned int switches = 0x0;
	unsigned int jumpers = 0x0;
	unsigned int buttoncount = 0x0;
	unsigned int tdcpowerbit = 0x0;
	unsigned int ledbits = NO_LEDS;
	unsigned int board_temp = 0;	// will get last-read board temperature word
    unsigned int replylength;       // will get length of reply message
    unsigned char bwork[10];     // scratchpad
    unsigned char sendbuf[10], retbuf[10];
    unsigned char maskoff;      // working reg used for masking bits
    unsigned char *wps;              // working pointer
    unsigned char *wpd;              // working pointer


// WB-11H
// This applies to first-image code, does not apply to second "download" image.
#if !defined (DOWNLOAD_CODE)
// Configure the oscillator for MCU internal (until we get going)
    Initialize_OSC(OSCSEL_FRCPLL);          // initialize the CPU oscillator

// be sure we are running from standard interrupt vector
    save_SR = INTCON2;
    save_SR &= 0x7FFF;  // clear the ALTIVT bit
    INTCON2 = save_SR;  // and restore it.
#else
// This applies to second-image code.
// Note that ALTIVT bit gets set just prior to starting the second image, but just to be sure
    INTCON2 |= 0x8000;      // This is the ALTIVT bit
#endif

// We will want to run at priority 0 mostly
    SR &= 0x011F;          // Lower CPU priority to allow interrupts
    CORCONbits.IPL3=0;     // Lower CPU priority to allow user interrupts
// WB-11H end

#if defined (RC15_IO) // RC15 will be I/O (in TDIG-D-Board.h)
	TRISC = 0x7FFF;		// make RC15 an output
#else
//  RC15/OSC2 is set up to output TCY clock on pin 40 = CLK_DIV2_OUT, TP1
#endif

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
    DCONFIG_OUT = ~UCONFIG_IN;   // Bit 2 inverted and copied to output

/* Initialize Port B bits for output */
    AD1PCFGH = ANALOG1716;  // ENABLE analog 17, 16 only
    AD1PCFGL = ALLDIGITAL;  // Disable Analog function from B-Port Bits 15..0

    LATB = 0x0000;          // All zeroes
    TRISB = 0xDFE0;         // Set directions

// Set up the I2C routines
	I2C_Setup();

    I2CA_RESETB = 0;      // Lower I2CA_RESETB
	spin(SPINLIMIT);		// wait a while
    I2CA_RESETB = 1;      // Raise I2CA_RESETB

// Initialize and Set Threshhold DAC
	#if defined (DAC_ADDR)	// if address defined, it exists
    current_dac = DAC_INITIAL;
    current_dac = Write_DAC((unsigned char *)&current_dac);       // Set it to 100 mV
	#endif // defined (DAC_ADDR)

// Initialize Extended CSR (to PLD, etc)
	Initialize_ECSR();		// I2C == write4C = 00 00

// Initialize and Read Switches, button, and Jumpers
	Initialize_Switches();  // I2C == write22 = 00 9F etc.
// Get board-position switch
	switches = Read_MCP23008(SWCH_ADDR, MCP23008_GPIO);
    board_posn = (switches & BOARDSW4_MASK)>>BOARDSW4_SHIFT;   // position 0..7
// IF ECO14_SW4 is defined, we need to compensate for the bit0<-->bit2 swap error
#if defined (ECO14_SW4)
	j = board_posn & 2;	// save the center bit
	if ((board_posn&1)==1) j |= 4;	// fix the 4 bit
	if ((board_posn&4)==4) j |= 1;	// fix the 1 bit
	board_posn = j;
#endif // defined (ECO14_SW4)

// Initialize and Turn Off LEDs
    Initialize_LEDS();

// Initialize and Read Serial Number
#if defined (SN_ADDR) // if address defined, it exists
    Write_device_I2C1 (SN_ADDR, CM00_CTRL, CM00_CTRL_I2C);     // set I2C mode
#endif
    for (j=0; j<8; j++) {
#if defined (SN_ADDR)
        bwork[j] = (unsigned char)Read_MCP23008(SN_ADDR,j);        // go get sn byte
#else
        bwork[j] = j;
#endif
//      Briefly display each byte of Serial Number on LEDs
        Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, (unsigned int)(bwork[j]^0xFF)); //
//      spin (SPINLIMIT);
    }

// Initialize and Read Temperature Monitor
#if defined (TMPR_ADDR)
    Initialize_Temp (MCP9801_CFGR_RES12);   // configure 12 bit resolution
    board_temp = Read_Temp ();
    j = board_temp ^ 0xFFFF;        // flip bits for LED
    Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, (j&0xFF)); // display LSByte
//  spin(SPINLIMIT);
    Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, ((j>>8)&0xFF));
//  spin(SPINLIMIT);
#endif // defined (TMPR_ADDR)

/* -------------------------------------------------------------------------------------------------------------- */
	switches = Read_MCP23008(SWCH_ADDR, MCP23008_GPIO);
    jumpers = (switches & JUMPER_MASK)>>JUMPER_SHIFT;

/* -----------------12/9/2006 11:39AM----------------
** Jumper JU2.1-2 now controls MCU_SEL_LOCAL_OSC
** and MCU_EN_LOCAL_OSC
** Installing the jumper forces low on MCU_...OSC
** disabling it.
 --------------------------------------------------*/
// WB-11H - Osc selection
    if ( (jumpers & JUMPER_1_2) == JUMPER_1_2) { // See if jumper IN 1-2
                                        // Jumper INSTALLED inhibits local osc.
//        MCU_SEL_LOCAL_OSC = 0;          // turns off sel-local-osc
//        MCU_EN_LOCAL_OSC = 0;          // turns off en-local-osc
        Initialize_OSC (OSCSEL_TRAY);       //  Use TRAY clock
    } else {                        // Jumper OUT (use local osc)
//        MCU_SEL_LOCAL_OSC = 1;          // turns on sel-local-osc
//        MCU_EN_LOCAL_OSC = 1;          // turns on en-local-osc
        Initialize_OSC (OSCSEL_BOARD);       //  Use BOARD clock
    }                               // end else turn ON local osc

// Clear all interrupts
	clearIntrflags();

// Delay power-on by 1 second + 1 second x board-position switch value
#define DELAYPOWER 36
#if defined (DELAYPOWER)
    j = board_posn + 1;
    while ( j != 0 ) {
        spin(DELAYPOWER);               // delay approx 1 second per 36 counts
        --j;
    }                                   // end while spinning 1 sec per board posn

// Turn on power to HPTDC

#endif                                  // DELAYPOWER conditional
	tdcpowerbit |= ESCR_TDC_POWER;	    // Write the TDC Power-ON bit
    Write_device_I2C1 (ECSR_ADDR, MCP23008_OLAT, tdcpowerbit);
//		TDC Power is being turned on, delay a while
    ledbits = 0x7F;		// turn on orange LED
    Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, (jumpers^ledbits) );

    spin(5);
// Make sure FPGA has configured and reset it
//    waitfor_FPGA();
    reset_FPGA();
    init_regs_FPGA();

    j = 0;

// Do an HPTDC Reset
    write_FPGA (CONFIG_2_RW, ~CONFIG_2_TDCRESET); // HPTDC_RESET = 0;  // lower HPTDC Reset bit
    write_FPGA (CONFIG_2_RW,  CONFIG_2_TDCRESET); // HPTDC_RESET = 1; // raise "reset" bit
	spin(0);
    write_FPGA (CONFIG_2_RW, ~CONFIG_2_TDCRESET); // HPTDC_RESET = 0; // Lower RESET bit

// Write Board-Position to FPGA Register
    write_FPGA (CONFIG_12_W, board_posn);

/* -------------------------------------------------------------------------------------------------------------- */
/* ECAN1 Initialization
   Configure DMA Channel 0 for ECAN1 Transmit (buffers[0] )
   Configure DMA Channel 2 for ECAN1 Receive  (buffers[1] )
*/
    ecan1Init(board_posn);
    dma0Init();                     // defined in ECAN1Config.c (copied here)
    dma2Init();                     // defined in ECAN1Config.c (copied here)

/* Enable ECAN1 Interrupt */
    IEC2bits.C1IE = 1;                  // Interrupt Enable ints from ECAN1
    C1INTEbits.TBIE = 1;                // ECAN1 Transmit Buffer Interrupt Enable
    C1INTEbits.RBIE = 1;                // ECAN1 Receive  Buffer Interrupt Enable

/* Initialize large-block download */
    block_status = BLOCK_NOTSTARTED;    // no block transfer started yet
    block_bytecount = 0;
    block_checksum = 0L;

/* 09-Feb-2007
** Wait for a button press to start the next section
*/
//    buttoncount = 0;
//    do {
//        switches = Read_MCP23008(SWCH_ADDR, MCP23008_GPIO);
//		if ((switches & 0x1)==0x1) {
//			buttoncount++;
//		} else buttoncount = 0; // end else switch was not pressed
//		tglbit ^= 1;		// toggle the bit in port
//      MCU_TEST = tglbit;
// #if defined (RC15_IO) // RC15 will be I/O (in TDIG-D-Board.h)
//      LATCbits.LATC15 = tglbit;        // make it like RG15
// #endif
//        spin(5);
//    } while (buttoncount != BUTTONLIMIT);


// #define DOIDCODE 1
#if defined (DOIDCODE)
/* Read the HPTDC ID code using the JTAG routines, Send result via CAN */
    for (j=1; j<=NBR_HPTDCS; j++) {
      read_hptdc_id (j, (unsigned char *)&retbuf, (sizeof(retbuf)/sizeof(unsigned char)));
      send_CAN1_diagnostic (board_posn, 4, (unsigned char *)&retbuf);
    } // end loop over all NBR_HPTDCS (3)
#endif


/* Configure the HPTDCs */
    for (j=1; j<=NBR_HPTDCS; j++) {
        select_hptdc(JTAG_MCU, j);        // select MCU controlling which HPTDC
        // Copy "base" initialization to working inititalization
//        for (i=0; i<J_HPTDC_SETUPBYTES; i++) {hptdc_setup[j][i] = basic_setup[i];}
        memcpy (&hptdc_setup[j][0], &basic_setup[0], J_HPTDC_SETUPBYTES);
        hptdc_setup[j][5] &= 0xFFF0;    // clear old TDC ID value
#if defined (REVTDCNUMBER)              // if defined, use revised method (J.Schambach 6-Sep-07)
        // Fix up HPTDC ID byte in working initialization (Revised method)
        // board_posn 0,4 have TDCs 0x0,0x1,0x2
        // board_posn 1,5 have TDCs 0x4,0x5,0x6
        // board_posn 2,6 have TDCs 0x8,0x9,0xA
        // board_posn 3,7 have TDCs 0xC,0xD,0xE
        // ((lo 2 bits of board posn) << 2 bits) or'd with (lo 2 bits of (index-1))
        hptdc_setup[j][5] |= ((board_posn&0x3)<<2) | ((j-1)&0x3); // compute and insert new value
#else
        // Fix up HPTDC ID byte in working initialization (Original method)
        // board_posn 0,4 have TDCs 0x0,0x1,0x2
        // board_posn 1,5 have TDCs 0x3,0x4,0x5
        // board_posn 2,6 have TDCs 0x6,0x7,0x8
        // board_posn 3,7 have TDCs 0x9,0xA,0xB
        hptdc_setup[j][5] |= ((((board_posn&0x3)*NBR_HPTDCS)+(j-1))&0xF); // compute and insert new value
#endif                                  // Not NEWTDCNUMBER (old method)
        // Fix up Parity bit in working initialization
		insert_parity (&hptdc_setup[j][0], J_HPTDC_SETUPBITS);
        write_hptdc_setup (j, (unsigned char *)&hptdc_setup[j][0], (unsigned char *)&readback_setup);
        // check for match between working and read-back initialization
        maskoff = 0xFF;
        for (i=0; i<J_HPTDC_SETUPBYTES;i++){ // checking readback
            if (i == (J_HPTDC_SETUPBYTES-1)) maskoff = 0x7F;     // don't need last bit!
            if ((unsigned char)hptdc_setup[j][i] != ((unsigned char)readback_setup[i])&maskoff) {
//                send_CAN1_hptdcmismatch (board_posn, j, i, (unsigned char)hptdc_setup[j][i], (unsigned char)readback_setup[i]);
                if ((ledbits & 0x10) != 0) {
                    ledbits &= 0xEF;    //
                    Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, ledbits);
                    // set LED 4 if there was an error
                    // send a mismatch CAN error
                } // end if have not already seen 1 error
            } // end if got a mismatch
        } // end loop over checking readback
        // LED 4 SET if there was an error
        memcpy (&hptdc_control[j][0], &enable_final, J_HPTDC_CONTROLBYTES);
        reset_hptdc (j, &hptdc_control[j][0]);                    // JTAG the hptdc reset sequence
    } // end loop over all NBR_HPTDCS(3)

// If no error, turn on LED 6
    if ((ledbits & 0x10) != 0) {    // bit 4 is hi (led OFF) if no mismatch error issued
        ledbits &= 0xBF;    //
        Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, ledbits);
    } // end if no error
    reset_FPGA();
    spin(0);

// Lo jumpers select TDC for JTAG using CONFIG_1 register in FPGA
// Re-enabled and moved to before ALERT message 08-Mar-07
    select_hptdc(JTAG_HDR,(jumpers&0x3));        // select HEADER (J15) controlling which HPTDC
    ledbits = (ledbits|0x0F) ^ (jumpers & 0x0F);    //
    Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, ledbits);

    spin(0);           // spin loop

// Select this board as first in readout chain if it is board =0 or 4
    write_FPGA (CONFIG_0_RW, 0);    // Configure FPGA readout normal
    if ((board_posn==0) || (board_posn==4)) {
        write_FPGA (CONFIG_0_RW, CONFIG_0_FIRSTR);    // Configure FPGA readout First board in chain
    } // End if this is first board in chain

/* Read the HPTDC Status using the JTAG port, Send result via CAN */
//    for (j=0; j<NBR_HPTDCS; j++) {
//        read_hptdc_status (j, (unsigned char *)&retbuf, 10);
//        send_CAN1_diagnostic (board_posn, 8, (unsigned char *)&retbuf);
//    } // end loop over all 3 HPTDCs

/* -------------------------------------------------------------------------------------------------------------- */
	switches = Read_MCP23008(SWCH_ADDR, MCP23008_GPIO);
    jumpers = (switches & JUMPER_MASK)>>JUMPER_SHIFT;

// WB-11H
// CLOCK SWITCHING IS NOT DYNAMIC - Clock Jumper is read once at start-up and not examined thereafter.
/* -----------------12/9/2006 11:39AM----------------
** Jumper JU2.1-2 now controls MCU_SEL_LOCAL_OSC
** and MCU_EN_LOCAL_OSC
** Installing the jumper forces low on MCU_...OSC
** disabling it.
 --------------------------------------------------*/
//    if ( (jumpers & JUMPER_1_2) == JUMPER_1_2) {    // See if jumper IN
//        MCU_SEL_LOCAL_OSC = 0;          // turns off sel-local-osc
//        MCU_EN_LOCAL_OSC  = 0;          // turns off en-local-osc
//    } else {                        // Jumper OUT (use local osc)
//        MCU_SEL_LOCAL_OSC = 1;          // turns on sel-local-osc
//        MCU_EN_LOCAL_OSC  = 1;          // turns on en-local-osc
//    }                               // end else turn ON local osc

// Lo jumpers select TDC for JTAG using CONFIG_1 register in FPGA
    select_hptdc(JTAG_HDR,(jumpers&0x3));        // select HEADER (J15) controlling which HPTDC
    spin(5);           // spin loop

// #define DODATATEST 1
#if defined (DODATATEST)
    write_FPGA (STROBE_9_W, 0);        // Reset local Readout state machine
    write_FPGA (STROBE_10_W, 0);        // Reset MCU FIFO
    write_FPGA (CONFIG_0_RW, CONFIG_0_TEST);    // set test mode
    for (j=0; j<8; j++) write_FPGA (STROBE_11_W, 0);
#endif

/* Send an "Alert" message to say we are on-line */
//    pld_ident = read_FPGA (IDENT_7_R);
    send_CAN1_alert (board_posn);
/* Send a diagnostic message showing which clock we are running */
//    l = OSCCON;         // read the OSCCON register
//    send_CAN1_diagnostic (board_posn, 2, (unsigned char *)&l);  // send the OSCCON value

#if defined (MCUREPROGRAM1)
/* MCU REPROGRAMMING TEST #1
** See if we can read from Processor ID String
*/
    read_MCU_pm ((unsigned char *)&block_buffer[0], 0xF80010L); // Read from ID field
    read_MCU_pm ((unsigned char *)&block_buffer[1], 0xF80012L); // Read from ID field
    read_MCU_pm ((unsigned char *)&block_buffer[2], 0xF80014L); // Read from ID field
    read_MCU_pm ((unsigned char *)&block_buffer[3], 0xF80016L); // Read from ID field
    send_CAN1_diagnostic (board_posn, 8, block_buffer);
/* We saw the same value for processor ID bytes as was revealed by MPLAB */
#endif // defined MCUREPROGRAM1

//#define MCUREPROGRAM2
#if defined (MCUREPROGRAM2)
/* MCU REPROGRAMMING TEST #2
** See if we can read from program memory at 0x4000 and 0x4002
*/
    read_MCU_pm ((unsigned char *)&retbuf[0], 0x4000L); // Read from 0x4000
    read_MCU_pm ((unsigned char *)&retbuf[4], 0x4002L); // Read from 0x4002
    send_CAN1_diagnostic (board_posn, 8, retbuf);    // tell what we read.
/* We saw the expected values of 0x00FFFFF 0x00FFFFFF for an erased device */
#endif // defined (MCUREPROGRAM2)

//#define MCUREPROGRAM3
#if defined (MCUREPROGRAM3)
/* MCU REPROGRAMMING TEST #3
** See if we can program to memory at 0x4002
*/
    block_buffer[0] = 0x1;
    block_buffer[1] = 0x2;
    block_buffer[2] = 0x3;
    block_buffer[3] = 0x4;
    write_MCU_pm ((unsigned char *)&block_buffer[0], 0x4002L); // Write a word
//
    read_MCU_pm ((unsigned char *)&retbuf[0], 0x4000L); // Read from 0x4000
    read_MCU_pm ((unsigned char *)&retbuf[4], 0x4002L); // Read from 0x4002
//
    send_CAN1_diagnostic (board_posn, 8, retbuf);
/* We saw FF FF FF 00 01 02 03 00 which agrees with what we expected */
#endif

//#define MCUREPROGRAM4
#if defined (MCUREPROGRAM4)
/* MCU REPROGRAMMING TEST #4
** read the memory at 0x200 and 0x202 and see if it agrees with manual HEX file
*/
    read_MCU_pm ((unsigned char *)&retbuf[0], 0x200L); // Read from 0x200
    read_MCU_pm ((unsigned char *)&retbuf[4], 0x202L); // Read from 0x202
    send_CAN1_diagnostic (board_posn, 8, retbuf);
/* We saw 80 01 78 00 02 00 e0 00 ; just like original .hex file */
#endif
/* Look for Have-a-Message
*/
    do {                            // Do Forever
        if ( C1RXFUL1bits.RXFUL1 ) {
// Dispatch to Message Code handlers.
// Note that Function Code symbolics are defined already shifted.
			unsigned int rcvmsglen = ecan1msgBuf[1][2] & 0x000F; //JS
            retbuf[0] = ecan1msgBuf[1][3];  // pre-fill reply with "subcommand" payload[0]
            retbuf[1] = C_STATUS_OK;            // Assume all is well (status OK)
            wps = (unsigned char *)&ecan1msgBuf[1][3];   // point to message text (source)
            switch ((ecan1msgBuf[1][0] & C_CODE_MASK)) {  // Major switch on WRITE or READ COMMAND
                case C_WRITE:  // Process a "Write"
                    replylength = 2;                    // Assume 2 byte reply for Writes
                    // now decode the "Write-To" Subcommand from inside message
                    switch ((*wps++)&0xFF) {       // look at and dispatch SUB-command, point to remainder of message
                        case C_WS_LED:              // Write to LED register
                            Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, ~(*wps));
                            break;

                        case C_WS_FPGARESET:        // Issue an FPGA Reset
                            memcpy ((unsigned char *)&lwork, wps, 4);   // copy 4 bytes from incoming message
                            // Confirm length is correct and constant agrees
                            //JS if ((ecan1msgBuf[1][2] == FPGARESET_LEN) && (lwork == FPGARESET_CONST)) {
                            if ((rcvmsglen == FPGARESET_LEN) && (lwork == FPGARESET_CONST)) { //JS
                                reset_FPGA();       // do the reset if all is ok
                            } else retbuf[1] = C_STATUS_INVALID;    // else mark invalid
                            break;

                        case C_WS_FPGAREG:          // Write to FPGA Register(s)
                            i = 3;
                            //JS while (i <= ecan1msgBuf[1][2]) { // for length of message (1, 2, or 3 reg,val pairs)
                            while (i <= rcvmsglen) { // for length of message (1, 2, or 3 reg,val pairs) //JS
                                j = *wps++;
                                write_FPGA (j, (*wps++));
                                i+=2;
                            } // end while have something in message (1, 2, or 3 reg,val pairs)
                            break;

                        case C_WS_BLOCKSTART:       // Start Block Download
                            block_status = BLOCK_INPROGRESS;
                            block_bytecount = 0;    // clear block buffer counter
                            block_checksum = 0L;    // clear block buffer checksum
                            wpd = (unsigned char *)&block_buffer[0];    // point destination to buffer
                            // Copy any data from message.  We don't need to check buffer length since it was just set "empty"
                            //JS for (i=1; i<ecan1msgBuf[1][2]; i++) {   // copy any remaining bytes
                            for (i=1; i<rcvmsglen; i++) {   // copy any remaining bytes //JS
                                    *wpd++ = *wps;        // copy byte into buffer
                                    block_checksum += (*wps++)&0xFF;
                                    block_bytecount++;
                            } // end loop over any bytes in message
                            break;

                        case C_WS_BLOCKDATA:        // Block Data Download
                            if (block_status == BLOCK_INPROGRESS) {
                                //JS for (i=1; i<ecan1msgBuf[1][2]; i++) {
                                for (i=1; i<rcvmsglen; i++) { //JS
                                    if (block_bytecount < BLOCK_BUFFERSIZE) {
                                        *wpd++ = *wps;        // copy byte into buffer
                                        block_checksum += (*wps++)&0xFF;
                                        block_bytecount++;
                                    } else {                // buffer is full
                                        retbuf[1] = C_STATUS_OVERRUN;       // SET ERROR REPLY
                                    } // end if can put data in buffer
                                } // end for loop to copy data
                                // end if had block in progress
                            } else {        // else block was not in progress, send error reply
                                retbuf[1] = C_STATUS_NOSTART;       // SET ERROR REPLY
                            } // end else block was not in progress
                            break;

                        case C_WS_BLOCKEND:         // End Data Download
                            if (block_status == BLOCK_INPROGRESS) {
                                // mark end of block and send bytes and checksum
                                block_status = BLOCK_ENDED;
                                memcpy ((unsigned char *)&retbuf[2], (unsigned char *)&block_bytecount, 2);    // copy bytecount
                                memcpy ((unsigned char *)&retbuf[4], (unsigned char *)&block_checksum, 4);    // copy checksum
                                replylength = 8;            // Update length of reply
                            } else {        // else block was not in progress, send error reply
                                retbuf[1] = C_STATUS_NOSTART;       // ERROR REPLY
                            } // end else block was not in progress
                            break;

                        case C_WS_TARGETHPTDCS:
                        case C_WS_TARGETHPTDC1:
                        case C_WS_TARGETHPTDC2:
                        case C_WS_TARGETHPTDC3:
                            if (block_status == BLOCK_ENDED) {
                                if (block_bytecount == J_HPTDC_SETUPBYTES) {    // if bytecount OK
                                    if ((retbuf[0]&0x3) == 0) { // are we doing all 3?
                                        i = 1;          // yes, set first
                                        k = NBR_HPTDCS;          // yes, set last
                                    } else {            // Not all 3,
                                        i = (retbuf[0]&0x3);       // set first and last to be the one
                                        k = i;          // set first and last to be the one
                                    } // end if one or all 3 HPTDCs.
                                    for (j=i; j<=k; j++) {   // put the data into an HPTDC
                                        select_hptdc(JTAG_MCU, j);        // select MCU controlling which HPTDC
                                        // Copy the received buffer into the setup buffer
                                        memcpy (&hptdc_setup[j][0], &block_buffer[0], J_HPTDC_SETUPBYTES);
                                        hptdc_setup[j][5] &= 0xFFF0;    // clear old TDC ID value
                                        #if defined (REVTDCNUMBER)              // if defined, use revised method (J.Schambach 6-Sep-07)
                                        // Fix up HPTDC ID byte in working initialization (Revised method)
                                        // board_posn 0,4 have TDCs 0x0,0x1,0x2
                                        // board_posn 1,5 have TDCs 0x4,0x5,0x6
                                        // board_posn 2,6 have TDCs 0x8,0x9,0xA
                                        // board_posn 3,7 have TDCs 0xC,0xD,0xE
                                        // ((lo 2 bits of board posn) << 2 bits) or'd with (lo 2 bits of (index-1))
                                        hptdc_setup[j][5] |= ((board_posn&0x3)<<2) | ((j-1)&0x3); // compute and insert new value
                                        #else
                                        // Fix up HPTDC ID byte in working initialization
                                        // board_posn 0,4 have TDCs 0x0,0x1,0x2
                                        // board_posn 1,5 have TDCs 0x3,0x4,0x5
                                        // board_posn 2,6 have TDCs 0x6,0x7,0x8
                                        // board_posn 3,7 have TDCs 0x9,0xA,0xB
                                        hptdc_setup[j][5] |= ((((board_posn&0x3)*NBR_HPTDCS)+(j-1))&0xF); // compute and insert new value
                                        #endif                                  // Not NEWTDCNUMBER (old method)
                                        // Fix up Parity bit in working initialization
                                        insert_parity (&hptdc_setup[j][0], J_HPTDC_SETUPBITS);
                                        write_hptdc_setup (j, (unsigned char *)&hptdc_setup[j][0], (unsigned char *)&readback_setup);
                                        // check for match between working and read-back initialization
                                        maskoff = 0xFF;
                                        for (l=0; l<J_HPTDC_SETUPBYTES;l++){ // checking readback
                                            if (l == (J_HPTDC_SETUPBYTES-1)) maskoff = 0x7F;     // don't need last bit!
                                            if ((unsigned char)hptdc_setup[j][i] != ((unsigned char)readback_setup[i])&maskoff) {
                                                retbuf[1] = C_STATUS_BADCFG;    // bad configuration status
                                                if ((ledbits & 0x10) != 0) {
                                                    ledbits &= 0xEF;    //
                                                    Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, ledbits);
                                                // set LED 4 if there was an error
                                                } // end if have not already seen 1 error
//                                                send_CAN1_hptdcmismatch (board_posn, j, l, (unsigned char)hptdc_setup[j][l], (unsigned char)readback_setup[l]);
                                            } // end if got a mismatch
                                        } // end loop over checking readback
                                        // LED 4 SET if there was an error
                                        reset_hptdc (j, &hptdc_control[j][0]);                    // JTAG the hptdc reset sequence
                                    } // end loop over one or all HPTDCs
                                    // restore Test header access to JTAG
                                    // Lo jumpers select TDC for JTAG using CONFIG_1 register in FPGA
                                    select_hptdc(JTAG_HDR,(jumpers&0x3));        // select HEADER (J15) controlling which HPTDC
                                } else {  // Length is not right
                                    retbuf[1] = C_STATUS_LTHERR;     // SET ERROR REPLY
                                } // end else length was not OK
                            } else {        // else block was not ended, send error reply
                                retbuf[1] = C_STATUS_NOSTART;       // ERROR REPLY
                            } // end else block was not in progress
                            break;

                        case C_WS_RECONFIGEE1:              // Reconfigure FPGA using EEPROM #1
                        case C_WS_RECONFIGEE2:              // Reconfigure FPGA using EEPROM #2
                            memcpy ((unsigned char *)&lwork, wps, 4);   // copy 4 bytes from incoming message
                            // Confirm length and have proper code
                            //JS if ((ecan1msgBuf[1][2] == RECONFIG_LEN) && (lwork == RECONFIG_CONST)) {
                            if ((rcvmsglen == RECONFIG_LEN) && (lwork == RECONFIG_CONST)) { //JS
                                i = ecan1msgBuf[1][3] & 0x3;    // get which EEPROM we are doing
                                retbuf[1] = C_STATUS_OK;        // assume FPGA configuration OK
// loop here if it failed the first time
                                do {
                                    MCU_CONFIG_PLD = 0; // disable FPGA configuration
                                    if (i==2) {
                                        sel_EE2;        // select EEPROM #2
                                    } else {
                                        sel_EE1;        // else it was #1
                                    } // end if select EEPROM #
                                    set_EENCS;      //
                                    MCU_CONFIG_PLD = 1; // re-enable FPGA
                                    j = waitfor_FPGA();     // wait for FPGA to reconfigure
                                    if (j != 0) {
                                        retbuf[1] = C_STATUS_TMOFPGA;   // report an FPGA configuration timeout
                                        i--;        // try again from #1
                                    } // end if had timeout
                                } while ((i != 0) && (j != 0));       // try til either both were used or no error
                                reset_FPGA();       // reset FPGA
                                init_regs_FPGA();   // initialize FPGA
                                pld_ident = read_FPGA (IDENT_7_R);
                                retbuf[2] = pld_ident;  // tell the magic ID code value
                                replylength = 3;
                            } else {        // else we could not do it
                                retbuf[1] = C_STATUS_INVALID;   // Assume ERROR REPLY
                                replylength = 2;
                            } // end if we could not do it
                            break;

                        case C_WS_TARGETEEPROM2:
                            if (block_status == BLOCK_ENDED) {
                                if ((block_bytecount != 0) && (block_bytecount <= 256) ){    // if bytecount OK
                                    // copy eeprom address
                                    memcpy ((unsigned char *)&eeprom_address, wps, 4);    // copy eeprom target address
                                    eeprom_address &= 0xFFFF00L; // mask off lowest bits (byte in page)
                                    wps += 4;
                                    MCU_CONFIG_PLD = 0; // disable FPGA configuration
                                    sel_EE2;            // select EEPROM #2
                                    if ((*wps)==1) {// see if need to erase
                                        // Write-enable the CSR, data doesn't matter
                                        spi_write (EE_AL_WREN, MS2LSBIT, 0, (unsigned char *)&retbuf);
                                        // Do the erase, data doesn't matter
                                        spi_write_adr (EE_AL_ERAS, (unsigned char *)&eeprom_address, MS2LSBIT, 0, (unsigned char *)&retbuf[0]);
                                        // wait for completion
                                        spi_wait (EE_AL_RDSR, EE_AL_BUSY);
                                    } // end if need to erase
                                    // Write-enable the CSR, data doesn't matter
                                    spi_write (EE_AL_WREN, MS2LSBIT, 0, (unsigned char *)&retbuf);
                                    // write the bytes (Altera .RBF gets written LS bit to MS bit
                                    spi_write_adr (EE_AL_WRDA, (unsigned char *)&eeprom_address, LS2MSBIT, block_bytecount, (unsigned char *)&block_buffer[0]);
                                    // wait for completion
                                    spi_wait (EE_AL_RDSR, EE_AL_BUSY);
                                    retbuf[1] = C_STATUS_OK;    // assume all was well
                                    // Read back data and check for match (Altera .RBF was written LSbit to MSbit)
                                    for (i=0; i<block_bytecount; i+= 8) {
                                        lwork = eeprom_address + i;
                                        spi_read_adr (EE_AL_RDDA, (unsigned char *)&lwork, LS2MSBIT, 8, (unsigned char *)&sendbuf[0]);
                                        for (j=0; j<8; j++) if (sendbuf[j] != block_buffer[i+j]) retbuf[1] = C_STATUS_BADEE2;
                                    } // end loop checking readback of newly written data

                                    sel_EE1;        // de-select EEPROM #2
                                    set_EENCS;      //
                                    MCU_CONFIG_PLD = 1; // re-enable FPGA
//                                    waitfor_FPGA(); // wait for FPGA to reconfigure
                                    reset_FPGA();   // reset FPGA
                                    init_regs_FPGA(); // initialize FPGA
                                    // Write Board-Position to FPGA Register
                                    write_FPGA (CONFIG_12_W, board_posn);
                                } else {  // Length is not right
                                    retbuf[1] = C_STATUS_LTHERR;     // SET ERROR REPLY
                                } // end else length was not OK
                            } else {        // else block was not ended, send error reply
                                retbuf[1] = C_STATUS_NOSTART;       // ERROR REPLY
                            } // end else block was not in progress
                            break;  // end case C_WS_TARGETEEPROM2
// WB-11H If second image is running we do not want to download another second image
#if !defined (DOWNLOAD_CODE)
                        case C_WS_TARGETMCU:
                            if (block_status == BLOCK_ENDED) {
                                // check for correct length of stored block and incoming message
                                //JS if ( (block_bytecount != 0) && (ecan1msgBuf[1][2] == 6) ) {
                                if ( (block_bytecount != 0) && (rcvmsglen == 6) ) { //JS
                                    // lengths OK, set parameters for doing this block
                                    j = 0;          // assume start is begin of buffer
                                    k = block_bytecount;        // assume just going block
                                    memcpy ((unsigned char *)&laddrs, wps, 4);   // copy 4 address bytes from incoming message
                                    lwork = laddrs;        // save for later
                                    wps += 4;
                                    if ((*wps)==ERASE_PRESERVE) {     // need to preserve before erase
                                        lwork = laddrs & PAGE_MASK;   // mask to page start
                                        for (i=0; i<PAGE_BYTES; i+=4) {
                                            read_MCU_pm ((unsigned char *)&readback_buffer[i], lwork);
                                            lwork += 2;
                                        } // end for loop over all bytes in save block
                                        lwork = laddrs & PAGE_MASK;
                                        j = (unsigned int)(laddrs & OFFSET_MASK); // save offset for copy
                                        j <<= 1;        // *2 for bytes
                                        k = PAGE_BYTES;                   // reprogram whole block
                                    } // end if need to save before copy

                                    // put the new data over the old[j] thru old[j+block_bytecount-1]
                                    memcpy ((unsigned char *)&readback_buffer[j], block_buffer, block_bytecount);
                                    save_SR = SR;           // save the Status Register
                                    SR |= 0xE0;             // Raise CPU priority to lock out  interrupts
                                    if ( ((*wps)==ERASE_NORMAL) || ((*wps)==ERASE_PRESERVE) ) {// see if need to erase
                                        erase_MCU_pm ((laddrs & PAGE_MASK));      // erase the page
                                    } // end if need to erase the page
                                    // now write the block_bytecount or PAGE_BYTES starting at actual address or begin page
                                    lwork2 = lwork;
                                    for (i=0; i<k; i+=4) {
                                        write_MCU_pm ((unsigned char *)(readback_buffer+i), lwork); // Write a word
                                        lwork += 2L;    // next write address
                                    } // end loop over bytes
                                    SR = save_SR;           // restore the saved status register
                                    // now check for correct writing
                                    lwork = lwork2;                             // recall the start address
                                    for (i=0; i<k; i+=4) {                  // read either k= block_bytecount or 2048
                                        read_MCU_pm ((unsigned char *)&bwork, lwork); // read a word
                                        for (j=0; j<4; j++) {       // check each word
                                            if (bwork[j] != readback_buffer[i+j]) retbuf[1] = C_STATUS_BADEE2;
                                        } // end loop checking 4 bytes within each word
                                        lwork += 2L;    // next write address
                                    } // end loop over bytes
                                } else {  // Length is not right
                                    retbuf[1] = C_STATUS_LTHERR;     // SET ERROR REPLY
                                } // end else length was not OK
                            } else {        // else block was not ended, send error reply
                                retbuf[1] = C_STATUS_NOSTART;       // ERROR REPLY
                            } // end else block was not in progress
                            break;  // end case C_WS_TARGETMCU
#endif // #if !defined (DOWNLOAD_CODE)

                        case C_WS_BLOCKCKSUM:       // Block Data Checksum
                            retbuf[1] = C_STATUS_INVALID;
                            break;

                        case C_WS_CONTROLTDCS:           // Copy Control word to ALL TDCs
                        case C_WS_CONTROLTDC1:           // Copy Control word to TDC #1
                        case C_WS_CONTROLTDC2:           // Copy Control word to TDC #2
                        case C_WS_CONTROLTDC3:           // Copy Control word to TDC #3
                            if ((retbuf[0]&0x3) == 0) { // are we doing all 3?
                                j = 1;                  // yes, set first is number 1
                                k = NBR_HPTDCS;         // yes, set last is NBR_HPTDCS
                            } else {                    // Not all 3,
                                j = (retbuf[0]&0x3);    // set first to be the one specified
                                k = j;                  // and last to be the one specified
                            } // end if one or all 3 HPTDCs.
                            for (i=j; i<=k; i++) {   // put the data into one or more HPTDCs
                                select_hptdc(JTAG_MCU, i);        // select MCU controlling which HPTDC
                                // Copy the received buffer (wps) into the setup buffer
                                memcpy (&hptdc_control[i][0], wps, J_HPTDC_CONTROLBYTES);
                                control_hptdc(i, (unsigned char *)&hptdc_control[i][0]);
                            } // end loop over one or more HPTDCs
                            select_hptdc(JTAG_HDR,(jumpers&0x3));        // select HEADER (J15) controlling which HPTDC
                            break; // end of C_WS_CONTROLTDCx

                        case C_WS_THRESHHOLD:        // Write-to-THRESHHOLD DAC
                            current_dac = Write_DAC (((unsigned char *)&ecan1msgBuf[1][3])+1); // point to LSB of DAC setting
                            for (i=0; i<8; i++) ecan1msgBuf[0][i] = ecan1msgBuf[1][i]; // save message for echo reply
                            break;

                        case C_WS_MCURESTARTA:              // 0x8D MCU Start new image
                        case C_WS_MCURESET:                 // 0x8F MCU Reset (POR Reset)
                            retbuf[1] = C_STATUS_INVALID;   // Assume ERROR REPLY
                            replylength = 2;
                            memcpy ((unsigned char *)&lwork, wps, 4);   // copy 4 bytes from incoming message
                            // Confirm length is 5 and have proper code
                            //JS if ((ecan1msgBuf[1][2] == MCURESET_LEN) && (lwork == MCURESET_CONST)) {
                            if ((rcvmsglen == MCURESET_LEN) && (lwork == MCURESET_CONST)) { //JS
                                retbuf[1] = C_STATUS_OK;            // acknowledge we are going to do it
                                send_CAN1_message (board_posn, (C_TDIG | C_WRITE_REPLY), replylength, (unsigned char *)&retbuf);
                                while (C1TR01CONbits.TXREQ0==1) {};    // wait for transmit to complete
                                if ((ecan1msgBuf[1][3] & 0xFF) == C_WS_MCURESTARTA) {  // if we are starting new code
#ifndef DOWNLOAD_CODE
                                    // stop interrupts
                                    CORCONbits.IPL3=1;     // WB-11H Raise CPU priority to lock out user interrupts
                                    save_SR = SR;          // save the Status Register
                                    SR |= 0xE0;            // Raise CPU priority to lock out interrupts
// be sure we are running from alternate interrupt vector
                                    INTCON2 |= 0x8000;     // This is the ALTIVT bit
                                    jumpto();    // jump to new code
#endif
                                } // end if we are starting second image.
                                __asm__ volatile ("reset");  // else we do "reset" (_resetPRI)
                            } // end if have valid reset or start new image message
                            break;

                        default:                    // Undecodeable
                            retbuf[1] = C_STATUS_INVALID;       // ERROR REPLY
                            break;
                    }                           // end switch on Write Subcommand
                    // Send the reply to the WRITE message
                    send_CAN1_message (board_posn, (C_TDIG | C_WRITE_REPLY), replylength, (unsigned char *)&retbuf);
                    break;  // end case C_WRITE

                case C_READ:    // Process a "Read"
                    replylength = 1;        // default reply length for a Read
                    retbuf[0] = ecan1msgBuf[1][3] & 0xFF;   // copy address byte

                                // now decode the "Read-from" location inside message
                    switch ((*wps++)&0xFF) {       // look at and dispatch SUB-command, point to remainder of message
                        case (C_RS_STATUS1):              // READ STATUS #1
                        case (C_RS_STATUS2):              // READ STATUS #2
                        case (C_RS_STATUS3):              // READ STATUS #3
                            /* Read the HPTDC Status using the JTAG port, Send result via CAN */
                            i = ecan1msgBuf[1][3] & 0x3;            // LOW 2 bits are TDC#
// WB-11H - Use read_hptdc_status() routine instead of code duplicated here
                            read_hptdc_status (i, (unsigned char *)&retbuf[1], (sizeof(retbuf)-1));
//                            memset (&retbuf[1], 0, (sizeof(retbuf))-1); // clear before reading but save first byte of reply
//                            select_hptdc(JTAG_MCU, i);        // select which HPTDC
//                            reset_TAP();                    // WB-11H
//                            IRScan ((unsigned char)J_HPTDC_STATUS);       // 0x0A = parity + status instruction
//                            DRScan ((unsigned char *)&sendbuf, J_HPTDC_STATUSBITS, J_RETURN_DATA, (unsigned char *)&retbuf[1]);
//                            reset_TAP();                    // WB-11H
//                            select_hptdc(JTAG_HDR, i);        // de-select HPTDC
// WB-11H end
                            // send the first part of the reply
                            replylength = 8;
// WB-11H testing of Status Reply
//      - If the following is #defined, only the low-order part of the status is sent (so we can see it in PCANView)
// #define HPTDCS_LOW 1
#if !defined (HPTDCS_LOW)
                            send_CAN1_message (board_posn, (C_TDIG | C_READ_REPLY), 8, (unsigned char *)&retbuf);
                            // send the second part of the reply
                            retbuf[1] = retbuf[8];      // copy last byte for sending
                            replylength = 2;
                            // second part gets sent at end of Switch statement.
							//JS: wait a little, so TCPU can receive this:
							spin(0);
#endif
                            break; // end case C_RS_STATUSx

                        case (C_RS_MCUMEM ):            // Return MCU Memory 4-bytes
                            //JS if (ecan1msgBuf[1][2] == 5) { // check for correct length of incoming message
                            if (rcvmsglen == 5) { // check for correct length of incoming message //JS
                                memcpy ((unsigned char *)&lwork, wps, 4);   // copy 4 bytes from incoming message
                            } else {        // allow continued reads w/o address
                                lwork += 2L;
                            } // end else continued reads
                            read_MCU_pm ((unsigned char *)&retbuf[1], lwork); // Read from requested location
                            replylength = 5;
                            break; // end case C_RS_MCUMEM


                        case (C_RS_FIRMWID):            // Return MCU Firmware ID
                            retbuf[1] = FIRMWARE_ID_0;
                            retbuf[2] = FIRMWARE_ID_1;
                            retbuf[3] = (unsigned char)(read_FPGA (IDENT_7_R)&0xFF);
                            replylength = 4;
                            break; // end case C_RS_FIRMWID

#if defined (SN_ADDR) // if address defined, it exists
                        case (C_RS_SERNBR):           // Return the board Serial Number
                            Write_device_I2C1 (SN_ADDR, CM00_CTRL, CM00_CTRL_I2C);     // set I2C mode
                            for (j=1; j<8; j++) {       // we only return 7 bytes (of 8)
                                retbuf[j] = (unsigned char)Read_MCP23008(SN_ADDR,j);        // go get sn byte
                            }
                            replylength = 8;
                            break; // end case C_RS_SERNBR
#endif // defined (SN_ADDR)

                        case (C_RS_STATUSB):              // READ STATUS Board
                            for (i=1; i<8; i++) retbuf[i] = 0;   // stubbed off for now
                            board_temp = Read_Temp();
                            memcpy ((unsigned char *)&retbuf[1], (unsigned char *)&board_temp, 2);
                            retbuf[3] = (unsigned char)Read_MCP23008(ECSR_ADDR, MCP23008_GPIO);
                            replylength = 8;
                            break; // end case C_RS_STATUSB

                        case (C_RS_TEMPBRD):           // Return the board Temperature
                            board_temp = Read_Temp ();
                            memcpy ((unsigned char *)&retbuf[1], (unsigned char *)&board_temp, 2);        // copy temperature to message
                            replylength = 3;
                            break; // end case C_RS_TEMPBRD

                        case (C_RS_FPGAREG):          // Read from FPGA Register(s)
                            replylength = 1;
                            i = 2;
                            //JS while (i <= (ecan1msgBuf[1][2]&0xFF)) { // for length of message (1, 2, or 3 reg,val pairs)
                            while (i <= rcvmsglen) { // for length of message (1, 2, or 3 reg,val pairs) //JS
                                retbuf[replylength] = *wps++;
                                retbuf[replylength+1] = read_FPGA((unsigned int)(retbuf[replylength]&0xFF));
                                replylength +=2;
                                i++;
                            } // end while have something in message (1, 2, or 3 reg,val pairs)
                            break;                  // end C_RS_FPGAREG

                        case (C_RS_JSW):              // Return the Jumper/Switch settings (U35)
                            retbuf[1] = (unsigned char)Read_MCP23008(SWCH_ADDR, MCP23008_GPIO);
                            replylength = 2;
                            break; // end case C_RS_JSW

                        case (C_RS_ECSR):             // Return the Extended CSR settings (U36)
                            retbuf[1] = (unsigned char)Read_MCP23008(ECSR_ADDR, MCP23008_GPIO);
                            replylength = 2;
                            break; // end case C_RS_ECSR

                        default:    // Undecodable Read only echoes subcommand
                            break; // end case default

                    } // end switch on READ SUBCOMMAND (Address)
                    send_CAN1_message (board_posn, (C_TDIG | C_READ_REPLY), replylength, (unsigned char *)&retbuf);
                    break;

                default:                 // All others are undecodable, ignore
                    break;
            }                               // end MAJOR switch on WRITE or READ COMMAND
// Mark Receive buffer 1 OK to reuse
            C1RXFUL1bits.RXFUL1 = 0;
        } // end if have a message to process
#if defined (DODATATEST)
//        j = 0;
// See if we have data to send
          j = read_FPGA (FIFO_STATUS_R);
          if ((j & FIFO_WORDS_MASK) != 0) {
//        if ((j & FIFO_EMPTY_BIT) == 0) {
            memcpy ((unsigned char *)&sendbuf[4], (unsigned char *)&j, 2);      // send status at start
//        if ((read_FPGA (FIFO_STATUS_R)&FIFO_EMPTY_BIT) != 0) {  // Do we have data to send?
            // bit was not 0, we have data, send it
            sendbuf[0] = (unsigned char)read_FPGA (FIFO_BYTE0_R);
            sendbuf[1] = (unsigned char)read_FPGA (FIFO_BYTE1_R);
            sendbuf[2] = (unsigned char)read_FPGA (FIFO_BYTE2_R);
            sendbuf[3] = (unsigned char)read_FPGA (FIFO_BYTE3_R);
//            j += 4;
            read_FPGA (FIFO_STATUS_R);          // extra read-status
            j = read_FPGA (FIFO_STATUS_R);      // get final status
            memcpy ((unsigned char *)&sendbuf[6], (unsigned char *)&j, 2);          // send status at end
//            // Check again for more data
//            if ((read_FPGA (FIFO_STATUS_R)&FIFO_EMPTY_BIT) != 0) {
//                sendbuf[4] = (unsigned char)read_FPGA (FIFO_BYTE0_R);
//                sendbuf[5] = (unsigned char)read_FPGA (FIFO_BYTE1_R);
//                sendbuf[6] = (unsigned char)read_FPGA (FIFO_BYTE2_R);
//                sendbuf[7] = (unsigned char)read_FPGA (FIFO_BYTE3_R);
//                j += 4;
//                read_FPGA (FIFO_STATUS_R);          // extra read-status
//            } // end if had more, send message regardless
            send_CAN1_data (board_posn, 8, (unsigned char *)&sendbuf[0] ); // fixed indexing 08-Mar-07
//            j = 0;
        } else { // No data to send, do the other stuff
            for (j=0; j<8; j++) write_FPGA (STROBE_11_W, 0);        // Generate some data
#endif
// Mostly Idle
            tglbit ^= 1;        // toggle the bit in port
            MCU_TEST = tglbit;
#if defined (RC15_IO) // RC15 will be I/O (in TDIG-D-Board.h)
            LATCbits.LATC15 = tglbit;        // make it like RG15
#endif
#define UDCONFIGBITS 1
#if defined (UDCONFIGBITS)
//          Copy UCONFIGI bit to DCONFIGO bit to allow testing of corresponding LVDS signals (define UDCONFIGBITS)
            DCONFIG_OUT = ~UCONFIG_IN;
#endif

// Mostly Idle, Check for change of switches/jumpers/button
            if ( (Read_MCP23008(SWCH_ADDR, MCP23008_GPIO)) != switches ) {        // if changed
                switches = Read_MCP23008(SWCH_ADDR, MCP23008_GPIO);
                if ((switches & BUTTON)==BUTTON) {            // if Button
                    spin(0);
                    switches = Read_MCP23008(SWCH_ADDR, MCP23008_GPIO);
                    if ((switches & BUTTON)==BUTTON) {        // still button?
//                      write_FPGA (STROBE_12_W, 0);
                    } // end if have second switch
                } // end if have first switch
                jumpers = (switches & JUMPER_MASK)>>JUMPER_SHIFT;
// WB-11H
// CLOCK SELECTION IS NOT DYNAMIC - JUMPER IS EXAMINED ONLY AT POWER-ON
//                if ( (jumpers & JUMPER_1_2) == JUMPER_1_2) { // See if jumper IN 1-2
//                                            // Jumper INSTALLED inhibits local osc.
//                    MCU_SEL_LOCAL_OSC = 0;          // turns off sel-local-osc
//                    MCU_EN_LOCAL_OSC = 0;          // turns off en-local-osc
//                } else {                        // Jumper OUT (use local osc)
//                    MCU_SEL_LOCAL_OSC = 1;          // turns on sel-local-osc
//                    MCU_EN_LOCAL_OSC = 1;          // turns on en-local-osc
//                }                               // end else turn ON local osc

// Lo jumpers select TDC for JTAG using CONFIG_1 register in FPGA
                select_hptdc(JTAG_HDR,(jumpers&0x3));        // select HEADER (J15) controlling which HPTDC
                ledbits = (ledbits|0x0F) ^ (jumpers & 0x0F);    //
                Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, ledbits);
//
                i = (switches & 0xF)>>1;   // position 0..7
// IF ECO14_SW4 is defined, we need to compensate for the bit0<-->bit2 swap error
#if defined (ECO14_SW4)
                j = i & 2; // save the center bit
                if ((i&1)==1) j |= 4;  // fix the 4 bit
                if ((i&4)==4) j |= 1;  // fix the 1 bit
#endif // defined (ECO14_SW4)
                write_FPGA (CONFIG_12_W, j);        // write new switch to config_12 in FPGA
            } // end if something changed
#if defined (DODATATEST)
        } // end else no data
#endif
    } while (1); // end do forever
}

// WB-11H
// Replaced old initialize_OSC routine

int Initialize_OSC (unsigned int selectosc){
/* initialize the CPU oscillator (works with settings in TDIG-D_CAN_HLP3.h)
** Call with: selectosc as follows:
**      selectosc == OSCSEL_BOARD  == 0 == Use on-Board oscillator (40 MHz)
**      selectosc == OSCSEL_TRAY   == 8 == Use Tray oscillator (40 MHz)
**      selectosc == OSCSEL_FRCPLL == 1 == Use MCU Fast RC + PLL (40 MHz)
*/
    int retstat = 0;                    // Assume OK return
    switch (selectosc) {
        case (OSCSEL_TRAY):             // Selecting TRAY clock
            MCU_SEL_LOCAL_OSC = 0;      // turns off sel-local-osc
            MCU_EN_LOCAL_OSC = 0;       // turns off en-local-osc
            Switch_OSC(MCU_EXTERN);     // Change MCU to External Osc
            break;
        case (OSCSEL_BOARD):            // Selecting BOARD clock
            MCU_SEL_LOCAL_OSC = 1;      // turns on sel-local-osc
            MCU_EN_LOCAL_OSC = 1;       // turns on en-local-osc
            spin(0);                    // wait for local osc to turn on
            Switch_OSC(MCU_EXTERN);     // Change MCU to External Osc
            break;
        case (OSCSEL_FRCPLL):           // Selecting Fast RC w/PLL for 40MHz
            Switch_OSC(MCU_FRCPLL);     /* Switch to FRCPLL */
            PLLFBD=20;                  /* M= 20*/
            CLKDIVbits.PLLPOST=0;       /* N1=2 */
            CLKDIVbits.PLLPRE=0;        /* N2=2 */
            OSCTUN=0;                   /* Tune FRC oscillator, if FRC is used */
//          OSCTUN=0x11;                /* Tune FRC oscillator upwards to 40 MHz */
            while(OSCCONbits.LOCK!=1) {}; /* Wait for PLL to lock */
            break;
        default:
            retstat = 1;                // mark bad return
            break;
    } // end else switching to external oscillator (board or tray)
    if (retstat == 0) ecan1Init(board_posn);      // if clock has changed we must reinitialize CANBus
    return(retstat);                    // return the status
}

void Switch_OSC(unsigned int mcuoscsel) {         /* Switch Clock Oscillator */
/* Parameter mcuoscsel ends up in W0
** WE MUST USE ASM TO INSURE THE EXACT SEQUENCE OF UNLOCK OPERATION CYCLES
** mcuoscsel determines Oscillator to use
**   0 = FRC
**   1 = FRC+PLL
**   2 = Primary Oscillator (XT, HS, or EC set by _FOSC()
**   3 = Primary Oscillator + PLL (XT, HS, or EC set by _FOSC()
**   4 = Secondary Oscillator (SOSC)
**   5 = Low Power RC Oscillator (LPRC)
**   6 = Fast RC oscillator with div. by 16
**   7 = Fast RC oscillator with div by n
** TDIG- uses (1)FRC+PLL and (2)Primary=EC
** WARNING: NO ERROR CHECKING ON mcuoscsel !
*/
//    __asm__ volatile ("mov #OSCCONH,W1");   // set up unlock sequence
    __asm__ volatile ("mov #OSCCON+1,W1");   // set up unlock sequence
    __asm__ volatile ("disi #6");           // Disable interrupts
    __asm__ volatile ("mov #0x78,W2");      //
    __asm__ volatile ("mov #0x9A,W3");
    __asm__ volatile ("mov.b W2,[W1]");
    __asm__ volatile ("mov.b W3,[W1]");
    __asm__ volatile ("mov.b W0,[W1]");

    __asm__ volatile ("mov #0x01,W0");    // 0x01 = Switch Oscillators
    //__asm__ volatile ("mov #OSCCONL,W1");   // set up unlock sequence
    __asm__ volatile ("mov #OSCCON,W1");   // set up unlock sequence
    __asm__ volatile ("disi #6");           // Disable interrupts
    __asm__ volatile ("mov #0x46,W2");      //
    __asm__ volatile ("mov #0x57,W3");
    __asm__ volatile ("mov.b W2,[W1]");
    __asm__ volatile ("mov.b W3,[W1]");
    __asm__ volatile ("mov.b W0,[W1]");
    while (OSCCONbits.OSWEN != 0) {}    // wait for switch to happen
}
// WB-11H end

void spin(count) {
	int i, j;
	j=count + 1;
	do {
		for (i=0xFFFF; i!=0; --i){}	// spin loop
	} while (--j != 0);
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


void ecan1Init(unsigned int board_id) {
/* Initialize ECAN #1  and put board_id into mask / filter */
/* Request Configuration Mode */
    C1CTRL1bits.REQOP=4;                // Request configuration mode
    while(C1CTRL1bits.OPMODE!=4);       // Wait for configuration mode active

/* FCAN is selected to be FCY
** FCAN = FCY = 20MHz */
    C1CTRL1bits.CANCKS = 0x1;           // FCAN = FCY == 20MHz depends on board and PLL
/*
Bit Time = (Sync Segment (1*TQ) +  Propagation Delay (3*TQ) +
 Phase Segment 1 (3*TQ) + Phase Segment 2 (3TQ) ) = 10*TQ = NTQ
 Baud Prescaler CiCFG1<BRP>  = (FCAN /(2�NTQ�FBAUD)) � 1
 BRP = (20MHz / 2*10*1MBaud))-1 = 0
*/
	/* Baud Rate Prescaler */
	C1CFG1bits.BRP = CAN1_BRP;

	/* Synchronization Jump Width set to SJW TQ */
	C1CFG1bits.SJW = CAN1_SJW;

	/* Propagation Segment time is PRSEG TQ */
	C1CFG2bits.PRSEG = CAN1_PRSEG;

	/* Phase Segment 1 time is SEG1PH TQ */
    C1CFG2bits.SEG1PH = CAN1_SEG1PH;

	/* Phase Segment 2 time is set to be programmable */
	C1CFG2bits.SEG2PHTS = CAN1_SEG2PHTS;
	/* Phase Segment 2 time is SEG2PH TQ */
	C1CFG2bits.SEG2PH = CAN1_SEG2PH;

	/* Bus line is sampled SAM times at the sample point */
	C1CFG2bits.SAM = CAN1_SAM;
/* -------------------------------*/

/* 4 CAN Message (FIFO) Buffers in DMA RAM (minimum number) */
    C1FCTRLbits.DMABS=0b000;            // Page 189

/*	Filter Configuration
    ecan1WriteRxAcptFilter(int n, long identifier, unsigned int exide,
        unsigned int bufPnt, unsigned int maskSel)
        n = 0 to 15 -> Filter number
        identifier -> SID <10:0> : EID <17:0>
        exide = 0 -> Match messages with standard identifier addresses
        exide = 1 -> Match messages with extended identifier addresses
        bufPnt = 0 to 14  -> RX Buffer 0 to 14
        bufPnt = 15 -> RX FIFO Buffer
        maskSel = 0 ->  Acceptance Mask 0 register contains mask
        maskSel = 1 ->  Acceptance Mask 1 register contains mask
        maskSel = 2 ->  Acceptance Mask 2 register contains mask
        maskSel = 3 ->  No Mask Selection
*/
    C1CTRL1bits.WIN = 1;                  // SFR maps to filter window

// Select Acceptance Filter Mask 0 for Acceptance Filter 0
    C1FMSKSEL1bits.F0MSK = 0x0;

// Configure Acceptance Filter Mask 0 register to
//      Mask board_id in SID<6:4> per HLP 3 protocol
    C1RXM0SIDbits.SID = 0x03F0; // 0b011 1brd 0000

// Configure Acceptance Filter 0 to match Standard Identifier
    C1RXF0SIDbits.SID = (C_TDIG>>2)|(board_id<<4);  // 0biii ibrd xxxx

// Configure Acceptance Filter for Standard Identifier
    C1RXM0SIDbits.MIDE = 0x1;
    C1RXM0SIDbits.EID = 0x0;

// Acceptance Filter 0 uses message buffer 1 to store message
    C1BUFPNT1bits.F0BP = 1;

// Filter 0 enabled
    C1FEN1bits.FLTEN0 = 0x1;

// Clear window bit to access ECAN control registers
    C1CTRL1bits.WIN = 0;

/* Enter Normal Mode */
    C1CTRL1bits.REQOP=0;                // Request normal mode
    while(C1CTRL1bits.OPMODE!=0);       // Wait for normal mode

/* ECAN transmit/receive message control */
    C1RXFUL1=0x0000;                    // mark RX Buffers 0..15 empty
    C1RXFUL2=0x0000;                    // mark RX Buffers 16..31 empty
    C1RXOVF1=0x0000;                    // clear RX Buffers 0..15 overflow
    C1RXOVF2=0x0000;                    // clear RX Buffers 16..31 overflow
	C1TR01CONbits.TXEN0=1;			/* ECAN1, Buffer 0 is a Transmit Buffer */
	C1TR01CONbits.TXEN1=0;			/* ECAN1, Buffer 1 is a Receive Buffer */
    C1TR01CONbits.TX0PRI=0b11;      /* Message Buffer 0 Priority Level highest */
    C1TR01CONbits.TX1PRI=0b11;      /* Message Buffer 1 Priority Level highest */
}


/* DMA Initialization for ECAN1 Transmission */
void dma0Init(void){
/* Set up DMA for ECAN1 Transmit ----------------------------------------- */
     DMACS0=0;                          // Clear DMA collision flags

/* Continuous, no Ping-Pong, Normal, Full, Mem-to-Periph, Word, disabled */
     DMA0CON=0x2020;

/* Peripheral Address Register */
     DMA0PAD=0x0442;    /* ECAN 1 (C1TXD register) */

/* Transfers to do = DMA0CNT+1 */
 	 DMA0CNT=0x0007;

/* DMA IRQ 70. (ECAN1 Tx Data) select */
     DMA0REQ=0x0046;

/* point DMA0STA to start address of data-to-transmit buffer */
     //JS DMA0STA=  __builtin_dmaoffset(&ecan1msgBuf[0][0]);
     DMA0STA=  __builtin_dmaoffset(ecan1msgBuf); //JS

/* Enable DMA2 channel */
     DMA0CONbits.CHEN=1;
}
/* ----------------------------------------------------------------------- */


/* DMA Initialization for ECAN1 Reception */
void dma2Init(void){
/* Set up DMA for ECAN1 Receive  ----------------------------------------- */
     DMACS0=0;                          // Clear DMA collision flags

/* Continuous, no Ping-Pong, Normal, Full, Periph-to-Mem, Word, disabled */
     DMA2CON=0x0020;

/* Peripheral Address Register */
     DMA2PAD=0x0440;    /* ECAN 1 (C1RXD register) */

/* Transfers to do = DMA0CNT+1 */
 	 DMA2CNT=0x0007;

/* DMA IRQ 34. (ECAN1 Rx Data Ready) select */
	 DMA2REQ=0x0022;	/* ECAN 1 Receive */

/* point DMA2STA to start address of receive-data buffer */
     //JS DMA2STA= __builtin_dmaoffset(&ecan1msgBuf[1][0]);
     DMA2STA= __builtin_dmaoffset(ecan1msgBuf); //JS

/* Enable DMA2 channel */
     DMA2CONbits.CHEN=1;
}

// void send_CAN1_alert (unsigned int board_id, unsigned int extrabyte)
void send_CAN1_alert (unsigned int board_id)
{
/* Write an ALERT Message to ECAN1 Transmit Buffer
   Request Message Transmission			*/
/* ------------------------------------------------
Builds ECAN1 message ID into buffer[0] words [0..2]
 -------------------------------------------------- */
	unsigned long msg_id;
#if defined (SENDCAN)
    msg_id = (unsigned long)((board_id&0x7)<<6); // stick in board ID
    msg_id |= (C_TDIG | C_ALERT);    // reply constant part
    ecan1msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
    ecan1msgBuf[0][1] = 0;
    ecan1msgBuf[0][2] = 0;
/* ------------------------------------------------
** Builds ECAN1 payload Length and Data into buffer words [2..6]
** transmit length 4 bytes
** Data is constant FF 00 00 00
 -------------------------------------------------- */
    ecan1msgBuf[0][2] += 4;       // message length 4
    ecan1msgBuf[0][3] = 0x00FF;
//    ecan1msgBuf[0][3] = 0b1111000010010100; // this was a bit-order test
//    ecan1msgBuf[0][4] = extrabyte;      // gets filled in by PLD read
    ecan1msgBuf[0][4] = 0;
    ecan1msgBuf[0][5] = 0;
    ecan1msgBuf[0][6] = 0;
/* Request the message be transmitted */
    C1TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit
#endif
}

void send_CAN1_write_reply (unsigned int board_id)
{
/* Write a Write_Reply Message to ECAN1 Transmit Buffer
   Request Message Transmission			*/
/* ------------------------------------------------
Builds ECAN1 message ID into buffer[0] words [0..2]
 -------------------------------------------------- */
	unsigned long msg_id;
#if defined (SENDCAN)
    msg_id = (unsigned long)((board_id&0x7)<<6); // stick in board ID
    msg_id |= (C_TDIG | C_WRITE_REPLY);    // reply constant part
    ecan1msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
    ecan1msgBuf[0][1] = 0;
    ecan1msgBuf[0][2] = 0;
/* ------------------------------------------------
** Builds ECAN1 payload Length and Data into buffer words [2..6]
** transmit length 4 bytes
** Data is constant FF 00 00 00
 -------------------------------------------------- */
    ecan1msgBuf[0][2] += 4;       // message length 4
    ecan1msgBuf[0][3] = 0;
    ecan1msgBuf[0][4] = 0;
    ecan1msgBuf[0][5] = 0;
    ecan1msgBuf[0][6] = 0;
/* Request the message be transmitted */
    C1TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit
#endif
}

void send_CAN1_diagnostic (unsigned int board_id, unsigned int bytes, unsigned char *bp)
{
/* Write a Diagnostic Message to ECAN1 Transmit Buffer
   Request Message Transmission			*/
/* ------------------------------------------------
Builds ECAN1 message ID into buffer[0] words [0..2]
 -------------------------------------------------- */
	unsigned long msg_id;
    unsigned char *cp, *wp;
	unsigned int i;
#if defined (SENDCAN)
    if (bytes <= 8) {
        while (C1TR01CONbits.TXREQ0==1) {};    // wait for transmit to complete
        msg_id = (unsigned long)((board_id&0x7)<<6); // stick in board ID
//        msg_id |= (C_TDIG | C_ALERT);    // reply constant part
        msg_id |= (C_TDIG);
        ecan1msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
        ecan1msgBuf[0][1] = 0;
        ecan1msgBuf[0][2] = 0;
/* ------------------------------------------------
** Builds ECAN1 payload Length and Data into buffer words [2..6]
 -------------------------------------------------- */
        ecan1msgBuf[0][2] += (bytes&0xF);       // message length
        cp = (unsigned char *)&ecan1msgBuf[0][3];
        if (bytes > 0) memcpy (cp, bp, (bytes&0xF));          // copy the message

/* Request the message be transmitted */
        C1TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit
    } // end if have proper length to send
#endif
}

void send_CAN1_message (unsigned int board_id, unsigned int message_type, unsigned int bytes, unsigned char *payload)
{
/* Write a Message to ECAN1 Transmit Buffer and Request Message Transmission
** Call with:
**      board_id = identifier of board to be stuffed into message header
**      message_id = type of message being sent gets or'd with board_id
**      bytes = number of payload bytes to send
**      *payload = pointer to payload buffer
**          payload[0] is usually the "subcommand" (HLP 3.0)
**          payload[1] is usually "status" (HLP 3.0)
*/
/* ------------------------------------------------
Builds ECAN1 message ID into buffer[0] words [0..2]
 -------------------------------------------------- */
	unsigned long msg_id;
    unsigned char *cp;
	unsigned int i;
#if defined (SENDCAN)
    i = bytes;
    if (i > 8) i=8;         // at most 8 bytes of payload
    while (C1TR01CONbits.TXREQ0==1) {};    // wait for transmit to complete
    msg_id = (unsigned long)((board_id&0x7)<<6); // stick in board ID
//        msg_id |= (C_TDIG | C_ALERT);    // reply constant part
    msg_id |= message_type;
    ecan1msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
    ecan1msgBuf[0][1] = 0;

/* ------------------------------------------------
** Builds ECAN1 payload Length and Data into buffer words [2..6]
 -------------------------------------------------- */
    ecan1msgBuf[0][2] = i;
    cp = (unsigned char *)&ecan1msgBuf[0][3];
    if (i > 0) {
       // message length up to 7 more
        memcpy (cp, payload, i);          // copy the message
    } // end if have additional bytes in message
/* Request the message be transmitted */
    C1TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit
#endif
}


void send_CAN1_data (unsigned int board_id, unsigned int bytes, unsigned char *bp)
{
/* Write a Data Message to ECAN1 Transmit Buffer
   Request Message Transmission			*/
/* ------------------------------------------------
Builds ECAN1 message ID into buffer[0] words [0..2]
 -------------------------------------------------- */
	unsigned long msg_id;
    unsigned char *cp, *wp;
	unsigned int i;
#if defined (SENDCAN)
    if (bytes <= 8) {
	    while (C1TR01CONbits.TXREQ0==1); 	// wait for transmit to complete
        msg_id = (unsigned long)((board_id&0x7)<<6); // stick in board ID
        msg_id |= (C_TDIG | C_DATA);    // reply constant part
//      msg_id |= (C_TDIG);
        ecan1msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
        ecan1msgBuf[0][1] = 0;
        ecan1msgBuf[0][2] = 0;
/* ------------------------------------------------
** Builds ECAN1 payload Length and Data into buffer words [2..6]
 -------------------------------------------------- */
        ecan1msgBuf[0][2] += (bytes&0xF);       // message length
		wp = bp;
		cp = (unsigned char *)&ecan1msgBuf[0][3];
		for (i=0; i<bytes; i++) {
			*cp++ = *wp++;
		}
//		ecan1msgBuf[0][3] = *wp++;
//		ecan1msgBuf[0][3] |= (*wp++)<<8;

/* Request the message be transmitted */
        C1TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit
    } // end if have proper length to send
#endif
}


/* -----------------12/8/2006 10:15AM----------------
How do these get hooked to hardware???
 ans: by magic name "C1Interrupt" and attribute
 --------------------------------------------------*/
void __attribute__((__interrupt__))_C1Interrupt(void)
{
    IFS2bits.C1IF = 0;        // clear interrupt flag ECAN1 Event
    if(C1INTFbits.TBIF) {     // If interrupt was from Tx Buffer
        C1INTFbits.TBIF = 0;            // Clear Tx Buffer Interrupt
    }
    if(C1INTFbits.RBIF) {     // If interrupt was from Rx Buffer
        C1INTFbits.RBIF = 0;            // Clear Rx Buffer Interrupt
	}
}


void send_CAN1_hptdcmismatch (unsigned int board_id, unsigned int tdcno, unsigned int index, unsigned char expectedbyte, unsigned char gotbyte)
{
/* Write a Message to ECAN1 Transmit Buffer
   Request Message Transmission			*/
/* ------------------------------------------------
Builds ECAN1 message ID into buffer[0] words [0..2]
 -------------------------------------------------- */
	unsigned long msg_id;
    unsigned char *cp, *wp;
	unsigned int i;
#if defined (SENDCAN)
    while (C1TR01CONbits.TXREQ0==1); 	// wait for transmit to complete
    msg_id = (unsigned long)((board_id&0x7)<<6); // stick in board ID
    msg_id |= (C_TDIG | C_ALERT );   // identify the message ALERT
    ecan1msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
    ecan1msgBuf[0][1] = 0;
    ecan1msgBuf[0][2] = 0;
/* ------------------------------------------------
** Builds ECAN1 payload Length and Data into buffer words [2..6]
 -------------------------------------------------- */
    ecan1msgBuf[0][2] += 6;       // message length
    ecan1msgBuf[0][3] = ((unsigned char)tdcno)<<8 | 0x11;
    ecan1msgBuf[0][4] = (unsigned)index;
    ecan1msgBuf[0][5] = (((unsigned char)expectedbyte)<<8) | (unsigned char)gotbyte;

/* Request the message be transmitted */
    C1TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit
#endif
}


unsigned long get_MCU_pm (UWord16, UWord16);

void read_MCU_pm (unsigned char *buf, unsigned long addrs){
/* Read from MCU program memory address "addrs"
** and return value to "buf" buffer array of chars
** Uses W0, W1, and TBLPAG
*/
    unsigned long retval;
    retval = get_MCU_pm ((unsigned)(addrs>>16), (unsigned)(addrs&0xFFFF));
//    retval = 0x030201L;
    *buf = retval & 0xFF;   // LSByte
    retval>>= 8;
    *(buf+1) = retval & 0xFF; // 2nd Byte
    retval>>= 8;
    *(buf+2) = retval & 0xFF; // 3rd Byte
    retval>>= 8;
    *(buf+3) = retval & 0xFF;  // MSByte
}

unsigned long get_MCU_pm (UWord16 addrh,UWord16 addrl){
    unsigned long temp;
    TBLPAG = addrh;
    __asm__ volatile ("tblrdl [W1],W0");
    __asm__ volatile ("tblrdh [W1],W1");
    return;
}


void put_MCU_pm (UWord16, UWord16, UWord16, UWord16);
void wrt_MCU_pm (void);

void write_MCU_pm (unsigned char *buf, unsigned long addrs){
/* Write to MCU program memory address "addrs"
** 4th byte is always zero.
*/
    UReg32 data;
    data.Val[0] = *(buf);
    data.Val[1] = *(buf+1);
    data.Val[2] = *(buf+2);
    data.Val[3] = 0;                // upper byte not real, must be zero
    put_MCU_pm ((unsigned)(addrs>>16), (unsigned)(addrs&0xFFFF), data.Word.HW, data.Word.LW);
    wrt_MCU_pm ();
}

void put_MCU_pm (UWord16 addrh,UWord16 addrl, UWord16 valh,UWord16 vall) {
/* Put data into table latch
*/
    TBLPAG = addrh;
    __asm__ volatile ("tblwtl W3,[W1]");    // write data latch L
    __asm__ volatile ("tblwth W2,[W1]");    // write data latch H
    return;
}

void wrt_MCU_pm (void) {
/* Execute the program memory write sequence
*/
// Need to set interrupt level really high / lock out interrupts
    int save_SR;            //
    NVMCON = 0x4003;        // Operation is Memory Write Word
    save_SR = SR;           // Save the status register
    SR |= 0xE0;             // Raise priority to lock out  interrupts
    NVMKEY = 0x55;          // Unlock 1
    NVMKEY = 0xAA;          // Unlock 2
    NVMCONbits.WR = 1;          // Set the "Write" bit
    __asm__ volatile ("nop");   // required NOPs for timing
    __asm__ volatile ("nop");   // required NOPs for timing
    while (NVMCONbits.WR) {}    // Spin until done
    SR = save_SR;           // restore the saved status register
}

void erase_MCU_pm (unsigned long addrs) {
/* Execute the program memory page-erase sequence
*/
    put_MCU_pm ((unsigned)(addrs>>16), (unsigned)(addrs&0xFFFF), 0, 0);

// Need to set interrupt level really high / lock out interrupts
    int save_SR;            //
    NVMCON = 0x4042;        // Operation is Memory Erase Page
    save_SR = SR;           // Save the status register
    SR |= 0xE0;             // Raise priority to lock out  interrupts
    NVMKEY = 0x55;          // Unlock 1
    NVMKEY = 0xAA;          // Unlock 2
    NVMCONbits.WR = 1;          // Set the "Write" bit
    __asm__ volatile ("nop");   // required NOPs for timing
    __asm__ volatile ("nop");   // required NOPs for timing
    while (NVMCONbits.WR) {}    // Spin until done
    SR = save_SR;           // restore the saved status register
}

#ifndef DOWNLOAD_CODE
void __attribute__((__noreturn__, __weak__, __noload__, address(MCU2ADDRESS) ))
jumpto(void) {
/* this routine is really just a placeholder for the start address in the
 * MCU2 code image.  If there is no image downloaded yet, eventually the MCU
 * will just restart into the first image.
 * During compile-and-link, a warning message will be issued.  That is OK    */

    for ( ; ; )
     __asm__ volatile ("nop");
//    __asm__ volatile ("goto 0x4000");

}
#endif
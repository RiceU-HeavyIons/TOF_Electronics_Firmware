// $Id: TCPU-C.C,v 1.5 2008-06-19 21:45:51 jschamba Exp $

// TCPU-C.c
// Version for build TCPU-C_2C
// main program for PIC24HJ256GP610 as used on TCPU-B rev 0 board
// Program # 2C -
//      09-May-08, W. Burton
//          Renumbered versions per Jo Schambach request.
//          Made sending of 2-word data messages conditional on definition of SENDTWO
// Program # 2B -
//      08-May-08, W. Burton
//          Rework CAN2<==>CAN1 transfers to avoid hang-up; fix spurious retransmit of CAN2 messages to CAN1.
// Program # 2A -
//      14-Mar-08, W. Burton
//          More rework of clock initialization
//      29-Feb-08, W. Burton
//          For TCPU-C board.
//          JU2 pins 1-2 jumpered select EXTERNAL clock.
//          JU2 pins 3-4 jumpered select PLL clock processing.
// Program # 1l - (note lower case L)
//      27-28 Feb-08, W. Burton
//          SIGNIFICANT REWORK OF CLOCK INITIALIZATION.
//          Changed for TCPU-C.  New Clock and PLL control bits.
// Program # 1L -
//      08-Feb-08, W. Burton
//          Fix reply length for JSW and ECSR commands
//      16-Oct-07, W. Burton
//          Mask board position to 0..31 and implement C_BOARD board ID.
//          Program version ID is still 0x01 0x4C (version 1L)
//          Changes marked with // WB-1L
//      15-Oct-07, W. Burton
//          If the second (download) image is running, we do not want to download over it.
//          Clock selection and control is migrated-in from TDIG-F_ver11H.c
//          CPU starts up using internal oscillator; then examines jumpers and changes to Board or Tray external Oscillator.
//          CLOCK JUMPER (PINS 1-2) IS EXAMINED ONLY ONCE AT START-UP TO DETERMINE CLOCK SOURCE!
//          For DOWNLOADED code (second image), the OSCILLATOR IS NOT CHANGED
//          Program version ID is 0x01 0x4C (version 1L)
//          Changes marked with // WB-1L
//      11-Oct-07, W. Burton
//          Program version ID is 0x01 0x4C (version 1L)
//          Changes marked with // WB-1L
//          Made the call to initialize_osc() conditional on definition of DOWNLOAD_CODE;
//              initialize_osc() is not called for download version.
//          PortF is initialized to all inputs so PLD_SERIN and PLD_SEROUT are "safe".
//          Add timeouts in case CAN2 is not connected.
//          Set CPU priority=0 and select interrupt vector depending on DOWNLOAD_CODE
//             "normal" code = standard interrupts; "DOWNLOAD_CODE" = alternate interrupts.
//          "Download" code has id 0x81 0x4C (81L)
// Program # 1K -
//      10-Oct-07, J. Schambach
//          Program version ID is 01 0x4B (version 1K)
//			Fixed DMA initialization
//			Use correct buffers in received messages according to filter initialization
//			Mask off length field correctly in received CAN messages
//			All changes are marked by "//JS"
// Program # 1J -
//      27 thru 29-Sep-07, W. Burton
//          Program version ID is 01 0x4A (version 1J)
//          CAN1 to/from CAN2 routing.
//          "Standard" Messages from either CAN1 or CAN2 addressed to this board "standard" get processed.
//          Detect Standard-Address upstream-pointing (bit0 set) TDIG messages coming in on CAN1
//              (they go into buffer[3]), get the TCPU ID put on in the extended address bits, then sent
//              out on CANBus #2.
//          Detect Extended-Address downtream-pointing (bit0 clear) messages coming in on CAN2
//              (they go into buffer[3]), Take the TCPU ID off; put the standard address bits,
//              then send message to CANBus #1.
// Program # 1H -
//      25-Sep-07, W. Burton
//          Make MCU Reset and Reprogramming work properly.
//          Update version ID to 0x1 0x48 (version 1H)
//          Fix CAN1 and CAN2 Alert messages
//          Fix CAN1 and CAN2 board ID numbers to allow [0..31].
// Program # 1G -
//      02-Jul-2007, W. Burton
//          FPGA firmware Identifier added to C_RS_FIRMWID
//      29-Jun-2007, W. Burton
//          Update Include file processing.
//      20-Jun-2007, W. Burton
//          Bring in FPGA Reconfiguration timeout.
//          Speed up download/reprogramming.
// Program # 1F -
//      31-May-2007, W. Burton
//          MCU RESET implemented.
//      23-May-2007, W. Burton
//          Read_Temperature and part of Read Status implemented.
// Program # 1E -
//      23-May-2007, W. Burton
//          Change FPGA initialization to do the latest reset sequence in init_regs_FPGA() in file TCPU-B_MCU_PLD.C and .H
//          "TDIG-FPGA MCU interface registers.xls" dated 4/17/2007
//          Sequence is a) Initialize FPGA b) toggle PLD_RESETB using reset_FPGA(); c) load registers[0..3] with zero;
//          d) Toggle TDC HARDWARE RESET bit in CONFIG_2 register.
//          Update to correct FIRMWARE ID
// Program # 1D -
//      23-May-2007, W. Burton
//          Change to NOT terminate CAN1 and CAN2 for TCPU test.
//          Confirmation of change:
//              Before - the voltage across open pins of JU1 was approx. 0.0 volts (terminator switch closed).
//              After - the voltage across open pins of JU1 was approx 1.0 volts (terminator switch open).
//                  Without a hardware jumper across JU1, there were BUSHEAVY errors reported by PcanView.
//                  With a hardware jumper across JU1, there were no BUSHEAVY errors reported by PcanView.
// Program # 1C -
//      22-May-2007, W. Burton
//          Review and correct MCU-FPGA configuration and initialization.
//          Added reset of state-machine through Reg 1 in module init_regs()
//      17-May-2007, L. Bridges (WDB)
//          This code was placed on WIKI for distribution.
//      14-May-2007, W. Burton
//          Changed CANBus parameters to allow long-cable to operate
//          while still allowing "short" cables to work.
//      12-May-2007, W. Burton
//          FIRMWARE_ID added.
//          Additional CAN messages implemented Firmware ID, LEDs.
//      11-May-2007, W. Burton
//          Rework FPGA Initialization/reset sequences:
//              Power On == Configure from EE1, Issue PLD_RESETB, Load registers w/defaults.
//              Reconfiguration == Configure from EEx, Issue PLD_RESETB, Load registers w/defaults.
//              CANBus PLD_RESET 0x2 5 0C 69 96 A5 5A command == Issue PLD_RESETB, Load registers w/defaults.
//              Serial Statemachine Reset via CANBus 0x2 3 0E 09 00 == write to FPGA register 9
//              MCU FIFO Reset via CANBus 0x2 3 0E 10 00 == write to FPGA register 10
//          Implement FPGA Reset and FPGA Write Register messages.
//          Implement READ and WRITE messages for status.
// Program # 1B -
//      09-May-07, W. Burton
//          Conditional code (#define DOREGTEST) writes FPGA Reg 0 with defined value and
//          reads it back.  It also reads Register 7 (the ID register)
//      02-May-07, W. Burton
//          Conditional Code (#define DODATATEST)
//              Read data from FPGA (same way as TDIG), send over CAN bus
// Program # 1A -
//      27 thru 30-Apr-2007, W. Burton
//          Write Position switch value to FPGA at startup and when it changes.
//          Make sure MCU_PLD (fpga) registers are initialized.
//      23-Apr-2007, W. Burton
//          Added specific reset/calibration of PLL and
//          copy PLL_LOL status to LED D5.
//      02-Apr-2007 based on TDIG-D program 11A.
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
//    #define DOREGTEST 0x5A      // Do the register test
                                // This overrides DODATATEST

//JS: Uncomment this for version to be downloaded via CANbus
//JS    #define DOWNLOAD_CODE

// Define the FIRMWARE ID
    #define FIRMWARE_ID_0 'D'   // version 2D = 0x44
// WB-1L make downloaded version have different ID
#ifdef DOWNLOAD_CODE
    #define FIRMWARE_ID_1 0x82  // WB version 2 download
#else
    #define FIRMWARE_ID_1 0x2   // WB version 2
#endif
// WB-11H end

// Define implementation on the TCPU board (I/O ports, etc)
    #define CONFIG_CPU 1        // Make TCPU-C_Board.h define the CPU options
    #include "TCPU-C_Board.h"

//  #define RC15_TOGGLE 1       // RC15/OSC2 is Clock divided by 2 Output

// Define the library includes
    #include "ecan.h"           // Include for E-CAN peripheral
    #include "i2c.h"            // Include for I2C peripheral library
    #include "stddef.h"         // Standard definitions
    #include "string.h"         // Definitions for string functions

// Define our routine includes
	#include "TCPU-C_I2C.h"		// Include prototypes for our I2C routines



    #include "TCPU-C_SPI.h"     // Include for our SPI (EEPROM) macros

    #include "TCPU-C_MCU_PLD.h" // Include for our parallel interface to FPGA

/* DEFINE the HLP_version_3 Packet IDs */
    #include "TCPU-C_CAN_HLP3.h"

// Spin Counter
	#define SPINLIMIT 20

// Special Test Configurations
    #define DODATATEST 1

/* ECAN1 stuff */
	#define NBR_ECAN_BUFFERS 4

    typedef unsigned int ECAN1MSGBUF [NBR_ECAN_BUFFERS][8];
    ECAN1MSGBUF  ecan1msgBuf __attribute__((space(dma),aligned(NBR_ECAN_BUFFERS*16)));  // Buffer to TRANSMIT

    void ecan1Init(unsigned int board_id);
    void dma0Init(void);
    void dma2Init(void);

/* ECAN2 stuff */

    typedef unsigned int ECAN2MSGBUF [NBR_ECAN_BUFFERS][8];
    ECAN2MSGBUF  ecan2msgBuf __attribute__((space(dma),aligned(NBR_ECAN_BUFFERS*16)));  // Buffer to TRANSMIT

    void ecan2Init(unsigned int board_id);
    void dma1Init(void);
    void dma3Init(void);


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
// WB-1L
// void Initialize_OSC();                  // initialize the CPU oscillator
int Initialize_OSC(unsigned int oscsel);              // initialize the CPU oscillator
void Switch_OSC(unsigned int mcuoscsel);               // Switch CPU oscillator (low level)
// WB-1L end
void spin(int cycle);		// delay
void clearIntrflags(void);	// Clear interrupt flags

/* CAN message routines     */
// Messgaes common to both busses
   void send_CAN_alerts (unsigned int board_id);

// CANBus #1 ("tray")
// Send a CAN message - fills in     board id               message type  number of payload bytes    &payload[0]
void send_CAN1_message (unsigned int board_id, unsigned int message_type, unsigned int bytes, unsigned char *bp);
void send_CAN1_data (unsigned int board_id, unsigned int bytes, unsigned char *bp);

// CANBus #2 ("System")
void send_CAN2_message (unsigned int board_id, unsigned int message_type, unsigned int bytes, unsigned char *bp);
void send_CAN2_message_extended (unsigned int ext_id, unsigned int std_id, unsigned int bytes, unsigned char *bp);
void send_CAN2_data (unsigned int board_id, unsigned int bytes, unsigned char *bp);

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

unsigned char readback_buffer[2048];        // readback general buffer

// Large-Block Download Buffer
#define BLOCK_BUFFERSIZE 256                // NEVER MAKE THIS LESS THAN 8
unsigned char block_buffer [BLOCK_BUFFERSIZE];
unsigned int block_bytecount;
unsigned int block_status;
unsigned long int block_checksum;
unsigned long int eeprom_address;

// Current DAC setting
// unsigned int current_dac;

// WB-1L CAN2 timeout
unsigned int CAN2timeout;

// Image of PLD control / configuration registers read-back
unsigned int pld_ident;
// unsigned int pld_config_0;
// unsigned int pld_config_1;
// unsigned int pld_config_2;
// unsigned int pld_config_3;

unsigned int board_posn = 0;    // Gets board-position from switch

//JS: TIMER STUFF *******************************************************
#ifndef DOWNLOAD_CODE
unsigned int timerExpired = 0;
#endif
//JS: END TIMER STUFF ***************************************************


main()
{
    unsigned long int laddrs, lwork2;
    unsigned long int fifovalue;
    unsigned long int expectedvalue;
    unsigned long int lwork;
	unsigned int i, j, k;
	unsigned int save_SR;
	unsigned int tglbit = 0x0;
	unsigned int switches = 0x0;
	unsigned int jumpers = 0x0;
    unsigned int oldjumpers = 0x0;  // saves previous jumper state
    unsigned int oldswitch = 0x0;   // saves previous value of position switch
	unsigned int buttoncount = 0x0;
	unsigned int tdcpowerbit = 0x0;
	unsigned int ledbits = NO_LEDS;
	unsigned int board_temp = 0;	// will get last-read board temperature word
    unsigned int replylength;       // will get length of reply message
    unsigned int rcvmsgtype = 0;    // will get received message type for dispatch
    unsigned int rcvmsglen = 0;     // will get received message length for dispatch
    unsigned int rcvmsgfrom = 0;    // source of message (CAN1 or CAN2)
	unsigned char bwork[10];
    unsigned char sendbuf[10], retbuf[10];
    unsigned char *wps;              // working pointer
    unsigned char *wpd;              // working pointer


//JS
#ifndef DOWNLOAD_CODE
// WB-1L
// This applies to first-image code, does not apply to second "download" image.
    Initialize_OSC(OSCSEL_FRCPLL);          // initialize the CPU oscillator to ON-CHIP

// be sure we are running from standard interrupt vector
    save_SR = INTCON2;
    save_SR &= 0x7FFF;  // clear the ALTIVT bit
    INTCON2 = save_SR;  // and restore it.
#endif
//JS end
// WB-1L
// Note that ALTIVT bit gets set just prior to starting the second image, but just to be sure
#ifdef DOWNLOAD_CODE
    INTCON2 |= 0x8000;      // This is the ALTIVT bit
#endif

// We will want to run at priority 0 mostly
    SR &= 0x011F;          // Lower CPU priority to allow interrupts
    CORCONbits.IPL3=0;     // Lower CPU priority to allow user interrupts
// WB-1L end

#if defined (RC15_IO) // RC15 will be I/O (in TCPU-C_Board.h)
	TRISC = 0x7FFF;		// make RC15 an output
#else
//  RC15/OSC2 is set up to output TCY clock on pin 40 = CLK_DIV2_OUT, TP1
#endif

/* 27-Feb-2008
** Initialize PORTD bits[0..3,4..9] pins [72, 76, 77, 78, 81, 82, 83, 84, 68, 69]
** for control/monitoring of PLL and EEPROM
*/
// Make D0 an output (pin 72 = PLL_RESET, initialize L)
// Make D1 an input  (pin 76 = PLL_LOS)
// Make D2 an input  (pin 77 = DH_ACTV)
// Make D3 an input  (pin 78 = CAL_ACTV)
// Make D4 an input  (pin 81 = MCU_EE_DATA)
// Make D5 an output (pin 82 = MCU_EE_DCLK, initialize L)
// Make D6 an output (pin 83 = MCU_EE_ASDO, initialize L)
// Make D7 an output (pin 84 = MCU_EE_NCS, initialize H)
// Make D8 an output (pin 68 = MCU_SEL_EE2, initialize L)
// Make D9 an output (pin 69 = MCU_CONFIG_PLD, initialize H)
    LATD  = (0xFFFF & MCU_EE_initial & MCU_PLL_initial); // Initial bits
    TRISD = (0xFFFF & MCU_EE_dirmask & MCU_PLL_dirmask); // I/O configuration

// WB-1L
/* Make sure port F is in a safe condition */
    LATF = PORTF_initial;
    TRISF = PORTF_dirmask;
// WB-1L end

/* Port G bits used for various control functions
** Pin Port.Bit Dir'n Initial Signal Name
**   1    G.15  Out     1     MCU_TEST
**  95    G.14  Out     1     PLD_RESETB
**  97    G.13  Out     0     TCPU-C No Connect
**  96    G.12  Out     1     PLD_DEVOE
**  14    G.9   Out     0     SEL_BYPASS (0=PLL Bypassed, 1=PLL used)
**  12    G.8   Out     1     MCU_SEL_LOCAL_CLK (0=Local, 1=External)
**  11    G.7   Out     1     MCU_EN_LOCAL_OSC (0=U25 disabled, 1=U25 enabled) must be enabled if G.8 is 0
**  10    G.6   Out     1     I2CA_RESETB
*/
    LATG = PORTG_initial;       // Initial settings port G (I2CA_RESETB must be Hi)
    TRISG = PORTG_dirmask;      // Directions port G
/* 23-May-2007, NO termination on CAN1 or CAN2 */
/* selected by configuration in tcpu-b_board.h */
//    MCU_SEL_TERM1 = 1;          // Turn on CAN1 Terminator
//    MCU_SEL_TERM2 = 1;          // Turn on CAN2 Terminator

/* Initialize Port B bits for output */
    AD1PCFGH = 0xFFFF;      // Disable Analog function from B-Port
    AD1PCFGL = 0xFFFF;      // Disable Analog function from B-Port
    AD2PCFGL = 0xFFFF;      // Disable Analog function from B-Port

    LATB = 0x0000;          // All zeroes
    TRISB = 0xDFE0;         // Set directions

// Initialize CAN2 timeout flag
    CAN2timeout = 0;        // no timeout yet (global flag)

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

// Initialize and Read Board Position Switches
	Initialize_Switches();  // I2C == write22 = 00 9F etc.
// Get board-position switch
	oldswitch = Read_MCP23008(SWCH_ADDR, MCP23008_GPIO);
    // posn #  =  (SW5 * 10) + SW4  == switches are BCD decimal
    board_posn = (((oldswitch&0xF0)>>4)*10) + (oldswitch & 0xF);
    board_posn &= 0x1F;     // WB-1L mask board position to 0..31

// Initialize and Turn Off LEDs
    Initialize_LEDS();

// Initialize and Read Serial Number
//	#if defined (SN_ADDR) // if address defined, it exists
//    	Write_device_I2C1 (SN_ADDR, CM00_CTRL, CM00_CTRL_I2C);     // set I2C mode
//		for (j=0; j<8; j++) {
//			sn[j] = (unsigned char)Read_MCP23008(SN_ADDR,j);		// go get sn byte
//    #else
//        for (j=0; j<8; j++) sn[j] = j;
//    #endif
//          Briefly display each byte of Serial Number on LEDs
//            Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, (unsigned int)(sn[j]^0xFF)); //
//			spin (SPINLIMIT);
//		}

// Initialize and Read Temperature Monitor
	#if defined (TMPR_ADDR)
		Initialize_Temp (MCP9801_CFGR_RES12);	// configure 12 bit resolution
		board_temp = Read_Temp ();
		j = board_temp ^ 0xFFFF;		// flip bits for LED
    	Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, (j&0xFF)); // display LSByte
		spin(SPINLIMIT);
    	Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, ((j>>8)&0xFF));
		spin(SPINLIMIT);
	#endif // defined (TMPR_ADDR)


/* -------------------------------------------------------------------------------------------------------------- */
    jumpers = Read_MCP23008(ECSR_ADDR, MCP23008_GPIO) & JUMPER_MASK;
    oldjumpers = jumpers;           // remember state for next time

/* -----------------12/9/2006 11:39AM----------------
** Jumper JU2.1-2 now controls MCU_SEL_LOCAL_OSC
** and MCU_EN_LOCAL_OSC
** Installing the jumper forces low on MCU_...OSC
** disabling it.
 --------------------------------------------------*/
// WB-1L - Osc selection
// For now, External Osc must already be running
    i = 0;
    if ( (jumpers & JUMPER_3_4) == JUMPER_3_4) {  // See if jumper IN
        i = PLL_SELECT;
    } // end if jumper 3-4 is in
    if ( (jumpers & JUMPER_1_2) == JUMPER_1_2) {  // See if jumper IN
//        MCU_SEL_LOCAL_OSC = 0;      // turns off sel-local-osc
//        MCU_EN_LOCAL_OSC  = 0;      // turns off en-local-osc
        Initialize_OSC ((OSCSEL_TRAY|i));  //  Use TRAY clock W or W/O PLL
    } else {                        // Jumper OUT (use local osc)
//        MCU_SEL_LOCAL_OSC = 1;      // turns on sel-local-osc
//        MCU_EN_LOCAL_OSC  = 1;      // turns on en-local-osc
        Initialize_OSC ((OSCSEL_BOARD|i));       //  Use BOARD clock W or W/O PLL
    }                               // end else turn ON local osc

// Clear all interrupts
	clearIntrflags();

// Make sure FPGA has configured and reset it
//    waitfor_FPGA();
//    reset_FPGA();
// Put board-position switch into CONFIG_12_W of FPGA and initialize 0..3 to zero
    init_regs_FPGA(board_posn);

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

/* -------------------------------------------------------------------------------------------------------------- */
/* ECAN2 Initialization
   Configure DMA Channel 1 for ECAN2 Transmit (buffers[0] )
   Configure DMA Channel 3 for ECAN2 Receive  (buffers[1] )
*/
    ecan2Init(board_posn);
    dma1Init();                     // defined in ECAN1Config.c (copied here)
    dma3Init();                     // defined in ECAN1Config.c (copied here)

/* Enable ECAN2 Interrupt */
    IEC3bits.C2IE = 1;                  // Interrupt Enable ints from ECAN2
    C2INTEbits.TBIE = 1;                // ECAN2 Transmit Buffer Interrupt Enable
    C2INTEbits.RBIE = 1;                // ECAN2 Receive  Buffer Interrupt Enable

/* -------------------------------------------------------------------------------------------------------------- */
/* Initialize large-block download */
    block_status = BLOCK_NOTSTARTED;    // no block transfer started yet
    block_bytecount = 0;
    block_checksum = 0L;

/* Use SPI to access EEPROM #2 and read device ID
*/
// We disable this for now so we can do FPGA Write/Read testing
#if defined (DOEEPROM2)
// Set port directions (Din IN, Clk OUT, Dout OUT, nCS OUT, EE2 Select OUT)
// This was done back at the beginning (after Initialize_OSC())
    for (i=0; i<10; i++) retbuf[i] = 0x0;
// Select EE #2
    sel_EE2;
// Lower CS
    clr_EENCS;
// Lower CLK
  clr_EECLK
// {Put Instruction out LS-bit first, toggle clock} x8
    j = EE_AL_RDID;
    for (i=0; i<8; i++) {
        MCU_EE_ASDO = (j & 0x1);  // put out the instruction bit
        j >>= 1;  // move to next bit
        str_EECLK;      // strobe the clock
    } // end loop over instruction bits
    for (i=0; i<24; i++) str_EECLK;      // DUMMY BYTES for ALTERA
// Read MSbit of Din (MSbit of Mfr ID)
    for (k=0; k<3; k++) {           // we get 3 copies from ALTERA
        i = 8;
        j = 0;
        do {
            j <<= 1;
            j |= MCU_EE_DATA;  // Read the data bit and put away
            str_EECLK;  // strobe the clock
        } while (--i != 0); // end loop over reply bits
        retbuf[k] = (unsigned char)j;
    } // end loop over reply bytes
// Raise CS
    set_EENCS;
    sel_EE1;            // de-select EEPROM #2
// now send a diagnostic message over CAN
//  send_CAN1_message (board_posn, (C_BOARD | C_DIAGNOSTIC), 3, (unsigned char *)&retbuf);
#endif // end if (DOEEPROM2)

/* -------------------------------------------------------------------------------------------------------------- */
    jumpers = Read_MCP23008(ECSR_ADDR, MCP23008_GPIO) & JUMPER_MASK;

// WB-1L
// CLOCK SWITCHING IS NOT DYNAMIC - Clock Jumper is read once at start-up and not examined thereafter.
/* -----------------12/9/2006 11:39AM----------------
** Jumper JU2.1-2 now controls MCU_SEL_LOCAL_OSC
** and MCU_EN_LOCAL_OSC
** Installing the jumper forces low on MCU_...OSC
** disabling it.
 --------------------------------------------------*/
//    if ( (jumpers & JUMPER_1_2) == JUMPER_1_2) { // See if jumper IN 1-2
//                                // Jumper INSTALLED inhibits local osc.
//        MCU_SEL_LOCAL_OSC = 0;          // turns off sel-local-osc
//        MCU_EN_LOCAL_OSC = 0;          // turns off en-local-osc
//        // Make sure PLL is initialized if not using local osc.
//        PLL_RESET = 0;          // Make sure it is Low
//        PLL_RESET = 1;          // Make it High
//        spin(0);                // Spin a while (1 uSec minimum, this is 20 mSec)
//        PLL_RESET = 0;          // Make it Low (enables self cal)
//        spin(0);                // Spin a while (2 mSec minimum, this is 20 mSec)
//    } else {                        // Jumper OUT (use local osc)
//        MCU_SEL_LOCAL_OSC = 1;          // turns on sel-local-osc
//        MCU_EN_LOCAL_OSC = 1;          // turns on en-local-osc
//    }
// WB-1L end

/* Send an "Alert" message to both CANBus to say we are on-line */
    send_CAN_alerts (board_posn);

//JS: TIMER STUFF **********************************************************
#ifndef DOWNLOAD_CODE
/* setup timer: Combine Timer 2 and 3 for a 32 bit timer;
	combined timer is controlled by Timer 2 control bits,
	but fires Timer 3 interrupt  */
	timerExpired = 0;		// global flag to indicate expired timer 1
	T2CON = 0; 				// clear Timer 2 control register
	T3CON = 0; 				// clear Timer 3 control register
	T2CONbits.TCKPS = 0b11; // Set prescale to 1:256
	TMR2 = 0;				// clear Timer 2 timer register
	TMR3 = 0;				// clear Timer 3 timer register
	PR2 = 0xffff;			// load period register (low 16 bits)
	PR3 = 0x0004;			// load period register (high 16 bits)
	IPC2bits.T3IP0 = 1;		// Timer 3 Interrupt priority = 1
	IPC2bits.T3IP1 = 0;
	IPC2bits.T3IP2 = 0;
	IFS0bits.T3IF = 0;		// clear interrupt status flag Timer 3
	IEC0bits.T3IE = 1;		// enable Timer 3 interrupt

	T2CONbits.T32 = 1; 		// Enable 32-bit timer operation
	T2CONbits.TON = 1; 		// Turn on Timer 2
#endif
//JS: END TIMER STUFF *********************************************************
	
	

/* Look for Have-a-Message
*/

    //JS: Here is an explanation of what the different received words mean:
	/*
    Standard Message Format:
    Word0 : 0bUUUx xxxx xxxx xxxx
                 |____________|||
                     SID10:0   SRR IDE(bit 0)
    Word1 : 0bUUUU xxxx xxxx xxxx
                   |____________|
                      EID17:6
    Word2 : 0bxxxx xxx0 UUU0 xxxx
              |_____||       |__|
			  EID5:0 RTR   	  DLC
    word3-word6: data bytes
	word7: filter hit code bits

	Substitute Remote Request Bit
	SRR->	"0"	 Normal Message
			"1"  Message will request remote transmission

	Extended  Identifier Bit
	IDE-> 	"0"  Message will transmit standard identifier
	   		"1"  Message will transmit extended identifier

	Remote Transmission Request Bit
	RTR-> 	"0"  Message transmitted is a normal message
			"1"  Message transmitted is a remote message
	*/
    do {                            // Do Forever
        rcvmsgfrom = 0;
        if ( C1RXFUL1bits.RXFUL2 ) {                // Receive TDIG message on Tray CAN#1 */
                                                    // Add Extended Address and transmit on CAN#2
            i = 0xFFF;                              // WB-1L add timeout
//            while (C2TR01CONbits.TXREQ0==1) {};     // wait for transmit CAN#2 to complete
            while ((C2TR01CONbits.TXREQ0==1)&&(i!= 0)) {--i;};     // wait for transmit CAN#2 to complete or time out
                                                    // copy the message from CAN#1 Receive buffer #2 to
                                                    // CAN#2 transmit buffer#0
            //JS for (i=0; i<8; i++) ecan2msgBuf[0][i] = ecan1msgBuf[3][i];
            for (i=0; i<8; i++) ecan2msgBuf[0][i] = ecan1msgBuf[2][i]; //JS
            C1RXFUL1bits.RXFUL2 = 0;        // CAN#1 Receive Buffer 2 OK to re-use
                                            // Mark CAN#2 Buffer #0 for extended ID
            ecan2msgBuf[0][0] |= C_EXT_ID_BIT;    // extended ID =1, no remote xmit
            ecan2msgBuf[0][1]  = 0;             // WB-1L this will need to change if C_BOARD is redefined
            ecan2msgBuf[0][2] |= (((C_BOARD>>6)|board_posn)<<10);   // extended ID<5..0> gets TCPU board_posn
            C2TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit on CAN#2

        } else if ( C2RXFUL1bits.RXFUL2 ) {         // Receive TCPU message on CAN#2 */
            if ( (ecan2msgBuf[2][0] & C_EXT_ID_BIT) != 0) {  // It must be an "extended" message in order to be retransmitted
                i = 0xFFF;                      // WB-1M add timeout
                while ((C1TR01CONbits.TXREQ0==1)&&(i!=0)) {--i;};     // wait for transmit CAN#1 to complete or time out
//                while (C1TR01CONbits.TXREQ0==1) {};     // wait for transmit CAN#1 to complete
                                                        // copy the message from CAN#2 Receive buffer #2 to
                                                        // CAN#1 transmit buffer#0
            //JS for (i=0; i<8; i++) ecan1msgBuf[0][i] = ecan2msgBuf[3][i];
                for (i=0; i<8; i++) ecan1msgBuf[0][i] = ecan2msgBuf[2][i]; //JS
                                                // Mark CAN#1 Buffer #0 for standard ID
                                                // Strip off extended ID bits etc.
                ecan1msgBuf[0][0] &= 0x1FFC;    // extended ID =0, no remote xmit
                ecan1msgBuf[0][1] = 0;          // clear extended ID
                ecan1msgBuf[0][2] &= 0x000F;    // clear all but length
                C1TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit
            } // end if it was an extended message
            C2RXFUL1bits.RXFUL2 = 0;        // CAN#2 Receive Buffer 2 OK to re-use
        } else if ( C2RXFUL1bits.RXFUL1 ) {     //  Receive message on CAN#2
            rcvmsgfrom = 2;                     // source of message is CAN#2
            rcvmsgtype = ecan2msgBuf[1][0];     // Save message type code
            //JS rcvmsglen= ecan2msgBuf[1][2];  // Save message length
            rcvmsglen= ecan2msgBuf[1][2] & 0x000F;   // Save message length //JS
            wps = (unsigned char *)&ecan2msgBuf[1][3];  // pointer to source buffer (message data)
        } else if ( C1RXFUL1bits.RXFUL1 ) {     // Receive standard msg via CAN#1
            rcvmsgfrom = 1;                     // source of message is CAN#1
            rcvmsgtype = ecan1msgBuf[1][0];     // Save message type code
            //JS rcvmsglen= ecan1msgBuf[1][2];  // Save message length
            rcvmsglen= ecan1msgBuf[1][2] & 0x000F;   // Save message length
            wps = (unsigned char *)&ecan1msgBuf[1][3];  // pointer to source buffer
        } // end checking for messages
// Dispatch to Message Code handlers.
// Note that Function Code symbolics are defined already shifted.
        if (rcvmsgfrom != 0) {
            retbuf[0] = (*wps);  // pre-fill reply with "subcommand" payload[0]
            retbuf[1] = C_STATUS_OK;            // Assume all is well (status OK)
            switch ((rcvmsgtype & C_CODE_MASK)) {  // Major switch on WRITE or READ COMMAND
                case C_WRITE:  // Process a "Write"
                               // now decode the "Write-To" Subcommand from inside message
                    replylength = 2;                    // Assume 2 byte reply
                    switch ((*wps++)&0xFF) {       // look at and dispatch SUB-command, point to remainder of message

                        case C_WS_LED:              // Write to LED register
                            Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, ~(*wps));
                            break;  // end case C_WS_LED

                        case C_WS_FPGARESET:        // Issue an FPGA Reset
                            memcpy ((unsigned char *)&lwork, wps, 4);   // copy 4 bytes from incoming message
                            // Confirm length is correct and constant agrees
                            if ((rcvmsglen == FPGARESET_LEN) && (lwork == FPGARESET_CONST)) {
                                reset_FPGA();       // do the reset if all is OK
                                init_regs_FPGA(board_posn);
                            } else retbuf[1] = C_STATUS_INVALID;    // else mark invalid
                            break;  // end case C_WS_FPGARESET

                        case C_WS_FPGAREG:          // Write to FPGA Register(s)
                            i = 3;
                            while (i <= rcvmsglen) { // for length of message (1, 2, or 3 reg,val pairs)
                                j = *wps++;
                                write_FPGA (j, (*wps++));
                                i+=2;
                            } // end while have something in message (1, 2, or 3 reg,val pairs)
                            break;  // end case C_WS_FPGAREG

                        case C_WS_BLOCKSTART:       // Start Block Download
                            block_status = BLOCK_INPROGRESS;
                            block_bytecount = 0;    // clear block buffer counter
                            block_checksum = 0L;    // clear block buffer checksum
                            wpd = (unsigned char *)&block_buffer[0];    // point destination to buffer
                            // Copy any data from message.  We don't need to check buffer length since it was just set "empty"
                            for (i=1; i<rcvmsglen; i++) {   // copy any remaining bytes
                                    *wpd++ = *wps;        // copy byte into buffer
                                    block_checksum += (*wps++)&0xFF;
                                    block_bytecount++;
                            } // end loop over any bytes in message
                            break;  // end case C_WS_BLOCKSTART

                        case C_WS_BLOCKDATA:        // Block Data Download
                            if (block_status == BLOCK_INPROGRESS) {
                                for (i=1; i<rcvmsglen; i++) {
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
                            break;  // end case C_WS_BLOCKDATA

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
                            break;  // end case C_WS_BLOCKEND

                        case C_WS_RECONFIGEE2:              // Reconfigure FPGA using EEPROM #2
                        case C_WS_RECONFIGEE1:              // Reconfigure FPGA using EEPROM #1
                            retbuf[1] = C_STATUS_INVALID;   // Assume ERROR REPLY
                            replylength = 2;
                            memcpy ((unsigned char *)&lwork, wps, 4);   // copy 4 bytes from incoming message
                            // Confirm length is 5 and have proper code
                            if ((rcvmsglen == RECONFIG_LEN) && (lwork == RECONFIG_CONST)) {
                                i = retbuf[0] & 0x3;    // get which EEPROM we are doing (had been copied here)
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
                                init_regs_FPGA(board_posn);   // initialize FPGA
                                pld_ident = read_FPGA (IDENT_7_R);
                                retbuf[2] = pld_ident;  // tell the magic ID code value
                                replylength = 3;
                            } // end if we could really do it
                            break;      // end case C_WS_RECONFIGEE?

                        case C_WS_TARGETEEPROM2:
                            if (block_status == BLOCK_ENDED) {
                                if (block_bytecount == 256) {    // if bytecount OK
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
                                    spi_write_adr (EE_AL_WRDA, (unsigned char *)&eeprom_address, LS2MSBIT, 256, (unsigned char *)&block_buffer[0]);
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
// This is commented out for speed test
//                                    waitfor_FPGA(); // wait for FPGA to reconfigure
                                    reset_FPGA();   // reset FPGA
                                    init_regs_FPGA(board_posn); // initialize FPGA
                                } else {  // Length is not right
                                    retbuf[1] = C_STATUS_LTHERR;     // SET ERROR REPLY
                                } // end else length was not OK
                            } else {        // else block was not ended, send error reply
                                retbuf[1] = C_STATUS_NOSTART;       // ERROR REPLY
                            } // end else block was not in progress
                            break;  // end case C_WS_TARGETEEPROM2

// WB-1L If second image is running we do not want to download another second image
#if !defined (DOWNLOAD_CODE)
                        case C_WS_TARGETMCU:
                            if (block_status == BLOCK_ENDED) {
                                // check for correct length of stored block and incoming message
                                //JS if ( (block_bytecount != 0) && (ecan2msgBuf[1][2] == 6) ) {
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
//JS: TIMER STUFF **************************************
						case C_WS_MAGICNUMWR:
                            if (rcvmsglen == 3) {
                            	// Copy any data from message.
								memset(readback_buffer, 0xff, 4);
                            	wpd = (unsigned char *)readback_buffer;    // point destination to buffer
                            	for (i=1; i<3; i++) {   // copy any remaining bytes
                                    *wpd++ = *wps++;        // copy byte into buffer
                            	} // end loop over any bytes in message

								// magic address at end of PIC24HJ64 device program memory
								laddrs = 0xABFE;		// magic address
                                save_SR = SR;           // save the Status Register
                                SR |= 0xE0;             // Raise CPU priority to lock out  interrupts
                                erase_MCU_pm ((laddrs & PAGE_MASK));      // erase the page
                                // now write the block_bytecount or PAGE_BYTES starting at actual address or begin page
                                write_MCU_pm ((unsigned char *)readback_buffer, laddrs); // Write a word
                                SR = save_SR;           // restore the saved status register

                            } else {        // else block was not ended, send error reply
                                retbuf[1] = C_STATUS_LTHERR;     // SET ERROR REPLY
                            } // end else block was not in progress

                            break;  // end case C_WS_MAGICNUMWR
//JS: END TIMER STUFF **********************************
#endif // #if !defined (DOWNLOAD_CODE)

                        case C_WS_MCURESTARTA:       // Restart MCU
                        case C_WS_MCURESET:        // Reset MCU
                            retbuf[1] = C_STATUS_INVALID;   // Assume ERROR REPLY
                            replylength = 2;
                            memcpy ((unsigned char *)&lwork, wps, 4);   // copy 4 bytes from incoming message
                            // Confirm length is 5 and have proper code
                            if ((rcvmsglen == MCURESET_LEN) && (lwork == MCURESET_CONST)) {
                                retbuf[1] = C_STATUS_OK;    // say we are OK
                                if (rcvmsgfrom == 1) {
                                    send_CAN1_message (board_posn, (C_BOARD | C_WRITE_REPLY), replylength, (unsigned char *)&retbuf);
                                    while (C1TR01CONbits.TXREQ0==1) {};    // wait for transmit to complete
                                } else if (rcvmsgfrom == 2) {
                                    send_CAN2_message (board_posn, (C_BOARD | C_WRITE_REPLY), replylength, (unsigned char *)&retbuf);
                                    while (C2TR01CONbits.TXREQ0==1) {};    // wait for transmit to complete
                                }
                                if ((retbuf[0] & 0xFF) == C_WS_MCURESTARTA) {  // if we are starting new code
#ifndef DOWNLOAD_CODE
                                    // stop interrupts
                                    CORCONbits.IPL3=1;     // WB-1L Raise CPU priority to lock out user interrupts
                                    save_SR = SR;          // save the Status Register
                                    SR |= 0xE0;            // Raise CPU priority to lock out interrupts
// be sure we are running from alternate interrupt vector
                                    INTCON2 |= 0x8000;     // This is the ALTIVT bit
                                    jumpto();    // jump to new code
#endif
                                } // end if we are starting new code,
                                __asm__ volatile ("reset");
                            }
                            break;  // end case C_WS_MCURESET - execution never gets here since we do a reset and restart

                           break;

                        case C_WS_BLOCKCKSUM:       // Block Data Checksum
                            retbuf[1] = C_STATUS_INVALID;
                            break;

                        default:                    // Undecodeable
                            retbuf[1] = C_STATUS_INVALID;       // ERROR REPLY
                            break;
                    }                           // end switch on Write Subcommand
                    // Send the reply to the WRITE message
                    if (rcvmsgfrom == 1) send_CAN1_message (board_posn, (C_BOARD | C_WRITE_REPLY), replylength, (unsigned char *)&retbuf);
                    if (rcvmsgfrom == 2) send_CAN2_message (board_posn, (C_BOARD | C_WRITE_REPLY), replylength, (unsigned char *)&retbuf);
                    break;  // end case C_WRITE

                case C_READ:    // Process a "Read"
                    replylength = 1;        // default reply length for a Read
                                // now decode the "Read-from" location inside message
                    retbuf[0] = *wps++;     // WPS now points to remainder of message
                    switch (retbuf[0]&0xFF) {   // which address?
                        case (C_RS_STATUSB):              // READ STATUS Board
                            for (i=1; i<8; i++) retbuf[i] = 0;   // stubbed off for now
                            board_temp = Read_Temp();
                            memcpy ((unsigned char *)&retbuf[1], (unsigned char *)&board_temp, 2);
                            retbuf[3] = (unsigned char)Read_MCP23008(ECSR_ADDR, MCP23008_GPIO);
                            replylength = 8;
                            break;
                            // end case C_RS_STATUSB

                        case (C_RS_MCUMEM ):            // Return MCU Memory 4-bytes
                            if (rcvmsglen == 5) { // check for correct length of incoming message
                                memcpy ((unsigned char *)&lwork, wps, 4);   // copy 4 bytes from incoming message
                            } else {        // allow continued reads w/o address
                                lwork += 2L;
                            } // end else continued reads
                            read_MCU_pm ((unsigned char *)&retbuf[1], lwork); // Read from requested location
                            replylength = 5;
                            break; // end case C_RS_MCUMEM

                        case (C_RS_TEMPBRD):                // READ Temperature
                            board_temp = Read_Temp();
                            memcpy ((unsigned char *)&retbuf[1], (unsigned char *)&board_temp, 2);
                            replylength = 3;
                            break; // end case C_RS_TEMPBRD

                        case (C_RS_FIRMWID):              // READ FIRMWARE ID of MCU
                              retbuf[1] = FIRMWARE_ID_0;
                              retbuf[2] = FIRMWARE_ID_1;
                              retbuf[3] = (unsigned char)(read_FPGA (IDENT_7_R)&0xFF);
                              replylength = 4;
                            break; // end case C_RS_FIRMWID

                        #if defined (SN_ADDR)
                        case (C_RS_SERNBR):           // Return the board Serial Number
                            Write_device_I2C1 (SN_ADDR, CM00_CTRL, CM00_CTRL_I2C);     // set I2C mode
                            for (j=1; j<8; j++) {       // we only return 7 bytes (of 8)
                                retbuf[j] = (unsigned char)Read_MCP23008(SN_ADDR,j);        // go get sn byte
                            }
                            replylength = 8;
                            break; // end case C_RS_SERNBR
                        #endif

                       case C_RS_FPGAREG:          // Read from FPGA Register(s)
                            replylength = 1;
                            i = 2;
                            //JS while ( i<=(ecan2msgBuf[1][2]&0xFF)) {
                            while ( i<=rcvmsglen) { //JS
                                retbuf[replylength] = *wps++;
                                retbuf[replylength+1] = read_FPGA ((unsigned int)(retbuf[replylength]&0xFF));
                                replylength += 2;
                                i++;
                            }
                            break;  // end case C_RS_FPGAREG

                        case (C_RS_JSW):              // Return the Jumper/Switch settings (U35)
                            retbuf[1] = (unsigned char)Read_MCP23008(SWCH_ADDR, MCP23008_GPIO);
                            replylength = 2;
                            break; // end case C_RS_JSW

                        case (C_RS_ECSR):             // Return the Extended CSR settings (U36)
                            retbuf[1] = (unsigned char)Read_MCP23008(ECSR_ADDR, MCP23008_GPIO);
                            replylength = 2;
                            break; // end case C_RS_ECSR

                        case (C_RS_MCUSTATUS):        // Return the MCU Status (U19)
                            // return the contents of the reset vector
                            read_MCU_pm ((unsigned char *)&retbuf[1], 0L);
                            replylength = 5;
                            break; // end case C_RS_MCUSTATUS

                        default:    // Undecodable
                            replylength = 1;        // just return the code
                            break; // end case default

                    } // end switch on READ SUBCOMMAND (Address)
                    if (rcvmsgfrom == 1) send_CAN1_message (board_posn, (C_BOARD | C_READ_REPLY), replylength, (unsigned char *)&retbuf);
                    if (rcvmsgfrom == 2) send_CAN2_message (board_posn, (C_BOARD | C_READ_REPLY), replylength, (unsigned char *)&retbuf);
                    break;

                default:                 // All others are undecodable, ignore
                    break;
            }                               // end MAJOR switch on WRITE or READ COMMAND
            //  Mark buffers OK to re-use
            if (rcvmsgfrom == 1) C1RXFUL1bits.RXFUL1 = 0;       // receive buffer 1 OK to re-use
            if (rcvmsgfrom == 2) C2RXFUL1bits.RXFUL1 = 0;       // receive buffer 2 OK to re-use
        } else {    // do not have message to process, check switch / jumper settings, loss-of-lock, etc.
	        if (oldswitch != Read_MCP23008(SWCH_ADDR, MCP23008_GPIO) ) { // see if switches changed
                // posn #  =  (SW5 * 10) + SW4  == switches are BCD decimal
                oldswitch = Read_MCP23008(SWCH_ADDR, MCP23008_GPIO); // see if switches changed
                j = (((oldswitch&0xF0)>>4)*10) + (oldswitch & 0xF);
                write_FPGA (CONFIG_12_W, j);        // write it to FPGA
            } // end if sw4 or sw5 changed
// Check button and issue strobe_12 if pressed
            jumpers = Read_MCP23008(ECSR_ADDR, MCP23008_GPIO) & JUMPER_MASK;
            if ((jumpers & BUTTON)==BUTTON) {
                spin(0);
                jumpers = Read_MCP23008(ECSR_ADDR, MCP23008_GPIO) & JUMPER_MASK;
                if ((jumpers & BUTTON)==BUTTON) {
//                  write_FPGA (STROBE_12_W, 0);
                } // end if have second switch
            } // end if have first switch
            if (jumpers != oldjumpers) { // look for jumpers to change

// WB-1L
// CLOCK SELECTION IS NOT DYNAMIC - JUMPER IS EXAMINED ONLY AT POWER-ON
/* -----------------12/9/2006 11:39AM----------------
** Jumper JU2.1-2 now controls MCU_SEL_LOCAL_OSC
** and MCU_EN_LOCAL_OSC
** Installing the jumper forces low on MCU_...OSC
** disabling it.
 --------------------------------------------------*/
//                if ( (jumpers & JUMPER_1_2) == JUMPER_1_2) {  // See if jumper IN
//                    MCU_SEL_LOCAL_OSC = 0;      // Jumper INSTALLED turns off sel-local-osc
//                    MCU_EN_LOCAL_OSC  = 0;      // and turns off en-local-osc
//                    // Make sure PLL is initialized if not using local osc.
//                    PLL_RESET = 0;          // Make sure it is Low
//                    PLL_RESET = 1;          // Make it High
//                    spin(0);                // Spin a while (1 uSec minimum, this is 20 mSec)
//                    PLL_RESET = 0;          // Make it Low (enables self cal)
//                    spin(0);                // Spin a while (2 mSec minimum, this is 20 mSec)
//                } else {                        // Jumper OUT (use local osc)
//                    MCU_SEL_LOCAL_OSC = 1;      // turns on sel-local-osc
//                    MCU_EN_LOCAL_OSC  = 1;      // turns on en-local-osc
//                }                               // end else turn ON local osc

// WB-1L end

                oldjumpers = jumpers;
                ledbits = (ledbits|0x0F) ^ (jumpers & 0x0F);    //
            } // end if jumpers changed
/* 30-Apr-2007
** If board-position switch changes, write it to FPGA
*/
// Get board-position switch

            jumpers = Read_MCP23008(SWCH_ADDR, MCP23008_GPIO);
            if (jumpers != oldswitch) {         // see if switch changed
                // posn #  =  (SW5 * 10) + SW4  == switches are BCD decimal
                oldswitch = jumpers;        // remember for next time
                jumpers = (((oldswitch&0xF0)>>4)*10) + (oldswitch & 0xF);
// Put board-position switch into CONFIG_12_W of FPGA
                write_FPGA (CONFIG_12_W, jumpers);
            } // end if switch changed.

/* --------------- 04/23/2007
** Add check of PLL_Loss_of_Lock signal and copy to LED D5
*/
            if (PLL_LOS== 0) {     // zero is OK
                ledbits |= LED5;        // LED D5 is OFF if OK
            } else {
                ledbits &= ~LED5;        // LED D5 is ON if LOSS-OF-LOCK
            } // end else it was not OK

            Write_device_I2C1 (LED_ADDR, MCP23008_OLAT, ledbits);

            tglbit ^= 1;        // toggle the bit in port
            PORTGbits.RG15 = tglbit;
#if defined (RC15_IO) // RC15 will be I/O (in TCPU-C_Board.h)
            PORTCbits.RC15 = tglbit;        // make it like RG15
#endif
//            spin(15);
#if defined (DOREGTEST)
    #undef DODATATEST
/* Register Write/Read/Read test
** Once we enter here, we keep reading and sending until a CAN message comes in
*/
// See if we have data to send
            do {
                write_FPGA (CONFIG_0_RW,DOREGTEST);       // Write the test value to the FPGA
                sendbuf[1] = (unsigned char)read_FPGA (7);  // Read register 7
                sendbuf[0] = (unsigned char)read_FPGA (0);  // Read register 0
                j = 2;
                send_CAN2_data (board_posn, j, (unsigned char *)&sendbuf[0] ); // fixed indexing 08-Mar-07
                j = 0;

            } while ( ! C1RXFUL1bits.RXFUL1 );      // send-data loop until a message comes in
#endif

#if defined (DODATATEST)
/* Data transmission test
** Once we enter here, we keep reading and sending until a CAN message comes in
*/
            j = 0;
// See if we have data to send
            do {
				i = read_FPGA (FIFO_STATUS_R);
				if ((i&FIFO_EMPTY_BIT) == 0) {  // Do we have data to send?
                // bit was not 0, we have data, send it
                    sendbuf[0] = (unsigned char)read_FPGA (FIFO_BYTE0_R);
                    sendbuf[1] = (unsigned char)read_FPGA (FIFO_BYTE1_R);
                    sendbuf[2] = (unsigned char)read_FPGA (FIFO_BYTE2_R);
                    sendbuf[3] = (unsigned char)read_FPGA (FIFO_BYTE3_R);
                    j += 4;
                    read_FPGA (FIFO_STATUS_R);          // extra read-status

#define SENDTWO 1
#if defined (SENDTWO)
                    // Check again for more data
                    if ((read_FPGA (FIFO_STATUS_R)&FIFO_EMPTY_BIT) == 0) {
                        sendbuf[4] = (unsigned char)read_FPGA (FIFO_BYTE0_R);
                        sendbuf[5] = (unsigned char)read_FPGA (FIFO_BYTE1_R);
                        sendbuf[6] = (unsigned char)read_FPGA (FIFO_BYTE2_R);
                        sendbuf[7] = (unsigned char)read_FPGA (FIFO_BYTE3_R);
                        j += 4;
                        read_FPGA (FIFO_STATUS_R);          // extra read-status
                    } // end if had more, send message
#endif          // endif defined SENDTWO

                    if (j != 0) send_CAN2_data (board_posn, j, (unsigned char *)&sendbuf[0] ); // fixed indexing 08-Mar-07
                    j = 0;
                } // end if have data to send

//JS: TIMER STUFF **************************************
#ifndef DOWNLOAD_CODE
				if (timerExpired == 1) {
					timerExpired = 0;
					// magic address at end of PIC24HJ64 device program memory
                    read_MCU_pm ((unsigned char *)readback_buffer, 0xABFE); 
#ifdef NOTNOW
					// for now, just send back a CAN message indicating the memory content
					retbuf[0] = readback_buffer[0];
					retbuf[1] = readback_buffer[1];
					retbuf[2] = readback_buffer[2];
					retbuf[3] = readback_buffer[3];
#endif
					if (*((unsigned int *)readback_buffer) == 0x3412) {
						// in the future, the reset code would go here
#ifdef NOTNOW
						retbuf[4] = 1;
#endif
                        // stop interrupts
                        CORCONbits.IPL3=1;     // Raise CPU priority to lock out user interrupts
                        save_SR = SR;          // save the Status Register
                        SR |= 0xE0;            // Raise CPU priority to lock out interrupts
						// be sure we are running from alternate interrupt vector
                        INTCON2 |= 0x8000;     // This is the ALTIVT bit
                        jumpto();    // jump to new code
					} 
#ifdef NOTNOW
					else {
						retbuf[4] = 0;
					}
                    send_CAN2_message (board_posn, (C_BOARD | C_WRITE_REPLY), 5, (unsigned char *)&retbuf);
#endif
				}
#endif
//JS: END TIMER STUFF ***********************************

//            } while ( ! C1RXFUL1bits.RXFUL1 );      // send-data loop until a message comes CAN1
//            } while ( ! C2RXFUL1bits.RXFUL1 );      // send-data loop until a message comes in CAN2
            } while ( ! (C1RXFUL1bits.RXFUL1|C2RXFUL1bits.RXFUL1|C1RXFUL1bits.RXFUL2 | C2RXFUL1bits.RXFUL2) );      // send-data loop until a message comes in either port

#endif
        } // end else did not have message
    } while (1); // end do forever
}

// WB-1L
// Replaced old initialize_OSC routine

int Initialize_OSC (unsigned int selectosc){
/* initialize the CPU oscillator (works with settings in TDIG-D_CAN_HLP3.h)
** Call with: selectosc as follows:
**      selectosc == OSCSEL_BOARD  == 0 == Use on-Board oscillator (40 MHz)
**      selectosc == OSCSEL_TRAY   == 8 == Use Tray oscillator (40 MHz)
**      selectosc == OSCSEL_FRCPLL == 1 == Use MCU Fast RC + PLL (40 MHz)
**      OSCSEL_TRAY / OSCSEL_BOARD can be OR'd with PLL_SELECT to include PLL (U100) in clock chain
**
*/
    int retstat = 1;                    // Assume BAD return

/*  First, switch to FRCPLL so we are sure to keep MCU running */
    Switch_OSC(MCU_FRCPLL);     /* Switch MCU to FRCPLL */
    PLLFBD=20;                  /* M= 20*/
    CLKDIVbits.PLLPOST=0;       /* N1=2 */
    CLKDIVbits.PLLPRE=0;        /* N2=2 */
    OSCTUN=0;                   /* Tune FRC oscillator, if FRC is used */
//  OSCTUN=0x11;                /* Tune FRC oscillator upwards to 40 MHz */
    while(OSCCONbits.LOCK!=1) {}; /* Wait for PLL to lock */
//    ecan1Init(board_posn);      // if clock has changed we must reinitialize CANBus

    MCU_SEL_BYPASS = 0;         // Turns OFF PLL process (U100) by default

/* Select FRCPLL, TRAY, or BOARD Clock Source */
    if ((selectosc&OSCSEL_FRCPLL)==OSCSEL_FRCPLL) {
        // we don't need to do anything here, we already reset the MCU
        retstat = 0;
    } else {
        if ((selectosc&OSCSEL_TRAY)==OSCSEL_TRAY) { // Selecting TRAY clock (EXT_CLK) w/ or w/o PLL
            MCU_SEL_LOCAL_CLK = 1;      // turns on EXT_CLK at mux U101
            MCU_EN_LOCAL_OSC = 0;       // turns off en-local-osc to U25
            retstat = 0;                // ok
        } else {                        // Else Selecting BOARD clock (Int_Clock) w/ or w/o PLL
            MCU_EN_LOCAL_OSC = 1;       // turns on en-local-osc to U25
            spin(0);                    // wait for local osc to turn on
            MCU_SEL_LOCAL_CLK = 0;      // selects LOCAL_CLK at U101
            retstat = 0;                // ok
        } // end if selecting BOARD or EXT clock source

/* Select whether or not to use PLL */
        if ((selectosc&PLL_SELECT)==PLL_SELECT) { // Selecting PLL
        // Make sure PLL is initialized
            PLL_RESET = 0;          // Make sure it is Low
            spin(0);                // (this is 20 mSec)
            PLL_RESET = 1;          // Make it High, starts Calibration
            spin(0);                // (this is 20 mSec)
            while (CAL_ACTV==1) {}  // Wait for PLL to lock

            MCU_SEL_BYPASS = 1;         // Turns ON PLL process (U100)

        } // end if we asked for PLL
        Switch_OSC(MCU_EXTERN);
    } // end else switching to external oscillator (board or tray)
//    if (retstat == 0) ecan1Init(board_posn);      // if clock has changed we must reinitialize CANBus
    return(retstat);                    // return the status
}

void Switch_OSC(unsigned int mcuoscsel) {         /* Switch Clock Oscillator on MCU*/
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
// Old routine
//void Initialize_OSC (void)
//{                   // initialize the CPU oscillator (works with settings in TCPU-C_Board.h)
//    PLLFBD=20;                  /* M= 20*/
//    CLKDIVbits.PLLPOST=0;       /* N1=2 */
//    CLKDIVbits.PLLPRE=0;        /* N2=2 */
////  OSCTUN=0x35;                /* Tune FRC oscillator */
////  OSCTUN=0;                   /* Tune FRC oscillator, if FRC is used */
////    OSCTUN=0x11;                /* Tune FRC oscillator upwards to 40 MHz */
///* Wait for PLL to lock */
//    while(OSCCONbits.LOCK!=1) {};
//}
// WB-1L end

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
 Baud Prescaler CiCFG1<BRP>  = (FCAN /(2×NTQ×FBAUD)) – 1
 BRP = (20MHz / 2*10*1MBaud))-1 = 0
*/
	/* Baud Rate Prescaler */
	C1CFG1bits.BRP = 0;

	/* Synchronization Jump Width set to 1 TQ */
	C1CFG1bits.SJW = 0x1;

	/* Propagation Segment time is 3 TQ */
	C1CFG2bits.PRSEG = 0x2;

	/* Phase Segment 1 time is 4 TQ */
	C1CFG2bits.SEG1PH=0x3;

	/* Phase Segment 2 time is set to be programmable */
	C1CFG2bits.SEG2PHTS = 0x1;
	/* Phase Segment 2 time is 2 TQ */
	C1CFG2bits.SEG2PH = 0x1;

	/* Bus line is sampled one time at the sample point */
	C1CFG2bits.SAM = 0x0;
/* -------------------------------*/

/* 4 CAN Message (FIFO) Buffers in DMA RAM (minimum number) */
    C1FCTRLbits.DMABS=0b000;            // Page 189

/* --------- Filter/Buffer for messages TCPU will act on ---------- */
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
    C1RXM0SIDbits.SID = 0x03F1; // 0b011 1brd 0000 << LSBit ==0

// Configure Acceptance Filter 0 to match Standard Identifier
    C1RXF0SIDbits.SID = (C_BOARD>>2)|((board_id&0x1F)<<4);  // 0biii ibrd xxxx

// Configure Acceptance Filter for Standard Identifier
    C1RXM0SIDbits.MIDE = 0x1;
    C1RXM0SIDbits.EID = 0x0;

// Acceptance Filter 0 uses message buffer 1 to store message
    C1BUFPNT1bits.F0BP = 1;

// Filter 0 enabled
    C1FEN1bits.FLTEN0 = 0x1;

/* --------- Filter/Buffer for messages TCPU will pass along  ---------- */
/* Set up Filter 1 to accept NON-TCPU type messages */
// Select Acceptance Filter Mask 1 for Acceptance Filter 1
    C1FMSKSEL1bits.F1MSK = 0x1;

// Configure Acceptance Filter Mask 1 register to
//      Mask TDIG specific bits per HLP 3 protocol
//     only the "reply-type" messages (bit 0 set) will get passed along
    C1RXM1SIDbits.SID = 0x0001; // 0bxx1 xxxx xxx1
// we will expect to get           0b001 xxxx xxx1

// Configure Acceptance Filter 1 to match Standard Identifier for Any TDIG (ID xx1)
    C1RXF1SIDbits.SID = 0b00000000001;  //

// Configure Acceptance Filter for Standard Identifier
    C1RXM0SIDbits.MIDE = 0x1;
    C1RXM0SIDbits.EID = 0x0;

// Acceptance Filter 1 uses message buffer 2 to store message
    C1BUFPNT1bits.F1BP = 2;

// Filter 1 enabled
    C1FEN1bits.FLTEN1 = 0x1;

// Clear window bit to access ECAN control registers
    C1CTRL1bits.WIN = 0;

/* Enter Normal Mode */
    C1CTRL1bits.REQOP=0;                // Request normal mode
    while(C1CTRL1bits.OPMODE!=0);       // Wait for normal mode

/* ECAN #1 transmit/receive message control */
    C1RXFUL1=0x0000;                    // mark RX Buffers 0..15 empty
    C1RXFUL2=0x0000;                    // mark RX Buffers 16..31 empty
    C1RXOVF1=0x0000;                    // clear RX Buffers 0..15 overflow
    C1RXOVF2=0x0000;                    // clear RX Buffers 16..31 overflow
	C1TR01CONbits.TXEN0=1;			/* ECAN1, Buffer 0 is a Transmit Buffer */
	C1TR01CONbits.TXEN1=0;			/* ECAN1, Buffer 1 is a Receive Buffer */
    C1TR23CONbits.TXEN2=0;          /* ECAN1, Buffer 2 is a Receive Buffer */
//    C1TR23CONbits.TXEN3=0;          /* ECAN1, Buffer 3 is a Receive Buffer */
    C1TR01CONbits.TX0PRI=0b11;      /* Message Buffer 0 Priority Level highest */
    C1TR01CONbits.TX1PRI=0b11;      /* Message Buffer 1 Priority Level highest */
    C1TR23CONbits.TX2PRI=0b11;      // Message Buffer 2 Priority Level highest */
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

/* Enable DMA0 channel */
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

void ecan2Init(unsigned int board_id) {
/* Initialize ECAN #2  and put board_id into mask / filter */
/* Request Configuration Mode */
    C2CTRL1bits.REQOP=4;                // Request configuration mode
    while(C2CTRL1bits.OPMODE!=4);       // Wait for configuration mode active

/* FCAN is selected to be FCY
** FCAN = FCY = 20MHz */
    C2CTRL1bits.CANCKS = 0x1;           // FCAN = FCY == 20MHz depends on board and PLL
/*
Bit Time = (Sync Segment (1*TQ) +  Propagation Delay (3*TQ) +
 Phase Segment 1 (3*TQ) + Phase Segment 2 (3TQ) ) = 10*TQ = NTQ
 Baud Prescaler CiCFG1<BRP>  = (FCAN /(2×NTQ×FBAUD)) – 1
 BRP = (20MHz / 2*10*1MBaud))-1 = 0
*/
	/* Baud Rate Prescaler */
    C2CFG1bits.BRP = 0;

	/* Synchronization Jump Width set to 2 TQ */
    C2CFG1bits.SJW = 0x1;

	/* Propagation Segment time is 3 TQ */
    C2CFG2bits.PRSEG = 0x2;

    /* Phase Segment 1 time is 4 TQ */
    C2CFG2bits.SEG1PH=0x3;

	/* Phase Segment 2 time is set to be programmable */
    C2CFG2bits.SEG2PHTS = 0x1;
    /* Phase Segment 2 time is 2 TQ */
    C2CFG2bits.SEG2PH = 0x1;

	/* Bus line is sampled one time at the sample point */
    C2CFG2bits.SAM = 0x0;
/* -------------------------------*/

/* 4 CAN Message (FIFO) Buffers in DMA RAM (minimum number) */
    C2FCTRLbits.DMABS=0b000;            // Page 189

/*	Filter Configuration
    ecan2WriteRxAcptFilter(int n, long identifier, unsigned int exide,
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
    C2CTRL1bits.WIN = 1;                  // SFR maps to filter window

// Select Acceptance Filter Mask 0 for Acceptance Filter 0
    C2FMSKSEL1bits.F0MSK = 0x0;

// Configure Acceptance Filter Mask 0 register to
//      Mask board_id in SID<6:4> per HLP 3 protocol
    C2RXM0SIDbits.SID = 0x03F0; // 0b011 1brd 0000

// Configure Acceptance Filter 0 to match Standard Identifier
    C2RXF0SIDbits.SID = (C_BOARD>>2)|((board_id&0x1F)<<4);  // 0biii ibrd xxxx

// Configure Acceptance Filter for Standard Identifier
    C2RXM0SIDbits.MIDE = 0x1;
    C2RXM0SIDbits.EID = 0x0;

// Acceptance Filter 0 uses message buffer 1 to store message
    C2BUFPNT1bits.F0BP = 1;

// Filter 0 enabled
    C2FEN1bits.FLTEN0 = 0x1;

/* --------- Filter/Buffer for messages TCPU will pass along  ---------- */
/* Set up Filter 1 to accept TCPU extended type messages */
// Select Acceptance Filter Mask 1 for Acceptance Filter 1
    C2FMSKSEL1bits.F1MSK = 0x1;

// Configure Acceptance Filter Mask 1 register to
//      Mask TCPU specific bits per HLP 3 protocol
//     only the "reply-type" messages (bit 0 set) will get passed along
    C2RXM1SIDbits.SID = 0x0000; // SID<10..0>/EID<28..18> 0bxxx xxxx xxxx (any part of standard ID)
    C2RXM1SIDbits.EID = 0x0000; // EID<17..16> 0bxx
    //JS C2RXM1EIDbits.EID = 0x0000; // EID<15..0> 0bxxx xx11 1111 (low bits of EID)
    C2RXM1EIDbits.EID = 0x003f; // EID<15..0> 0bxxx xx11 1111 (low bits of EID) //JS

// Configure Acceptance Filter 1 to match Standard Identifier for Any TDIG (ID xx1)
    C2RXF1SIDbits.SID = 0b00000000000;  //
    C2RXF1SIDbits.EID = 0b00;           //
//    C2RXF1EIDbits.EID = (board_id & 0x1F);
    C2RXF1EIDbits.EID = (C_BOARD>>6)|(board_id & 0x1F);      // WB-1L include C_BOARD bits

// Configure Acceptance Filter 1 for Extended Identifier
    C2RXM0SIDbits.MIDE = 0x1;
    C2RXM0SIDbits.EID = 0x1;

// Acceptance Filter 1 uses message buffer 2 to store message
    C2BUFPNT1bits.F1BP = 2;

// Filter 1 enabled
    C2FEN1bits.FLTEN1 = 0x1;
/* ----- End Filter/Buffer for messages TCPU will pass along  ---------- */


// Clear window bit to access ECAN control registers
    C2CTRL1bits.WIN = 0;

/* Enter Normal Mode */
    C2CTRL1bits.REQOP=0;                // Request normal mode
    while(C2CTRL1bits.OPMODE!=0);       // Wait for normal mode

/* ECAN transmit/receive message control */
    C2RXFUL1=0x0000;                    // mark RX Buffers 0..15 empty
    C2RXFUL2=0x0000;                    // mark RX Buffers 16..31 empty
    C2RXOVF1=0x0000;                    // clear RX Buffers 0..15 overflow
    C2RXOVF2=0x0000;                    // clear RX Buffers 16..31 overflow
    C2TR01CONbits.TXEN0=1;          /* ECAN2, Buffer 0 is a Transmit Buffer */
    C2TR01CONbits.TXEN1=0;          /* ECAN2, Buffer 1 is a Receive Buffer */
    C2TR23CONbits.TXEN2=0;          /* ECAN2, Buffer 2 is a Receive Buffer */
//    C2TR23CONbits.TXEN3=0;          /* ECAN2, Buffer 3 is a Receive Buffer */
    C2TR01CONbits.TX0PRI=0b11;      /* Message Buffer 0 Priority Level highest */
    C2TR01CONbits.TX1PRI=0b11;      /* Message Buffer 1 Priority Level highest */
    C2TR23CONbits.TX2PRI=0b11;      // Message Buffer 2 Priority Level highest */
}


/* DMA Initialization for ECAN2 Transmission */
void dma1Init(void){
/* Set up DMA for ECAN2 Transmit ----------------------------------------- */
     DMACS0=0;                          // Clear DMA collision flags

/* Continuous, no Ping-Pong, Normal, Full, Mem-to-Periph, byte, disabled */
     DMA1CON=0x2020;

/* Peripheral Address Register */
     DMA1PAD=0x0542;    /* ECAN 2 (C2TXD register) */

/* Transfers to do = DMA1CNT+1 */
     DMA1CNT=0x0007;

/* DMA IRQ 71. (ECAN2 Tx Data) select */
     DMA1REQ=71;        // 0x0047

/* point DMA1STA to start address of data-to-transmit buffer */
     //JS DMA1STA=  __builtin_dmaoffset(&ecan2msgBuf[0][0]);
     DMA1STA=  __builtin_dmaoffset(ecan2msgBuf); //JS

/* Enable DMA1 channel */
     DMA1CONbits.CHEN=1;
}
/* ----------------------------------------------------------------------- */

/* DMA Initialization for ECAN2 Reception */
void dma3Init(void){
/* Set up DMA for ECAN2 Receive  ----------------------------------------- */
     DMACS0=0;                          // Clear DMA collision flags

/* Continuous, no Ping-Pong, Normal, Full, Periph-to-Mem, Word, disabled */
     DMA3CON=0x0020;

/* Peripheral Address Register */
     DMA3PAD=0x0540;    /* ECAN 2 (C2RXD register) */

/* Transfers to do = DMA0CNT+1 */
 	 DMA3CNT=0x0007;

/* DMA IRQ 55. (ECAN1 Rx Data Ready) select */
     DMA3REQ=0x0037;    /* ECAN 2 Receive */

/* point DMA2STA to start address of receive-data buffer */
     //JS DMA3STA= __builtin_dmaoffset(&ecan2msgBuf[1][0]);
     DMA3STA= __builtin_dmaoffset(ecan2msgBuf); //JS

/* Enable DMA2 channel */
     DMA3CONbits.CHEN=1;
}

void send_CAN_alerts (unsigned int board_posn)
{
    unsigned long lwork = C_ALERT_ONLINE;
/* Sends "Alert" messge to both CANBusses */
    send_CAN1_message (board_posn, (C_BOARD | C_ALERT), 4, (unsigned char *)&lwork);
    send_CAN2_message (board_posn, (C_BOARD | C_ALERT), 4, (unsigned char *)&lwork);
//  send_CAN2_message_extended ((board_posn+1), ((board_posn<<6) | C_BOARD | C_ALERT), 4, (unsigned char *)&lwork);
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
    i = bytes;
    if (i > 8) i=8;         // at most 8 bytes of payload
    while (C1TR01CONbits.TXREQ0==1) {};    // wait for transmit to complete
    msg_id = (unsigned long)((board_id&0x1F)<<6); // stick in board ID
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
    if (bytes <= 8) {
        while (C1TR01CONbits.TXREQ0==1) {};    // wait for transmit to complete
        msg_id = (unsigned long)((board_id&0x1F)<<6); // stick in board ID
        msg_id |= (C_BOARD | C_DATA);    // reply constant part
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

/* Request the message be transmitted */
        C1TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit
    } // end if have proper length to send
}

void send_CAN2_message (unsigned int board_id, unsigned int message_type, unsigned int bytes, unsigned char *payload)
{
/* Write a Message to ECAN2 Transmit Buffer and Request Message Transmission
** Call with:
**      board_id = identifier of board to be stuffed into message header (board position)
**      message_id = type of message being sent gets or'd with board_id (HLP Type code)
**      bytes = number of payload bytes to send
**      *payload = pointer to payload buffer
**          payload[0] is usually the "subcommand" (HLP 3.0)
**          payload[1] is usually "status" (HLP 3.0)
*/
// WB-1L Added timeout

	unsigned long msg_id;
    unsigned char *cp;
    unsigned int i;
    unsigned int j=0xFFF;

    i = bytes;
    if (i > 8) i=8;         // at most 8 bytes of payload
// WB-1L
//    while (C2TR01CONbits.TXREQ0==1) {}    // wait for transmit to complete

    do {
        --j;
    } while ((C2TR01CONbits.TXREQ0==1) && (j != 0));    // wait for transmit to complete or timeout

    if (j != 0) {
// WB-1L end

/* ------------------------------------------------
Builds ECAN2 message ID into buffer[0] words [0..2]
 -------------------------------------------------- */
        msg_id = (unsigned long)((board_id&0x1F)<<6); // stick in board ID
        msg_id |= message_type;
        ecan2msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
        ecan2msgBuf[0][1] = 0;

/* ------------------------------------------------
** Builds ECAN2 payload Length and Data into buffer words [2..6]
 -------------------------------------------------- */
        ecan2msgBuf[0][2] = i;
        cp = (unsigned char *)&ecan2msgBuf[0][3];
        if (i > 0) {
       // message length up to 7 more
            memcpy (cp, payload, i);          // copy the message
        } // end if have additional bytes in message
/* Request the message be transmitted */
        C2TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit
    } // WB-1L end if didn't time out
}

void send_CAN2_message_extended (unsigned int ext_id, unsigned int message_id, unsigned int bytes, unsigned char *payload)
{
/* Write a Message to ECAN2 Transmit Buffer and Request Message Transmission
** Call with:
**      ext_id = 6 LSBits of extended ID (TCPU board address)
**      message_id = message ID word (presumably from incoming message)
**      bytes = number of payload bytes to send
**      *payload = pointer to payload buffer
**          payload[0] is usually the "subcommand" (HLP 3.0)
**          payload[1] is usually "status" (HLP 3.0)
*/
// WB-1L Added timeout
    unsigned long std_id;
    unsigned char *cp;
	unsigned int i;
    unsigned int j=0xFFF;

    i = bytes;
    if (i > 8) i=8;         // at most 8 bytes of payload
// WB-1L
//    while (C2TR01CONbits.TXREQ0==1) {}    // wait for transmit to complete

    do {
        --j;
    } while ((C2TR01CONbits.TXREQ0==1) && (j != 0));    // wait for transmit to complete or timeout

    if (j != 0) {
// WB-1L end

/* ------------------------------------------------
Builds ECAN2 message ID into buffer[0] words [0..2]
 -------------------------------------------------- */
        ecan2msgBuf[0][0] = message_id | C_EXT_ID_BIT;  // extended ID =1, no remote xmit
        ecan2msgBuf[0][1] = 0;              // upper bits <17..6> of extended ID.
        ecan2msgBuf[0][2] = ((ext_id &0x3F)<<10) | (i & 0xF);   // extended ID<5..0> and # bytes

/* ------------------------------------------------
** Builds ECAN2 payload Length and Data into buffer words [2..6]
 -------------------------------------------------- */
        if (i > 0) {
            cp = (unsigned char *)&ecan2msgBuf[0][3];
       // message length up to 7 more
            memcpy (cp, payload, i);          // copy the message
        } // end if have additional bytes in message
/* Request the message be transmitted */
        C2TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit
    } // WB-1L end if didn't time out
}


void send_CAN2_data (unsigned int board_id, unsigned int bytes, unsigned char *bp)
{
/* Write a Data Message to ECAN2 Transmit Buffer
   Request Message Transmission			*/
/* ------------------------------------------------
Builds ECAN2 message ID into buffer[0] words [0..2]
 -------------------------------------------------- */
	unsigned long msg_id;
    unsigned char *cp, *wp;
	unsigned int i;
    if (bytes <= 8) {
        while (C2TR01CONbits.TXREQ0==1) {};    // wait for transmit to complete
        msg_id = (unsigned long)((board_id&0x1F)<<6); // stick in board ID
        msg_id |= (C_BOARD | C_DATA);    // reply constant part
//      msg_id |= (C_BOARD);
        ecan2msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
        ecan2msgBuf[0][1] = 0;
        ecan2msgBuf[0][2] = 0;
/* ------------------------------------------------
** Builds ECAN1 payload Length and Data into buffer words [2..6]
 -------------------------------------------------- */
        ecan2msgBuf[0][2] += (bytes&0xF);       // message length
		wp = bp;
        cp = (unsigned char *)&ecan2msgBuf[0][3];
		for (i=0; i<bytes; i++) {
			*cp++ = *wp++;
		}

/* Request the message be transmitted */
        C2TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit
    } // end if have proper length to send
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

void __attribute__((__interrupt__))_C2Interrupt(void)
{
    IFS3bits.C2IF = 0;        // clear interrupt flag ECAN2 Event
    if(C2INTFbits.TBIF) {     // If interrupt was from Tx Buffer
        C2INTFbits.TBIF = 0;            // Clear Tx Buffer Interrupt
    }
    if(C2INTFbits.RBIF) {     // If interrupt was from Rx Buffer
        C2INTFbits.RBIF = 0;            // Clear Rx Buffer Interrupt
	}
}

//JS: TIMER STUFF
#ifndef DOWNLOAD_CODE
// Timer 1 Interrupt Service Routine
void _ISR _T3Interrupt(void)
{
	IFS0bits.T3IF = 0;		// clear interrupt status flag Timer 3
	IEC0bits.T3IE = 0;		// disable Timer 3 interrupt
	T2CON = 0; 				// clear Timer 2 control register (turn timer off)
	T3CON = 0; 				// clear Timer 3 control register (turn timer off)
	timerExpired = 1;		// indicate to main program that timer has expired
}
#endif
//JS: END TIMER STUFF

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

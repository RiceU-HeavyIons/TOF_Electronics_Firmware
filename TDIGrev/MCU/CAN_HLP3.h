/* $Id: CAN_HLP3.h,v 1.2 2010-02-10 17:14:38 jschamba Exp $ */
/* CAN_HLP3.h
** DEFINE the HLP_version_3 Packet IDs and constants
** THIS FILE IS A CONSOLIDATION of TDIG-F_CAN_HLP3.h and TCPU-C_CAN_HLP3.h
**     C_BOARD definition is conditional on whether TCPU or TDIG symbol is defined at entry to this file.
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

// Low Nibble Codes (Function):
    #define C_CODE_MASK (0xF<<2)        // Mask for code (function) bits for ECAN buffer
    #define C_ALERT (0x7<<2)            // ALERT message shifted for ECAN buffer
    #define C_DIAGNOSTIC (0x8<<2)       // DIAGNOSTIC message shifted for ECAN buffer
    #define C_READ_REPLY (0x5<<2)       // Read_reply message for ECAN buffer
    #define C_READ (0x4<<2)             // Read message for ECAN buffer
    #define C_WRITE_REPLY (0x3<<2)      // Write_reply message for ECAN buffer
    #define C_WRITE (0x2<<2)            // Write message for ECAN buffer
    #define C_DATA (0x1<<2)             // Data Transmit message for ECAN buffer
#if defined (TCPU)                     // only TCPU uses extended-ID
    #define C_EXT_ID_BIT (0x1)          // Extended ID in message header
#endif
// Destination Codes (Address)
    #if defined (TDIG)
        #define C_BOARD (0x100<<2)           // Target / Source is TDIG
    #elif defined (TCPU)
        #define C_BOARD (0x200<<2)      // Target/Source is TCPU
    #endif

// WB-2H: Limit time spent in CAN1-to-CAN2 transfer loop.
    #define C_LOOP_LIMIT 40

// Block transfer status indicators
    #define BLOCK_NOTSTARTED 0          // Block has not been started yet
    #define BLOCK_INPROGRESS 1          // Block has been started
    #define BLOCK_ENDED 2               // Block has been ended

// byte-0 of Payload codes (C_WRITE SubCommands)
    #define C_WS_CONTROLTDCS  0x04      // Copy Control word to All TDCs
    #define C_WS_CONTROLTDC1  0x05      // Copy Control word to TDC #1
    #define C_WS_CONTROLTDC2  0x06      // Copy Control word to TDC #2
    #define C_WS_CONTROLTDC3  0x07      // Copy Control word to TDC #3
    #define C_WS_THRESHHOLD   0x08      // Write-to-THRESHHOLD DAC
    #define C_WS_TEMPALERTS   0x09      // Write-to-Temperature Alarm limit.
    #define C_WS_LED          0x0A      // Write-to-LED register (U34)
    #define C_WS_TDCPOWER     0x0B      // Write to Power-control
    #define C_WS_FPGARESET    0x0C      // Toggle PLD_RESETB
    #define C_WS_OSCSRCSEL    0x0D      // Select Oscillator/Clock Source
    #define C_WS_FPGAREG      0x0E      // Write FPGA register
    #define C_WS_TOGGLETINO   0x0F      // WB-11V: Toggle TINO_TEST_MCU line.
    #define C_WS_BLOCKSTART   0x10      // Start Block Download
    #define C_WS_BLOCKDATA    0x20      // Block Data Download
    #define C_WS_BLOCKEND     0x30      // End Block Data Download
    #define C_WS_TARGETHPTDCS 0x40      // BlockTarget is all 3 HPTDCs Configuration (setup)
    #define C_WS_TARGETHPTDC1 0x41      // Target is HPTDC 1 Configuration (setup)
    #define C_WS_TARGETHPTDC2 0x42      // Target is HPTDC 2 Configuration (setup)
    #define C_WS_TARGETHPTDC3 0x43      // Target is HPTDC 3 Configuration (setup)
    #define C_WS_TARGETCFGS   0x44      // Target is all 3 HPTDCs basic config (PM)
    #define C_WS_TARGETCFG1   0x45      // Target is HPTDC 1 basic config (PM)
    #define C_WS_TARGETCFG2   0x46      // Target is HPTDC 2 basic config (PM)
    #define C_WS_TARGETCFG3   0x47      // Target is HPTDC 3 basic config (PM)
    #define C_WS_TARGETCTRLS  0x48      // Target is all 3 HPTDCs basic control (PM)
    #define C_WS_TARGETCTRL1  0x49      // Target is HPTDC 1 basic control (PM)
    #define C_WS_TARGETCTRL2  0x4A      // Target is HPTDC 2 basic control (PM)
    #define C_WS_TARGETCTRL3  0x4B      // Target is HPTDC 3 basic control (PM)
    #define C_WS_TARGETMCU    0x4C      // Target is MCU
    #define C_WS_TARGETEEPROM2 0x4E     // Target is EEPROM #2
	#define C_WS_MAGICNUMWR   0x4F      // Write magic number location
    #define C_WS_BLOCKCKSUM   0x50      // Block Data Checksum
    #define C_WS_RECONFIGEE1  0x89      // Reconfigure FPGA from EEPROM #1
    #define C_WS_RECONFIGEE2  0x8A      // Reconfigure FPGA from EEPROM #2
    #define C_WS_MCURESTARTA  0x8D      // MCU Restart at Address
    #define C_WS_MCURESET     0x8F      // MCU Reset (POR Reset)
    #define C_WS_RSTSEQHPTDCS 0x90      // Reset Sequence of all 3 HPTDCs
    #define C_WS_RSTSEQHPTDC1 0x91      // Reset Seq for HPTDC 1
    #define C_WS_RSTSEQHPTDC2 0x92      // Reset Seq for HPTDC 2
    #define C_WS_RSTSEQHPTDC3 0x93      // Reset Seq for HPTDC 3
    #define C_WS_DIAGNOSTIC   0xFF      // Diagnostic use
	//JS: try this for faster eeprom2 loading:
    #define C_WS_FPGA_CONF0   0x11      // 
    #define C_WS_FPGA_CONF1   0x12      // 
	#define C_WS_SEND_ALARM	  0xA0		// Boolean for sending alarm messages

// Oscillator clock selection constants for C_WS_OSCSRCSEL
    #define OSCSRCSEL_LEN 3             // 3 payload bytes exactly
    #define OSCSEL_JUMPER 0xFF          // Select oscillator from Jumper
    #define OSCSEL_BOARD 0x0            // Select on-board oscillator (U25)
    #define OSCSEL_TRAY 0x8             // Select Tray (cable) oscillator (U45)
#if defined (TCPU)
    #define PLL_SELECT 0x10             // Select U100 SI-5321 PLL with either BOARD or TRAY
#endif
    #define OSCSEL_FRCPLL 0x1           // Select MCU FRC w/PLL Oscillator
/* note for the MCU, FNOSC[2..0] codes 0..7 select which oscillator is used (Table 8-1 of Datasheet 70175..pdf)
**    FRCPLL is Fast RC with PLL code  1  these codes are used in routine Switch_osc()                          */

// WB-11V: Length of TOGGLETINO message must be correct
    #define TOGGLETINO_LEN 3            // 3 bytes
// WB-11X: ALARM is now ALERT
// WB-11V: Length of TEMPALERTS message must be correct
// WB-2G: Length of TEMPALARMS and interval between is conditional on TDIG or TCPU definition
#if defined (TCPU)                      // if we are doing TCPU
//    #define TEMPALARMS_LEN 3            // 3 bytes length (CMD code + one 16-bit value)
//    #define TEMPALARMS_INTERVAL 7000   // interval between successive alarm sending (7000 ~= 5 seconds)
    #define TEMPALERTS_LEN 3            // 3 bytes length (CMD code + one 16-bit value)
    #define TEMPALERTS_INTERVAL 7000   // interval between successive alert sending (7000 ~= 5 seconds)
#else                                   // else we are doing TDIG
    #define TEMPALERTS_LEN 7            // 7 bytes length (CMD code + 3 16-bit values)
    #define TEMPALERTS_INTERVAL 14000   // interval between successive alert sending (14000 ~= 5 seconds)
#endif
// bytes 1 thru 4 of C_WS_RECONFIGx Message (used for security)
    #define RECONFIG_LEN 5              // 5 payload bytes in FPGA reconfiguration message
    #define RECONFIG_CONST 0x5AA59669L  // 0x69 0x96 0xA5 0x5A confirmation
// bytes 1 thru 4 of C_WS_FPGARESET Message (used for security)
    #define FPGARESET_LEN 5             // 5 payload bytes in FPGA reset message
    #define FPGARESET_CONST 0x5AA59669L  // 0x69 0x96 0xA5 0x5A confirmation
// bytes 1 thru 4 of C_WS_MCURESET Message (used for security)
    #define MCURESET_LEN 5             // 5 payload bytes in MCU Restart message
    #define MCURESET_CONST 0x5AA59669L  // 0x69 0x96 0xA5 0x5A confirmation
// bytes 1 thru 4 of C_WS_MCUSTART (used for security)
    #define MCURESTART_LEN 5            // 5 payload bytes in MCU restart message
    #define MCURESTART_CONST 0x0L       // 0x00 0x00 0x00 0x00 confirmation

/* byte 5 of C_WS_TARGETMCU (new MCU code download controlling erase/preserve type\
 * These must agree with the host-side code in MCU2.cpp
 */
    #define ERASE_NONE     0            // do not erase
    #define ERASE_NORMAL   1            // normal erase entire 2Kbyte block
    #define ERASE_PRESERVE 2            // preserve unmodified part of 2Kbyte block (e.g. IVT).
    #define PAGE_MASK 0xFFFFFC00L       // Page address mask0xFFFFFC00L
    #define OFFSET_MASK 0x3FF           // Offset mask
    #define PAGE_BYTES 2048             // Page size, bytes

	//JS20090821: new defines for row wise programming
	#define ROW_MASK 0xFFFFFF80L
	#define ROW_OFFSET_MASK 0x7F
	#define ROW_BYTES 256				// Row size, bytes

/* Allowable ranges for MCU Target addresses are defined in TCPU-C_Board.h  or TDIG-F_Board.h */

// byte-0 of Payload codes (C_READ SubCommands)
    #define C_RS_CONTROLTDCS  0x00      // WB-11X Read Control word from All TDCs
    #define C_RS_CONTROLTDC1  0x01      // WB-11X Read Control word from TDC #1
    #define C_RS_CONTROLTDC2  0x02      // WB-11X Read Control word from TDC #2
    #define C_RS_CONTROLTDC3  0x03      // WB-11X Read Control word from TDC #3
    #define C_RS_STATUS1      0x05      // Read Status HPTDC #1
    #define C_RS_STATUS2      0x06      // Read Status HPTDC #2
    #define C_RS_STATUS3      0x07      // Read Status HPTDC #3
    #define C_RS_THRESHHOLD   0x08      // Read THRESHHOLD DAC
    #define C_RS_TEMPBRD      0x09      // Read Temperature of board (U37)
//    #define C_RS_LED          0x0A      // Read-from-LED register (U34)
    #define C_RS_CLKSTATUS    0x0D      // Read MCU Clock Status
    #define C_RS_FPGAREG      0x0E      // Read FPGA Register(s)
    #define C_RS_CONFIGTDCS   0x40      // WB-11X Read Configuration block from All TDCs
    #define C_RS_CONFIGTDC1   0x41      // WB-11X Read Configuration block from TDC #1
    #define C_RS_CONFIGTDC2   0x42      // WB-11X Read Configuration block from TDC #2
    #define C_RS_CONFIGTDC3   0x43      // WB-11X Read Configuration block from TDC #3

    #define C_RS_MCUMEM       0x4C      // Read MCU program memory
    #define C_RS_MCUCKSUM     0x4D      // Checksum MCU address block
    #define C_RS_EEPROM2      0x4E      // Read EEPROM #2
    #define C_RS_EEP2CKSUM    0x4F      // Checksum EEPROM #2 block
    #define C_RS_STATUSB      0xB0      // Read Status of Board
    #define C_RS_FIRMWID      0xB1      // Read Firmware IDs
    #define C_RS_SERNBR       0xB2      // Read Silicon Serial Number (U60)
    #define C_RS_JSW          0xB3      // Read Jumper/Switch Register (U35)
    #define C_RS_ECSR         0xB4      // Read Extended Control/Status (U36)
    #define C_RS_MCUSTATUS    0xB5      // Read MCU Status
    #define C_RS_DIAGNOSTIC   0xFF      // Diagnostic use

// byte-1 of Payload Returned (Status Codes)
    #define C_STATUS_OK       0x00      // OK, Success
    #define C_STATUS_INVALID  0x01      // Invalid, Not Implemented
    #define C_STATUS_NOSTART  0x02      // Block Data/End/Target w/o Block Start
    #define C_STATUS_OVERRUN  0x03      // Block Buffer Overrun
    #define C_STATUS_NOTARGET 0x04      // Block Target is Unknown
    #define C_STATUS_CKSUMERR 0x05      // Checksum mismatch
    #define C_STATUS_LTHERR   0x06      // Block length wrong for target
    #define C_STATUS_BADCFG   0x07      // HPTDC Configuration Readback mismatched
    #define C_STATUS_BADEE2   0x08      // EEPROM #2 / MCU readback error
    #define C_STATUS_TMOFPGA  0x09      // Timeout during FPGA Reconfiguration
    #define C_STATUS_BADADDRS 0x0A      // Invalid address for MCU target

// Payload of "alert" message for sign-on
    #define C_ALERT_ONLINE_LEN 4        // length of sign-on message
    #define C_ALERT_ONLINE 0x000000FFL  // contents of sign-on message

// WB-11J (TDIG) Checksum ALERT message contents
// WB-2F  (TCPU) Checksum ALERT message contents
    #define C_ALERT_CKSUM_LEN 1
    #define C_ALERT_CKSUM_CODE 0x04

// WB-11V (TDIG) Over-temperature alert
    #define C_ALERT_OVERTEMP_LEN 2
    #define C_ALERT_OVERTEMP_CODE 0x09
    #define ALERT_MASK_MCU 0x1
    #define ALERT_MASK_TINO1 0x2
    #define ALERT_MASK_TINO2 0x4

// WB-11R (TDIG) Clock Fail ALERT message
// WB-2F  (TCPU) Clock Fail ALERT message
   #define C_ALERT_CLOCKFAIL_LEN 1
   #define C_ALERT_CLOCKFAIL_CODE 0xFC

// WB-11W (TDIG) CAN1 Overflow /Error Alerts
#if defined (TDIG)
    #define C_ALERT_ERRCAN1_LEN 2
    #define C_ALERT_ERRCAN1_CODE 0xC1
#endif
// WB-2G (TCPU) CAN1 & CAN2 Overflow/Error Alerts
#if defined (TCPU)
    #define C_ALERT_ERRCAN1_LEN 2
    #define C_ALERT_ERRCAN1_CODE 0xC1
    #define C_ALERT_ERRCAN2_LEN 2
    #define C_ALERT_ERRCAN2_CODE 0xC2
#endif

/* CAN_HLP3.h
** comments moved from top of file to here:
**
**  16-Feb-thru-19-Feb-2009, W. Burton (WB-11X)
**      Add symbolics for Report HPTDC Configuration and Control Word readback.
**      Relabel "Alarm" to "Alert" for consistency (e.g. TEMPALARMS_LEN is now TEMPALERTS_LEN).
**  02-Feb-2009, W. Burton (WB-2H)
**      Add symbolic limit for CAN1-to-CAN2 transfer loop
**  30-Jan-2009, W. Burton
**      Add symbolics for CAN1 and CAN2 Overflow/Error alert messages
**  17-Dec-2008, W. Burton
**      TEMPALARMS_LEN and TEMPALARMS_INTERVAL values are conditional on whether TDIG or TCPU is being
**      built.
**  10-Dec-2008, W. Burton
**      Add C_WS_TOGGLETINO == Toggle_TINO_TEST_MCU line function to CANBus protocol.
**      Add C_WS_TEMPALARMS == Temperature Alarm Limits
**  05-Sep-2008, W. Burton
**     THIS FILE IS A CONSOLIDATION of TDIG-F_CAN_HLP3.h and TCPU-C_CAN_HLP3.h
**     C_BOARD definition is conditional on whether TCPU or TDIG symbol is defined at entry
**             to this file.
** 04-Sep-2008, W. Burton
**     C_RS_CLKSTATUS changed to 0x0C to avoid overlap with data switch message.
** 02-Sep-2008, W. Burton
**     Added C_RS_MCUCKSUM, C_RS_EEP2CKSUM, C_STATUS_BADADDRS
** 22-Jul-2008, W. Burton
**     Added C_RS_CLKSTATUS to get read clock status
** 21-Jul-2007, W. Burton
**    Added Clock Source Selection code C_WS_OSCSRCSEL
** 29-Jun-2007, W. Burton
**    Created header file to be used in common with TCPU to define the HLP codes
**
** These implement the new codes as described in the HLP_3 document
** "Standard" CAN address/packet ID (11 bits)
** Low nibble: command function code
** 2nd nibble: 3- or 4-bits of board ID (position switch)
** Top 3 bits: 1-bit of board ID (position switch and 2 bits of Destination
*/

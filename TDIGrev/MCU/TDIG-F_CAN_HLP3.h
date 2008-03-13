// $Id: TDIG-F_CAN_HLP3.h,v 1.3 2008-03-13 18:15:20 jschamba Exp $

/* TDIG-D_CAN_HLP3.h
** DEFINE the HLP_version_3 Packet IDs and constants
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
** 02-Jul-2007, W. Burton
**    Added Clock Source Selection code C_WS_OSCSRCSEL
** 29-Jun-2007, W. Burton
**    Created header file to be used in common with TCPU to define the HLP codes
**
** These implement the new codes as described in the HLP_3 document
** "Standard" CAN address/packet ID (11 bits)
** Low nibble: command function code
** 2nd nibble: 1 bit of Destination or'd w/ 3-bit board ID
** Top 3 bits: 3 bits of Destination
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

// Destination Codes (Address)
    #define C_TDIG (0x100<<2)           // Target / Source is TDIG

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
    #define C_WS_LED          0x0A      // Write-to-LED register (U34)
    #define C_WS_FPGARESET    0x0C      // Toggle PLD_RESETB
    #define C_WS_OSCSRCSEL    0x0D      // Select Oscillator/Clock Source
    #define C_WS_FPGAREG      0x0E      // Write FPGA register
    #define C_WS_BLOCKSTART   0x10      // Start Block Download
    #define C_WS_BLOCKDATA    0x20      // Block Data Download
    #define C_WS_BLOCKEND     0x30      // End Block Data Download
    #define C_WS_TARGETHPTDCS 0x40      // BlockTarget is all 3 HPTDCs
    #define C_WS_TARGETHPTDC1 0x41      // Target is HPTDC 1
    #define C_WS_TARGETHPTDC2 0x42      // Target is HPTDC 2
    #define C_WS_TARGETHPTDC3 0x43      // Target is HPTDC 3
    #define C_WS_TARGETMCU    0x4C      // Target is MCU
    #define C_WS_TARGETEEPROM2 0x4E     // Target is EEPROM #2
    #define C_WS_BLOCKCKSUM   0x50      // Block Data Checksum
    #define C_WS_RECONFIGEE1  0x89      // Reconfigure FPGA from EEPROM #1
    #define C_WS_RECONFIGEE2  0x8A      // Reconfigure FPGA from EEPROM #2
    #define C_WS_MCURESTARTA  0x8D      // MCU Restart at Address
    #define C_WS_MCURESET     0x8F      // MCU Reset (POR Reset)
    #define C_WS_RSTSEQHPTDCS 0x90      // Reset Sequence of all 3 HPTDCs
    #define C_WS_RSTSEQHPTDC1 0x91      // Reset Seq for HPTDC 1
    #define C_WS_RSTSEQHPTDC2 0x92      // Reset Seq for HPTDC 2
    #define C_WS_RSTSEQHPTDC3 0x93      // Reset Seq for HPTDC 3

// Oscillator clock selection constants
    #define OSCSEL_JUMPER 0xFF          // Select oscillator from Jumper
    #define OSCSEL_BOARD 0x0            // Select on-board oscillator (U25)
    #define OSCSEL_TRAY 0x8             // Select Tray (cable) oscillator (U45)
    #define OSCSEL_FRCPLL 0x1           // Select MCU FRC w/PLL Oscillator

// byte-0 of Payload codes (C_READ SubCommands)
    #define C_RS_STATUS1      0x05      // Read Status HPTDC #1
    #define C_RS_STATUS2      0x06      // Read Status HPTDC #2
    #define C_RS_STATUS3      0x07      // Read Status HPTDC #3
    #define C_RS_TEMPBRD      0x09      // Read Temperature of board (U37)
    #define C_RS_FPGAREG      0x0E      // Read FPGA Register(s)
    #define C_RS_MCUMEM       0x4C      // Read MCU program memory
    #define C_RS_STATUSB      0xB0      // Read Status of Board
    #define C_RS_FIRMWID      0xB1      // Read Firmware IDs
    #define C_RS_SERNBR       0xB2      // Read Silicon Serial Number (U60)
    #define C_RS_JSW          0xB3      // Read Jumper/Switch Register (U35)
    #define C_RS_ECSR         0xB4      // Read Extended Control/Status (U36)
    #define C_RS_MCUSTATUS    0xB5      // Read MCU Status

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

// bytes 1 thru 4 of C_WS_RECONFIGx Message (used for security)
    #define RECONFIG_LEN 5              // 5 payload bytes in FPGA reconfiguration message
    #define RECONFIG_CONST 0x5AA59669L  // 0x69 0x96 0xA5 0x5A confirmation
// bytes 1 thru 4 of C_WS_FPGARESET Message (used for security)
    #define FPGARESET_LEN 5             // 5 payload bytes in FPGA reset message
    #define FPGARESET_CONST 0x5AA59669L  // 0x69 0x96 0xA5 0x5A confirmation
// bytes 1 thru 4 of C_WS_MCURESET Message (used for security)
    #define MCURESET_LEN 5             // 5 payload bytes in MCU Restart message
    #define MCURESET_CONST 0x5AA59669L  // 0x69 0x96 0xA5 0x5A confirmation
/* byte 5 of C_WS_TARGETMCU (new MCU code download controlling erase/preserve type\
 * These must agree with the host-side code in MCU2.cpp
 */
    #define ERASE_NONE     0            // do not erase
    #define ERASE_NORMAL   1            // normal erase entire 2Kbyte block
    #define ERASE_PRESERVE 2            // preserve unmodified part of 2Kbyte block (e.g. IVT).
    #define PAGE_MASK 0xFFFFFC00L       // Page address mask0xFFFFFC00L
    #define OFFSET_MASK 0x3FF           // Offset mask
    #define PAGE_BYTES 2048             // Page size, bytes

// Length of message to change oscillator must be correct
    #define OSCSRCSEL_LEN 3             // 3 payload bytes

// WB-11J Checksum ALERT message contents
    #define C_ALERT_CKSUM_LEN 1
    #define C_ALERT_CKSUM_CODE 0x04

/* $Id$ */
/* CAN_HLP3.h
*/

#define C_CODE_MASK 0xF        // Mask for code (function) bits for ECAN buffer
#define C_ALERT 0x7            // ALERT message shifted for ECAN buffer
#define C_DIAGNOSTIC 0x8       // DIAGNOSTIC message shifted for ECAN buffer
#define C_READ_REPLY 0x5       // Read_reply message for ECAN buffer
#define C_READ 0x4             // Read message for ECAN buffer
#define C_WRITE_REPLY 0x3      // Write_reply message for ECAN buffer
#define C_WRITE 0x2            // Write message for ECAN buffer
#define C_DATA 0x1             // Data Transmit message for ECAN buffer

#define C_BOARD 0x410      	   // Target/Source is TOCK

#define C_WS_BUNCHRST 0x70     // Issue Bunch Reset Pulse

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

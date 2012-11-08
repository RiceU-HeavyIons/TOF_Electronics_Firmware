// $Id$

// exeScript_empty.c:
// Do nothing

#define TCPU 1              // We are building TCPU
#include "TCPU-C_Board.h"
#include <ecan.h>

extern void write_FPGA (unsigned int, unsigned int);

#define C_ALERT (0x7<<2)            // ALERT message shifted for ECAN buffer
#define C_DIAGNOSTIC (0x8<<2)       // DIAGNOSTIC message shifted for ECAN buffer
#define C_READ_REPLY (0x5<<2)       // Read_reply message for ECAN buffer
#define C_READ (0x4<<2)             // Read message for ECAN buffer
#define C_WRITE_REPLY (0x3<<2)      // Write_reply message for ECAN buffer
#define C_WRITE (0x2<<2)            // Write message for ECAN buffer
#define C_DATA (0x1<<2)             // Data Transmit message for ECAN buffer
#define C_BOARD (0x200<<2)
#define C_EXT_ID_BIT (0x1)          // Extended ID in message header

#define set_MCU_PLD_STROBE {MCU_PLD_STROBE=1;__asm__ volatile ("nop");}
#define clr_MCU_PLD_STROBE {MCU_PLD_STROBE=0;__asm__ volatile ("nop");}
#define str_MCU_PLD_STROBE {MCU_PLD_STROBE=1;__asm__ volatile ("nop");MCU_PLD_STROBE=0;__asm__ volatile ("nop");}

typedef unsigned int ECAN1MSGBUF [4][8];
extern ECAN1MSGBUF  ecan1msgBuf;
typedef unsigned int ECAN2MSGBUF [4][8];
extern ECAN2MSGBUF  ecan2msgBuf;

int __attribute__((__section__(".script_buffer"))) exeScript(unsigned int board_id)
{

	return 0;
}

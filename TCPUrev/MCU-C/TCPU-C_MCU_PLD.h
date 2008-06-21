// $Id: TCPU-C_MCU_PLD.h,v 1.2 2008-06-21 21:32:38 jschamba Exp $

/* TDIG-D_MCU_PLD.h
** Version for build TCPU-C_2A
** This header file defines the TDIG-D macros and interfaces for MCU data interface to FPGA.
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
** Modified:
**      20-Jun-2008, W. Burton
**          Add function prototype waitfor_fpga()
**      20-Jun-2007, W. Burton
**          Add timeout status return on waitfor_fpga()
** Written: 31-Jan-2007, W. Burton
*/
    #include "TCPU-C_Board.h"

// Defines which configuration EEPROM to use
    #define EEPROM1 0
    #define EEPROM2 1

// Macros
    #define set_MCU_PLD_STROBE {MCU_PLD_STROBE=1;__asm__ volatile ("nop");}
    #define clr_MCU_PLD_STROBE {MCU_PLD_STROBE=0;__asm__ volatile ("nop");}
    #define str_MCU_PLD_STROBE {MCU_PLD_STROBE=1;__asm__ volatile ("nop");MCU_PLD_STROBE=0;__asm__ volatile ("nop");}

// Function Prototypes

void write_FPGA (unsigned int addr, unsigned int val);
unsigned int read_FPGA (unsigned int addr);

void reset_FPGA (void);
void configure_FPGA (unsigned int whicheeprom);
unsigned int waitfor_FPGA (void);
void init_regs_FPGA(unsigned int reg12);
unsigned int waitfor_FPGA (void);

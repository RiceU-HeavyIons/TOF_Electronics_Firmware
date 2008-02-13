// $Id: TDIG-F_JTAG.h,v 1.1 2008-02-13 17:16:12 jschamba Exp $

/* TDIG-D_JTAG.h
** This header file defines the TDIG-D macros and interfaces for JTAG interface to the TDIG chips.
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
**      13-Oct-2007, W. Burton
**          Made "slower" JTAG the only option.
**      06-Sep-2007, W. Burton
**          Added conditional code for "slower" JTAG (added another NOP)
**      29-Jun-2007, W. Burton
**          Updated include processing
**      15-May-2007, W. Burton
**          Added control_hptdc() to send control word (40 bits)
**      29-Mar-2007, W. Burton
**          Added symbolic names for MCU or HEADER control of JTAG.
**          Added
**		17-Jan-2007, W. Burton
**			Added symbolic Instructions and IR length
** Written: 13-Dec-2006, W. Burton
**              Based on assembly macros from Justin Kennington's PIC18F implementation.
*/
//    #include "TDIG-D_Board.h"

// Macros
//#define SLOWERJTAG 1
//#if defined SLOWERJTAG
    #define set_TMS {MCU_TDC_TMS=1;__asm__ volatile ("nop");__asm__ volatile ("nop");}
    #define clr_TMS {MCU_TDC_TMS=0;__asm__ volatile ("nop");__asm__ volatile ("nop");}
    #define set_TDI {MCU_TDC_TDI=1;__asm__ volatile ("nop");__asm__ volatile ("nop");}
    #define clr_TDI {MCU_TDC_TDI=0;__asm__ volatile ("nop");__asm__ volatile ("nop");}
    #define set_TCK {MCU_TDC_TCK=1;__asm__ volatile ("nop");__asm__ volatile ("nop");}
    #define clr_TCK {MCU_TDC_TCK=0;__asm__ volatile ("nop");__asm__ volatile ("nop");}
    #define str_TCK {MCU_TDC_TCK=0;__asm__ volatile ("nop");MCU_TDC_TCK=1;__asm__ volatile ("nop");__asm__ volatile ("nop");MCU_TDC_TCK=0;__asm__ volatile ("nop");__asm__ volatile ("nop");}
//#else
//    #define set_TMS {MCU_TDC_TMS=1;__asm__ volatile ("nop");}
//    #define clr_TMS {MCU_TDC_TMS=0;__asm__ volatile ("nop");}
//    #define set_TDI {MCU_TDC_TDI=1;__asm__ volatile ("nop");}
//    #define clr_TDI {MCU_TDC_TDI=0;__asm__ volatile ("nop");}
//    #define set_TCK {MCU_TDC_TCK=1;__asm__ volatile ("nop");}
//    #define clr_TCK {MCU_TDC_TCK=0;__asm__ volatile ("nop");}
//    #define str_TCK {MCU_TDC_TCK=1;__asm__ volatile ("nop");MCU_TDC_TCK=0;__asm__ volatile ("nop");}
//#endif

// Prototypes for routines
    void read_hptdc_id (unsigned int tdcnbr, unsigned char *rp, unsigned int bufsize);
    void read_hptdc_status (unsigned int tdcnbr, unsigned char *rp, unsigned int bufsize);
    void write_hptdc_setup (unsigned int tdcnbr, unsigned char *configptr, unsigned char *retcfgptr);
    void reset_hptdc (unsigned int tdcnbr, unsigned char *finalctrl);
    void select_hptdc(unsigned int ifmcu, unsigned int whichhptdc); // select which HPTDC to address
    void insert_parity (unsigned char *bitsbuf, unsigned int nbits);
    void JTAG_SCAN (unsigned int IRlen, unsigned int IRword, unsigned int DRlen, unsigned char *DRbyte,
        unsigned int ifDRread, unsigned char *DRread);
    void control_hptdc(unsigned int tdcnbr, unsigned char *ctrl);

// TDIG-D_JTAG.c local routines
    void reset_TAP (void);              // Reset the JTAG
    void IRScan (unsigned char inst);    // Scan the Instruction word
    void DRScan (unsigned char *config, unsigned int dsize, unsigned int write_to, unsigned char *retbuf);

    #define J_NORETURN_DATA 0
    #define J_RETURN_DATA 1

// Symbolic names and sizes for instructions
    #define J_HPTDC_IRBITS 5        // Number of bits in Instruction Register

    #define J_HPTDC_IDCODE 0x11     // IDCODE instruction w/parity
    #define J_HPTDC_IDBITS 32       // Number of bits in IDCODE data

    #define J_HPTDC_SETUP 0x18      // SETUP  instruction w/parity
    #define J_HPTDC_SETUPBITS 647   // Number of bits in SETUP data
    #define J_HPTDC_SETUPBYTES ((unsigned int)((J_HPTDC_SETUPBITS+7)/8))

    #define J_HPTDC_CONTROL 0x09    // CONTROL instruction w/parity
    #define J_HPTDC_CONTROLBITS 40  // Number of bits in CONTROL data
    #define J_HPTDC_CONTROLBYTES ((unsigned int)((J_HPTDC_CONTROLBITS+7)/8))

    #define J_HPTDC_STATUS 0x0A    // STATUS  instruction w/parity
    #define J_HPTDC_STATUSBITS  62 // Number of bits in STATUS data
    #define J_HPTDC_STATUSBYTES  ((unsigned int)((J_HPTDC_STATUSBITS+7)/8))

    #define JTAG_MCU 1      // MCU is in control of HPTDC JTAG (via FPGA)
    #define JTAG_HDR 0      // JTAG Header is in control of HPTDC JTAG (via FPGA)

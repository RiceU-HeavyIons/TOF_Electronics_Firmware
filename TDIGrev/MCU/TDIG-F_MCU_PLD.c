// $Id: TDIG-F_MCU_PLD.c,v 1.2 2008-03-13 18:17:06 jschamba Exp $

/* TDIG-F_MCU_PLD.c
** This file defines the TDIG-D routines and interfaces for MCU iterface to the FPGA.
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
** Modified:
**      08-Sep-2007, W. Burton
**          Updated filenames for RevF boards
**      06-Jul-2007, W. Burton
**          Lengthen strobes if LONGSTROBE is defined.
**      29-Jun-2007, W. Burton
**          Updated include file processing.
**      19-Jun-2007, W. Burton
**          Add timeout return to waitfor_FPGA()
**      30-Apr-2007, W. Burton
**          Add register MCU_PLC initialization routine init_regs_FPGA
**      02-Feb-2007, W. Burton
**          Fix polarities and port directions.
** Written: 31-Jan-2007, W. Burton
*/
    #include "TDIG-F_Board.h"
    #include "TDIG-F_MCU_PLD.h"

void reset_FPGA (void){
/* Hardware reset the FPGA
*/
    PLD_RESETB = 1;
    __asm__ volatile ("nop");
#if defined (LONGSTROBE)
    __asm__ volatile ("nop");
#endif
    PLD_RESETB = 0;
    __asm__ volatile ("nop");
    PLD_RESETB = 1;
}

void write_FPGA (unsigned int addr, unsigned int val) {
/* this routine writes to the FPGA register using
**    MCU_PLD_DATA[0..7] for data (bidirectional)
**    MCU_PLD_CTRL[0..3] for the address (output from MCU)
**    MCU_PLD_CTRL[4] is read=0, write=1
**    MCU_PLD_SPARE1 for the strobe
*/
    unsigned int j;
// Make port bits into Outputs, strobe is low
    clr_MCU_PLD_STROBE;
    j = TRISB;
    TRISB = j & PLD_BDATA_OUTPUT;
    __asm__ volatile ("nop");   // let it settle

// Put out Data and Address
    j = PORTB;      // get current PORTB bits
    j &= 0xA000;    // preserve SPARE0 and SPARE2
    j |= (((addr & 0x0F)<<8) | (val&0xFF));
    LATB = j;       // put out the write, address, and data
    __asm__ volatile ("nop");   // let it settle
    __asm__ volatile ("nop");   // let it settle

// Strobe toggles lHl
    set_MCU_PLD_STROBE; // make the write strobe last longer.
    __asm__ volatile ("nop");   // let it settle
#if defined (LONGSTROBE)
    __asm__ volatile ("nop");
#endif
    str_MCU_PLD_STROBE;

// Just for testing, put out a zero on the data lines (no strobe)
    LATB = j & 0xFF00;
    __asm__ volatile ("nop");   // let it settle

// Make port data bits into Inputs
    j = TRISB;
    TRISB = j | PLD_BDATA_INPUT;
// Done
}

unsigned int read_FPGA (unsigned int addr){
    unsigned int j=0;
// Make port Data bits into Inputs, Control and Strobe are output
// Strobe is low.
    clr_MCU_PLD_STROBE;
    j = TRISB;
    TRISB = j | PLD_BDATA_INPUT;

    j = PORTB;      // get current PORTB bits
    j &= 0xA000;    // preserve SPARE0 and SPARE2

// Make sure to Read
    j |= MCU_PLD_READ;
    LATB = j | ((addr & 0x0F)<<8); // Put out Address
    __asm__ volatile ("nop");   // let it settle
#if defined (LONGSTROBE)
    __asm__ volatile ("nop");
#endif

// Strobe Raises to enable data
    set_MCU_PLD_STROBE;
    __asm__ volatile ("nop");   // let it settle
    __asm__ volatile ("nop");   // let it settle
    __asm__ volatile ("nop");   // let it settle
#if defined (LONGSTROBE)
    __asm__ volatile ("nop");
#endif
    j = PORTB;
    __asm__ volatile ("nop");   // let it settle
// Grab data from port MCU_PLD_DATA[0..7]
    j = PORTB;

// Done with port on PLD , disable it
    clr_MCU_PLD_STROBE;

// Return the value we saw
    return ((j&0xFF));
}

void configure_FPGA(unsigned int whicheeprom) {
/* configure the FPGA from either EEPROM #1 or #2
** TEMPORARY FILE - For now the whicheeprom parameter is ignored,
** therefore, the FPGA will ONLY configure/reconfigure from EEPROM #1 (U15)
** This routine initiates an FPGA reconfiguration cycle and returns when BOTH
** PLD_CONFIG_DONE (U1.N18) AND PLD_INIT_DONE (U1.V19) are High
** After reconfiguration, the FPGA is "reset" by strobing PLD_RESETB (U1.B3)
*/
// Toggle the configuration bit to make it happen
    MCU_SEL_EE2 = 0;
    __asm__ volatile ("nop");
#if defined (LONGSTROBE)
    __asm__ volatile ("nop");
#endif
    MCU_CONFIG_PLD = 0;
    __asm__ volatile ("nop");
       spin(5);
    MCU_CONFIG_PLD = 1;
    __asm__ volatile ("nop");
#if defined (LONGSTROBE)
    __asm__ volatile ("nop");
#endif

// Check to see if FPGA has configured
    waitfor_FPGA();

// When FPGA has configured, reset it
    reset_FPGA();
}

unsigned int waitfor_FPGA (void){
/* Wait for FPGA to become Ready as defined by
** PLD_CONFIG_DONE (U1.N18) AND PLD_INIT_DONE (U1.V19) being High
** These signals are available to the MCU through the I2C bus at U36 (ECSR)
**  19-Jun-2007, W. Burton
**      Add timeout status return
*/
    unsigned timeout=0xFFFF;
    while ( (timeout != 0) && ((Read_MCP23008(ECSR_ADDR,MCP23008_GPIO) & PLD_READY) != PLD_READY)) {timeout--;};
    if (timeout == 0) { return (1); } else return (0);
}

void init_regs_FPGA(unsigned int board_posn) {
/* Write default initial values into FPGA registers (MCU_PLD_xx).
** For now, Registers address 0 thru 3 are initialized to zero.
** 06-Sep-07 Reg 14 set to zero to select data.
*/
    unsigned int i;
    for (i=0; i<4; i++) {
        write_FPGA (i, 0);
    }
    write_FPGA (14, 0);

// Write Board-Position to FPGA Register
    write_FPGA (CONFIG_12_W, board_posn);
// Select this board as first in readout chain if it is board =0 or 4
    if ((board_posn==0) || (board_posn==4)) {
        write_FPGA (CONFIG_0_RW, CONFIG_0_FIRSTR);    // Configure FPGA readout First board in chain
    } // End if this is first board in chain

}

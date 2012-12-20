// $Id$
/* TCPU-C_SPI.c
** Version for build TCPU-C_2A
** This file defines routines for SPI access to EEPROM #2
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
**    27-Aug-2008, W. Burton
**        Remove references to TDIG where appropriate.
**    20-Jun-2008, W. Burton
**        Add missing function prototype spin() and clean up unused variables
**    04-May-2007, W. Burton
**        Add MSbit-LSbit and LSbit-MSbit options to write and read.
**        Added new local functions for get and put byte to SPI
**    NOTE: Instructions and Addresses are always sent MS bit FIRST
**    30-Apr-2007, W. Burton
**        Add spi_write_wait() routine
**    22-Apr-2007, W. Burton
**        Extensive rewrite and consolidation of routines.  Added routines
**        spi_read_adr(), spi_read(), spi_write_adr(), spi_write().
** Written:
**    3-Feb-2007, W. Burton
**    Moved routine spi_readid() from main tdig program.
**      parameterized instruction.
*/

    #include "TCPU-C_SPI.h"

void spin(unsigned int);

/* Local routines */
void spi_put_m2l (unsigned int byte);   // send byte MS bit to LS bit
void spi_put_l2m (unsigned int byte);  // send byte LS bit to MS bit
unsigned char spi_get_m2l (void);       // read byte MS bit to LS bit
unsigned char spi_get_l2m (void);       // read byte LS bit to MS bit


void spi_read_adr ( unsigned int instrn, unsigned char *ap, unsigned int dir, unsigned int bplim, unsigned char *bp) {
/* Do an SPI read sequence with address.
**      Call with:
**          instrn = unsigned int Instruction (Read Bytes, Read Status, Read ID, etc)
**          ap = POINTER to Address to read from, must be at least 3 bytes; bytes are sent [2][1][0].
**          dir = unsigned int Direction of read (0=LS2MSBIT =0= transfer is LSBit to MSBit,
**                  else MS2LSBIT goes MSBit to LSBit).  Symbolic names are in TCPU-C_SPI.h
**                NOTE: Instructions and Addresses are always sent MS bit FIRST
**          bplim = unsigned int byte limit (size) of return buffer.
**          *bp = pointer to unsigned char buffer to receive return data
**      NOTE: Certain instructions require 3 bytes of address OR 3 "dummy" bytes.
**          This routine sends the contents of the 3 LSBytes of address.
**          For Instruction-Only Reads, use routine spi_read().
*/
// Set port directions (Din IN, Clk OUT, Dout OUT, nCS OUT, EE2 Select OUT)
// This was done back at the beginning (after Initialize_OSC())
    unsigned char *rp;      // pointer to return area
    unsigned char *wp;      // working pointer
//    unsigned int i, j;
    unsigned int k;
    wp = ap;                // point to MSByte of address field
    wp += 2;
    rp = bp;

// Lower CS
    clr_EENCS;
// Lower CLK
    clr_EECLK
// {Put Instruction out MS-bit first, toggle clock} x8
    spi_put_m2l (instrn);   // send MSbit to LSbit
//    j = instrn;
//    for (i=0; i<8; i++) {       // loop over bits in instruction
//        MCU_EE_ASDO = (j & 0x80)==0x80 ? 1: 0;  // put out the instruction bit
//        j <<= 1;  // move to next bit
//        str_EECLK;      // strobe the clock
//    } // end loop over instruction bits

// Put out 3 bytes of Address, MS-bit first
    for (k = 0; k<3; k++) {
//        for (i=0; i<8; i++) {       // loop over bits in address byte
//            MCU_EE_ASDO = (j & 0x80)==0x80 ? 1: 0;  // put out the address bit
//            j <<= 1;  // move to next bit
//            str_EECLK;      // strobe the clock
//        } // end loop over address bits
        spi_put_m2l ((*wp));        // put out address byte
        wp--;   // step down to next address bytes
    } // end loop over instruction Bytes

// Read requested length number of bytes (bplim) from input
// Store result in array at location pointed to by rp.
    if (bplim != 0) {
        if (dir == MS2LSBIT) {
            for (k = 0; k<bplim; k++) {
//                i = 8;
//                j = 0;
//// Read MSbit to LSbit of Din (MSbit of Mfr ID)
//                do {
//                    j <<= 1;
//                    j |= MCU_EE_DATA;  // Read the data bit and put away
//                    str_EECLK;  // strobe the clock
//                } while (--i != 0); // end loop over reply bits
//                *rp = (unsigned char)j;
                *rp = spi_get_m2l ();
                rp++;
            } // end loop over reply bytes (MS to LS)
        } else if (dir == LS2MSBIT) {
            for (k = 0; k<bplim; k++) {
                *rp = spi_get_l2m ();
                rp++;
            } // end loop over reply bytes (MS to LS)
        } // end else if (dir == LS2MSBIT)
    } // end if desire something to return
// Raise CS
    set_EENCS;
}

void spi_read ( unsigned int instrn, unsigned int dir, unsigned int bplim, unsigned char *bp) {
/* Do an SPI read sequence withOUT address.
**      Call with:
**          instrn = unsigned int Instruction (Read Bytes, Read Status, Read ID, etc)
**          dir = unsigned int Direction of read (0=LS2MSBIT =0= transfer is LSBit to MSBit,
**                  else MS2LSBIT goes MSBit to LSBit).  Symbolic names are in TCPU-C_SPI.h
**                NOTE: Instructions and Addresses are always sent MS bit FIRST
**          bplim = unsigned int byte limit (size) of return buffer.
**          *bp = pointer to unsigned char buffer to receive return data
**      NOTE: Certain instructions require 3 bytes of address OR 3 "dummy" bytes.
**          This routine DOES NOT send those address/dummy bytes.
**          For Address-based reads, use routine spi_read_adr().
*/
// Set port directions (Din IN, Clk OUT, Dout OUT, nCS OUT, EE2 Select OUT)
// This was done back at the beginning (after Initialize_OSC())
    unsigned char *rp;      // pointer to return area
//    unsigned int i, j, k;
    unsigned int k;
    rp = bp;

// Lower CS
    clr_EENCS;
// Lower CLK
    clr_EECLK
// {Put Instruction out MS-bit first, toggle clock} x8
    spi_put_m2l (instrn);
//    j = instrn;
//    for (i=0; i<8; i++) {       // loop over bits in instruction
//        MCU_EE_ASDO = (j & 0x80)==0x80 ? 1: 0;  // put out the instruction bit
//        j <<= 1;  // move to next bit
//        str_EECLK;      // strobe the clock
//    } // end loop over instruction bits

// Read the requested number of bytes (bplim) from input,
// store results in array pointed to by bp
    if (bplim != 0) {
        if (dir == MS2LSBIT) {
            for (k = 0; k<bplim; k++) {
//                i = 8;
//                j = 0;
// Read MSbit to LSbit of Din (MSbit of Mfr ID)
//                do {
//                    j <<= 1;
//                    j |= MCU_EE_DATA;  // Read the data bit and put away
//                    str_EECLK;  // strobe the clock
//                } while (--i != 0); // end loop over reply bits
//                *rp = (unsigned char)j;     // Return the byte
                *rp = spi_get_m2l();     // Return the byte
                rp++;                       // point to the next
            } // end loop over reply bytes
        } else if (dir == LS2MSBIT) {
            for (k = 0; k<bplim; k++) {
// Read LSbit to MSbit of Din (MSbit of Mfr ID)
                *rp = spi_get_l2m();     // Return the byte
                rp++;                       // point to the next
            } // end loop over reply bytes
        } // end else if dir
    } // end if have something to return
// Raise CS
    set_EENCS;
}

void spi_write_adr ( unsigned int instrn, unsigned char *ap, unsigned int dir, unsigned int bplim, unsigned char *bp) {
/* Do an SPI write sequence with address.
**      Call with:
**          instrn = unsigned int Instruction (Write Bytes, Write Status, etc)
**          ap = POINTER to Address (within chip) to write to, must be at least 3 bytes; bytes are sent [2][1][0].
**               For some Write instructions, these are "dummy" bytes; but they still must be specified here.
**          dir = unsigned int Direction of read (0=LS2MSBIT =0= transfer is LSBit to MSBit,
**                  else MS2LSBIT goes MSBit to LSBit).  Symbolic names are in TCPU-C_SPI.h
**                NOTE: Instructions and Addresses are always sent MS bit FIRST
**          bplim = unsigned int byte limit (size) of source buffer (number of bytes to be written).
**               May be zero if no data is to be transferred (the Instruction and Address/Dummy are still sent).
**          *bp = pointer to unsigned char buffer holding data to be written.  Data from this array is written LSByte first,
**                MSBit first.
**      NOTE: Certain write instructions require 3 bytes of address OR 3 "dummy" bytes.
**          This routine sends the contents of the 3 LSBytes of address.
**          For Instruction-Only writes, use routine spi_write().
*/
// Set port directions (Din IN, Clk OUT, Dout OUT, nCS OUT, EE2 Select OUT)
// This was done back at the beginning (after Initialize_OSC())
//    unsigned char *rp;      // pointer to source area
    unsigned char *wp;      // working pointer
    unsigned int j, k;

    wp = ap;            // point to MSByte of address field
    wp += 2;

// Lower CS
    clr_EENCS;
// Lower CLK
    clr_EECLK
// {Put Instruction out MS-bit first, toggle clock} x8
    spi_put_m2l (instrn);
//    j = instrn;
//    for (i=0; i<8; i++) {       // loop over bits in instruction
//        MCU_EE_ASDO = (j & 0x80)==0x80 ? 1: 0;  // put out the instruction bit
//        j <<= 1;  // move to next bit
//        str_EECLK;      // strobe the clock
//    } // end loop over instruction bits

// Put out 3 bytes of Address
    for (k = 0; k<3; k++) {
        j = (*wp); // pick up address byte
        wp--;   // step down to next address bytes
        spi_put_m2l (j);    // send address
//        for (i=0; i<8; i++) {       // loop over bits in address byte
//            MCU_EE_ASDO = (j & 0x80)==0x80 ? 1: 0;  // put out the address bit
//            j <<= 1;  // move to next bit
//            str_EECLK;      // strobe the clock
//        } // end loop over instruction bits
    } // end loop over address Bytes

// Write requested length number of bytes (bplim) from array at location pointed to by wp.
    if (bplim != 0) {
        wp = bp;
        if (dir == MS2LSBIT) {
            for (k = 0; k<bplim; k++) {
                j = *wp;
// Write MSbit to LSbit to Dout
                spi_put_m2l (j);
//                i = 8;
//                do {
//                    MCU_EE_ASDO = (j & 0x80)==0x80 ? 1: 0;  // put out the data bit
//                    j <<= 1;                // step to next bit
//                    str_EECLK;  // strobe the clock
//                } while (--i != 0); // end loop over send bits
                wp++;
            } // end loop over source bytes
        } else if (dir == LS2MSBIT) {
// Write LSbit to MSbit to Dout
            for (k = 0; k<bplim; k++) {
                j = *wp;
                spi_put_l2m (j);
                wp++;
            } // end loop over source bytes
        } // end else if dir
    } // end if have something to write
// Raise CS
    set_EENCS;
}

void spi_write ( unsigned int instrn, unsigned int dir, unsigned int bplim, unsigned char *bp) {
/* Do an SPI write sequence withOUT address.
**      Call with:
**          instrn = unsigned int Instruction (Write Bytes, Write Status, etc)
**          dir = unsigned int Direction of read (0=LS2MSBIT =0= transfer is LSBit to MSBit,
**                  else MS2LSBIT goes MSBit to LSBit).  Symbolic names are in TCPU-C_SPI.h
**                NOTE: Instructions and Addresses are always sent MS bit FIRST
**          bplim = unsigned int byte limit (size) of number of bytes to write.
**              May be zero, in which case only the instruction is written.
**          *bp = pointer to unsigned char buffer to receive return data
**      NOTE: Certain instructions require 3 bytes of address OR 3 "dummy" bytes.
**          This routine DOES NOT send those address/dummy bytes.
**          For Address-based writes, use routine spi_write_adr().
*/
// Set port directions (Din IN, Clk OUT, Dout OUT, nCS OUT, EE2 Select OUT)
// This was done back at the beginning (after Initialize_OSC())
    unsigned char *wp;      // working pointer for send
    unsigned int k;

// Lower CS
    clr_EENCS;
// Lower CLK
    clr_EECLK
// {Put Instruction out MS-bit first, toggle clock} x8
    spi_put_m2l (instrn);
//    j = instrn;
//    for (i=0; i<8; i++) {       // loop over bits in instruction
//        MCU_EE_ASDO = (j & 0x80)==0x80 ? 1: 0;  // put out the instruction bit
//        j <<= 1;  // move to next bit
//        str_EECLK;      // strobe the clock
//    } // end loop over instruction bits

// Write the requested number of bytes (bplim) from buffer array pointed to by bp
    if (bplim != 0) {
        wp = bp;
        if (dir == MS2LSBIT) {
            for (k = 0; k<bplim; k++) {
                spi_put_m2l ((*wp));
//                i = 8;
//// Write MSbit to LSbit of Din (MSbit of Mfr ID)
//                do {
//                    MCU_EE_ASDO = (j & 0x80)==0x80 ? 1: 0;  // put out the data bit
//                    j <<= 1;                // step to next bit
//                    str_EECLK;  // strobe the clock
//                } while (--i != 0); // end loop over reply bits
                wp++;                       // point to the next
            } // end loop over source bytes
        } else if (dir == LS2MSBIT) {
            for (k = 0; k<bplim; k++) {
                spi_put_l2m ((*wp));
                wp++;                       // point to the next
            } // end loop over source bytes
        } // end else if dir
    } // end if have something to send
// Raise CS to deactivate the chip
    set_EENCS;
}

void spi_wait (unsigned int spireg, unsigned int busybit) {
/* this routine is called to wait for the Write Busy bit to become clear.
** It performs repeated reads of the SPI status register address spireg and checks to see if bit busybit becomes clear.
** Call with:
**  spireg = SPI register (Status Register)
**  busybit = bit which needs to become clear; test is (spireg) & busybit != 0;
*/
    unsigned char wbuf;
    wbuf = busybit;
    while ((wbuf & busybit) != 0) {
        spin(0);
        spi_read (spireg, MS2LSBIT, 1, &wbuf);
    }   // end waiting for erase to go on
}

void spi_put_m2l (unsigned int byte) {
/* transmit an 8-bit byte MS bit to LS bit out the SPI port
** The CS, CLK, and directions must already have been setup.
*/
    unsigned int i=8;
    unsigned int j;
    j = (unsigned int)byte; // pick up the byte to send
    do {      // loop over bits in byte
        MCU_EE_ASDO = (j & 0x80)==0x80 ? 1: 0;  // put out the high bit
        j <<= 1;  // move to next bit
        str_EECLK;      // strobe the clock
    } while (--i != 0);// end loop over 8 bits
}

void spi_put_l2m (unsigned int byte) {
/* transmit an 8-bit byte LS bit to MS bit out the SPI port
** The CS, CLK, and directions must already have been setup.
*/
    unsigned int i=8;
    unsigned int j;
    j = (unsigned int)byte; // pick up the byte to send
    do {
        MCU_EE_ASDO = (j & 0x1); // put out the low bit
        j >>= 1;  // move to next bit
        str_EECLK;      // strobe the clock
    } while (--i != 0); // end loop over 8 bits
}

unsigned char spi_get_m2l (void) {
/* retrieve and return an 8-bit byte MS bit to LS bit from the SPI port
** The CS, CLK, and directions must already have been setup.
*/
    unsigned int i=8;       // 8 bits
    unsigned int j=0;       // initial return value
// Read MSbit to LSbit of Din
    do {
        j <<= 1;
        j |= MCU_EE_DATA;  // Read the data bit and put away
        str_EECLK;  // strobe the clock
    } while (--i != 0); // end loop over reply bits
    return ((unsigned char)j);
}

unsigned char spi_get_l2m (void) {
/* retrieve and return an 8-bit byte LS bit to MS bit from the SPI port
** The CS, CLK, and directions must already have been setup.
*/
    unsigned int i=1;       // bitmask
    unsigned int j=0;       // initial return value
// Read LSbit to MSbit of Din
    do {
        if (MCU_EE_DATA) {
            j |= i;
        } // end if need to set bit
        str_EECLK;  // strobe the clock
        i <<= 1;
    } while ((i & 0x100) == 0); // end loop over reply bits (until bitmask shifted out of byte)
    return ((unsigned char)j);
}

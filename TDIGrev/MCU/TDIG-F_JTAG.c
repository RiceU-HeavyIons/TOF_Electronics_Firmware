// $Id: TDIG-F_JTAG.c,v 1.4 2008-07-23 16:38:53 jschamba Exp $

/* TDIG-F_JTAG.c
** This file defines the TDIG-F routines and interfaces for JTAG interface to the TDIG chips.
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
**  26-Jun-2008, W. Burton
**      Add include for FPGA interface (TDIG-F_MCU_PLD.h)
**      Remove definition of unused variables (warned by compiler)
**      Fix unclosed nested comment.
**  13-Oct-2007, W. Burton
**      Be sure TAP is reset when starting and ending functions.
**  12-Sep-2007, W. Burton
**      Rework HPTDC reset sequence.
**  10-Sep-2007, W. Burton
**      Conditional REVISEDRESET for reset sequence from Jo Schambach
**  08-Sep-2007, W. Burton
**      Updated filenames for RevF boards
**  29-Jun-2007, W. Burton
**      Updated include file processing.
**  15-May-2007, W. Burton
**      Added routine control_hptdc();
**  29-Mar-2007, W. Burton
**      Moved routines into here from TDIG-D_Ver11A.c
**          read_hptdc_id()
**          select_hptdc()
** Written: 13-Dec-2006, W. Burton
**              Based on assembly code from Justin Kennington's PIC18F implementation.
*/
    #include "TDIG-F_Board.h"
    #include "TDIG-F_JTAG.h"
    #include "TDIG-F_MCU_PLD.h"
    #include "stddef.h"         // Standard definitions
    #include "string.h"

 #define REVISEDRESET 1
#if defined (REVISEDRESET)      // Jo Schambach sequence
    static unsigned char reset_all    [J_HPTDC_CONTROLBYTES] = {0x04, 0x00, 0x00, 0x00, 0xE0}; // 1st control
    static unsigned char lock_pll     [J_HPTDC_CONTROLBYTES] = {0x04, 0x00, 0x00, 0x00, 0x20}; // 2nd control
    static unsigned char lock_dll     [J_HPTDC_CONTROLBYTES] = {0x04, 0x00, 0x00, 0x00, 0x80}; // 3rd control
    static unsigned char global_reset [J_HPTDC_CONTROLBYTES] = {0x14, 0x00, 0x00, 0x00, 0x00}; // 4th control
//    static unsigned char enable_all   [J_HPTDC_CONTROLBYTES] = {0xE4, 0xFF, 0xFF, 0xFF, 0x9F}; // final control
#else
    static unsigned char global_reset [J_HPTDC_CONTROLBYTES] = {0x14, 0x00, 0x00, 0x00, 0x00};
    static unsigned char lock_pll     [J_HPTDC_CONTROLBYTES] = {0x04, 0x00, 0x00, 0x00, 0x40};
    static unsigned char lock_dll     [J_HPTDC_CONTROLBYTES] = {0x04, 0x00, 0x00, 0x00, 0x20};
    static unsigned char enable_one   [J_HPTDC_CONTROLBYTES] = {0x44, 0x00, 0x00, 0x00, 0x00};
    static unsigned char reset_all    [J_HPTDC_CONTROLBYTES] = {0xE4, 0xFF, 0xFF, 0xFF, 0xFF};
    static unsigned char enable_all   [J_HPTDC_CONTROLBYTES] = {0xE4, 0xFF, 0xFF, 0xFF, 0x9F};
#endif

void spin(int cycle);       // delay via do-nothing loop (defined in TDIG-F.c)

void control_hptdc (unsigned int tdcnbr, unsigned char *ctrl);

void read_hptdc_id (unsigned int tdcnbr, unsigned char *rp, unsigned int bufsize){
/* Read the HPTDC ID string via JTAG
** See HPTDC Manual Version 2.2, Section 17.4, page 30.
** Call with:
**      nbr = number of the HPTDC to read (1 to 3)
**      rp = pointer to unsigned character array to receive ID string
**      bufsize = size of the array (must be at least 4 bytes)
*/
    if ((tdcnbr > 0) && (tdcnbr <= NBR_HPTDCS) && (bufsize >= 4)) {
        memset (rp, 0, bufsize);   // clear before reading
        select_hptdc(JTAG_MCU, tdcnbr);     // select MCU and which HPTDC
        reset_TAP();
        IRScan ((unsigned char)J_HPTDC_IDCODE);       // 0x11 = parity+IDCODE instruction
        DRScan (rp, J_HPTDC_IDBITS, J_RETURN_DATA, rp);
        reset_TAP();
        select_hptdc(JTAG_HDR, tdcnbr);     // select JTAG header and which HPTDC
    } // end if have enough space
// ----- end of read_hptdc_id()
}

void read_hptdc_status (unsigned int tdcnbr, unsigned char *rp, unsigned int bufsize){
/* Read the HPTDC Status using the JTAG port
** See HPTDC Manual Version 2.2, Section 17.7, page 38.
** Call with:
**     tdcnbr = tdc number to access (1 to NBR_HPTDCS)
**     rp = pointer to array to receive status string (byte[0]..[bufsize-1])
**     bufsize = number of bytes in return array (at least 8)
*/
    if (bufsize >= 8) {
        memset (rp, 0, bufsize);
        if ((tdcnbr >= 1) && tdcnbr <= NBR_HPTDCS) {
            select_hptdc(JTAG_MCU, tdcnbr);        // select MCU and which HPTDC
            reset_TAP();
            IRScan ((unsigned char)J_HPTDC_STATUS);       // 0x0A = parity + status instruction
            DRScan (rp, J_HPTDC_STATUSBITS, J_RETURN_DATA, rp); // rp on sending is all zero
            reset_TAP();
            select_hptdc(JTAG_HDR, tdcnbr);        // select FPGA and which HPTDC
        } // end if tdcnbr is OK
    } // end if valid return buffer size
// ----- end of routine read_hptdc_status()
}



void control_hptdc(unsigned int tdcnbr, unsigned char *ctrl) {
/* Send the 40-bit control sequence to a tdc
** call with:
**   tdcnbr = number of the hptdc to do (1 to NBR_HPTDCS)
**   ctrl = pointer to control string (40-bit control word, page 37 of HPTDC manual)
*/
    if ((tdcnbr > 0) && (tdcnbr<= NBR_HPTDCS)) {
        select_hptdc(JTAG_MCU, tdcnbr);        // select MCU controlling which HPTDC
        reset_TAP();
        // Put out control string (40 bits)
        IRScan ((unsigned char)J_HPTDC_CONTROL);       // parity+CONTROL instruction
        DRScan (ctrl, J_HPTDC_CONTROLBITS, J_NORETURN_DATA, (unsigned char *)NULL);
        spin(1);
        // Done with JTAG
        reset_TAP();
        select_hptdc(JTAG_HDR, tdcnbr);        // select FPGA and which HPTDC
    } // end if valid HPTDC number
// -----  end of routine control_hptdc()
}


void select_hptdc(unsigned int ifmcu, unsigned int whichhptdc) {
/* this routine selects which HPTDC chip (1, 2, or 3) is to be acted on by JTAG
** ifmcu determines whether the MCU (ifmcu != 0) or
**                          the Jumpers (ifmcu = 0 = JTAG_HDR) are doing the selection
*/
    unsigned int regval;
    regval = whichhptdc & CONFIG_1_TDCMASK; // mask for valid selections, assume not MCU
    if (ifmcu == JTAG_MCU) {
        regval |= CONFIG_1_MCUJTAG;              // need to set MCU in control
    } // end if need to set MCU in control
    write_FPGA (CONFIG_1_RW, regval);
// ----- end select_hptdc()
}

void reset_hptdc(unsigned int tdcnbr, unsigned char *finalctrl) {
/* do the hptdc reset sequence using the JTAG interface
** call with:
**   tdcnbr = number of the hptdc to do (1 to NBR_HPTDCS)
**   finalctrl = pointer to final control string (40-bit control word, page 37 of HPTDC manual)
*/
#if defined (REVISEDRESET)
    if ((tdcnbr > 0) && (tdcnbr<= NBR_HPTDCS) ) {
        // Send first RESET word
        control_hptdc ( tdcnbr, (unsigned char *)&reset_all);
        spin(1);
        // Send second RESET word
        control_hptdc ( tdcnbr, (unsigned char *)&lock_pll);
        spin(1);
        // Send third RESET word
        control_hptdc ( tdcnbr, (unsigned char *)&lock_dll);
        spin(1);
        //Send fourth RESET word
        control_hptdc ( tdcnbr, (unsigned char *)&global_reset);
        spin(1);
        // Send final control word
        control_hptdc ( tdcnbr, finalctrl);
        spin(0);

        select_hptdc(JTAG_HDR, tdcnbr);        // select FPGA and which HPTDC
     } // end if valid HPTDC number
// -----  end of routine reset_hptdc()
#else
    if ((tdcnbr > 0) && (tdcnbr<= NBR_HPTDCS)) {
        select_hptdc(JTAG_MCU, tdcnbr);        // select MCU controlling which HPTDC
        reset_TAP();
        // use JTAG - SET Global Reset
        IRScan ((unsigned char)J_HPTDC_CONTROL);       // parity+CONTROL instruction
        spin(0);
        DRScan ((unsigned char *)&global_reset, J_HPTDC_CONTROLBITS, J_NORETURN_DATA, (unsigned char *)NULL);
        spin(0);
        // use JTAG - CLEAR Global Reset, ENABLE ALL
        IRScan ((unsigned char)J_HPTDC_CONTROL);       // parity+CONTROL instruction
        spin(0);
        DRScan ((unsigned char *)&enable_all, J_HPTDC_CONTROLBITS, J_NORETURN_DATA, (unsigned char *)NULL);
        spin(0);
        // <enable lock> sequence
        // 1. RESET ALL
        // use JTAG - "reset-all" control string
        IRScan ((unsigned char)J_HPTDC_CONTROL);       // parity+CONTROL instruction
        DRScan ((unsigned char *)&reset_all, J_HPTDC_CONTROLBITS, J_NORETURN_DATA, (unsigned char *)NULL);
        spin(5);
        // 2. LOCK PLL
        // use JTAG - "lock_pll" control string
        IRScan ((unsigned char)J_HPTDC_CONTROL);       // parity+CONTROL instruction
        DRScan ((unsigned char *)&lock_pll, J_HPTDC_CONTROLBITS, J_NORETURN_DATA, (unsigned char *)NULL);
        spin(5);
        // 3. LOCK DLL
        // use JTAG - "lock_dll" control string
        IRScan ((unsigned char)J_HPTDC_CONTROL);       // parity+CONTROL instruction
        DRScan ((unsigned char *)&lock_dll, J_HPTDC_CONTROLBITS, J_NORETURN_DATA, (unsigned char *)NULL);
        spin(1);
        // 4. GLOBAL_RESET
        // use JTAG - "global_reset" control string
        IRScan ((unsigned char)J_HPTDC_CONTROL);       // parity+CONTROL instruction
        DRScan ((unsigned char *)&global_reset, J_HPTDC_CONTROLBITS, J_NORETURN_DATA, (unsigned char *)NULL);
        spin(1);
        // 5. Put out "Final" control string (40 bits)
        // use JTAG - "enable_one" control string
        IRScan ((unsigned char)J_HPTDC_CONTROL);       // parity+CONTROL instruction
        DRScan (finalctrl, J_HPTDC_CONTROLBITS, J_NORETURN_DATA, (unsigned char *)NULL);
        spin(1);
        // Done with JTAG
        reset_TAP();
        select_hptdc(JTAG_HDR, tdcnbr);        // select FPGA and which HPTDC
     } // end if valid HPTDC number
#endif
}

void reset_TAP (void) {         // Reset the JTAG TAP
	clr_TCK;					// Make sure to start w/ TCK low.
    set_TMS;
    str_TCK;
	str_TCK;
	str_TCK;
	str_TCK;
	str_TCK;
//	str_TCK;    // 13-Oct-07 Extra
//  clr_TMS;    // 13-Oct-07 Testing
// -----  end reset_TAP()
}

/*  -----  IRScan()  in file JTAG_functions.asm  ------------------------------
** This subroutine performs JTAG IR-Scan.
** It assumes that the TAP controller starts in the Run-Test/Idle state.
** It will also return the TAP controller to the Run-Test/Idle state when
** finished.
** It moves the bits onto TDI LSbit-first, and assumes a 5-bit instruction word
** (including parity)
** Converted from JTAG_functions.asm 13-Dec-2006, W. Burton
*/
void IRScan (unsigned char instruction) {
    unsigned char workins;
    unsigned int i;
    workins = instruction; // save a copy of the instruction word
    reset_TAP();    // reset the TAP before IRscan (move to Test-Logic-Reset)
    clr_TMS;        // TMS = 0
    str_TCK;        // TAP controller moves to Run-Test-Idle
    str_TCK;        // Extra tick in RT/I inserted to match Jam 9/6/2004
    set_TMS;        // TMS = 1
    str_TCK;        // TAP controller moves to Select-DR-Scan
    str_TCK;        // TMS still 1, TAP controller moves to Select-IR-Scan
    clr_TMS;        // TMS = 0
    str_TCK;        // TAP controller moves to Capture-IR
    str_TCK;        // TAP controller moves to Shift-IR
	for (i=0; i<(J_HPTDC_IRBITS-1); i++) {
    	MCU_TDC_TDI = (workins & 0x1);    // put out lowest bit of instruction
		__asm__ volatile ("nop");
		str_TCK;
    	clr_TDI;        // clear TDI just in case.
		workins >>= 1;	// shift to next bit of instruction
	} // end for loop over bits-1
   	MCU_TDC_TDI = workins & 0x1;    // put out last bit of instruction
	__asm__ volatile ("nop");
    set_TMS;        // TMS = 1 on last bit
    str_TCK;        // last bit and TAP to Exit1-IR
    clr_TMS;        // TMS = 0
    clr_TDI;        // clear TDI just in case.
                    // Added to match JAM 9/6/2004
    str_TCK;        // TAP to Pause-IR
    set_TMS;        // TMS = 1
    str_TCK;        // TAP to Exit2-IR
    str_TCK;        // TAP to Update-IR
    clr_TMS;        // TMS = 0
    str_TCK;        // TAP to Run-Test/Idle
    str_TCK;        // 2
// -----  end IRSCAN()
}


void DRScan (unsigned char *sndbuf, unsigned int dsize, unsigned int read_into, unsigned char *retbuf) {
/* -----  DRScan() in file JTAG_functions.asm  -------------------------------
** This subroutine performs JTAG DR-Scan.
** It uses the value in dsize to determine how many bits to shift in/out.
** It assumes the TAP controller is in Run-Test/Idle state, and returns to that state when finished.
** If dsize = 0 when called this routine will return having done nothing.
** Before calling DRScan, set *sndbuf to point to the memory location of the MSB of the
** data you want to shift (*sndbuf)
** If you wish to KEEP the data scanned through TDO, set read_into to non-zero and
** set retbuf to the address of the desired location of the LSB, and the data
** will be stored from that address through following addresses (just like
** config data is stored). (*retbuf)
** Set read_into to 0 to throw out inbound data (otherwise data pointed at by
** *retbuf WILL be overwritten)
** Bits are shifted out/in from LSByte [bit0, bit 1...bit7] then next byte bit 0...
** Converted from drscan() in file JTAG_functions.asm 13-Dec-06, W. Burton
*/
    unsigned char retbyte=0;
	unsigned char sendbyte;
    unsigned char *rp;
    unsigned char *sp;
    unsigned int bitcount;
    unsigned int i;
//    unsigned int mcu_tdo;
    if (dsize != 0) {
        bitcount=dsize;     // number of bits to process
		sp = sndbuf;		// point to source location
		sendbyte = *sp++;	// sendbyte is currently-sending
        rp = retbuf;        // point to return location
							// retbyte is currently-receiving
        clr_TMS;
        str_TCK;                        //  TAP controller to Run-Test-Idle
        str_TCK;                        //  TAP controller to Run-Test-Idle
        str_TCK;                        //  TAP controller to Run-Test-Idle
        set_TMS;                        //  TMS = 1
        str_TCK;                        //  TAP controller moves to Select-DR-Scan
        clr_TMS;                        //  TMS = 0
        str_TCK;                        //  TAP controller moves to Capture-DR
        str_TCK;                        //  TAP controller moves to Capture-DR
                                        // brings out bit 0 to TDO
		i = 0;
        for (bitcount=(dsize-1); bitcount != 0; bitcount--) {
// Loop over bits in a byte
            retbyte |= (MCU_TDC_TDO<<i);       // save the bit to the correct location
            i++;
			MCU_TDC_TDI = (sendbyte&0x1); // put bit onto TDI
			sendbyte >>= 1;				// move to next bit
			str_TCK;                    // TAP controller stays-in Shift-DR
            if (i==8) {					// if have sent a whole byte
                *rp = (unsigned char)retbyte;	// return it
                rp++;					// point to next retn location
                retbyte = 0;			// initialize return value
				i = 0;					// initialiize counter
				sendbyte = *sp++;		// pick up next byte
            } // end if need to move to next byte
        } // end loop over bits requested
        retbyte |= (MCU_TDC_TDO<<i);       // save the bit to the correct location
        i++;
		MCU_TDC_TDI = (sendbyte&0x1); // put last bit onto TDI
        if (i!= 0) *rp = retbyte;	// if have any bits in
		set_TMS;
        str_TCK;       // TCK = 1, 0. TAP -> Exit1-DR
        clr_TMS;       // TMS = 0
        str_TCK;       // TAP to Pause-DR
        set_TMS;       // TMS = 1
        clr_TDI;       // TDI = 0
        str_TCK;       // TAP to Exit2-DR
        str_TCK;       // TAP to Update-DR
        clr_TMS;       // TMS = 0
        str_TCK;       // TAP to Run-test/Idle
    } // end if dsize was not zero
// -----  end DRSCAN()
}

void insert_parity (unsigned char *bitsbuf, unsigned int nbits)
{
/* This routine scans the buffer from [0] to [nbits-2] places a bit at
** location [nbits-1] (C-style array indexing) such that parity will be
** EVEN (even # of 1-bits total)
** bit ordering is such that bit 2^0 of bitsbuf[0] is the first bit examined.
** The parity bit will be stored at bitsbuf[(nbits-1)/8] bit 2^rem(nbits-1,8)
** If nbits is <= 1, nothing happens
*/
    unsigned char *bp;
	unsigned int todo;
	unsigned int i=8;
	unsigned int partial=0;
	unsigned int p2=0;
	unsigned int offset;
//    unsigned int work;

	if (nbits > 1) {
		bp = bitsbuf;
        todo = (nbits-1)&0x7;   // trim to 0..7 for remainder
/* Make a bytewise scan of full bytes */
		while (i<=nbits-1) {
			partial ^= *bp;
			bp++;
			i += 8;
		} // end while
/* now scan the bytewise partial */
		for (i=0; i<8; i++) {
			p2 += partial;	// we are just interested in 1 bit
			partial >>=1;   // so move each one down.
		} // end
		if (todo != 0) {
			partial = (unsigned int)*bp;
			for (i=0; i<todo; i++) {
				p2 += partial;
				partial >>= 1;
			} // end loop over loose bits at end
		} // end if have some loose bits at end
		offset = 1<<((nbits-1)&0x7);
		offset = ~offset;
		bp = bitsbuf + ((nbits-1)>>3);
		*bp = *bp & offset;
		offset = (p2&0x1)<<((nbits-1)&0x7);
		*bp = *bp | offset;
	} // end if have something to do
// ----- end of routine insert_parity()
}

    void write_hptdc_setup (unsigned int tdcnbr, unsigned char *configptr, unsigned char *retcfgptr)
{
/* This routine uses the JTAG interface through the FPGA to the HPTDC chips "Setup" registers
** See HPTDC Manual Version 2.2, Section 17.5, pages 30-37.
** call with:
**     tdcnbr = the HPTDC number (1 to NBR_HPTDCS)
**     configptr = pointer to the array containing J_HPTDC_SETUPBITS number of configuration bits (point to LSByte of
**                 LSword, i.e. location of bit[0])
**     retcfgptr = pointer to the array to receive J_HPTDC_SETUPBITS number of configuration bits read back from HPTDC chip
**                 (point to LSByte of LSword, i.e. location of bit[0])
*/
/* Configure the HPTDCs */
    if ((tdcnbr > 0) && (tdcnbr<= NBR_HPTDCS)) {
        select_hptdc(JTAG_MCU, tdcnbr);        // select MCU controlling which HPTDC
        // use JTAG - IRSCAN the SETUP instruction
        IRScan ((unsigned char)J_HPTDC_SETUP);       // parity+SETUP instruction
        // use JTAG - DRSCAN the SETUP data (initial load)
        DRScan (configptr, J_HPTDC_SETUPBITS, J_NORETURN_DATA, retcfgptr);
        // use JTAG - IRSCAN the SETUP instruction
        IRScan ((unsigned char)J_HPTDC_SETUP);       // parity+SETUP instruction
        // use JTAG - DRSCAN to Re-output initialization while reading back initial load
        DRScan (configptr, J_HPTDC_SETUPBITS, J_RETURN_DATA, retcfgptr);
        // Done with JTAG
        reset_TAP();
        select_hptdc(JTAG_HDR, tdcnbr);        // select FPGA and which HPTDC
    } // end if valid HPTDC number
// ----- end of routine write_hptdc_setup()
}


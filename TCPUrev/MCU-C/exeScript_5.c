// $Id$

// exeScript.c for 5 TDIGs

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
    unsigned int j=0xFFF;
	unsigned long msg_id;
	unsigned int i, numRcvd;
	//unsigned int k;
	unsigned int val, addr;

	// ***************************************************
	// 1) send the CANbus reboot FPGA message to the TDIGs
	// ***************************************************

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
	*/
    ecan1msgBuf[0][1] = 0;
    ecan1msgBuf[0][2] = 5; // length
	ecan1msgBuf[0][3] = 0x698a; // data[1,0]
	ecan1msgBuf[0][4] = 0xa596; // data[3,2]
	ecan1msgBuf[0][5] = 0x005a; // data[5,4]
	//msg_id = (unsigned int)(0x7F<<6) | C_WRITE; // stick in broadcast ID
   	//ecan1msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit

	numRcvd = 0; // keep track of number of responses
	for (i=0x10; i<0x16; i++) {
		// Don't do 0x13
		if (i==0x13) continue;
 
	    // wait for transmit on CAN1 to complete or timeout
		j = 0xfff;
	    do {--j;} while ((C1TR01CONbits.TXREQ0==1) && (j != 0));
		if (j == 0) return -1; // timed out, don't continue
		msg_id = (unsigned int)(i<<6) | C_WRITE; // TDIG 0x11
    	ecan1msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
    	C1TR01CONbits.TXREQ0=1; // Mark message buffer ready-for-transmit on CAN#1
		j = 0x5fff;	do {--j;} while (j != 0); // idle a little to pace the messages
		// check if we already got a response
		if (C1RXFUL1bits.RXFUL2==1) {
			// send received message as extended message on CAN2
	    	//for (k=0; k<8; k++) ecan2msgBuf[0][k] = ecan1msgBuf[2][k];

    	    C1RXFUL1bits.RXFUL2 = 0;        // mark CAN1 Receive-Buffer 2 OK to re-use
			numRcvd++;

        	//ecan2msgBuf[0][0] |= C_EXT_ID_BIT;    // extended ID =1, no remote xmit
        	//ecan2msgBuf[0][1]  = 0;             // WB-1L this will need to change if C_BOARD is redefined
        	//ecan2msgBuf[0][2] |= (((C_BOARD>>6)|board_id)<<10);   // extended ID<5..0> gets TCPU board_posn
			//j = 0xfff;
	    	//do {--j;} while ((C1TR01CONbits.TXREQ0==1) && (j != 0));
			//if (j == 0) return -1; // timed out, don't continue
        	//C2TR01CONbits.TXREQ0=1;             // Mark message buffer ready-for-transmit on CAN2
		}
	}

	j = 0xffff;	do {--j;} while (j != 0); // idle a little before checking

	// check for responses, expect 5, 
	// but check more than necessary to account for time of responses to come back
	for (i=1; i<12; i++) {
		// once we received 5 responses, we are finished:
		//if (numRcvd == 8) break;
		if (numRcvd == 5) break;
		// now check for response with timeout
		j = 0xffff;
	    do {--j;} while ((C1RXFUL1bits.RXFUL2==0) && (j != 0));
		if (j != 0) {
			// send received message as extended message on CAN2
	    	//for (k=0; k<8; k++) ecan2msgBuf[0][k] = ecan1msgBuf[2][k];

    	    C1RXFUL1bits.RXFUL2 = 0;        // mark CAN1 Receive-Buffer 2 OK to re-use
			numRcvd++;

        	//ecan2msgBuf[0][0] |= C_EXT_ID_BIT;    // extended ID =1, no remote xmit
        	//ecan2msgBuf[0][1]  = 0;             // WB-1L this will need to change if C_BOARD is redefined
        	//ecan2msgBuf[0][2] |= (((C_BOARD>>6)|board_id)<<10);   // extended ID<5..0> gets TCPU board_posn
			//j = 0xffff;
	    	//do {--j;} while ((C1TR01CONbits.TXREQ0==1) && (j != 0));
			//if (j != 0)
	        //	C2TR01CONbits.TXREQ0=1; // Mark message buffer ready-for-transmit on CAN#2
		}
		else {
			// no message received within timeout, send alert on CAN2
			msg_id = (unsigned int)((0x20+board_id)<<6) | C_ALERT;
    		ecan2msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
    		ecan2msgBuf[0][1] = 0;
    		ecan2msgBuf[0][2] = 4; // length
			ecan2msgBuf[0][3] = i; // data[1,0]
			ecan2msgBuf[0][4] = numRcvd | 0xF000; // data[3,2]
			j = 0xffff;
	    	do {--j;} while ((C1TR01CONbits.TXREQ0==1) && (j != 0));
			if (j != 0)
        		C2TR01CONbits.TXREQ0=1; // Mark message buffer ready-for-transmit on CAN2
		}
	}

	// ****************************************************************
	// 2) set threshold on each TDIG to 1200mV
	// threshold = 1200.0;
	// val = (unsigned int)((threshold * 4095.0 / 3300.0 + 0.5) = 0x5D2
	// set threshold command: m s 0xXX2 3 0x08 val&0xff (val>>8)&0xff
	// ****************************************************************
    ecan1msgBuf[0][1] = 0;
    ecan1msgBuf[0][2] = 3; // length
	ecan1msgBuf[0][3] = 0xD208; // data[1,0]
	ecan1msgBuf[0][4] = 0x0005; // data[3,2]

	numRcvd = 0; // keep track of number of responses
	for (i=0x10; i<0x16; i++) { 
		// Don't do 0x13
		if (i==0x13) continue;

	    // wait for transmit on CAN1 to complete or timeout
		j = 0xfff;
	    do {--j;} while ((C1TR01CONbits.TXREQ0==1) && (j != 0));
		if (j == 0) return -1; // timed out, don't continue
		msg_id = (unsigned int)(i<<6) | C_WRITE; // TDIG i write
    	ecan1msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
    	C1TR01CONbits.TXREQ0=1; // Mark message buffer ready-for-transmit on CAN#1
		j = 0x5fff;	do {--j;} while (j != 0); // idle a little to pace the messages
		// check if we already got a response
		if (C1RXFUL1bits.RXFUL2==1) {
    	    C1RXFUL1bits.RXFUL2 = 0;        // mark CAN1 Receive-Buffer 2 OK to re-use
			numRcvd++;
		}
	}

	// check for responses, expect 5, 
	// but check more than necessary to account for time of responses to come back
	for (i=1; i<12; i++) {
		// once we received 5 responses, we are finished:
		if (numRcvd == 5) break;
		// now check for response with timeout
		j = 0xffff;
	    do {--j;} while ((C1RXFUL1bits.RXFUL2==0) && (j != 0));
		if (j != 0) {
    	    C1RXFUL1bits.RXFUL2 = 0;        // mark CAN1 Receive-Buffer 2 OK to re-use
			numRcvd++;
		}
		else {
			// no message received within timeout, send alert on CAN2
			msg_id = (unsigned int)((0x20+board_id)<<6) | C_ALERT;
    		ecan2msgBuf[0][0] = msg_id;  // extended ID =0, no remote xmit
    		ecan2msgBuf[0][1] = 0;
    		ecan2msgBuf[0][2] = 4; // length
			ecan2msgBuf[0][3] = i; // data[1,0]
			ecan2msgBuf[0][4] = numRcvd; // data[3,2]
			j = 0xffff;
	    	do {--j;} while ((C1TR01CONbits.TXREQ0==1) && (j != 0));
			if (j != 0)
        		C2TR01CONbits.TXREQ0=1; // Mark message buffer ready-for-transmit on CAN2
		}
	}

	// ****************************************************
	// 3) write multiplicity gate value to FPGA address 0x8
	// ****************************************************
	addr = 8;
	val = 0xd0; // multiplicity gate value (phase is upper 4 bits)
	write_FPGA(addr, val);

	// ****************************************************
	// 4) reset SerDes Link
	// ****************************************************
	addr = 2;
	val = 0; // FPGA Reg2 = 0
	write_FPGA(addr, val);

	val = 0xf; // FPGA Reg2 = 0xf
	write_FPGA(addr, val);

	// ****************************************************
	// Done!
	// ****************************************************
	return numRcvd;
}

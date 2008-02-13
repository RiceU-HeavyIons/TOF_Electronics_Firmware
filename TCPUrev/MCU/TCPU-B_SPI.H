// $Id: TCPU-B_SPI.H,v 1.1 2008-02-13 17:44:42 jschamba Exp $

/* TCPU-B_SPI.h
** This header file defines the TDIG-D macros and interfaces for SPI interface to EEPROM #2.
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
**      04-May-2007, W. Burton
**          Updated to add MS2LSBIT and direction parameter.
**      22-Apr-2007, W. Burton
**          Modified to reflect new routines in TDIG-D_SPI.c
** Written: 24-Jan-2007, W. Burton
*/
    #include "TCPU-B_Board.h"

// Macros
    #define set_EENCS {MCU_EE_NCS=1;__asm__ volatile ("nop");}
    #define clr_EENCS {MCU_EE_NCS=0;__asm__ volatile ("nop");}
    #define set_EESDO {MCU_EE_ASDO=1;__asm__ volatile ("nop");}
    #define clr_EESDO {MCU_EE_ASDO=0;__asm__ volatile ("nop");}
    #define set_EECLK {MCU_EE_DCLK=1;__asm__ volatile ("nop");}
    #define clr_EECLK {MCU_EE_DCLK=0;__asm__ volatile ("nop");}
    #define str_EECLK {MCU_EE_DCLK=1;__asm__ volatile ("nop");MCU_EE_DCLK=0;__asm__ volatile ("nop");}
    #define sel_EE2 {MCU_SEL_EE2=1;__asm__ volatile ("nop");}
    #define sel_EE1 {MCU_SEL_EE2=0;__asm__ volatile ("nop");}


// Symbolic names for read-direction controls on data bytes "dir" parameter.
// NOTE: Instructions and Addresses are always sent MS bit FIRST
    #define MS2LSBIT    1       // Data read/write direction is MS bit to LS bit in byte.
    #define LS2MSBIT    0       // Data read/write direction is LS bit to MS bit in byte.

// Prototypes for routines
void spi_read_adr ( unsigned int instrn, unsigned char *ap, unsigned int dir, unsigned int bplim, unsigned char *bp);
void spi_read ( unsigned int instrn, unsigned int dir, unsigned int bplim, unsigned char *bp);
void spi_write_adr ( unsigned int instrn, unsigned char *ap, unsigned int dir, unsigned int bplim, unsigned char *bp);
void spi_write ( unsigned int instrn, unsigned int dir, unsigned int bplim, unsigned char *bp);
void spi_wait (unsigned int spiaddr, unsigned int busybit);


// Symbolic names and sizes for ST_Micro instructions (per datasheet ST_m25P20.pdf revision 10)
    #define EE_ST_RDID 0x9F    // Read Identification
    #define EE_ST_RDSR 0x05    // Read Status Register
    #define EE_ST_RDDA 0x03    // Read Data Bytes
    #define EE_ST_RLSI 0xAB    // Release from Deep Power Down, Read Signature
    #define EE_ST_WREN 0x06    // Write Enable

// Symbolic names and sizes for ALTERA EPCS instructions (per Cyclone Device Handbook 2006, pg 4-24)
// send as MSbit-to-LSbit
    #define EE_AL_WREN 0x06    // Write Enable
    #define EE_AL_WRDI 0x04    // Write Disable
    #define EE_AL_RDSR 0x05    // Read Status Register
    #define EE_AL_RDDA 0x03    // Read Data Bytes
    #define EE_AL_RDID 0xAB    // Read Identification
    #define EE_AL_WRST 0x01    // Write Status
    #define EE_AL_WRDA 0x02    // Write Data (Bytes)
    #define EE_AL_ERAB 0xC7    // Erase Bulk
    #define EE_AL_ERAS 0xD8    // Erase Sector
    #define EE_AL_BUSY 0x01     // Status busy (write/erase)
    #define EE_AL_WREN_AL 0    // Length of Write Enable Address
    #define EE_AL_WRDI_AL 0    // Length of Write Disable Address
    #define EE_AL_RDSR_AL 0    // Length of Read Status Register Address
    #define EE_AL_RDDA_AL 3    // Length of Read Data Bytes Address
    #define EE_AL_RDID_AL 3    // Length of Read Identification Address
    #define EE_AL_WRST_AL 0    // Length of Write Status Address
    #define EE_AL_WRDA_AL 3    // Length of Write Data (Bytes) Address
    #define EE_AL_ERAB_AL 0    // Length of Erase Bulk Address
    #define EE_AL_ERAS_AL 3    // Length of Erase Sector Address
    #define EE_AL_WREN_DL 0    // Length of Write Enable Data
    #define EE_AL_WRDI_DL 0    // Length of Write Disable Data
    #define EE_AL_RDSR_DL 1    // Length of Read Status Register Data
    #define EE_AL_RDDA_DL 1    // Length of Read Data Bytes Data
    #define EE_AL_RDID_DL 1    // Length of Read Identification Data
    #define EE_AL_WRST_DL 1    // Length of Write Status Data
    #define EE_AL_WRDA_DL 256  // Length of Write Data (Bytes) Data
    #define EE_AL_ERAB_DL 0    // Length of Erase Bulk Data
    #define EE_AL_ERAS_DL 0    // Length of Erase Sector Data


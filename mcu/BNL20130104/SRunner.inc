; $Id$
;******************************************************************************
;                                                                             *
;    Filename:      SRunner.inc                                               *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:        J. Schambach                                              *
;    Company:                                                                 *
;                                                                             * 
;******************************************************************************

#ifndef __SRUNNER_INC           ;Check if inc file already included
#define __SRUNNER_INC

#ifndef  AS_PRIOR_SOURCE
    EXTERN  asReadSiliconID, asStart, asDone, asBulkErase, asProgram256, asSelect
    EXTERN  asReadCRC_Error

    EXTERN  asOneByte, asAddress, asDataBytes
#endif

AS_WRITE_ENABLE:    =   0x06
AS_WRITE_DISABLE:   =   0x04
AS_READ_STATUS:     =   0x05
AS_WRITE_STATUS:    =   0x01
AS_READ_BYTES:      =   0x03
AS_FAST_READ_BYTES: =   0x0B
AS_PAGE_PROGRAM:    =   0x02
AS_ERASE_SECTOR:    =   0xD8
AS_ERASE_BULK:      =   0xC7
AS_READ_SILICON_ID: =   0xAB


mAsReadSiliconID macro varAddress
    call    asReadSiliconID
    movlw   low(varAddress)
    movwf   FSR0L
    movlw   high(varAddress)
    movwf   FSR0H
    movff   asOneByte, INDF0
    endm

mAsSelect macro ASDEVICE
    movlw   ASDEVICE
    call    asSelect
    endm

#endif


; $Id$
;******************************************************************************
;                                                                             *
;    Filename:      CANHLP.inc                                                *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:        J. Schambach                                              *
;    Company:                                                                 *
;                                                                             * 
;******************************************************************************

#ifndef __CANHLP_INC           ;Check if inc file already included
#define __CANHLP_INC

#ifndef  HLP_PRIOR_SOURCE
    EXTERN  TofHandleWrite, TofHandleRead, initCAN
#endif

#define     _CAN_HLP_COMMANDID_DATA         (0x1 << 5)
#define     _CAN_HLP_COMMANDID_WRRESPONSE   (0x3 << 5)
#define     _CAN_HLP_COMMANDID_RDRESPONSE   (0x5 << 5)
#define     _CAN_HLP_COMMANDID_ALERT        (0x7 << 5)

CAN_RX_FILTER_BITS:     = B'00000111'   ;Use this to access filter bits
CAN_RX_FILTER_0:        = B'00000000'
CAN_RX_FILTER_1:        = B'00000001'

;****************************************************************************
;* Macro:               mCANSendAlert DataLngth
;*
;* PreCondition:        None
;*
;* Input:               DataLngth - Data Length (Must be between 0 to 8)
;*
;* Output:              Given CAN id value and data is copied into Tx buffer
;*                      according to priority for Transmission.
;*
;* Side Effects:        None
;*
;* Overview:            It copies the data in available hardware or software
;*                      buffer. If present data is of higher priority then
;*                      the data in hardware buffer then it aborts
;*                      transmission of lowest priority data in HW buffer and
;*                      copies it to SW buffer and copies present data to HW
;*                      Buffer for immediate transmission
;*
;****************************************************************************
mCANSendAlert  macro   DataLngth

	movlw	DataLngth
	; banksel TXB0DLC
	movwf	TXB0DLC
	movlw	_CAN_HLP_COMMANDID_ALERT
	movwf	TXB0SIDL

	bsf		TXB0CON, TXREQ			; Start the transmission

	endm

;****************************************************************************
;* Macro:               mCANSendData DataLngth
;*
;* PreCondition:        None
;*
;* Input:               DataLngth - Data Length (Must be between 0 to 8)
;*
;* Output:              Given CAN id value and data is copied into Tx buffer
;*                      according to priority for Transmission.
;*
;* Side Effects:        None
;*
;* Overview:            It copies the data in available hardware or software
;*                      buffer. If present data is of higher priority then
;*                      the data in hardware buffer then it aborts
;*                      transmission of lowest priority data in HW buffer and
;*                      copies it to SW buffer and copies present data to HW
;*                      Buffer for immediate transmission
;*
;****************************************************************************
mCANSendData  macro   DataLngth

	movlw	DataLngth
	; banksel TXB0DLC
	movwf	TXB0DLC
	movlw	_CAN_HLP_COMMANDID_DATA
	movwf	TXB0SIDL

	bsf		TXB0CON, TXREQ			; Start the transmission

	endm

;****************************************************************************
;* Macro:               mCANSendRdResponse DataLngth
;*
;* PreCondition:        None
;*
;* Input:               DataLngth - Data Length (Must be between 0 to 8)
;*
;* Output:              Given CAN id value and data is copied into Tx buffer
;*                      according to priority for Transmission.
;*
;* Side Effects:        None
;*
;* Overview:            It copies the data in available hardware or software
;*                      buffer. If present data is of higher priority then
;*                      the data in hardware buffer then it aborts
;*                      transmission of lowest priority data in HW buffer and
;*                      copies it to SW buffer and copies present data to HW
;*                      Buffer for immediate transmission
;*
;****************************************************************************
mCANSendRdResponse  macro   DataLngth

	movlw	DataLngth
	; banksel TXB0DLC
	movwf	TXB0DLC
	movlw	_CAN_HLP_COMMANDID_RDRESPONSE
	movwf	TXB0SIDL

	bsf		TXB0CON, TXREQ			; Start the transmission

	endm

;****************************************************************************
;* Macro:               mCANSendWrResponse DataLngth
;*
;* PreCondition:        None
;*
;* Input:               DataLngth - Data Length (Must be between 0 to 8)
;*
;* Output:              Given CAN id value and data is copied into Tx buffer
;*                      according to priority for Transmission.
;*
;* Side Effects:        None
;*
;* Overview:            It copies the data in available hardware or software
;*                      buffer. If present data is of higher priority then
;*                      the data in hardware buffer then it aborts
;*                      transmission of lowest priority data in HW buffer and
;*                      copies it to SW buffer and copies present data to HW
;*                      Buffer for immediate transmission
;*
;****************************************************************************
mCANSendWrResponse  macro   DataLngth

	movlw	DataLngth
	; banksel TXB0DLC
	movwf	TXB0DLC
	movlw	_CAN_HLP_COMMANDID_WRRESPONSE
	movwf	TXB0SIDL

	bsf		TXB0CON, TXREQ			; Start the transmission

	endm

;****************************************************************************
;* Macro:               mCANSendWrResponse_IDL      DataLngthPtr
;*
;* PreCondition:        None
;*
;* Input:               DataLngthPtr - Address of Register for Data Length
;*                                      storage
;*
;* Output:              Given CAN id value and data is copied into Tx buffer
;*                      according to priority for Transmission.
;*
;* Side Effects:        None
;*
;* Overview:            It copies the data in available hardware or software
;*                      buffer. If present data is of higher priority then
;*                      the data in hardware buffer then it aborts
;*                      transmission of lowest priority data in HW buffer and
;*                      copies it to SW buffer and copies present data to HW
;*                      Buffer for immediate transmission
;*
;****************************************************************************
mCANSendWrResponse_IDL macro DataLngthPtr

    movff   DataLngthPtr, TXB0DLC
	movlw	_CAN_HLP_COMMANDID_WRRESPONSE
	movwf	TXB0SIDL

	bsf		TXB0CON, TXREQ			; Start the transmission

    endm

;****************************************************************************
;* Macro:               mCANSendAlert_IDL      DataLngthPtr
;*
;* PreCondition:        None
;*
;* Input:               DataLngthPtr - Address of Register for Data Length
;*                                      storage
;*
;* Output:              Given CAN id value and data is copied into Tx buffer
;*                      according to priority for Transmission.
;*
;* Side Effects:        None
;*
;* Overview:            It copies the data in available hardware or software
;*                      buffer. If present data is of higher priority then
;*                      the data in hardware buffer then it aborts
;*                      transmission of lowest priority data in HW buffer and
;*                      copies it to SW buffer and copies present data to HW
;*                      Buffer for immediate transmission
;*
;****************************************************************************
mCANSendAlert_IDL macro DataLngthPtr

    movff   DataLngthPtr, TXB0DLC
	movlw	_CAN_HLP_COMMANDID_ALERT
	movwf	TXB0SIDL

	bsf		TXB0CON, TXREQ			; Start the transmission

    endm

#endif

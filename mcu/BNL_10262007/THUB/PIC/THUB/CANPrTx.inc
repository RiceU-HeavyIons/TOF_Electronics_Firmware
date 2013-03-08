; $Id: CANPrTx.inc,v 1.1 2006-08-11 22:11:01 jschamba Exp $
;****************************************************************************
;*
;*              CAN Library routines in Assembly
;*
;****************************************************************************
;* FileName:            CANPrTx.ASM
;* Dependencies:        CANPrTxIn.inc
;*                      CANPrTx.def
;*
;* Processor:           PIC 18XXX8
;* Compiler:            MPLAB 6.00.20
;* Company:             Microchip Technology, Inc.
;*
;* Software License Agreement
;*
;* The software supplied herewith by Microchip Technology Incorporated
;* (the “Company”) for its PICmicro® Microcontroller is intended and
;* supplied to you, the Company’s customer, for use solely and
;* exclusively on Microchip PICmicro Microcontroller products. The
;* software is owned by the Company and/or its supplier, and is
;* protected under applicable copyright laws. All rights are reserved.
;* Any use in violation of the foregoing restrictions may subject the
;* user to criminal sanctions under applicable laws, as well as to
;* civil liability for the breach of the terms and conditions of this
;* license.
;*
;* THIS SOFTWARE IS PROVIDED IN AN “AS IS” CONDITION. NO WARRANTIES,
;* WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED
;* TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
;* PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE COMPANY SHALL NOT,
;* IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL OR
;* CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
;*
;* Author               Date        Comment
;*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;* Gaurang Kavaiya      4/25/01         Original
;* Gaurang Kavaiya      10/23/02        Modified for Application Maestro (1.0)
;*
;*****************************************************************************
#ifndef __CANPrTx_INC           ;Check if inc file already included

#define __CANPrTx_INC

#ifndef  CAN_PRIOR_TX_INT_SOURCE
        EXTERN  CANInit, CANSetOpMode, CANSetBaudRate
        EXTERN  CANSetReg, CANReadReg
        EXTERN  CANSendMsg, CANISR
        EXTERN  CANReadMsg

        #ifdef ADD_CANIsTxPassive
                EXTERN  CANIsTxPassive
        #endif

        #ifdef ADD_CANIsRxPassive
                EXTERN  CANIsRxPassive
        #endif

        #ifdef  ADD_CANIsBusOff
                EXTERN  CANIsBusOff
        #endif

        #ifdef ADD_CANIsRxReady
                EXTERN  CANIsRxReady
        #endif

        #ifdef  ADD_CANIsTxReady
                EXTERN  CANIsTxReady
        #endif

;Global Variables
        EXTERN  vCANBufSize

;Private Variables
        EXTERN  _Temp1_A
        EXTERN  _vCANSJW_O, _vCANBRP_O, _vCANPHSEG1_O, _vCANPHSEG2_O, _vCANPROPSEG2_O
        EXTERN  _vFlags1_O, _vReg1_O, _vTemp32Data, _DataLength, _RxFlags, _TxFlags

#endif




; *********************************************************************
; *
; * CAN_CONFIG_FLAGS
; *
; * This values define flags related to configuring CAN module.
; * Routines CANPrTxInit() and CANPrTxSetBaudRate() uses these
; * codes. One or more these values may be ANDed to form multiple
; * flags.
; *
; ********************************************************************


CAN_CONFIG_DEFAULT:             = B'11111111'   ; 11111111

CAN_CONFIG_PHSEG2_PRG_BIT:      = B'10000000'
CAN_CONFIG_PHSEG2_PRG_BIT_NO:   = 0x07
CAN_CONFIG_PHSEG2_PRG_ON:       = B'11111111'   ; 1XXXXXXX
CAN_CONFIG_PHSEG2_PRG_OFF:      = B'01111111'   ; 0XXXXXXX

CAN_CONFIG_MSG_BITS:            = B'01100000'
CAN_CONFIG_ALL_MSG:             = B'11111111'   ; XX11XXXX
CAN_CONFIG_VALID_XTD_MSG:       = B'11011111'   ; X10XXXXX
CAN_CONFIG_VALID_STD_MSG:       = B'10111111'   ; X01XXXXX
CAN_CONFIG_ALL_VALID_MSG:       = B'10011111'   ; X00XXXXX

CAN_CONFIG_SAMPLE_BIT:          = B'00010000'
CAN_CONFIG_SAMPLE_BIT_NO:       = 0x04
CAN_CONFIG_SAMPLE_ONCE:         = B'11101111'   ; XXX1XXXX
CAN_CONFIG_SAMPLE_THRICE:       = B'11111111'   ; XXX0XXXX

CAN_CONFIG_MSG_TYPE_BIT:        = B'00001000'
CAN_CONFIG_MSG_TYPE_BIT_NO:     = 0x03
CAN_CONFIG_STD_MSG:             = B'11111111'   ; XXXX1XXX
CAN_CONFIG_XTD_MSG:             = B'11110111'   ; XXXX0XXX

CAN_CONFIG_DBL_BUFFER_BIT:      = B'00000100'
CAN_CONFIG_DBL_BUFFER_BIT_NO:   = 0x02
CAN_CONFIG_DBL_BUFFER_ON:       = B'11111111'   ; XXXXX1XX
CAN_CONFIG_DBL_BUFFER_OFF:      = B'11111011'   ; XXXXX0XX


CAN_CONFIG_LINE_FILTER_BIT:     = B'00000001'
CAN_CONFIG_LINE_FILTER_BIT_NO:  = 0x0
CAN_CONFIG_LINE_FILTER_ON:      = B'11111111'   ; XXXXXXX1
CAN_CONFIG_LINE_FILTER_OFF:     = B'11111110'   ; XXXXXXX0





; *********************************************************************
; *
; * CAN_OP_MODE
; *
; * This values define codes related to CAN module operation mode.
; * CANSetOperationModefunc() routine requires this code.
; * These values must be used by itself
; * i.e. it cannot be ANDed to form * multiple values.
; *
; ********************************************************************

CAN_OP_MODE_BITS:       = B'11100000'   ; Use this to access opmode
                                        ; bits
CAN_OP_MODE_NORMAL:     = B'00000000'
CAN_OP_MODE_SLEEP:      = B'00100000'
CAN_OP_MODE_LOOP:       = B'01000000'
CAN_OP_MODE_LISTEN:     = B'01100000'
CAN_OP_MODE_CONFIG:     = B'10000000'




;CAN Mask bits Registers
CAN_MASK_B0: =  0x0f18          ;Address of RXM0SIDH
CAN_MASK_B1: =  0x0f1c          ;Address of RXM1SIDH


;CAN FILTER Registers
CAN_FILTER_B0_F1: =     0x0f00  ;Address of RXF0SIDH
CAN_FILTER_B0_F2: =     0x0f04  ;Address of RXF1SIDH
CAN_FILTER_B1_F1: =     0x0f08  ;Address of RXF2SIDH
CAN_FILTER_B1_F2: =     0x0f0c  ;Address of RXF3SIDH
CAN_FILTER_B1_F3: =     0x0f10  ;Address of RXF4SIDH
CAN_FILTER_B1_F4: =     0x0f14  ;Address of RXF5SIDH



;CAN ID registers
CAN_TX_IDB0:    =       0xf41           ;Address of TXB0SIDH
CAN_TX_IDB1:    =       0xf31           ;Address of TXB1SIDH
CAN_TX_IDB2:    =       0xf21           ;Address of TXB2SIDH







; *********************************************************************
; *
; * CAN_TX_MSG_FLAGS
; *
; * This values define flags related to transmission of a
; * CAN message.  There could be more than one this flag
; * ANDed together to form multiple flags.
; *
; *********************************************************************

CAN_TX_PRIORITY_BITS:   = B'00000011'
CAN_TX_PRIORITY_0:      = B'11111100'   ;XXXXXX00
CAN_TX_PRIORITY_1:      = B'11111101'   ; XXXXXX01
CAN_TX_PRIORITY_2:      = B'11111110'   ; XXXXXX10
CAN_TX_PRIORITY_3:      = B'11111111'   ; XXXXXX11

CAN_TX_FRAME_BIT:       = B'00001000'
CAN_TX_STD_FRAME:       = B'11111111'   ; XXXXX1XX
CAN_TX_XTD_FRAME:       = B'11110111'   ; XXXXX0XX

CAN_TX_RTR_BIT:         = B'01000000'
CAN_TX_RTR_BIT_NO:      = 0x06
CAN_TX_NO_RTR_FRAME:    = B'11111111'   ; X1XXXXXX
CAN_TX_RTR_FRAME:       = B'10111111'   ; X0XXXXXX





; *********************************************************************
; *
; * CAN_RX_MSG_FLAGS
; *
; * These values define flags related to reception of a CAN
; * message.  There could be more than one this flag
; * ANDed together to form multiple flags.
; * If a particular bit is set, corresponding meaning is TRUE or else
; * it will be FALSE.
; *
; * e.g.
; *             if (MsgFlag & CAN_RX_OVERFLOW)
; *             {
; *                     // Receiver overflow has occurred.  We have lost ;
; *                     previous
; *                     // message.
; *                     ...
; *             }
; *
; *********************************************************************
CAN_RX_FILTER_BITS:     = B'00000111'   ;Use this to access filter bits
CAN_RX_FILTER_0:        = B'00000000'
CAN_RX_FILTER_1:        = B'00000001'
CAN_RX_FILTER_1_BIT_NO: = 0x00
CAN_RX_FILTER_2:        = B'00000010'
CAN_RX_FILTER_3:        = B'00000011'
CAN_RX_FILTER_4:        = B'00000100'
CAN_RX_FILTER_5:        = B'00000101'

CAN_RX_OVERFLOW:        = B'00001000'   ;Set if Overflowed else cleared
CAN_RX_OVERFLOW_BIT_NO: = 0x03

CAN_RX_INVALID_MSG:     = B'00010000'   ;Set if invalid else cleared
CAN_RX_INVALID_MSG_BIT_NO: = 0x04

CAN_RX_XTD_FRAME:       = B'00100000'   ;Set if XTD message else cleared
CAN_RX_XTD_FRAME_BIT_NO: = 0x05

CAN_RX_RTR_FRAME:       = B'01000000'   ;Set if RTR message else cleared
CAN_RX_RTR_FRAME_BIT_NO: = 0x06         ;RTR message bit

CAN_RX_DBL_BUFFERED: = B'10000000'      ;Set if this message was hardware
CAN_RX_DBL_BUFFERED_BIT_NO: = 0x07      ;double-buffered







;This Flag is used to determine which buffer has been loaded.
CANTxBuf0Flag:  = 0x00
CANTxBuf1Flag:  = 0x01
CANTxBuf2Flag:  = 0x02
CANTxSoftBufFlag: = 0x07

;****************************************************************************
;* MACRO SECTION
;****************************************************************************



;****************************************************************************
;* Macro:               mEnableCANTxInt
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        W, STATUS changed
;*
;* Overview:            It enables the CAN transmit Interrupt
;*
;****************************************************************************
mEnableCANTxInt       macro
        movlw   B'00011100'
        iorwf   PIE3            ;Enable Tx Int
        endm

;****************************************************************************
;* Macro:               mDisableCANTxInt
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        W, STATUS changed
;*
;* Overview:            It Disables the CAN transmit Interrupt
;*
;****************************************************************************
mDisableCANTxInt      macro
        movlw   B'11100011'
        andwf   PIE3            ;Disable Tx Int
        endm

;****************************************************************************
;* Macro:               mEnablePeriphInt
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        None
;*
;* Overview:            It enables the Peripheral Interrupt
;*
;****************************************************************************
mEnablePeriphInt macro
        bsf     INTCON,PEIE
        endm

;****************************************************************************
;* Macro:               mDisablePeriphInt
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        None
;*
;* Overview:            It disables the Peripheral Interrupt
;*
;****************************************************************************
mDisablePeriphInt        macro
        bcf     INTCON,PEIE
        endm




;****************************************************************************
;* Macro:               mCANAbortAll
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        None
;*
;****************************************************************************
mCANAbortAll     macro
        bsf     CANCON,ABAT     ;Abort all pending transmissions
        endm



;****************************************************************************
;* Macro:               mCANGetTxErrCnt
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              W reg = Current transmit error count as defined by
;*                              CAN specifications.
;*
;* Side Effects:        None
;*
;****************************************************************************
mCANGetTxErrCnt      macro
        movf    TXERRCNT,W
        endm



;****************************************************************************
;* Macro:               mCANGetRxErrCnt
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              W reg = Current receive error count as defined by
;*                              CAN specifications.
;*
;* Side Effects:        None
;*
;****************************************************************************
mCANGetRxErrCnt      macro
        movf    RXERRCNT,w
        endm





;****************************************************************************
;* Macro:               mCANInit   SJW, BRP,PHSEG1, PHSEG2, PROPSEG,
;*                                  CAN_CONFIG_FLAGS flags
;*
;* Input:               SJW - SJW value as defined in 18CXX8 data sheet
;*                      (Must be between 1 thru 4)
;*                      BRP - BRP value as defined in 18CXX8 data sheet
;*                      (Must be between 1 thru 64)
;*                      PHSEG1 - PHSEG1 value as defined in 18CXX8 data sheet
;*                      Must be between 1 thru 8)
;*                      PHSEG2 - PHSEG2 value as defined in 18CXX8 data sheet
;*                      (Must be between 1 thru 8)
;*                      PROPSEG - PROPSEG value as defined in 18CXX8 datasheet
;*                      (Must be between 1 thru 8)
;*                      flags - Value of type CAN_CONFIG_FLAGS
;*
;* Output:              CAN bit rate is set. All masks registers are set
;*                      '0' to allow all messages.
;*                      Filter registers are set according to flag value.
;*                      If (config & CAN_CONFIG_VALID_XTD_MSG)
;*                      Set all filters to XTD_MSG
;*                      Else if (config & CONFIG_VALID_STD_MSG)
;*                      Set all filters to STD_MSG
;*                      Else
;*                      Set half of the filters to STD while rests to
;*                      XTD_MSG.
;*
;* Side Effects:        All pending transmissions are aborted.
;*
;****************************************************************************
mCANInit   macro   SJW, BRP, PHSEG1, PHSEG2, PROPSEG, Flags
        banksel _vCANSJW_O
        movlw   SJW
        movwf   _vCANSJW_O           ;Save SJW value

        banksel _vCANBRP_O
        movlw   BRP
        movwf   _vCANBRP_O           ;Save BRP value

        banksel _vCANPHSEG1_O
        movlw   PHSEG1
        movwf   _vCANPHSEG1_O        ;Save Phase Segment 1 value

        banksel _vCANPHSEG2_O
        movlw   PHSEG2
        movwf   _vCANPHSEG2_O        ;Save Phase Segment 2 value

        banksel _vCANPROPSEG2_O
        movlw   PROPSEG
        movwf   _vCANPROPSEG2_O      ;Save Propagation time value

        banksel _vFlags1_O        ;Save Configuration Flags info
        movlw   Flags
        movwf   _vFlags1_O

        call    CANInit       ;Initialize the CAN module
        endm





;****************************************************************************
;* Macro:               mCANSetBaud  SJW, BRP,PHSEG1, PHSEG2, PROPSEG,
;*                                  CAN_CONFIG_FLAGS flags
;*
;* PreCondition:        MCU must be in Configuration mode or else these
;*                      values will be ignored.
;*
;* Input:               SJW - SJW value as defined in 18CXX8 data sheet
;*                      (Must be between 1 thru 4)
;*                      BRP - BRP value as defined in 18CXX8 data sheet
;*                      (Must be between 1 thru 64)
;*                      PHSEG1 - PHSEG1 value as defined in 18CXX8 data sheet
;*                      Must be between 1 thru 8)
;*                      PHSEG2 - PHSEG2 value as defined in 18CXX8 data sheet
;*                      (Must be between 1 thru 8)
;*                      PROPSEG - PROPSEG value as defined in 18CXX8 datasheet
;*                      (Must be between 1 thru 8)
;*                      flags - Value of type CAN_CONFIG_FLAGS
;*
;* Output:              CAN bit rate is set. All masks registers are set
;*                      '0' to allow all messages.
;*                      Filter registers are set according to flag value.
;*                      If (config & CAN_CONFIG_VALID_XTD_MSG)
;*                      Set all filters to XTD_MSG
;*                      Else if (config & CONFIG_VALID_STD_MSG)
;*                      Set all filters to STD_MSG
;*                      Else
;*                      Set half of the filters to STD while rests to
;*                      XTD_MSG.
;*
;* Side Effects:        All pending transmissions are aborted.
;*
;****************************************************************************
mCANSetBaud  macro   SJW, BRP, PHSEG1, PHSEG2, PROPSEG, Flags
        banksel _vCANSJW_O
        movlw   SJW
        movwf   _vCANSJW_O           ;Save SJW value

        banksel _vCANBRP_O
        movlw   BRP
        movwf   _vCANBRP_O           ;Save BRP value

        banksel _vCANPHSEG1_O
        movlw   PHSEG1
        movwf   _vCANPHSEG1_O        ;Save Phase Segment 1 value

        banksel _vCANPHSEG2_O
        movlw   PHSEG2
        movwf   _vCANPHSEG2_O        ;Save Phase Segment 2 value

        banksel _vCANPROPSEG2_O
        movlw   PROPSEG
        movwf   _vCANPROPSEG2_O      ;Save Propagation time value

        banksel _vFlags1_O        ;Save Configuration Flags info
        movlw   Flags
        movwf   _vFlags1_O

        call    CANSetBaudRate      ;Initialize the Baud Rate
        endm







;****************************************************************************
;* Macro:               mCANSetOpMode     CAN_OP_MODE mode
;*
;* PreCondition:        None
;*
;* Input:               Value of type CAN_OP_MODE
;*
;*
;* Output:              MCU is set to requested mode
;*
;* Side Effects:        Databank is changed
;*
;* Overview:            Given mode byte is copied to CANCON and made
;*                      sure that requested mode is set.
;*
;* Note:                This is a blocking call.  It will not return until
;*                      requested mode is set.
;****************************************************************************
mCANSetOpMode macro OpMode
        movlw   OpMode
        call    CANSetOpMode ;Set CAN module Operation mode
        endm


;****************************************************************************
;* Macro:               mCANSetOpModeNoWait    CAN_OP_MODE mode
;*
;* PreCondition:        None
;*
;* Input:               Value of type CAN_OP_MODE
;*
;*
;* Output:              MCU is set to requested mode
;*
;* Side Effects:        None
;*
;* Overview:            Given mode byte is copied to CANCON
;*
;* Note:                This is a non-blocking call. It will not verify if
;*                      requested mode is set or not.
;****************************************************************************
mCANSetOpModeNoWait macro OpMode
        movlw   OpMode
        movwf   CANCON          ;Set CAN module Operation mode
        endm



;****************************************************************************
;* Macro:               mCANSetReg       RegAddr,
;*                                      val,
;*                                      CAN_CONFIG_FLAGS type
;*
;* PreCondition:        None
;*
;* Input:               RegAddr Starting address of a 32-bit buffer to be
;*                      updated
;*                      val - 32-bit value to be converted
;*                      Flags - Type of message - either
;*                              CAN_CONFIG_XTD_MSG or CAN_CONFIG_STD_MSG
;*
;* Output:              Given CAN id value 'val' is bit adjusted and copied
;*                      into corresponding PIC18CXX8 CAN registers
;*
;* Side Effects:        FSR0 changed
;*
;* Overview:            If given id is of type standard identifier,
;*                      only SIDH and SIDL are updated
;*                      If given id is of type extended identifier,
;*                      bits val<17:0> is copied to EIDH, EIDL and SIDH<1:0>
;*                      bits val<28:18> is copied to SIDH and SIDL
;*
;****************************************************************************
mCANSetReg macro RegAddr, val, Flags
        banksel _vFlags1_O        ;Save Configuration Flags info
        movlw   Flags
        movwf   _vFlags1_O

        movlw   low(RegAddr)
        movwf   FSR0L           ;Save the address of destination register
        movlw   high(RegAddr)
        movwf   FSR0H
        movlw   val & H'FF' ;Store the 32-bit variable in register
        banksel _vReg1_O
        movwf   _vReg1_O            ;First LL byte
        movlw   val >> D'08' & H'FF' ;
        movwf   _vReg1_O+1          ;Second LH byte
        movlw   val >> D'16' & H'FF' ;
        movwf   _vReg1_O+2          ;Third HL byte
        movlw   val >> D'24' & H'FF' ;
        movwf   _vReg1_O+3          ;Fourth HH byte
        call    CANSetReg   ;Copy 32-bit value into required registers.
        endm







;****************************************************************************
;* Macro:               mCANSetReg_IF    RegAddr,
;*                                      val,
;*                                      CAN_CONFIG_FLAGS type
;*
;* PreCondition:        None
;*
;* Input:               RegAddr - Starting address of a 32-bit buffer to be
;*                      updated
;*                      val - 32-bit value to be converted
;*                      FlagsReg - Address of Register containing flags info
;*                              CAN_CONFIG_XTD_MSG or CAN_CONFIG_STD_MSG
;*
;* Output:              Given CAN id value 'val' is bit adjusted and copied
;*                      into corresponding PIC18CXX8 CAN registers
;*
;* Side Effects:        FSR0 changed
;*
;* Overview:            If given id is of type standard identifier,
;*                      only SIDH and SIDL are updated
;*                      If given id is of type extended identifier,
;*                      bits val<17:0> is copied to EIDH, EIDL and SIDH<1:0>
;*                      bits val<28:18> is copied to SIDH and SIDL
;*
;****************************************************************************
mCANSetReg_IF macro RegAddr, val, FlagsReg
        movlw   low(FlagsReg)
        movwf   FSR0L           ;Save the address of destination register
        movlw   high(FlagsReg)
        movwf   FSR0H
        movff   INDF0,_vFlags1_O

        movlw   low(RegAddr)
        movwf   FSR0L           ;Save the address of destination register
        movlw   high(RegAddr)
        movwf   FSR0H
        movlw   val & H'FF' ;Store the 32-bit variable in register
        banksel _vReg1_O
        movwf   _vReg1_O            ;First LL byte
        movlw   val >> D'08' & H'FF' ;
        movwf   _vReg1_O+1          ;Second LH byte
        movlw   val >> D'16' & H'FF' ;
        movwf   _vReg1_O+2          ;Third HL byte
        movlw   val >> D'24' & H'FF' ;
        movwf   _vReg1_O+3          ;Fourth HH byte
        call    CANSetReg   ;Copy 32-bit value into required registers.
        endm





;****************************************************************************
;* Macro:               mCANSetReg_IV    RegAddr,
;*                                  val,
;*                                  CAN_CONFIG_FLAGS type
;*
;* PreCondition:        None
;*
;* Input:               RegAddr - Starting address of a 32-bit buffer to be
;*                      updated
;*                      val - Starting address of 32 bit value to be converted
;*                              (LL:LH:HL:HH) format (Low -> High)
;*                      Flags - Type of message - either
;*                              CAN_CONFIG_XTD_MSG or CAN_CONFIG_STD_MSG
;*
;* Output:              Given CAN id value 'val' is bit adjusted and copied
;*                      into corresponding PIC18CXX8 CAN registers
;*
;* Side Effects:        FSR0 changed
;*
;* Overview:            If given id is of type standard identifier,
;*                      only SIDH and SIDL are updated
;*                      If given id is of type extended identifier,
;*                      bits val<17:0> is copied to EIDH, EIDL and SIDH<1:0>
;*                      bits val<28:18> is copied to SIDH and SIDL
;*
;****************************************************************************
mCANSetReg_IV macro RegAddr, Var, Flags
        banksel _vFlags1_O        ;Save Configuration Flags info
        movlw   Flags
        movwf   _vFlags1_O

        movlw   low(Var)
        movwf   FSR0L
        movlw   high(Var)
        movwf   FSR0H
        movff   POSTINC0,_vReg1_O   ;Save LL byte
        movff   POSTINC0,_vReg1_O+1 ;save LH byte
        movff   POSTINC0,_vReg1_O+2 ;save HL byte
        movff   POSTINC0,_vReg1_O+3 ;save HH byte

        movlw   low(RegAddr)
        movwf   FSR0L           ;Save the address of destination register
        movlw   high(RegAddr)
        movwf   FSR0H
        call    CANSetReg   ;copy 32-bit value into required registers.
        endm








;****************************************************************************
;* Macro:               mCANSetReg_IV_IF RegAddr,
;*                                  var,
;*                                  CAN_CONFIG_FLAGS type
;*
;* PreCondition:        None
;*
;* Input:               RegAddr - Starting address of a 32-bit buffer to be
;*                      updated
;*                      var - Starting address of 32 bit value to be converted
;*                              (LL:LH:HL:HH) format(Low -> High)
;*                      Flags - Address of Register containing flags info
;*                              CAN_CONFIG_XTD_MSG or CAN_CONFIG_STD_MSG
;*
;* Output:              Given CAN id value 'val' is bit adjusted and copied
;*                      into corresponding PIC18CXX8 CAN registers
;*
;* Side Effects:        FSR0 changed
;*
;* Overview:            If given id is of type standard identifier,
;*                      only SIDH and SIDL are updated
;*                      If given id is of type extended identifier,
;*                      bits val<17:0> is copied to EIDH, EIDL and SIDH<1:0>
;*                      bits val<28:18> is copied to SIDH and SIDL
;*
;****************************************************************************
mCANSetReg_IV_IF macro RegAddr, Var, FlagsReg
        movlw   low(FlagsReg)
        movwf   FSR0L           ;Save the address of destination register
        movlw   high(FlagsReg)
        movwf   FSR0H
        movff   INDF0,_vFlags1_O

        movlw   low(Var)
        movwf   FSR0L
        movlw   high(Var)
        movwf   FSR0H
        movff   POSTINC0,_vReg1_O   ;Save LL byte
        movff   POSTINC0,_vReg1_O+1 ;save LH byte
        movff   POSTINC0,_vReg1_O+2 ;save HL byte
        movff   POSTINC0,_vReg1_O+3 ;save HH byte

        movlw   low(RegAddr)
        movwf   FSR0L           ;Save the address of destination register
        movlw   high(RegAddr)
        movwf   FSR0H
        call    CANSetReg   ;copy 32-bit value into required registers.
        endm









;****************************************************************************
;* Macro:               mCANSetReg_PREG_IV_IF    val,
;*                                          CAN_CONFIG_FLAGS type
;*
;* PreCondition:        None
;*
;* Input:               FSR0: Starting address of a 32-bit buffer to be
;*                      updated
;*                      Var - Starting address of 32 bit value to be
;*                              converted, (LL:LH:HL:HH) format (Low -> High)
;*                      Flags - Address of Register containing flags info
;*                              CAN_CONFIG_XTD_MSG or CAN_CONFIG_STD_MSG
;*
;* Output:              Given CAN id value 'val' is bit adjusted and copied
;*                      into corresponding PIC18CXX8 CAN registers
;*
;* Side Effects:        FSR1 changed
;*
;* Overview:            If given id is of type standard identifier,
;*                      only SIDH and SIDL are updated
;*                      If given id is of type extended identifier,
;*                      bits val<17:0> is copied to EIDH, EIDL and SIDH<1:0>
;*                      bits val<28:18> is copied to SIDH and SIDL
;*
;****************************************************************************
mCANSetReg_PREG_IV_IF macro Var, FlagsReg
        movlw   low(FlagsReg)
        movwf   FSR1L           ;Save the address of destination register
        movlw   high(FlagsReg)
        movwf   FSR1H
        movff   INDF1,_vFlags1_O

        movlw   low(Var)
        movwf   FSR1L
        movlw   high(Var)
        movwf   FSR1H
        movff   POSTINC1,_vReg1_O   ;Save LL byte
        movff   POSTINC1,_vReg1_O+1 ;save LH byte
        movff   POSTINC1,_vReg1_O+2 ;save HL byte
        movff   POSTINC1,_vReg1_O+3 ;save HH byte

        call    CANSetReg   ;copy 32-bit value into required registers.
        endm






;****************************************************************************
;* Macro:               mCANSetReg_PREG_DV_IF    FlagsReg
;*
;* PreCondition:        None
;*
;* Input:               FSR0: Starting address of a 32-bit buffer to be
;*                      updated
;*                      _vReg1_O - Starting address of 32 bit value to be
;*                              converted, (LL:LH:HL:HH) format (Low -> High)
;*                      Flags - Address of Register containing flags info
;*                              CAN_CONFIG_XTD_MSG or CAN_CONFIG_STD_MSG
;*
;* Output:              Given CAN id value 'val' is bit adjusted and copied
;*                      into corresponding PIC18CXX8 CAN registers
;*
;* Side Effects:        FSR1 changed
;*
;* Overview:            If given id is of type standard identifier,
;*                      only SIDH and SIDL are updated
;*                      If given id is of type extended identifier,
;*                      bits val<17:0> is copied to EIDH, EIDL and SIDH<1:0>
;*                      bits val<28:18> is copied to SIDH and SIDL
;*
;****************************************************************************
mCANSetReg_PREG_DV_IF macro FlagsReg

        movlw   low(FlagsReg)
        movwf   FSR1L           ;Save the address of destination register
        movlw   high(FlagsReg)
        movwf   FSR1H
        movff   INDF1,_vFlags1_O
        call    CANSetReg   ;copy 32-bit value into required registers.
        endm








;****************************************************************************
;* Macro:               mCANReadReg      RegAddr, Val
;*
;* PreCondition:        None
;*
;* Input:               RegAddr - Starting address of a 32-bit buffer to be
;*                      read
;*                      Val - Starting address of a buffer for storage of
;*                      converted 32-bit variable
;*
;* Output:              Corresponding CAN id registers are read  and value is
;*                      bit adjusted and copied into 32-bit destination
;*
;* Side Effects:        FSR0/FSR1 changed
;*
;* Overview:            If given id is of type standard identifier,
;*                      only SIDH and SIDL are read
;*                      If given id is of type extended identifier,
;*                      EIDL and EIDH are read too.
;*
;****************************************************************************
mCANReadReg macro RegAddr, Val

        movlw   low(RegAddr)
        movwf   FSR0L           ;Save the address of destination register
        movlw   high(RegAddr)
        movwf   FSR0H

        movlw   low(Val)
        movwf   FSR1L           ;Save the address of destination register
        movlw   high(Val)
        movwf   FSR1H
        call    CANReadReg
        endm








;****************************************************************************
;* Macro:               mCANReadReg_PREG Val,
;*
;* PreCondition:        None
;*
;* Input:               FSR0 - Starting address of a 32-bit buffer to be
;*                      read
;*                      Val - Starting address of a buffer for storage of
;*                      converted 32-bit variable
;*
;* Output:              Corresponding CAN id registers are read  and value is
;*                      bit adjusted and copied into 32-bit destination
;*
;* Side Effects:        FSR1 changed
;*
;* Overview:            If given id is of type standard identifier,
;*                      only SIDH and SIDL are read
;*                      If given id is of type extended identifier,
;*                      EIDL and EIDH are read too.
;*
;****************************************************************************
mCANReadReg_PREG macro Val

        movlw   low(Val)
        movwf   FSR1L           ;Save the address of destination register
        movlw   high(Val)
        movwf   FSR1H
        call    CANReadReg
        endm











;****************************************************************************
;* Macro:               mCANReadReg_PPREG        RegAddr,
;*                                              Val,
;*
;* PreCondition:        None
;*
;* Input:               FSR0 - FSR0 contains an address of memory location
;*                      which contains address of starting address of buffer
;*                      to be read.
;*                      Val - Starting address of a buffer for storage of
;*                      converted 32-bit variable
;*
;* Output:              Corresponding CAN id registers are read  and value is
;*                      bit adjusted and copied into 32-bit destination
;*
;* Side Effects:        None
;*
;* Overview:            If given id is of type standard identifier,
;*                      only SIDH and SIDL are read
;*                      If given id is of type extended identifier,
;*                      EIDL and EIDH are read too.
;*
;****************************************************************************
mCANReadReg_PPREG macro Val

        movff   POSTINC0,_Temp1_A  ;Get the Low byte of Address pointer
        movff   POSTINC0,Temp2  ;Get the high byte of address pointer

        movff   _Temp1_A,FSR0L     ;Point towards actual register
        movff   Temp2,FSR0H     ;

        movlw   low(Val)
        movwf   FSR1L           ;Save the address of destination register
        movlw   high(Val)
        movwf   FSR1H
        call    CANReadReg
        endm









;****************************************************************************
;* Macro:               mCANSendMsg  msgID,
;*                                  DataPtr,
;*                                  DataLngth,
;*                                  CAN_TX_MSG_FLAGS type
;*
;* PreCondition:        None
;*
;* Input:               msgID - 32-bit Message ID
;*                      DataPtr - Starting address of data to be transmitted
;*                      DataLngth - Data Length (Must be between 0 to 8)
;*                      type - Type of message -CAN_TX_MSG_FLAGS type
;*                              CAN_CONFIG_XTD_MSG or CAN_CONFIG_STD_MSG &
;*                              CAN_TX_RTR_FRAME or CAN_TX_NO_RTR_FRAME
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
mCANSendMsg  macro   msgID, DataPtr, DataLngth, Flags
        movlw   low(msgID)      ;Store the 32-bit variable in register
        banksel _vReg1_O
        movwf   _vReg1_O            ;First LL byte
        movlw   high(msgID)
        movwf   _vReg1_O+1          ;Second LH byte
        movlw   upper(msgID)
        movwf   _vReg1_O+2          ;Third HL byte
msgID1 = msgID >> 8
        movlw   upper(msgID1)
        movwf   _vReg1_O+3          ;Fourth HH byte

        movlw   low(DataPtr)
        movwf   FSR1L
        movlw   high(DataPtr)
        movwf   FSR1H

        movlw   DataLngth
        banksel _DataLength
        movwf   _DataLength

        movlw   Flags
        banksel _TxFlags
        movwf   _TxFlags
        call    CANSendMsg
        endm







;****************************************************************************
;* Macro:               mCANSendMsg_IID_IDL_IF       msgIDPtr,
;*                                                  DataPtr,
;*                                                  DataLngthPtr,
;*                                                  FlagsReg
;*
;* PreCondition:        None
;*
;* Input:               msgIDPtr - Starting address of 32-bit Message ID
;*                                 storage, format (LL:LH:HL:HH),(Low ->High)
;*                      DataPtr - Starting address of data to be transmitted
;*                      DataLngthPtr - Address of Register for Data Length
;*                                      storage
;*                      FlagsReg - Address of Register containing flags info
;*                              Type of message -CAN_TX_MSG_FLAGS type
;*                              CAN_CONFIG_XTD_MSG or CAN_CONFIG_STD_MSG &
;*                              CAN_TX_RTR_FRAME or CAN_TX_NO_RTR_FRAME
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
mCANSendMsg_IID_IDL_IF macro msgIDPtr, DataPtr, DataLngthPtr, FlagsReg

        movlw   low(msgIDPtr)
        movwf   FSR1L
        movlw   high(msgIDPtr)
        movwf   FSR1H

        movff   POSTINC1,_vReg1_O           ;Copy Message ID value into _vReg1_O
        movff   POSTINC1,_vReg1_O+1         ;32-bit Source is Pointed by FSR1
        movff   POSTINC1,_vReg1_O+2         ;32 bit storage Low -> High
        movff   POSTINC1,_vReg1_O+3

        movlw   low(DataLngthPtr)
        movwf   FSR1L           ;Copy Data Length value into _DataLength
        movlw   high(DataLngthPtr)
        movwf   FSR1H
        movff   INDF1,_DataLength

        movlw   low(FlagsReg)
        movwf   FSR1L           ;Save the address of destination register
        movlw   high(FlagsReg)
        movwf   FSR1H
        movff   INDF1,_TxFlags

        movlw   low(DataPtr)
        movwf   FSR1L
        movlw   high(DataPtr)
        movwf   FSR1H

        call    CANSendMsg
        endm







;****************************************************************************
;* Macro:               mCANReadMsg  msgIDPtr,
;*                                  DataPtr,
;*                                  DataLngth,
;*                                  CAN_RX_MSG_FLAGS type
;*
;* PreCondition:        None
;*
;* Input:               msgIDPtr - Starting address of 32-bit Message ID
;*                                      storage
;*                      DataPtr - Starting address for recd. data storage
;*                      DataLngth - Location to store Data Length info
;*                      Flags- Location to store flags info
;*
;* Output:              If any pending received data is available then data
;*                      and ID values is returned
;*
;* Side Effects:        None
;*
;* Overview:            It formats the data in Rx Buffer and returns it.
;*                      It stores 32-bit Message ID, Recd. data, Data Length
;*                      and Receiver Status Flags into user supplied memory
;*                      locations.

;****************************************************************************
mCANReadMsg  macro   msgIDPtr, DataPtr, DataLngth, Flags
        movlw   low(DataPtr)
        movwf   FSR0L
        movlw   high(DataPtr)
        movwf   FSR0H

        call    CANReadMsg
        movwf   _Temp1_A           ;Save return value

        movlw   low(msgIDPtr)
        movwf   FSR0L
        movlw   high(msgIDPtr)
        movwf   FSR0H
        movff   _vTemp32Data,POSTINC0     ;Transfer Message ID value
        movff   _vTemp32Data+1,POSTINC0
        movff   _vTemp32Data+2,POSTINC0
        movff   _vTemp32Data+3,POSTINC0

        movlw   low(DataLngth)
        movwf   FSR0L
        movlw   high(DataLngth) ;Transfer Data Length value
        movwf   FSR0H
        movff   _DataLength,INDF0

        movlw   low(Flags)
        movwf   FSR0L
        movlw   high(Flags)     ;Transfer Flags value
        movwf   FSR0H
        movff   _RxFlags,INDF0

        movf    _Temp1_A,W         ;Restore return value
        endm

#endif                          ;For .inc file check

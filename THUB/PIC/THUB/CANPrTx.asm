; $Id: CANPrTx.asm,v 1.2 2006-09-12 22:49:50 jschamba Exp $
;****************************************************************************
;*
;*              CAN Library routines in Assembly
;*
;****************************************************************************
;* FileName:            CANPrTx.ASM
;* Dependencies:        CANPrTx.inc
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
;* Gaurang Kavaiya      10/23/02        Modified for Application Maestro (V1.0)
;*
;*****************************************************************************

#define         CAN_PRIOR_TX_INT_SOURCE

#define         CAN_MODULE
#define         _ADD_PROC_INC_FILE
#define         GEN_MODULE_ERROR

#include        "p18f4680.inc"
#include        "CANPrTx.inc"
#include        "CANPrTx.def"

#ifndef RX0DBEN
 RX0DBEN         EQU  H'0002'    ;For backward compatibility
#endif
 
TxBufData: = D'14' * MAX_TX_SOFT_BUFFER ;Total RAM locations requirement
TxBufPtrSize: = (MAX_TX_SOFT_BUFFER + 3) * 0x02 ;
TxBufMaxSize: = MAX_TX_SOFT_BUFFER + 3 ;




                UDATA
TxBuffer        RES     TxBufData       ;Software Transmit Buffer
;TxBufPtr:      RES     TxBufPtrSize    ;TxBuffer Pointer
vCANBufSize     RES     01              ;Tx Buffer Size value

        GLOBAL  vCANBufSize

;Working regs. to be saved during Interrupt
ITemp32Data     RES     08
IReg1           RES     04
ITxFlags        RES     01
Im_TxFlags      RES     01
ITemp1          RES     01
ITemp2          RES     01
ITemp3          RES     01
IFSR0           RES     02
IFSR1           RES     02



        UDATA_ACS
TxFlags         RES     01
_Temp1_A        RES     01
Temp2           RES     01
Temp3           RES     01

        GLOBAL  _Temp1_A




;Used by mCANPrTxInit, mCANPrTxSetOpMode and mCANPrTxSetBaud function
                UDATA_OVR
_vCANSJW_O      RES     01      ;SJW value
_vCANBRP_O      RES     01      ;BRP value
_vCANPHSEG1_O   RES     01      ;Phase Segment 1 value
_vCANPHSEG2_O   RES     01      ;Phase Segment 2 value
_vCANPROPSEG2_O RES     01      ;Propagation Segment 1 value
_vFlags1_O      RES     01      ;Configuration Flags
_vReg1_O        RES     04      ;32 bit register for intermediate storage
;vTempPtr_O      RES     02
_vTemp32Data    RES     08
TFSR0           RES     02
TFSR1           RES     02

_DataLength     RES     01      ;Tx message data length
_RxFlags
_TxFlags        RES     01


        GLOBAL  _vCANSJW_O, _vCANBRP_O, _vCANPHSEG1_O, _vCANPHSEG2_O, _vCANPROPSEG2_O
        GLOBAL   _vFlags1_O, _vReg1_O, _vTemp32Data, _DataLength, _RxFlags, _TxFlags







;****************************************************************************
;* Macro:               SaveFSR0
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        None
;*
;* Overview:            It copies the content of FSR0 in Temp. FSR0 reg.
;*
;****************************************************************************
SaveFSR0        macro
        movff   FSR0L,TFSR0
        movff   FSR0H,TFSR0+1
        endm

;****************************************************************************
;* Macro:               SaveFSR1
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        None
;*
;* Overview:            It copies the content of FSR1 in Temp. FSR1 reg.
;*
;****************************************************************************
SaveFSR1        macro
        movff   FSR1L,TFSR1
        movff   FSR1H,TFSR1+1
        endm



;****************************************************************************
;* Macro:               RestoreFSR0
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        None
;*
;* Overview:            It restores the content of FSR0 from Temp. FSR0 reg.
;*
;****************************************************************************
RestoreFSR0     macro
        movff   TFSR0,FSR0L
        movff   TFSR0+1,FSR0H
        endm

;****************************************************************************
;* Macro:               RestoreFSR1
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        None
;*
;* Overview:            It restores the content of FSR1 from Temp. FSR1 reg.
;*
;****************************************************************************
RestoreFSR1     macro
        movff   TFSR1,FSR1L
        movff   TFSR1+1,FSR1H
        endm








CANLib  CODE
;****************************************************************************
;* Function:            void CANInit(BYTE SJW,
;*                      BYTE BRP,
;*                      BYTE PHSEG1,
;*                      BYTE PHSEG2,
;*                      BYTE PROPSEG,
;*                      enum CAN_CONFIG_FLAGS flags)
;*
;* Input:               _vCANSJW_O - SJW value as defined in 18CXX8 datasheet
;*                      (Must be between 1 thru 4)
;*                      _vCANBRP_O - BRP value as defined in 18CXX8 datasheet
;*                      (Must be between 1 thru 64)
;*                      _vCANPHSEG1_O - PHSEG1 value as defined in 18CXX8 datasheet
;*                      Must be between 1 thru 8)
;*                      _vCANPHSEG2_O - PHSEG2 value as defined in 18CXX8 datasheet
;*                      (Must be between 1 thru 8)
;*                      _vCANPROPSEG2_O - PROPSEG value as defined in 18CXX8
;*                      datasheet
;*                      (Must be between 1 thru 8)
;*                      _vFlags1_O - Value of type enum CAN_CONFIG_FLAGS
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
;*                      W, STATUS, BSR and FSR0 changed
;*
;* Overview:            Initializes CAN module
;*
;* Stack requirements:  3 level deep
;*
;****************************************************************************

CANInit:

        GLOBAL  CANInit

;Set configuration mode
        mCANSetOpMode     CAN_OP_MODE_CONFIG      ;
        call    CANSetBaudRate

        movlw   CAN_CONFIG_MSG_BITS
        andwf   _vFlags1_O,W
        movwf   RXB0CON         ;Load Rx Buffer 0 Control reg.
        btfsc   _vFlags1_O,CAN_CONFIG_DBL_BUFFER_BIT_NO
        bsf     RXB0CON,RX0DBEN ;Set double Buffer Enable bit

        movff   RXB0CON,RXB1CON ;Load same configuration in Rx Buffer 1
                                ;control register


        mCANSetReg_IF    CAN_MASK_B0, 0, _vFlags1_O        ;Set Mask B0
        mCANSetReg_IF    CAN_MASK_B1, 0, _vFlags1_O        ;Set Mask B1
        mCANSetReg_IF    CAN_FILTER_B0_F1, 0, _vFlags1_O   ;Set Filter 1
        mCANSetReg_IF    CAN_FILTER_B0_F2, 0, _vFlags1_O   ;Set Filter 2
        mCANSetReg_IF    CAN_FILTER_B1_F1, 0, _vFlags1_O   ;Set Filter 3
        mCANSetReg_IF    CAN_FILTER_B1_F2, 0, _vFlags1_O   ;Set Filter 4
        mCANSetReg_IF    CAN_FILTER_B1_F3, 0, _vFlags1_O   ;Set Filter 5
        mCANSetReg_IF    CAN_FILTER_B1_F4, 0, _vFlags1_O   ;Set Filter 6

; Restore to Normal mode.
        mCANSetOpMode     CAN_OP_MODE_NORMAL      ;
        banksel vCANBufSize
        clrf    vCANBufSize       ;Clear Tx Buffer data counter

#ifdef  CANIntLowPrior
        bsf     RCON,IPEN       ;Enable Priority levels on Int.
        movlw   B'11100011'
        andwf   IPR3,F          ;Set low priority for Tx. Int.
#else
        movlw   B'00011100'
        iorwf   IPR3,F          ;Set high priority for Tx. Int. (Default)
#endif

        bsf     INTCON,GIE      ;Enable global Interrupt
        bsf     INTCON,PEIE     ;Enable Peripheral Interrupt

        return





;****************************************************************************
;* Function:            void CANSetOpMode(CAN_OP_MODE mode)
;*
;* PreCondition:        None
;*
;* Input:               W reg   - Operation mode code
;*
;* Output:              MCU is set to requested mode
;*
;* Side Effects:        W, STATUS changed
;*
;* Overview:            Given mode byte is copied to CANCON and made
;*                      sure that requested mode is set.
;*
;* Note:                This is a blocking call.  It will not return until
;*                      requested mode is set.
;*
;* Stack requirements:  1 level deep
;*
;****************************************************************************

CANSetOpMode:

        GLOBAL  CANSetOpMode
        movwf   CANCON          ;Request desired mode
        movwf   _Temp1_A        ;Store value in Temp reg. for future

ChkModeSet:
        movlw   CAN_OP_MODE_BITS
        andwf   CANSTAT,W       ;Chk CAN status register
        xorwf   _Temp1_A,W
        bnz     ChkModeSet      ;Wait till desired mode is set

        return





;****************************************************************************
;* Function:            void CANSetBaudRate(BYTE SJW,
;*                                          BYTE BRP,
;*                                          BYTE PHSEG1,
;*                                          BYTE PHSEG2,
;*                                          BYTE PROPSEG,
;*                                          enum CAN_CONFIG_FLAGS flags)
;*
;* PreCondition:        MCU must be in Configuration mode or else these
;*                      values will be ignored.
;*
;* Input:               _vCANSJW_O   - SJW value as defined in 18CXX8 datasheet
;*                              (Must be between 1 thru 4)
;*                      _vCANBRP_O   - BRP value as defined in 18CXX8 datasheet
;*                              (Must be between 1 thru 64)
;*                      _vCANPHSEG1_O - PHSEG1 value as defined in 18CXX8
;*                               datasheet
;*                              (Must be between 1 thru 8)
;*                      _vCANPHSEG2_O - PHSEG2 value as defined in 18CXX8
;*                               datasheet
;*                              (Must be between 1 thru 8)
;*                      m_PROPSEG - PROPSEG value as defined in 18CXX8
;*                               datasheet
;*                              (Must be between 1 thru 8)
;*                              flags   - Value of type enum CAN_CONFIG_FLAGS
;*
;* Output:              CAN bit rate is set as per given values.
;*
;* Side Effects:        W, STATUS, BSR, PRODL is changed
;*
;* Overview:            Given values are bit adjusted to fit in 18CXX8
;*                      BRGCONx registers and copied.
;*
;* Stack requirements:  1 level deep
;*
;****************************************************************************

CANSetBaudRate:

        GLOBAL  CANSetBaudRate

        movff   _vCANSJW_O,_Temp1_A
        decf    _Temp1_A,F      ;Align values for offfset from 0
        movlw   0x40            ;Multiply by 40H to align the bits
        mulwf   _Temp1_A        ;for BRGCON1 requirement
        movff   PRODL,_Temp1_A  ;Transfer Result to _Temp1_A

        movlw   0xc0
        andwf   _Temp1_A,F      ;Mask bits
        banksel _vCANBRP_O
        decf    _vCANBRP_O,W    ;Align values for offset from 0
        iorwf   _Temp1_A,W      ;Calculate value for BRGCON1
        movwf   BRGCON1         ;Transfer value to BRGCON1

        movff   _vCANPHSEG1_O,_Temp1_A
        decf    _Temp1_A,F
        rlncf   _Temp1_A,F      ;Align the bits
        rlncf   _Temp1_A,F
        rlncf   _Temp1_A,W
;        banksel _vCANPROPSEG2_O
        decf    _vCANPROPSEG2_O,F    ;Align values for offset 0
        iorwf   _vCANPROPSEG2_O,W    ;Calculate value for BRGCON2
        movwf   BRGCON2         ;Transfer value to BRGCON2
        btfsc   _vFlags1_O,CAN_CONFIG_PHSEG2_PRG_BIT_NO
        bsf     BRGCON2,SEG2PHTS        ;Set SEG2PHTS
        btfsc   _vFlags1_O,CAN_CONFIG_SAMPLE_BIT_NO
        ; bsf     BRGCON2,SAM     ;Set SEG2PHTS
        bcf     BRGCON2,SAM     ;Set SEG2PHTS

        movff   _vCANPHSEG2_O,BRGCON3        ;Transfer PHSEG2 value to BRGCON3
        decf    BRGCON3,F
        btfsc   _vFlags1_O,CAN_CONFIG_LINE_FILTER_BIT_NO
        bsf     BRGCON3,WAKFIL  ;Set WAKFIL bit

        return





;****************************************************************************
;* Function:            CANSetReg   RegAddr,
;*                                  unsigned long val,
;*                                  CAN_CONFIG_FLAGS type
;*
;* PreCondition:        None
;*
;* Input:               FSR0H:FSR0L - Starting address of a 32-bit buffer to
;*                                      be updated
;*                      _vReg1_O:_vReg1_O+3 - 32-bit value to be converted
;*                      (_vReg1_O= LL, _vReg1_O+1 =LH, _vReg1_O+2 = HL and _vReg1_O+3 = HH
;*                       byte)
;*                      _vFlags1_O - Type of message Flag - either
;*                              CAN_CONFIG_XTD_MSG or CAN_CONFIG_STD_MSG
;*
;* Output:              Given CAN id value 'val' is bit adjusted and copied
;*                      into corresponding PIC18XXX8 CAN registers
;*
;* Side Effects:        Databank, W, STATUS and FSR0 changed
;*
;* Overview:            If given id is of type standard identifier,
;*                      only SIDH and SIDL are updated
;*                      If given id is of type extended identifier,
;*                      bits val<17:0> is copied to EIDH, EIDL and SIDH<1:0>
;*                      bits val<28:18> is copied to SIDH and SIDL
;*
;* Stack requirements:  2 level deep
;*
;****************************************************************************
CANSetReg:

        GLOBAL  CANSetReg
        banksel _vFlags1_O
        btfss   _vFlags1_O,CAN_CONFIG_MSG_TYPE_BIT_NO
        bra     SetExtFram

        movlw   0x05            ;Rotate Left 5 times the 32 bit number
        rcall   _RotateLeft32N
        movff   _vReg1_O+1,POSTINC0
 ;       banksel _vReg1_O
        movlw   0xe0
        andwf   _vReg1_O,W
        movwf   INDF0
        return

SetExtFram
        movlw   0x03            ;Rotetae Left 5 times the 32 bit number
        rcall   _RotateLeft32N
        movff   _vReg1_O+3,POSTINC0 ;Set EID<28:21>
        movff   _vReg1_O+2,INDF0    ;Set EID <20:18>

        movlw   0x03            ;Rotate Right 5 times the 32 bit number
        rcall   _RotateRight32N ;to restore original number
        movlw   0xe0            ;Mask other bits except EID<20:18>
        andwf   INDF0,F
        bsf     INDF0,EXIDE     ;Set  EXIDE bit
        movlw   0x03
        andwf   _vReg1_O+2,W
        iorwf   POSTINC0,F      ;Set EID<17:16>

        movff   _vReg1_O+1,POSTINC0
        movff   _vReg1_O,POSTINC0

        return






;****************************************************************************
;* Function:            _RotateLeft32N
;*
;*
;* PreCondition:        None
;*
;* Input:               W reg: Value for total rotation required
;*
;*                      _vReg1_O:_vReg1_O+3 - 32-bit value to be converted
;*                      (_vReg1_O= LL, _vReg1_O+1 =LH, _vReg1_O+2 = HL and _vReg1_O+3 = HH
;*                       byte)
;*
;* Output:              32 bit value in _vReg1_O shifted left by value in W times
;*
;* Side Effects:        Data Bank, STATUS, W changed
;*
;* Overview:            It shifts 32-bit value in _vReg1_O by W times and returns
;*                      result in _vReg1_O
;*
;****************************************************************************
_RotateLeft32N:

;        GLOBAL  _RotateLeft32N

        banksel _vReg1_O
RotateLMore:
        bcf     STATUS,C
        btfsc   _vReg1_O+3,7        ;Pre-read bit 31 to be copied into
        bsf     STATUS,C        ;Bit 0

        rlcf    _vReg1_O,F
        rlcf    _vReg1_O+1,F
        rlcf    _vReg1_O+2,F
        rlcf    _vReg1_O+3,F
        decfsz  WREG,F
        bra     RotateLMore

        return





;*********************************************************************
;* Function:            CANReadReg     RegAddr,
;*                                     Val,
;*                                     CAN_CONFIG_FLAGS type
;*
;* PreCondition:        None
;*
;* Input:               FSR0 - Starting address of a 32-bit buffer to be
;*                              read
;*                      FSR1 - Starting address of a memory location to
;*                              copy read 32 bit value
;*
;* Output:              Corresponding CAN id registers are read  and value is
;*                      bit adjusted and copied into 32-bit destination
;*
;* Side Effects:        Databank, W, STATUS, FSR0, FSR1 changed
;*
;* Overview:            If given id is of type standard identifier,
;*                      only SIDH and SIDL are read
;*                      If given id is of type extended identifier,
;*                      then EIDH and EIDL are read too to form 32 bit
;*                      value
;*
;* Stack requirements:  2 level deep
;*
;********************************************************************/
CANReadReg:

        GLOBAL  CANReadReg

        movf    POSTINC0,W      ;To increment Pointer to point towards
                                ;TxBnSIDL reg.
        btfsc   POSTDEC0,EXIDE  ;Check for Extended Fram
        bra     ReadExtFram     ;Yes Ext Frame, Read it.
                                ;No, Standard Frame
        banksel _vReg1_O
        clrf    _vReg1_O+2          ;Set High Word to 00 for STD message
        clrf    _vReg1_O+3
        movff   POSTINC0,_vReg1_O+1 ;Copy LH byte
        movff   INDF0,_vReg1_O      ;Save LL byte
        movlw   0x05
        rcall   _RotateRight32N  ;Rotate right for 5 times
        movlw   0x1f
        andwf   _vReg1_O+3,F        ;Mask EID <31:28>
        bra     CopyIDVal

ReadExtFram
        banksel _vReg1_O
        movff   POSTINC0,_vReg1_O+3 ;Save EID <28:21>
        movff   INDF0,_vReg1_O+2    ;save EID<20:16>
        clrf    _vReg1_O+1
        clrf    _vReg1_O
        movlw   0x03            ;Position EID <28:18>
        rcall   _RotateRight32N  ;
        movlw   0xfc            ;Mask EID<17:16>
        andwf   _vReg1_O+2,F
        movlw   0x03            ;Mask all except EID<17:16>
        andwf   POSTINC0,W
        iorwf   _vReg1_O+2,F
        movff   POSTINC0,_vReg1_O+1 ;Save EID<15:8>
        movff   POSTINC0,_vReg1_O   ;Save EID<7:0>

CopyIDVal
        movff   _vReg1_O,POSTINC1   ;Return LL byte
        movff   _vReg1_O+1,POSTINC1 ;Return LH byte
        movff   _vReg1_O+2,POSTINC1 ;Return HL byte (What if EXt?)
        movff   _vReg1_O+3,POSTINC1 ;Return HH byte

        return


;****************************************************************************
;* Function:            _RotateRight32N
;*
;*
;* PreCondition:        None
;*
;* Input:               W reg: Value for total rotation required
;*
;*                      _vReg1_O:_vReg1_O+3 - 32-bit value to be converted
;*                      (_vReg1_O= LL, _vReg1_O+1 =LH, _vReg1_O+2 = HL and _vReg1_O+3 = HH
;*                       byte)
;*
;* Output:              32 bit value in _vReg1_O shifted right by value in W times
;*
;* Side Effects:        Data Bank, W and STATUS changed
;*
;* Overview:            It shifts 32-bit value in _vReg1_O by W times and returns
;*                      result in _vReg1_O
;*
;****************************************************************************
_RotateRight32N:

;        GLOBAL  _RotateRight32N

        banksel _vReg1_O
RotateRMore:
        bcf     STATUS,C
        btfsc   _vReg1_O,0          ;Pre-read bit 0 to be copied into
        bsf     STATUS,C        ;Bit 31

        rrcf    _vReg1_O+3,F
        rrcf    _vReg1_O+2,F
        rrcf    _vReg1_O+1,F
        rrcf    _vReg1_O,F
        decfsz  WREG,F
        bra     RotateRMore

        return





;****************************************************************************
;* Function:            CANSendMsg
;*
;*
;* PreCondition:        None
;*
;* Input:               _vReg1_O<3:0> 32-bit Message ID
;*                      FSR1: starting address of data buffer
;*                      _DataLength - Data Length
;*                      m_Flags - CAN_TX_MSG_FLAGS type
;*
;* Output:              W reg = 0, If buffer is Full
;*                      W reg = 1, If successful
;*
;* Side Effects:        Databank, W, STATUS, FSR0, FSR1 changed
;*
;* Overview:            It copies the data in available hardware or software
;*                      buffer. If present data is of higher priority then
;*                      the data in hardware buffer then it aborts
;*                      transmission of lowest priority data in HW buffer and
;*                      copies it to SW buffer and copies present data to HW
;*                      Buffer for immediate transmission
;*
;* Stack requirements:  3 level deep
;*
;****************************************************************************
CANSendMsg:

        GLOBAL  CANSendMsg

        banksel vCANBufSize
        movf    vCANBufSize,W
        xorlw   TxBufMaxSize
        bnz     BufEmpty
        retlw   0x00            ;Send Error Code that Buffer is full

BufEmpty:
        clrf    TxFlags         ;Clear Buf set flags

        movlw   0x03
        subwf   vCANBufSize,W
        bnc     LoadHWBuf
        bra     LoadSWBuf

LoadHWBuf:

        banksel TXB0CON
        btfsc   TXB0CON,TXREQ,BANKED
        bra     ChkNxtHWBuf1

        movlw   low(TXB0SIDH)
        movwf   FSR0L           ;Save the address of destination register
        movlw   high(TXB0SIDH)
        movwf   FSR0H
        bsf     TxFlags,CANTxBuf0Flag   ;Indicate Buf 0 Set
        bra     CopyBufData


ChkNxtHWBuf1:
        banksel TXB1CON
        btfsc   TXB1CON,TXREQ, BANKED
        bra     ChkNxtHWBuf2
        movlw   low(TXB1SIDH)
        movwf   FSR0L           ;Save the address of destination register
        movlw   high(TXB1SIDH)
        movwf   FSR0H
        bsf     TxFlags,CANTxBuf1Flag   ;Indicate Buf 1 Set
        bra     CopyBufData

ChkNxtHWBuf2:
        banksel TXB2CON
        btfsc   TXB2CON,TXREQ, BANKED
        bra     CopyBufData     ; What ?
        movlw   low(TXB2SIDH)
        movwf   FSR0L           ;Save the address of destination register
        movlw   high(TXB2SIDH)
        movwf   FSR0H
        bsf     TxFlags,CANTxBuf2Flag   ;Indicate Buf 2 set

CopyBufData:
        nop
        SaveFSR0        ;FSR0 contains starting address of Reg to be read
        SaveFSR1        ;FSR1 contains starting address of Data Buffer
        mCANSetReg_PREG_DV_IF _TxFlags  ;Copy ID value in corresponding Regs.
        RestoreFSR0
        RestoreFSR1
        movlw   0x04            ;Point towards TXBnDLC reg.
        movff   _DataLength,PLUSW0
        btfss   _vFlags1_O,CAN_TX_RTR_BIT_NO
        bsf     PLUSW0,TXRTR
        incf    WREG            ;Point towards TxBnD0
        addwf   FSR0L,F         ;Add W value into FSR0 to find
        movlw   0x00
        addwfc  FSR0H,F         ;new pointer value in FSR for TxBnD0
        banksel _DataLength
        movf    _DataLength,W  ;Data Length Counter to copy all data

CopyNxtTxData:
        movff   POSTINC1,POSTINC0
        decfsz  WREG            ;All data copied?
        bra     CopyNxtTxData   ;No, Copy next data

        mDisableCANTxInt              ;Disable Interrupt occurrence

        banksel vCANBufSize
        incf    vCANBufSize       ;Indicate new Buffer size

        btfss   TxFlags,CANTxSoftBufFlag
        bra     HWBufAnal

;This section checks for higher priority message in SW buffer than the HW
;buffer. If SW buf contains higher priority message then it Aborts the
;Transmission of lowest priority message in HW buf and Exchanges the data

        call    FindPriorSWBuf  ;Returns Highest Priority buffer number in
                                ;Temp2 and Data in _vTemp32Data+4

        banksel TXB0CON
        movlw   0x03
        andwf   TXB0CON,W,BANKED
        bnz     ChkBuf1
        mCANReadReg CAN_TX_IDB0, _vTemp32Data+4    ;
        call    _Cmp32Bit        ;Check if SW buffer priority is higher than
        bc      HWBufAnal       ;TxBuf0 Priority
        banksel TXB0CON
        bcf     TXB0CON,TXREQ,BANKED    ;If yes, Request Abort

WaitAbort0:
        btfsc   PIR3,TXB0IF     ;If TxBuf0 is transmitting then TxBuf0 Empty?
        bra     TxBuf0Emptied
        btfss   TXB0CON,TXABT,BANKED    ;Message Aborted?
        bra     WaitAbort0
        bra     TxB0Abtd        ;Message was successfully Aborted

TxBuf0Emptied:
        bcf     PIR3,TXB0IF     ;If TxBuf has finished the Transmission of
        bcf     PIE3,TXB0IE     ;current message than decrease buffer size
        banksel vCANBufSize
        decf    vCANBufSize,F


TxB0Abtd:
        movlw   low(TXB0SIDH)
        movwf   FSR0L
        movlw   high(TXB0SIDH)
        movwf   FSR0H
        call    ExchangeBuffers         ;Xchng highest priority SW Buffer data
        banksel TXB0CON                 ;with Tx Buffer 0 and
        bsf     TXB0CON,TXREQ,BANKED    ;Request Transmission
        bra     HWBufAnal


ChkBuf1:
        banksel TXB1CON
        movlw   0x03
        andwf   TXB1CON,W,BANKED
        bnz     ChkBuf2

        mCANReadReg CAN_TX_IDB1, _vTemp32Data+4    ;
        call    _Cmp32Bit        ;Check if SW Buf priority is higher than
        bc      HWBufAnal       ;TxBuf1
        banksel TXB1CON
        bcf     TXB1CON,TXREQ,BANKED    ;If yes, Request Abort


WaitAbort1:
        btfsc   PIR3,TXB1IF     ;TxBuf0 Empty?
        bra     TxBuf1Emptied
        btfss   TXB1CON,TXABT,BANKED    ;Message Aborted?
        bra     WaitAbort1
        bra     TxB1Abtd        ;Message was successfully Aborted

TxBuf1Emptied:
        bcf     PIR3,TXB1IF     ;If TxBuf has finished the Transmission of
        bcf     PIE3,TXB1IE     ;current message than decrease buffer size
        banksel vCANBufSize
        decf    vCANBufSize,F


TxB1Abtd:
        movlw   low(TXB1SIDH)
        movwf   FSR0L
        movlw   high(TXB1SIDH)
        movwf   FSR0H
        call    ExchangeBuffers         ;Exchange highest priority SW buffer
        banksel TXB1CON                 ;data with Tx Buffer 1 and
        bsf     TXB1CON,TXREQ,BANKED    ;Request Transmission
        bra     HWBufAnal



ChkBuf2:
        banksel TXB2CON
        movlw   0x03
        andwf   TXB2CON,W,BANKED
        bnz     HWBufAnal

        mCANReadReg CAN_TX_IDB2, _vTemp32Data+4    ;, _TxFlags
        call    _Cmp32Bit        ;Check if SW buffer priority is higher than
        bc      HWBufAnal       ;TxBuf2
        banksel TXB2CON
        bcf     TXB2CON,TXREQ,BANKED    ;If yes, Request Abort

WaitAbort2:
        btfsc   PIR3,TXB2IF     ;TxBuf0 Empty?
        bra     TxBuf2Emptied
        btfss   TXB2CON,TXABT,BANKED    ;Message Aborted?
        bra     WaitAbort2
        bra     TxB2Abtd        ;Message was successfully Aborted

TxBuf2Emptied:
        bcf     PIR3,TXB2IF     ;If TxBuf has finished the transmission of
        bcf     PIE3,TXB2IE     ;current message then decrease Buffer Size
        banksel vCANBufSize
        decf    vCANBufSize,F

TxB2Abtd:
        movlw   low(TXB2SIDH)
        movwf   FSR0L
        movlw   high(TXB2SIDH)
        movwf   FSR0H
        call    ExchangeBuffers         ;Exchange Highest priority SW buf data
        banksel TXB2CON                 ;with TxBuf2 and
        bsf     TXB2CON,TXREQ,BANKED    ;Request Transmission

HWBufAnal:
        rcall   _SetHWBufPrior

        mEnableCANTxInt

        retlw   0x01            ;Return success Code



LoadSWBuf:
        mullw   D'14'           ;Buffer size in bytes
        movf    PRODL,W         ;Get low byte of result in W reg
        addlw   low(TxBuffer)
        movwf   FSR0L           ;Find Starting address of Soft. Buffer
        clrf    FSR0H
        movlw   high(TxBuffer)
        addwfc  FSR0H,F
        bsf     TxFlags,CANTxSoftBufFlag
        bra     CopyBufData





;****************************************************************************
;* Function:            _SetHWBufPrior
;*
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;*
;* Output:              It sets the priority of all HW Tx Buffer depending on
;*                      the Message ID in Buffer. Lower the ID value higher
;*                      the priority
;*
;*
;* Side Effects:        Databank, W and STATUS changed
;*
;* Overview:            It sets the CAN TX HW Buffer priority depending on the
;*                      CAN ID in buffer.
;*
;*
;****************************************************************************
_SetHWBufPrior:

;        GLOBAL  _SetHWBufPrior
        banksel TXB0CON
        movlw   0xfc
        andwf   TXB0CON,F,BANKED        ;Set Priority level 0 for TxBuf-0
        banksel TXB1CON
        andwf   TXB1CON,F,BANKED        ;Set Priority level 0 for TxBuf-1
        banksel TXB2CON
        andwf   TXB2CON,F,BANKED        ;Set Priority level 0 for TxBuf-2

        mCANReadReg CAN_TX_IDB0, _vTemp32Data      ;
        mCANReadReg CAN_TX_IDB1, _vTemp32Data+4    ;
        rcall   _Cmp32Bit
        btfsc   STATUS,C
        bra     Buf1HighPrior
        banksel TXB0CON
        incf    TXB0CON,F,BANKED
        bra     NxtCompare1

Buf1HighPrior:
        banksel TXB1CON
        incf    TXB1CON,F,BANKED

NxtCompare1:
        mCANReadReg CAN_TX_IDB0, _vTemp32Data      ;
        mCANReadReg CAN_TX_IDB2, _vTemp32Data+4    ;
        rcall   _Cmp32Bit
        btfsc   STATUS,C
        bra     Buf2HighPrior
        banksel TXB0CON
        incf    TXB0CON,F,BANKED
        bra     NxtCompare2

Buf2HighPrior:
        banksel TXB2CON
        incf    TXB2CON,F,BANKED

NxtCompare2:
        mCANReadReg CAN_TX_IDB1, _vTemp32Data      ;
        mCANReadReg CAN_TX_IDB2, _vTemp32Data+4    ;
        rcall   _Cmp32Bit
        btfsc   STATUS,C
        bra     Buf2HighPrior1
        banksel TXB1CON
        incf    TXB1CON,F,BANKED
        bra     NxtCompare3

Buf2HighPrior1:
        banksel TXB2CON
        incf    TXB2CON,F,BANKED

NxtCompare3:

        btfss   TxFlags,CANTxBuf0Flag
        bra     SetNxtBuf1
        banksel TXB0CON
        bsf     TXB0CON,TXREQ, BANKED
        bsf     PIE3,TXB0IE     ;Enable TxBuf0 Int.
SetNxtBuf1:
        btfss   TxFlags,CANTxBuf1Flag
        bra     SetNxtBuf2
        banksel TXB1CON
        bsf     TXB1CON,TXREQ, BANKED
        bsf     PIE3,TXB1IE     ;Enable TxBuf0 Int.
SetNxtBuf2:
        btfss   TxFlags,CANTxBuf2Flag
        bra     SetNxtBuf3
        banksel TXB2CON
        bsf     TXB2CON,TXREQ, BANKED
        bsf     PIE3,TXB2IE     ;Enable TxBuf0 Int.
SetNxtBuf3:


        return




;****************************************************************************
;* Function:            _Cmp32Bit
;*
;*
;* PreCondition:        None
;*
;* Input:               _vTemp32Data -  32-bit data 1
;*                      _vTemp32Data + 4 - 32-bit Data -2
;*
;* Output:              If Data 1 = Data 2 C =1, Z=1
;*                      If Data 1 > Data 2 C =1, Z=0
;*                      If Data 1 < Data 2 C =0, Z=0
;*
;*
;* Side Effects:        Databank W and STATUS changed
;*
;* Overview:            It compares two 32-bit data and sets the Flag
;*                      accordingly.
;*
;*
;****************************************************************************
_Cmp32Bit:

        GLOBAL  _Cmp32Bit

        banksel _vTemp32Data
        movf    _vTemp32Data+4,w
        subwf   _vTemp32Data,W

        movf    _vTemp32Data+5,w
        subwfb  _vTemp32Data+1,W

        movf    _vTemp32Data+6,w
        subwfb  _vTemp32Data+2,W

        movf    _vTemp32Data+7,w
        subwfb  _vTemp32Data+3,W

        return





;****************************************************************************
;* Function:            FindPriorSWBuf
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              Max. Priority buffer number into Temp2
;*
;* Side Effects:        Databank, W, STATUS and FSR0 changed
;*
;* Overview:            It finds highest priority Message Buffer number
;*
;****************************************************************************
FindPriorSWBuf:
        clrf    Temp3           ;Clear Buffer Counter
        banksel _vTemp32Data
        setf    _vTemp32Data      ;+4     ;Initialize Maximum data to 0
        setf    _vTemp32Data+1    ;+5
        setf    _vTemp32Data+2    ;+6
        setf    _vTemp32Data+3    ;+7

ChkNxtBufID:
        movf    Temp3,W
        mullw   D'14'           ;Buffer size in bytes
        movf    PRODL,W         ;Get result in W
        addlw   low(TxBuffer)
        movwf   FSR0L           ;Find Starting address of Soft. Buffer
        clrf    FSR0H
        movlw   high(TxBuffer)
        addwfc  FSR0H,F
;       mCANReadReg_PREG _vTemp32Data+4, CAN_CONFIG_XTD_MSG
        mCANReadReg_PREG _vTemp32Data+4
        rcall   _Cmp32Bit
        bnc     PrsntDataBig
        movff   _vTemp32Data+4 ,_vTemp32Data        ;Present Data is
                                                ;bigger so
        movff   _vTemp32Data+5 ,_vTemp32Data+1      ;save it for next comparison
        movff   _vTemp32Data+6 ,_vTemp32Data+2
        movff   _vTemp32Data+7 ,_vTemp32Data+3
        movff   Temp3,Temp2     ;Save software Buffer Number

PrsntDataBig:
        incf    Temp3,F
        movf    Temp3,W
        addlw   0x03
        banksel vCANBufSize
        xorwf   vCANBufSize,W
        bnz     ChkNxtBufID

        return





;****************************************************************************
;* Function:            ArrangeBuffers
;*
;* PreCondition:        None
;*
;* Input:               FSR0 - Starting address of buffer 1
;*                      Temp2 - SW buffer number to start sorting
;*
;* Output:              It copies buffer n+1 data to buffer n
;*                      It starts with the buffer number passed in Temp2
;*                      and ends at highest buffer
;*
;* Side Effects:        Databank, W, STATUS, FSR0 and FSR1 changed
;*
;* Overview:            It arranges the data in Software buffer for next
;*                      transmission.
;*
;****************************************************************************
ArrangeBuffers:
;       clrf    Temp2           ;Temp2 contains Buffer start number
                                ;Clear if want to start with Buf 0 to make
                                ;FIFO
XchngNxtBuf:
        movf    Temp2,W
        mullw   D'14'           ;Buffer size in bytes
        movf    PRODL,W         ;Get result in W
        addlw   low(TxBuffer)
        movwf   FSR0L           ;Find Starting address of present Soft. Buffer
        clrf    FSR0H
        movlw   high(TxBuffer)
        addwfc  FSR0H,F

        incf    Temp2,F
        movf    Temp2,W
        addlw   0x03
        banksel vCANBufSize
        subwf   vCANBufSize,W   ;Check if Max. Buf size has been reached
        bnc     EndXchng        ;Yes, then end exchanging
;       bz      EndXchng

        movf    Temp2,W
        mullw   D'14'           ;Buffer size in bytes
        movf    PRODL,W         ;Get result in W
        addlw   low(TxBuffer)
        movwf   FSR1L           ;Find Starting address of next Soft. Buffer
        clrf    FSR1H
        movlw   high(TxBuffer)
        addwfc  FSR1H,F


        movlw   D'13'
XchngNxtData:
        movff   POSTINC1,POSTINC0
        decfsz  WREG
        bra     XchngNxtData
        bra     XchngNxtBuf


EndXchng:
        return









;****************************************************************************
;* Function:            ExchangeBuffers
;*
;* PreCondition:        None
;*
;* Input:               FSR0 - Starting address of buffer 1
;*                      Temp2 - SW buffer number
;*
;* Output:
;*
;* Side Effects:        W, STATUS, PRODL, PRODH and FSR1 changed
;*
;* Overview:            It exchanges the data in Buffer pointed by FSR0 and
;*                      Software buffer (number in Temp2).
;*
;****************************************************************************
ExchangeBuffers:
        movf    Temp2,W
        mullw   D'14'           ;Buffer size in bytes
        movf    PRODL,W         ;Get result in W
        addlw   low(TxBuffer)
        movwf   FSR1L           ;Find Starting address of Soft. Buffer
        clrf    FSR1H
        movlw   high(TxBuffer)
        addwfc  FSR1H,F

        movlw   D'13'
XchngNxtData1:
        movff   INDF0,_Temp1_A
        movff   INDF1,POSTINC0
        movff   _Temp1_A,POSTINC1
        decfsz  WREG
        bra     XchngNxtData1

        return











;****************************************************************************
;* Function:            CANReadMsg
;*
;* PreCondition:        None
;*
;* Input:               FSR0 - Starting address of the buffer to store received
;*                      data
;*
;* Output:              W reg =0, If no data is pending
;*                      W reg= 1, If data is available
;*                      _vTemp32Data - Received message ID
;*                      _DataLength - Total data bytes received
;*                      _RxFlags - Type of message flags.
;*
;* Side Effects:        Databank, W, STATUS, FSR0, FSR1 changed
;*
;* Overview:            It formats the data in Rx Buffer and returns it.
;*                      It stores 32-bit Message ID, Recd. data, Data Length
;*                      and Receiver Status Flags into user supplied memory
;*                      locations.
;*
;* Stack requirements:  3 level deep
;*
;*****************************************************************************
CANReadMsg:
        GLOBAL  CANReadMsg
        SaveFSR0

        banksel _RxFlags
        clrf    _RxFlags

        btfss   RXB0CON,RXFUL
        bra     ChkRxBuf1

        movlw   B'11110001'
        andwf   CANCON,F        ;Select WIN bits for buffer 0
        bcf     PIR3,RXB0IF     ;Clear flag indicating new message in Buf 0
        btfss   COMSTAT,RXB0OVFL        ;Check for Buf 0 Overflow
        bra     B0NotOvrFlow
        bsf     _RxFlags,CAN_RX_OVERFLOW_BIT_NO

B0NotOvrFlow:
        btfsc   RXB0CON ,FILHIT0
        bsf     _RxFlags,CAN_RX_FILTER_1_BIT_NO
        bra     CopyBuffer

ChkRxBuf1:
        banksel RXB1CON
        btfss   RXB1CON,RXFUL,BANKED
        bra     ReturnRxErrCode ;Return Error code

        movlw   B'11110001'
        andwf   CANCON,F        ;Select WIN bits for buffer 1
        movlw   B'00001010'     ;
        iorwf   CANCON,F        ;
        bcf     PIR3,RXB1IF     ;Clear flag indicating new message in Buf 0

        banksel _RxFlags
        btfss   COMSTAT,RXB1OVFL        ;Check for Buf 0 Overflow
        bra     B1NotOvrFlow
        bsf     _RxFlags,CAN_RX_OVERFLOW_BIT_NO

B1NotOvrFlow:
        movlw   CAN_RX_FILTER_BITS
        andwf   RXB0CON,W       ;Because of WIN bits accessing RXB1CON
        iorwf   _RxFlags       ;Store the Acceptance filter value into
                                ;Rx_Flags
        movlw   0xf8            ;Mask all bits except 3 LSB's
        andwf   RXB0CON,W       ;And with RXB1CON
        sublw   0x02            ;Whether Filter 0 or 1 caused hit
        bz      CopyBuffer      ;No, Then copy buffer data
        bnc     CopyBuffer

        bsf     _RxFlags,CAN_RX_DBL_BUFFERED_BIT_NO


CopyBuffer:
        movlw   0x0f
        andwf   RXB0DLC,W       ;Depending on the WIN bits actual register
                                ;will be accessed.
        banksel _DataLength
        movwf   _DataLength    ;copy Data length value into register

        banksel _RxFlags
        ; btfsc   RXB0CON,RXRTRRO ;Check for Remote Frame bit
        btfsc   RXB0CON,RXRTRRO_RXB0CON ;Check for Remote Frame bit
        bsf     _RxFlags,CAN_RX_RTR_FRAME_BIT_NO

        btfsc   RXB0SIDL,EXID   ;Check for Remote Frame bit
        bsf     _RxFlags,CAN_RX_XTD_FRAME_BIT_NO

        movff   FSR0L,TFSR1     ;Transfer data in Temp. reg. for FSR1
        movff   FSR0H,TFSR1+1

        movlw   low(RXB0SIDH)   ;Point towards starting address of ID
        movwf   FSR0L
        movlw   high(RXB0SIDH)
        movwf   FSR0H

        mCANReadReg_PREG _vTemp32Data      ;, CAN_CONFIG_XTD_MSG
        RestoreFSR1             ;Get source data pointer in FSR1

        movlw   low(RXB0D0)     ;Point towards starting address of ID
        movwf   FSR0L
        movlw   high(RXB0D1)
        movwf   FSR0H

        banksel _DataLength        
        tstfsz  _DataLength
        bra     StartCopying
        bra     MarkBufferOpen
StartCopying:
        movf    _DataLength,w
CopyNxtRxData:
        movff   POSTINC0,POSTINC1
        decfsz  WREG
        bra     CopyNxtRxData

MarkBufferOpen:
        bcf     RXB0CON,RXFUL   ;Indicate that buffer is open to receive Msg.

        movlw   B'11110001'
        andwf   CANCON,F        ;Select default WIN bits

        btfss   PIR3,IRXIF      ;Check for any invalid message occurrence on
        bra     NoInvldMsg      ;the CAN bus
        bcf     PIR3,IRXIF
        banksel _RxFlags       ;Return Invalid message flag bit
        bsf     _RxFlags,CAN_RX_INVALID_MSG_BIT_NO
NoInvldMsg:

        retlw   0x01            ;Return Success code

ReturnRxErrCode:

        retlw   0x00            ;Return Error Code






;****************************************************************************
;* Function:            CANISR
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        W, STATUS and BSR changed
;*
;* Overview:            If any data is pending for transmission then it will
;*                      copy highest priority data in Empty buffer and
;*                      requests Transmission.
;*
;* Stack requirements:  4 level deep
;*

;****************************************************************************
CANISR:
        GLOBAL  CANISR
        movlw   B'00011100'     ;If all Tx interrupts are disabled
        andwf   PIR3,W
        bz      EndCANISR       ;then End ISR
        call    _SaveWorkRegs
        clrf    TxFlags
        btfss   PIR3,TXB0IF     ;TxBuf0 Empty?
        bra     ChkTxBuf1Int
        bcf     PIR3,TXB0IF
        bcf     PIE3,TXB0IE
        bsf     TxFlags,CANTxBuf0Flag
        call    FindPriorSWBuf  ;Returns Highest Priority buffer number in
                                ;Temp2 and Data in _vTemp32Data+4
        movlw   low(TXB0SIDH)
        movwf   FSR0L
        movlw   high(TXB0SIDH)
        movwf   FSR0H
        bra     BufSet


ChkTxBuf1Int:
        btfss   PIR3,TXB1IF     ;TxBuf1 Empty?
        bra     ChkTxBuf2Int
        bcf     PIR3,TXB1IF
        bcf     PIE3,TXB1IE
        bsf     TxFlags,CANTxBuf1Flag
        call    FindPriorSWBuf  ;Returns Highest Priority buffer number in
                                ;Temp2 and Data in _vTemp32Data+4
        movlw   low(TXB1SIDH)
        movwf   FSR0L
        movlw   high(TXB1SIDH)
        movwf   FSR0H
        bra     BufSet


ChkTxBuf2Int:
        btfss   PIR3,TXB2IF     ;TxBuf2 Empty?
        bra     NoBufEmpty
        bcf     PIR3,TXB2IF
        bcf     PIE3,TXB2IE
        bsf     TxFlags,CANTxBuf2Flag
        call    FindPriorSWBuf  ;Returns Highest Priority buffer number in
                                ;Temp2 and Data in _vTemp32Data+4
        movlw   low(TXB2SIDH)
        movwf   FSR0L
        movlw   high(TXB2SIDH)
        movwf   FSR0H

BufSet:
        movlw   0x03            ;Check whether any data is pending in Buffer
        banksel vCANBufSize
        decf    vCANBufSize,F
        subwf   vCANBufSize,W
        bc      BufPending
        bz      BufPending
        bra     NoBufEmpty

BufPending:
        call    ExchangeBuffers
        rcall   _SetHWBufPrior
        call    ArrangeBuffers

NoBufEmpty:
        rcall   _RestoreWorkRegs
EndCANISR
        return








;****************************************************************************
;* Function:            _SaveWorkRegs
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        None
;*
;* Overview:            It saves all GPR registers used by different functions
;*                      in Temp. locations.
;*
;****************************************************************************
_SaveWorkRegs
        movff   _vTemp32Data,ITemp32Data          ;Save _vTemp32Data
        movff   _vTemp32Data+1,ITemp32Data+1
        movff   _vTemp32Data+2,ITemp32Data+2
        movff   _vTemp32Data+3,ITemp32Data+3
        movff   _vTemp32Data+4,ITemp32Data+4
        movff   _vTemp32Data+5,ITemp32Data+5
        movff   _vTemp32Data+6,ITemp32Data+6
        movff   _vTemp32Data+7,ITemp32Data+7

        movff   _vReg1_O,IReg1      ;Save _vReg1_O
        movff   _vReg1_O+1,IReg1+1
        movff   _vReg1_O+2,IReg1+2
        movff   _vReg1_O+3,IReg1+3

        movff   _TxFlags,Im_TxFlags
        movff   TxFlags,ITxFlags
        movff   _Temp1_A,ITemp1    ;Save _Temp1_A
        movff   Temp2,ITemp2    ;Save Temp2
        movff   Temp3,ITemp3    ;Save Temp3

        movff   FSR0L,IFSR0     ;Save FSR 0
        movff   FSR0H,IFSR0+1

        movff   FSR1L,IFSR1     ;Save FSR 1
        movff   FSR1H,IFSR1+1

        return



;****************************************************************************
;* Function:            _RestoreWorkRegs
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              None
;*
;* Side Effects:        None
;*
;* Overview:            It saves all GPR registers used by different functions
;*                      in Temp. locations.
;*
;****************************************************************************
_RestoreWorkRegs
        movff   ITemp32Data,_vTemp32Data          ;Restore _vTemp32Data
        movff   ITemp32Data+1,_vTemp32Data+1
        movff   ITemp32Data+2,_vTemp32Data+2
        movff   ITemp32Data+3,_vTemp32Data+3
        movff   ITemp32Data+4,_vTemp32Data+4
        movff   ITemp32Data+5,_vTemp32Data+5
        movff   ITemp32Data+6,_vTemp32Data+6
        movff   ITemp32Data+7,_vTemp32Data+7

        movff   IReg1,_vReg1_O      ;Restore _vReg1_O
        movff   IReg1+1,_vReg1_O+1
        movff   IReg1+2,_vReg1_O+2
        movff   IReg1+3,_vReg1_O+3

        movff   ITxFlags,TxFlags
        movff   Im_TxFlags,_TxFlags
        movff   ITemp1,_Temp1_A    ;Restore _Temp1_A
        movff   ITemp2,Temp2    ;Restore Temp2
        movff   ITemp3,Temp3    ;Restore Temp3

        movff   IFSR0,FSR0L     ;Restore FSR 0
        movff   IFSR0+1,FSR0H

        movff   IFSR1,FSR1L     ;Restore FSR 1
        movff   IFSR1+1,FSR1H

        return






;*****************************************************************************
;* Function:            CANIsTxPassive()
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              C = 1, if CAN transmit module is error passive as
;*                      defined by CAN specifications.
;*                      C = 0, if CAN transmit module is in active state
;* Side Effects:        STATUS changed
;*
;*****************************************************************************
#ifdef  ADD_CANIsTxPassive
CANIsTxPassive
        GLOBAL  CANIsTxPassive
        bcf     STATUS,C
        btfsc   COMSTAT,TXBP
        bsf     STATUS,C        ;If Bus is in Tx passive state, set C
        return
#endif


;*****************************************************************************
;* Function:            CANIsRxPassive()
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              C = 1, if CAN receive module is error passive as
;*                      defined by CAN specifications.
;*                      C = 0, if CAN receive module is in active state
;* Side Effects:        STATUS changed
;*
;*****************************************************************************
#ifdef  ADD_CANIsRxPassive
CANIsRxPassive
        GLOBAL  CANIsRxPassive
        bcf     STATUS,C
        btfsc   COMSTAT,RXBP
        bsf     STATUS,C        ;If Bus is in Rx passive state, set C
        return
#endif



;*****************************************************************************
;* Function:            CANIsBusOff()
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              C = 1, if CAN transmit module is in Bus Off state as
;*                      defined by CAN specifications.
;*                      C = 0, if CAN module is not in bus Off state
;* Side Effects:        STATUS changed
;*
;*****************************************************************************
#ifdef  ADD_CANIsBusOff
CANIsBusOff

        GLOBAL  CANIsBusOff
        bcf     STATUS,C
        btfsc   COMSTAT,TXBO
        bsf     STATUS,C        ;If Bus is in off state, set C
        return
#endif



;****************************************************************************
;* Function:            BOOL  CANIsRxReady()
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              C=1, If one of the receive buffer is empty
;*                      C=0, If none of the receive buffer is empty.
;*
;* Side Effects:        Data banks, STATUS  changed
;*
;****************************************************************************
#ifdef  ADD_CANIsRxReady
CANIsRxReady

        GLOBAL  CANIsRxReady
        bcf     STATUS,C
        btfsc   RXB0CON,RXFUL
        bsf     STATUS,C        ;If buffer is empty than set carry to
                                ;indicate

        banksel RXB1CON
        btfsc   RXB1CON,RXFUL,BANKED
        bsf     STATUS,C

        return
#endif


;****************************************************************************
;* Macro:               BOOL CANIsTxReady()
;*
;* PreCondition:        None
;*
;* Input:               None
;*
;* Output:              C=1, If at least one CAN transmit buffer is empty
;*                      C=0, If all CAN transmit buffers are full
;*
;* Side Effects:        Databank, W and STATUS changed
;*
;****************************************************************************
#ifdef  ADD_CANIsTxReady
CANIsTxReady

        GLOBAL  CANIsTxReady
        banksel vCANBufSize
        movf    vCANBufSize,W
        sublw   TxBufMaxSize
        bnz     TxReady1
        bcf     STATUS,C        ;
TxReady1:
        return
#endif




        END




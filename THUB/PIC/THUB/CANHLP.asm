; $Id: CANHLP.asm,v 1.1 2007-03-29 15:25:12 jschamba Exp $
;******************************************************************************
;                                                                             *
;    Filename:      CANHLP.asm                                                *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:        J. Schambach                                              *
;    Company:                                                                 *
;                                                                             * 
;******************************************************************************

#define HLP_PRIOR_SOURCE

	#include <P18F4680.INC>		;processor specific variable definitions
    #include "CANHLP.inc"
	#include "CANPrTx.inc"		;CAN functions
    #include "SRunner.inc"
    #include "THUB.def"         ; bit definitions

    EXTERN  CANDt1, RxData, RxMsgID, RxFlag, RxDtLngth, QuietFlag

CANHLP CODE
;**************************************************************
;* Now handle HLP commands.
;* 
;* which write command?
;**************************************************************
TofHandleWrite:
    GLOBAL TofHandleWrite

    ;**************************************************************
    ;****** Write PLD Register: ***********************************
    ;* msgID = 0x402
    ;* RxData[0] = Register address, 0x80 < address < 0xff
    ;* RxData[1] = Data to write
    ;**************************************************************
    btfss   RxData, 7           ; test if bit 7 in RxData[0] is set
    bra     is_it_MCU_RDOUT_MODE    ; false: test next command
    call    TofWriteReg         ; true: write PLD register
    return
is_it_MCU_RDOUT_MODE:
    ;**************************************************************
    ;****** Set MCU DATA Readout Mode: ****************************
    ;* msgID = 0x402
    ;* RxData[0] = 0xa
    ;* RxData[1] = 1: Don't read PLD data
    ;*           = 0: Read PLD data and send it
    ;**************************************************************
    movf    RxData,W            ; WREG = RxData
    sublw   0x0A                ; if (RxData[0] == 0x0a)
    bnz     is_it_programPLD    ; false: test next command
    call    TofSetRDOUT_MODE    ; true: set MCU DATA Readout Mode
    return
is_it_programPLD:
    movf    RxData,W            ; WREG = RxData
    andlw   0xF8
    sublw   0x20                ; if (32 <= RxData[0] <= 39)
    bnz     unknown_message     ; false: send error message
    call    TofProgramPLD       ; true: a "program PLD" command
    return
    

;**************************************************************
;* which read command? 
;**************************************************************
TofHandleRead:
    GLOBAL TofHandleRead

    ;**************************************************************
    ;****** Read Silicon ID ***************************************
    ;* msgID = 0x404
    ;* RxData[0] = 0x27
    ;*
    ;* Effect: read Silicon ID of EEPROM and return as a
    ;*          Read Response (not quite logical, need to correct this!)
    ;**************************************************************
    movf    RxData,W
    sublw   0x27
    bnz     is_it_TofReadReg  
    call    TofReadSiID
    return

is_it_TofReadReg:
    ;**************************************************************
    ;****** Read PLD Register *************************************
    ;* msgID = 0x404
    ;* RxData[0] = Register address, 0x80 < address < 0xff
    ;**************************************************************
    btfss   RxData, 7       ; if ( 0x80 < RxData[0] < 0xFF )
    bra     unknown_message ; false: send error message
    call    TofReadReg      ; true: read PLD register
    return

    ;**************************************************************
    ;****** Unknown Message Response ******************************
    ;* msgID = 0x407
    ;* RxData[0..x] = originally sent message bytes just echoed
    ;**************************************************************
unknown_message: 
    ; send an error message here (message ID=0x407)
    movlw   0x07
    movwf   RxMsgID
    ; byte 1 should already contain 0x4, so no need to set it again)
    movlw   CAN_TX_STD_FRAME
    movwf   RxFlag
unknownMsgAgn
    nop
    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    addlw   0x00            ; Check for return value of 0 in WREG
    bz      unknownMsgAgn   ; Buffer Full, Try again
    return

;**************************************************************
;* CAN "Write" Commands
;**************************************************************
TofSetRDOUT_MODE:
    ;**************************************************************
    ;****** Set Readout Mode **************************************
    ;**************************************************************
    movff   RxData+1, QuietFlag
    return

TofWriteReg:
    ;**************************************************************
    ;****** Write Register ****************************************
    ;**************************************************************
    movff   RxData, PORTD   ; put first byte as register address on PORTD
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    movff   RxData+1, PORTD ; second byte as register data on PORTD
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    return                  ; back to receiver loop

TofProgramPLD:
    ;**************************************************************
    ;****** Initialize Program EEPROM *****************************
    ;* msgID = 0x402
    ;* RxData[0] = 0x20
    ;* Effect: call asStart, followed by asBulkErase
    ;**************************************************************
    movf    RxData,W        ; WREG = RxData
    sublw   0x20
    bnz     is_it_writeAddress
    call    asStart
    call    asBulkErase
    ; send WriteResponse packet
    movlw   0x03
    movwf   RxMsgID
    movlw   CAN_TX_STD_FRAME
    movwf   RxFlag
    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    return

is_it_writeAddress:
    ;**************************************************************
    ;****** Write EEPROM Address **********************************
    ;* msgID = 0x402
    ;* RxData[0] = 0x21
    ;* RxData[1] = asAddress[23:16] 
    ;* RxData[2] = asAddress[15: 8]
    ;* RxData[3] = asAddress[ 7: 0]
    ;*
    ;* Effect: set the EEPROM address to write to
    ;**************************************************************
    ;       and reset FSR1H to beginning of "asDataBytes"
    movf    RxData,W
    sublw   0x21
    bnz     is_it_writeDataByte
    movff   RxData+1, asAddress
    movff   RxData+2, asAddress+1
    movff   RxData+3, asAddress+2
    movlw   low(asDataBytes)
    movwf   FSR2L
    movlw   high(asDataBytes)
    movwf   FSR2H
    ; sendWriteResponse
    movlw   0x03
    movwf   RxMsgID
    movlw   CAN_TX_STD_FRAME
    movwf   RxFlag
    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    return

is_it_writeDataByte:
    ;**************************************************************
    ;****** Write EEPROM Data **********************************
    ;* msgID = 0x402
    ;* RxData[0] = 0x22
    ;* RxData[1..x] = DataByte[0..x-1] 
    ;*
    ;* Effect: write data bytes to RAM pointed to by FSR1 and 
    ;*          increase FSR1 pointer appropriately, so that
    ;*          consecutive "Write EEPROM Data" commands write to 
    ;*          consecutive RAM locations
    ;**************************************************************
    movf    RxData,W
    sublw   0x22
    bnz     is_it_writePage
    movlw   low(RxData+1)
    movwf   FSR0L
    movlw   high(RxData+1)
    movwf   FSR0H
    movf    RxDtLngth,W
    decfsz  WREG,W
    bra     mainProgLoop1
    ; sendWriteResponse
    movlw   0x03
    movwf   RxMsgID
    ; byte 1 of RxMsgID should already contain 0x4, so no need to set it again
    movlw   CAN_TX_STD_FRAME
    movwf   RxFlag
    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    return
mainProgLoop1:
    movff   POSTINC0, POSTINC2
    decfsz  WREG,W
    bra     mainProgLoop1
    ; sendWriteResponse
;    movlw   0x03
;    movwf   RxMsgID
;    movlw   CAN_TX_STD_FRAME
;    movwf   RxFlag
;    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    return   

is_it_writePage:
    ;**************************************************************
    ;****** Program 256 *******************************************
    ;* msgID = 0x402
    ;* RxData[0] = 0x23
    ;* RxData[1..x] = DataByte[0..x-1] 
    ;*
    ;* Effect: write data bytes to RAM pointed to by FSR1 and
    ;*          call asProgram256 afterwards, which writes this
    ;*          page to the EEPROM
    ;**************************************************************
    movf    RxData,W
    sublw   0x23
    bnz     is_it_endPLDProgram
    movlw   low(RxData+1)
    movwf   FSR0L
    movlw   high(RxData+1)
    movwf   FSR0H
    movf    RxDtLngth,W
    decfsz  WREG,W
    bra     mainProgLoop2
    ; sendWriteResponse
    movlw   0x03
    movwf   RxMsgID
    ; byte 1 of RxMsgID should already contain 0x4, so no need to set it again
    movlw   CAN_TX_STD_FRAME
    movwf   RxFlag
    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    return
mainProgLoop2:
    movff   POSTINC0, POSTINC2
    decfsz  WREG,W
    bra     mainProgLoop2
    call    asProgram256
    ; sendWriteResponse
    movlw   0x03
    movwf   RxMsgID
    ; byte 1 of RxMsgID should already contain 0x4, so no need to set it again
    movlw   CAN_TX_STD_FRAME
    movwf   RxFlag
    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    return

is_it_endPLDProgram:
    ;**************************************************************
    ;****** Program EEPROM Done ***********************************
    ;* msgID = 0x402
    ;* RxData[0] = 0x24
    ;*
    ;* Effect: call asDone
    ;**************************************************************
    ; 0x24: call asDone
    movf    RxData,W
    sublw   0x24
    bz      TofEndPLDProgram
    call    unknown_message
    return

TofEndPLDProgram:
    call    asDone
    ; sendWriteResponse
    movlw   0x03
    movwf   RxMsgID
    ; byte 1 of RxMsgID should already contain 0x4, so no need to set it again
    movlw   CAN_TX_STD_FRAME
    movwf   RxFlag
    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    return


;**************************************************************
;* CAN "Read" Commands
;**************************************************************

    ;**************************************************************
    ;****** Read Register *****************************************
    ;**************************************************************
TofReadReg:
    ;setup address pointer to CAN payload
    movlw   low(CANDt1)
    movwf   FSR0L
    movlw   high(CANDt1)
    movwf   FSR0H

    banksel PORTD
    movff   RxData, LATD    ; put first byte as register address on PORTD
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low
    
    setf    TRISD           ; set PORT D as input
    bcf     uc_fpga_DIR     ; DIR low
    bsf     uc_fpga_DS      ; DS hi
    movff   PORTD, POSTINC0 ; move PORT D data to CAN TX buffer
    bcf     uc_fpga_DS      ; DS lo
    bsf     uc_fpga_DIR     ; DIR hi
    clrf    TRISD           ; PORT D as output again
MsgTofAgn:
    mCANSendMsg  0x405,CANDt1,1,CAN_TX_STD_FRAME
    addlw   0x00            ; Check for return value of 0 in W
    bz      MsgTofAgn       ; Buffer Full, Try again
    return                  ; back to receiver loop

    ;**************************************************************
    ;****** Read Silicon ID ***************************************
    ;**************************************************************
TofReadSiID:
    mAsReadSiliconID    CANDt1
Msg9Agn:
    mCANSendMsg  0x405,CANDt1,1,CAN_TX_XTD_FRAME
    addlw   0x00            ; Check for return value of 0 in W
    bz      Msg9Agn         ; Buffer Full, Try again
    return                  ; back to receiver loop


    END

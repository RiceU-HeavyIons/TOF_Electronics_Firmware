; $Id: main.asm,v 1.2 2006-08-30 18:46:02 jschamba Exp $
;******************************************************************************
;   This file is a basic template for assembly code for a PIC18F2525. Copy    *
;   this file into your project directory and modify or add to it as needed.  *
;                                                                             *
;   The PIC18FXXXX architecture allows two interrupt configurations. This     *
;   template code is written for priority interrupt levels and the IPEN bit   *
;   in the RCON register must be set to enable priority levels. If IPEN is    *
;   left in its default zero state, only the interrupt vector at 0x008 will   *
;   be used and the WREG_TEMP, BSR_TEMP and STATUS_TEMP variables will not    *
;   be needed.                                                                *
;                                                                             *
;   Refer to the MPASM User's Guide for additional information on the         *
;   features of the assembler.                                                *
;                                                                             *
;   Refer to the PIC18F2585/4585/2680/4680 Data Sheet for additional          *
;   information on the architecture and instruction set.                      *
;                                                                             *
;******************************************************************************
;                                                                             *
;    Filename:      main.asm                                                             *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:        J. Schambach                                                                 *
;    Company:                                                                 *
;                                                                             * 
;******************************************************************************
;                                                                             *
;    Files required:         P18F4680.INC                                     *
;			                 18F4680.LKR               			              *
;									                                          *
;                                                                             *
;                                                                             *
;******************************************************************************

	LIST P=18F4680, F=INHX32	;directive to define processor, HEX file format
	#include <P18F4680.INC>		;processor specific variable definitions
	#include "CANPrTx.inc"		;CAN functions
    #include "THUB.def"         ; bit definitions
    #include "SRunner.inc"

	EXTERN Init18F4680

#define TX_TEST
#define RX_TEST
	
;******************************************************************************
;Configuration bits
;Microchip has changed the format for defining the configuration bits, please 
;see the .inc file for futher details on notation.  Below are a few examples.


;   Oscillator Selection:
	CONFIG	OSC = ECIO, FCMEN = OFF, IESO = OFF
	CONFIG	PWRT = ON, BOREN = OFF, BORV = 0
	CONFIG	WDT = OFF, WDTPS = 32768
	CONFIG	MCLRE = ON, LPT1OSC = OFF
	CONFIG	PBADEN = OFF
	CONFIG	DEBUG = OFF
	CONFIG	XINST = OFF
	CONFIG	BBSIZ = 1024
	CONFIG	LVP = OFF
	CONFIG	STVREN = ON
	CONFIG	CP0 = OFF, CP1 = OFF, CP2 = OFF, CP3 = OFF, CPB = OFF, CPD = OFF
	CONFIG	WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF, WRTB = OFF, WRTC = OFF, WRTD = OFF
	CONFIG	EBTR0 = OFF, EBTR1 = OFF, EBTR2 = OFF, EBTR3 = OFF, EBTRB = OFF

;******************************************************************************
;Variable definitions
; These variables are only needed if low priority interrupts are used. 
; More variables may be needed to store other special function registers used
; in the interrupt routines.

		UDATA

CANDt1		    RES     08  ; CAN Tx Data
RxMsgID         RES     04  ; CAN MsgID, starting from LSB
RxData          RES     08  ; CAN Rx Data
RxDtLngth       RES     01  ; CAN Message length
RxFlag          RES     01  ; Receive flag

;		UDATA_ACS
;
;EXAMPLE		RES	1	;example of a variable in access RAM

;******************************************************************************
;EEPROM data
; Data to be programmed into the Data EEPROM is defined here


;DATA_EEPROM	CODE	0xf00000
;
;		DE	"Test Data",0,1,2,3,4,5

;******************************************************************************
;Reset vector
; This code will start executing when a reset occurs.

RESET_VECTOR	CODE	0x0000

	goto    Main		    ; go to start of main code

;******************************************************************************
;High priority interrupt vector
; This code will start executing when a high priority interrupt occurs or
; when any interrupt occurs if interrupt priorities are not enabled.

HI_INT_VECTOR	CODE	0x0008
#ifndef CANIntLowPrior
	call	CANISR          ; Call CAN Interrupt Service Routine
#endif	
	retfie	FAST		
;******************************************************************************
;Low priority interrupt vector and routine
; This code will start executing when a low priority interrupt occurs.
; This code can be removed if low priority interrupts are not used.

LOW_INT_VECTOR	CODE	0x0018
#ifdef  CANIntLowPrior
	movwf   W_IL            ; Save W
	movff   STATUS,STAT_IL  ; Save STATUS
	movff   BSR,BSR_IL      ; Save BSR
	call    CANISR          ; Call CAN Interrupt Service routine
	movff   BSR_IL,BSR      ; Restore BSR
	movff   STAT_IL,STATUS  ; Restore Status
	movf    W_IL,W          ; Restore W reg
#endif
		retfie

;******************************************************************************
;Start of main program
; The main program code is placed here.

MAIN_START	CODE
Main:

	call Init18F4680	;  Initialize all features / IO ports

;; Here is where the CAN code starts
	;; SJW=1, BRP=1, PHSEG1=5, PHSEG2=3, PROPSEG2=1, with 20MHz clock results in 1Mbit/s 
	mCANInit   1, 1, 5, 3, 1,CAN_CONFIG_ALL_VALID_MSG

;Set Loop-back mode for testing in Stand alone mode
;    mCANSetOpMode     CAN_OP_MODE_LOOP        ;Loop back mode

;Set configuration mode
	mCANSetOpMode     CAN_OP_MODE_CONFIG

;Following settings will ensure only following messages in Buf 0
; 0x012 (Filter Hit 0)
; 0x014 (Filter Hit 1)

;Set Mask B0 to 0xffffffff
    mCANSetReg CAN_MASK_B0, 0xffffffff, CAN_CONFIG_STD_MSG
;Set Filter 0 with 0x12
    mCANSetReg CAN_FILTER_B0_F1, 0x012, CAN_CONFIG_STD_MSG
;Set Filter 1 with 0x14
    mCANSetReg CAN_FILTER_B0_F2, 0x014, CAN_CONFIG_STD_MSG

; Restore to Normal mode.
    mCANSetOpMode     CAN_OP_MODE_NORMAL

;-------------------------------
;Startup Message, Data ff,00,00,00,ID 15
Msg1Agn:
    movlw   low(CANDt1)
    movwf   FSR0L
    movlw   high(CANDt1)
    movwf   FSR0H
    movlw   0xFF
    movwf   POSTINC0
    movlw   0x00
    movwf   POSTINC0
    movwf   POSTINC0
    movwf   POSTINC0
    mCANSendMsg  0x15,CANDt1,4,CAN_TX_STD_FRAME
    addlw   0x00            ; Check for return value of 0 in W
    bz      Msg1Agn         ; Buffer Full, Try again
;-------------------------------

;       mCANAbortAll         ; Use to abort transmission of all messages.
;       mCANGetTxErrCnt      ; Get Tx Error count
;       mCANGetRxErrCnt      ; Get Rx Error count

RcvMsg:

; loop until we receive a CANbus message with the above filters
Loop:                                   
    nop
	mCANReadMsg  RxMsgID, RxData, RxDtLngth, RxFlag
	xorlw   0x01
	bnz     Loop

;Message Recd. Successfully 
;       RxMsgID = 32 bit ID
;       RxData = Received Data Buffer
;       RxDtLngth = Length f Received data
;       RxFlag = Flag of CAN_RX_MSG_FLAGS type, Use it for Message
;       information
        
	nop

    movlw   CAN_RX_FILTER_BITS      ; mask out FILTER bits
    andwf   RxFlag, F               ; and store back
    
    movf    RxFlag,W                ; WREG = filter bits
    sublw   CAN_RX_FILTER_0         ; check if Filter0 fired
    bnz     is_it_read              ; if not, check next
    call    TofHandleWrite          ; if yes, it is a "Write" HLP message
    bra     Loop                    ; back to receiver loop

is_it_read:
    movf    RxFlag,W                ; WREG = filter bits
    sublw   CAN_RX_FILTER_1         ; check if Filter1 fired
    bnz     Loop                    ; if not, back to receiver loop
    call    TofHandleRead           ; if yes, it is a "Read" HLP message
    bra     Loop                    ; back to receiver loop
        
;**************************************************************
;* which write command?
;**************************************************************
TofHandleWrite:
    btfss   RxData, 7
    bra     is_it_programPLD
    call    TofWriteReg
    return
is_it_programPLD:
    movf    RxData,W        ; WREG = RxData
    andlw   0xF8
    sublw   0x20            ; if (32 <= RxData[0] <= 39)
    bnz     unknown_message ; false: send error message
    call    TofProgramPLD   ; true: write PLD register
    return

;**************************************************************
;* which read command?
;**************************************************************
TofHandleRead:
    btfss   RxData, 7       ; if ( 0x80 < RxData[0] < 0xFF )
    bra     unknown_message ; false: send error message
    call    TofReadReg      ; true: read PLD register
    return

unknown_message: 
    ; send an error message here (message ID=0x017)
    movlw   0x17
    movwf   RxMsgID
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
TofWriteReg:
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
    ; 0x20: call asStart, followed by asBulkErase
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
    ; 0x21: asAddress[23:16] = RxData[1]
    ;       asAddress[15:8]  = RxData[2]
    ;       asAddress[7:0]   = RxData[3]
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
    ; 0x22: put RxData[1:x] into RAM pointed to by FSR1    
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
    movlw   CAN_TX_STD_FRAME
    movwf   RxFlag
    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    return
mainProgLoop1:
    movff   POSTINC0, POSTINC2
    decfsz  WREG,W
    bra     mainProgLoop1
    ; sendWriteResponse
    movlw   0x03
    movwf   RxMsgID
    movlw   CAN_TX_STD_FRAME
    movwf   RxFlag
    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    return   

is_it_writePage:
    ; 0x23: put RxData[1:x] into RAM pointed to by FSR1 
    ;       then call asProgram256   
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
    movlw   CAN_TX_STD_FRAME
    movwf   RxFlag
    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    return

is_it_endPLDProgram:
    ; 0x24: call asDone
    movf    RxData,W
    sublw   0x24
    bnz     is_it_readSiID
    call    asDone
    ; sendWriteResponse
    movlw   0x03
    movwf   RxMsgID
    movlw   CAN_TX_STD_FRAME
    movwf   RxFlag
    mCANSendMsg_IID_IDL_IF RxMsgID, RxData, RxDtLngth, RxFlag 
    return

is_it_readSiID:
    movf    RxData,W
    sublw   0x27
    bz      TofReadSiID
    call    unknown_message
    return
TofReadSiID:
    mAsReadSiliconID    CANDt1
Msg9Agn:
    mCANSendMsg  0x05,CANDt1,1,CAN_TX_XTD_FRAME
    addlw   0x00            ; Check for return value of 0 in W
    bz      Msg9Agn         ; Buffer Full, Try again
    return                  ; back to receiver loop


;**************************************************************
;* CAN "Read" Commands
;**************************************************************
TofReadReg:
    movff   RxData, PORTD   ; put first byte as register address on PORTD
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low
    
    ;setup address pointer to CAN payload
    movlw   low(CANDt1)
    movwf   FSR0L
    movlw   high(CANDt1)
    movwf   FSR0H

    setf    TRISD           ; set PORT D as input
    bcf     uc_fpga_DIR     ; DIR low
    bsf     uc_fpga_DS      ; DS hi
    movff   PORTD, POSTINC0 ; move PORT D data to CAN TX buffer
    bcf     uc_fpga_DS      ; DS lo
    bsf     uc_fpga_DIR     ; DIR hi
    clrf    TRISD           ; PORT D as output again
MsgTofAgn:
    mCANSendMsg  0x20,CANDt1,1,CAN_TX_STD_FRAME
    addlw   0x00            ; Check for return value of 0 in W
    bz      MsgTofAgn       ; Buffer Full, Try again
    return                  ; back to receiver loop

;******************************************************************************
;End of program

	END

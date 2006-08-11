; $Id: main.asm,v 1.1 2006-08-11 22:11:01 jschamba Exp $
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

CANDt1		    RES     02
#ifdef  RX_TEST
RxMsgID         RES     04
RxData          RES     08
RxDtLngth       RES     01
RxFlag          RES     01
#endif

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

	goto    Main		;go to start of main code

;******************************************************************************
;High priority interrupt vector
; This code will start executing when a high priority interrupt occurs or
; when any interrupt occurs if interrupt priorities are not enabled.

HI_INT_VECTOR	CODE	0x0008
#ifndef CANIntLowPrior
	call	CANISR ; Call CAN Interrupt Service Routine
#endif	
	retfie	FAST		
;******************************************************************************
;Low priority interrupt vector and routine
; This code will start executing when a low priority interrupt occurs.
; This code can be removed if low priority interrupts are not used.

LOW_INT_VECTOR	CODE	0x0018
#ifdef  CANIntLowPrior
	movwf   W_IL            ;Save W
	movff   STATUS,STAT_IL  ;Save STATUS
	movff   BSR,BSR_IL      ;Save BSR
	call    CANISR      ;Call CAN Interrupt Service routine
	movff   BSR_IL,BSR      ;Restore BSR
	movff   STAT_IL,STATUS  ;Restore Status
	movf    W_IL,W          ;Restore W reg
#endif
		retfie

;******************************************************************************
;Start of main program
; The main program code is placed here.

MAIN_START	CODE
Main:

	call Init18F4680	;  Initialize all features

	;; now set 2 LEDs high, and 2 LEDs low:
	;; UC_CPLD0-3:	
	;; movlw	0x03
	;; movwf	PORTC
	
;; Here is where the CAN code starts
	;; SJW=1, BRP=1, PHSEG1=5, PHSEG2=3, PROPSEG2=1 
	mCANInit   1, 1, 5, 3, 1,CAN_CONFIG_ALL_VALID_MSG

;Set Loop-back mode for testing in Stand alone mode
;    mCANSetOpMode     CAN_OP_MODE_LOOP        ;Loop back mode

;Set configuration mode
	mCANSetOpMode     CAN_OP_MODE_CONFIG

;Following settings will ensure only following messages in Buf 0
; 0x25 and 0x125 (Filter Hit 0)
; 0x36 and 0x136 (Filter Hit 1)

;Set Mask B0 to 0xfffffeff
    mCANSetReg CAN_MASK_B0, 0xfffffeff, CAN_CONFIG_XTD_MSG
;Set Filter 0 with 0x25
    mCANSetReg CAN_FILTER_B0_F1, 0x025, CAN_CONFIG_XTD_MSG
;Set Filter 1 with 0x36
    mCANSetReg CAN_FILTER_B0_F2, 0x036, CAN_CONFIG_XTD_MSG



;Following settings will ensure only following messages in Buf 1
; 0x08,0x88, 0x1000008, 0x1000088 (Filter Hit 2)
; 0x06,0x86, 0x1000006, 0x1000086 (Filter Hit 3)
; 0x02,0x82, 0x1000002, 0x1000082 (Filter Hit 4)
; 0x01,0x81, 0x1000001, 0x1000081 (Filter Hit 5)

;Set Mask B1 to 0xfeffff7f
    mCANSetReg CAN_MASK_B1,0xfeffff7f, CAN_CONFIG_XTD_MSG
;Set Filter 2 with 0x08
    mCANSetReg CAN_FILTER_B1_F1,0x08, CAN_CONFIG_XTD_MSG
;Set Filter 3 with 0x05
    mCANSetReg CAN_FILTER_B1_F2,0x06, CAN_CONFIG_XTD_MSG
;Set Filter 4 with 0x02
    mCANSetReg CAN_FILTER_B1_F3,0x02, CAN_CONFIG_XTD_MSG
;Set Filter 5 with 0x01
    ;mCANSetReg CAN_FILTER_B1_F4,0x01, CAN_CONFIG_XTD_MSG
    mCANSetReg CAN_FILTER_B1_F4,0x01, CAN_CONFIG_STD_MSG

; Restore to Normal mode.
    mCANSetOpMode     CAN_OP_MODE_NORMAL


;-------------------------------
;Message 1, Data 01,02, ID 20
Msg1Agn:
    movlw   low(CANDt1)
    movwf   FSR0L
    movlw   high(CANDt1)
    movwf   FSR0H
    movlw   0x01
    movwf   POSTINC0
    movlw   0x02
    movwf   POSTINC0
    mCANSendMsg  0x20,CANDt1,2,CAN_TX_STD_FRAME
    addlw   0x00            ;Check for return value of 0 in W
    bz      Msg1Agn         ;Buffer Full, Try again
;-------------------------------


;-------------------------------
;Message 2, Data 03,04, ID 30
Msg2Agn:
    movlw   low(CANDt1)
    movwf   FSR0L
    movlw   high(CANDt1)
    movwf   FSR0H
    movlw   0x03
    movwf   POSTINC0
    movlw   0x04
    movwf   POSTINC0
    movlw   0xaa
    movwf   POSTINC0
    movlw   0xbb
    movwf   POSTINC0
    mCANSendMsg  0x30,CANDt1,4,CAN_TX_STD_FRAME
    addlw   0x00            ;Check for return value of 0 in W
    bz      Msg2Agn         ;Buffer Full, Try again
;-------------------------------


;-------------------------------
;Message 3, Data 05,06, ID 15
Msg3Agn:
    movlw   low(CANDt1)
    movwf   FSR0L
    movlw   high(CANDt1)
    movwf   FSR0H
    movlw   0x05
    movwf   POSTINC0
    movlw   0x06
    movwf   POSTINC0
    mCANSendMsg  0x15,CANDt1,2,CAN_TX_XTD_FRAME
    addlw   0x00            ;Check for return value of 0 in W
    bz      Msg3Agn         ;Buffer Full, Try again
;-------------------------------


;-------------------------------
;Message 4, Data 07,08, ID 05
Msg4Agn:
    movlw   low(CANDt1)
    movwf   FSR0L
    movlw   high(CANDt1)
    movwf   FSR0H
    movlw   0x07
    movwf   POSTINC0
    movlw   0x08
    movwf   POSTINC0
    mCANSendMsg  0x05,CANDt1,2,CAN_TX_XTD_FRAME
    addlw   0x00            ;Check for return value of 0 in W
    bz      Msg4Agn         ;Buffer Full, Try again
;-------------------------------


;-------------------------------
;Message 5, Data 09,0A, ID 10
Msg5Agn:
    movlw   low(CANDt1)
    movwf   FSR0L
    movlw   high(CANDt1)
    movwf   FSR0H
    movlw   0x09
    movwf   POSTINC0
    movlw   0x0A
    movwf   POSTINC0
    mCANSendMsg  0x10,CANDt1,2,CAN_TX_XTD_FRAME
    addlw   0x00            ;Check for return value of 0 in W
    bz      Msg5Agn         ;Buffer Full, Try again
;------------------------------



;-------------------------------
;Message 6, Data 0B,0C, ID 35
Msg6Agn:
    movlw   low(CANDt1)
    movwf   FSR0L
    movlw   high(CANDt1)
    movwf   FSR0H
    movlw   0x0B
    movwf   POSTINC0
    movlw   0x0C
    movwf   POSTINC0
    mCANSendMsg  0x35,CANDt1,2,CAN_TX_XTD_FRAME
    addlw   0x00            ;Check for return value of 0 in W
    bz      Msg6Agn         ;Buffer Full, Try again
;-------------------------------


;-------------------------------
;Message 7, Data 0D,0E, ID 20
Msg7Agn:
    movlw   low(CANDt1)
    movwf   FSR0L
    movlw   high(CANDt1)
    movwf   FSR0H
    movlw   0x0D
    movwf   POSTINC0
    movlw   0x0E
    movwf   POSTINC0
    mCANSendMsg  0x20,CANDt1,2,CAN_TX_XTD_FRAME
    addlw   0x00            ;Check for return value of 0 in W
    bz      Msg7Agn         ;Buffer Full, Try again
;-------------------------------

;-------------------------------
;Message 8, Data 0F,10, ID 05
Msg8Agn:
    movlw   low(CANDt1)
    movwf   FSR0L
    movlw   high(CANDt1)
    movwf   FSR0H
    movlw   0x0F
    movwf   POSTINC0
    movlw   0x10
    movwf   POSTINC0
    mCANSendMsg  0x05,CANDt1,2,CAN_TX_XTD_FRAME
    addlw   0x00            ;Check for return value of 0 in W
    bz      Msg8Agn         ;Buffer Full, Try again
;-------------------------------

;       mCANAbortAll         ;Use to abort transmission of all messages.
;       mCANGetTxErrCnt      ;Get Tx Error count
;       mCANGetRxErrCnt      ;Get Rx Error count

RcvMsg:
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
; move first data byte to the uc_CPLD bus, which has LEDs attached
; to the lowest 4 bits
	;; movff RxData, PORTC

;    movlw   CAN_RX_FILTER_BITS    ; mask out FILTER bits
;    andwf   RxFlag, W
;
;    sublw   CAN_RX_FILTER_0
;    bz      TofWriteReg 
;
;    movlw   CAN_RX_FILTER_BITS    ; mask out FILTER bits
;    andwf   RxFlag, W
;
;    sublw   CAN_RX_FILTER_1
;    bz      TofReadReg
;
;    movlw   CAN_RX_FILTER_BITS    ; mask out FILTER bits
;    andwf   RxFlag, W
;
;    sublw   CAN_RX_FILTER_2
;    bz      TofReadSiID
;
    movlw   CAN_RX_FILTER_BITS      ; mask out FILTER bits
    andwf   RxFlag, F               ; and store back
    
    movf    RxFlag,W                ; WREG = filter bits
    sublw   CAN_RX_FILTER_0
    bz      TofWriteReg 

    movf    RxFlag,W
    sublw   CAN_RX_FILTER_1
    bz      TofReadReg

    movf    RxFlag,W
    sublw   CAN_RX_FILTER_2
    bz      TofReadSiID

    movf    RxFlag,W
    sublw   CAN_RX_FILTER_5
    bz      Msg8Agn

    nop

    bra     Loop
        
TofWriteReg:
    movff   RxData, PORTD   ; put first byte as register address on PORTD
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    movff   RxData+1, PORTD ; second byte as register data on PORTD
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bra     Loop            ; back to receiver loop

TofReadReg:
    movff   RxData, PORTD   ; put first byte as register address on PORTD
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low
    
;Message 1, Data 01,02, ID 20
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
    addlw   0x00            ;Check for return value of 0 in W
    bz      MsgTofAgn       ;Buffer Full, Try again
    bra     Loop            ; back to receiver loop

TofReadSiID:

    mAsReadSiliconID    CANDt1
;-------------------------------
;Message 9, Data 0F,10, ID 07
Msg9Agn:
    mCANSendMsg  0x07,CANDt1,1,CAN_TX_XTD_FRAME
    addlw   0x00            ;Check for return value of 0 in W
    bz      Msg9Agn         ;Buffer Full, Try again
    bra Loop                ; back to receiver loop

;******************************************************************************
;End of program

	END

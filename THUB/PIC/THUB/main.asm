; $Id: main.asm,v 1.13 2007-05-23 18:16:29 jschamba Exp $
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
;    Filename:      main.asm                                                  *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:        J. Schambach                                              *
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
    #include "CANHLP.inc"       ; CAN HLP functions 
    #include "SRunner.inc"      ; SRunner functions
    #include "THUB.def"         ; bit definitions

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


    __idlocs _IDLOC0, 0x1 ;IDLOC register 0 will be programmed to 1.
    __idlocs _IDLOC1, 0x2 ;IDLOC register 1 will be programmed to 2.
    __idlocs _IDLOC2, 0x3 ;IDLOC register 2 will be programmed to 3.
    __idlocs _IDLOC3, 0x4 ;IDLOC register 3 will be programmed to 4.
    __idlocs _IDLOC4, 0x5 ;IDLOC register 4 will be programmed to 5.
    __idlocs _IDLOC5, 0x6 ;IDLOC register 5 will be programmed to 6.
    __idlocs _IDLOC6, 0x7 ;IDLOC register 6 will be programmed to 7.
    __idlocs _IDLOC7, 0x8 ;IDLOC register 7 will be programmed to 8.

;******************************************************************************
;Variable definitions
; These variables are only needed if low priority interrupts are used. 
; More variables may be needed to store other special function registers used
; in the interrupt routines.

;		UDATA

		UDATA_ACS           ; Access Bank

CANDt1		    RES     08  ; CAN Tx Data
RxMsgID         RES     04  ; CAN MsgID, starting from LSB
RxData          RES     08  ; CAN Rx Data
RxDtLngth       RES     01  ; CAN Message length
RxFlag          RES     01  ; Receive flag
QuietFlag       RES     01  ; Boolean for micro loop
        GLOBAL  CANDt1, RxData, RxMsgID, RxFlag, RxDtLngth, QuietFlag

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
    goto    REDIR_RESET     ; go to the redirect code

;******************************************************************************
;High priority interrupt vector
; This code will start executing when a high priority interrupt occurs or
; when any interrupt occurs if interrupt priorities are not enabled.

HI_INT_VECTOR	CODE	0x0008
    goto    REDIR_HI_INT
;******************************************************************************
;Low priority interrupt vector and routine
; This code will start executing when a low priority interrupt occurs.
; This code can be removed if low priority interrupts are not used.

LOW_INT_VECTOR	CODE	0x0018
    goto    REDIR_LOW_INT   ; go to the redirect code
;#ifdef  CANIntLowPrior
;	movwf   W_IL            ; Save W
;	movff   STATUS,STAT_IL  ; Save STATUS
;	movff   BSR,BSR_IL      ; Save BSR
;	call    CANISR          ; Call CAN Interrupt Service routine
;	movff   BSR_IL,BSR      ; Restore BSR
;	movff   STAT_IL,STATUS  ; Restore Status
;	movf    W_IL,W          ; Restore W reg
;#endif
	retfie

; in this code section we check the last EEPROM data location to see if it
; contains 0xFF or a different value. In case of 0xFF we execute code
; segments that are located in "lower" (< 0x4000) memory, otherwise
; we go to code in the "upper" memory. This allows for new code to be loaded
; above 0x4000 via CANbus (to be implemented later).

REDIRECT CODE               
                            
                                
REDIR_RESET:
    clrf    EECON1
    setf    EEADR           ; Point to last location of EEDATA
    setf    EEADRH
    bsf     EECON1, RD      ; Read control code
    incfsz  EEDATA, W       ; if it is not 0xFF   
    goto    NEW_RESET_VECT  ; go to new code section, otherwise ...
    goto    Main

REDIR_HI_INT:
    clrf    EECON1
    setf    EEADR           ; Point to last location of EEDATA
    setf    EEADRH
    bsf     EECON1, RD      ; Read control code
    incfsz  EEDATA, W       ; if it is not 0xFF
    goto    NEW_HI_INT_VECT ; go to new code section, otherwise ...
#ifndef CANIntLowPrior
	call	CANISR          ; Call CAN Interrupt Service Routine
#endif	
	retfie	FAST		

REDIR_LOW_INT:
    clrf    EECON1
    setf    EEADR           ; Point to last location of EEDATA
    setf    EEADRH
    bsf     EECON1, RD      ; Read control code
    incfsz  EEDATA, W       ; if it is not 0xFF   
    goto    NEW_LOW_INT_VECT ; go to new code section, otherwise ...
	retfie		



;******************************************************************************
; Start of main program
; The main program code is placed here.
;******************************************************************************

MAIN_START	CODE
Main:

	call Init18F4680	;  Initialize all features / IO ports
    mAsSelect 8         ;  Set FPGA progamming lines to FPGA H (8)
    setf QuietFlag,0    ;  Initially don't send any PLD data (QuietFlag = 0xff)

;; Here is where the CAN code starts
	;; SJW=1, BRP=1, PHSEG1=5, PHSEG2=3, PROPSEG2=1, with 20MHz clock results in 1Mbit/s 
	mCANInit   1, 1, 5, 3, 1, CAN_CONFIG_ALL_VALID_MSG
    ;; Bill's Parameters:
	;; SJW=2, BRP=1, PHSEG1=3, PHSEG2=3, PROPSEG2=3, with 20MHz clock results in 1Mbit/s 
	;;mCANInit   2, 1, 3, 3, 3, CAN_CONFIG_ALL_VALID_MSG & CAN_CONFIG_SAMPLE_ONCE
	;; SJW=1, BRP=1, PHSEG1=8, PHSEG2=8, PROPSEG2=3, with 20MHz clock results in 500kbit/s 
	;;mCANInit   1, 1, 8, 8, 3, CAN_CONFIG_ALL_VALID_MSG ; 500kbit/s

;Set Loop-back mode for testing in Stand alone mode
;    mCANSetOpMode     CAN_OP_MODE_LOOP        ;Loop back mode

;Set configuration mode
	mCANSetOpMode     CAN_OP_MODE_CONFIG

; NodeID of THUB = 64  -> 0x400
;Following settings will ensure only following messages in Buf 0
; 0x402 (Filter Hit 0, WRITE Command) 
; 0x404 (Filter Hit 1, READ Command)

;Set Mask B0 to 0xffffffff
    mCANSetReg CAN_MASK_B0, 0xffffffff, CAN_CONFIG_STD_MSG
;Set Filter 0 with 0x402
    mCANSetReg CAN_FILTER_B0_F1, 0x402, CAN_CONFIG_STD_MSG
;Set Filter 1 with 0x404
    mCANSetReg CAN_FILTER_B0_F2, 0x404, CAN_CONFIG_STD_MSG

; Restore to Normal mode.
    mCANSetOpMode     CAN_OP_MODE_NORMAL

;-------------------------------
;Startup Message, Data ff,00,00,00,ID 0x407
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
; Send ALERT message (command = 7, msgID = 0x407)
    mCANSendMsg  0x407,CANDt1,4,CAN_TX_STD_FRAME
    addlw   0x00            ; Check for return value of 0 in W
    bz      Msg1Agn         ; Buffer Full, Try again
;-------------------------------

;       mCANAbortAll         ; Use to abort transmission of all messages.
;       mCANGetTxErrCnt      ; Get Tx Error count
;       mCANGetRxErrCnt      ; Get Rx Error count

;**************************************************************
;* Default Receive Loop
;**************************************************************
MicroLoop:
    tstfsz  QuietFlag,0 ; QuietFlag in access bank   
    bra     QuietLoop   ; if QuietFlag != 0, don't get PLD data
; get data from the PLD, if any, and send it over CANbus
    call    getPLDData
; loop until we receive a CANbus message with the above filters
QuietLoop:
	mCANReadMsg  RxMsgID, RxData, RxDtLngth, RxFlag
	xorlw   0x01
	bnz     MicroLoop

; Message Recd. Successfully 
;       RxMsgID = 32 bit ID
;       RxData = Received Data Buffer
;       RxDtLngth = Length f Received data
;       RxFlag = Flag of CAN_RX_MSG_FLAGS type, Use it for Message
;       information
    movlw   CAN_RX_FILTER_BITS      ; mask out FILTER bits
    andwf   RxFlag, F               ; and store back
    
; first check if this is a HLP Write command (msgID = 0x402)
    movf    RxFlag,W                ; WREG = filter bits
    sublw   CAN_RX_FILTER_0         ; check if Filter0 fired
    bnz     is_it_read              ; if not, check next
    call    TofHandleWrite          ; if yes, it is a "Write" HLP message
    bra     MicroLoop               ; back to receiver loop


; Now check if it is a HLP Read command (msgID = 0x404)
is_it_read:
    movf    RxFlag,W                ; WREG = filter bits
    sublw   CAN_RX_FILTER_1         ; check if Filter1 fired
    bnz     MicroLoop               ; if not, back to receiver loop
    call    TofHandleRead           ; if yes, it is a "Read" HLP message
    bra     MicroLoop               ; back to receiver loop
        

;**************************************************************
;* Get TCD Data from PLD and send it
;**************************************************************
getPLDData:
    ; setup address pointer to CAN payload
;    banksel CANDt1
    ; send TCD data with LSB in Rx[0], 0xa in Rx[3]
    lfsr    FSR0, CANDt1+3

    movlw   0xa0
    movwf   POSTDEC0

    banksel PORTD

    ; read register 0x87, contains the trigger command
    movlw   0x87   
    movwf   LATD            ; put WREG as register address on PORTD
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    setf    TRISD           ; set PORT D as input
    bcf     uc_fpga_DIR     ; DIR low
    bsf     uc_fpga_DS      ; DS hi
    movff   PORTD, POSTDEC0 ; move PORT D data to CAN TX buffer
    bcf     uc_fpga_DS      ; DS lo
    bsf     uc_fpga_DIR     ; DIR hi
    clrf    TRISD           ; PORT D as output again

;    banksel CANDt1
    ; test if trigger command not zero:
    tstfsz  CANDt1+2,0      ; if (CANDt1[2] == 0)
    bra     readToken       ; true: valid PLD Data read, read token and send it over CANbus

    ; now write to register 0x87 to advance the TCD FIFO
    banksel PORTD
    movlw   0x87   
    movwf   LATD            ; put WREG as register address on PORTD
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    bsf     uc_fpga_DS      ; DS hi
    bcf     uc_fpga_DS      ; DS lo

    return                  ; false: back to loop


readToken:
    banksel PORTD

    movlw   0x86            ; DAQ cmd, token[11:8]  
    movwf   LATD            ; put WREG as register address on PORTD
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    setf    TRISD           ; set PORT D as input
    bcf     uc_fpga_DIR     ; DIR low
    bsf     uc_fpga_DS      ; DS hi
    movff   PORTD, POSTDEC0 ; move PORT D data to CAN TX buffer
    bcf     uc_fpga_DS      ; DS lo
    bsf     uc_fpga_DIR     ; DIR hi
    clrf    TRISD           ; PORT D as output again

    movlw   0x85            ; token[7:0]
    movwf   LATD            ; put WREG as register address on PORTD
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    setf    TRISD           ; set PORT D as input
    bcf     uc_fpga_DIR     ; DIR low
    bsf     uc_fpga_DS      ; DS hi
    movff   PORTD, POSTDEC0 ; move PORT D data to CAN TX buffer
    bcf     uc_fpga_DS      ; DS lo
    bsf     uc_fpga_DIR     ; DIR hi
    clrf    TRISD           ; PORT D as output again

    ; now write to register 0x87 to advance the TCD FIFO
    movlw   0x87   
    movwf   LATD            ; put WREG as register address on PORTD
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    bsf     uc_fpga_DS      ; DS hi
    bcf     uc_fpga_DS      ; DS lo

sendPLDData:
; send a DATA packet, command = 1, msgID = 0x401
    mCANSendMsg  0x401,CANDt1,4,CAN_TX_STD_FRAME
    addlw   0x00            ; Check for return value of 0 in W
    bz      sendPLDData     ; Buffer Full, Try again

    return

;******************************************************************************
;End of program
;******************************************************************************

;******************************************************************************
; This is a stub for the "new" ("upper") program to be executed. 
; Currently, this just sets the last EEPROM location to 0xFF
; and resets the MCU.
; When a new code is to be programmed, delete this, but define the memory
; locations. Then take care in the linker file to map those locations.
;******************************************************************************
NEW_CODE_R	CODE	0x4000
    goto    Reset_EEPROM
NEW_CODE_H	CODE	0x4008
    goto    Reset_EEPROM
;
;NEW_RESET_VECT:
;NEW_HI_INT_VECT:
;NEW_LOW_INT_VECT:

DEFAULT_RST CODE    0x4018
Reset_EEPROM
    setf    EEADR           ; Point to the last byte in EEPROM
    setf    EEADRH
    setf    EEDATA          ; Boot mode control byte
    movlw   b'00000100'     ; Setup for EEData
    movwf   EECON1
    movlw   0x55            ; Unlock
    movwf   EECON2
    movlw   0xAA
    movwf   EECON2
    bsf     EECON1, WR      ; Start the write
    nop
    btfsc   EECON1, WR      ; Wait
    bra     $ - 2
    RESET

	END

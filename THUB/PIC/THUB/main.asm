; $Id$
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

	;; LIST P=18F4680, F=INHX32	; directive to define processor, HEX file format
	LIST P=18F8680, F=INHX32	; directive to define processor, HEX file format

;; define this when compiling for CANbus download (upper memory)
; #define THUB_is_upper
	#include "THUB_uc.inc"		; processor specific variable definitions
    #include "CANHLP.inc"       ; CAN HLP functions 
    #include "SRunner.inc"      ; SRunner functions
    #include "I2CMPol.inc"      ;This include all required files and variables.                

    #include "THUB.def"         ; bit definitions

	EXTERN InitMicro

;******************************************************************************
; Configuration bits
; Microchip has changed the format for defining the configuration bits, please 
; see the .inc file for futher details on notation.  Below are a few examples.


; These are the definitions for the 18F4680 micro:

#ifndef THUB_is_upper
; These are the definitions for the 18F4680 micro:
;	CONFIG	OSC = ECIO, FCMEN = OFF, IESO = OFF
;	CONFIG	PWRT = ON, BOREN = OFF, BORV = 0
;	CONFIG	WDT = OFF, WDTPS = 32768
;	CONFIG	MCLRE = ON, LPT1OSC = OFF
;	CONFIG	PBADEN = OFF
;	CONFIG	DEBUG = OFF
;	CONFIG	XINST = OFF
;	CONFIG	BBSIZ = 1024
;	CONFIG	LVP = OFF
;	CONFIG	STVREN = ON
;	CONFIG	CP0 = OFF, CP1 = OFF, CP2 = OFF, CP3 = OFF, CPB = OFF, CPD = OFF
;	CONFIG	WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF, WRTB = OFF, WRTC = OFF, WRTD = OFF
;	CONFIG	EBTR0 = OFF, EBTR1 = OFF, EBTR2 = OFF, EBTR3 = OFF, EBTRB = OFF
;
; These are the definitions for the 18F8680 micro:

	CONFIG	OSC = ECIO, OSCS = OFF
	CONFIG	PWRT = ON, BOR = OFF, BORV = 20
	CONFIG	WDT = OFF, WDTPS = 32768
	CONFIG	MODE = MC, WAIT = OFF
	CONFIG	MCLRE = ON, ECCPMX = PORTE, CCP2MX = ON
	CONFIG	DEBUG = OFF
	CONFIG	LVP = OFF, STVR = ON
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
#endif

;******************************************************************************
;Variable definitions
; These variables are only needed if low priority interrupts are used. 
; More variables may be needed to store other special function registers used
; in the interrupt routines.

;		UDATA
;temp_1          RES     1
;temp_2          RES     1

		UDATA_ACS           ; Access Bank

RxData          RES     08  ; CAN Rx Data
RxDtLngth       RES     01  ; CAN Message length
RxFlag          RES     01  ; Receive flag
QuietFlag       RES     01  ; Boolean for micro loop
CANTestDelay    RES     01  ; Boolean and delay for sending CAN test messages in a loop
checkAlertFlag  RES     01  ; Boolean for Alert messages from PLD
temp_1          RES     1
temp_2          RES     1
        GLOBAL  RxData, RxFlag, RxDtLngth, QuietFlag, CANTestDelay, checkAlertFlag

;		UDATA_ACS
;
;EXAMPLE		RES	1	;example of a variable in access RAM

;******************************************************************************
;EEPROM data
; Data to be programmed into the Data EEPROM is defined here
;DATA_EEPROM	CODE	0xf00000 ; this address gets mapped to EEPROM address 0x0
;
;		DE	"Test Data",0,1,2,3,4,5

;; use the first 32 EEPROM entries as the geographical IDs to be programmed into
;; the SerDes FPGAs
#ifndef THUB_is_upper
DATA_EEPROM	CODE	0xf00000 ; this address gets mapped to EEPROM address 0x0
		; These are the geographical words loaded in the  Serdes channels
		DE	0x66,0x67,0x68,0x69     ; FPGA A
        DE  0x6a,0x6b,0x6c,0x6d     ; FPGA B
		DE	0x00,0x01,0x02,0x03     ; FPGA C
        DE  0x04,0x05,0x06,0x07     ; FPGA D
        DE  0x08,0x09,0x0A,0x0B     ; FPGA E
        DE  0x0C,0x0D,0x0E,0x0F     ; FPGA F
        DE  0x10,0x11,0x12,0x13     ; FPGA G
        DE  0x14,0x15,0x16,0x17     ; FPGA H 
		; address: 0x0020:
		; These are the SerDes register configurations
		DE	0x1f,0x1f,0x1f,0x1f		; FPGAs A,B,C,D
		DE	0x1f,0x1f,0x1f,0x13		; FPGAs E,F,G,H
#endif

#ifdef THUB_is_upper
;   upper memory code has redefined vector locations:
NEW_RESET_VECT      CODE    0x4000                                
    goto    Main

NEW_HI_INT_VECT     CODE    0x4008
	retfie	FAST		

NEW_LOW_INT_VECT    CODE    0x4018
	retfie		

#else
;   "lower memory" code needs to take care of redirection for upper memory code:

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
; here should be lower program memory interrupt routines
;
	retfie	FAST		

REDIR_LOW_INT:
    clrf    EECON1
    setf    EEADR           ; Point to last location of EEDATA
    setf    EEADRH
    bsf     EECON1, RD      ; Read control code
    incfsz  EEDATA, W       ; if it is not 0xFF   
    goto    NEW_LOW_INT_VECT ; go to new code section, otherwise ...
	retfie		

#endif

;******************************************************************************
; Start of main program
; The main program code is placed here.
;******************************************************************************

MAIN_START	CODE
Main:

	call InitMicro  	;  Initialize all features / IO ports
    mAsSelect 0         ;  Set FPGA progamming lines to FPGA M (0)
    clrf QuietFlag,0    ;  Initially don't send any PLD TCD data (QuietFlag = 0)
    setf checkAlertFlag,0    ;  Initially don't send any PLD Alert data (checkAlertFlag = 0xff)
    clrf CANTestDelay,0 ;  Initially don't send CAN test messages (CANTestDelay = 0)

;; calibrate the PLL:
    bcf     PLL_CAL         ; make sure PLL_CAL is low first
    bsf     PLL_CAL         ; set PLL_CAL hi
    movlw   0x83
    movwf   temp_2          ; should be about 100ms
    call    delay_XCycles   ; at least 1 us, here: 100ms
    bcf     PLL_CAL         ; set PLL_CAL low again to initiate PLL calibration
    movlw   0xff
    movwf   temp_2          ; should be about 100ms
    call    delay_XCycles   ; wait another 100ms to make sure clock is stable
    

	call	initCAN			; initialize CAN interface

    call    I2CMPolInit     ; Initialise MSSP Module

;;;;;;;;;;;;; program the EEPROM data into the Serdes FPGAs ;;;;;;;;;;;;;;;;;;;;;;
    ;;; first wait a while for FPGAs to initialize
    movlw   0x87
    movwf   T0CON           ; initialize TIMER0
    bcf     INTCON, TMR0IF  ; clear Timer 1 interrupt flag
    movlw   0xf0            ; ~210ms
    movwf   TMR0H           ; load timer register
    clrf    TMR0L

    btfss   INTCON, TMR0IF  ; wait for timer1 overflow
    bra     $ - 2

    clrf    T0CON           ; turn off timer
    bcf     INTCON, TMR0IF  ; clear Timer 1 interrupt flag

    ;;; Check that FPGAs are initialized
    mAsSelect 5         ;  Set FPGA progamming lines to FPGA E (5)
    btfss   as_CONFIG_DONE  ; check if FPGA M is configured
	bra		FPGA_NOT_PROGRAMMED
    mAsSelect 1             ;  Set FPGA progamming lines to FPGA A (1)
    btfss   as_CONFIG_DONE  ; check if FPGA A is configured
	bra		FPGA_NOT_PROGRAMMED
    
    ;;; Now setup the EEPROM address
    clrf    EECON1
    clrf    EEADR           ; Point to first location of EEDATA
    clrf    EEADRH

    ;; read EEPROM data at address 0 - 3 and write to FPGA register 0x91
    ;; set bit 7 in  the data to indicate writing to GEO registers
    movlw   0x91            
    movwf   TXB0D0          ; "mis-use" TXB0D0 to hold the FPGA register address

    movlw   8               ; loop over 8 Serdes FPGAs
    movwf   temp_2

    bcf     uc_fpga_DIR     ; DIR lo: uc -> FPGA
    clrf    uc_fpga_DATADIR ; DATA PORT as output

eeloop2:
    movlw   4               ; loop over 4 values
    movwf   temp_1          
eeloop1:
    movff   TXB0D0, uc_fpga_DATA    ; register address on DATA PORT
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low
    
    bsf     EECON1, RD      ; Read EEPROM

    movff   EEDATA, uc_fpga_DATA ; register data on DATA PORT
    bsf     uc_fpga_DATA, 7 ; raise bit 7 for GEO_DATA write
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low

    incf    EEADR,F         ; increase EEPROM address
    decfsz  temp_1
    bra     eeloop1

    incf    TXB0D0, F       ; next Serdes FPGA
    decfsz  temp_2
    bra     eeloop2

	;;;; Now configure the Serdes registers with the
	;;;; next 8 bytes from EEPROM.

	; reset register address to first Serdes register 
   	movlw   0x91            
    movwf   TXB0D0          ; "mis-use" TXB0D0 to hold the FPGA register address

    movlw   8               ; loop over 8 Serdes FPGAs
    movwf   temp_2

eeloop3:
    movff   TXB0D0, uc_fpga_DATA    ; register address on DATA PORT
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low
    
    bsf     EECON1, RD      ; Read EEPROM

    movff   EEDATA, uc_fpga_DATA ; register data on DATA PORT
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low

    incf    EEADR,F         ; increase EEPROM address

    incf    TXB0D0, F       ; next Serdes FPGA
    decfsz  temp_2
    bra     eeloop3
	; finished with Serdes register configuration

    setf    uc_fpga_DATADIR ; DATA PORT as input
    bsf     uc_fpga_DIR     ; DIR hi: FPGA -> uc

    ;;; finished with EEPROM writing to Serdes FPGA
    ;;; reset FPGA select
;    movff   asPORT, TXB0D7
    mAsSelect 8         ;  Set FPGA progamming lines to FPGA H (8)

    ; finished with init   
;-------------------------------
;Startup Message, Data ff,00,00,00, ID 0x407
	banksel	TXB0CON
	btfsc	TXB0CON,TXREQ			; Wait for the buffer to empty
	bra		$ - 2

    lfsr    FSR0, TXB0D0
    movlw   0xFF
    movwf   POSTINC0
    movlw   0x00
    movwf   POSTINC0
    movwf   POSTINC0
    movwf   POSTINC0
; Send ALERT message (command = 7, msgID = 0x407)
    mCANSendAlert  4

	bcf		RXB0CON, RXFUL			; Clear the receive flag
    bra     MicroLoop

; If the FPGA's didn't check programmed, send a startup message with all FFs
FPGA_NOT_PROGRAMMED:
	banksel	TXB0CON
	btfsc	TXB0CON,TXREQ			; Wait for the buffer to empty
	bra		$ - 2

    lfsr    FSR0, TXB0D0
    movlw   0xFF
    movwf   POSTINC0
    movwf   POSTINC0
    movwf   POSTINC0
    movwf   POSTINC0

; Send ALERT message (command = 7, msgID = 0x407)
    mCANSendAlert  4

	bcf		RXB0CON, RXFUL			; Clear the receive flag

;**************************************************************
;* Default Receive Loop
;**************************************************************
MicroLoop:
    tstfsz  CANTestDelay,0  ; CANTestDelay in access bank
    bra     CanTxTestMsg    ; send CAN test message in a loop
    tstfsz  QuietFlag,0     ; QuietFlag in access bank   
    call    getPLDData      ; if QuietFlag != 0, get PLD Trigger data
    tstfsz  checkAlertFlag,0    ; if checkAlertFlag is 0, check register 0x88
    bra     QuietLoop       ; otherwise just check for received CAN message

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; send PLD data in register 0x88 as ALERT message, if there are any
	btfsc	TXB0CON,TXREQ			; Wait for the buffer to empty
	bra		$ - 2

    ; setup address pointer to CAN payload
    lfsr    FSR0, TXB0D0
    ; fill Txbuffer with default data
    movlw   0xFF
    movwf   POSTINC0
    movlw   0x00
    movwf   POSTINC0
    movwf   POSTINC0
    movwf   POSTINC0

    ; read register 0x88, 
    ; contains PLD data to send or 0x0 if nothing to send
    banksel uc_fpga_DATA
    bcf     uc_fpga_DIR     ; DIR lo: uc -> FPGA
    clrf    uc_fpga_DATADIR ; DATA PORT as output
    movlw   0x88   
    movwf   uc_fpga_DATA    ; put WREG as register address on DATA PORT
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    setf    uc_fpga_DATADIR ; set DATA PORT as input
    bsf     uc_fpga_DIR     ; DIR hi: FPGA -> uc
    bsf     uc_fpga_DS      ; DS hi
    movff   uc_fpga_DATA, TXB0D1 ; move DATA PORT data to CAN TX buffer
    bcf     uc_fpga_DS      ; DS lo

    ; test if PLD data not zero:
    tstfsz  TXB0D1,1      	; if (TXB0D2 == 0), use BSR
    bra     sendMsg         ; true: valid PLD Data read, send alert message
    bra     QuietLoop       ; false: continue checking for received messages

sendMsg:
    ; Fill in transmit buffer and send alert message
    lfsr    FSR0, TXB0D0
    movlw   0xFF
    movwf   INDF0
    lfsr    FSR0, TXB0D2
    movlw   0x00
    movwf   POSTINC0
    movwf   POSTINC0
    mCANSendAlert  4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; now continue with checking the CAN receive buffer for messages
; loop until we receive a CANbus message with the above filters
QuietLoop:
	btfss	RXB0CON, RXFUL		; Is there a message waiting?
    bra     MicroLoop           ; If not, continue looping

; A Message was received.
; Copy message to local buffer:
    lfsr    FSR0, RXB0D0
	lfsr	FSR1, RxData
	movf	RXB0DLC, W
	andlw	0xF
	movwf	RxDtLngth,0
	movwf	temp_1,0
CANMoveRxData:
	movff	POSTINC0, POSTINC1
	decfsz	temp_1,1,0
	bra		CANMoveRxData

	movff	RXB0CON, RxFlag			; save receive filter bits

; Now the buffer is all copied, make it available for new messages
	bcf		RXB0CON, RXFUL			; Clear the receive flag
	
; Message Recd. Successfully 
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
;* Send a CAN test message and then delay
;**************************************************************
CanTxTestMsg:        
; send a DATA packet, command = 1, msgID = 0x401
	; banksel	TXB0CON
	btfsc	TXB0CON,TXREQ			; Wait for the buffer to empty
	bra		$ - 2

    ; banksel TXB0D0
    bsf     LATJ,3
	infsnz	TXB0D0, F	; increment counter by 1
	incf	TXB0D1, F	; increment next byte by 1 when counter wraps
	infsnz	TXB0D0, F	; increment counter by 1
	incf	TXB0D1, F	; increment next byte by 1 when counter wraps
	infsnz	TXB0D4, F	; increment counter by 1
	incf	TXB0D5, F	; increment next byte by 1 when counter wraps
	infsnz	TXB0D4, F	; increment counter by 1
	incf	TXB0D5, F	; increment next byte by 1 when counter wraps
    mCANSendData    8
    bcf     LATJ, 3
    movff   CANTestDelay, temp_2 ; amount of xcycle delays
    call    delay_XCycles   ; delay some
    bra     QuietLoop       ; branch back to QuientLoop to continue
    
    
;**************************************************************
;* Get TCD Data from PLD and send it
;**************************************************************
getPLDData:
	btfsc	TXB0CON,TXREQ			; Wait for the buffer to empty
	bra		$ - 2

    ; setup address pointer to CAN payload
    ; send TCD data with LSB in Tx[0], 0xa in Tx[3]
    lfsr    FSR0, TXB0D3

    movlw   0xa0
    movwf   POSTDEC0

    banksel uc_fpga_DATA

    ; read register 0x87, contains the trigger command
    bcf     uc_fpga_DIR     ; DIR lo: uc -> FPGA
    clrf    uc_fpga_DATADIR ; DATA PORT as output
    movlw   0x87   
    movwf   uc_fpga_DATA    ; put WREG as register address on DATA PORT
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    setf    uc_fpga_DATADIR ; set DATA PORT as input
    bsf     uc_fpga_DIR     ; DIR hi: FPGA -> uc
    bsf     uc_fpga_DS      ; DS hi
    movff   uc_fpga_DATA, POSTDEC0 ; move DATA PORT data to CAN TX buffer
    bcf     uc_fpga_DS      ; DS lo

;    banksel TXB0D2
    ; test if trigger command not zero:
    tstfsz  TXB0D2,1      	; if (TXB0D2 == 0), use BSR
    bra     readToken       ; true: valid PLD Data read, read token and send it over CANbus

    ; now write to register 0x87 to advance the TCD FIFO
    ; banksel uc_fpga_DATA
    bcf     uc_fpga_DIR     ; DIR lo: uc -> FPGA
    clrf    uc_fpga_DATADIR ; DATA PORT as output
    movlw   0x87   
    movwf   uc_fpga_DATA    ; put WREG as register address on DATA PORT
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    bsf     uc_fpga_DS      ; DS hi
    bcf     uc_fpga_DS      ; DS lo
    setf    uc_fpga_DATADIR ; set DATA PORT as input
    bsf     uc_fpga_DIR     ; DIR hi: FPGA -> uc

    return                  ; false: back to loop


readToken:
    ; banksel uc_fpga_DATA

    bcf     uc_fpga_DIR     ; DIR lo: uc -> FPGA
    clrf    uc_fpga_DATADIR ; DATA PORT as output
    movlw   0x86            ; DAQ cmd, token[11:8]  
    movwf   uc_fpga_DATA    ; put WREG as register address on data port
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    setf    uc_fpga_DATADIR ; set PORT D as input
    bsf     uc_fpga_DIR     ; DIR hi: FPGA -> uc
    bsf     uc_fpga_DS      ; DS hi
    movff   uc_fpga_DATA, POSTDEC0 ; move DATA PORT data to CAN TX buffer
    bcf     uc_fpga_DS      ; DS lo
    bcf     uc_fpga_DIR     ; DIR lo: uc -> FPGA 
    clrf    uc_fpga_DATADIR ; Data PORT as output again

    movlw   0x85            ; token[7:0]
    movwf   uc_fpga_DATA    ; put WREG as register address on DATA PORT
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    setf    uc_fpga_DATADIR ; set DATA PORT as input
    bsf     uc_fpga_DIR     ; DIR hi: FPGA -> uc
    bsf     uc_fpga_DS      ; DS hi
    movff   uc_fpga_DATA, POSTDEC0 ; move DATA PORT data to CAN TX buffer
    bcf     uc_fpga_DS      ; DS lo
    bcf     uc_fpga_DIR     ; DIR lo: uc -> FPGA
    clrf    uc_fpga_DATADIR ; PORT D as output again

    ; send a DATA packet, command = 1, msgID = 0x401, Data Length = 4
	mCANSendData 4

    ; now write to register 0x87 to advance the TCD FIFO
    movlw   0x87   
    movwf   uc_fpga_DATA    ; put WREG as register address on DATA PORT
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    bsf     uc_fpga_DS      ; DS hi
    bcf     uc_fpga_DS      ; DS lo
    setf    uc_fpga_DATADIR ; set PORT D as input
    bsf     uc_fpga_DIR     ; DIR hi: FPGA -> uc

    return

;******************************************************************************
; temp_2 = 0x83 equals 100ms delay
;******************************************************************************
delay_XCycles:
    ;banksel temp_1
;    movlw   0xFF
    movlw   0x8F
    movwf   temp_1
;    movlw   0x83
;    movwf   temp_2

d100l1:
    decfsz  temp_1,F
    bra     d100l1
    decfsz  temp_2,F
    bra     delay_XCycles
    return

;******************************************************************************
;End of program
;******************************************************************************

#ifndef THUB_is_upper
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
    setf    EEDATA          ; Boot mode control byte = 0xFF
    movlw   b'00000100'     ; Enable writes to EEData
    movwf   EECON1
    movlw   0x55            ; Unlock with "magic sequence"
    movwf   EECON2
    movlw   0xAA
    movwf   EECON2
    bsf     EECON1, WR      ; Start the write
    nop
    btfsc   EECON1, WR      ; Wait
    bra     $ - 2
    RESET
#endif

	END

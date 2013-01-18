; $Id$
;*******************************************************************************;
;*                                                                              ;
;*  This implements a generic library functionality to support I2C Master       ;
;*  for PIC18 family                                                            ;
;*                                                                              ;
;*                                                                              ;
;*******************************************************************************;
;* FileName:            I2CMPol.asm                                     ;        
;*                                                                      ;
;***********************************************;***********************;
                                                ;
#define MSSP_MODULE                             ;Module definitions to generate error message for
#define _GEN_MODULE_ERROR                       ;Processor which do not have these module.
                                                ;
#define _ADD_PROC_INC_FILE                      ;
                                                ;
	#include "THUB_uc.inc"		                ; processor specific variable definitions
                                                ;
#define I2CMPol_Source                          ;
                                                ;                                                
        #include "I2CMPol.Inc"                  ;
                                                ;
;***********************************************;
; Baud Rate Genarator Reload value              ;
;***********************************************;    
        #ifdef  I2CM_SPEED_400K                 ;
                                                ;
_QUOTIENT    EQU    CLOCK_FREQ / (4 * .400000)-1;to convert the freq in 400KHz            
_REMAINDER   EQU    CLOCK_FREQ % (4 * .400000)  ;
                                                ;
        #else   ;I2CM_SPEED_100K                ;
                                                ;
_QUOTIENT    EQU    CLOCK_FREQ / (4 * .100000)-1;to convert the freq in 100KHz            
_REMAINDER   EQU    CLOCK_FREQ % (4 * .100000)  ;
                                                ;
        #endif                                  ;
                                                ;
        #if     _REMAINDER != 0                 ;
                                                ;
_I2CM_BAUD_COUNT    EQU     _QUOTIENT + 1       ;_I2CMBAUDCOUNT is nearest to ((fosc/4)/I2CMSPEED)-1,
                                                ; which has to be written in SSPADD.
        #else   ;_REMAINDER = 0                 ;
                                                ;
_I2CM_BAUD_COUNT    EQU    _QUOTIENT            ;_I2CMBAUDCOUNT = ((fosc/4)/I2CMSPEED)-1, which has to be written in SSPADD.
                                                ;which has to be written in SSPADD.
        #endif                                  ;
                                                ;
;-----------------------------------------------;
        #if     _I2CM_BAUD_COUNT > 255          ;
                                                ;
        ERROR "At this System frequency, the given I2C frequency is not attainable."
                                                ;
        #endif                                  ;
                                                ;
        #if     _I2CM_BAUD_COUNT < 2            ;
                                                ;
        ERROR "At this System frequency, the given I2C frequency is not attainable."
                                                ;
        #endif                                  ;
                                                ;
;***********************************************;
    EXTERN  RxData, RxFlag, RxDtLngth

;***********************************************;
;                                               ;
                                                ;
;***********************************************************************;
_I2CMPOLCODE    CODE                                                    ;
;***********************************************************************;
; HIGH LEVEL CODE:                              ;
                                                ;
;***********************************************************************;
ispPAC_ReadADC:
    GLOBAL ispPAC_ReadADC

    ;;; 0. Store I2C slave address in RxData[7]
    movlw   ispPAC_ADDR_U122                ; Default is address for U122
    btfsc   RxData+1, 0                     ; If RxData[1] bit 0 = 1
    movlw   ispPAC_ADDR_U123                ; Use address for U123
    btfsc   RxData+1, 2                     ; If RxData[1] bit 2 = 1
    movlw   ispPAC_ADDR_U124                ; Use address for U124
    movwf   RxData+7                        ; put in RxData[7]

    ;;; 1. Setup ADC_MUX Register

    ; Initiate I2C interaction
    mI2CMPolStart                           ; Send Start
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle

    ; Send Slave address
    movf    RxData+7,w                      ; Slave address (with write bit)
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received

    ; Send pointer register address
    movlw   0x09                            ; Send PointerRegister Address;
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received

    ; Send register data
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    movf    RxData+2, w                     ; Send PointerRegister Data
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    mI2CMPolStop                            ; Send I2C Stop


    ;;; 2. Read ADC_VALUE_LOW and put in TxData[0]

    ; Initiate I2C interaction, when bus is idle
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    mI2CMPolStart                           ; Send Start
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle

    ; Send Slave address
    movf    RxData+7,w                      ; Slave address (with write bit)
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received

    ; Send Pointer Register address 
    movlw   0x07                            ; Send PointerRegister Data;
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received

    ; Restart
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    mI2CMPolReStart                         ; Send Start
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle

    ; Send Slave address
    movf    RxData+7,w                      ; Slave address
    iorlw   1                               ; Set Read bit
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received

    ; Read byte
    mI2CMPolEnableReceiver                  ; Enable the receiver
    call    I2CMPolIsDataReady              ; Wait till Data is ready
    call    I2CMPolGet                      ; Read received value in W
    movwf   TXB0D0                          ; Move byte to CAN TXB0 byte 1
    mI2CMPolNoAck                           ; Send NoAck
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    mI2CMPolStop                            ; Send I2C Stop

    ;;; 3. Read ADC_VALUE_HIGH and put in TxData[1]

    ; second byte of ID register
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    mI2CMPolStart                           ; Send Start
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle

    ; Send slave address
    movf    RxData+7,w                      ; Slave address (with write bit)
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received

    ; Send pointer register address
    movlw   0x08                            ; Send PointerRegister Data;
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received

    ; Restart
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    mI2CMPolReStart                         ; Send Start
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle

    ; Send slave address
    movf    RxData+7,w                      ; Slave address
    iorlw   1                               ; Set Read bit
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received

    ; Read byte
    mI2CMPolEnableReceiver                  ; Enable the receiver
    call    I2CMPolIsDataReady              ; Wait till Data is ready
    call    I2CMPolGet                      ; Read received value in W
    movwf   TXB0D1                          ; Move byte to CAN TXB0 byte 1
    mI2CMPolNoAck                           ; Send NoAck
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    mI2CMPolStop                            ; Send I2C Stop

    return

;***********************************************************************;
LM73_ReadTemp:
    GLOBAL LM73_ReadTemp

    ; Initiate I2C Interaction
    mI2CMPolStart                           ; Send Start
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle

    ; Initiate Read with preset pointer
    movlw   LM73_ADDR131                    ; Use address for U131
    btfss   RxData+1, 0                     ; If RxData[1] != 1
    movlw   LM73_ADDR132                    ; Use address for U132
    iorlw   1                               ; Set Read bit

    call    I2CMPolPut                      ; Send Slave address
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received

    ; Read first (MSB)byte
    mI2CMPolEnableReceiver                  ; Enable the receiver
    call    I2CMPolIsDataReady              ; Wait till Data is ready
    call    I2CMPolGet                      ; Read received value in W
    movwf   TXB0D1                          ; Move byte to CAN TXB0 byte 1
    mI2CMPolAck                             ; Send Ack
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle

    ; Read second (LSB) byte
    mI2CMPolEnableReceiver                  ; Enable the receiver
    call    I2CMPolIsDataReady              ; Wait till Data is ready
    call    I2CMPolGet                      ; Read received value in W
    movwf   TXB0D0                          ; Move byte to CAN TXB0 byte 0
    mI2CMPolNoAck                           ; Send NoAck
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    mI2CMPolStop                            ; Send I2C Stop

    return

;***********************************************************************;
LM73_ReadIDRegister:
    GLOBAL LM73_ReadIDRegister

    mI2CMPolStart                           ; Send Start
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle

    ; Send Slave address
    movlw   0x9C                            ; SlaveAddress(with write bit)
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received

    ; Send Pointer Register Address
    movlw   0x07                            ; Send PointerRegister Address;
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received


    mI2CMPolReStart                         ; Send ReStart
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle

    ; Send Slave Address
    movlw   0x9D                            ; Send SlaveAddress(with read bit)
    call    I2CMPolPut                      ;
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    call    I2CMPolIsAckReceived            ; Check whether Ack received


    ; Read first byte of ID register
    mI2CMPolEnableReceiver                  ; Enable the receiver
    call    I2CMPolIsDataReady              ; Wait till Data is ready
    call    I2CMPolGet                      ; Read received value in W
    movwf   TXB0D0                          ;
    mI2CMPolAck                             ; Send Ack
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle


    ; Read second byte of ID register
    mI2CMPolEnableReceiver                  ; Enable the receiver
    call    I2CMPolIsDataReady              ; Wait till Data is ready
    call    I2CMPolGet                      ; Read received value in W
    movwf   TXB0D1                          ;
    mI2CMPolNoAck                           ; Send NoAck
    call    I2CMPolIsIdle                   ; Wait till bus becomes Idle
    mI2CMPolStop                            ; Send Stop bit

    return

;***********************************************************************;
; LOW LEVEL CODE:                               ;
                                                ;
;***********************************************************************;
                                                                        ;
;***********************************************************************;
; Function: I2CMPolInit                                                 ;
;                                                                       ;
; PreCondition: None                                                    ;
;                                                                       ;
; Overview:                                                             ;
;       This routine is used for MSSP Module Initialization.            ;
;       It initializes Module according to compile time selection       ;
;                                                                       ;
; Input: MpAM options                                                   ;
;                                                                       ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: 'W' register is changed                                 ;
;                                                                       ;
; Stack requirement: 1 level deep                                       ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
I2CMPolInit:                                    ;
                                                ;
        GLOBAL  I2CMPolInit                     ;
                                                ;
        movlw   028h                            ;Enable MSSP module and Master mode
        movwf   SSPCON1                         ;
                                                ;
        movlw   _I2CM_BAUD_COUNT                ;
        movwf   SSPADD                          ;loading SSPADD with baudrate generator
                                                ;reloading value
                                                ;
        return                                  ;
                                                ;
;***********************************************;




;***********************************************************************;
; Function: I2CMPolPut                                                  ;
;                                                                       ;
; PreCondition: I2CMPolStart should be called.                          ;
;                                                                       ;
; Overview:                                                             ;
;       This sends data byte over I2C Bus and checks write collision.   ;
;                                                                       ;
; Input: 'W' Register                                                   ;
;                                                                       ;
; Output: 'W' Register                                                  ;
;                                                                       ;
; Side Effects: 'W' register is changed                                 ;
;                                                                       ;
; Stack requirement: 1 level deep                                       ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
I2CMPolPut:                                     ;
                                                ;
        GLOBAL  I2CMPolPut                      ;
                                                ;
        movwf   SSPBUF                          ;
                                                ;
        btfss   SSPCON1,WCOL                    ;
        retlw   000h                            ;
                                                ;
        bcf     SSPCON1,WCOL                    ;
        retlw   I2CMErrWriteCollision           ;indicates Write Collision Error
                                                ;
;***********************************************;        



;***********************************************************************;
; Function: I2CMPolIsAckReceived                                        ;
;                                                                       ;
; PreCondition: I2CMPolPut should have called.                          ;
;                                                                       ;
; Overview:                                                             ;
;       This checks acknowledge has received.                           ;
;                                                                       ;
; Input: None                                                           ;
;                                                                       ;
; Output: 'W' Register                                                  ;
;                                                                       ;
; Side Effects: 'W' register is changed                                 ;
;                                                                       ;
; Stack requirement: 1 level deep                                       ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
I2CMPolIsAckReceived:                           ;
                                                ;
        GLOBAL  I2CMPolIsAckReceived            ;
                                                ;
        btfsc   SSPCON2,ACKSTAT                 ;
        retlw   I2CMErrNoAck                    ;indicates No Acknowledge received
                                                ;
        retlw   000h                            ;
                                                ;
;***********************************************;        



;***********************************************************************;
; Function: I2CMPolGet                                                  ;
;                                                                       ;
; PreCondition: I2CMPolPut should have called.                          ;
;                                                                       ;
; Overview:                                                             ;
;       This reads a data byte from the buffer.                         ;
;                                                                       ;
; Input: None                                                           ;
;                                                                       ;
; Output: 'W' Register                                                  ;
;                                                                       ;
; Side Effects: 'W' register is changed                                 ;
;                                                                       ;
; Stack requirement: 1 level deep                                       ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
I2CMPolGet:                                     ;
                                                ;
        GLOBAL  I2CMPolGet                      ;
                                                ;
        movf    SSPBUF,w                        ;
                                                ;
        return                                  ;
                                                ;
;***********************************************;        



;***********************************************************************;
; Function: I2CMPolIsDataReady                                          ;
;                                                                       ;
; PreCondition: SPIMPOlPut should have been called.                     ;
;                                                                       ;
; Overview:                                                             ;
;       This tells weather the Data is received                         ;
;        If data over flow has occurred it indicates it.                ; 
;                                                                       ;
; Input: None                                                           ;
;                                                                       ;
; Output: 'W' Register                                                  ;
;                                                                       ;
; Side Effects: Bank selection bits and 'W' register are changed        ;
;                                                                       ;
; Stack requirement: 1 level deep                                       ;
;                                                                       ;
;***********************************************;***********************;
                                                ;        
I2CMPolIsDataReady:                             ;
        GLOBAL  I2CMPolIsDataReady              ;
                                                ;
        btfsc   SSPCON1,SSPOV                   ;Checks is over flow has occured
        goto    I2COverRxErr                    ;
                                                ;
        #ifndef I2CM_BLOCKING_FUNCTION          ;
                                                ;
        btfss   SSPSTAT,BF                      ;Checks transmission/reception in progress
        retlw   I2CMDataNotReady                ;Indicates In progress
                                                ;
        retlw   000h                            ;Indicates Over
                                                ;
        #else                                   ;
                                                ;
I2CMWaitRxOver                                  ;
        btfss   SSPSTAT,BF                      ;
        goto    I2CMWaitRxOver                  ;Wait for a data byte reception
                                                ;
        return                                  ;
                                                ;
        #endif                                  ;
                                                ;
I2COverRxErr                                    ;
        bcf     SSPCON1,SSPOV                   ;
        retlw   I2CMErrRxDataOverFlow           ;Indicates Over flow
                                                ;
;***********************************************;



;***********************************************************************;
; Function: I2CMPolIsIdle                                               ;
;                                                                       ;
; PreCondition: Must be after every I2CMPol functions and macros        ;
;        except I2CMPolGet                                              ;
;                                                                       ;
; Overview:                                                             ;
;       This checks whether the I2C Bus is Idle or not.                 ;
;                                                                       ;
; Input: None                                                           ;
;                                                                       ;
; Output: 'W' Register                                                  ;
;                                                                       ;
; Side Effects: 'W' register is changed                                 ;
;                                                                       ;
; Stack requirement: 1 level deep                                       ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
I2CMPolIsIdle:                                  ;
        GLOBAL  I2CMPolIsIdle                   ;
                                                ;
        #ifndef I2CM_BLOCKING_FUNCTION          ;
                                                ;
        movf    SSPCON2,w                       ;
        andlw   01fh                            ;Checks SEN,PEN,RSEN,RCEN,ACKEN
                                                ;
        btfss   STATUS,Z                        ;
        retlw   I2CMBusNotIdle                  ;Indicates Bus is not Idle
                                                ;
        btfsc   SSPSTAT,R_W                     ;Checks transmission in progress
        retlw   I2CMBusNotIdle                  ;Indicates Bus is not Idle
                                                ;
        retlw   000h                            ;Indicates Bus is Idle
                                                ;
                                                ;
        #else                                   ;
                                                ;
I2CMSPRxANotOver                                ;
        movf    SSPCON2,w                       ;
        andlw   01fh                            ;Checks SEN,PEN,RSEN,RCEN,ACKEN
                                                ;
        btfss   STATUS,Z                        ;
        goto    I2CMSPRxANotOver                ;Indicates Bus is not Idle
                                                ;
I2CMTxNotOver                                   ;
        btfsc   SSPSTAT,R_W                     ;Checks transmission in progress
        goto    I2CMTxNotOver                   ;Indicates Bus is not Idle
                                                ;
        return                                  ;
                                                ;
 		#endif                                  ;
                                                ;
                                                ;
;***********************************************;


        end

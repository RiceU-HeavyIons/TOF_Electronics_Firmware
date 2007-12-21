; $Id: I2CMPol.inc,v 1.2 2007-12-21 21:33:58 jschamba Exp $
;*******************************************************************************;
;*                                                                              ;
;*  This implements a generic library functionality to support I2C Master       ;
;*  for PIC18 family                                                            ;
;*                                                                              ;
;*                                                                              ;
;*******************************************************************************;
;* FileName:            I2CMPol.inc                                     ;        
;* Dependencies:        I2CMPol.Def                                     ;
;* Processor:           PIC16xxxx/PIC18xxxx                             ;
;* Assembler:           MPASMWIN 02.70.02 or higher                     ;
;* Linker:              MPLINK 2.33.00 or higher                        ;
;* Company:             Microchip Technology, Inc.                      ;
;*                                                                      ;
;* Software License Agreement                                           ;
;*                                                                      ;
;* The software supplied herewith by Microchip Technology Incorporated  ;
;* (the "Company") for its PICmicro® Microcontroller is Polended and    ;
;* supplied to you, the Company's customer, for use solely and          ;
;* exclusively on Microchip PICmicro Microcontroller products. The      ;
;* software is owned by the Company and/or its supplier, and is         ;
;* protected under applicable copyright laws. All rights are reserved.  ;
;* Any use in violation of the foregoing restrictions may subject the   ;
;* user to criminal sanctions under applicable laws, as well as to      ;
;* civil liability for the breach of the terms and conditions of this   ;
;* license.                                                             ;
;*                                                                      ;
;* THIS SOFTWARE IS PROVIDED IN AN "AS IS" CONDITION. NO WARRANTIES,    ;
;* WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED    ;
;* TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A          ;
;* PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE COMPANY SHALL NOT,    ;
;* IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL OR           ;
;* CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.                    ;
;*                                                                      ;
;*                                                                      ;
;*                                                                      ;
;* Author               Date            Comment                         ;
;*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
;* Vidyadhar       Feb 17, 2003    Initial Release (V1.0)               ;
;*                                                                      ;
;***********************************************************************;

    #ifndef __I2CMPol_INC                       ;Check if inc file already included
                                                ;
        #define __I2CMPol_INC                   ;
                                                ;
        #include "I2CMPol.Def"                  ;
                                                ;
        #ifndef I2CMPol_Source                  ;
                                                ;
;***********************************************;

;***********************************************;
                                                ;
        EXTERN  LM73_ReadTemp                   ;
        EXTERN  ispPAC_ReadADC                  ;
        EXTERN  LM73_ReadIDRegister             ;
                                                ;
        EXTERN  I2CMPolInit                     ;
        EXTERN  I2CMPolIsIdle                   ;
        EXTERN  I2CMPolPut                      ;
        EXTERN  I2CMPolGet                      ;
        EXTERN  I2CMPolIsDataReady              ;
        EXTERN  I2CMPolIsAckReceived            ;
                                                ;
        #ifdef  I2CM_MULTI_MASTER               ;
                                                ;
        EXTERN  I2CMPolIsBusCollision           ;
                                                ;
        #endif                                  ;
;***********************************************;
        #endif                                  ;
                                                ;
;***********************************************;
;I2CMPolError bits                              ;
;***********************************************;
                                                ;
I2CMErrWriteCollision   EQU     01h             ;Write collision has occured
I2CMErrBusCollision     EQU     02h             ;Bus collision has occured
I2CMErrNoAck            EQU     03h             ;No Acknowledge received
I2CMErrRxDataOverFlow   EQU     04h             ;Received Data Over flow has occured
I2CMBusNotIdle          EQU     05h             ;Bus is not Idle
I2CMDataNotReady        EQU     06h             ;Data is not yet ready
                                                ;
;***********************************************;


;***********************************************************************;
; Macro: mI2CMPolStart                                                  ;
;                                                                       ;
; PreCondition: I2CMPolInit should have been called.                    ;
;                                                                       ;
; Overview:                                                             ;
;       This sends Start bit on I2C Bus.                                ;
;                                                                       ;
; Input: None                                                           ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: None                                                    ;
;                                                                       ;
; Stack requirement: None                                               ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
mI2CMPolStart MACRO                             ;
                                                ;
        bsf     SSPCON2,SEN                     ;Send START bit
                                                ;
        ENDM                                    ;
                                                ;
;***********************************************;




;***********************************************************************;
; Macro: mI2CMPolReStart                                                ;
;                                                                       ;
; PreCondition: mI2CMPolStart should have been invoked.                 ;
;                                                                       ;
; Overview:                                                             ;
;       This sends RepeatedStart bit on I2C Bus.                        ;
;                                                                       ;
; Input: None                                                           ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: None                                                    ;
;                                                                       ;
; Stack requirement: None                                               ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
mI2CMPolReStart MACRO                           ;
                                                ;
        bsf     SSPCON2,RSEN                    ;Send RepeatedSTART bit
                                                ;
        ENDM                                    ;
                                                ;
;***********************************************;




;***********************************************************************;
; Macro: mI2CMPolStop                                                   ;
;                                                                       ;
; PreCondition: mI2CMPolStart should have been invoked.                 ;
;                                                                       ;
; Overview:                                                             ;
;       This sends Stop bit on I2C Bus.                                 ;
;                                                                       ;
; Input: None                                                           ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: None                                                    ;
;                                                                       ;
; Stack requirement: None                                               ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
mI2CMPolStop MACRO                              ;
                                                ;
        bsf     SSPCON2,PEN                     ;Send STOP bit
                                                ;
        ENDM                                    ;
                                                ;
;***********************************************;




;***********************************************************************;
; Macro: mI2CMPolAck                                                    ;
;                                                                       ;
; PreCondition: I2CMPolGet should have been called.                     ;
;                                                                       ;
; Overview:                                                             ;
;       This sends Acknowledge bit on I2C Bus.                          ;
;                                                                       ;
; Input: None                                                           ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: None                                                    ;
;                                                                       ;
; Stack requirement: None                                               ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
mI2CMPolAck MACRO                               ;
                                                ;
        bcf     SSPCON2,ACKDT                   ;
        bsf     SSPCON2,ACKEN                   ;Acknowledge
                                                ;
        ENDM                                    ;
                                                ;
;***********************************************;




;***********************************************************************;
; Macro: mI2CMPolNoAck                                                  ;
;                                                                       ;
; PreCondition: I2CMPolGet should have been called.                     ;
;                                                                       ;
; Overview:                                                             ;
;       This sends Noacknowledge bit on I2C Bus.                        ;
;                                                                       ;
; Input: None                                                           ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: None                                                    ;
;                                                                       ;
; Stack requirement: None                                               ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
mI2CMPolNoAck MACRO                             ;
                                                ;
        bsf     SSPCON2,ACKDT                   ;
        bsf     SSPCON2,ACKEN                   ;NoAcknowledge
                                                ;
        ENDM                                    ;
                                                ;
;***********************************************;




;***********************************************************************;
; Macro: mI2CMPolEnableReceiver                                         ;
;                                                                       ;
; PreCondition: I2CMPolPut should have been called.                     ;
;                                                                       ;
; Overview:                                                             ;
;       This Enables the receiver.                                      ;
;                                                                       ;
; Input: None                                                           ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: None                                                    ;
;                                                                       ;
; Stack requirement: None                                               ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
mI2CMPolEnableReceiver MACRO                    ;
                                                ;
        bsf     SSPCON2,RCEN                    ;
                                                ;
        ENDM                                    ;
                                                ;
;***********************************************;




;***********************************************************************;
; Macro: mI2CMPolDisable                                                ;
;                                                                       ;
; PreCondition: mI2CMPolStop should have been invoked                   ;
;                                                                       ;
; Overview:                                                             ;
;       This disables MSSP Module.                                      ;
;                                                                       ;
; Input: None                                                           ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: None                                                    ;
;                                                                       ;
; Stack requirement: None                                               ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
mI2CMPolDisable MACRO                           ;
                                                ;
        bcf     SSPCON1,SSPEN                   ;
                                                ;
        ENDM                                    ;
                                                ;
;***********************************************;


    #endif





;***********************************************;
;        END                                    ;
;***********************************************;        


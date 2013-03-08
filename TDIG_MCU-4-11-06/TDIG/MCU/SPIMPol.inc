;*******************************************************************************;
;*                                                                              ;
;*  This implements a generic library functionality to support SPI Master       ;
;*  for PIC16/PIC18 family                                                      ;
;*                                                                              ;
;*                                                                              ;
;*******************************************************************************;
;* FileName:            SPIMPol.inc                                     ;        
;* Dependencies:        SPIMPol.Def                                     ;
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
;* Vidyadhar       Feb 28, 2003    Initial Release (V1.0)               ;
;*                                                                      ;
;***********************************************************************;                                                ;

    #ifndef __SPIMPol_INC                       ;Check if inc file already included
                                                ;
        #define __SPIMPol_INC                   ;
                                                ;
        #include    "SPIMPol.Def"               ;
                                                ;
    #ifndef SPIMPol_Source                      ;
                                                ;
        #define     BSSP_MODULE                 ;Module definition to generate error message for
        #define     SSP_MODULE                  ;Processor which do not have this module.
        #define     MSSP_MODULE                 ;
        #define     _GEN_MODULE_ERROR           ;
                                                ;
        #include    "P18xxx.inc"                ;
;***********************************************;
                                                ;
        EXTERN  SPIMPolInit                     ;
        EXTERN  SPIMPolPut                      ;
        EXTERN  SPIMPolGet                      ;
        EXTERN  SPIMPolIsDataReady              ;
                                                ;
;***********************************************;
;***********************************************;
                                                ;
Hi              EQU     1                       ;
Lo              EQU     0                       ;
ActiveToIdle    EQU     1                       ;
IdleToActive    EQU     0                       ;
Mids            EQU     0                       ;
Ends            EQU     1                       ;
                                                ;
;***********************************************;
    #endif                                      ;
                                                ;
;***********************************************;
;SPIMPolError bits                              ;
;***********************************************;
                                                ;
SPIMErrWriteCollision   EQU     01h             ;Write collision has occured
SPIMDataNotReady        EQU     02h             ;Data not yet ready
SPIMTransmitNotOver     EQU     02h             ;Data not yet fully transmitted
                                                ;
;***********************************************;
;***********************************************;

        #ifdef  _PIC18xxx

;***********************************************************************;
; Macro: mSPIMPolSetClockIdleState                                      ;
;                                                                       ;
; PreCondition: None.                                                   ;
;                                                                       ;
; Overview:                                                             ;
;       This sets Idle State of the Clock pin High(Hi) or Low(Lo)       ;
;                                                                       ;
; Input: State - 'Hi' or 'Lo'                                           ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: None                                                    ;
;                                                                       ;
; Stack requirement: 1 level deep                                       ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
mSPIMPolSetClockIdleState MACRO State           ;
                                                ;
        #if     State == 0                      ;
                                                ;
        bcf     SSPCON1,CKP                     ;
                                                ;
        #else                                   ;
                                                ;
        bsf     SSPCON1,CKP                     ;
                                                ;
        #endif                                  ;
                                                ;
        ENDM                                    ;
                                                ;
;***********************************************;        


;***********************************************************************;
; MACRO: mSPIMPolSetTransmitOnClockEdge                                 ;
;                                                                       ;
; PreCondition: None.                                                   ;
;                                                                       ;
; Overview:                                                             ;
;       This selects to Transmition on  Clock Edge IdleToActive or      ;
;       ActiveToIdle of the Clock                                       ;
;                                                                       ;
; Input: Edge - 'IdleToActive' or 'ActiveToIdle'                        ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: None                                                    ;
;                                                                       ;
; Stack requirement: 1 level deep                                       ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
mSPIMPolSetTransmitOnClockEdge MACRO Edge       ;
                                                ;
        #if     Edge == 0                       ;
                                                ;
        bcf     SSPSTAT,CKE                     ;
                                                ;
        #else                                   ;
                                                ;
        bsf     SSPSTAT,CKE                     ;
                                                ;
        #endif                                  ;
                                                ;
        ENDM                                    ;
                                                ;
;***********************************************;        


;***********************************************************************;
; MACRO: mSPIMPolSetSampleAtDataOut Phase                               ;
;                                                                       ;
; PreCondition: None.                                                   ;
;                                                                       ;
; Overview:                                                             ;
;       This selects to Sampling Phase at the Point Middle(Mids) or     ;
;       End(Ends) of Data                                               ;
;                                                                       ;
; Input: Point - 'Mids' or 'Ends'                                       ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: None                                                    ;
;                                                                       ;
; Stack requirement: 1 level deep                                       ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
mSPIMPolSetSampleAtDataOut MACRO Phase          ;
                                                ;
        #if     Phase == 0                      ;
                                                ;
        bcf     SSPSTAT,CKE                     ;
                                                ;
        #else                                   ;
                                                ;
        bsf     SSPSTAT,CKE                     ;
                                                ;
        #endif                                  ;
                                                ;
        ENDM                                    ;
                                                ;
;***********************************************;



;***********************************************************************;
; Macro: mSPIMPolDisable                                                ;
;                                                                       ;
; PreCondition: Communication should be over                            ;
;                                                                       ;
; Overview:                                                             ;
;       This disables SSP Module.                                       ;
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
mSPIMPolDisable MACRO                           ;
                                                ;
        bcf     SSPCON1,SSPEN                   ;
                                                ;
        ENDM                                    ;
                                                ;
;***********************************************;


        #endif

    #endif

;***********************************************;
;        END                                    ;
;***********************************************;        


;*******************************************************************************;
;*                                                                              ;
;*  This implements a generic library functionality to support SPI Master       ;
;*  for PIC18 family                                                            ;
;*  It adds additional functionality of Rx/Tx user defined Cicular buffer       ;
;*                                                                              ;
;*******************************************************************************;
;* FileName:            SPIMPol.asm                                     ;        
;* Dependencies:        P18xxx.inc                                      ;
;*                      SPIMPol.Def                                     ;
;*                      SPIMPol.Inc                                     ;
;* Processor:           PIC18xxxx                                       ;
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
;* Vidyadhar       Jun 27, 2003    corrected SPIMPolIsTransmitOver/     ;
;*                                 SPIMPolIsDataReady function for      ;
;*                                 non-blocking option (V1.1)           ;
;***********************************************************************;


;***********************************************************************;
_SPIMPOLCODE   code                                                     ;
                                                                        ;
;***********************************************************************;
; Function: SPIMPolInit                                                 ;
;                                                                       ;
; PreCondition: TRIS bits of the SCK,SDO are to be made o/p             ;
;               TRIS bit of SDI as i/p                                  ;
;               Pin/s used to select Slave Chip has to be made o/p      ;
;                                                                       ;
; Overview:                                                             ;
;       This routine is used for MSSP/SSP/BSSP Module Initialization    ;
;       It initializes Module according to compile time selection       ;
;                                                                       ;
; Input: CLM options                                                    ;
;                                                                       ;
;                                                                       ;
; Output: None                                                          ;
;                                                                       ;
; Side Effects: Bank selection bits and 'W' register are changed        ;
;                                                                       ;
; Stack requirement: 1 level deep                                       ;
;                                                                       ;
;***********************************************;***********************;
                                                ;
SPIMPolInit:                                    ;
                                                ;
        GLOBAL  SPIMPolInit                     ;
                                                ;
        movlw   SPIM_SPEED                      ;Initialize SSP as Master
        movwf   SSPCON1                         ;Initialize to opted frequency
                                                ;Enable SSP module
        return                                  ;
                                                ;
;***********************************************;



;***********************************************************************;
; Function: SPIMPolPut                                                  ;
;                                                                       ;
; PreCondition: SPIMPolInit should have been called and slave should    ;
;        have been selected.                                            ;
;                                                                       ;
; Overview:                                                             ;
;       This sends data over SPI Bus and checks write collision         ;
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
SPIMPolPut:                                     ;
                                                ;
        GLOBAL  SPIMPolPut                      ;
                                                ;
        movwf   SSPBUF                          ;
                                                ;
        btfss   SSPSTAT,WCOL                    ;
        retlw   000h                            ;
                                                ;
        bcf     SSPCON1,WCOL                    ;
        retlw   SPIMErrWriteCollision           ;indicates Write Collision Error
                                                ;
;***********************************************;        



;***********************************************************************;
; Function: SPIMPolGet                                                  ;
;                                                                       ;
; PreCondition: SPIMPolIsDataReady returns with '0' in 'W'.             ;
;                                                                       ;
; Overview:                                                             ;
;       This reads data from buffer.                                    ; 
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
SPIMPolGet:                                     ;
                                                ;
        GLOBAL  SPIMPolGet                      ;
                                                ;
        movf    SSPBUF,w                        ;
                                                ;
        return                                  ;
                                                ;
;***********************************************;        



;***********************************************************************;
; Function: SPIMPolIsDataReady                                          ;
;                                                                       ;
; PreCondition: SPIMPOlPut should have been called.                     ;
;                                                                       ;
; Overview:                                                             ;
;       This tells is Data is received                                  ; 
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
SPIMPolIsTransmitOver:                          ;
        GLOBAL  SPIMPolIsTransmitOver           ;
                                                ;
SPIMPolIsDataReady:                             ;
        GLOBAL  SPIMPolIsDataReady              ;
                                                ;
        #ifndef SPIM_BLOCKING_FUNCTION         ;
                                                ;
        btfss   SSPSTAT,BF                      ;Checks transmission/reception in progress
        retlw   SPIMDataNotReady                ;Indicates In progress
                                                ;
        retlw   000h                            ;Indicates Over
                                                ;
        #else                                   ;
                                                ;
SPIMWaitRxOver                                  ;
        btfss   SSPSTAT,BF                      ;
        goto    SPIMWaitRxOver                  ;Wait for a data byte reception
												;
        return                                  ;
                                                ;
		#ENDIF                                  ;
                                                ;
;***********************************************;

;***********************************************;
        end                                     ;
;***********************************************;

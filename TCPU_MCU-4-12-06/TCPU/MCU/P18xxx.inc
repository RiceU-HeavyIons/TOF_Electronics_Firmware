;*********************************************************************
;*
;*  The generic include file for PIC18 family
;*
;*********************************************************************
;* Company:             Microchip Technology, Inc.
;*
;* Software License Agreement
;*
;* The software supplied herewith by Microchip Technology Incorporated
;* (the "Company") for its PICmicro® Microcontroller is intended and
;* supplied to you, the Company's customer, for use solely and
;* exclusively on Microchip PICmicro Microcontroller products. The
;* software is owned by the Company and/or its supplier, and is
;* protected under applicable copyright laws. All rights are reserved.
;* Any use in violation of the foregoing restrictions may subject the
;* user to criminal sanctions under applicable laws, as well as to
;* civil liability for the breach of the terms and conditions of this
;* license.
;*
;* THIS SOFTWARE IS PROVIDED IN AN "AS IS" CONDITION. NO WARRANTIES,
;* WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED
;* TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
;* PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE COMPANY SHALL NOT,
;* IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL OR
;* CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
;*
;* Author               Date            Comment
;*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;* Gaurang Kavaiya      Nov 17, 2000    Initial Release (V1.0)
;* Gaurang Kavaiya      Feb 18, 2003    Modified for CLM and backward
;*                                      compatible modules (V1.1)
;* Gaurang Kavaiya      Mar 11, 2003    Minor Clean-up
;* Anantha Ramu         Mar 17, 2003    Commented, non-available
;                                       features of ADC modules deleted
;* Vidyadhar            Mar 17, 2003    MSSP issues clean-up (V1.2)

;********************************************************************/


;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+ Device:      18F8720
;+ Date:        2/18/03
;+ By:          GK
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        #ifdef __18F8720

;PIC family derivation
                #ifndef _PIC18xxx
                        #define _PIC18xxx
                #endif

;Processor specific include file inclusion
                #ifdef  _ADD_PROC_INC_FILE
                        #ifndef PROC_INC_ADDED
                                #define PROC_INC_ADDED
                                include <P18F8720.INC>
                        #endif
                #endif

;##########################################
;Resource definition
;##########################################


;USART module
                #ifdef  USART_MODULE

                        #ifndef _AUSART_2_MODULE
                                #define _AUSART_2_MODULE
                        #endif

                        #ifndef _USART_MODULE
                                #define _USART_MODULE
                        #endif

                        #ifndef _AUSART_MODULE
                                #define _AUSART_MODULE
                        #endif
                #endif




;AUSART module
                #ifdef  AUSART_MODULE
                        #ifndef _AUSART_2_MODULE
                                #define _AUSART_2_MODULE
                        #endif

                        #ifndef _AUSART_MODULE
                                #define _AUSART_MODULE
                        #endif
                #endif



;EUSART module
                #ifdef  EUSART_MODULE
                        #ifdef  _GEN_MODULE_ERROR
                                error "PIC 18F8720 does not have EUSART"
                        #endif
                #endif



;8-bit A/D module
                #ifdef  A2D_8BIT_MODULE
                        #ifndef _A2D_8BIT_MODULE
                                #define _A2D_8BIT_MODULE
                        #endif

                        #ifndef _A2D_10BIT_MODULE
                                #define _A2D_10BIT_MODULE      ;Backward compatible
                        #endif

                        #ifndef _A2D_10BIT_16CHANNEL_MODULE
                                #define _A2D_10BIT_16CHANNEL_MODULE
                        #endif

                        #ifndef _A2D_10BIT_5REGISTER_MODULE
                                #define _A2D_10BIT_5REGISTER_MODULE
                        #endif

                #endif

;10-bit A/D module
                #ifdef  A2D_10BIT_MODULE
                        #ifndef _A2D_10BIT_MODULE
                                #define _A2D_10BIT_MODULE      
                        #endif

                        #ifndef _A2D_10BIT_16CHANNEL_MODULE
                                #define _A2D_10BIT_16CHANNEL_MODULE
                        #endif

                        #ifndef _A2D_10BIT_5REGISTER_MODULE
                                #define _A2D_10BIT_5REGISTER_MODULE
                        #endif

                #endif

;10-bit A/D module with Acquisition time
                #ifdef  A2D_10BIT_MODULE_AUTO_ACQ_TIME

                        #ifdef  _GEN_MODULE_ERROR
                                error "PIC 18F8720 does not have 10-bit A/D with auto acquisition time facility"
                        #endif
                #endif
;12-bit A/D module
                #ifdef  A2D_12BIT_MODULE

                        #ifdef  _GEN_MODULE_ERROR
                                error "PIC 18F8720 does not have 12-bit A/D"
                        #endif
                #endif

;MSSP module
                #ifdef  MSSP_MODULE
                        #ifndef _MSSP_MODULE
                                #define _MSSP_MODULE
                        #endif

                        #ifndef _MSSP_CLOCK_STRETCH_MODULE
                                #define _MSSP_CLOCK_STRETCH_MODULE
                        #endif
                #endif

;MSSP Clock Stretch module
                #ifdef  MSSP_CLOCK_STRETCH_MODULE
                        #ifndef _MSSP_CLOCK_STRETCH_MODULE
                                #define _MSSP_CLOCK_STRETCH_MODULE
                        #endif
                #endif


;CAN module
                #ifdef  CAN_MODULE
                        #ifdef  _GEN_MODULE_ERROR
                                error "PIC 18F8720 does not have CAN"
                        #endif
                #endif



        #endif                  ;End of device definition

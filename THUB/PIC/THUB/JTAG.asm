; $Id: JTAG.asm,v 1.2 2007-12-07 19:34:56 jschamba Exp $
;******************************************************************************
;                                                                             *
;    Filename:      JTAG.asm                                                  *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:        J. Schambach                                              *
;    Company:                                                                 *
;                                                                             * 
;******************************************************************************

#define AS_PRIOR_SOURCE

	#include "THUB_uc.inc"		;processor specific variable definitions
    #include "THUB.def"         ; bit definitions

    EXTERN  RxData

    UDATA_ACS
__jtTemp1   RES 01
__jtTemp2   Res 01
__jtIRCode  RES 02      ; ALTERA JTAG Instructions are 10 bit wide, i.e. 2 bytes
numPre      RES 01      ; Number of Altera devices before the FPGA
numPost     RES 01      ; Number of Altera devices after the FPGA

;*****************************************************************
; macros to set or clear the JTAG Configuration lines
set_TCK macro
    bsf     fp_TCK, A
    endm

clr_TCK macro
    bcf     fp_TCK, A
    endm

set_TDI macro
    bsf     fp_TDI, A
    endm

clr_TDI macro
    bcf     fp_TDI, A
    endm

set_TMS macro
    bsf     fp_TMS, A
    endm

clr_TMS macro
    bcf     fp_TMS, A
    endm

str_TCK macro
    set_TCK
    clr_TCK
    endm

reset_TAP	macro
	set_TMS
	str_TCK
	str_TCK
	str_TCK
	str_TCK
	str_TCK
	endm

as_enable macro
    bsf     as_ASenable, A
    endm

as_disable macro
    bcf     as_ASenable, A
    endm

pulse_asClk macro
    bsf     asClk, A
    bcf     asClk, A
    endm

pulse_asRst macro
    bsf     asRst, A
    bcf     asRst, A
    endm

;; *********************************************************
;; end of macro section, beginnning of code
;; *********************************************************


JTAG CODE
;***********************************************************
;* Function:    jtagSelect
;*
;* Description: sets up the FPGA to talk to by first 
;*              pulsing the asRst pin
;*              and then pulsing the asClk pin 
;*              9 times
;*
;* Inputs:      none
;*
;* Outputs:     None
;*
;************************************************************
jtagSelect:
    GLOBAL jtagSelect

    movlw   9
    movwf   __jtTemp1 
    pulse_asRst     ; pulse asReset pin
jtSelectLoop:
    pulse_asClk
    decfsz  __jtTemp1, F
    bra     jtSelectLoop

    ;; set everything to a default state
    set_TMS     ; TMS = 1
    set_TDI     ; TDI = 1
    clr_TCK     ; TCK = 0
    ;; now enable pins
    as_enable
    return

;***********************************************************
;* Function:    jtDone
;*
;* Description: sets all the JTAG signals back to default, 
;*              disables the JTAG pins at the CPLD (will be
;*              tri-stated)
;*
;* Inputs:      None
;*
;* Outputs:     None
;*
;************************************************************
jtDone:
    GLOBAL jtDone

    ;; set everything back to default state
    set_TMS     ; TMS = 1
    set_TDI     ; TDI = 1
    clr_TCK     ; TCK = 0
    ;; now enable pins
    as_disable
    return

;***********************************************************
;* Function:    IRScan
;*
;* Description: performs a JTAG IR-Scan. Assumes JTAG 
;*              Instruction Code is in the 2 byte variable
;*              __jtIRCode and that the instruction code is
;*              10 bit wide. It will leave the TAP in the
;*              Run_Test/Idle state when finished. Before 
;*              the actual IRScan, a reset_TAP is executed.
;*
;* Inputs:      __jtIRCode
;*
;* Outputs:     None
;*
;************************************************************
IRScan:
    GLOBAL IRScan

	reset_TAP		; reset the TAP before IRscan (move to Test-Logic-Reset)
	clr_TMS			; TMS = 0
	str_TCK			; TAP controller moves to Run-Test-Idle
	set_TMS			; TMS = 1
	str_TCK			; TAP controller moves to Select-DR-Scan
	str_TCK			; TMS still 1, TAP controller moves to Select-IR-Scan
	clr_TMS			; TMS = 0
	str_TCK			; TAP controller moves to Capture-IR
	str_TCK			; TAP controller moves to Shift-IR

    movf    numPost, F
    btfsc   STATUS,Z
    bra     _IRstart
    
    set_TDI
    movff    numPost, __jtTemp2

preLoop2:
    movlw   .10
    movwf   __jtTemp1  
    
preLoop1:
    str_TCK                 ; strobe 10 "1"'s into instruction register
    decfsz  __jtTemp1, F
    bra     preLoop1
    decfsz  __jtTemp2, F    ; for each device after the FPGA
    bra     preLoop2

_IRstart:
; bits 0 - 7:
    movlw   8
    movwf   __jtTemp1  ; do the next section for 8 bits:
    ;; byte is located in location "__jtIRCode"

jtProgLoop2:
    clr_TDI
    rrcf    __jtIRCode, F   ; rotate right through carry and store back
    bnc     $+4
    set_TDI                 ; TDI = 1, if (carry == 1)
    str_TCK
    decfsz  __jtTemp1, F
    bra     jtProgLoop2

; bit 8
    clr_TDI
    rrcf    __jtIRCode+1, F ; rotate right through carry and store back
    bnc     $+4
	set_TDI
	str_TCK
; bit 9
    clr_TDI
    rrcf    __jtIRCode+1, F ; rotate right through carry and store back
    bnc     $+4
	set_TDI				    ; final bit on TDI

    movf    numPre, F
    btfsc   STATUS,Z
    bra     _IRend

    str_TCK                 ; strobe final bit, then put others in bypass

    set_TDI
    movff    numPre, __jtTemp2

postLoop2:
    movlw   .9
    movwf   __jtTemp1  
    
postLoop1:
    str_TCK                 ; strobe 9 "1"'s into instruction register
    decfsz  __jtTemp1, F
    bra     postLoop1
    dcfsnz  __jtTemp2, F    ; for each device before the FPGA
    bra     _IRend          ; if last one, set TMS first before TCK strobe
    str_TCK                 ; one more TCK strobe for 10th bit
    bra     postLoop2

_IRend:
	set_TMS
	str_TCK				; TAP to Exit1-IR, while strobing in 10th bit
	str_TCK				; TAP to Update-IR
	clr_TMS
	str_TCK				; TAP to Run-Test/Idle

; done
	return


;***********************************************************
;* Function:    DRScanRdOnly
;*
;* Description: performs a JTAG DR-Scan. Output will be
;*              stored in the bytes pointed to by INDF0, 
;*              which should point to the LSB of a 4 byte
;*              memory location. The data scanned into TDI
;*              will be all 0's. It also assumes that the TAP
;*              controller starts in Run-Test/Idle state and
;*              will return it to that state when finished.
;*
;* Inputs:      None
;*
;* Outputs:     Memory pointed to by INDF0 will contain the
;*              4 byte word read from JTAG
;*
;************************************************************
DRScanRdOnly:
    GLOBAL DRScanRdOnly

    clr_TDI                 ; TDI = 0
	set_TMS				    ; TMS = 1
	str_TCK				    ; TAP controller moves to Select-DR-Scan
	clr_TMS				    ; TMS = 0
	str_TCK				    ; TAP controller moves to Capture-DR
    
    ; next rising edge of TCK will move to  Shift-DR

    movf    numPost, F
    btfsc   STATUS,Z
    bra     _DRstart

    movff    numPost, __jtTemp2
_DRPreLoop:
    str_TCK                 ; strobe TCK for number of devices after FPGA
    decfsz  __jtTemp2, F
    bra     _DRPreLoop    

_DRstart:
    movlw   4               ; loop for 4 bytes
    movwf   __jtTemp2       

jtProgLoop5:
    movlw   8               ; loop for 8 bits per byte
    movwf   __jtTemp1
    
jtProgLoop4:
    str_TCK                 ; TDO is now valid, capture it
    movf    fp_TDO,W        ; read TDO port, bit 0 = TDO 
    rrcf    WREG            ; rotate bit 0 into carry
    rrcf    INDF0, F        ; rotate carry bit into "*INDF0[7]" and shift right
    decfsz  __jtTemp1, F
    bra     jtProgLoop4
    incf    FSR0L, F        ; next byte
    decfsz  __jtTemp2, F
    bra     jtProgLoop5

    ; got all 32 bits, now exit:
	set_TMS			; TMS = 1
; Next tick leaves Shift-DR
	str_TCK			; TCK = 1, 0. TAP -> Exit1-DR
	str_TCK			; TAP to Update-DR
	clr_TMS			; TMS = 0
	str_TCK			; TAP to Run-test/Idle

    return

 
;***********************************************************
;* Function:    jtGetIDCode
;*
;* Description: Issue an IRSCAN with a JTAG instruction
;*              "IDCODE", followed by a DRSCAN to read 
;*              the FPGA IDCODE. The resulting IDCODE is
;*              stored in TXB0D0 - TXB0D3 for CANbus 
;*              transmission, with the LSB in byte 0
;*
;* Inputs:      RxData[1] - which FPGA to address
;*
;* Outputs:     TXB0D0 - TXB0D3 contain the IDCODE
;*
;************************************************************
jtGetIDCode:
    GLOBAL jtGetIDCode

    call    jtagSelect

    banksel __jtIRCode
    movlw   0x06            ; JTAG instruction "IDCODE"
    movwf   __jtIRCode
    clrf    __jtIRCode+1

    movf    RxData+1, W     ; FPGA number
    tstfsz  RxData+1
    bra     $+4
    movlw   .4              ; FPGA number 0 is the 4th FPGA
    decf    WREG, W         ; FPGA number 1 is first in chain
    movwf   numPre
    sublw   3               ; a total of 4 FPGA's in current chain
    movwf   numPost



    call    IRScan
    lfsr    FSR0, TXB0D0
    call    DRScanRdOnly

    call    jtDone
    return 

;***********************************************************
;* Function:    jtGetUserCode
;*
;* Description: Issue an IRSCAN with a JTAG instruction
;*              "USERCODE", followed by a DRSCAN to read 
;*              the FPGA IDCODE. The resulting USERCODE is
;*              stored in TXB0D0 - TXB0D3 for CANbus 
;*              transmission, with the LSB in byte 0
;*
;* Inputs:      RxData[1] - which FPGA to address
;*
;* Outputs:     TXB0D0 - TXB0D3 contain the IDCODE
;*
;************************************************************
jtGetUserCode:
    GLOBAL jtGetUserCode

    call    jtagSelect

    banksel __jtIRCode
    movlw   0x07            ; JTAG instruction "USERCODE"
    movwf   __jtIRCode
    clrf    __jtIRCode+1

    movf    RxData+1, W     ; FPGA number
    tstfsz  RxData+1
    bra     $+4
    movlw   .9              ; FPGA number 0 is the 9th FPGA
    decf    WREG, W         ; FPGA number 1 is first in chain
    movwf   numPre
    sublw   .8               ; a total of 9 FPGA's in current chain
    movwf   numPost



    call    IRScan
    lfsr    FSR0, TXB0D0
    call    DRScanRdOnly

    call    jtDone
    return 


   END

; $Id: SRunner.asm,v 1.1 2006-08-11 22:11:01 jschamba Exp $
;******************************************************************************
;                                                                             *
;    Filename:      SRunner.asm                                                             *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:        J. Schambach                                                                 *
;    Company:                                                                 *
;                                                                             * 
;******************************************************************************

#define AS_PRIOR_SOURCE

	#include <P18F4680.INC>		;processor specific variable definitions
    #include "SRunner.inc"

        UDATA
asOneByte   RES     01
__asTemp    RES     01
        GLOBAL  asOneByte


;*****************************************************************
; macro set_nconfig
set_NCONFIG macro
    bsf     PORTC, 5
    endm

clr_NCONFIG macro
    bcf     PORTC, 5
    endm

set_NCE macro
    bsf     PORTC, 4
    endm

clr_NCE macro
    bcf     PORTC, 4
    endm

set_NCS macro
    bsf     PORTC, 3
    endm

clr_NCS macro
    bcf     PORTC, 3
    endm

set_DCLK macro
    bsf     PORTC, 1
    endm

clr_DCLK macro
    bcf     PORTC, 1
    endm

set_ASDI macro
    bsf     PORTC, 2
    endm

clr_ASDI macro
    bcf     PORTC, 2
    endm

as_enable macro
    bsf     PORTC, 6
    endm

as_disable macro
    bcf     PORTC, 6
    endm

as_select macro ASDEVICE
    movlw   ASDEVICE
    swapf   WREG        ; move value to bits
    rrncf   WREG        ; 3,4,5
    movwf   __asTemp    ; store away temporarily
    movlw   0xC7        ; mask out other bits
    andwf   LATA,W      ; and read PORTA
    iorwf   __asTemp,W  ; set bits which were stored above
    movwf   LATA        ; and move back to PORTA output latch
    endm

mAsProgramByteMSB macro ONE_BYTE
    movlw   ONE_BYTE
    movwf   asOneByte
    call    asProgramByteMSB
    endm

mAsProgramByteLSB macro ONE_BYTE
    movlw   ONE_BYTE
    movwf   asOneByte
    call    asProgramByteLSB
    endm


;; *********************************************************
;; end of macro section, beginnning of code
;; *********************************************************

SRunner CODE
;***********************************************************
;* Function:    asStart
;*
;* Description: sets all AS signals to default, enables the
;*              AS pins through the CPLD, and then disables
;*              access to the EEPROM from the FPGA by setting
;*              NCONFIG=0 and NCE=1
;*
;* Inputs:      None
;*
;* Outputs:     None
;*
;************************************************************
asStart:
    GLOBAL asStart

    ;; set everything to default state
    set_NCONFIG
    clr_NCE
    set_NCS
    clr_DCLK    
    as_select 0
    ;; now enable the pins
    as_enable

    ;; disbale FPGA access to prom
    clr_NCONFIG
    set_NCE
    return

;***********************************************************
;* Function:    asDone
;*
;* Description: 
;*
;* Inputs:      None
;*
;* Outputs:     None
;*
;************************************************************
asDone:
    GLOBAL asDone

    ;; set everything back to default state
    clr_NCE
    set_NCONFIG
    set_NCS
    ;; disable pins
    as_disable
    as_select 7
    return

;***********************************************************
;* Function:    asProgramByteMSB
;*
;* Description: write bits to ASDI starting with MSB, while
;*              moving DCLK up and down
;*
;* Inputs:      asOneByte contains the byte to program
;*
;* Outputs:     None
;*
;************************************************************
asProgramByteMSB:
    movlw   8
    movwf   __asTemp   ; do the next section for 8 bits:
    ;; byte is located in location "asOneByte"

asProgLoop1:
    clr_DCLK
    clr_ASDI
    rlcf    asOneByte, F    ; rotate left through carry and store back
    bnc     $+4
    set_ASDI                ; ASDI = 1, if (carry == 1)
    set_DCLK
    decfsz  __asTemp, F
    bra     asProgLoop1
    return

;***********************************************************
;* Function:    asProgramByteLSB
;*
;* Description: write bits to ASDI starting with LSB, while
;*              moving DCLK up and down
;*
;* Inputs:      asOneByte contains the byte to program
;*
;* Outputs:     None
;*
;************************************************************
asProgramByteLSB:
    movlw   8
    movwf   __asTemp   ; do the next section for 8 bits:
    ;; byte is located in location "asOneByte"

asProgLoop2:
    clr_DCLK
    clr_ASDI
    rrcf    asOneByte, F    ; rotate right through carry and store back
    bnc     $+4
    set_ASDI                ; ASDI = 1, if (carry == 1)
    set_DCLK
    decfsz  __asTemp, F
    bra     asProgLoop2
    return

;***********************************************************
;* Function:    asReadByteMSB
;*
;* Description: read bits from DATA pin, stuff them into
;*              asOneByte starting with MSB (right to left)
;*
;* Inputs:      None
;*
;* Outputs:     asOneByte contains the byte that was read
;*
;************************************************************
asReadByteMSB:
    clrf    asOneByte   ; clear temporary storage
    movlw   8
    movwf   __asTemp   ; do the next section for 8 bits:
    
asProgLoop3:
    clr_DCLK
    nop
    set_DCLK
    movf    PORTC,W         ; read PORTC 
    rrcf    WREG            ; rotate bit 0 into carry
    rlcf    asOneByte, F    ; rotate carry bit into "asOneByte[0]" and shift left
    decfsz  __asTemp, F
    bra     asProgLoop3
    return 

;***********************************************************
;* Function:    asReadByteLSB
;*
;* Description: read bits from DATA pin, stuff them into
;*              asOneByte starting with LSB (left to right)
;*
;* Inputs:      None
;*
;* Outputs:     asOneByte contains the byte that was read
;*
;************************************************************
asReadByteLSB:
    clrf    asOneByte   ; clear temporary storage
    movlw   8
    movwf   __asTemp   ; do the next section for 8 bits:
    
asProgLoop4:
    clr_DCLK
    nop
    set_DCLK
    movf    PORTC,W         ; read PORTC 
    rrcf    WREG            ; rotate bit 0 into carry
    rrcf    asOneByte, F    ; rotate carry bit into "asOneByte[7]" and shift right
    decfsz  __asTemp, F
    bra     asProgLoop4
    return 

;***********************************************************
;* Function:    asReadSiliconID
;*
;* Description: Read Silicon ID from serial device
;*
;* Inputs:      None
;*
;* Outputs:     asOneByte contains the Silicon ID read
;*
;************************************************************
asReadSiliconID:
    GLOBAL  asReadSiliconID

    call    asStart
    clr_NCS
    mAsProgramByteMSB   AS_READ_SILICON_ID
    mAsProgramByteMSB   0x00    ; first dummy byte
    mAsProgramByteMSB   0x00    ; second dummy byte
    mAsProgramByteMSB   0x00    ; third dummy byte

    call asReadByteMSB          ; read silicon ID byte into asOneByte
    set_NCS
    call    asDone
    return

;***********************************************************
;* Function:    asBulkErase
;*
;* Description: Bulk Erase EEPROM
;*
;* Inputs:      None
;*
;* Outputs:     None
;*
;************************************************************
asBulkErase:
    clr_NCS
    mAsProgramByteMSB   AS_WRITE_ENABLE
    set_NCS
    nop
    clr_NCS
    mAsProgramByteMSB   AS_ERASE_BULK
    set_NCS
    nop
    clr_NCS
    mAsProgramByteMSB   AS_READ_STATUS
asCheckStatus:
    call    asReadByteMSB
    rrcf    asOneByte,W     ; rotate lowest bit into carry
    bc      asCheckStatus   ; keep polling if this bit is high
    ; bulk erase finished
    set_ncs
    return



    END
   

; $Id: CANHLP.asm,v 1.10 2007-11-05 16:27:22 jschamba Exp $
;******************************************************************************
;                                                                             *
;    Filename:      CANHLP.asm                                                *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:        J. Schambach                                              *
;    Company:                                                                 *
;                                                                             * 
;******************************************************************************

#define HLP_PRIOR_SOURCE

	#include "THUB_uc.inc"		; processor specific variable definitions
    #include "CANHLP.inc"
    #include "SRunner.inc"      ; SRunner functions
    #include "THUB.def"         ; bit definitions
	#include "CANHLP.def"		; configuration bits for CAN

#define		_CAN_BRGCON1	((HLP_CAN_SJW - 1) << 6) | (HLP_CAN_PRESCALE-1)	; Data rate control
#define		_CAN_BRGCON2	(HLP_CAN_SEG2PHTS << 7) | (HLP_CAN_SAM << 6) | ((HLP_CAN_SEG1PH - 1) << 3) | (HLP_CAN_PRSEG - 1)
#define		_CAN_BRGCON3	(HLP_CAN_WAKFIL << 6) | (HLP_CAN_SEG2PH - 1) 

#define		_CAN_CIOCON		(HLP_CAN_ENDRHI << 5) | (HLP_CAN_CANCAP << 4)		; CAN IO control

; Filters and masks
#define		_CAN_RXF0SIDH	(HLP_CAN_RXF0 & 0x7F8)	>> 3	; RX filter 0
#define		_CAN_RXF0SIDL	(HLP_CAN_RXF0 & 0x7) << 5
#define		_CAN_RXF0EIDH	0
#define		_CAN_RXF0EIDL	0

#define		_CAN_RXF1SIDH	(HLP_CAN_RXF1 & 0x7F8)	>> 3	; RX filter 1
#define		_CAN_RXF1SIDL	(HLP_CAN_RXF1 & 0x7) << 5
#define		_CAN_RXF1EIDH	0
#define		_CAN_RXF1EIDL	0

#define		_CAN_RXM0SIDH	(HLP_CAN_RXM0 & 0x7F8)	>> 3	; RX mask 0
#define		_CAN_RXM0SIDL	(HLP_CAN_RXM0 & 0x7) << 5
#define		_CAN_RXM0EIDH	0
#define		_CAN_RXM0EIDL	0

#define		_CAN_TXB0SIDH	(HLP_CAN_NODEID & 0x7F) << 1	; SIDH for TX ID

    EXTERN  RxData, RxFlag, RxDtLngth, QuietFlag, CANTestDelay

    UDATA_ACS
hlpCtr1 RES     01          ; temporary variable used as counter
hlpCtr2 RES     01          ; temporary variable used as counter

CANHLP CODE

initCAN:
	GLOBAL initCAN
	
    banksel CANCON
	movlw 	B'10000000'		; set to Configuration Mode
	movwf	CANCON
    btfss   CANSTAT, 7      ; test if bit 7 (configuration mode) is set?
    bra		$ - 2           ; if not, wait...
; *****************************************************************************
	movlw	_CAN_RXF0SIDH			; Set filter 0
	movwf	RXF0SIDH
	movlw	_CAN_RXF0SIDL
	movwf	RXF0SIDL
	movlw	_CAN_RXF0EIDH
	movwf	RXF0EIDH
	movlw	_CAN_RXF0EIDL
	movwf	RXF0EIDL
	
	movlw	_CAN_RXF1SIDH			; Set filter 1
	movwf	RXF1SIDH
	movlw	_CAN_RXF1SIDL
	movwf	RXF1SIDL
	movlw	_CAN_RXF1EIDH
	movwf	RXF1EIDH
	movlw	_CAN_RXF1EIDL
	movwf	RXF1EIDL
	
	movlw	_CAN_RXM0SIDH			; Set mask 0
	movwf	RXM0SIDH
	movlw	_CAN_RXM0SIDL
	movwf	RXM0SIDL
	movlw	_CAN_RXM0EIDH
	movwf	RXM0EIDH
	movlw	_CAN_RXM0EIDL
	movwf	RXM0EIDL
	
	movlw	_CAN_BRGCON1			; Set baud rate
	movwf	BRGCON1
	movlw	_CAN_BRGCON2
	movwf	BRGCON2
	movlw	_CAN_BRGCON3
	movwf	BRGCON3
	
	movlw	_CAN_CIOCON				; Set IO
	movwf	CIOCON

	movlw	_CAN_TXB0SIDH			; Setg TX SIDH
	movwf	TXB0SIDH
		
	clrf	CANCON					; Enter Normal mode

	return
; *****************************************************************************

HLPCopyRxData:
	banksel	TXB0CON
	btfsc	TXB0CON,TXREQ			; Wait for the buffer to empty
	bra		$ - 2

    lfsr    FSR1, TXB0D0
    lfsr    FSR0, RXB0D0
    movff   RxDtLngth, hlpCtr1
HLPCopyRxDataLoop:
	movff	POSTINC0, POSTINC1
	decfsz	hlpCtr1
	bra		HLPCopyRxDataLoop

    return

; *****************************************************************************
HLPSendWriteResponseOK:
	banksel	TXB0CON
	btfsc	TXB0CON,TXREQ			; Wait for the buffer to empty
	bra		$ - 2

    movff   RXB0D0, TXB0D0          ; copy first byte to Tx buffer
    movlw    0x00
    movwf   TXB0D1                  ; second byte = 0
    mCANSendWrResponse   2

    return



;**************************************************************
;* Now handle HLP commands.
;* 
;* which write command?
;**************************************************************
TofHandleWrite:
    GLOBAL TofHandleWrite

    ;**************************************************************
    ;****** Write PLD Register: ***********************************
    ;* msgID = 0x402
    ;* RxData[0] = Register address, 0x80 < address < 0xff
    ;* RxData[1] = Data to write
    ;**************************************************************
    btfss   RxData, 7           ; test if bit 7 in RxData[0] is set
    bra     is_it_MCU_RDOUT_MODE    ; false: test next command
    call    TofWriteReg         ; true: write PLD register
    return
is_it_MCU_RDOUT_MODE:
    ;**************************************************************
    ;****** Set MCU DATA Readout Mode: ****************************
    ;* msgID = 0x402
    ;* RxData[0] = 0xa
    ;* RxData[1] = 1: Don't read PLD data
    ;*           = 0: Read PLD data and send it
    ;**************************************************************
    movf    RxData,W            ; WREG = RxData
    sublw   0x0A                ; if (RxData[0] == 0x0a)
    bnz     is_it_CAN_TESTMSG_MODE  ; false: test next command
    call    TofSetRDOUT_MODE        ; true: set MCU DATA Readout Mode
    call    HLPSendWriteResponseOK  ; send response    
    return
is_it_CAN_TESTMSG_MODE:
    ;**************************************************************
    ;****** Set MCU CAN Test Message Mode: ************************
    ;* msgID = 0x402
    ;* RxData[0] = 0xB
    ;* RxData[1] != 0: send CAN test messages in a loop with RxData[1] delay
    ;*            = 0: Don't send CAN test messages
    ;**************************************************************
    movf    RxData,W            ; WREG = RxData
    sublw   0x0B                ; if (RxData[0] == 0x0b)
    bnz     is_it_programPLD    ; false: test next command
    call    TofSetCANTestMsg_MODE   ; true: set CAN Test Msg Mode
    call    HLPSendWriteResponseOK  ; send response    
    return
is_it_programPLD:
    movf    RxData,W            ; WREG = RxData
    andlw   0xF8
    sublw   0x20                ; if (32 <= RxData[0] <= 39)
    bnz     unknown_message     ; false: send error message
    call    TofProgramPLD       ; true: a "program PLD" command
    return
    

;**************************************************************
;* which read command? 
;**************************************************************
TofHandleRead:
    GLOBAL TofHandleRead

    ;**************************************************************
    ;****** Read MCU Firmware ID **********************************
    ;* msgID = 0x404
    ;* RxData[0] = 0x1
    ;*
    ;* Effect: read Firmware ID of MCU and return as a
    ;*          Read Response
    ;**************************************************************
    movf    RxData,W
    sublw   0x1
    bnz     is_it_TofReadSiID  
    call    TofReadFirmwareID
    return

is_it_TofReadSiID:
    ;**************************************************************
    ;****** Read Silicon ID ***************************************
    ;* msgID = 0x404
    ;* RxData[0] = 0x27
    ;* RxData[1] = FPGA number to read (1 - 8 for SERDES FPGA,
    ;*                                  0 for Master FPGA
    ;*
    ;* Effect: read Silicon ID of EEPROM and return as a
    ;*          Read Response
    ;**************************************************************
    movf    RxData,W
    sublw   0x27
    bnz     is_it_TofReadReg  
    call    TofReadSiID
    return

is_it_TofReadReg:
    ;**************************************************************
    ;****** Read PLD Register *************************************
    ;* msgID = 0x404
    ;* RxData[0] = Register address, 0x80 < address < 0xff
    ;**************************************************************
    btfss   RxData, 7       ; if ( 0x80 < RxData[0] < 0xFF )
    bra     unknown_message ; false: send error message
    call    TofReadReg      ; true: read PLD register
    return

    ;**************************************************************
    ;****** Unknown Message Response ******************************
    ;* msgID = 0x407
    ;* RxData[0..x] = originally sent message bytes just echoed
    ;**************************************************************
unknown_message: 
    ; send an error message here (message ID=0x407)
    call    HLPCopyRxData
    mCANSendAlert_IDL   RxDtLngth

    return

;**************************************************************
;* CAN "Write" Commands
;**************************************************************
TofSetRDOUT_MODE:
    ;**************************************************************
    ;****** Set Readout Mode **************************************
    ;**************************************************************
    movff   RxData+1, QuietFlag
    return

TofSetCANTestMsg_MODE:
    ;**************************************************************
    ;****** Set CAN Test Msg Mode *********************************
    ;**************************************************************
    movff   RxData+1, CANTestDelay
    movlw   0xa0
    movwf   TXB0D3
    clrf    TXB0D2
    clrf    TXB0D1
    clrf    TXB0D0
    return

TofWriteReg:
    ;**************************************************************
    ;****** Write Register ****************************************
    ;**************************************************************
    movff   RxData, uc_fpga_DATA   ; put first byte as register address on DATA PORT
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low

    movff   RxData+1, uc_fpga_DATA ; second byte as register data on DATA PORT
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    return                  ; back to receiver loop

TofProgramPLD:
    ;**************************************************************
    ;****** Initialize Program EEPROM *****************************
    ;* msgID = 0x402
    ;* RxData[0] = 0x20
    ;* RxData[1] = FPGA number to program (1 - 8 for SERDES FPGA,
    ;*                                     0 for Master FPGA
    ;* Effect: call asSelect, then asStart, followed by asBulkErase
    ;**************************************************************
    movf    RxData,W        ; WREG = RxData
    sublw   0x20
    bnz     is_it_writeAddress
    movf    RxData+1,W
    call    asSelect
    call    asStart
    call    asBulkErase
    ; send WriteResponse packet

    call    HLPCopyRxData
    mCANSendWrResponse_IDL   RxDtLngth

    return

is_it_writeAddress:
    ;**************************************************************
    ;****** Write EEPROM Address **********************************
    ;* msgID = 0x402
    ;* RxData[0] = 0x21
    ;* RxData[1] = asAddress[ 7: 0]
    ;* RxData[2] = asAddress[15: 8]
    ;* RxData[3] = asAddress[23:16] 
    ;*
    ;* Effect: set the EEPROM address to write to (3 bytes)
    ;           and reset FSR2H to beginning of "asDataBytes"
    ;**************************************************************
    movf    RxData,W
    sublw   0x21
    bnz     is_it_writeDataByte
    movff   RxData+1, asAddress
    movff   RxData+2, asAddress+1
    movff   RxData+3, asAddress+2
    lfsr    FSR2, asDataBytes
    ; sendWriteResponse
    call    HLPCopyRxData
    mCANSendWrResponse_IDL   RxDtLngth
    return

is_it_writeDataByte:
    ;**************************************************************
    ;****** Write EEPROM Data **********************************
    ;* msgID = 0x402
    ;* RxData[0] = 0x22
    ;* RxData[1..x] = DataByte[0..x-1] 
    ;*
    ;* Effect: write data bytes to RAM pointed to by FSR1 and 
    ;*          increase FSR1 pointer appropriately, so that
    ;*          consecutive "Write EEPROM Data" commands write to 
    ;*          consecutive RAM locations
    ;**************************************************************
    movf    RxData,W
    sublw   0x22
    bnz     is_it_writePage
    lfsr    FSR0, RxData+1
    movf    RxDtLngth,W
    decfsz  WREG,W
    bra     mainProgLoop1
    ; sendWriteResponse
    call    HLPCopyRxData
    mCANSendWrResponse_IDL   RxDtLngth

    return

mainProgLoop1:
    movff   POSTINC0, POSTINC2
    decfsz  WREG,W
    bra     mainProgLoop1
    ; sendWriteResponse
;    call    HLPCopyRxData
;    mCANSendWrResponse_IDL   RxDtLngth
    return   

is_it_writePage:
    ;**************************************************************
    ;****** Program 256 *******************************************
    ;* msgID = 0x402
    ;* RxData[0] = 0x23
    ;* RxData[1..x] = DataByte[0..x-1] 
    ;*
    ;* Effect: write data bytes to RAM pointed to by FSR2 and
    ;*          call asProgram256 afterwards, which writes this
    ;*          page to the EEPROM
    ;**************************************************************
    movf    RxData,W
    sublw   0x23
    bnz     is_it_endPLDProgram
    lfsr    FSR0, RxData+1
    movf    RxDtLngth,W
    decfsz  WREG,W
    bra     mainProgLoop2
    bra     program_it

    ; sendWriteResponse
;    call    HLPCopyRxData
;    mCANSendWrResponse_IDL   RxDtLngth
    ;return
mainProgLoop2:
    movff   POSTINC0, POSTINC2
    decfsz  WREG,W
    bra     mainProgLoop2
program_it:
    call    asProgram256
    ; sendWriteResponse
    call    HLPCopyRxData
    mCANSendWrResponse_IDL   RxDtLngth
    return

is_it_endPLDProgram:
    ;**************************************************************
    ;****** Program EEPROM Done ***********************************
    ;* msgID = 0x402
    ;* RxData[0] = 0x24
    ;*
    ;* Effect: call asDone
    ;**************************************************************
    movf    RxData,W
    sublw   0x24
    bnz     is_it_reprogram64
    call    asDone
    ; set FPGA programming lines to device H (= 8)
    mAsSelect 8
    ; sendWriteResponse
    call    HLPCopyRxData
    mCANSendWrResponse_IDL   RxDtLngth
    return

is_it_reprogram64:
    ;**************************************************************
    ;****** Reprogram 64 bytes of program memory ******************
    ;* msgID = 0x402
    ;* RxData[0] = 0x25
    ;* RxData[1..x] = DataByte[0..x-1] 
    ;*
    ;* Effect: write data bytes to RAM pointed to by FSR2 and
    ;*          erase 64 bytes of program memory pointed to by
    ;*          asAddress, write 64 new bytes from asDataBytes
    ;*          to this memory
    ;**************************************************************
    movf    RxData,W        ; WREG = RxData
    sublw   0x25
    bnz     is_it_resetToNewProgram
    lfsr    FSR0, RxData+1
    movf    RxDtLngth,W
    decfsz  WREG,W
    bra     reprogram_loop
    bra     programMCU
reprogram_loop:
    movff   POSTINC0, POSTINC2
    decfsz  WREG,W
    bra     reprogram_loop
programMCU:
    call    handle_reprogram64
    ; send WriteResponse packet
    call    HLPCopyRxData
    mCANSendWrResponse_IDL   RxDtLngth
    return

is_it_resetToNewProgram:
    ;**************************************************************
    ;****** Set EEPROM and Reset **********************************
    ;* msgID = 0x402
    ;* RxData[0] = 0x26
    ;* RxData[1] = EEPROM data byte
    ;*
    ;* Effect: set last location of EEPROM data to "EEPROM data 
    ;*           byte" and reset
    ;**************************************************************
    movf    RxData,W        ; WREG = RxData
    sublw   0x26
    bz      resetToNewProgram
    call    unknown_message
    return

resetToNewProgram:
    setf    EEADR           ; Point to the last byte in EEPROM
    setf    EEADRH
    movff   RxData+1,EEDATA ; Boot mode control byte = RxData[1]
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
    ; EEPROM is written, send a CAN writeResponse
    call    HLPCopyRxData
    mCANSendWrResponse_IDL   RxDtLngth
    ; waste a little time
    banksel hlpCtr1
    movlw   0xff
    movwf   hlpCtr1
innerDelayLoop:
    decfsz  hlpCtr1
    bra     innerDelayLoop
    nop    
    ; and reset
    RESET


    ;**************************************************************
    ;****** Reprogram 256 bytes of program memory *****************
    ;**************************************************************
handle_reprogram64:
    ; move 3 bytes of program memory address to TBLPTR
    movff   asAddress, TBLPTRL
    movff   asAddress+1, TBLPTRH
    movff   asAddress+2, TBLPTRU
    ; initialize FSR0 with asDataBytes address
    lfsr    FSR0, asDataBytes

    ; the following procedure needs to be repeated 4 times
    ; so that 4 * 64 = 256 bytes are programmed
    ;movlw   4
    ;movwf   hlpCtr2

repeat64:
    ; now follow erase procedure on page 100 of manual
    bsf     EECON1, EEPGD       ; point to Flash program memory
    bcf     EECON1, CFGS        ; access Flash program memory
    bsf     EECON1, WREN        ; write enable
    bsf     EECON1, FREE        ; enable Row Erase operation
    bcf     INTCON, GIE         ; disable interrupts
    movlw   55h
    movwf   EECON2              ; write 55h
    movlw   0AAh
    movwf   EECON2              ; write 0AAh
    bsf     EECON1, WR          ; start erase (CPU stall)
    bsf     INTCON, GIE         ; re-enable interrupts
    tblrd*-                     ; dummy read decrement

    ; now copy 64 bytes of buffer data to holding registers
    movlw   .64                 ; number of bytes in holding register
    movwf   hlpCtr1
WRITE_BYTE_TO_HREGS:
    movf    POSTINC0, w         ; get next byte of buffer data
    movwf   TABLAT              ; present data to table latch
    tblwt+*                     ; write data, perform a short write
                                ; to internal TBLWT holding register
    decfsz  hlpCtr1             ; loop until buffers are full
    bra     WRITE_BYTE_TO_HREGS

    ; now follow write procedure on page 103 of manual    
    bsf     EECON1, EEPGD       ; point to Flash program memory
    bcf     EECON1, CFGS        ; access Flash program memory
    bsf     EECON1, WREN        ; write enable
    bcf     INTCON, GIE         ; disable interrupts
    movlw   55h
    movwf   EECON2              ; write 55h
    movlw   0AAh
    movwf   EECON2              ; write 0AAh
    bsf     EECON1, WR          ; start erase (CPU stall)
    bsf     INTCON, GIE         ; re-enable interrupts
    bcf     EECON1, WREN        ; disable write

    ; now TBLPTR and FSR0 should be advanced by 64, so repeat
    ; until all 256 bytes are programed.
    ;decfsz  hlpCtr2
    ;bra     repeat64

    return

;**************************************************************
;* CAN "Read" Commands
;**************************************************************

    ;**************************************************************
    ;****** Read Firmware ID***************************************
    ;**************************************************************
TofReadFirmwareID:
    call    HLPCopyRxData
    mCANSendAlert_IDL   RxDtLngth

    return                  ; back to receiver loop

    ;**************************************************************
    ;****** Read Register *****************************************
    ;**************************************************************
TofReadReg:
    ;setup address pointer to CAN payload
    lfsr    FSR0, TXB0D0

	banksel	TXB0CON
	btfsc	TXB0CON,TXREQ			; Wait for the buffer to empty
	bra		$ - 2

    banksel uc_fpga_DATA
    movff   RxData, uc_fpga_DATA    ; put first byte as register address on DATA PORT
    bsf     uc_fpga_CTL     ; put CTL hi
    bsf     uc_fpga_DS      ; put DS hi
    bcf     uc_fpga_DS      ; DS back low
    bcf     uc_fpga_CTL     ; CTL back low
    
    setf    uc_fpga_DATADIR ; set DATA PORT as input
    bcf     uc_fpga_DIR     ; DIR low
    bsf     uc_fpga_DS      ; DS hi
    movff   uc_fpga_DATA, POSTINC0 ; move DATA PORT data to CAN TX buffer
    bcf     uc_fpga_DS      ; DS lo
    bsf     uc_fpga_DIR     ; DIR hi
    clrf    uc_fpga_DATADIR ; DATA PORT as output again

    mCANSendRdResponse  1
    return                  ; back to receiver loop

    ;**************************************************************
    ;****** Read Silicon ID ***************************************
    ;**************************************************************
TofReadSiID:
    movf    RxData+1,W
    call    asSelect

	banksel	TXB0CON
	btfsc	TXB0CON,TXREQ			; Wait for the buffer to empty
	bra		$ - 2

    mAsReadSiliconID    TXB0D0
    ; set FPGA programming lines to device H (= 8)
    mAsSelect 8
    mCANSendRdResponse  1
    return                  ; back to receiver loop


    END

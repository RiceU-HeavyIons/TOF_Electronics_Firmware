CAN_error
; this function handles packets that the MCU does not recognize, or that do not adhere
; to the CAN HLP spec by returning the packets with ID 11110000000
	lfsr	FSR2, CAN_msg_DLC	; FSR0 = &CAN_msg[DLC]
	movff	POSTINC2, ctr		; ctr = rx'd message length
								; FSR2 = &CAN_msg[D1]
	movlw	0xF0
	movwf	dsize				; dsize = F0, MSB's of error MSG_ID (see CAN HLP spec)
	call	send_msg
	return	

setup_PLD
; this function is called when a PLD configure packet is received.
; first check that it is the correct length of 2.
	movlw	0x02
	subwf	CAN_msg_DLC, 0				; WREG = DLC - 0x02
	bnz		CAN_error
; once here, the length is correct.  Go ahead with the instruction
	movff	CAN_msg_data0, write_to		; data0 holds PLD register address
	movf	CAN_msg_data1, 0			; data1 holds the byte to write
	call	write_byte_PLD

	setf	WREG
	movff	CAN_msg_data0, write_to
	call	read_byte_PLD				; read the register
	movwf	CAN_msg_data1

	lfsr	FSR2, CAN_msg_data0
	movlw	0x02
	movwf	ctr
	movlw	0x10
	movwf	dsize
	call	send_msg
	return

reset_TDCs
; This function is called when a reset_TDCs message is received
; it writes to the register that causes all TDCs to be reset synchronized
; first check that it is appropriately zero length
	clrf	WREG
	subwf	CAN_msg_DLC, 0
	bnz		CAN_error
	setf	write_to				; bunch_reset register is 0x07
	call	write_byte_PLD			; doesn't matter what data you write
	clrf	ctr						; return message length = 0
	movlw	0x30					; return message ID
	movwf	dsize
	call	send_msg
	return

status_to_PC
; First check that DLC = 0
	movf	CAN_msg_DLC,0			; WREG = DLC 
	sublw	0x00					; WREG = WREG - DLC
	bnz		CAN_error
; Ok it's a status request.  Get status from PLD.
	movlw	0x07
	movwf	write_to
	call	read_byte_PLD
; status is in WREG.  send it up CANbus
	movwf	CAN_msg_data0
	lfsr	FSR2, CAN_msg_data0
	movlw	0x01
	movwf	ctr
	movlw	0x50
	movwf	dsize
	call	send_msg
	return

handle_debug
	lfsr	FSR0, CAN_msg_data0
test_for_MCU_reset
	movlw	0x45
	subwf	CAN_msg_data0,0		; WREG = 0 if this is a reset command
	bnz		test_for_PLD_reset
	movlw	0x69
	subwf	CAN_msg_data1,0		; WREG = 0 if this is a reset command
	bnz		test_for_PLD_reset
	movlw	0x33
	subwf	CAN_msg_data2,0		; WREG = 0 if this is a reset command	
	bnz		test_for_PLD_reset
	movlw	0x14
	subwf	CAN_msg_data3,0		; WREG = 0 if this is a reset command
	bnz		test_for_PLD_reset
	; ok, this is a legit restart command.
	call	stall
	call	return_debug_message
	call	stall
	goto	START			; start initialization code
test_for_PLD_reset
	movlw	0x69
	subwf	CAN_msg_data0,0		; WREG = 0 if this is PLD reset
	bnz		shortcut
	movlw	0x96
	subwf	CAN_msg_data1,0		; WREG = 0 if this is PLD reset
	bnz		shortcut
	movlw	0xA5
	subwf	CAN_msg_data2,0		; WREG = 0 if this is PLD reset
	bnz		shortcut
	movlw	0x5A
	subwf	CAN_msg_data3,0		; WREG = 0 if this is PLD reset
	bnz		shortcut
	; ok, this is a legit PLD reset command.
	reset_PLD_FIFO
	call	return_debug_message
	return

return_debug_message
	movff	CAN_msg_DLC, ctr	; msg length = rx'd message length, FSR0 = &data1
	lfsr	FSR2, CAN_msg_data0
	movlw	0x90
	movwf	dsize				; MSG_ID[10:3] = 0x90
	call	send_msg
	return

shortcut
	goto	CAN_error
	return

startup_message
	movlw	0x04
	movwf	ctr			; send 4 bytes
	setf	CAN_msg_data0
	clrf	CAN_msg_data1
	clrf	CAN_msg_data2
	clrf	CAN_msg_data3	; set up message 0xFF 00 00 00
	#IF	CODE_BASE == 0x10000
	bsf		CAN_msg_data1, 0
	#ENDIF
	lfsr	FSR2, CAN_msg_data0
	movlw	0x70
	movwf	dsize
	call	send_msg
	return

handle_MS
	movlw	0x01
	cpfseq	CAN_msg_DLC
	goto	CAN_error
; Ok it's a legit M/S command
	movlw	0xAA
	cpfseq	CAN_msg_data0
	bra		try_slave
; If here, this is a master request
	bsf		PORTC, 1
	nop
	nop
	nop
; Insert code here to inform PLD that this is a master
;-----------------------------------------------------
	movlw	0xB0
	movwf	dsize
	movlw	0x01
	movwf	ctr
	lfsr	FSR2, CAN_msg_data0
	call	send_msg
	return
try_slave
	movlw	0x55
	cpfseq	CAN_msg_data0
	goto	CAN_error
	bcf		PORTC, 1
	nop
	nop
	nop
; Insert code here to inform PLD that this is a slave
;----------------------------------------------------
	movlw	0xB0
	movwf	dsize
	movlw	0x01
	movwf	ctr
	lfsr	FSR2, CAN_msg_data0
	call	send_msg
	return

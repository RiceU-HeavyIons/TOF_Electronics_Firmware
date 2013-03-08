write_byte_PLD
; This function writes one byte to a PLD register.
; Inputs:
;
;		WREG		=	byte to write
;		write_to	=	address to write (0 through 7)
;
; Outputs:		None.
;
	tell_PLD_to_read
	bcf		PLD_addr, PLD_addr0
	bcf		PLD_addr, PLD_addr1
	bcf		PLD_addr, PLD_addr2
	rrcf	write_to		; rotate write_to and put LSB into C
	btfsc	STATUS, C
	bsf		PLD_addr, PLD_addr0
	rrcf	write_to
	btfsc	STATUS, C
	bsf		PLD_addr, PLD_addr1
	rrcf	write_to
	btfsc	STATUS, C
	bsf		PLD_addr, PLD_addr2
; Address is now on address output pins
	movwf	PLD_data		; PORTF = data to output
; Data is now in place.  Set the pins as outputs
	clrf	PLD_data_port_dir
; That's it, just strobe the data strobe
	bsf		PLD_strb_port, PLD_data_strb
	bcf		PLD_strb_port, PLD_data_strb
; Now the data should be read.  Set data pins back to inputs
	setf	PLD_data_port_dir
; And that should be all it takes
	return

read_byte_PLD
; This function reads one byte from a PLD register.
; Inputs:
;		write_to	=	address to read (0 through 7)
; Outputs:
;		WREG = read data
;
; First set data pins as inputs
	setf	PLD_data_port_dir
; Now set the address pins appropriately
	bcf		PLD_addr, PLD_addr0
	bcf		PLD_addr, PLD_addr1
	bcf		PLD_addr, PLD_addr2
	rrcf	write_to
	btfsc	STATUS, C
	bsf		PLD_addr, PLD_addr0
	rrcf	write_to
	btfsc	STATUS, C
	bsf		PLD_addr, PLD_addr1
	rrcf	write_to
	btfsc	STATUS, C
	bsf		PLD_addr, PLD_addr2
; Address is now on address output pins.
	tell_PLD_to_write
; Pulse data strobe
	bsf		PLD_strb_port, PLD_data_strb
; grab the data to WREG
	movf	PLD_data, 0
	bcf		PLD_strb_port, PLD_data_strb
	tell_PLD_to_read
; And that should be all
	return
	
check_for_PLD_data
; this funtion checks to see if there is PLD data waiting
; if there is, it calls grab_PLD_data to get it.
	btfsc	FIFO_empty_port, FIFO_empty	; if FIFO_empty is NOT clear
	bra		no_PLD_data
	call	grab_PLD_data_new
	call	TDC_data_CAN
no_PLD_data	
	return

grab_PLD_data_new
; This should get 32-bit data from the PLD according to LWB & JK's new system 10/12/04
	setf	PLD_data_port_dir			; data port is input
	lfsr	FSR0, PLD_word				; Ready to store data in PLD_word
; First set address of first data register, 0x2:
	bcf		PLD_addr, PLD_addr0
	bsf		PLD_addr, PLD_addr1
	bcf		PLD_addr, PLD_addr2
; Address is set.  Set PLD to output:	
	tell_PLD_to_write
; Pulse data strobe and collect a byte.  Four times.
	bsf		PLD_strb_port, PLD_data_strb
	movff	PLD_data, POSTINC0
	bcf		PLD_strb_port, PLD_data_strb		; 1
; Got one byte.  Now read address 0x03
	bsf		PLD_addr, PLD_addr0
	bsf		PLD_strb_port, PLD_data_strb
	movff	PLD_data, POSTINC0
	bcf		PLD_strb_port, PLD_data_strb		; 2
; Got two bytes.  Now read address 0x04
	bsf		PLD_addr, PLD_addr2
	bcf		PLD_addr, PLD_addr1
	bcf		PLD_addr, PLD_addr0
	bsf		PLD_strb_port, PLD_data_strb
	movff	PLD_data, POSTINC0
	bcf		PLD_strb_port, PLD_data_strb		; 3
; Got three bytes.  Now read address 0x05
	bsf		PLD_addr, PLD_addr0
	bsf		PLD_strb_port, PLD_data_strb
	movff	PLD_data, POSTINC0
	bcf		PLD_strb_port, PLD_data_strb		; 4
; Ok got all four bytes.  Now "read" register 6 to increment the FIFO
	bsf		PLD_addr, PLD_addr1
	bcf		PLD_addr, PLD_addr0
	bsf		PLD_strb_port, PLD_data_strb
	bcf		PLD_strb_port, PLD_data_strb
	tell_PLD_to_read
	return

TDC_data_CAN
; first move the data word to dataword1
; then test to see if another DATA word is ready from PLD
; if it is, put it in dataword2
; if not, send a 4 byte message
	lfsr	FSR0, PLD_word			; FSR0 -> PLD_word
	lfsr	FSR1, dataword1			; FSR1 -> dataword1[3]
	movff	POSTINC0, POSTINC1		; FSR0 -> PLD_word[3],
									; dataword1[3] = PLD_word[3],
									; FSR1 -> dataword1[3]
	movff	POSTINC0, POSTINC1
	movff	POSTINC0, POSTINC1
	movff	INDF0, INDF1			; dataword1 now holds recent PLD_word
	btfsc	FIFO_empty_port, FIFO_empty	; if FIFO_empty is clear
	bra		send_1_word				; then only send 1 word
									; else get started on word #2
; first test to make sure the waiting data is TDC data
	call	grab_PLD_data_new		; if it is, grab the next word
	lfsr	FSR0, PLD_word
	lfsr	FSR1, dataword2
	movff	POSTINC0, POSTINC1
	movff	POSTINC0, POSTINC1
	movff	POSTINC0, POSTINC1
	movff	INDF0, INDF1		; put the new word in dataword2
	movlw	0x08
	bra		send_whatever
send_1_word
	movlw	0x04
send_whatever
	movwf	ctr						; # of bytes to send = 4 or 8
	lfsr	FSR2, dataword1			; where to start = dataword1
	clrf	dsize					; MSG_ID[10:3] = 00
	call	send_msg
	return

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
	bsf		PLD_ctrl, PLD_data_strb
	bcf		PLD_ctrl, PLD_data_strb
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
	bsf		PLD_ctrl, PLD_data_strb
; grab the data to WREG
	movf	PLD_data, 0
	bcf		PLD_ctrl, PLD_data_strb
	tell_PLD_to_read
; And that should be all
	return
	
check_for_PLD_data
; this funtion checks to see if there is PLD data waiting
; if there is, it calls grab_PLD_data to get it.
	btfsc	PLD_ctrl, FIFO_empty	; if FIFO_empty is NOT clear
	bra		no_PLD_data
	call	grab_PLD_data_new
	call	TDC_data_CAN
no_PLD_data	
	return

grab_PLD_data_new
; This should get 32-bit data from the PLD according to LWB & JK's new system 10/12/04
	setf	PLD_data_port_dir			; data port is input
	lfsr	FSR0, PLD_word				; Ready to store data in PLD_word
; First set address of data register, 0x4:
	bcf		PLD_addr, PLD_addr0
	bcf		PLD_addr, PLD_addr1
	bsf		PLD_addr, PLD_addr2
; Address is set.  Set PLD to output:	
	tell_PLD_to_write
; Pulse data strobe and collect a byte.  Four times.
	bsf		PLD_ctrl, PLD_data_strb
	movff	PLD_data, POSTINC0
	bcf		PLD_ctrl, PLD_data_strb		; 1
	bsf		PLD_ctrl, PLD_data_strb
	movff	PLD_data, POSTINC0
	bcf		PLD_ctrl, PLD_data_strb		; 2
	bsf		PLD_ctrl, PLD_data_strb
	movff	PLD_data, POSTINC0
	bcf		PLD_ctrl, PLD_data_strb		; 3
	bsf		PLD_ctrl, PLD_data_strb
	movff	PLD_data, POSTINC0
	bcf		PLD_ctrl, PLD_data_strb		; 4
	tell_PLD_to_read
	return

get_tray_posn
; This grabs the tray position stored in PLD register.
	setf	PLD_data_port_dir			; data port is input
; set address of position register, 0x5
	bsf		PLD_addr, PLD_addr0
	bcf		PLD_addr, PLD_addr1
	bsf		PLD_addr, PLD_addr2
; Address is set.  Set PLD to output
	tell_PLD_to_write
; Pulse data strobe and collect the byte
	bsf		PLD_ctrl, PLD_data_strb
	movff	PLD_data, tray_posn
	bcf		PLD_ctrl, PLD_data_strb
	tell_PLD_to_read
	movlw	0xE0
	andwf	tray_posn
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
	btfsc	PLD_ctrl, FIFO_empty	; if FIFO_empty is clear
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

;grab_PLD_data
;; gets 5 bytes of PLD data
;	lfsr	FSR0, PLD_word			; FSR0 = &PLD_word
;	set_RX_ready
;grab_PLD_byte1
;	btfss	PLD_ctrl, PLD_ready		; wait for flag to go high (should ALWAYS be high 1st time)
;	bra		grab_PLD_byte1
;	movff	PLD_data, POSTINC0		; PLD_word = PLD_data, FSR++
;	clear_RX_ready					; tell PLD data has been received
;	nop
;	set_RX_ready
;grab_PLD_byte2
;	btfss	PLD_ctrl, PLD_ready
;	bra		grab_PLD_byte2
;	movff	PLD_data, POSTINC0
;	clear_RX_ready
;	nop
;	set_RX_ready
;grab_PLD_byte3
;	btfss	PLD_ctrl, PLD_ready
;	bra		grab_PLD_byte3
;	movff	PLD_data, POSTINC0
;	clear_RX_ready
;	nop
;	set_RX_ready
;grab_PLD_byte4
;	btfss	PLD_ctrl, PLD_ready
;	bra		grab_PLD_byte4
;	movff	PLD_data, POSTINC0
;	clear_RX_ready
;	return
;
; This subroutine checks JTAG ID_CODE.  The instruction for this is 10001 using even parity.
; This subroutine assumes TAP controller is in T-L-R to start, and leaves the TAP controller
; in T-L-R when finished.
;id_code_PLD
;	control_PLD_JTAG
;	movlw	0x68		; 10 0110 1000 = ID_CODE instruction
;	movwf	inst		
;	movlw	0x02
;	movwf	dsize
;	call	PLD_IRscan	; shift inst into JTAG instruction register
;	movlw	0x04		; ID_CODE is 4 bytes
;	movwf	dsize
;	lfsr	FSR0, ctr
;	; ID_Code is not saved currently.  If you want it, allocate space for it
;	; and put a pointer to where you want the MSB in write_to before calling DRScan
;	setf	write_to
;	lfsr	FSR1, CAN_msg_data0
;	call	DRScan		; Read back ID_Code
;	allow_BB_PLD
;	return
;
; 9/13/04: I think there's no point in doing this.  The MCU won't work
; unless the PLD is already configured.
;reset_PLD
;	control_PLD_JTAG
;	movlw	0x01
;	movwf	inst
;	clrf	dsize		; 00 0000 0001  = PULSE_NCONFIG
;	call	PLD_IRscan
;	nop
;	reset_TAP
;	allow_BB_PLD
;	call	stall
;	reset_PLD_FIFO
;	return
;

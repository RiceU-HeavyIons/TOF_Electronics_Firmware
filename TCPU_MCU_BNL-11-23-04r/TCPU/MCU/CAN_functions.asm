handle_CAN_msg
; This function takes no inputs, but responds to the most recently received
; CANbus message, stored in CAN_msg, according to the CAN HLP spec
; is this a status request?
	lfsr	FSR0, CAN_msg_header	; FSR0 = &CAN_msg
	movf	PREINC0,0				; FSR0 = &CAN_msg[MSG_ID]
									; WREG = MSG_ID
	andlw	0xF8					; WREG = MSG_ID Mask[11111000]
	movwf	ctr						;  ctr = MSG_ID Mask[11111000]
	sublw	0x60					; WREG = (MSG_ID & F8) - 0x60
	bnz		is_it_PLD_setup?
	call	status_to_PC
	return
is_it_PLD_setup?
; ok.  is it a PLD control word change command?
	movf	ctr,0					; WREG = ctr = MSG_ID (Masked)
	sublw	0x20					; WREG = (MSG_ID & F8) - 0x20
	bnz		is_it_reset_TDCs?
	call	setup_PLD
	return
is_it_reset_TDCs?
; ok.  Then is it a reset_TDCs packet?
	movf	ctr,0
	sublw	0x40
	bnz		is_it_debug?
	call	reset_TDCs
	return
is_it_debug?
	movf	ctr,0
	sublw	0xA0
	bnz		is_it_MS?
	call	handle_debug
	return
is_it_MS?
	movf	ctr,0
	sublw	0xC0
	bnz		is_it_reprogram?
	call	handle_MS
	return
is_it_reprogram?
	#IF	CODE_BASE == 0x0
	movf	ctr,0
	sublw	0x80
	bnz		unrecognized_message
	call	handle_reprogram_pkt
	return
	#ENDIF
unrecognized_message
	call	CAN_error
	return


send_msg
; this takes in a number of payload bytes to send in ctr, and a start address in WREG.
; it sends ctr # of bytes, starting at the address in WREG over CANbus.
; inputs:
;			ctr = # of bytes to send
;		   FSR2 = source address (start)
;		  dsize = 8 MSB's of MSG_ID
;
; Set up MSG ID, MSG type:
	movlw	0x31			; WREG = 0x31, TXB0SIDH
	movwf	write_to		; write_to = 0x31, TXBnSIDH
	; dsize is already set for the call to write_byte_2515 & no longer needed after:
	call	write_byte_2515	; first 8 bits of MSG_ID
	incf	write_to		; write_to = 0xn2, TXBnSIDL
	movlw	0x08			; EID bit (bit 3 of TXBnSIDL) = 1 for extended ID
	movwf	dsize			; 0x32 = 0x20
	call	write_byte_2515	; [7:5] = 3 LSB's of MSG_ID.  everything else 0's (for standard ID)
	incf	write_to		; 0x33 = 0x00
	clrf	dsize
	call	write_byte_2515	; all EID bits set to 0
	incf	write_to		; 0x34 = 0x00
	clrf	dsize
	call	write_byte_2515	; all EID bits set to 0
; set data length:
	incf	write_to			; write_to = 0x35 = TXBnDLC
	movff	ctr, dsize			; dsize = ctr (dsize is input to write_byte_2515)
	call	write_byte_2515		; write ctr (size) to TXBnDLC
; write payload to 2515:
	incf	write_to			; write_to = 36, TXBnD0
	; ctr and FSR2 are already set		
	; write_to = TXBnD0
	; ctr	   = # of payload bytes
	; FSR2  = &data_to_send
	call	write_2515
; request to send message
	select_2515
	movlw	0x05		; Bit modify instruction
	xmit_SPI
	movlw	0x30		; WREG = 0x30, TXBnCTRL
	xmit_SPI
	movlw	mask3		; WREG = 0000 1000 
	xmit_SPI			; bit modify mask-- now modifying TXBnCTRL.TXREQ
	movlw	0x08		; 
	xmit_SPI			; set TXREQ to request transmission	
	deselect_2515
	return

get_msg
; this stores an incoming CAN message in TEMP_CAN_MSG
; if no incoming message is available, WREG = 0xFF and the function returns
	read_2515	0x2C	; read CANINTF
	btfss	WREG,0		; if no message received
	bra		no_msg		; then exit.
						; else read & store the message:
	lfsr	FSR0,CAN_msg_header
	read_2515	0x60	; read RXB0CTRL
	movwf	POSTINC0
	read_2515	0x61	; read RXB0SIDH
	movwf	POSTINC0
	read_2515	0x62	; read RXB0SIDL
	movwf	POSTINC0
	read_2515	0x65	; read RXB1DLC
	movwf	POSTINC0
	read_2515	0x66	; read RXB0D0
	movwf	POSTINC0
	read_2515	0x67
	movwf	POSTINC0
	read_2515	0x68
	movwf	POSTINC0
	read_2515	0x69	; read RXB0D3
	movwf	POSTINC0
	read_2515	0x6A
	movwf	POSTINC0
	read_2515	0x6B
	movwf	POSTINC0
	read_2515	0x6C	; read RXB0D6
	movwf	POSTINC0
	read_2515	0x6D
	movwf	POSTINC0
	mwrite_2515	0x2C, 0x00	; clear CANINTF
	clrf	WREG
	return
no_msg
	movlw	0xFF
	return

config_2515
;***------------------- 1mbps @ 20MHz ------------------------***
; Clock = 20MHz, BRP = 0, Tq = 100ns
; use 10 Tq's so that bit period is 1us = 1mbps
	mwrite_2515	0x28, 0x02	; write 0x02 to addr 0x28 (CNF3)
	; CNF3[7]: D.C.
	; CNF3[6]: WAKFIL = 0, wake-up filter disabled
	; CNF3[5:3]: = D.C.
	; CNF3[2:0]: Phase segment 2 length = 010 = 3 * TQ
	mwrite_2515	0x29, 0x99	; write 0x99 to 0x29 (CNF2)
	; CNF2[7]: BTLMODE = 1, Phase 2 determined by CNF3[2:0]
	; CNF2[6]: SAM = 0, sample 1x
	; CNF2[5:3]: PHSEG1 = 011 = 4 * Tq
	; CNF2[2:0]: PRSEG = 001 = 2 * Tq
	mwrite_2515	0x30, 0x00	; write 0x00 to 0x30 (CNF1)
	; CNF1[7:6] = SJW = sync jump width = 00 = 1 * Tq
	; CNF1[5:0] = Baud rate prescaler = 0
;***-----------------------------------------------------------***

	; set up masks & filters 
	mwrite_2515	0x20, 0x00		; RXM0SIDH
	mwrite_2515	0x21, 0x00		; RXM0SIDL
	mwrite_2515	0x22, 0x00		; RXM0EID8
	mwrite_2515	0x23, 0x00		; RXM0EID0
	mwrite_2515	0x00, 0x00		; RXF0SIDH
	mwrite_2515	0x01, 0x09		; RXF0SIDL
	mwrite_2515	0x02, 0x00		; RXF0EID8
	mwrite_2515	0x03, 0x00		; RXF0EID0
	mwrite_2515	0x04, 0x00		; RXF1SIDH
	mwrite_2515	0x05, 0x09		; RXF1SIDL
	mwrite_2515 0x06, 0x00		; RXF1EID8
	mwrite_2515	0x07, 0x00		; RXF1EID0

	mwrite_2515	0x24, 0x00		; RXM1SIDH
	mwrite_2515	0x25, 0x00		; RXM1SIDL
	mwrite_2515	0x26, 0x00		; RXM1EID8
	mwrite_2515 0x27, 0x00		; RXM1EID0
	mwrite_2515	0x08, 0x00		; RXF2SIDH
	mwrite_2515	0x09, 0x09		; RXF2SIDL
	mwrite_2515	0x0A, 0x00		; RXF2EID8
	mwrite_2515	0x0B, 0x00		; RXF2EID0
	mwrite_2515	0x10, 0x00		; RXF3SIDH
	mwrite_2515	0x11, 0x09		; RXF3SIDL
	mwrite_2515	0x12, 0x00		; RXF3EID8
	mwrite_2515	0x13, 0x00		; RXF3EID0
	mwrite_2515	0x14, 0x00		; RXF4SIDH
	mwrite_2515	0x15, 0x09		; RXF4SIDL
	mwrite_2515	0x16, 0x00		; RXF4EID8
	mwrite_2515	0x17, 0x00		; RXF4EID0
	mwrite_2515	0x18, 0x00		; RXF5SIDH
	mwrite_2515	0x19, 0x09		; RXF5SIDL
	mwrite_2515	0x1A, 0x00		; RXF5EID8
	mwrite_2515	0x1B, 0x00		; RXF5EID0

	; RXB0CTRL: [6:5] = 11 -> Mask/Filters off
	;			  [2] = 1  -> Rollover B0 to B1 if B0 full

	mwrite_2515	0x60, 0x44		; Filters on -- RX only valid Ext. ID
								; packets that match filter criteria
	mwrite_2515 0x70, 0x44
;	mwrite_2515 0x60, 0x64		; Turn off filters

	mwrite_2515	0x2B, 0x00		; write 0x00 to 0x2B (CANINTE)
	return

normal_mode
	select_2515
	movlw	0x05		; 2515 bit modify instruction
	xmit_SPI
	movlw	0x0F		; addr of CANCTRL
	xmit_SPI
	movlw	0xE0		; 1110 0000 mask
	xmit_SPI
	movlw	0x00		; CANCTRL[7:5] = REQOP = 000 = normal mode
	xmit_SPI
	deselect_2515
	return

config_mode
	select_2515
	movlw	0x05		; 2515 bit modify instruction
	xmit_SPI
	movlw	0x0F		; addr of CANCTRL
	xmit_SPI
	movlw	0xE0		; 1110 0000 mask
	xmit_SPI
	movlw	0x80		; CANCTRL[7:5] = REQOP = 100 = config mode
	xmit_SPI
	deselect_2515
	return

loopback_mode
	select_2515
	movlw	0x05		; 2515 bit modify instruction
	xmit_SPI
	movlw	0x0F		; addr of CANCTRL
	xmit_SPI
	movlw	0xE0		; 1110 0000 mask
	xmit_SPI
	movlw	0x40		; CANCTRL[7:5] = REQOP = 010 = loopback mode
	xmit_SPI
	deselect_2515
	return

read_2515_status
	select_2515
	movlw	0xA0		; 2515 read_status instruction
	xmit_SPI
	deselect_2515
	return

reset_2515
	select_2515
	movlw	0xC0			; 2515 reset instruction
	xmit_SPI
	deselect_2515	
	return

CAN_init
	call	reset_2515
	call	stall			; 128 cycles of Fosc (1.25MHz) = 102us.
	call	stall
	call	stall
;	bsf		PORTA, 3		; CAN nRESET = 1 (reset inactive)
							; this pin is the LED on rev 2 boards
	read_2515	0x1D
	call	config_2515
	call	normal_mode
	return

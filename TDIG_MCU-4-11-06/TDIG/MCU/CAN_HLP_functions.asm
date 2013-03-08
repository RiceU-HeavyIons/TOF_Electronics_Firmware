CAN_reconfigure
; this function is called when a change_config packet is received.
; first, it checks to find out what kind of packet this is, and if that is appropriate:
; First, test for data packet.  this is the most frequent packet, so checking for it first
; speeds things up overall.
	lfsr	FSR0, CAN_msg_data0
	; For a data packet:
	; DES[7:6] = 01
	; DES[5]   = X
	; DES[4]   = X
	; DES[3:0] = 0001 - 1101
	movlw	0xC0				; Mask = 11000000
	andwf	INDF0,0				; WREG = xx000000, xx = current instruction code
	sublw	0x40				; 0x40 in WREG indicates this is a data instruction
	bnz		test_for_start		; otherwise, see if it's a start instruction
; now see if this is a VALID data instruction.
; first see if 0 < desc[3:0]
	movlw	0x0F
	andwf	INDF0,0
	bz		config_msg_error	; packet number should never be zero for data instructions
; then see if desc[3:0] <= 12b.
	sublw	0x0C				; WREG = 0x12 - desc[3:0]
	bn		config_msg_error	; should ALWAYS be non-negative
; packet number is within range
; test to make sure the correct TDC is set
	movf	CAN_msg_IDh,0		; WREG = CAN_msg_IDh		
	cpfseq	prev_header		; for valid non-start subinstruction this will always be true
	bra		config_msg_error
; once here, we know the TDC# matches the previous instruction
;******************************************************************************
; then see that desc[3:0] = prev_desc[3:0] + 1.  
	movlw	0x0F
	andwf	INDF0,0
	movwf	ctr					; ctr temporarily stores current packet number
	movlw	0x0F
	andwf	prev_desc,0			; WREG = prev_desc[3:0] (again)
	incf	WREG				; WREG = prev_desc[3:0] + 1
	; at this point, WREG should match the current packet number (in ctr)
	subwf	ctr,0				; WREG = prev_desc[3:0] + 1 - desc[3:0]
	bnz		config_msg_error	; if not zero, something is wrong
; once here, we know that the packet number is valid.  Test one more thing.
; if packet number = 1, then previous instruction should be START
	movlw	0x0F
	andwf	INDF0,0				; WREG = pkt number
	sublw	0x01				
	bnz		handle_config_data	; only perform next text if pkt# = 1
	movlw	0xC0
	andwf	prev_desc,0			; WREG = xx000000, xx = previous instruction code, should be 00
	bnz		config_msg_error
; once here, we have a valid data packet instruction
	call	handle_config_data
	return
test_for_start
; branching here indicates that it is not a data packet.  test to see if it is a start packet.
; a start packet will ALWAYS restart the config_TDC process, so there is no need to check previous_pkt
	; we are looking for the START subinstruction.  The descriptor for a START is as follows:
	; DES[7:6] = 00   -> START
	; DES[5]   = X    -> no error signal from PC
	; DES[4]   = X    
	; DES[3:0] = 0000 -> packet #0
	movlw	0xCF				; 11001111 mask.  we don't care about DES[5:4]
	andwf	INDF0,0				; WREG should be zero if this is a valid start instruction
	bnz		test_for_config_end	; if WREG != 0, this isn't a start instruction
	; now that we're here, we have a valid reconfigure START subinstruction.  first thing is to
	; set prev_desc and prev_header.
	movff	INDF0, prev_desc	; prev_desc = descriptor
	movff	CAN_msg_IDh, prev_header
	call	confirm_config		; return the packet to confirm
	return
test_for_config_end
	; for config_end:
	; DES[7:6] = 10
	; DES[5]   = X    		  -> no error signal from PC
	; DES[4]   = X
	; DES[3:0] = 0000	      -> 12th packet is last data packet
	movlw	0xCF				; Mask.  we don't care about DES[5:4]
	andwf	INDF0,0				; WREG now holds the desctiptor with 0's in bits 5,4
	sublw	0x80				; 0x80 in WREG indicates that this is a config_end instruction
	bnz		test_for_program
	; now test to see that it is appropriate to get a config_end instruction at this time:
	; prev_desc[7:6] should be 01, Data.  Also, TDC# should match, and previous packet number
	; should be 1101.
	; prev_des = 01xT1101
	movlw	0x4C				; 01001100 = expected prev_desc (without TDC# set)	
	cpfseq	prev_desc
	bra		config_msg_error	; if the value in WREG != prev_desc, then an error has occured
	movf	CAN_msg_IDh,0
	cpfseq	prev_header			; compare current MsgID[10:3]
	bra		config_msg_error
	; Once here, we have a valid config_end instruction.  
	; No good way to check for 647 bits, but we should be able to assume that things went ok
	; because of the prev_desc checks.
	call	ready_config_data
	return
test_for_program
	; for program:
	; DES[7:6] = 11
	; DES[5]   = X
	; DES[4]   = X
	; DES[3:0] = 0000
	movlw	0xCF				; mask out bits [5,4], don't care
	andwf	INDF0,0
	sublw	0xC0				; 0xC0 in WREG indicates that this is a program instruction
	bnz		config_msg_error	; we have tested for all four types of subinstructions and received none
	; now test to see that we are ready for a program instruction at this time:
	; prev_desc[7:6] should be 10, config_end.  TDC# should match, and previous packet # should be 0
	; prev_desc = 10xx0000
	movf	CAN_msg_IDh,0		; WREG = CAN_msg_IDh
	cpfseq	prev_header			; compare current MsgID[10:3]
	bra		config_msg_error
	movlw	0x80				; WREG = expected prev_desc value for TDC1
	subwf	prev_desc,0			; WREG = prev_desc - expected desc (TDC1)
	bz		valid_program_msg
	movlw	0x00
	subwf	prev_desc,0			; WREG = prev_desc
	bz		valid_program_msg	; if prev_desc = 0, this is a valid START-PROGRAM reapply command
	bra		config_msg_error	; if value in WREG != prev_desc, error has occured
	; once here, we have received a valid program instruction.
valid_program_msg
	call	program_config_data
	return

config_msg_error
; This function handles replying to the CAN-PC in the case of a reconfiguration error.
; Currently, an error causes nothing to happen.  If you send a wrong packet, it is echoed
; back, and sending the correct packet will pick up things where they left off.
;
; In order to force the CAN-PC to restart the config routine, add the following lines here:
;	movlw	0xFF
;	movwf	prev_desc
	lfsr	FSR2, CAN_msg_data0	; FSR2 = &CAN_msg[D1]
	bsf		CAN_msg_data0,5
	movff	CAN_msg_DLC, ctr
	movlw	0x10
	subwf	prev_header,0		; WREG = prev_header - 0x10 (see CAN HLP spec.  this is MsgID[10:3]
	movwf	dsize				; dsize = WREG, MSB's of configure reply MSG_ID (see CAN HLP spec)
	call	send_msg
	return

handle_config_data
; set up a pointer to the correct spot in the config array
	movlw	0x0F
	andwf	INDF0,0				; WREG = packet number
	decf	WREG				; WREG = pkt# - 1
	mullw	0x07				; PRODL = results of multiplication = offset into config array
	
	movff	PRODL,WREG			; WREG = result of multiplication
	lfsr	FSR1,config_temp	; FSR1 = &config_temp = 0xDC
	addwf	FSR1L				; FSR1 = &config_temp + offset without carry
	btfsc	STATUS,C
	bsf		FSR1H,0				; set FSR1H,0 if the carry bit (status,c) is set
; WREG points to next location in the temporary config array to write
; set up new prev_desc, and pointer to CAN message data
	movff	CAN_msg_IDh, prev_header
	movff	POSTINC0, prev_desc	; prev_desc = current descriptor, FSR0 -> data byte 1
; now move the data from the CAN msg to the config_temp array.
; FSR0 points to the correct spot in the CAN msg.  WREG points to destination.
; don't forget: if this is packet 12, we only want to do this 4 times:
	movlw	0x0F
	andwf	prev_desc,0			; WREG = current pkt# (prev_desc already been set)
	sublw	0x0C
	bz		packet_12			; skip the first 3 xfrs if this is packet 12
	movff	POSTINC0, POSTINC1	; byte 1
	movff	POSTINC0, POSTINC1	; byte 2
	movff	POSTINC0, POSTINC1	; byte 3
packet_12
	movff	POSTINC0, POSTINC1	; byte 4
	movff	POSTINC0, POSTINC1	; byte 5
	movff	POSTINC0, POSTINC1	; byte 6
	movff	POSTINC0, POSTINC1	; byte 7
; config array is set.	prev_desc is set.  now just confirm the packet
	call	confirm_config
	return

ready_config_data
; this function moves the configuration data from config_temp to appropriate
; config1_data, config2_data, config3_data, or config4_data
	movff	INDF0, prev_desc	; prev_desc = descriptor
	lfsr	FSR0, CAN_msg_header
	movf	PREINC0,0			; WREG = MSG_ID[10:3]
	movwf	prev_header			; prev_header = MSG_ID[10:3]
	andlw	0x06				; WREG = TDC# in bits [2:1]
	movwf	ctr					; ctr = TDC# in bits [2:1]
; Now set FSR2 to point to the correct TDC config array
	sublw	0x00				; WREG = WREG - 0x00
	bnz		try_TDC2
	lfsr	FSR2, config1_data	; FSR2 = &config1_data
	bra		destination_set
try_TDC2
	movf	ctr,0
	sublw	0x02
	bnz		try_TDC3
	lfsr	FSR2, config2_data
	bra		destination_set
try_TDC3
	movf	ctr,0
	sublw	0x04
	bnz		must_be_TDC4
	lfsr	FSR2,config3_data
	bra		destination_set
must_be_TDC4
	lfsr	FSR2,config4_data
destination_set
	lfsr	FSR1, config_temp	; FSR1 = &config_temp
	; at this point, FSR2 points to the base address of the correct TDC's config array
	; and FSR1 points to the base address of the temp config array.
	; so move the data from config_temp to config_data
	clrf	ctr
data_remains
	movff	POSTINC1, POSTINC2	; config_data[i] = config_temp[i]
	incf	ctr
	movlw	0x51
	subwf	ctr,0				; WREG = 51 - ctr
	bnz		data_remains
	call	confirm_config		; return the packet to confirm
	return

program_config_data
; first, turn off the config error LED.  If there is an error on this config, it will turn back on
	LED_OFF
	ifdef	TDC1
	control_TDC1
	call	config_parity		; config_parity sets parity bit according to control_TDCx setting
	call	config_basic		; resets and reconfigures designated TDC with new configuration info
	call	stall
	call	lock				; re-locks TDC
	endif
	ifdef	TDC2
	control_TDC2
	call	config_parity
	call	config_basic
	call	stall
	call	lock
	endif
	ifdef	TDC3
	control_TDC3
	call	config_parity
	call	config_basic
	call	stall
	call	lock
	endif
	ifdef	TDC4
	control_TDC4
	call	config_parity
	call	config_basic
	call	stall
	call	lock
	endif
	; new configuration has been written.
	call	confirm_config
	setf	prev_desc			; previous descriptor gets an invalid value.  only a START command will work now
	return

confirm_config
	lfsr	FSR2, CAN_msg_data0	; FSR2 = &CAN_msg[D1]
	movff	CAN_msg_DLC, ctr
	movlw	0x10
	subwf	prev_header,0		; WREG = prev_header - 0x10 (see CAN HLP spec.  this is MsgID[10:3]
	movwf	dsize				; dsize = WREG, MSB's of configure reply MSG_ID (see CAN HLP spec)
	call	send_msg
	return	

set_control_word
; this function is called when a set_control instruction has been received.
; it programs the specified TDC with the new control word.
; the new control word is stored in the received CAN message, 0x22-0x26
	lfsr	FSR0, control		; FSR0 -> control
	lfsr	FSR1, CAN_msg_data0	; FSR1 -> CAN_msg_data
	movff	POSTINC1, POSTINC0	; control[0] = CAN_msg[data0]
	movff	POSTINC1, POSTINC0	; control[1] = CAN_msg[data1]
	movff	POSTINC1, POSTINC0	; control[2] = CAN_msg[data2]
	movff	POSTINC1, POSTINC0	; control[3] = CAN_msg[data3]
	movff	INDF1, INDF0		; control[4] = CAN_msg[data4]	
; Control now holds the new control word.  Determine appropriate TDC
; TDC number is stored in CAN_msg_header[1], bits 2,1
; bit 0 is the "All TDC's" bit
; FSR1 points to CAN_msg_data[4]
	movf	CAN_msg_IDh,0
	btfsc	WREG,0
	bra		new_control_all
; once here, determine which of the 4 TDC's gets new config
	andlw	0x06				; mask out all but bits [2,1]
	movwf	ctr					; ctr masked msg_ID
	ifdef	TDC1
	movlw	0x00
	subwf	ctr,0				; WREG = ctr - 0
	bnz		not_control_TDC1
	control_TDC1
	call	new_control
	bra		control_set
	endif
not_control_TDC1
	ifdef	TDC2
	movlw	0x02
	subwf	ctr,0
	bnz		not_control_TDC2
	control_TDC2
	call	new_control
	bra		control_set
	endif
not_control_TDC2
	ifdef	TDC3
	movlw	0x04
	subwf	ctr,0
	bnz		not_control_TDC3
	control_TDC3
	call	new_control
	bra		control_set
	endif
not_control_TDC3
	ifdef	TDC4
	movlw	0x06
	subwf	ctr,0
	bnz		not_control_TDC4
	control_TDC4
	call	new_control
	bra		control_set
	endif
not_control_TDC4
	call	CAN_error
	return
new_control_all
	ifdef	TDC1
	control_TDC1
	call	new_control
	endif
	ifdef	TDC2
	control_TDC2
	call	new_control
	endif
	ifdef	TDC3
	control_TDC3
	call	new_control
	endif
	ifdef	TDC4
	control_TDC4
	call	new_control	
	endif
control_set	
	movlw	0x05
	movwf	ctr					; ctr = return msg length
	movf	CAN_msg_IDh,0		; WREG = CAN_msg_IDh
	addlw	0xF0				; WREG = CAN_msg_IDh - 0x10
	movwf	dsize				; dsize = MSB's of control reply MSG_ID
	lfsr	FSR2, CAN_msg_data0	; FSR2 -> CAN_msg_data
	call	send_msg
	return

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

TDC_JTAG_data_to_PC
; this function sends TDC data formatted as specified in the CAN spec
; it accepts no inputs
	call	get_data_word		; get_data from WHICHEVER TDC is selected
	btfsc	WREG,0
	return						; if WREG = 0xFF, return with no data
	; on return from get_data_word, if WREG = 0x00, then new data is stored 
	; in dataword1.  If WREG = 0xFF, then ignore dataword1. This assumes that 
	; WREG survives intact from datagrab through get_data_word to here.
;**** KIND OF UGLY CODE HERE *****
	lfsr	FSR0, dataword1		; move dataword1 contents to dataword2
	movlw	0x03
	movff	POSTINC0, PLUSW0
	movff	POSTINC0, PLUSW0
	movff	POSTINC0, PLUSW0
	movff	POSTINC0, PLUSW0	; dataword now in dataword2
	call	get_data_word
	btfsc	WREG,0
	bra		ship_one_word
	movlw	0x08
	movwf	ctr
	lfsr	FSR2, dataword1
	clrf	dsize
	call	send_msg
	return
;******** BEGIN MESSY CODE THAT IS NOT VERY PORTABLE AND RELIES ON FIXED PLD MUX ******;
; alternative is to write a select_next_TDC function.  a bit tricky, but probably worth it
;	btfss	WREG,0				; if WREG = 0
;	bra		ship_JTAG_data		; then ship the data
;	btg		PORTH,2				; increment selected TDC by one
;	call	get_data_word		; try the new TDC for data
;	btfss	WREG,0				; if WREG = 0
;	bra		ship_JTAG_data		; then ship the data
;	btg		PORTH,3				; else try another TDC by incrementing mux
;	call	get_data_word		; try the new TDC for data
;	btfss	WREG,0				; if WREG = 0
;	bra		ship_JTAG_data		; then ship the data
;	btg		PORTH,2				; try the final untried TDC
;	call	get_data_word
;	btfss	WREG,0
;	bra		ship_JTAG_data
;	return
ship_one_word
	movlw	0x04
	movwf	ctr					; send 8 bytes
	lfsr	FSR2, dataword2
	clrf	dsize				; dsize (MSG_ID[10:3]) = 0x00
	call	send_msg
	return

handle_threshold
	movlw	0x02
	cpfseq	CAN_msg_DLC
	bra		CAN_error
	lfsr	FSR0, CAN_msg_data0
	movff	POSTINC0, write_to	; ctr = LSB's of DAC word
	movff	INDF0, ctr			; write_to = MSB's of DAC word
	bcf		write_to,7			; DAC command = 0x4
	bsf		write_to,6
	bcf		write_to,5
	bcf		write_to,4			
	call	new_DAC_value
;------------------------------------------
; attempt to read feedback DAC value through ADC
	movlw	0x11
	movwf	ADCON0				; select channel AN4, turn AD unit on
	call	stall				; wait 100us, much longer than acquisition time
	bsf		ADCON0,1			; set GO bit
ADC_wait
	btfsc	ADCON0,1
	bra		ADC_wait
	movff	ADRESH, CAN_msg_data0
	movff	ADRESL, CAN_msg_data1	; ADC result is now stored in CAN msg for transmit
	movlw	0x02
	movwf	ctr						; ctr = 2, DLC for outbound message
;------------------------------------------
	lfsr	FSR2, CAN_msg_data0
	movlw	0xB0
	movwf	dsize
	call	send_msg
	return

status_to_PC
; First check that DLC = 0
	movf	CAN_msg_DLC,0			; WREG = DLC 
	sublw	0x00					; WREG = WREG - DLC
	bnz		CAN_error
; Test for board status request
	lfsr	FSR1, CAN_msg_header
	btfsc	PREINC1,0					; bit 4 of the Msg_ID is board status bit
	bra		board_status
; TDC requested is encoded in the message ID bits [5:4].  This is CAN_msg[MSG_ID](2:1)
	movf	INDF1,0				; WREG = MSG_ID
	andlw	0x06				; WREG = MSG_ID mask (00000110)
	movwf	ctr					; ctr = TDC number stored in bits 2,0
	ifdef	TDC1
	movlw	0x00				; WREG = 0x00 -> TDC1 ID
	subwf	ctr, 0				; WREG = 0x00 - ctr (0 if TDC1)
	bnz		not_TDC1			; if WREG = 0, request is for TDC1 status
	control_TDC1
	call	get_status
	movlw	0x08
	movwf	ctr
	movlw	0x50
	movwf	dsize				; dsize (MSG_ID[10:3]) = 0x50
	lfsr	FSR2, tdc_status
	call	send_msg
	return
	endif
not_TDC1
	ifdef	TDC2
	movlw	0x02
	subwf	ctr,0				; WREG = 0x02 - ctr (0 if TDC2)
	bnz		not_TDC2			; if WREG = 0, request is for TDC2 status
	control_TDC2
	call	get_status
	movlw	0x08
	movwf	ctr
	movlw	0x52
	movwf	dsize				; dsize (MSG_ID[10:3]) = 0x50
	lfsr	FSR2, tdc_status
	call	send_msg
	return
	endif
not_TDC2
	ifdef	TDC3
	movlw	0x04				
	subwf	ctr,0				; WREG = 0x04 - ctr (0 if TDC3)
	bnz		not_TDC3
	control_TDC3
	call	get_status
	movlw	0x08
	movwf	ctr
	movlw	0x54
	movwf	dsize
	lfsr	FSR2, tdc_status
	call	send_msg
	return
	endif
not_TDC3
	ifdef	TDC4
	movlw	0x06
	subwf	ctr,0				; WREG = 0x04 - ctr (0 if TDC4)
	bnz		not_TDC4
	control_TDC4
	call	get_status
	movlw	0x08
	movwf	ctr
	movlw	0x56
	movwf	dsize
	lfsr	FSR2, tdc_status
	call	send_msg
	return
	endif
not_TDC4
	call	CAN_error
	return

board_status
	movlw	0x01
	movwf	ADCON0				; select channel AN0, turn AD unit on
	call	stall				; wait 100us, longer than necessary
	bsf		ADCON0,1			; set GO bit
ADC_temp_wait1
	btfsc	ADCON0,1
	bra		ADC_temp_wait1
	movff	ADRESH, CAN_msg_data0
	movff	ADRESL, CAN_msg_data1
	movlw	0x05
	movwf	ADCON0
	call	stall
	bsf		ADCON0,1
ADC_temp_wait2
	btfsc	ADCON0,1
	bra		ADC_temp_wait2
	movff	ADRESH, CAN_msg_data2
	movff	ADRESL, CAN_msg_data3
	movlw	0x09
	movwf	ADCON0
	call	stall
	bsf		ADCON0,1
ADC_temp_wait3
	btfsc	ADCON0,1
	bra	ADC_temp_wait3
	movff	ADRESH, CAN_msg_data4
	movff	ADRESL, CAN_msg_data5
	movlw	0x0D
	movwf	ADCON0
	call	stall
	bsf		ADCON0,1
ADC_temp_wait4
	btfsc	ADCON0,1
	bra		ADC_temp_wait4
	movff	ADRESH, CAN_msg_data6
	movff	ADRESL, CAN_msg_data7
	bcf		ADCON0,0				; turn off ADC
	movlw	0x08
	movwf	ctr						; ctr = 2, DLC for outbound message
	lfsr	FSR2, CAN_msg_data0
	movlw	0x51
	movwf	dsize
	call	send_msg
	return

handle_debug
	lfsr	FSR0, CAN_msg_data0
test_for_MCU_mode
	movlw	0xAA
	subwf	CAN_msg_data0,0				; WREG = 0 if data1 = AA
	bnz		test_for_PLD_configure
; Once here, we have a real MCU mode switch command.  Check what mode it wants
test_for_mode_silent
	tstfsz	CAN_msg_data1
	bra		test_for_mode_PLD
	call	return_message
	goto	SILENT_LOOP
test_for_mode_PLD
	movlw	0x01
	subwf	CAN_msg_data1,0				; WREG = 0 if MCU mode = 1
	bnz		test_for_mode_JTAG
	call	return_message
	goto	PLD_LOOP
test_for_mode_JTAG
	movlw	0x02
	subwf	CAN_msg_data1,0				; WREG = 0 if MCU mode = 2
	bnz		bad_mode_byte
	call	return_message
	goto	JTAG_LOOP
bad_mode_byte
	call	CAN_error
	return
test_for_PLD_configure
	movlw	0xBB
	subwf	CAN_msg_data0,0
	bnz		test_for_MCU_reset
; ok, PLD mode switch.  check that DLC = 3
	movlw	0x03
	subwf	CAN_msg_DLC,0			; WREG = 0 if DLC = 3
	bz		valid_PLD_config_msg
	call	CAN_error
	return
valid_PLD_config_msg
; Once here, we have a PLD config switch command.
	movff	CAN_msg_data1, write_to
	movf	CAN_msg_data2,0			; WREG = byte 2 of message
	call	write_byte_PLD
	movff	CAN_msg_data1, write_to
	setf	WREG
	call	read_byte_PLD
	call	return_message
	return
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
	call	return_message
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
	call	return_message
	return

return_message
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

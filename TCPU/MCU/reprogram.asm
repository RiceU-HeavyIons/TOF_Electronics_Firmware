handle_reprogram_pkt
; This function is called when a reprogram packet of any kind is received.
; First thing to do is determine which type of packet it is:
; Check for data packet (most frequent packet)
	lfsr	FSR0, CAN_msg_data0
	; for data packet:
	; DES[3:0] = 0001
	; There should be no error bit set (DES[7])
	movf	INDF0, 0
	sublw	0x01
	bz		check_data_pkt_valid
; Ok, not a data packet.  Try a start packet
	movf	INDF0,0
	sublw	0x00
	bz		check_start_pkt_valid
; not a start packet either!  Hrmph.  Maybe it's a chksum_64
	movf	INDF0,0
	sublw	0x02
	bz		check_chksum64_pkt_valid
; Not a chk64?  Maybe it's a program_64
	movf	INDF0,0
	sublw	0x03
	bz		check_program64_pkt_valid
; not program64.  try final_chksum
	movf	INDF0,0
	sublw	0x04
	bz		check_final_chksum_valid
; Ok, it must be a jump_PC, right?
	movf	INDF0,0
	sublw	0x05
	bz		check_jumpPC_valid
; Fine!  Send it back!  I didn't want your stupid packet anyway!
	call	CAN_error
	return

; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;				FINAL CHECKSUM VALIDATOR:
;
; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

check_final_chksum_valid
; This function is called when a final_checksum packet is rx'd.  it checks that the 
; packet is valid.  First, check the length.  Should be 4.
	movlw	0x04
	subwf	CAN_msg_DLC, w
	bnz		reprogram_pkt_error_ptr
; Preceeding instruction may be a start or a program_64.  First check for start
	movlw	0x00
	subwf	prev_reprog_desc, w
	bz		final_chk_pkt_ok
; If here, previous instructino was not start.  check for program_64
	movlw	0x03
	subwf	prev_reprog_desc, w
	bnz		reprogram_pkt_error
; If here, previous instruction was program_64.
; check that current addr = prev addr + 0x40
	movff	prev_reprog_addrH, ctr2
	movff	prev_reprog_addrL, ctr		; counters as temporary holding registers
	movlw	0x40
	addwf	ctr
	btfsc	STATUS, C
	incf	ctr2						; [ctr2, ctr] should equal current addr
	movf	ctr2, w
	cpfseq	CAN_msg_data1
	bra		reprogram_pkt_error
	movf	ctr, w
	cpfseq	CAN_msg_data2
	bra		reprogram_pkt_error
; Once here, previous address is ok *OR* previous instruction was start
final_chk_pkt_ok
	call	handle_final_chksum
	return

; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;				JUMP PC VALIDATOR:
;
; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

check_jumpPC_valid
; this function is called when a Jump_PC command is RX's. It checks for validity.
; first, as always, check length:
	movlw	0x01
	subwf	CAN_msg_DLC, w
	bnz		reprogram_pkt_error
; Now confirm that previous instruction was a final_checksum
	movlw	0x04
	cpfseq	prev_reprog_desc
	bnz		reprogram_pkt_error
; If this test passes, the instruction is valid.  Time to jump the program counter
	goto	0x10000
	return

; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;				DATA PACKET VALIDATOR:
;
; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

check_data_pkt_valid
; This function is called when a reprogramming data packet is received.
; It checks that the packet is valid (no error conditions)
; First, see if this is a valid data instruction
; In all cases, a data packet should have length 7
	movlw	0x07
	subwf	CAN_msg_DLC, w
	bnz		reprogram_pkt_error
; For all data packets, one of two conditions must be met:
;	1) Previous instruction is START, and current address is 0x00
;	2) Previous instruction is DATA, and current address is prev_addr + 0x40
; First check for condition 1
	clrf	WREG
	subwf	prev_reprog_desc, w
	bz		prev_desc_start	
	movlw	0x01
	subwf	prev_reprog_desc, w
	bz		prev_desc_data
	call	reprogram_pkt_error
	return
prev_desc_start
; Here we know that the previous instruction was a start.
; Now make sure the address is the beginning of a 64-byte sector.
	movlw	0x3F
	andwf	CAN_msg_data2, w	; WREG = 0x00aaaaaa
; All bits in WREG should be zero
	clrf	ctr
	cpfseq	ctr
	bra		reprogram_pkt_error
	bra		data_addr_ok			; this is a valid data packet
prev_desc_data
; Here we know that the previous instruction was a data packet.
; Now make sure the address is equal to prev_addr + 0x04
	movlw	0x04
	addwf	prev_reprog_addrL, w
	btfsc	STATUS,C
	bra		addr_overflow
; WREG holds prev_reprog_addrL + 0x40, and there has been no overflow:
	cpfseq	CAN_msg_data2
	bra		reprogram_pkt_error
; current address = prev_reprog_addr + 0x40-- valid data packet
	bra		data_addr_ok
addr_overflow
; WREG holds prev_reprog_addrL + 0x40, and there has been overflow
	movlw	0xC0
	cpfseq	prev_reprog_addrL		; This must be true for a valid data
	bra		reprogram_pkt_error		; packet that has caused overflow
; Ok, overflow has happened, addrL is ok.  Check addrH
	movlw	0x01
	addwf	prev_reprog_addrH, w	; WREG = prev_addrH + 1 (the overflow)
	cpfseq	CAN_msg_data1			; WREG should equal CAN_data1 (addrH)
	bra		reprogram_pkt_error	
data_addr_ok
; Once here, the address is a valid one	
	call	handle_data_pkt
	return

; This is a silly little thing to handle the fact that relative branches
; are limited in their reach.  I don't want to use goto because my branches
; are conditional.
reprogram_pkt_error_ptr
	bra		reprogram_pkt_error


; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;				START PACKET VALIDATOR:
;
; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

check_start_pkt_valid
; This function is called when a reprogram start instruction is RX'd.
; It checks that the istruction is valid, and prepares the MCU for data
; packets.
; A start packet will always have length 1
	movlw	0x01
	subwf	CAN_msg_DLC, w
	bnz		reprogram_pkt_error
; Initialize prev_reprog_addrL, prev_reprog_addrH, and set prev_reprog_desc.
	setf	prev_reprog_addrL
	setf	prev_reprog_addrH
	movff	CAN_msg_data0, prev_reprog_desc	; prev_desc = current descriptor
; Ok, prev_addr and prev_reprog are now set.  Return the start packet
	call	confirm_reprog_pkt
	return

; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;				CHECKSUM 64 VALIDATOR:
;
; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

check_chksum64_pkt_valid
; This function is called when a chksum64 packet is received.  It checks
; that the packet is valid and calls the packet handler if so.
; First check packet length.  Should always be 4
	movlw	0x04
	subwf	CAN_msg_DLC,w
	bnz		reprogram_pkt_error
; A chksum64 packet is invalid unless the previous instruction was a data
; packet or a chksum64 packet.
; first check if it was a data packet:
	movlw	0x01
	subwf	prev_reprog_desc, w
	bz		chk64_prev_data
; now check for chk64
	movlw	0x02
	subwf	prev_reprog_desc, w
	bz		chk64_prev_chk64
; previous was neither, so send error:
	call	reprogram_pkt_error
	return
chk64_prev_chk64
; here we know that previous instruction was chk64.  Therefore the current
; address should match the previous address
	movf	prev_reprog_addrH, w
	cpfseq	CAN_msg_data1
	bra		reprogram_pkt_error
	movf	prev_reprog_addrL, w
	cpfseq	CAN_msg_data2
	bra		reprogram_pkt_error
; Ok, previous address matches current.  This is a valid chk64 packet
	bra		chk64_ok
chk64_prev_data
; here we know that previous instruction was data.  Therefore current
; address should be previous address minus 0x3C
	movff	prev_reprog_addrL, ctr
	movff	prev_reprog_addrH, ctr2	; counters used as temporary holding registers
; ASSUMPTION: NO 16-bit underflow (carry) is possible!
; there are only four possible valid cases for this subtraction:
; 0x...3C - 0x3C = 0x...00
; 0x...7C - 0x3C = 0x...40
; 0x...BC - 0x3C = 0x...80
; 0x...FC - 0x3C = 0x...C0
; THEREFORE NO CHECKING IS DONE FOR UNDERFLOW!!!
	movlw	0x3C
	subwf	ctr						; ctr = prev_addrL - 0x3C
; This doesn't work for underflow checking because it uses 2's complement
; Therefore, for example, 0xBC - 0x3C has a NEGATIVE result
;	btfsc	STATUS, N
;	decf	ctr2					; [ctr2, ctr] = prev_addr - 0x3C
	; ctr2, ctr now hold the address value that the current instruction's address
	; should match
	movf	ctr, w
	cpfseq	CAN_msg_data2
	bra		reprogram_pkt_error
	movf	ctr2, w
	cpfseq	CAN_msg_data1
	bra		reprogram_pkt_error
; If we reach here, the start address included in chk_64 is ok
; all that's left is to validate the checksum.
chk64_ok
	call	handle_chk64_pkt
	return

; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;				PROGRAM 64 VALIDATOR:
;
; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

check_program64_pkt_valid
; This function is called when a check_prog64 packet is received.
; It checks that the instruction is valid and calls the appropriate handler if so.
; A program_64 packet should always have length 3
	movlw	0x03
	subwf	CAN_msg_DLC, w
	bnz		reprogram_pkt_error
; program_64 must be preceded by chksum_64.  so check prev_desc
	movlw	0x02
	cpfseq	prev_reprog_desc
	bra		reprogram_pkt_error
; prev_addr should equal current.
	movf	prev_reprog_addrH, w
	cpfseq	CAN_msg_data1
	bra		reprogram_pkt_error
	movf	prev_reprog_addrL, w
	cpfseq	CAN_msg_data2
	bra		reprogram_pkt_error
; ok everything seems in order here.  go do it:	
	call	handle_program64
	return

; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;				RESPONSE HANDLERS:
;
; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

reprogram_pkt_error
; This function handles the reply when a reprogramming packet is received in error.
; All it has to do is set the error bit in the descriptor and echo the packet otherwise.
	bsf		CAN_msg_data0, 7			; set error bit
	call	confirm_reprog_pkt			; send it back now that error is set
	return

chk64_error
; this function is called when a checksum mismatch is detected
	movwf	CAN_msg_data4			; put the calculated checksum into CAN pkt
	movlw	0x05
	movwf	CAN_msg_DLC				; new DLC for this packet (because of checksum)
	call	reprogram_pkt_error
	return

confirm_reprog_pkt
; This function simply returns a reprogramming packet and is called any time
; a reprogramming packet command is successfully received and the appropriate
; action performed.
	lfsr	FSR2, CAN_msg_data0			; FSR2 -> &CAN_msg[d1]
	movff	CAN_msg_DLC, ctr
	movlw	0x10
	subwf	CAN_msg_IDh, 0				; WREG = return packet ID	
	movwf	dsize
	call	send_msg
	return

; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;				CHECKSUM 64 HANDLERS:
;
; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

handle_chk64_pkt
	movlw	0x40
	movwf	ctr						; we need to sum 64 addresses
	clrf	WREG
	lfsr	FSR0, new_prog_data		; FSR0 -> new program data array start
chksum64_loop
	addwf	POSTINC0,w
	decfsz	ctr
	bra		chksum64_loop			; at end of loop, WREG = chksum64
	cpfseq	CAN_msg_data3
	bra		chk64_error
; once here, checksum is validated.  just set up prev_addr and prev_desc and finished
	movff	CAN_msg_data1, prev_reprog_addrH
	movff	CAN_msg_data2, prev_reprog_addrL
	movff	CAN_msg_data0, prev_reprog_desc
	call	confirm_reprog_pkt
	return

; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;				DATA HANDLERS:
;
; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

handle_data_pkt
; Once here we are guaranteed that a valid new_data packet is sitting in the 
; incoming CAN message.  Need to move the foud data bytes to the proper spot in 
; the new_prog_data array.	
; address to write to is stored in CAN_msg_data2 and CAN_msg_data3
; data bytes are stored in CAN_msg_data4 through CAN_msg_data7
; First thing, set up an indirect pointer to the new_prog_data array
	lfsr	FSR0, new_prog_data		; FSR0 -> base of new_prog_data array
	movlw	0x3F
	andwf	CAN_msg_data2, 0		; WREG = lower 6 bits of address
	addwf	FSR0L					; Add 6 bit array offset to array pointer
	btfsc	STATUS,C				; handle overflow
	incf	FSR0H					; FSR0 -> spot in new_prog_data to write to

	lfsr	FSR1, CAN_msg_data3		; FSR1 -> new data stored in CAN msg
	movff	POSTINC1, POSTINC0
	movff	POSTINC1, POSTINC0
	movff	POSTINC1, POSTINC0
	movff	POSTINC1, POSTINC0		; move four bytes into new_prog_data array
; Everything is accomplished.  Now set prev_addr and prev_desc
	movff	CAN_msg_data0, prev_reprog_desc
	movff	CAN_msg_data1, prev_reprog_addrH
	movff	CAN_msg_data2, prev_reprog_addrL
	call	confirm_reprog_pkt
	return

; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;				PROGRAM 64 HANDLERS:
;
; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

handle_program64
; This function is called once a program_64 packet is RX'd and verified.  Once here,
; we know that the data stored in new_prog_data is good, and should be written to 
; FLASH memory starting at address referenced by CAN_msg_data2 and CAN_msg_data3
; data is written to FLASH 8 bytes at a time.
; First, erase the 64-byte sector before programming:
	movff	CAN_msg_data2, TBLPTRL
	movff	CAN_msg_data1, TBLPTRH
	movlw	0x01
	movwf	TBLPTRU					; now TBLPTR -> start of 64 byte sector
; THIS CODE TAKEN FROM MCU DATASHEET, PAGE 66:
	bsf		EECON1, EEPGD			; point to FLASH program memory
	bcf		EECON1, CFGS			; access FLASH program memory
	bsf		EECON1, WREN			; enable write to memory
	bsf		EECON1, FREE			; enable row erase operation
	bcf		INTCON, GIE				; disable interrupts
	movlw	0x55
	movwf	EECON2					; write 0x55
	movlw	0xAA
	movwf	EECON2					; write 0xAA
	bsf		EECON1, WR				; start erase (CPU stall)
	nop
	bsf		INTCON, GIE				; re-enable interrupts
; data sector is now erased and ready for reprogramming
; This function uses ctr2 to loop 8 times.  Each time it calls write_program once.
	lfsr	FSR0, new_prog_data		; FSR0 -> base of new program array
	movlw	0x08
	movwf	ctr2					; ctr2 is for the big loop
write_8_loop
	; FSR0 -> data source
	; TBLPTR -> program destination
	call	write_program
	; on return, FSR0, TBLPTR -> next location
	decfsz	ctr2
	bra		write_8_loop
; Ok everything's written to program memory.  check that program memory matches data memory
	movlw	0x40
	movwf	ctr
	movff	CAN_msg_data2, TBLPTRL
	movff	CAN_msg_data1, TBLPTRH
	movlw	0x01
	movwf	TBLPTRU
	clrf	WREG
	lfsr	FSR0, new_prog_data
; TBLPTR -> program memory, FSR0 -> data memory.  compare 64 bytes
program_check64
	tblrd*+
	movf	POSTINC0, w
	cpfseq	TABLAT
	bra		data_prog_mismatch
	decfsz	ctr
	bra		program_check64
; OK once here the data is correctly programmed.  set prev_* and respond
	movff	CAN_msg_data0, prev_reprog_desc
	movff	CAN_msg_data1, prev_reprog_addrH
	movff	CAN_msg_data2, prev_reprog_addrL
	call	confirm_reprog_pkt
	return

data_prog_mismatch
	bsf		CAN_msg_data0, 6
	call	confirm_reprog_pkt
	return

write_program
; This function writes eight bytes of data memory to program memory
; it uses FSR0 as a pointer to the data memory start location
; and TBLPTR as a pointer to the program memory location.
; When finished, INDF0 will point to incoming INDF0 + 8
	movlw	0x08
	movwf	ctr
write_to_holding_regs
	movf	POSTINC0, W
	movwf	TABLAT					; move first data word to table latch
	tblwt*+							; write data to holding register
	decfsz	ctr
	bra		write_to_holding_regs	; loop until 8 words moved
program_memory
	bsf		EECON1, EEPGD			; point to FLASH program memory
	bcf		EECON1, CFGS			; access FLASH program memory
	bsf		EECON1, WREN			; enable write to memory
	tblrd*-							; dummy read to decrement tblptr
									; so it is within range of program write address
									; see data sheet p. 69
	bcf		INTCON, GIE				; disable interrupts
	movlw	0x55
	movwf	EECON2					; write 0x55
	movlw	0xAA
	movwf	EECON2					; write 0xAA
	bsf		EECON1, WR				; begin program sequence (CPU will stall)
	nop
	bsf		INTCON, GIE				; re-enable interrupts
	bcf		EECON1, WREN			; disable memory write
	tblrd*+							; dummy read to set pointer back where it belongs.
	return

; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;
;				FINAL CHECKSUM HANDLER:
;
; -=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

handle_final_chksum
; this function is called once a final checksum packet has been validated.
; need to compare the incoming checksum with the calculated checksum for
; program memory from address 0x10000 through (but not including) address 
; included in the final_checksum packet
; this will be a checksum for thousands of bytes.  End address will always be a 
; 64-byte boundary though.  So calculate the checksum for 64 bytes at a time.
; following each 64-byte calculation, check whether TBLPTR matches address in the 
; instruction packet.
	clrf	ctr2					; ctr2 will hold the final checksum
	clrf	TBLPTRL
	clrf	TBLPTRH
	clrf	TBLPTRU
	incf	TBLPTRU					; TBLPTR = 0x10000
finalchk_outer_loop
	movlw	0x40
	movwf	ctr						; sum 64 addresses at a time
	clrf	WREG					; WREG will temporarily hold the 64-byte checksum
finalchk_inner_loop
	TBLRD*+							; read data at TBLPTR, TBLPTR++
	addwf	TABLAT, w				; add data into running 64-byte checksum
	decfsz	ctr
	bra		finalchk_inner_loop		; at end of loop, WREG = new 64-byte checksum
; new 64-byte checksum calculated.  add it to running total:
	addwf	ctr2					; ctr2 += WREG
; now check to see if we're done by comparing TBLPTR to rx'd command address
	movf	CAN_msg_data2,w
	cpfseq	TBLPTRL					; see if addrL = TBLPTRL
	bra		finalchk_outer_loop		; if TBLPTRL != addrL, then add another 64 bytes
	movf	CAN_msg_data1,w
	cpfseq	TBLPTRH					; see if addrH = TBLPTRH
	bra		finalchk_outer_loop		; if TBLPTRH != addrH, then add another 64 bytes
; If we get here, the checksum is complete and stored in ctr2.
; now just compare ctr2 to the message's checksum
	movf	ctr2, w
	cpfseq	CAN_msg_data3
	bra		chk64_error				; checksum mismatch
; If here, the checksum is valid.  set prev_desc and prev_addr and return the packet
	movff	CAN_msg_data0, prev_reprog_desc
	movff	CAN_msg_data1, prev_reprog_addrH
	movff	CAN_msg_data2, prev_reprog_addrL
	call	confirm_reprog_pkt
	return

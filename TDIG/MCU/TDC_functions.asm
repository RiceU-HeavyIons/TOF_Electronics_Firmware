;***********************************************************************
; mid-level subroutines that get called above go here:
;***********************************************************************

new_control
; this function applies whatever word is in control (5 bytes) to whichever
; TDC is currently selected for JTAG control.
	take_JTAG_control
	movlw	0x09	; 01001 = reset instruction
	movwf	inst	; inst = 01001
	call 	IRScan	; shift inst into JTAG instruction register
	call	stall
	call	stall
	movlw	0x05	; control word is 5 bytes
	movwf	dsize
	; put control word into DRScan out
	lfsr	FSR0, control
	clrf	write_to
	call	DRScan
	reset_TAP
	allow_byteblaster
	return

; This subroutine checks JTAG ID_CODE.  The instruction for this is 10001 using even parity.
; This subroutine assumes TAP controller is in T-L-R to start, and leaves the TAP controller
; in T-L-R when finished.
;ID_Code
;	take_JTAG_control
;	movlw	0x11	; 10001 = ID_CODE instruction
;	movwf	inst	; inst = 10001
;	call	IRScan	; shift inst into JTAG instruction register
;	movlw	0x04	; ID_CODE is 4 bytes
;	movwf	dsize
;;	lfsr	FSR0, compare_ID
;	; ID_Code is not saved currently.  If you want it, allocate space for it
;	; and put a pointer to where you want the MSB in write_to before calling DRScan
;	clrf	write_to
;	call	DRScan	; Read back ID_Code
;	reset_TAP
;	allow_byteblaster
;	return
;
get_status
	take_JTAG_control
	movlw	0x0A				; 01010 = 0x0A = status instruction
	movwf	inst
	call	IRScan
	movlw	0x08				; status is 8 bytes (62 bits)
	movwf	dsize
	lfsr	FSR1, tdc_status
	setf	write_to
	lfsr	FSR0, config1_data	; FSR0 -> some data (we don't care!) to shove
								; into TDI, just so we can get what we want out of TDO
	call	DRScan				; on return, status should be held in data memory
	reset_TAP
	allow_byteblaster			; TDC2 in CAN messages (see CAN HLP spec, get_status)
	return

get_data_word
	; DATA WORD IS 33 bits!  dataword[0] == readout FIFO status (0 -> empty FIFO)
	; using datagrab, the 32 bit data word is stored in memory 0x82-0x85.
	; datagrab may do something with FIFO status if desired.

	; using datagrab and calling get_data_word in a loop, the micro can read over
	; 14,000 data words per second.  In the final system, time to decode CAN
	; instructions will have to be figured in, but it is likely that 10kwords can 
	; be achieved.  Further optimizations are possible including unravelling the loop
	; inside datagrab, and skipping the IRscan and the run-test/idle state for 
	; multiple consecutive reads.
	take_JTAG_control
	movlw	0x17	; 10111 = 0x17 = readout instruction
	movwf	inst
	call	IRScan
	movlw	0x04	; data word is 4 bytes
	movwf	dsize
	call	datagrab
	reset_TAP
	allow_byteblaster
	return	

config_basic
	take_JTAG_control
	reset_TAP
	movlw	0x18			; 11000 = setup instruction
	movwf	inst
	call	IRScan
	call	stall
	call	set_config_pointer
	movlw	0x51			
	movwf	dsize				; shift in 0x51 bytes
	clrf	write_to
	call	DRScan
	; now RE-scan and compare bytes
	movlw	0x18
	movwf	inst
	call	IRScan
	call	stall
	call	set_config_pointer
	movlw	0x51
	movwf	dsize
	lfsr	FSR1, config_temp
	setf	write_to
	call	DRScan
	; TDC configured (again), returned value in config_temp
	call	setup_scanned_config
	call	set_config_pointer
	lfsr	FSR1, config_temp
	clrf	ctr
test_another_byte
	movf	POSTINC0,0			; WREG = byte of desired config array
	cpfseq	POSTINC1			; compare byte of desired with byte of returned. skip next if equal
	LED_ON						; turn on MCU LED 4 if there is a configuration error
	incf	ctr
	movlw	0x51
	subwf	ctr,0
	bnz		test_another_byte
; 9/4/04: Add a do_reset here, to match JAM code
	movlw	0x09				; 0x01001 = control instruction
	movwf	inst
	call	IRScan				; IRScan 01001 control instruction
	call	stall				; pause 100us
	; move global_reset from program memory into control registers
	tcopy	global_reset, control, 0x05
	; control now holds global_reset.  point FSR0 to control
	lfsr	FSR0, control
	movlw	0x05
	movwf	dsize
	clrf	write_to
	call	DRScan				; DRScan global_reset
	call	stall				; pause 100us
	tcopy	enable_all, control, 0x05
	lfsr	FSR0, control
	movlw	0x05
	movwf	dsize
	clrf	write_to
	call	DRScan
	call	stall
	reset_TAP
	allow_byteblaster
	return

set_config_pointer
; This function is called by config_basic and config_parity.  
; It simply sets FSR0 to point at the base of the configuration array 
; for the TDC currently indicated by JTAG_status
	movf	JTAG_status,0	; WREG = JTAG_status
	andlw	0x03			; mask out all but the lower 2 bits
	sublw	TDC1			; WREG = JTAG_status - TDC1
	bnz		try_config_TDC2
	lfsr	FSR0, config1_data
	return
try_config_TDC2
	ifdef	TDC2
	movf	JTAG_status,0
	andlw	0x03
	sublw	TDC2
	bnz		try_config_TDC3
	lfsr	FSR0, config2_data
	return
	endif
try_config_TDC3
	ifdef	TDC3
	movf	JTAG_status,0
	andlw	0x03
	sublw	TDC3
	bnz		must_be_config_TDC4
	lfsr	FSR0,config3_data
	return
	endif
must_be_config_TDC4
	ifdef	TDC4
	lfsr	FSR0, config4_data	; then use config4
	endif
; Should have a method to handle an error if TDC_pointer is invalid!
	return

lock
	take_JTAG_control
	movlw	0x09		; 01001 = load control data inst
	movwf	inst
	call	IRScan		; IRScan 01001
	call	stall		; stall for 100us
	; move reset_all from program memory into control registers
	tcopy	reset_all, control, 0x05
	; control now holds reset_all.  point FSR0 to control
	lfsr	FSR0, control
	movlw	0x05
	movwf	dsize
	clrf	write_to
	call	DRScan		; DRScan reset_all
	call	stall
	; move lock_pll from program memory into control registers
	tcopy	lock_pll, control, 0x05
	; control now holds lock_pll.  point FSR0 to control
	lfsr	FSR0, control
	movlw	0x05
	movwf	dsize
	clrf	write_to
	call	DRScan		; DRScan lock_pll
	movlw	0x96
	movwf	ctr2		; ctr2 = 150 (decimal)
	call	longstall 	; stall for 15ms
	; move lock_dll from program memory into control registers
	tcopy	lock_dll, control, 0x05
	; control now holds lock_dll.  point FSR0 to control
	lfsr	FSR0, control
	movlw	0x05
	movwf	dsize
	clrf	write_to
	call	DRScan		; DRScan lock_dll
	movlw	0x96
	movwf	ctr2		; ctr2 = 150
	call	longstall
	; move global_reset from program memory into control registers
	tcopy	global_reset, control, 0x05
	; control now holds global_reset.  point FSR0 to control
	lfsr	FSR0, control
	movlw	0x05
	movwf	dsize
	clrf	write_to	
	call	DRScan		; DRScan global_reset
	call	stall
	; move enable_all from program memory into control registers
	tcopy	enable_all, control, 0x05
	; control now holds enable_all.  point FSR0 to control
	lfsr	FSR0, control
	movlw	0x05
	movwf	dsize
	clrf	write_to
	call	DRScan		; DRScan enable_all
	call	stall	
	reset_TAP
	allow_byteblaster
	return

#define TDC1	0x00	; Comment lines corresponding to missing TDC's
#define TDC2	0x01	; 
#define TDC3	0x02	; 	
#define TDC4	0x03	; 

;#define HLPnodeID	0x20	; Node ID = 1

; copy table to RAM
tcopy	macro	t_address, r_address, tCount
	local tLoop
   		movlw	UPPER(t_address)
   		movwf	TBLPTRU
   		movlw	HIGH(t_address)
   		movwf	TBLPTRH
   		movlw	LOW(t_address)
   		movwf	TBLPTRL
   		lfsr	FSR0, r_address
   		movlw	tCount
		movwf	ctr
tLoop
		tblrd*+
		movff	TABLAT, POSTINC0
		decfsz	ctr
		bra		tLoop
	endm

LED_ON macro
	bsf	PORTC,0
	endm

LED_OFF macro
	bcf	PORTC,0
	endm

str_tck	macro
	set_TCK
	clr_TCK
	endm

set_TMS macro
	bsf		PORTH,6
	endm
clr_TMS macro
	bcf		PORTH,6
	endm

set_TCK macro
	bsf		PORTH,7
	endm
clr_TCK macro
	bcf		PORTH,7
	endm

set_TDI macro
	bsf		PORTH,5
	endm
clr_TDI	macro
	bcf		PORTH,5
	endm

grab_TDO_bit macro
	movf	PORTH,0		; WREG = PORTH
	andlw	mask4		; WREG = TDO (in bit 4)
	endm

reset_TAP	macro
	set_TMS
	str_tck
	str_tck
	str_tck
	str_tck
	str_tck
	endm

allow_byteblaster	macro
	movlw	0x03				; address for JTAG status in PLD
	movwf	write_to
	clrf	WREG
	call	write_byte_PLD
	endm

take_JTAG_control	macro
	bsf		JTAG_status, 2
	movlw	0x03				; address for JTAG status in PLD
	movwf	write_to
	movf	JTAG_status, 0		; move JTAG status to WREG for output'
	call	write_byte_PLD
	endm

	IFDEF TDC1				; If we have a TDC1 on this board, then:
control_TDC1	macro
	clr_TCK
	set_TMS
	clr_TDI
	movlw	0x03
	movwf	write_to		; addr = 0x3, PLD JTAG mux register
	movlw	0x04			; bit 2 -> take JTAG control
							; [1,0] = 00 -> TDC1
	movwf	JTAG_status		; this is for local information ONLY
	call	write_byte_PLD
	endm
	endif

	IFDEF TDC2
control_TDC2	macro
	clr_TCK
	set_TMS
	clr_TDI
	movlw	0x03
	movwf	write_to		; addr = 0x3, PLD JTAG mux register
	movlw	0x05			; bit 2 -> take JTAG control
							; [1,0] = 01 -> TDC2
	movwf	JTAG_status		; this is for local information ONLY
	call	write_byte_PLD
	endm
	endif

	IFDEF TDC3
control_TDC3	macro
	clr_TCK
	set_TMS
	clr_TDI
	movlw	0x03
	movwf	write_to		; addr = 0x3, PLD JTAG mux register
	movlw	0x06			; bit 2 -> take JTAG control
							; [1,0] = 10 -> TDC3
	movwf	JTAG_status		; this is for local information ONLY
	call	write_byte_PLD
	endm
	endif

	IFDEF TDC4
control_TDC4	macro
	clr_TCK
	set_TMS
	clr_TDI
	movlw	0x03
	movwf	write_to		; addr = 0x3, PLD JTAG mux register
	movlw	0x07			; bit 2 -> take JTAG control
							; [1,0] = 11 -> TDC4
	movwf	JTAG_status		; this is for local information ONLY
	call	write_byte_PLD
	endm
	endif

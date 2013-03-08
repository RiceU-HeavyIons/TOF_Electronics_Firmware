#define HLPnodeID	0x20	; Node ID = 1
#define	system_CAN	0x01
#define tray_CAN	0x02

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
	bsf	PORTA,4
	endm

LED_OFF macro
	bcf	PORTA,4
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
;	bsf		PORTB,4
	endm

take_JTAG_control	macro
;	bcf		PORTB,4	
	endm

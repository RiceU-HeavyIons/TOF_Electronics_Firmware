xmit_SPI_DAC	macro
	bsf		SSPSTAT,6		; data TX'd on falling clock edge
	call	SPIMPolPut
	call	SPI_Wait
	endm

select_DAC	macro
	bcf		LATB,3
	bsf		LATA,6
	endm

clear_FS	macro
	bcf		LATA,6
	endm

deselect_DAC	macro
	bsf		LATA,6
	bsf		LATB,3
	endm

select_2515	macro
	bcf		SSPSTAT,6		; data TX'd on rising clock edge
	bcf		LATC,6
	endm

deselect_2515	macro
	bsf		LATC,6
	endm

xmit_SPI	macro
	call	SPIMPolPut
	call	SPI_Wait
	call	SPIMPolGet
	endm

mwrite_2515 macro addr, byte
	select_2515
	movlw	0x02		; write instruction
	xmit_SPI
	movlw	addr		; send ADDR over SPI
	xmit_SPI
	movlw	byte		; send data over SPI, load into addr
	xmit_SPI
	deselect_2515
	endm

filter_write_2515	macro	addr
	select_2515
	movlw	0x02
	xmit_SPI
	movlw	addr
	xmit_SPI
	movf	tray_posn, w
	xmit_SPI
	deselect_2515
	endm

read_2515	macro addr
	; reads specified address in 2515.  Result left in WREG.
	select_2515
	movlw	0x03		; read
	xmit_SPI
	movlw	addr		; addr to read
	xmit_SPI
	movlw	0x00		; dummy data
	xmit_SPI
	deselect_2515
	endm

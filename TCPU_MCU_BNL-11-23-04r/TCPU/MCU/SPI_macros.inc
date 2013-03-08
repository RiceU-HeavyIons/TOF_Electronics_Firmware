select_2515	macro
	bcf		SSPSTAT,6		; data TX'd on rising clock edge
;	movlw	0x01
;	cpfseq	CAN_net
;	bra		$+4
;	bcf		LATB, 1
;	movlw	0x02
;	cpfseq	CAN_net
;	bra		$+4
	bcf		LATB, 2
	endm

deselect_2515	macro
	bsf		LATB,2
	bsf		LATB,1
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

initialize_DAC
; sets up DAC control word.  For now, reference voltage = 2.048V
	select_DAC
	clear_FS		; FS = 0.  Falling edge tells DAC here comes data
	movlw	0xD0	; first byte of control word change, bit #6 = 1 -> fast mode
	xmit_SPI_DAC
	movlw	0x01	; second byte of control word: [1:0] = 01 -> 1.024V reference
	xmit_SPI_DAC
	deselect_DAC	; control word is now written.
	return

new_DAC_value
; accepts a two-byte DAC control word and programs that word into the DAC
; inputs:  write_to = Upper byte
;				ctr = Lower byte
	select_DAC
	clear_FS			; FS = 0
	movf	write_to,0	; WREG = upper byte
	xmit_SPI_DAC		; transmit upper byte
	movf	ctr,0		; WREG = lower byte
	xmit_SPI_DAC		; sends WREG (now lower byte) to DAC
	deselect_DAC
	return

write_2515
	; accepts a source address, a destination address and writes # of bytes
	; to destination, starting at source
	;
	; inputs: write_to - destination address
	; 			  FSR2 - source address (start)
	; 		       ctr - # of bytes to send
	select_2515
	movlw	0x02		; write instruction
	xmit_SPI
	movf	write_to,0	; WREG = destination addr
	xmit_SPI
SPI_another_byte
	movf	POSTINC2,0	; byte to write
	xmit_SPI
	decfsz	ctr					; ctr--; if ctr>0
	bra		SPI_another_byte	; then SPI another byte
	deselect_2515				; else done
	return

write_byte_2515
	; accepts a data byte and a destination address.
	; write data byte to destination address.
	; inputs: write_to - destination address
	;			 dsize - byte to write
	select_2515
	movlw	0x02		; write instruction
	xmit_SPI
	movf	write_to,0	; WREG = destination address
	xmit_SPI
	movf	dsize,0		; WREG = byte to write
	xmit_SPI
	deselect_2515
	return

SPI_Wait:                                   ; Wait till Data is Received
	call    SPIMPolIsDataReady              ; WREG == 0 when data is received
	tstfsz  WREG                            ;
	bra     SPI_Wait                        ;
	return 

SPI_init
	call	SPIMPolInit
	bsf		RCON,IPEN		; ???

	bcf		SSPCON1, SSPEN	; disable SPI pins for reconfigure
	bsf		SSPCON1,4		; clock idle = 1
	bcf		SSPSTAT,7		; input data sampled at middle of data output time	
	bcf		SSPSTAT,6		; data TX'd on rising clock edge
	bsf		SSPCON1, SSPEN	; re-enable SPI output
	return

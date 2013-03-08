;**********************************************************************************
; housekeeping functions, etc:
;**********************************************************************************

longstall	
	call	stall	; stall for 100us
	decfsz	ctr2
	bra		$-6
	nop
	return

stall    ; microchip clock is 20MHz
	; each loop consists of increment (1 instruction cycle), test (1 cycle), bra (2 cycles)
	; that's 4 instruction cycles = 16 clock ticks. each clock cycle is 50ns
	; 16 * 50ns = 800ns.  the loop runs 128 times.  total stall is about 100us
	; stall time verified with logic analyzer 8/26/03
	clrf	ctr
	incf	ctr
	btfss	ctr,7
	bra		$-4
	return

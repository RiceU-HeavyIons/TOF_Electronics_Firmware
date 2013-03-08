;*****************************************************************************
; Low level DRScan and IRScan follow:
;*****************************************************************************

; this subroutine performs JTAG DR-Scan.  It uses the value in dsize to determine how many
; bits to shift in/out.  It assumes the TAP controller is in Run-Test/Idle state, and
; returns to that state when finished.

; results are unpredictable if dsize = 0 when called! (most likely it will DRScan 2^8 bits)

; before calling DRScan, set FSR0 to the memory location of the MSB of the data 
; you want to shift

; If you wish to KEEP the data scanned through TDO, set write_to to 0xFF and set
; FSR1 to the address of the desired location of the MSB, and the data will be stored
; from that address through following addresses (just like config data is stored).  
; Set write_to to 0 to throw out inbound data (otherwise data pointed at by FSR1 WILL
; be overwritten)

DRScan
	clr_TMS
	str_tck				; TAP controller to Run-Test-Idle
	set_TMS				; TMS = 1
	str_tck				; TAP controller moves to Select-DR-Scan
	clr_TMS				; TMS = 0
	str_tck				; TAP controller moves to Capture-DR
	movf	dsize,0
	addwf	FSR0L		; FSR0 -> location of LSB of data +1 (outside data)
	btfsc	STATUS,C
	incf	FSR0H
	decf	FSR0L		; FSR0 -> location of LSB of data
	btfss	STATUS,C
	decf	FSR0H

	addwf	FSR1L
	btfsc	STATUS,C
	incf	FSR1H
	decf	FSR1L
	btfss	STATUS,C
	decf	FSR1H,0

	; make a loop that increments through memory words one at a time.
	; each time that loop runs, 8 iterations of moving one bit at a time
	; into TDObyte.  Then if desired, dump TDObyte to memory storage.

	; DRScan does not capture the bit on TDI upon the transition to Shift-DR
	; Therefore, we have to move TAP into Shift-DR before starting the loop:
	
	; 9/6/04: I'm not sure that's true.  JAM and byteblaster appear to 
	; do just that (shift in first bit on transition to Shift-DR.
	; However, everything APPEARS to work ok like this.

	set_TCK	; TAP controller moves to Shift-DR

grabTDObyte
	clrf	TDObyte
; now grab from memory the next byte to shove into TDI
; then go through that byte one bit at a time (See IRScan for help)

; bit 0:
; falling TCK -> valid TDO
; capture TDO:
	clr_TCK			; TDO now valid, capture it.
	grab_TDO_bit	; WREG = TDO (in bit 4)
	rlncf	WREG	; WREG = TDO (in bit 5)
	rlncf	WREG	; WREG = TDO (in bit 6)
	rlncf	WREG	; WREG = TDO (in bit 7)
	rlncf	WREG	; WREG = TDO (in bit 0)
	iorwf	TDObyte	; TDObyte: LSB now correct

; set TDI:
	movf	INDF0,0	; WREG = a byte of data to put on TDO
	andlw	mask0	; WREG = WREG & 0x01
	clr_TDI			; TDI = 0
	bz		$+4
	set_TDI			; TDI = 1 as long as WREG !=0
; clock in TDI:
	set_TCK			; TCK = 1
					; Next TDI is shifted in
; bit 1:
; capture TDO
	clr_TCK			; TCK = 0, new TDO valid
	grab_TDO_bit	; WREG = TDO (in bit 4)
	rrncf	WREG	; WREG = TDO (in bit 3)
	rrncf	WREG	; WREG = TDO (in bit 2)
	rrncf	WREG	; WREG = TDO (in bit 1)
	iorwf	TDObyte	; TDObyte = TDObyte | WREG
					; TDObyte should now be 0000 00VV
					; V = valid TDO bit
; set TDI:
	movf	INDF0,0	; WREG = a byte of data to put on TDO
	andlw	mask1	; WREG = WREG & 0x02
	clr_TDI			; TDI = 0
	bz		$+4
	set_TDI			; TDI = 1 as long as WREG !=0
; clock in TDI
	set_TCK			; TCK = 1
; bit 2:
; capture TDO:
	clr_TCK
	grab_TDO_bit	; WREG = TDO (in bit 4)
	rrncf	WREG	; WREG = TDO (in bit 3)
	rrncf	WREG	; WREG = TDO (in bit 2)
	iorwf	TDObyte
; set TDI:
	movf	INDF0,0	; WREG = a byte of data to put on TDO
	andlw	mask2	; WREG = WREG & 0x04
	clr_TDI	; TDI = 0
	bz		$+4
	set_TDI	; TDI = 1 as long as WREG !=0
; clock in TDI:
	set_TCK
; bit 3:
; capture TDO:
	clr_TCK
	grab_TDO_bit	; WREG = TDO (in bit 4)
	rrncf	WREG	; WREG = TDO (in bit 3)
	iorwf	TDObyte
; set TDI:
	movf	INDF0,0	; WREG = a byte of data to put on TDO
	andlw	mask3	; WREG = WREG & 0x08
	clr_TDI	; TDI = 0
	bz		$+4
	set_TDI	; TDI = 1 as long as WREG !=0
; clock in TDI:
	set_TCK
; bit 4:
; capture TDO:
	clr_TCK
	grab_TDO_bit	; WREG = TDO (in bit 4)
	iorwf	TDObyte
; set TDI:
	movf	INDF0,0	; WREG = a byte of data to put on TDO
	andlw	mask4	; WREG = WREG & 0x10
	clr_TDI	; TDI = 0
	bz		$+4
	set_TDI	; TDI = 1 as long as WREG !=0
; clock in TDI:
	set_TCK
; bit 5:
; capture TDO:
	clr_TCK
	grab_TDO_bit	; WREG = TDO (in bit 4)
	rlncf	WREG	; WREG = TDO (in bit 5)
	iorwf	TDObyte
; set TDI:
	movf	INDF0,0	; WREG = a byte of data to put on TDO
	andlw	mask5	; WREG = WREG & 0x20
	clr_TDI	; TDI = 0
	bz		$+4
	set_TDI	; TDI = 1 as long as WREG !=0
; clock in TDI:
	set_TCK
; bit 6:
; capture TDO:
	clr_TCK
	grab_TDO_bit	; WREG = TDO (in bit 4)
	rlncf	WREG	; WREG = TDO (in bit 5)
	rlncf	WREG	; WREG = TDO (in bit 6)
	iorwf	TDObyte
; set TDI:
	movf	INDF0,0	; WREG = a byte of data to put on TDO
	andlw	mask6	; WREG = WREG & 0x40
	clr_TDI	; TDI = 0
	bz		$+4
	set_TDI	; TDI = 1 as long as WREG !=0
; clock in TDI:
	set_TCK
; bit 7:
; capture TDO:
	clr_TCK
	grab_TDO_bit				; WREG = TDO (in bit 4)
	rlncf	WREG				; WREG = TDO (in bit 5)
	rlncf	WREG				; WREG = TDO (in bit 6)
	rlncf	WREG				; WREG = TDO (in bit 7)
	iorwf	TDObyte				; TDObyte now holds one word of TDO data
; if we're storing TDO (i.e. write_to != 0), write TDObyte to INDF1
	clrf	WREG				; WREG = 0
	cpfseq	write_to			; if write_to = 0, skip next instruction
	movff	TDObyte, POSTDEC1	; INDF1 = TDObyte, INDF1--
; don't forget to decrement FSR0 when you grab this bit
; set TDI:
	movf	POSTDEC0,0			; WREG = a byte of data to put on TDO, FSR0--
	andlw	mask7				; WREG = WREG & 0x80
	clr_TDI	; TDI = 0
	bz		$+4
	set_TDI	; TDI = 1 as long as WREG !=0
; We have to set TMS *BEFORE* the next rising edge, so exit the loop here if finished. 
	dcfsnz	dsize				; if dsize = 0, we're done grabbing bits
	bra		donegrabbing		; so go grab the last bit and exit DRScan
; clock in TDI (end of bit 7 of a NON FINAL BYTE):
	set_TCK
	bra		grabTDObyte			; else grab another word of TDO
; Grab the last bit and exit:
donegrabbing
	set_TMS	; TMS = 1
; Next tick leaves Shift-DR
	str_tck						; TCK = 1, 0. TAP -> Exit1-DR
	clr_TMS						; TMS = 0
	str_tck						; TAP to Pause-DR
	set_TMS						; TMS = 1
	clr_TDI						; TDI = 0
	str_tck						; TAP to Exit2-DR
	str_tck						; TAP to Update-DR
	clr_TMS						; TMS = 0
	str_tck						; TAP to Run-test/Idle
	return

PLD_IRscan
; This function performs IRScan on the cyclone PLD, which uses 10-bit JTAG instructions
;
; Inputs:
;					inst	:	8 least significant bits of JTAG instruction
;					dsize	:	holds 2 MSB's of JTAG instruction in dsize's LSB's
; it will also return the TAP controller to the Run-Test/Idle 
; state when finished.  It moves the bits onto TDI LSB-first, and assumes a 10-bit 
; instruction word (including parity)
	reset_TAP
	clr_TMS
	str_tck			; TAP controller to Run-Test-Idle
	set_TMS
	str_tck			; TAP controller to Select-DR-Scan
	str_tck			; TAP controller to Select-IR-Scan
	clr_TMS
	str_tck			; TAP controller to Capture-IR
	str_tck			; TAP controller to Shift-IR
; bit 0
	movf	inst,0
	andlw	mask0
	clr_TDI
	bz		$+4
	set_TDI			; TDI = 1 as long as WREG[0] != 0
	str_tck
; bit 1
	movf	inst,0
	andlw	mask1
	clr_TDI
	bz		$+4
	set_TDI
	str_tck
; bit 2
	movf	inst,0
	andlw	mask2
	clr_TDI
	bz		$+4
	set_TDI
	str_tck
; bit 3
	movf	inst,0
	andlw	mask3
	clr_TDI
	bz		$+4
	set_TDI
	str_tck
; bit 4
	movf	inst,0
	andlw	mask4
	clr_TDI
	bz		$+4
	set_TDI
	str_tck
; bit 5
	movf	inst,0
	andlw	mask5
	clr_TDI
	bz		$+4
	set_TDI
	str_tck
; bit 6
	movf	inst,0
	andlw	mask6
	clr_TDI
	bz		$+4
	set_TDI
	str_tck
; bit 7
	movf	inst,0
	andlw	mask7
	clr_TDI
	bz		$+4
	set_TDI
	str_tck
; bit 8
	movf	dsize,0
	andlw	mask0
	clr_TDI
	bz		$+4
	set_TDI
	str_tck
; bit 9
	movf	dsize,0
	andlw	mask1
	clr_TDI
	bz		$+4
	set_TDI				; final bit on TDI
	set_TMS
	str_tck				; TAP to Exit1-IR
	clr_TMS
	str_tck				; TAP to Pause-IR
	set_TMS
	str_tck				; TAP to Exit2-IR
	str_tck				; TAP to Update-IR
	clr_TMS
	str_tck				; TAP to Run-Test/Idle
	return

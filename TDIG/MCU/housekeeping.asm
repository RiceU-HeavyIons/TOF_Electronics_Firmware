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

set_TDC_ID
; This routine sets the TDC ID stored in the RAM copy of the configuration array.
; It calculates an appropriate ID based on the tray position and TDC number (1-4) on the board.
; Board #0 will have TDC's 0-3,
; Board #1 will have TDC's 4-7,
; Board #2 will have TDC's 8-B,
; Board #3 will have TDC's C-F,
; Board #4 will have TDC's 0-3, etc
	movf	tray_posn, 0			; WREG = ppp0 0000, tray position
	rrcf	WREG					
	rrcf	WREG					; WREG now contains  00pp p000
	movwf	ctr						; store 00pp p000 in ctr temporarily
	movf	JTAG_status, 0			; WREG = 0000 0sjj
									; s = JTAG source select
									; jj = TDC pointer
	rlcf	WREG					; WREG now contains  0000 sjj0
	bcf		WREG, 3					; WREG now contains  0000 0jj0
	iorwf	ctr, w					; WREG now conatins  00pp pjj0
	andlw	0x1E					; WREG now contains  000p pjj0, which is TDC ID
	movwf	ctr						; ctr now stores 000p pjj0, TDC ID
	call	set_config_pointer		; return with FSR0 pointed at the current TDC
	movlw	0x4B					; offset into config array where ID is stored
	movf	PLUSW0, w				; WREG = byte #75 of config_array
	andlw	0xE1					; WREG = bbb0 000b where b is old byte #75, TDC ID = 0
	iorwf	ctr, w					; WREG = bbbp pjjb
	movwf	ctr						; ctr = bbbp pjjb
	movlw	0x4B
	movff	ctr, PLUSW0				; config_array byte #75 gets new ID
	return	

config_parity
; this subroutine sets the parity bit in a config_data array according to the setting
; of JTAG_status
; config_parity should be called once after each time config_data is updated.
	call	set_config_pointer
	clrf	ctr
	clrf	ctr2
byteloope
	movf	POSTINC0,0		; WREG = next byte of config_data		
; first assume parity is even
bitloope
	incf	ctr
	rlcf	WREG,0
	btfsc	STATUS,C		; skip the next instruction if carry bit is clear
	bra		enterbitloopo
enterbitloope
	btfss	ctr,3
	bra		bitloope	; if ctr != 0x08, loop again
	clrf	ctr			; ctr = 0 (for next 8 bits)
	incf	ctr2		; ctr2++ (one more byte completed)
	movf	ctr2,0		; WREG = ctr2 (number of completed bytes)
	sublw	0x51		; WREG = ctr2 - 0x51
	bnz		byteloope	; go grab the next byte
	return				; if code gets here, it's finished and parity is already even
byteloopo
	movf	POSTINC0,0
bitloopo
	incf	ctr
	rlcf	WREG,0		
	btfsc	STATUS,C
	bra		enterbitloope
enterbitloopo
	btfss	ctr,3
	bra		bitloopo	
	clrf	ctr
	incf	ctr2
	movf	ctr2,0
	sublw	0x51
	bnz		byteloopo
; if code gets here, it's finished and parity is odd, so set parity bit
	call	set_config_pointer
	bsf		INDF0,7
	return

setup_scanned_config
; this function shifts the read-back configuration one bit to the left
; to align it with the data stored in config1_data and config2_data
	lfsr	FSR1, config_temp
	movlw	0x50
	addwf	FSR1L
	btfsc	STATUS,C
	bsf		FSR1H,0				; FSR1 -> LSB of config_temp
	addlw	0x00				; just to clear the CARRY bit
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	rlcf	POSTDEC1
	return

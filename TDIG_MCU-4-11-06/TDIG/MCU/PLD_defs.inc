; MCU_PLD_CTRL[0] - PORTC,7 - reset
; MCU_PLD_CTRL[1] - PORTB,4 - !R/W (data direction)
; MCU_PLD_CTRL[2] - PORTG,0 - addr[0]
; MCU_PLD_CTRL[3] - PORTG,3 - addr[1]
; MCU_PLD_CTRL[4] - PORTG,4 - addr[2]
;
; MCU_INT[0] - PORTB,0 - data strobe
; MCU_INT[1] - PORTB,1 - FIFO_EMPTY
;

PLD_data			equ	PORTF	; Bi-directional PLD data byte
PLD_data_port_dir	equ	TRISF

PLD_addr		equ	PORTG	; PLD register address for R/W ops
PLD_addr0		equ	0x00
PLD_addr1		equ	0x03
PLD_addr2		equ	0x04

PLD_ctrl		equ	PORTB	; includes data direction, strobe and fifo_empty
FIFO_empty		equ	0x01	; bit in PLD_ctrl set by PLD, indicates data exists
PLD_data_strb	equ	0x00
PLD_data_dir	equ	0x04

PLD_reset_port	equ	PORTC
PLD_reset		equ	0x07

tell_PLD_to_read	macro
	bsf		PLD_ctrl, PLD_data_dir
	endm

tell_PLD_to_write	macro
	bcf		PLD_ctrl, PLD_data_dir
	endm

reset_PLD_FIFO	macro
	bsf		PLD_reset_port, PLD_reset
	nop
	nop
	bcf		PLD_reset_port, PLD_reset
	endm

set_RX_ready	macro
	bsf		PLD_ctrl, RX_ready
	endm

clear_RX_ready	macro
	bcf		PLD_ctrl, RX_ready
	endm

control_PLD_JTAG	macro
	bsf		PORTB,2
	endm

allow_BB_PLD	macro	
	bcf		PORTB,2
	endm

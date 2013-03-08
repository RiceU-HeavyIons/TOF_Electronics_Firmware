; MCU_PLD_CTRL[0] - PORTG,0 - addr[0]
; MCU_PLD_CTRL[1] - PORTG,3 - addr[1]
; MCU_PLD_CTRL[2] - PORTG,4 - addr[2]
; MCU_PLD_CTRL[3] - PORTC,0 - !R/W (data direction)

; PLD_INT 	- PORTB,0 - data strobe
; PLD_RUnLU	- PORTA,1 - FIFO_EMPTY

PLD_data			equ	PORTF	; Bi-directional PLD data byte
PLD_data_port_dir	equ	TRISF

PLD_addr		equ	PORTG	; PLD register address for R/W ops
PLD_addr0		equ	0x00
PLD_addr1		equ	0x03
PLD_addr2		equ	0x04

PLD_strb_port	equ	PORTB	; includes data direction, strobe and fifo_empty
PLD_data_strb	equ	0x00

FIFO_empty_port	equ	PORTA
FIFO_empty		equ	0x01	; bit in PLD_ctrl set by PLD, indicates data exists

PLD_data_dir_port	equ	PORTC
PLD_data_dir		equ	0x00

tell_PLD_to_read	macro
	bsf		PLD_data_dir_port, PLD_data_dir
	endm

tell_PLD_to_write	macro
	bcf		PLD_data_dir_port, PLD_data_dir
	endm

reset_PLD_FIFO	macro
	movlw	0x06
	movwf	write_to
	call	write_byte_PLD
	endm

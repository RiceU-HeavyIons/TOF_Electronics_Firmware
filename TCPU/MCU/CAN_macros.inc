get_system_msg	macro
	movlw	system_CAN
	movwf	CAN_net
	call	get_msg
	endm

get_tray_msg	macro
	movlw	tray_CAN
	movwf	CAN_net
	call	get_msg
	endm

handle_system_msg	macro
	movlw	system_CAN
	movwf	CAN_net
	call	handle_CAN_msg
	endm

handle_tray_msg	macro
	movlw	tray_CAN
	movwf	CAN_net
	call	handle_CAN_msg
	endm

filter_write_2515	macro	addr
	select_2515
	movlw	0x02
	xmit_SPI
	movlw	addr
	xmit_SPI
	movlw	HLPnodeID
	xmit_SPI
	deselect_2515
	endm

#DEFINE CODE_BASE 0x0000

; file: TDIG-B.asm

;******************************************************************************
;    Date:          9/13/04                                                   *
;    File Version:  2.0                                                       *
;                                                                             *
;    Author:		Justin Kennington                                     *
;    Company:       Blue Sky Electronics                                      *
;                                                                             * 
;******************************************************************************

;******************************************************************************
;                                                                             *
;    Files required:         P18F8720.INC                                     *
;                            18f8720.lkr                                      *
;                            MCU_config.asm                                   *
;                                                                             *
;******************************************************************************

	LIST P=18F8720, F=INHX32	; directive to define processor and file format
	#include <P18F8720.INC>		; processor specific variable definitions
	#include "SPI_macros.inc"
	#include "TDIG_macros.inc"
	#include "PLD_defs.inc"
	#include "SPIMPol.inc"
;	#include "Flash_macros.inc"

;******************************************************************************
; Configuration bits
	;;  This is the old way of defining the configuration bits:
		
; The __CONFIG directive defines configuration data within the .ASM file.
; The labels following the directive are defined in the P18F8720.INC file.
; The PIC18FXX20 Data Sheet explains the functions of the configuration bits.

;	__CONFIG	_CONFIG1H, _OSCS_OFF_1H & _ECIO_OSC_1H		
;	__CONFIG	_CONFIG2L, _BOR_OFF_2L & _BORV_20_2L & _PWRT_OFF_2L
;	__CONFIG	_CONFIG2H, _WDT_OFF_2H & _WDTPS_128_2H
;	__CONFIG	_CONFIG3L, _XMC_MODE_3L
;	__CONFIG	_CONFIG3H, _CCP2MX_ON_3H
;	__CONFIG	_CONFIG4L, _STVR_OFF_4L & _LVP_OFF_4L & _DEBUG_ON_4L
;	__CONFIG	_CONFIG5L, _CP0_OFF_5L & _CP1_OFF_5L & _CP2_OFF_5L & _CP3_OFF_5L & _CP4_OFF_5L & _CP5_OFF_5L & _CP6_OFF_5L & _CP7_OFF_5L 
;	__CONFIG	_CONFIG5H, _CPB_OFF_5H & _CPD_OFF_5H
;	__CONFIG	_CONFIG6L, _WRT0_OFF_6L & _WRT1_OFF_6L & _WRT2_OFF_6L & _WRT3_OFF_6L & _WRT4_OFF_6L & _WRT5_OFF_6L & _WRT6_OFF_6L & _WRT7_OFF_6L 
;	__CONFIG	_CONFIG6H, _WRTC_OFF_6H & _WRTB_OFF_6H & _WRTD_OFF_6H
;	__CONFIG	_CONFIG7L, _EBTR0_OFF_7L & _EBTR1_OFF_7L & _EBTR2_OFF_7L & _EBTR3_OFF_7L &  _EBTR4_OFF_7L & _EBTR5_OFF_7L & _EBTR6_OFF_7L & _EBTR7_OFF_7L 
;	__CONFIG	_CONFIG7H, _EBTRB_OFF_7H

	;; This is the new way to define the configuration bits for 18F devices
	CONFIG	OSCS = OFF, OSC = ECIO		
	CONFIG	BOR = OFF, BORV = 25, PWRT = OFF
	CONFIG	WDT = OFF, WDTPS = 128
	CONFIG	MODE = EM
	CONFIG	CCP2MUX = ON
	CONFIG	STVR = OFF, LVP = OFF, DEBUG = OFF
	CONFIG	CP0 = OFF, CP1 = OFF, CP2 = OFF, CP3 = OFF, CP4 = OFF, CP5 = OFF, CP6 = OFF, CP7 = OFF 
	CONFIG	CPB = OFF, CPD = OFF
	CONFIG	WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF,  WRT4 = OFF,  WRT5 = OFF, WRT6 = OFF, WRT7 = OFF 
	CONFIG	WRTC = OFF, WRTB = OFF, WRTD = OFF
	CONFIG	EBTR0 = OFF, EBTR1 = OFF, EBTR2 = OFF, EBTR3 = OFF,  EBTR4 = OFF, EBTR5 = OFF, EBTR6 = OFF, EBTR7 = OFF 
	CONFIG	EBTRB = OFF

	CBLOCK 0x000
	ctr			; 0x000 counter used for loops
	ctr2		; 0x001	another counter
	inst		; 0x002 holds JTAG instructions before output
	dsize		; 0x003 holds the size of the DRScan register in bytes
				; (e.g. 4 for ID_Code, 81 for config bits)
	TDObyte		; 0x004 one byte of TDO input.  TDO comes in serially, is fed into TDObyte
				; and then TDOByte is written to memory and re-used.
	write_to	; 0x005	Destination address for writing to MCP 2515
	JTAG_status	; 0x006 Tells what TDC the MUX is pointed at
	prev_desc	; 0x007 previously received descriptor & CAN header
	prev_header	; 0x008 previously received CAN MsgID[10:3]

	prev_reprog_desc	; 0x009 previous reprogramming descriptor
	prev_reprog_addrH	; 0x00A upper 8 bits of previously received reprogramming address
	prev_reprog_addrL	; 0x00B lower 8 bits of previously received reprogramming address

	tdc_status:	  	0x08	; 0x00C - 0x013 holds TDC1 status bits
	dataword1:	  	0x04	; 0x014 - 0x017	holds a dataword from TDC1
	dataword2:	  	0x04	; 0x018 - 0x01B holds a dataword from TDC2
	control:	  	0x05	; 0x01C - 0x020
	CAN_msg_header			; 0x021 - 0x024
	CAN_msg_IDh				
	CAN_msg_IDl
	CAN_msg_DLC
	CAN_msg_data0			; 0x025 - 0x02C	
	CAN_msg_data1
	CAN_msg_data2
	CAN_msg_data3
	CAN_msg_data4
	CAN_msg_data5
	CAN_msg_data6
	CAN_msg_data7
	tray_posn				; 0x02D stores 3-bit tray position indicator which 
						; serves as CAN address.
						; 3 bits are left-justified
	flash_addrU				; 0x02E flash memory address upper bits
	flash_addrH				; 0x02F flash memory address high bits
	flash_addrL				; 0x030 flash memory address low bits
	flash_dataH				; 0x031 flash data high bits
	flash_dataL				; 0x032 flash data low bits
	PLD_word:       0x04	; 0x033 - 0x036 TDC data word from PLD
	config1_data: 	0x51	; 0x037 - 0x087
	config2_data: 	0x51	; 0x088 - 0x0D8
	config3_data:	0x51	; 0x0D9 - 0x129
	config4_data:	0x51	; 0x12A - 0x17A
	config_temp:	0x51	; 0x17B - 0x1CB cache for config data
	new_prog_data:	0x40	; 0x1CC - 0x20B	64 bytes of new program data
				; (temporary cache before writing to FLASH)
	endc

	constant	mask0 = 0x01
	constant	mask1 = 0x02
	constant	mask2 = 0x04
	constant	mask3 = 0x08
	constant	mask4 = 0x10
	constant	mask5 = 0x20
	constant	mask6 = 0x40
	constant	mask7 = 0x80

;******************************************************************************
; Reset vector
; This code will start executing when a reset occurs.

	org		(CODE_BASE + 0x0030)
	nop

;Start of main program
START

	call	config_micro		; set up MCU Pin I/O, other configuration

	movlw	0xFF
	movwf	ctr2
	call	longstall
	movlw	0xFF
	movwf	ctr2
	call	longstall
	movlw	0xFF
	movwf	ctr2
	call	longstall
	movlw	0xFF
	movwf	ctr2
	call	longstall

; Configure, Initialize, and flush PLD FIFOs:
	reset_PLD_FIFO

	LED_OFF
	call	SPI_init			; initialize the SPI bus
	call	get_tray_posn
	call	CAN_init			; Initialize CAN controller, return ready for I/O	
	
; Once CANbus is initialized, you should send a message saying "I've been reset!"
; This way, if the WDT trips and resets the MCU, the control network will know about
; it and can reapply configuration/firmware/whatever as necessary. 
; Here is that message:
	call	startup_message
	call	initialize_DAC

;**********************************************************************
; Move configuration strings into memory and configure TDC's
	ifdef	TDC1
	tcopy	p_config1, config1_data, 0x51
	control_TDC1
	call	set_TDC_ID
	call	config_parity
	call	config_basic
	call	stall
	call	lock
	endif
	ifdef	TDC2
	tcopy	p_config2, config2_data, 0x51
	nop
	control_TDC2
	call	set_TDC_ID
	call	config_parity
	call	config_basic
	call	stall
	call	lock
	endif
	ifdef	TDC3
	tcopy	p_config3, config3_data, 0x51
	control_TDC3
	call	set_TDC_ID
	call	config_parity
	call	config_basic
	call	stall
	call	lock
	endif
	ifdef	TDC4
	tcopy	p_config4, config4_data, 0x51
	control_TDC4
	call	set_TDC_ID
	call	config_parity
	call	config_basic
	call	lock
	endif
	
; Send global reset to all TDC's:
	movlw	0x04
	movwf	write_to
	setf	WREG
	call	write_byte_PLD
	movlw	0x04
	movwf	write_to
	clrf	WREG
	call	write_byte_PLD

;**********************************************************************
	
	nop
	setf	prev_desc		; this is an illegal prev_desc.  Forces a START to be issued first
	setf	prev_reprog_desc
	setf	prev_reprog_addrH
	setf	prev_reprog_addrL	; all illegal values to ensure START is issued first.

	movlw	0x97
	movwf	ctr			; This block gives DAC the value 0x597
	movlw	0x45			; which is 30mV (standard) threshold
	movwf	write_to
	call	new_DAC_value
		

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; Default (silent CANbus) execution loop here:
SILENT_LOOP
	call	get_msg
	sublw	0x00
	bnz		SILENT_LOOP
	call	handle_CAN_msg
	bra		SILENT_LOOP
; END DEFAULT EXECUTION LOOP

; Mode 1 (Read PLD) execution loop here:
PLD_LOOP
	call	check_for_PLD_data	; checks for PLD data and sends any that exists
check_CANbus_PLD
	call	get_msg
	sublw	0x00
	bnz		PLD_LOOP
	call	handle_CAN_msg
	bra		check_CANbus_PLD
; END MODE 1 EXECUTION LOOP

; Mode 2 (JTAG Readout) execution loop here:
JTAG_LOOP
	call	TDC_JTAG_data_to_PC
check_CANbus_JTAG
	call	get_msg
	sublw	0x00
	bnz		JTAG_LOOP
	call	handle_CAN_msg
	bra		check_CANbus_JTAG
; END MODE 2 EXECUTION LOOP

;------------------------------------------------------------------------------

	#include "MCU_config.asm"		; configuration routines for MCU
	#include "SPI_functions.asm"		; SPI functions for DAC and CAN controller access	
	#include "CAN_functions.asm"		; sending/receiving CAN functions	
	#include "CAN_HLP_functions.asm"	; functions implementing CAN HLP
	#include "JTAG_functions.asm"		; IRScan, DRScan
	#include "TDC_functions.asm"		; MCU JTAG instructions "lock" "get_data" etc
	#include "housekeeping.asm"		; parity, stall, etc
	#include "PLD_functions.asm"		; PLD interface
	#IF CODE_BASE == 0x0000
	#include "reprogram.asm"		; Program memory reprogramming code
	#ENDIF
	#include "TDC_config.asm"		; TDC configuration constants

;******************************************************************************

	END

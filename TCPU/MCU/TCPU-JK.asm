; $Id: TCPU-JK.asm,v 1.5 2006-04-12 15:32:42 jschamba Exp $
;
#DEFINE		CODE_BASE 0x0000

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
	#include "TCPU_macros.inc"
	#include "SPIMPol.inc"
;	#include "CAN_macros.inc"
	#include "PLD_defs.inc"

;******************************************************************************
; Configuration bits
; The __CONFIG directive defines configuration data within the .ASM file.
; The labels following the directive are defined in the P18F8720.INC file.
; The PIC18FXX20 Data Sheet explains the functions of the configuration bits.
	;; this is the old way of defining the configuration bits
;	__CONFIG	_CONFIG1H, _OSCS_OFF_1H & _EC_OSC_1H
;	__CONFIG	_CONFIG2L, _BOR_OFF_2L & _BORV_20_2L & _PWRT_ON_2L
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
	ctr             ; 0x000 counter used for loops
	ctr2		; 0x001	another counter
	inst		; 0x002 holds JTAG instructions before output
	dsize		; 0x003 holds the size of the DRScan register in bytes
                        ; (e.g. 4 for ID_Code, 81 for config bits)
	TDObyte		; 0x004 one byte of TDO input.  TDO comes in serially, is fed into TDObyte
                        ; and then TDOByte is written to memory and re-used.
	write_to	; 0x005	Destination address for writing to MCP 2515
	TDC_pointer	; 0x006 Tells what TDC the MUX is pointed at
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
;	CAN_net					; 0x02D : 0x01 -> pointer to system CANbus
							;		  0x02 -> pointer to tray CANbus
	PLD_word:		0x04	; 0x02D - 0x030
	new_prog_data:	0x40	; 0x031 - 0x070 - 64 bytes of new program data
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

	org		0x0030
	nop

;Start of main program
START

	call	VisualInitialization	; set up MCU Pin I/O, other configuration
	LED_OFF

	setf	ctr2
	call	longstall
	setf	ctr2
	call	longstall
	setf	ctr2
	call	longstall
	setf	ctr2
	call	longstall
	setf	ctr2
	call	longstall
	setf	ctr2
	call	longstall

	call	SPI_init				; initialize the SPI bus
	call	CAN_init				; Initialize CAN controller, return ready for I/O	

; Once CANbus is initialized, you should send a message saying "I've been reset!"
; This way, if the WDT trips and resets the MCU, the control network will know about
; it and can reapply configuration/firmware/whatever as necessary. 

;**********************************************************************
	LED_ON	

; PORTC, 1 is "MCU_Enable_Local" (clock)

	bsf		PORTC, 1

; PORTA, 5 is PLL_reset, and must be pulsed high for at least 1us once
; the power is stable.

; FOR SOME REASON, SETTING LATA5 or PORTA5 screws up the MCU.
; I don't understand it, and right now I"m not interested.  RA,5 is LVDIN
; but i can't find any settings that changing causes a difference.

;	bsf		LATA, 5
	nop
	nop
	nop
	nop
;	bcf		PORTA, 5

; in theory this will set the PLD to watch for input from cable 2
	movlw	0x01
	movwf	write_to
	movlw	0x04
	call	write_byte_PLD


; Main execution loop here:
PLD_LOOP
	bsf		PORTB, 4
	bcf		PORTB, 4
	call	check_for_PLD_data
check_top_CANbus
;	get_system_msg				; check for top level CAN message
	bsf		PORTB, 4
	bcf		PORTB, 4
	call	get_msg
	tstfsz	WREG
	bra		PLD_LOOP
	call	handle_CAN_msg
;	handle_system_msg
	bra		check_top_CANbus


SILENT_LOOP
	bsf		PORTB, 4
	bcf		PORTB, 4
	call	get_msg
	tstfsz	WREG
	bra		SILENT_LOOP
	call	handle_CAN_msg
;	handle_system_msg
	bra		SILENT_LOOP

;------------------------------------------------------------------------------

	#include <init_PIC18F8720.asm>		; configuration routines for MCU
	#include "SPI_functions.asm"		; SPI functions for DAC and CAN controller access	
	#include "CAN_functions.asm"		; sending/receiving CAN functions
	#include "CAN_HLP_functions.asm"	; high level protocol handlers
	#IF CODE_BASE == 0x0000
	#include "reprogram.asm"			; Program memory reprogramming code
	#ENDIF
	#include "JTAG_functions.asm"		; IRScan, DRScan
	#include "housekeeping.asm"			; parity, stall, etc
	#include "PLD_functions.asm"

;******************************************************************************

	END

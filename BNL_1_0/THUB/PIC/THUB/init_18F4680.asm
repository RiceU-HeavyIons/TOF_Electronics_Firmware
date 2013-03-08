; $Id: init_18F4680.asm,v 1.7 2007-12-05 22:48:20 jschamba Exp $
;******************************************************************************
;                                                                             *
;    Filename:      init_18F4680.asm                                          *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:        J. Schambach                                              *
;    Company:                                                                 *
;                                                                             * 
;******************************************************************************
; Initialization Code for PIC18F4680

#include "thub_uc.inc"
	
;**Note 1: Release 1 does not check POR**

InitLib	CODE
InitMicro:

	GLOBAL InitMicro
	
; Feature=ResetErrorChecks - Check for reset errors

; Feature=Interrupts
; B7=IRX B6=WAK B5=ERR B4=TXB2/n B3=TXB1 B2=TXB0 B1=RXB1/n B0=RXB0
; disable ints

	clrf PIE3

; B7=OSCF B6=CM B4=EE B3=BCL B2=HLVD B1=TMR3 B0=ECCP1

	clrf PIE2

; B7=PSP B6=AD B5=RC B4=TX B3=SSP B2=CCP1 B1=TMR2 B0=TMR1

	clrf PIE1

; Feature=Oscillator - Oscillator configuration
; B7=IDLEN B6:4=IRCF  B1:0=SCS

	movlw 0x00
	movwf OSCCON

; B7=VDIRMAG B5=IRVST B4=HLVDEN B3:0=LVDL3:0

	movlw 0x01
	movwf HLVDCON

; B0=SWDT

	movlw 0x00
	movwf WDTCON

; B7=IPEN B6=SBOREN B4=RI-L B3=TO-L B2=PD-L B1=POR-L B0=BOR-L

	movlw 0x83
	movwf RCON

; Feature=A2D - A2D configuration
; set pins for analog or digital
; B5:2=CHS3:0 B1=GO/DONE-L B0=ADON

	movlw 0x00	; GO bit1 to 0
	movwf ADCON0

; B5:4=VCFG1:0 B3:0=PCFG3:0

	movlw 0x0F	; ADCON1[3:0] = 0xF -> all digital I/O
	movwf ADCON1

; B7=ADFM B5:3=ACQT2:0 B2:0=ADCS2:0

	movlw 0x00
	movwf ADCON2

; Feature=CANIOPort - CAN I/O Control
; B5=ENDRHI B4=CANCAP
; this is done in the CAN driver, so don't do it here:
;	movlw 0x30	; Enable Tx drive high, CAN capture
;	movwf CIOCON 
	
; Feature=IOPort - IO Ports configuration

; port A is 7 bits wide
; set port bit as input (1) or output (0)
; PORTA bit#:   0 : UC_FPGA8	(o) (DS)
;               1 : UC_FPGA9	(o) (CTL)
;               2 : UC_FPGA10	(o) (DIR)
;               3 : UC_CPLD8	(o) (as_Clk)
;               4 : UC_CPLD9	(o) (as_Rst)
;               5 : UC_CPLD10	(o)
;               6 : CPLD_TDO	(i)

;	clrf  PORTA		; clear output data latches
    movlw 0x04      ; set DIR high (direction: UC ->PLD), uc_cpld(10..8) = 0
    movwf PORTA

	movlw 0xC0
	movwf TRISA
		

; port B is 8 bits wide
; PORTB bit#:   0 : CPLD_TCK	(i)
;               1 : CPLD_TDI	(i)
;               2 : CAN_TX	    (o)
;               3 : CAN_RX	    (i)
;               4 : NC
;               5 : PGM
;               6 : PGC
;               7 : PGD 

	;clrf  PORTB		; clear output data latches
	movlw 0x04		; CAN_TX needs to be high at initialization
	movwf PORTB		; set output data latches

	movlw 0xFB
	movwf TRISB

; port C is 8 bits wide
; PORTC bit#:   0 : UC_CPLD0	(i) (as_DATA or FP_TDO)
;               1 : UC_CPLD1	(o) (as_DCLK or FP_TCK)
;               2 : UC_CPLD2	(o) (as_ASDI or FP_TDI)
;               3 : UC_CPLD3	(o) (as_NCS  or FP_TMS)
;               4 : UC_CPLD4	(o) (as_NCE)
;               5 : UC_CPLD5	(o) (as_NCONFIG)
;               6 : UC_CPLD6	(o) (as_enable)
;               7 : UC_CPLD7	(o)

	clrf  PORTC		; clear output data latches

	movlw 0x01 
	movwf TRISC


; port D is 8 bits wide
; PORTD bit#:   0 : UC_FPGA0	(o)
;               1 : UC_FPGA1	(o)
;               2 : UC_FPGA2	(o)
;               3 : UC_FPGA3	(o)
;               4 : UC_FPGA4	(o)
;               5 : UC_FPGA5	(o)
;               6 : UC_FPGA6	(o)
;               7 : UC_FPGA7	(o)
;
; This port is used as a bi-directional data port
; between UC and FPGA. Set the port as output to
; start with:

	clrf  PORTD		; clear output data latches

;	movlw 0xFF 
;	movwf TRISD
	clrf  TRISD


; port E is 4 bits wide, 3 pins are configurable as input or output,
; the 4th pin is an input only pin.
; For this port, TRISE also controls the operation of the Parallel Slave Port:	
; B7=IBF B6=OBF B5=IBOV B4=PSPMODE B2:0=TRISE2:0 
; PORTE bit#:   0 : PLL_CALL	(o)
;               1 : LOL		    (i)
;               2 : CPLD_TMS	(i)
;               3 : MCLR#

	clrf  PORTE		; clear output data latches

	movlw 0x06 
	movwf TRISE


; Feature=Comparator - Comparator configuration

; set pins for analog or digital

; B7=C2OUT B6:C1OUT B5=C2INV B4=C1INV B3=CIS B2:0=CM2:0

	movlw 0x07		; Comparators off
	movwf CMCON

; Feature=VoltageRef - Voltage Reference configuration
; set pins for analog or digital
; B7=CVREN B6=CVROE B5=CVRR B4=CVSS B3:0=CVR3:0

	movlw 0x00
	movwf CVRCON

; Feature=required - Interrupt flags cleared and interrupt configuration
; interrupt priorities
; B7=OSCF B6=CM B4=EE B3=BCL B2=HLVD B1=TMR3 B0=ECCP1

;	movlw 0x00
;	movwf IPR2
	setf IPR2		; set all high priority (POR default)

; B7=PSP B6=AD B5=RC B4=TX B3=SSP B2=CCP1 B1=TMR2 B0=TMR1

;	movlw 0x00
;	movwf IPR1
	setf IPR1		; set all high priority (POR default)
	
; clear int flags
; B7=OSCF B6=CM B4=EE B3=BCL B2=HLVD B1=TMR3 B0=ECCP1

	clrf PIR2

; B7=PSP B6=AD B5=RC B4=TX B3=SSP B2=CCP1 B1=TMR2 B0=TMR1

	clrf PIR1

; global and external interrupt enables
; B7=GIE B6=PEIE B5=TMR0IE B4=INTOIE B3=RBIE B2=TMR0IF B1=INTOIF B0=RBIF

	movlw 0xC0
	movwf INTCON

; B7=RBPU-L B6:4=INTEDG0:2 B2=TMR0IP B0=RBIP

	movlw 0x05
	movwf INTCON2

; B7:6=INT2:1IP B4:3=INT2:1IE B1:0=INT2:1IF

	movlw 0xC0
	movwf INTCON3

; Feature=TMR - Timers configuration

; timer0
; (CON)B7=TMR0ON B6=T08BIT B5=T0CS B4=T0SE B3=PSA B2:0=T0PS2:0
; (TMRH)B7:0=Timer register High byte
; (TMRL)B7:0=Timer register Low byte

;	bcf T0CON,TMR0ON
;	movlw 0x00                             ; set options with timer on/off (bit7)
;	movwf T0CON
	clrf T0CON

; ***note: must reload 0x100-TMR in application code***

	clrf TMR0H                             ; preset timer values
	clrf TMR0L

; timer2
; (CON)B6:3=T2OUTPS3:0 B2=TMR2ON B1:0=T2CKPS1:0
; (TMR)Timer register (cleared)
; (PR)Timer preload register (set)

;	bcf T2CON,TMR2ON
;	movlw 0x00                             ; set options with timer on/off (bit2)
;	movwf T2CON
	clrf T2CON

	clrf TMR2                              ; preset timer values

	movlw 0xFF                             ; preload timer values
	movwf PR2


; timer1 and timer3
; (CON)B7=RD16 B6=T1RUN B5:4=T1CKPS1:0 B3=T1OSCEN B2=T1SYNC-L B1=TMR1CS B0=TMR1ON
; (TMRH)Timer register High byte
; (TMRL)Timer register Low byte

;	bcf T1CON,TMR1ON
;	movlw 0x00                             ; set options with timer on/off (bit0)
;	movwf T1CON
	clrf T1CON

; ***note: must reload 0x100-TMR in application code***

	clrf TMR1H                             ; preset timer values
	clrf TMR1L

;	bcf T3CON,TMR3ON
;	movlw 0x00  ; set options with timer on/off (bit0)
;	movwf T3CON
	clrf T3CON

; ***note: must reload 0x100-TMR in application code***

	clrf TMR3H  ; preset timer values
	clrf TMR3L

; Feature=CPU - CPU register configuration

; Feature=Interrupts - enable interrupts

; feature interrupt enables
; B7=IRX B6=WAK B5=ERR B4=TXB2 B3=TXB1 B2=TXB0 B1=RXB1 B0=RXB0

;	movlw 0x00
;	movwf PIE3
;	clrf PIE3

; B7=OSCF B6=CM B4=EE B3=BCL B2=HLVD B1=TMR3 B0=ECCP1

;	movlw 0x00
;	movwf PIE2
;	clrf PIE2

; B7=PSP B6=AD B5=RC B4=TX B3=SSP B2=CCP1 B1=TMR2 B0=TMR1

;	movlw 0x00
;	movwf PIE1
;	clrf PIE1

	return

	END

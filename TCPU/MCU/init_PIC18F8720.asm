
; Initialization Code for PIC18F8720, Family: GP control, Package: TQFP 80pins

;**Note 1: Release 1 does not check POR**


VisualInitialization:

; Feature=ResetErrorChecks - Check for reset errors

; Feature=Interrupts - Disable Interrupts during configuration

; disable ints

; B5=RC2 B4=TX2 B3=TMR4 B2=CCP5 B1=CCP4 B0=CCP3

	clrf PIE3

; B6=CM B4=EE B3=BCL B2=LVD B1=TMR3 B0=CCP2

	clrf PIE2

; B7=PSP B6=AD B5=RC1 B4=TX1 B3=SSP B2=CCP1 B1=TMR2 B0=TMR1

	clrf PIE1

; Feature=Oscillator - Oscillator configuration

; B0=SCS

	movlw 0x00
	movwf OSCCON

; B5=IRVST B4=LVDEN B3:0=LVDL3:0

	movlw 0x01
	movwf LVDCON

; B5=IRVST B4=LVDEN B3:0=LVDL3:0

	movlw 0x00
	movwf WDTCON

; B7=IPEN B4=RI-L B3=TO-L B2=PD-L B1=POR-L B0=BOR-L

	movlw 0x00
	movwf RCON

; Feature=IOPort - IO Ports configuration

; port A is 7 bits wide

; set TRIS to all inputs before setting initial value

	movlw 0x7F
	movwf TRISA

	movlw 0x08
	movwf PORTA

; set port bit as input (1) or output (0)
; PORTA bit#:	0 : Input	TEMPMON (analog)
;				1 :	Input	FIFO_empty
;				2 : Output	PLD_reset (to PLD PLL)
;				3 : Output	CAN_reset
;				4 : Output	LED (open drain)
;				5 : Output	PLL_reset
;				6 : Output	OSC2 (not an I/O pin)
		
	movlw 0x03
	movwf TRISA

; port B is 8 bits wide

; set TRIS to all inputs before setting initial value

	movlw 0xFF
	movwf TRISB

; PORTB bit#:	0 : Output	PLD strobe
;				1 :	Output	CAN1 select (active low)
;				2 : Output	CAN2 select (active low)
;				3 : Output	FLASH reset (active low)
;				4 : Output	WDT wiggle pin
;				5 : Input	ICD stuff
;				6 : Input	ICD stuff
;				7 : Input	ICD stuff

	movlw 0x0E
	movwf PORTB

; set port bit as input (1) or output (0)

	movlw 0xE0
	movwf TRISB

; port C is 8 bits wide

; set TRIS to all inputs before setting initial value

	movlw 0xFF
	movwf TRISC

; PORTC bit#:	0 : Output	PLD read/write select (high = PLD is input)
;				1 : Output	MCU enable local (?)
;				2 : Output	PLL in select
;				3 : Output	SPI SCK
;				4 : Input	SPI SDI
;				5 : Output	SPI SDO
;				6 : Output	Temp mon SPI chip select
;				7 : Input	PLL LOL

	movlw 0x43
	movwf PORTC

; set port bit as input (1) or output (0)

	movlw 0x90
	movwf TRISC

; port D is 8 bits wide

; set TRIS to all inputs before setting initial value

	movlw 0xFF
	movwf TRISD

	movlw 0x00
	movwf PORTD

; set port bit as input (1) or output (0)

	movlw 0xFF
	movwf TRISD

; port E is 8 bits wide

; set TRIS to all inputs before setting initial value

	movlw 0xFF
	movwf TRISE

	movlw 0x00
	movwf PORTE

; set port bit as input (1) or output (0)

	movlw 0xFF
	movwf TRISE

; port F is 8 bits wide

; set TRIS to all inputs before setting initial value

	movlw 0xFF
	movwf TRISF

	movlw 0xFF
	movwf PORTF

; set port bit as input (1) or output (0)

	movlw 0xFF
	movwf TRISF

; port G is 5 bits wide

; set TRIS to all inputs before setting initial value

	movlw 0x1F
	movwf TRISG

; PORTG bit#:	0 : Output	PLD addr[0]
;				1 :	Output	TX2
;				2 : Intput	RX2
;				3 : Output	PLD addr[1]
;				4 : Output	PLD addr[2]

	movlw 0x00
	movwf PORTG

; set port bit as input (1) or output (0)

	movlw 0x04
	movwf TRISG

; port H is 8 bits wide

; set TRIS to all inputs before setting initial value

	movlw 0xFF
	movwf TRISH

	movlw 0x00
	movwf PORTH

; set port bit as input (1) or output (0)

	movlw 0x10
	movwf TRISH

; port J is 8 bits wide

; set TRIS to all inputs before setting initial value

	movlw 0xFF
	movwf TRISJ

	movlw 0x2A
	movwf PORTJ

; set port bit as input (1) or output (0)

	movlw 0x00
	movwf TRISJ

; Feature=PSP - PSP configuration

; B7=IBF B6=OBF B5=IBOV B4=PSPMODE

	movlw 0x00
	movwf PSPCON

; Feature=EMI - EMI configuration

; B7=EBDIS B5:4=WAIT1:0 B1:0=WM1:0

	movlw 0x00
	movwf MEMCON

; Feature=CCP - CCP configuration

; (H)Register High Byte

; (L)Register Low Byte

; (CON)B5:4=DCB1:0 B4:0=CCPM3:0

; CCP1

	movlw 0x00
	movwf CCPR1H

	movlw 0x00
	movwf CCPR1L

	movlw 0x00
	movwf CCP1CON

; CCP2

	movlw 0x00
	movwf CCPR2H

	movlw 0x00
	movwf CCPR2L

	movlw 0x00
	movwf CCP2CON

; CCP3

	movlw 0x00
	movwf CCPR3H

	movlw 0x00
	movwf CCPR3L

	movlw 0x00
	movwf CCP3CON

; CCP4

	movlw 0x00
	movwf CCPR4H

	movlw 0x00
	movwf CCPR4L

	movlw 0x00
	movwf CCP4CON

; CCP5

	movlw 0x00
	movwf CCPR5H

	movlw 0x00
	movwf CCPR5L

	movlw 0x00
	movwf CCP5CON

; Feature=MSSP - MSSP configuration

; RX/TX buffer

	movf SSPBUF, W

; Address register (I2C Slave) or BRG (I2C Master)

	movlw 0x00
	movwf SSPADD

; B7=SMP B6=CKE B5=D/A-L B4=P B3=S B2=R/W-L B1=UA B0=BF

	movlw 0x00
	movwf SSPSTAT

; B7=WCOL B6=SSPOV B5=SSPEN B4=CKP B3:0=SSPM3:0

	movlw 0x00
	movwf SSPCON1

; B7=GCEN B6=ACKSTAT B5=ACKDT B4=ACKEN B3=RCEN B2=PEN B1=RSEN B0=SEN

	movlw 0x00
	movwf SSPCON2

; Feature=USART - USART configuration

; USART1 and USART2

; (RCSTA)B7=SPEN B6=RX9 B5=SREN B4=CREN B3=ADDEN B2=FERR B1=OERR B0=RX9D

; (TXSTA)B7=CSRC B6=TX9 B5=TXEN B4=SYNC B2=BRGH B1=TRMT B0=TX9D

; (SPBRG)Baud rate generator

; (RCREG)Recieve register

	movlw 0x00                             ; set up receive options
	movwf RCSTA1

	movlw 0x00                             ; set up transmit options
	movwf TXSTA1

	movlw 0x00                             ; set up baud
	movwf SPBRG1

	movf RCREG1, W                         ; flush receive buffer

	movf RCREG1, W

	movlw 0x00                             ; set up receive options
	movwf RCSTA2

	movlw 0x00                             ; set up transmit options
	movwf TXSTA2

	movlw 0x00                             ; set up baud
	movwf SPBRG2

	movf RCREG2, W                         ; flush receive buffer

	movf RCREG2, W

; Feature=CAN - CAN bus configuration - none in this release

; Feature=A2D - A2D configuration

; set pins for analog or digital

; B5:2=CHS3:0 B1=GO/DONE-L B0=ADON

	movlw 0x00                             ; GO bit1 to 0
	movwf ADCON0

; B5:4=VFG1:0 B4:0=PCFG3:0

	movlw 0x0E					; ADCON1[3:0] = 0xE -> only one analog pin (AN0)
	movwf ADCON1

; B7=ADFM B2:0=ADCS2:0

	movlw 0x00
	movwf ADCON2

; Feature=Comparator - Comparator configuration

; set pins for analog or digital

; B7=C2OUT B6:C1OUT B5=C2INV B4=C1INV B3=CIS B2:0=CM2:0

	movlw 0x07
	movwf CMCON

; Feature=VoltageRef - Voltage Reference configuration

; set pins for analog or digital

; B7=CVREN B6=CVROE B5=CVRR B4=CVSS B3:0=CVF3:0

	movlw 0x00
	movwf CVRCON

; Feature=required - Interrupt flags cleared and interrupt configuration

; interrupt priorities

; B5=RC2 B4=TX2 B3=TMR4 B2=CCP5 B1=CCP4 B0=CCP3

	movlw 0x00
	movwf IPR3

; B6=CM B4=EE B3=BCL B2=LVD B1=TMR3 B0=CCP2

	movlw 0x00
	movwf IPR2

; B7=PSP B6=AD B5=RC1 B4=TX1 B3=SSP B2=CCP1 B1=TMR2 B0=TMR1

	movlw 0x00
	movwf IPR1

; clear int flags

; B5=RC2 B4=TX2 B3=TMR4 B2=CCP5 B1=CCP4 B0=CCP3

	clrf PIR3

; B6=CM B4=EE B3=BCL B2=LVD B1=TMR3 B0=CCP2

	clrf PIR2

; B7=PSP B6=AD B5=RC1 B4=TX1 B3=SSP B2=CCP1 B1=TMR2 B0=TMR1

	clrf PIR1

; global and external interrupt enables

; B7=GIE B6=PEIE B5=TMR0IE B4=INTOIE B3=RBIE B2=TMR0IF B1=INTOIF B0=RBIF

	movlw 0xC0
	movwf INTCON

; B7=RBPU-L B6:3=INTEDG0:3 B2=TMR0IP B1=INT3IP B0=RBIP

	movlw 0x02
	movwf INTCON2

; B7:6=INT2:1IP B5:3=INT3:1IE B2:0=INT3:1IF

	movlw 0xC0
	movwf INTCON3

; Feature=TMR - Timers configuration

; timer0

; (CON)B7=TMRON B6=T8BIT B5=TCS B4=TSE B3=PSA B2:0=TPS2:0

; (TMRH)B7:0=Timer register High byte

; (TMRL)B7:0=Timer register Low byte

	bcf T0CON,TMR0ON

	movlw 0x00                             ; set options with timer on/off (bit7)
	movwf T0CON

; ***note: must reload 0x100-TMR in application code***

	clrf TMR0H                             ; preset timer values

	clrf TMR0L

; timer2 and timer4

; (CON)B6:3=TOUTPS3:0 B2=TMRON B1:0=TCKPS1:0

; (TMR)Timer register (cleared)

; (PR)Timer preload register (set)

	bcf T2CON,TMR2ON

	movlw 0x00                             ; set options with timer on/off (bit2)
	movwf T2CON

	clrf TMR2                              ; preset timer values

	movlw 0xFF                             ; preload timer values
	movwf PR2

	bcf T4CON,TMR4ON

	movlw 0x00                             ; set options with timer on/off (bit2)
	movwf T4CON

	clrf TMR4                              ; preset timer values

	movlw 0xFF                             ; preload timer values
	movwf PR4

; timer1 and timer3

; (CON)B7=RD16 B5:4=TCKPS1:0 B3=TOSCEN B2=TSYNC-L B1=TMRCS B0=TMRON

; (TMRH)Timer register High byte

; (TMRL)Timer register Low byte

	bcf T1CON,TMR1ON

	movlw 0x00                             ; set options with timer on/off (bit0)
	movwf T1CON

; ***note: must reload 0x100-TMR in application code***

	clrf TMR1H                             ; preset timer values

	clrf TMR1L

	bcf T3CON,TMR3ON

	movlw 0x00                             ; set options with timer on/off (bit0)
	movwf T3CON

; ***note: must reload 0x100-TMR in application code***

	clrf TMR3H                             ; preset timer values

	clrf TMR3L

; Feature=CPU - CPU register configuration

; Feature=Interrupts - enable interrupts

; feature interrupt enables

; B5=RC2 B4=TX2 B3=TMR4 B2=CCP5 B1=CCP4 B0=CCP3

	movlw 0x00
	movwf PIE3

; B6=CM B4=EE B3=BCL B2=LVD B1=TMR3 B0=CCP2

	movlw 0x00
	movwf PIE2

; B7=PSP B6=AD B5=RC1 B4=TX1 B3=SSP B2=CCP1 B1=TMR2 B0=TMR1

	movlw 0x00
	movwf PIE1

	return

; Feature=ResetErrorHandlers - 

	GLOBAL VisualInitialization

config_micro
; PORTA:
; RA0 INPUT - Analog Temperature from under PLD
; RA1 INPUT - Analog Temperature from under TDC2
; RA2 INPUT - Analog Temperature from TAMP edge
; RA3 INPUT - Analog Temperature from TAMP center
; RA4 OUTPUT - +2.8V_B enable (open drain) 
; RA5 INPUT - Analog threshold feedback
; RA6 OUTPUT - DAC Frame Sync pin
; check datasheet for appropriate values of TRISA[6,7]... they could screw you.

; Datasheet page 105: "Note: On a Power-on Reset, RA5 and RA3:RA0 are 
; configured as analog inputs and read as ‘0’. RA6 and RA4 are configured
; as digital inputs."

	MOVLW	0x2F
	MOVWF	TRISA
	movlw	0x10
	movwf	PORTA		; +2.8V_B_EN = 1 (enabled)
	
; D/A converter setup:
; ADCON0 REGISTER
; bit 7-6 Unimplemented: Read as '0'
; bit 5-2 CHS3:CHS0: Analog Channel Select bits (0x0 - 0x4)
; bit 1 GO/DONE: A/D Conversion Status bit
; 1 = A/D conversion in progress (setting this bit starts the A/D conversion, which 
;     is automatically cleared by hardware when the A/D conversion is complete)
; bit 0 ADON: A/D On bit
; 1 = A/D converter module is enabled
; 0 = A/D converter module is disabled

	clrf	ADCON0

; ADCON1 REGISTER
; bit 7-6 Unimplemented: Read as '0'
; bit 5-4 VCFG1:VCFG0: Voltage Reference Configuration bits:
; 00: AVDD AVSS
; bit 3-0 PCFG3:PCFG0: A/D Port Configuration Control bits:
; 1010 D D D D D D D D D D D A A A A A

	movlw	0x0A
	movwf	ADCON1

; ADCON2 REGISTER
; bit 7 ADFM: A/D Result Format Select bit
; 1 = Right justified
; 0 = Left justified
; bit 6-3 Unimplemented: Read as '0'
; bit 2-0 ADCS1:ADCS0: A/D Conversion Clock Select bits:
; 010 = FOSC/32  -> at 20MHz TAD = 1.6us, ideal
; 110 = FOSC/64  -> at 20MHz TAD ~=3.1us, possibly required for LF Part (see p.213)
; 111 = FRC (clock derived from an RC oscillator = 1 MHz max)
; For correct A/D conversions, the A/D conversion clock (TAD) must be 
; selected to ensure a minimum TAD time of 1.6 µs.
	movlw	0x86
	movwf	ADCON2

; PORTB:
; RB0 OUTPUT: PLD_DATA_Strobe
; RB1  INPUT: FIFO_empty
; RB2 OUTPUT: PLD/TDC JTAG MUX SEL - 1 => JTAG to PLD.  0 => JTAG TO TDC's
; RB3 OUTPUT: DAC Chip select (SPI)
; RB4 OUTPUT: MCU_PLD CTRL[1] PLD data direction
;				1 -> PLD reads MCU
;				0 -> PLD writes to MCU
; RB5, RB6, RB7 INPUT: Programmer pins

	movlw	0xE2
	movwf	TRISB
	clrf	PORTB
	clrf	JTAG_status
	
; Interrupt setup:
; INTCON:
; bit 7 GIE/GIEH: Global Interrupt Enable bit
;	When IPEN (RCON<7>) = 0: Enables all unmasked interrupts
;	When IPEN (RCON<7>) = 1: Enables all high priority interrupts
; bit 6 PEIE/GIEL: Peripheral Interrupt Enable bit
;	When IPEN (RCON<7>) = 0: Enables all unmasked peripheral interrupts
;	When IPEN (RCON<7>) = 1: Enables all low priority peripheral interrupts
; bit 5 TMR0IE: TMR0 Overflow Interrupt Enable bit
;	Enables the TMR0 overflow interrupt
; bit 4 INT0IE: INT0 External Interrupt Enable bit
;	Enables the INT0 external interrupt
; bit 3 RBIE: RB Port Change Interrupt Enable bit
;	Enables the RB port change interrupt
; bit 2 TMR0IF: TMR0 Overflow Interrupt Flag bit
;	1 = TMR0 register has overflowed (must be cleared in software)
; bit 1 INT0IF: INT0 External Interrupt Flag bit
;	1 = The INT0 external interrupt occurred (must be cleared in software)
; bit 0 RBIF: RB Port Change Interrupt Flag bit
;	1= At least one of the RB7:RB4 pins changed state (must be cleared in software)
; Note: A mismatch condition will continue to set this bit. Reading PORTB will end the
; mismatch condition and allow the bit to be cleared.

	clrf	INTCON

; INTCON2
; bit 7 RBPU: PORTB Pull-up Enable bit
;	1 = All PORTB pull-ups are disabled
;	0 = PORTB pull-ups are enabled by individual port latch values
; bit 6 INTEDG0:External Interrupt0 Edge Select bit
;	1 = Interrupt on rising edge
;	0 = Interrupt on falling edge
; bit 5 INTEDG1: External Interrupt1 Edge Select bit
;	1 = Interrupt on rising edge
;	0 = Interrupt on falling edge
; bit 4 INTEDG2: External Interrupt2 Edge Select bit
;	1 = Interrupt on rising edge
;	0 = Interrupt on falling edge
; bit 3 INTEDG2: External Interrupt3 Edge Select bit
;	1 = Interrupt on rising edge
;	0 = Interrupt on falling edge
; bit 2 TMR0IP: TMR0 Overflow Interrupt Priority bit
;	1 = High priority
;	0 = Low priority
; bit 1 INT3IP: INT3 External Interrupt Priority bit
;	1 = High priority
;	0 = Low priority
; bit 0 RBIP: RB Port Change Interrupt Priority bit
;	1 = High priority
;	0 = Low priority

	movlw	0xF8
	movwf	INTCON2

; PORTC setup:
; RC0: OUTPUT LED
; RC1: OUTPUT 40MHz Clock source select:
;	1 = 40MHz On-board CXO
;	0 = 4xRHIC from upstream
; RC2: OUTPUT nENABLE for 40MHz clock (as selected by RC1)
; RC3: OUTPUT SPI clock SCK
; RC4: INPUT SPI data SDI
; RC5: OUTPUT SPI data SDO
; RC6: OUTPUT SPI chip select (nCS) for MCP2515
; RC7: OUTPUT MCU_CTRL[0] RESET to PLD readout state machines

	movlw	0x10
	movwf	TRISC

	movlw	0x47
	movwf	PORTC
	
; PORTD is external Address/Data [7:0]
	setf	TRISD
	clrf	LATD

; PORTE is external Address/Data [15:8]

	setf	TRISE
	clrf	LATE

; PORTF Configuration
; PORTF is the PLD data byte.  Will change direction under protocol control.
; For initialization, set to input

	movlw	0x07
	movwf	CMCON		; turn off comparators

	setf	TRISF
	clrf	LATF

; PORTG Configuration
; RG0: OUTPUT MCU_CTRL[2] PLD REGISTER SELECT BIT 0
; RG1: OUTPUT RS232 TX USART2
; RG2: INPUT RS232 RX USART2
; RG3: OUTPUT MCU_CTRL[3] PLD REGISTER SELECT BIT 1
; RG4: OUTPUT MCU_CTRL[4] PLD REGISTER SELECT BIT 2

	movlw	0x04
	movwf	TRISG
	clrf	PORTG

; PORTH Configuration
; RH[3:0]: External memory interface Address[19:16]
; RH4: INPUT JTAG TDO
; RH5: OUTPUT JTAG TDI
; RH6: OUTPUT JTAG TMS
; RH7: OUTPUT JTAG TCK

	movlw	0x10
	movwf	TRISH
	clrf	PORTH

; MEMCON Setup (see page 71):
; bit 7: External bus disable bit.  Set to 1 (Digital I/O) by default
; bits [5:4]: Table reads and write bus cycle wait count
; only effective if CONFIG3L bits are set to allow software control
;    11 -> wait 0 Tcy
;    10 -> wait 1 Tcy
;    01 -> wait 2 Tcy
;    00 -> wait 3 Tcy
; bits [1:0]: word mode.  
;    11 -> word write mode
;	 00 -> byte write mode
	movlw	0x30
	movwf	MEMCON

; PORTJ Configuration
; RJ0: OUTPUT external memory address latch enable
; RJ1: OUTPUT external memory nOE
; RJ2: OUTPUT external memory nWRL (Unused)
; RJ3: OUTPUT external memory write enable (nWE)
; RJ4: OUTPUT external memory BA0 (Unused)
; RJ5: OUTPUT external memory nCE (atmel FLASH)
; RJ6: OUTPUT external memory nLB (Unused)
; RJ7: OUTPUT external memory nUB (Unused)

	clrf	TRISJ
	movlw	0x20
	movwf	PORTJ
	
	allow_byteblaster

	return

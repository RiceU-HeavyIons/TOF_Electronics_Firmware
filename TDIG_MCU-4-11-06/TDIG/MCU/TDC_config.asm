; store control constants to program memory:
reset_all	org	(CODE_BASE + 0x002000)
	db		0xFF, 0xFF, 0xFF, 0xFF, 0xE4
lock_pll	org	(CODE_BASE + 0x002006)
	db		0x3F, 0xFF, 0xFF, 0xFF, 0xE4
lock_dll	org	(CODE_BASE + 0x00200C)
	db		0x9F, 0xFF, 0xFF, 0xFF, 0xE4
enable_all	org	(CODE_BASE + 0x002012)
	db		0x9F, 0xFF, 0xFF, 0xFF, 0xE4
enable_group0	org	(CODE_BASE + 0x002018)
	db		0x80, 0x00, 0x00, 0x01, 0xE4
global_reset	org	(CODE_BASE + 0x00201E)
	db		0x00, 0x00, 0x00, 0x00, 0x14
TDC_ID		org (CODE_BASE + 0x002024)
	db		0x84, 0x70, 0xDA, 0xCE
;End of program

p_config1	org (CODE_BASE + 0x002028)
   DB B'00011101', B'11111111'
   DB B'11110110', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00100101', B'11000000'
   DB B'00100000', B'00001000'
   DB B'00100111', B'11111111'
   DB B'11111111', B'11011011'
   DB B'01101011', B'01101101'
   DB B'10010010', B'01000110'
   DB B'11011011', B'01001001'
   DB B'00100010', B'01001001'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'11100000'
   DB B'11100000', B'01111000'
   DB B'00000000', B'01010001'
   DB B'00100100', B'11110000'
   DB B'11110000', B'11110000'
   DB B'00000111', B'11010000'
   DB B'01111110', B'00011000'
   DB B'00010111', B'11000000'
   DB B'10010000', B'00000110'
   DB B'00000011', B'11111111'
   DB B'10011100'

p_config2	org	(CODE_BASE + 0x002080)
   DB B'00011101', B'11111111'
   DB B'11110110', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00100101', B'11000000'
   DB B'00100000', B'00001000'
   DB B'00100111', B'11111111'
   DB B'11111111', B'11011011'
   DB B'01101011', B'01101101'
   DB B'10010010', B'01000110'
   DB B'11011011', B'01001001'
   DB B'00100010', B'01001001'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'11100000'
   DB B'11100000', B'01111000'
   DB B'00000000', B'01010001'
   DB B'00100100', B'11110000'
   DB B'11110000', B'11110000'
   DB B'00000111', B'11010000'
   DB B'01111110', B'00011000'
   DB B'00010111', B'11000000'
   DB B'10010000', B'00000110'
   DB B'00000011', B'11111111'
   DB B'10011100'

p_config3	org	(CODE_BASE + 0x0020D8)
   DB B'00011101', B'11111111'
   DB B'11110110', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00100101', B'11000000'
   DB B'00100000', B'00001000'
   DB B'00100111', B'11111111'
   DB B'11111111', B'11011011'
   DB B'01101011', B'01101101'
   DB B'10010010', B'01000110'
   DB B'11011011', B'01001001'
   DB B'00100010', B'01001001'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'11100000'
   DB B'11100000', B'01111000'
   DB B'00000000', B'01010001'
   DB B'00100100', B'11110000'
   DB B'11110000', B'11110000'
   DB B'00000111', B'11010000'
   DB B'01111110', B'00011000'
   DB B'00010111', B'11000000'
   DB B'10010000', B'00000110'
   DB B'00000011', B'11111111'
   DB B'10011100'

p_config4	org	(CODE_BASE + 0x002130)
   DB B'00011101', B'11111111'
   DB B'11110110', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00100100', B'00100000'
   DB B'00100000', B'00001000'
   DB B'00100111', B'11111111'
   DB B'11111111', B'11011011'
   DB B'01101011', B'01101101'
   DB B'10010010', B'01000110'
   DB B'11011011', B'01001001'
   DB B'00100010', B'01001001'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'00000000'
   DB B'00000000', B'11100000'
   DB B'11100000', B'01111000'
   DB B'00000000', B'01010001'
   DB B'00100100', B'11110000'
   DB B'11110000', B'11110000'
   DB B'00000111', B'11010000'
   DB B'01111110', B'00011000'
   DB B'00010111', B'11000110'
   DB B'10010000', B'00000110'
   DB B'00000011', B'11111111'
   DB B'10011100'


TABEND
;#if ( (reset_all & 0xF00) != (TABEND & 0xF00) )
;       MESSG   "Warning - Table global_reset_tp crosses page boundry"
;#endif

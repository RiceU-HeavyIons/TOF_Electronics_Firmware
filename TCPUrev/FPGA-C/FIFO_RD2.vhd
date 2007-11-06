-- $Id: FIFO_RD2.vhd,v 1.1 2007-11-06 18:59:58 jschamba Exp $
--  C:\1_STAR_TOF\PICOTOF 2006\TCPU-B JAN 2007\TCPU-B FPGA\FIFO_RD2.vhd
--  VHDL code created by Xilinx's StateCAD 6.2i
--  Mon May 14 14:59:47 2007

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is disabled,  implied else is disabled, 
--  and outputs are speed optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY FIFO_RD2 IS
	PORT (CLK,MCU_STROBE,RD_ADR14,RESET: IN std_logic;
		OUT_HI : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF FIFO_RD2 IS
	TYPE type_sreg IS (STATE0,STATE1,STATE2);
	SIGNAL sreg, next_sreg : type_sreg;
	SIGNAL next_OUT_HI : std_logic;
BEGIN
	PROCESS (CLK, RESET, next_sreg, next_OUT_HI)
	BEGIN
		IF ( RESET='1' ) THEN
			sreg <= STATE0;
			OUT_HI <= '0';
		ELSIF CLK='1' AND CLK'event THEN
			sreg <= next_sreg;
			OUT_HI <= next_OUT_HI;
		END IF;
	END PROCESS;

	PROCESS (sreg,MCU_STROBE,RD_ADR14)
	BEGIN
		next_OUT_HI <= '0'; 

		next_sreg<=STATE0;

		CASE sreg IS
			WHEN STATE0 =>
				IF ( RD_ADR14='0' ) THEN
					next_sreg<=STATE0;
					next_OUT_HI<='0';
				END IF;
				IF ( RD_ADR14='1' ) THEN
					next_sreg<=STATE1;
					next_OUT_HI<='0';
				END IF;
			WHEN STATE1 =>
				IF ( MCU_STROBE='1' ) THEN
					next_sreg<=STATE1;
					next_OUT_HI<='0';
				END IF;
				IF ( MCU_STROBE='0' ) THEN
					next_sreg<=STATE2;
					next_OUT_HI<='1';
				END IF;
			WHEN STATE2 =>
				next_sreg<=STATE0;
				next_OUT_HI<='0';
			WHEN OTHERS => 
				next_sreg <= STATE0;
		END CASE;
	END PROCESS;
END BEHAVIOR;

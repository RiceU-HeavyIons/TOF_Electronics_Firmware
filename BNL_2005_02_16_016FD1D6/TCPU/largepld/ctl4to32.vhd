--  C:\AFRESNO\FIRMWARE\LARGEPLD\STATE MACHINES\CTL4TO32.vhd
--  VHDL code created by Xilinx's StateCAD 5.03
--  Tue Sep 07 06:36:36 2004

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are speed optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY CTL4TO32 IS
	PORT (CLK,DSTROBE,RESET: IN std_logic;
		REGA_EN : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF CTL4TO32 IS
	TYPE type_sreg IS (STATE0,STATE1,STATE2,STATE3,STATE4,STATE5,STATE6,STATE7,
		STATE8);
	SIGNAL sreg, next_sreg : type_sreg;
	SIGNAL next_REGA_EN : std_logic;
BEGIN
	PROCESS (CLK, next_sreg, next_REGA_EN)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			sreg <= next_sreg;
			REGA_EN <= next_REGA_EN;
		END IF;
	END PROCESS;

	PROCESS (sreg,DSTROBE,RESET)
	BEGIN
		next_REGA_EN <= '0'; 

		next_sreg<=STATE0;

		IF ( RESET='1' ) THEN
			next_sreg<=STATE0;
			next_REGA_EN<='0';
		ELSE
			CASE sreg IS
				WHEN STATE0 =>
					IF ( DSTROBE='1' ) THEN
						next_sreg<=STATE1;
						next_REGA_EN<='0';
					END IF;
					IF ( DSTROBE='0' ) THEN
						next_sreg<=STATE0;
						next_REGA_EN<='0';
					END IF;
				WHEN STATE1 =>
					next_sreg<=STATE2;
					next_REGA_EN<='0';
				WHEN STATE2 =>
					next_sreg<=STATE3;
					next_REGA_EN<='0';
				WHEN STATE3 =>
					next_sreg<=STATE4;
					next_REGA_EN<='0';
				WHEN STATE4 =>
					next_sreg<=STATE5;
					next_REGA_EN<='0';
				WHEN STATE5 =>
					next_sreg<=STATE6;
					next_REGA_EN<='0';
				WHEN STATE6 =>
					IF ( DSTROBE='1' ) THEN
						next_sreg<=STATE7;
						next_REGA_EN<='0';
					END IF;
					IF ( DSTROBE='0' ) THEN
						next_sreg<=STATE0;
						next_REGA_EN<='0';
					END IF;
				WHEN STATE7 =>
					next_sreg<=STATE8;
					next_REGA_EN<='1';
				WHEN STATE8 =>
					next_sreg<=STATE0;
					next_REGA_EN<='0';
				WHEN OTHERS =>
			END CASE;
		END IF;
	END PROCESS;
END BEHAVIOR;

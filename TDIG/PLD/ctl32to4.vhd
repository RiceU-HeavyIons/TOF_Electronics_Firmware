--  C:\AFRESNO\FIRMWARE\CABLE_SIM\CTL32TO4.vhd
--  VHDL code created by Xilinx's StateCAD 5.03
--  Sat Nov 13 10:46:44 2004

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are manually optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY SHELL_CTL32TO4 IS
	PORT (CLK,DIN_STROBE,RESET: IN std_logic;
		CTR0,CTR1,CTR2,CTR3,DOUT_STROBE,READY : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF SHELL_CTL32TO4 IS
	TYPE type_sreg IS (STATE0,STATE1,STATE2,STATE3,STATE4,STATE5,STATE6,STATE7,
		STATE8,STATE9,STATE10);
	SIGNAL sreg, next_sreg : type_sreg;
	SIGNAL CTR : std_logic_vector (3 DOWNTO 0);
BEGIN
	PROCESS (CLK, RESET, next_sreg)
	BEGIN
		IF ( RESET='1' ) THEN
			sreg <= STATE0;
		ELSIF CLK='1' AND CLK'event THEN
			sreg <= next_sreg;
		END IF;
	END PROCESS;

	PROCESS (sreg,DIN_STROBE,CTR)
	BEGIN
		CTR0 <= '0'; CTR1 <= '0'; CTR2 <= '0'; CTR3 <= '0'; DOUT_STROBE <= '0'; 
			READY <= '0'; 
		CTR<=std_logic_vector'("0000"); 

		next_sreg<=STATE0;

		CASE sreg IS
			WHEN STATE0 =>
				DOUT_STROBE<='0';
				READY<='1';
				CTR <= (std_logic_vector'("0000"));
				IF ( DIN_STROBE='0' ) THEN
					next_sreg<=STATE0;
				END IF;
				IF ( DIN_STROBE='1' ) THEN
					next_sreg<=STATE1;
				END IF;
			WHEN STATE1 =>
				DOUT_STROBE<='0';
				READY<='0';
				CTR <= (std_logic_vector'("0001"));
				next_sreg<=STATE2;
			WHEN STATE2 =>
				READY<='0';
				DOUT_STROBE<='1';
				CTR <= (std_logic_vector'("0010"));
				next_sreg<=STATE3;
			WHEN STATE3 =>
				READY<='0';
				DOUT_STROBE<='1';
				CTR <= (std_logic_vector'("0011"));
				next_sreg<=STATE4;
			WHEN STATE4 =>
				READY<='0';
				DOUT_STROBE<='1';
				CTR <= (std_logic_vector'("0100"));
				next_sreg<=STATE5;
			WHEN STATE5 =>
				READY<='0';
				DOUT_STROBE<='1';
				CTR <= (std_logic_vector'("0101"));
				next_sreg<=STATE6;
			WHEN STATE6 =>
				READY<='0';
				DOUT_STROBE<='1';
				CTR <= (std_logic_vector'("0110"));
				next_sreg<=STATE7;
			WHEN STATE7 =>
				READY<='0';
				DOUT_STROBE<='1';
				CTR <= (std_logic_vector'("0111"));
				next_sreg<=STATE8;
			WHEN STATE8 =>
				READY<='0';
				DOUT_STROBE<='1';
				CTR <= (std_logic_vector'("1000"));
				next_sreg<=STATE9;
			WHEN STATE9 =>
				READY<='0';
				DOUT_STROBE<='1';
				CTR <= (std_logic_vector'("0000"));
				next_sreg<=STATE10;
			WHEN STATE10 =>
				DOUT_STROBE<='0';
				READY<='0';
				CTR <= (std_logic_vector'("0000"));
				next_sreg<=STATE0;
			WHEN OTHERS =>
		END CASE;

		CTR3 <= CTR(3);
		CTR2 <= CTR(2);
		CTR1 <= CTR(1);
		CTR0 <= CTR(0);
	END PROCESS;
END BEHAVIOR;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY CTL32TO4 IS
	PORT (CTR : OUT std_logic_vector (3 DOWNTO 0);
		CLK,DIN_STROBE,RESET: IN std_logic;
		DOUT_STROBE,READY : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF CTL32TO4 IS
	COMPONENT SHELL_CTL32TO4
		PORT (CLK,DIN_STROBE,RESET: IN std_logic;
			CTR0,CTR1,CTR2,CTR3,DOUT_STROBE,READY : OUT std_logic);
	END COMPONENT;
BEGIN
	SHELL1_CTL32TO4 : SHELL_CTL32TO4 PORT MAP (CLK=>CLK,DIN_STROBE=>DIN_STROBE,
		RESET=>RESET,CTR0=>CTR(0),CTR1=>CTR(1),CTR2=>CTR(2),CTR3=>CTR(3),DOUT_STROBE
		=>DOUT_STROBE,READY=>READY);
END BEHAVIOR;

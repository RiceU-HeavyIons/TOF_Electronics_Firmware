--  C:\AFRESNO\FIRMWARE\LARGEPLD\STATE MACHINES\CTL_ONE.vhd
--  VHDL code created by Xilinx's StateCAD 5.03
--  Fri Dec 24 10:35:51 2004

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are manually optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY CTL_ONE IS
	PORT (CLK,CMD_L0,FIFO_EMPTY,RESET,SEL_EQ_0,SEPARATOR,TIMEOUT: IN std_logic;
		CLR_SEL,CLR_TIMEOUT,CTL_ONE_STUFF,INCR_SEL,RD_FIFO,TRIG_TO_TDC,WR_FIFO : 
			OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF CTL_ONE IS
	TYPE type_sreg IS (L0,STATE0,STATE1,STATE2,STATE3,STATE4,STATE5,STATE6,
		STATE7,STATE8,STATE9,STATE10,STATE11);
	SIGNAL sreg, next_sreg : type_sreg;
BEGIN
	PROCESS (CLK, RESET, next_sreg)
	BEGIN
		IF ( RESET='1' ) THEN
			sreg <= STATE0;
		ELSIF CLK='1' AND CLK'event THEN
			sreg <= next_sreg;
		END IF;
	END PROCESS;

	PROCESS (sreg,CMD_L0,FIFO_EMPTY,SEL_EQ_0,SEPARATOR,TIMEOUT)
	BEGIN
		CLR_SEL <= '0'; CLR_TIMEOUT <= '0'; CTL_ONE_STUFF <= '0'; INCR_SEL <= '0'; 
			RD_FIFO <= '0'; TRIG_TO_TDC <= '0'; WR_FIFO <= '0'; 

		next_sreg<=L0;

		CASE sreg IS
			WHEN L0 =>
				RD_FIFO<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='1';
				CLR_TIMEOUT<='1';
				TRIG_TO_TDC<='1';
				WR_FIFO<='1';
				next_sreg<=STATE5;
			WHEN STATE0 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_SEL<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE1;
			WHEN STATE1 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				IF ( FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE2;
				END IF;
				IF ( FIFO_EMPTY='1' ) THEN
					next_sreg<=STATE1;
				END IF;
			WHEN STATE2 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				INCR_SEL<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				RD_FIFO<='1';
				next_sreg<=STATE3;
			WHEN STATE3 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				IF ( CMD_L0='1' ) THEN
					next_sreg<=L0;
				END IF;
				IF ( CMD_L0='0' ) THEN
					next_sreg<=STATE0;
				END IF;
			WHEN STATE4 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				INCR_SEL<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				RD_FIFO<='1';
				next_sreg<=STATE5;
			WHEN STATE5 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				IF ( TIMEOUT='1' ) THEN
					next_sreg<=STATE7;
				END IF;
				IF ( FIFO_EMPTY='1' ) THEN
					next_sreg<=STATE5;
				END IF;
				IF ( FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE8;
				END IF;
			WHEN STATE6 =>
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				WR_FIFO<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE4;
			WHEN STATE7 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE9;
			WHEN STATE8 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				IF ( SEPARATOR='0' ) THEN
					next_sreg<=STATE6;
				END IF;
				IF ( SEPARATOR='1' ) THEN
					next_sreg<=STATE7;
				END IF;
			WHEN STATE9 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				IF ( SEL_EQ_0='1' ) THEN
					next_sreg<=STATE10;
				END IF;
				IF ( SEL_EQ_0='0' ) THEN
					next_sreg<=STATE5;
				END IF;
			WHEN STATE10 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='1';
				next_sreg<=STATE11;
			WHEN STATE11 =>
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='1';
				WR_FIFO<='1';
				next_sreg<=STATE0;
			WHEN OTHERS =>
		END CASE;
	END PROCESS;
END BEHAVIOR;

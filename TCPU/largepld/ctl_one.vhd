--  F:\JO\TOF\TCPU\COPY OF LARGEPLD\CTL_ONE.vhd
--  VHDL code created by Xilinx's StateCAD 6.2i
--  Wed Mar 29 10:54:09 2006

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are manually optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY CTL_ONE IS
	PORT (CLK,CMD_L0,FIFO_EMPTY,RESET,SEL_EQ_0,SEL_EQ_3,SEPARATOR,TIMEOUT: IN 
		std_logic;
		CLR_SEL,CLR_TIMEOUT,CTL_ONE_STUFF,INCR_SEL,RD_FIFO,STUFF0,STUFF1,
			TRIG_TO_TDC,WR_FIFO : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF CTL_ONE IS
	TYPE type_sreg IS (STATE0,STATE1,STATE2,STATE3,STATE4,STATE5,STATE6,STATE7,
		STATE8,STATE9,STATE10,STATE12,STATE13,STATE14,STATE15,STATE16,STATE17,STATE18
		,STATE19,STATE21,STATE23,STATE27,STATE28,STATE29,STATE30,STATE31,STATE32,
		STATE33,STATE34);
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

	PROCESS (sreg,CMD_L0,FIFO_EMPTY,SEL_EQ_0,SEL_EQ_3,SEPARATOR,TIMEOUT)
	BEGIN
		CLR_SEL <= '0'; CLR_TIMEOUT <= '0'; CTL_ONE_STUFF <= '0'; INCR_SEL <= '0'; 
			RD_FIFO <= '0'; STUFF0 <= '0'; STUFF1 <= '0'; TRIG_TO_TDC <= '0'; WR_FIFO <= 
			'0'; 

		next_sreg<=STATE0;

		CASE sreg IS
			WHEN STATE0 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_SEL<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE1;
			WHEN STATE1 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				IF ( FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE3;
				END IF;
				IF ( FIFO_EMPTY='1' ) THEN
					next_sreg<=STATE1;
				END IF;
			WHEN STATE2 =>
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				WR_FIFO<='1';
				STUFF0<='1';
				STUFF1<='0';
				next_sreg<=STATE10;
			WHEN STATE3 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				IF ( CMD_L0='1' ) THEN
					next_sreg<=STATE21;
				END IF;
				IF ( CMD_L0='0' ) THEN
					next_sreg<=STATE2;
				END IF;
			WHEN STATE4 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				RD_FIFO<='1';
				next_sreg<=STATE5;
			WHEN STATE5 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				IF ( TIMEOUT='1' ) THEN
					next_sreg<=STATE14;
				END IF;
				IF ( TIMEOUT='0' ) THEN
					next_sreg<=STATE12;
				END IF;
			WHEN STATE6 =>
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_SEL<='0';
				WR_FIFO<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE4;
			WHEN STATE7 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				RD_FIFO<='1';
				next_sreg<=STATE15;
			WHEN STATE8 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				IF ( SEPARATOR='0' ) THEN
					next_sreg<=STATE6;
				END IF;
				IF ( SEPARATOR='1' ) THEN
					next_sreg<=STATE31;
				END IF;
			WHEN STATE9 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				IF ( SEL_EQ_0='1' ) THEN
					next_sreg<=STATE27;
				END IF;
				IF ( SEL_EQ_0='0' ) THEN
					next_sreg<=STATE29;
				END IF;
			WHEN STATE10 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				RD_FIFO<='1';
				next_sreg<=STATE27;
			WHEN STATE12 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				IF ( FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE8;
				END IF;
				IF ( FIFO_EMPTY='1' ) THEN
					next_sreg<=STATE5;
				END IF;
			WHEN STATE13 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				CTL_ONE_STUFF<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='1';
				INCR_SEL<='1';
				next_sreg<=STATE9;
			WHEN STATE14 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				CTL_ONE_STUFF<='0';
				CLR_SEL<='0';
				INCR_SEL<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE9;
			WHEN STATE15 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				IF ( TIMEOUT='0' ) THEN
					next_sreg<=STATE16;
				END IF;
				IF ( TIMEOUT='1' ) THEN
					next_sreg<=STATE14;
				END IF;
			WHEN STATE16 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				IF ( FIFO_EMPTY='1' ) THEN
					next_sreg<=STATE15;
				END IF;
				IF ( FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE17;
				END IF;
			WHEN STATE17 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				IF ( SEPARATOR='1' ) THEN
					next_sreg<=STATE32;
				END IF;
				IF ( SEPARATOR='0' ) THEN
					next_sreg<=STATE18;
				END IF;
			WHEN STATE18 =>
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_SEL<='0';
				WR_FIFO<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE19;
			WHEN STATE19 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				RD_FIFO<='1';
				next_sreg<=STATE15;
			WHEN STATE21 =>
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				WR_FIFO<='1';
				TRIG_TO_TDC<='1';
				next_sreg<=STATE34;
			WHEN STATE23 =>
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='1';
				STUFF1<='0';
				STUFF0<='1';
				WR_FIFO<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE28;
			WHEN STATE27 =>
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='1';
				STUFF1<='1';
				STUFF0<='0';
				WR_FIFO<='1';
				next_sreg<=STATE0;
			WHEN STATE28 =>
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='1';
				STUFF0<='1';
				STUFF1<='1';
				WR_FIFO<='1';
				INCR_SEL<='1';
				next_sreg<=STATE5;
			WHEN STATE29 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				IF ( SEL_EQ_3='1' ) THEN
					next_sreg<=STATE30;
				END IF;
				IF ( SEL_EQ_3='0' ) THEN
					next_sreg<=STATE5;
				END IF;
			WHEN STATE30 =>
				TRIG_TO_TDC<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='1';
				STUFF0<='1';
				STUFF1<='1';
				WR_FIFO<='1';
				next_sreg<=STATE5;
			WHEN STATE31 =>
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_SEL<='0';
				WR_FIFO<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE7;
			WHEN STATE32 =>
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				RD_FIFO<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				WR_FIFO<='1';
				next_sreg<=STATE33;
			WHEN STATE33 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				RD_FIFO<='1';
				next_sreg<=STATE13;
			WHEN STATE34 =>
				WR_FIFO<='0';
				TRIG_TO_TDC<='0';
				STUFF1<='0';
				STUFF0<='0';
				INCR_SEL<='0';
				CTL_ONE_STUFF<='0';
				CLR_TIMEOUT<='0';
				CLR_SEL<='0';
				RD_FIFO<='1';
				next_sreg<=STATE23;
			WHEN OTHERS =>
		END CASE;
	END PROCESS;
END BEHAVIOR;

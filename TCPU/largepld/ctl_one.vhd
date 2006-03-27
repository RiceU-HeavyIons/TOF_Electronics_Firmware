--  F:\JO\TOF\TCPU\LARGEPLD\CTL_ONE.vhd
--  VHDL code created by Xilinx's StateCAD 6.2i
--  Mon Mar 27 13:14:53 2006

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are manually optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY CTL_ONE IS
	PORT (CLK,CMD_ABORT,CMD_L0,CMD_L2,FIFO_EMPTY,L2_TIMEOUT,RESET,SEL_EQ_0,
		SEL_EQ_3,SEPARATOR,TIMEOUT: IN std_logic;
		CLR_L2,CLR_SEL,CLR_TIMEOUT,CTL_ONE_STUFF,INCR_SEL,RD_FIFO,STUFF0,STUFF1,
			TRIG_TO_TDC,WR_FIFO,XFER_L2 : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF CTL_ONE IS
	TYPE type_sreg IS (STATE0,STATE1,STATE2,STATE3,STATE4,STATE5,STATE6,STATE7,
		STATE8,STATE9,STATE10,STATE11,STATE12,STATE13,STATE14,STATE15,STATE16,STATE17
		,STATE18,STATE19,STATE20,STATE21,STATE22,STATE23,STATE24,STATE25,STATE26,
		STATE27,STATE28,STATE29,STATE30,STATE31,STATE32,STATE33,STATE34);
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

	PROCESS (sreg,CMD_ABORT,CMD_L0,CMD_L2,FIFO_EMPTY,L2_TIMEOUT,SEL_EQ_0,
		SEL_EQ_3,SEPARATOR,TIMEOUT)
	BEGIN
		CLR_L2 <= '0'; CLR_SEL <= '0'; CLR_TIMEOUT <= '0'; CTL_ONE_STUFF <= '0'; 
			INCR_SEL <= '0'; RD_FIFO <= '0'; STUFF0 <= '0'; STUFF1 <= '0'; TRIG_TO_TDC <=
			 '0'; WR_FIFO <= '0'; XFER_L2 <= '0'; 

		next_sreg<=STATE0;

		CASE sreg IS
			WHEN STATE0 =>
				CLR_L2<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				CLR_SEL<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE1;
			WHEN STATE1 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( FIFO_EMPTY='1' ) THEN
					next_sreg<=STATE1;
				END IF;
				IF ( FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE3;
				END IF;
			WHEN STATE2 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				RD_FIFO<='1';
				next_sreg<=STATE0;
			WHEN STATE3 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( CMD_L0='0' ) THEN
					next_sreg<=STATE2;
				END IF;
				IF ( CMD_L0='1' ) THEN
					next_sreg<=STATE21;
				END IF;
			WHEN STATE4 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				RD_FIFO<='1';
				next_sreg<=STATE5;
			WHEN STATE5 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( TIMEOUT='0' ) THEN
					next_sreg<=STATE12;
				END IF;
				IF ( TIMEOUT='1' ) THEN
					next_sreg<=STATE14;
				END IF;
			WHEN STATE6 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				XFER_L2<='0';
				WR_FIFO<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE4;
			WHEN STATE7 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				RD_FIFO<='1';
				next_sreg<=STATE15;
			WHEN STATE8 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( SEPARATOR='1' ) THEN
					next_sreg<=STATE31;
				END IF;
				IF ( SEPARATOR='0' ) THEN
					next_sreg<=STATE6;
				END IF;
			WHEN STATE9 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( SEL_EQ_0='0' ) THEN
					next_sreg<=STATE29;
				END IF;
				IF ( SEL_EQ_0='1' ) THEN
					next_sreg<=STATE27;
				END IF;
			WHEN STATE10 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE25;
				END IF;
				IF ( FIFO_EMPTY='1' ) THEN
					next_sreg<=STATE22;
				END IF;
			WHEN STATE11 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='1';
				next_sreg<=STATE0;
			WHEN STATE12 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( FIFO_EMPTY='1' ) THEN
					next_sreg<=STATE5;
				END IF;
				IF ( FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE8;
				END IF;
			WHEN STATE13 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				CLR_TIMEOUT<='1';
				INCR_SEL<='1';
				next_sreg<=STATE9;
			WHEN STATE14 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				INCR_SEL<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE9;
			WHEN STATE15 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( TIMEOUT='1' ) THEN
					next_sreg<=STATE14;
				END IF;
				IF ( TIMEOUT='0' ) THEN
					next_sreg<=STATE16;
				END IF;
			WHEN STATE16 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE17;
				END IF;
				IF ( FIFO_EMPTY='1' ) THEN
					next_sreg<=STATE15;
				END IF;
			WHEN STATE17 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( SEPARATOR='0' ) THEN
					next_sreg<=STATE18;
				END IF;
				IF ( SEPARATOR='1' ) THEN
					next_sreg<=STATE32;
				END IF;
			WHEN STATE18 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				XFER_L2<='0';
				WR_FIFO<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE19;
			WHEN STATE19 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				RD_FIFO<='1';
				next_sreg<=STATE15;
			WHEN STATE20 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='1';
				next_sreg<=STATE0;
			WHEN STATE21 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				XFER_L2<='0';
				WR_FIFO<='1';
				TRIG_TO_TDC<='1';
				next_sreg<=STATE34;
			WHEN STATE22 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( L2_TIMEOUT='0' ) THEN
					next_sreg<=STATE10;
				END IF;
				IF ( L2_TIMEOUT='1' ) THEN
					next_sreg<=STATE11;
				END IF;
			WHEN STATE23 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				TRIG_TO_TDC<='0';
				XFER_L2<='0';
				CTL_ONE_STUFF<='1';
				STUFF1<='0';
				STUFF0<='1';
				WR_FIFO<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE28;
			WHEN STATE24 =>
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				CLR_L2<='1';
				RD_FIFO<='1';
				next_sreg<=STATE0;
			WHEN STATE25 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( CMD_ABORT='1' ) THEN
					next_sreg<=STATE24;
				ELSIF ( CMD_L2='1' ) THEN
					next_sreg<=STATE20;
				ELSIF ( CMD_L0='1' ) THEN
					next_sreg<=STATE11;
				 ELSE
					next_sreg<=STATE26;
				END IF;
			WHEN STATE26 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				RD_FIFO<='1';
				next_sreg<=STATE10;
			WHEN STATE27 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				TRIG_TO_TDC<='0';
				XFER_L2<='0';
				CTL_ONE_STUFF<='1';
				STUFF1<='1';
				STUFF0<='0';
				WR_FIFO<='1';
				next_sreg<=STATE10;
			WHEN STATE28 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				RD_FIFO<='0';
				TRIG_TO_TDC<='0';
				XFER_L2<='0';
				CTL_ONE_STUFF<='1';
				STUFF0<='1';
				STUFF1<='1';
				WR_FIFO<='1';
				INCR_SEL<='1';
				next_sreg<=STATE5;
			WHEN STATE29 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				IF ( SEL_EQ_3='0' ) THEN
					next_sreg<=STATE5;
				END IF;
				IF ( SEL_EQ_3='1' ) THEN
					next_sreg<=STATE30;
				END IF;
			WHEN STATE30 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				TRIG_TO_TDC<='0';
				XFER_L2<='0';
				CTL_ONE_STUFF<='1';
				STUFF0<='1';
				STUFF1<='1';
				WR_FIFO<='1';
				next_sreg<=STATE5;
			WHEN STATE31 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				XFER_L2<='0';
				WR_FIFO<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE7;
			WHEN STATE32 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				XFER_L2<='0';
				WR_FIFO<='1';
				next_sreg<=STATE33;
			WHEN STATE33 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				RD_FIFO<='1';
				next_sreg<=STATE13;
			WHEN STATE34 =>
				CLR_L2<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				CTL_ONE_STUFF<='0';
				INCR_SEL<='0';
				STUFF0<='0';
				STUFF1<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				XFER_L2<='0';
				RD_FIFO<='1';
				next_sreg<=STATE23;
			WHEN OTHERS =>
		END CASE;
	END PROCESS;
END BEHAVIOR;

--  C:\AFRESNO\FIRMWARE\LARGEPLD\STATE MACHINES\CTLV1.vhd
--  VHDL code created by Xilinx's StateCAD 5.03
--  Wed Oct 27 17:29:55 2004

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are manually optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY CTLV1 IS
	PORT (CLK,CMD_ABORT,CMD_IGNORE,CMD_L0,CMD_L2,CMD_RESET,FIFO_EMPTY,OPMODE1,
		RESET,SEL_EQ_0,SEPARATOR,TIMEOUT,TRIG_EQ_TOKEN: IN std_logic;
		CLR_FIFO_OUT,CLR_INFIFO,CLR_OUTFIFO,CLR_SEL,CLR_TDC,CLR_TIMEOUT,CLR_TOGGLE,
			CLR_TOKEN,ERROR2,INCR_SEL,RD_FIFO,SW_DDL_FIFO,TRIG_TO_TDC,WR_DDL,WR_FIFO,
			WR_L2_REG,WR_MCU,WR_MCU_ERROR,WR_MCU_FIFO : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF CTLV1 IS
	TYPE type_sreg IS (ABORT,ABORT_ERROR,ABORT_PROCESS,L0,L2,L2_ERROR,L2_PROCESS
		,RESET_STATE,STATE0,STATE1,STATE2,STATE3,STATE5,STATE6,STATE7,STATE8,STATE9,
		STATE14);
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

	PROCESS (sreg,CMD_ABORT,CMD_IGNORE,CMD_L0,CMD_L2,CMD_RESET,FIFO_EMPTY,
		OPMODE1,SEL_EQ_0,SEPARATOR,TIMEOUT,TRIG_EQ_TOKEN)
	BEGIN
		CLR_FIFO_OUT <= '0'; CLR_INFIFO <= '0'; CLR_OUTFIFO <= '0'; CLR_SEL <= '0';
			 CLR_TDC <= '0'; CLR_TIMEOUT <= '0'; CLR_TOGGLE <= '0'; CLR_TOKEN <= '0'; 
			ERROR2 <= '0'; INCR_SEL <= '0'; RD_FIFO <= '0'; SW_DDL_FIFO <= '0'; 
			TRIG_TO_TDC <= '0'; WR_DDL <= '0'; WR_FIFO <= '0'; WR_L2_REG <= '0'; WR_MCU 
			<= '0'; WR_MCU_ERROR <= '0'; WR_MCU_FIFO <= '0'; 

		next_sreg<=ABORT;

		CASE sreg IS
			WHEN ABORT =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				IF ( TRIG_EQ_TOKEN='1' ) THEN
					next_sreg<=ABORT_PROCESS;
				END IF;
				IF ( TRIG_EQ_TOKEN='0' ) THEN
					next_sreg<=ABORT_ERROR;
				END IF;
			WHEN ABORT_ERROR =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_FIFO<='0';
				WR_MCU_ERROR<='1';
				next_sreg<=STATE14;
			WHEN ABORT_PROCESS =>
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				WR_MCU<='1';
				CLR_FIFO_OUT<='1';
				CLR_TOKEN<='1';
				next_sreg<=STATE14;
			WHEN L0 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				INCR_SEL<='1';
				CLR_TIMEOUT<='1';
				TRIG_TO_TDC<='1';
				next_sreg<=STATE5;
			WHEN L2 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				IF ( TRIG_EQ_TOKEN='1' ) THEN
					next_sreg<=L2_PROCESS;
				END IF;
				IF ( TRIG_EQ_TOKEN='0' ) THEN
					next_sreg<=L2_ERROR;
				END IF;
			WHEN L2_ERROR =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				ERROR2<='1';
				WR_MCU<='1';
				next_sreg<=STATE14;
			WHEN L2_PROCESS =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_FIFO<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				WR_MCU<='1';
				WR_DDL<='1';
				WR_L2_REG<='1';
				SW_DDL_FIFO<='1';
				next_sreg<=STATE14;
			WHEN RESET_STATE =>
				CLR_FIFO_OUT<='0';
				CLR_SEL<='0';
				CLR_TIMEOUT<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='1';
				CLR_TOKEN<='1';
				CLR_INFIFO<='1';
				CLR_OUTFIFO<='1';
				CLR_TOGGLE<='1';
				CLR_TDC<='1';
				next_sreg<=STATE14;
			WHEN STATE0 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_TDC<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				CLR_SEL<='1';
				CLR_TIMEOUT<='1';
				IF ( OPMODE1='1' ) THEN
					next_sreg<=STATE1;
				 ELSE
					next_sreg<=STATE0;
				END IF;
			WHEN STATE1 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				IF ( FIFO_EMPTY='1' ) THEN
					next_sreg<=STATE1;
				END IF;
				IF ( FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE2;
				END IF;
			WHEN STATE2 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				RD_FIFO<='1';
				next_sreg<=STATE3;
			WHEN STATE3 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				IF ( CMD_IGNORE='0' AND CMD_L0='0' AND CMD_RESET='0' AND CMD_ABORT='0' 
					AND CMD_L2='0' ) THEN
					next_sreg<=STATE3;
				END IF;
				IF ( CMD_IGNORE='1' ) THEN
					next_sreg<=STATE14;
				END IF;
				IF ( CMD_L0='1' ) THEN
					next_sreg<=L0;
				END IF;
				IF ( CMD_RESET='1' ) THEN
					next_sreg<=RESET_STATE;
				END IF;
				IF ( CMD_ABORT='1' ) THEN
					next_sreg<=ABORT;
				END IF;
				IF ( CMD_L2='1' ) THEN
					next_sreg<=L2;
				END IF;
			WHEN STATE5 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				IF ( FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE8;
				END IF;
				IF ( FIFO_EMPTY='1' ) THEN
					next_sreg<=STATE5;
				END IF;
				IF ( TIMEOUT='1' ) THEN
					next_sreg<=STATE7;
				END IF;
			WHEN STATE6 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				RD_FIFO<='1';
				WR_FIFO<='1';
				next_sreg<=STATE5;
			WHEN STATE7 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				RD_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				INCR_SEL<='1';
				CLR_TIMEOUT<='1';
				SW_DDL_FIFO<='1';
				next_sreg<=STATE9;
			WHEN STATE8 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				IF ( SEPARATOR='1' ) THEN
					next_sreg<=STATE7;
				END IF;
				IF ( SEPARATOR='0' ) THEN
					next_sreg<=STATE6;
				END IF;
			WHEN STATE9 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				IF ( SEL_EQ_0='0' ) THEN
					next_sreg<=STATE5;
				END IF;
				IF ( SEL_EQ_0='1' ) THEN
					next_sreg<=STATE0;
				END IF;
			WHEN STATE14 =>
				CLR_FIFO_OUT<='0';
				CLR_INFIFO<='0';
				CLR_OUTFIFO<='0';
				CLR_SEL<='0';
				CLR_TDC<='0';
				CLR_TIMEOUT<='0';
				CLR_TOGGLE<='0';
				CLR_TOKEN<='0';
				ERROR2<='0';
				INCR_SEL<='0';
				RD_FIFO<='0';
				SW_DDL_FIFO<='0';
				TRIG_TO_TDC<='0';
				WR_DDL<='0';
				WR_FIFO<='0';
				WR_L2_REG<='0';
				WR_MCU<='0';
				WR_MCU_ERROR<='0';
				WR_MCU_FIFO<='0';
				next_sreg<=STATE0;
			WHEN OTHERS =>
		END CASE;
	END PROCESS;
END BEHAVIOR;

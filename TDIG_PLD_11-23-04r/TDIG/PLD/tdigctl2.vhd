--  C:\AFRESNO\FIRMWARE\LARGEPLD\STATE MACHINES\TDIGCTL2.vhd
--  VHDL code created by Xilinx's StateCAD 5.03
--  Fri Oct 29 11:31:29 2004

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are area optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY TDIGCTL2 IS
	PORT (CLK,DATA_ENABLE,FIFO_DS_EMPTY,OUTPUT_BUSY,POS_DNSTRM,RESET,SEPARATOR,
		TDC_FIFO_EMPTY,TIMEOUT,TRIGGER_PULSE: IN std_logic;
		CLR_TIMEOUT,EN_TDC_RDO,RD_DS_FIFO,RD_TDC_FIFO,SEL_DS_FIFO,WR_OUTPUT : OUT 
			std_logic);
END;

ARCHITECTURE BEHAVIOR OF TDIGCTL2 IS
	TYPE type_sreg IS (STATE0,STATE1,STATE2,STATE3,STATE4,STATE5,STATE6,STATE7,
		STATE8,STATE9,STATE10,STATE11,STATE12,STATE13,STATE14);
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

	PROCESS (sreg,DATA_ENABLE,FIFO_DS_EMPTY,OUTPUT_BUSY,POS_DNSTRM,SEPARATOR,
		TDC_FIFO_EMPTY,TIMEOUT,TRIGGER_PULSE)
	BEGIN
		CLR_TIMEOUT <= '0'; EN_TDC_RDO <= '0'; RD_DS_FIFO <= '0'; RD_TDC_FIFO <= 
			'0'; SEL_DS_FIFO <= '0'; WR_OUTPUT <= '0'; 

		next_sreg<=STATE0;

		CASE sreg IS
			WHEN STATE0 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				SEL_DS_FIFO<='0';
				WR_OUTPUT<='0';
				IF ( DATA_ENABLE='1' ) THEN
					next_sreg<=STATE1;
				 ELSE
					next_sreg<=STATE0;
				END IF;
			WHEN STATE1 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				SEL_DS_FIFO<='0';
				WR_OUTPUT<='0';
				IF ( TRIGGER_PULSE='1' ) THEN
					next_sreg<=STATE3;
				END IF;
				IF ( TRIGGER_PULSE='0' ) THEN
					next_sreg<=STATE1;
				END IF;
			WHEN STATE2 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				WR_OUTPUT<='0';
				SEL_DS_FIFO<='1';
				IF ( FIFO_DS_EMPTY='1' ) THEN
					next_sreg<=STATE14;
				END IF;
				IF ( FIFO_DS_EMPTY='0' ) THEN
					next_sreg<=STATE4;
				END IF;
			WHEN STATE3 =>
				CLR_TIMEOUT<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				SEL_DS_FIFO<='0';
				WR_OUTPUT<='0';
				EN_TDC_RDO<='1';
				next_sreg<=STATE5;
			WHEN STATE4 =>
				EN_TDC_RDO<='0';
				RD_TDC_FIFO<='0';
				WR_OUTPUT<='0';
				SEL_DS_FIFO<='1';
				RD_DS_FIFO<='1';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE6;
			WHEN STATE5 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				SEL_DS_FIFO<='0';
				WR_OUTPUT<='0';
				IF ( TDC_FIFO_EMPTY='0' ) THEN
					next_sreg<=STATE7;
				 ELSE
					next_sreg<=STATE5;
				END IF;
			WHEN STATE6 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				WR_OUTPUT<='0';
				SEL_DS_FIFO<='1';
				IF ( OUTPUT_BUSY='0' ) THEN
					next_sreg<=STATE9;
				 ELSE
					next_sreg<=STATE6;
				END IF;
			WHEN STATE7 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				SEL_DS_FIFO<='0';
				WR_OUTPUT<='0';
				RD_TDC_FIFO<='1';
				next_sreg<=STATE8;
			WHEN STATE8 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				SEL_DS_FIFO<='0';
				WR_OUTPUT<='0';
				IF ( OUTPUT_BUSY='0' ) THEN
					next_sreg<=STATE11;
				END IF;
				IF ( OUTPUT_BUSY='1' ) THEN
					next_sreg<=STATE8;
				END IF;
			WHEN STATE9 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				SEL_DS_FIFO<='1';
				WR_OUTPUT<='1';
				next_sreg<=STATE10;
			WHEN STATE10 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				WR_OUTPUT<='0';
				SEL_DS_FIFO<='1';
				IF ( SEPARATOR='0' ) THEN
					next_sreg<=STATE14;
				END IF;
				IF ( SEPARATOR='1' ) THEN
					next_sreg<=STATE0;
				END IF;
			WHEN STATE11 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				SEL_DS_FIFO<='0';
				WR_OUTPUT<='1';
				IF ( SEPARATOR='1' ) THEN
					next_sreg<=STATE12;
				END IF;
				IF ( SEPARATOR='0' ) THEN
					next_sreg<=STATE5;
				END IF;
			WHEN STATE12 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				SEL_DS_FIFO<='0';
				WR_OUTPUT<='0';
				IF ( POS_DNSTRM='0' ) THEN
					next_sreg<=STATE13;
				END IF;
				IF ( POS_DNSTRM='1' ) THEN
					next_sreg<=STATE0;
				END IF;
			WHEN STATE13 =>
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				SEL_DS_FIFO<='0';
				WR_OUTPUT<='0';
				CLR_TIMEOUT<='1';
				next_sreg<=STATE14;
			WHEN STATE14 =>
				CLR_TIMEOUT<='0';
				EN_TDC_RDO<='0';
				RD_DS_FIFO<='0';
				RD_TDC_FIFO<='0';
				SEL_DS_FIFO<='0';
				WR_OUTPUT<='0';
				IF ( TIMEOUT='1' ) THEN
					next_sreg<=STATE0;
				END IF;
				IF ( TIMEOUT='0' ) THEN
					next_sreg<=STATE2;
				END IF;
			WHEN OTHERS =>
		END CASE;
	END PROCESS;
END BEHAVIOR;

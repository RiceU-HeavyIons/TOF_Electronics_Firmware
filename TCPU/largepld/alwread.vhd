--  C:\AFRESNO\FIRMWARE\LARGEPLD\NOV_15_TCPU\ALWREAD.vhd
--  VHDL code created by Xilinx's StateCAD 5.03
--  Tue Nov 16 15:40:10 2004

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are area optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ALWREAD IS
	PORT (CLK,empty,RESET: IN std_logic;
		incr_cnt,rd_fifo,wr_fifo : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF ALWREAD IS
	TYPE type_sreg IS (STATE0,STATE1,STATE2,STATE3,STATE4,STATE5);
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

	PROCESS (sreg,empty)
	BEGIN
		incr_cnt <= '0'; rd_fifo <= '0'; wr_fifo <= '0'; 

		next_sreg<=STATE0;

		CASE sreg IS
			WHEN STATE0 =>
				incr_cnt<='0';
				rd_fifo<='0';
				wr_fifo<='0';
				next_sreg<=STATE1;
			WHEN STATE1 =>
				incr_cnt<='0';
				rd_fifo<='0';
				wr_fifo<='0';
				IF ( empty='1' ) THEN
					next_sreg<=STATE1;
				END IF;
				IF ( empty='0' ) THEN
					next_sreg<=STATE4;
				END IF;
			WHEN STATE2 =>
				incr_cnt<='0';
				rd_fifo<='0';
				wr_fifo<='1';
				next_sreg<=STATE3;
			WHEN STATE3 =>
				incr_cnt<='0';
				wr_fifo<='0';
				rd_fifo<='1';
				next_sreg<=STATE0;
			WHEN STATE4 =>
				rd_fifo<='0';
				wr_fifo<='0';
				incr_cnt<='1';
				next_sreg<=STATE5;
			WHEN STATE5 =>
				incr_cnt<='0';
				rd_fifo<='0';
				wr_fifo<='0';
				next_sreg<=STATE2;
			WHEN OTHERS =>
		END CASE;
	END PROCESS;
END BEHAVIOR;

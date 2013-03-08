--  C:\AFRESNO\FIRMWARE\LARGEPLD\STATE MACHINES\MCU_BOSS.vhd
--  VHDL code created by Xilinx's StateCAD 5.03
--  Tue Nov 02 21:43:40 2004

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are area optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY MCU_BOSS IS
	PORT (CLK,mcu_boss_enable,read_strobe,RESET: IN std_logic;
		rd_fifo,wr_fifo : OUT std_logic);
END;

ARCHITECTURE BEHAVIOR OF MCU_BOSS IS
	TYPE type_sreg IS (STATE0,STATE1,STATE2,STATE3);
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

	PROCESS (sreg,mcu_boss_enable,read_strobe)
	BEGIN
		rd_fifo <= '0'; wr_fifo <= '0'; 

		next_sreg<=STATE0;

		CASE sreg IS
			WHEN STATE0 =>
				wr_fifo<='0';
				rd_fifo<='0';
				IF ( mcu_boss_enable='1' ) THEN
					next_sreg<=STATE1;
				END IF;
				IF ( mcu_boss_enable='0' ) THEN
					next_sreg<=STATE0;
				END IF;
			WHEN STATE1 =>
				wr_fifo<='0';
				rd_fifo<='0';
				IF ( read_strobe='1' ) THEN
					next_sreg<=STATE2;
				END IF;
				IF ( read_strobe='0' ) THEN
					next_sreg<=STATE1;
				END IF;
			WHEN STATE2 =>
				wr_fifo<='0';
				rd_fifo<='0';
				IF ( read_strobe='1' ) THEN
					next_sreg<=STATE2;
				END IF;
				IF ( read_strobe='0' ) THEN
					next_sreg<=STATE3;
				END IF;
			WHEN STATE3 =>
				wr_fifo<='1';
				rd_fifo<='1';
				next_sreg<=STATE0;
			WHEN OTHERS =>
		END CASE;
	END PROCESS;
END BEHAVIOR;

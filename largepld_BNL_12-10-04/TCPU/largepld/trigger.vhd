--  C:\AFRESNO\FIRMWARE\LARGEPLD\STATE_MACHINES\TRIGGER.vhd
--  VHDL code created by Xilinx's StateCAD 5.03
--  Sat Sep 04 18:53:31 2004

--  This VHDL code (for use with Synopsys) was generated using: 
--  one-hot state assignment with boolean code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are speed optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY synopsys;
USE synopsys.attributes.all;

ENTITY TRIGGER IS
	PORT (CLK,ABORT,LEVEL0,LEVEL2_ACCEPT: IN std_logic);
END;

ARCHITECTURE BEHAVIOR OF TRIGGER IS
--	State variables for machine sreg
	SIGNAL ACQUIRE, next_ACQUIRE, BUFFER_DATA, next_BUFFER_DATA, BUILD_EVENT, 
		next_BUILD_EVENT, XMIT_TO_DAQ, next_XMIT_TO_DAQ : std_logic;
BEGIN
	PROCESS (CLK, next_ACQUIRE, next_BUFFER_DATA, next_BUILD_EVENT, 
		next_XMIT_TO_DAQ)
	BEGIN
		IF CLK='1' AND CLK'event THEN
			ACQUIRE <= next_ACQUIRE;
			BUFFER_DATA <= next_BUFFER_DATA;
			BUILD_EVENT <= next_BUILD_EVENT;
			XMIT_TO_DAQ <= next_XMIT_TO_DAQ;
		END IF;
	END PROCESS;

	PROCESS (ABORT,ACQUIRE,BUFFER_DATA,BUILD_EVENT,LEVEL0,LEVEL2_ACCEPT,
		XMIT_TO_DAQ)
	BEGIN

		IF (( LEVEL0='0' AND  (ACQUIRE='1')) OR ( ABORT='1' AND  (BUFFER_DATA='1'))
			) THEN next_ACQUIRE<='1';
		ELSE next_ACQUIRE<='0';
		END IF;

		IF (( ABORT='0' AND LEVEL2_ACCEPT='0' AND  (BUFFER_DATA='1')) OR (  (
			BUILD_EVENT='1'))) THEN next_BUFFER_DATA<='1';
		ELSE next_BUFFER_DATA<='0';
		END IF;

		IF (( LEVEL0='1' AND  (ACQUIRE='1'))) THEN next_BUILD_EVENT<='1';
		ELSE next_BUILD_EVENT<='0';
		END IF;

		IF (( LEVEL2_ACCEPT='1' AND  (BUFFER_DATA='1')) OR (  (XMIT_TO_DAQ='1'))) 
			THEN next_XMIT_TO_DAQ<='1';
		ELSE next_XMIT_TO_DAQ<='0';
		END IF;

	END PROCESS;
END BEHAVIOR;

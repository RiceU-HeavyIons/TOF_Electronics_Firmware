-- $Id: timer.vhd,v 1.1.1.1 2004-12-03 19:29:46 tofp Exp $
--*************************************************************************
--*  timer.VHD : Timer module for generating test triggers.
--*
--*
--*  REVISION HISTORY:
--*    10-Nov-2004 JS  Original coding
--*
--*************************************************************************


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY altera;
USE altera.maxplus2.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;

--  Entity Declaration
ENTITY timer IS
	GENERIC (CTR_WIDTH: positive:=17);
	PORT
	(
		clk 	: IN 	std_logic;
		trigger	: OUT	std_logic
	);
END timer;

-- Architecture body
ARCHITECTURE ver1 OF timer IS
 	CONSTANT MAX_CNT	 : std_logic_vector (CTR_WIDTH-1 DOWNTO 0) := (OTHERS => '1');
	SIGNAL s_ctr	 	 : std_logic_vector (CTR_WIDTH-1 DOWNTO 0);

-- ****************************************************************
-- ARCHITECTURE BEGINS HERE
-- ****************************************************************
BEGIN		

	counter_inst: COMPONENT lpm_counter
	  GENERIC MAP (
		LPM_WIDTH		=> CTR_WIDTH,
		lpm_type 		=> "LPM_COUNTER",
		LPM_DIRECTION	=> "UP"
	  )
	  PORT MAP (
		clock	=> clk,
		q		=> s_ctr
	);

	trigger <= '1' WHEN (s_ctr = MAX_CNT) ELSE '0';

END ver1;

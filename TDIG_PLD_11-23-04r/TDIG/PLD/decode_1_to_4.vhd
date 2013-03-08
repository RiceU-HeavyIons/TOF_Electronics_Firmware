-- megafunction wizard: %LPM_DECODE%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: lpm_decode 

-- ============================================================
-- File Name: decode_1_to_4.vhd
-- Megafunction Name(s):
-- 			lpm_decode
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 4.1 Build 208 09/10/2004 SP 2 SJ Full Version
-- ************************************************************


--Copyright (C) 1991-2004 Altera Corporation
--Any  megafunction  design,  and related netlist (encrypted  or  decrypted),
--support information,  device programming or simulation file,  and any other
--associated  documentation or information  provided by  Altera  or a partner
--under  Altera's   Megafunction   Partnership   Program  may  be  used  only
--to program  PLD  devices (but not masked  PLD  devices) from  Altera.   Any
--other  use  of such  megafunction  design,  netlist,  support  information,
--device programming or simulation file,  or any other  related documentation
--or information  is prohibited  for  any  other purpose,  including, but not
--limited to  modification,  reverse engineering,  de-compiling, or use  with
--any other  silicon devices,  unless such use is  explicitly  licensed under
--a separate agreement with  Altera  or a megafunction partner.  Title to the
--intellectual property,  including patents,  copyrights,  trademarks,  trade
--secrets,  or maskworks,  embodied in any such megafunction design, netlist,
--support  information,  device programming or simulation file,  or any other
--related documentation or information provided by  Altera  or a megafunction
--partner, remains with Altera, the megafunction partner, or their respective
--licensors. No other licenses, including any licenses needed under any third
--party's intellectual property, are provided herein.


LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY lpm;
USE lpm.lpm_components.all;

ENTITY decode_1_to_4 IS
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
		eq0		: OUT STD_LOGIC ;
		eq1		: OUT STD_LOGIC ;
		eq2		: OUT STD_LOGIC ;
		eq3		: OUT STD_LOGIC 
	);
END decode_1_to_4;


ARCHITECTURE SYN OF decode_1_to_4 IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (3 DOWNTO 0);
	SIGNAL sub_wire1	: STD_LOGIC ;
	SIGNAL sub_wire2	: STD_LOGIC ;
	SIGNAL sub_wire3	: STD_LOGIC ;
	SIGNAL sub_wire4	: STD_LOGIC ;



	COMPONENT lpm_decode
	GENERIC (
		lpm_width		: NATURAL;
		lpm_decodes		: NATURAL;
		lpm_type		: STRING
	);
	PORT (
			eq	: OUT STD_LOGIC_VECTOR (lpm_decodes-1 DOWNTO 0);
			data	: IN STD_LOGIC_VECTOR (1 DOWNTO 0)
	);
	END COMPONENT;

BEGIN
	sub_wire4    <= sub_wire0(3);
	sub_wire3    <= sub_wire0(2);
	sub_wire2    <= sub_wire0(1);
	sub_wire1    <= sub_wire0(0);
	eq0    <= sub_wire1;
	eq1    <= sub_wire2;
	eq2    <= sub_wire3;
	eq3    <= sub_wire4;

	lpm_decode_component : lpm_decode
	GENERIC MAP (
		lpm_width => 2,
		lpm_decodes => 4,
		lpm_type => "LPM_DECODE"
	)
	PORT MAP (
		data => data,
		eq => sub_wire0
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: nBit NUMERIC "2"
-- Retrieval info: PRIVATE: EnableInput NUMERIC "0"
-- Retrieval info: PRIVATE: BaseDec NUMERIC "1"
-- Retrieval info: PRIVATE: eq0 NUMERIC "1"
-- Retrieval info: PRIVATE: eq1 NUMERIC "1"
-- Retrieval info: PRIVATE: eq2 NUMERIC "1"
-- Retrieval info: PRIVATE: eq3 NUMERIC "1"
-- Retrieval info: PRIVATE: Latency NUMERIC "0"
-- Retrieval info: PRIVATE: aclr NUMERIC "0"
-- Retrieval info: PRIVATE: clken NUMERIC "0"
-- Retrieval info: PRIVATE: LPM_PIPELINE NUMERIC "0"
-- Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "2"
-- Retrieval info: CONSTANT: LPM_DECODES NUMERIC "4"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_DECODE"
-- Retrieval info: USED_PORT: data 0 0 2 0 INPUT NODEFVAL data[1..0]
-- Retrieval info: USED_PORT: eq0 0 0 0 0 OUTPUT NODEFVAL eq0
-- Retrieval info: USED_PORT: eq1 0 0 0 0 OUTPUT NODEFVAL eq1
-- Retrieval info: USED_PORT: eq2 0 0 0 0 OUTPUT NODEFVAL eq2
-- Retrieval info: USED_PORT: eq3 0 0 0 0 OUTPUT NODEFVAL eq3
-- Retrieval info: USED_PORT: @eq 0 0 LPM_DECODES 0 OUTPUT NODEFVAL @eq[LPM_DECODES-1..0]
-- Retrieval info: CONNECT: @data 0 0 2 0 data 0 0 2 0
-- Retrieval info: CONNECT: eq0 0 0 0 0 @eq 0 0 1 0
-- Retrieval info: CONNECT: eq1 0 0 0 0 @eq 0 0 1 1
-- Retrieval info: CONNECT: eq2 0 0 0 0 @eq 0 0 1 2
-- Retrieval info: CONNECT: eq3 0 0 0 0 @eq 0 0 1 3
-- Retrieval info: LIBRARY: lpm lpm.lpm_components.all
-- Retrieval info: GEN_FILE: TYPE_NORMAL decode_1_to_4.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL decode_1_to_4.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL decode_1_to_4.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL decode_1_to_4.bsf FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL decode_1_to_4_inst.vhd TRUE

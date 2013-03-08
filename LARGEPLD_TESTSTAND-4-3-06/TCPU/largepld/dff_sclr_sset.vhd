-- megafunction wizard: %LPM_FF%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: lpm_ff 

-- ============================================================
-- File Name: dff_sclr_sset.vhd
-- Megafunction Name(s):
-- 			lpm_ff
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 4.1 Build 181 06/29/2004 SJ Full Version
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

ENTITY dff_sclr_sset IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		sset		: IN STD_LOGIC ;
		data		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC 
	);
END dff_sclr_sset;


ARCHITECTURE SYN OF dff_sclr_sset IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (0 DOWNTO 0);
	SIGNAL sub_wire1	: STD_LOGIC ;
	SIGNAL sub_wire2	: STD_LOGIC ;
	SIGNAL sub_wire3	: STD_LOGIC_VECTOR (0 DOWNTO 0);



	COMPONENT lpm_ff
	GENERIC (
		lpm_width		: NATURAL;
		lpm_type		: STRING;
		lpm_fftype		: STRING
	);
	PORT (
			sclr	: IN STD_LOGIC ;
			clock	: IN STD_LOGIC ;
			q	: OUT STD_LOGIC_VECTOR (0 DOWNTO 0);
			data	: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
			sset	: IN STD_LOGIC 
	);
	END COMPONENT;

BEGIN
	sub_wire1    <= sub_wire0(0);
	q    <= sub_wire1;
	sub_wire2    <= data;
	sub_wire3(0)    <= sub_wire2;

	lpm_ff_component : lpm_ff
	GENERIC MAP (
		lpm_width => 1,
		lpm_type => "LPM_FF",
		lpm_fftype => "DFF"
	)
	PORT MAP (
		sclr => sclr,
		clock => clock,
		data => sub_wire3,
		sset => sset,
		q => sub_wire0
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: nBit NUMERIC "1"
-- Retrieval info: PRIVATE: CLK_EN NUMERIC "0"
-- Retrieval info: PRIVATE: DFF NUMERIC "1"
-- Retrieval info: PRIVATE: UseTFFdataPort NUMERIC "0"
-- Retrieval info: PRIVATE: SCLR NUMERIC "1"
-- Retrieval info: PRIVATE: SLOAD NUMERIC "0"
-- Retrieval info: PRIVATE: SSET NUMERIC "1"
-- Retrieval info: PRIVATE: SSET_ALL1 NUMERIC "1"
-- Retrieval info: PRIVATE: SSETV NUMERIC "0"
-- Retrieval info: PRIVATE: ACLR NUMERIC "0"
-- Retrieval info: PRIVATE: ALOAD NUMERIC "0"
-- Retrieval info: PRIVATE: ASET NUMERIC "0"
-- Retrieval info: PRIVATE: ASET_ALL1 NUMERIC "1"
-- Retrieval info: PRIVATE: ASETV NUMERIC "0"
-- Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "1"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_FF"
-- Retrieval info: CONSTANT: LPM_FFTYPE STRING "DFF"
-- Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
-- Retrieval info: USED_PORT: q 0 0 0 0 OUTPUT NODEFVAL q
-- Retrieval info: USED_PORT: sclr 0 0 0 0 INPUT NODEFVAL sclr
-- Retrieval info: USED_PORT: sset 0 0 0 0 INPUT NODEFVAL sset
-- Retrieval info: USED_PORT: data 0 0 0 0 INPUT NODEFVAL data
-- Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
-- Retrieval info: CONNECT: q 0 0 0 0 @q 0 0 1 0
-- Retrieval info: CONNECT: @sclr 0 0 0 0 sclr 0 0 0 0
-- Retrieval info: CONNECT: @sset 0 0 0 0 sset 0 0 0 0
-- Retrieval info: CONNECT: @data 0 0 1 0 data 0 0 0 0
-- Retrieval info: LIBRARY: lpm lpm.lpm_components.all
-- Retrieval info: GEN_FILE: TYPE_NORMAL dff_sclr_sset.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL dff_sclr_sset.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL dff_sclr_sset.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL dff_sclr_sset.bsf TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL dff_sclr_sset_inst.vhd TRUE

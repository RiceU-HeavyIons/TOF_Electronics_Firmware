-- megafunction wizard: %ALTDDIO_IN%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: ALTDDIO_IN 

-- ============================================================
-- File Name: ddio_in.vhd
-- Megafunction Name(s):
-- 			ALTDDIO_IN
--
-- Simulation Library Files(s):
-- 			altera_mf
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 10.1 Build 197 01/19/2011 SP 1 SJ Full Version
-- ************************************************************


--Copyright (C) 1991-2011 Altera Corporation
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, Altera MegaCore Function License 
--Agreement, or other applicable license agreement, including, 
--without limitation, that your use is for the sole purpose of 
--programming logic devices manufactured by Altera and sold by 
--Altera or its authorized distributors.  Please refer to the 
--applicable agreement for further details.


LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY ddio_in IS
	PORT
	(
		datain		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		inclock		: IN STD_LOGIC ;
		dataout_h		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		dataout_l		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END ddio_in;


ARCHITECTURE SYN OF ddio_in IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL sub_wire1	: STD_LOGIC_VECTOR (7 DOWNTO 0);

BEGIN
	dataout_h    <= sub_wire0(7 DOWNTO 0);
	dataout_l    <= sub_wire1(7 DOWNTO 0);

	ALTDDIO_IN_component : ALTDDIO_IN
	GENERIC MAP (
		intended_device_family => "Cyclone II",
		invert_input_clocks => "OFF",
		lpm_hint => "UNUSED",
		lpm_type => "altddio_in",
		power_up_high => "OFF",
		width => 8
	)
	PORT MAP (
		datain => datain,
		inclock => inclock,
		dataout_h => sub_wire0,
		dataout_l => sub_wire1
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone II"
-- Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Cyclone II"
-- Retrieval info: CONSTANT: INVERT_INPUT_CLOCKS STRING "OFF"
-- Retrieval info: CONSTANT: LPM_HINT STRING "UNUSED"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "altddio_in"
-- Retrieval info: CONSTANT: POWER_UP_HIGH STRING "OFF"
-- Retrieval info: CONSTANT: WIDTH NUMERIC "8"
-- Retrieval info: USED_PORT: datain 0 0 8 0 INPUT NODEFVAL "datain[7..0]"
-- Retrieval info: CONNECT: @datain 0 0 8 0 datain 0 0 8 0
-- Retrieval info: USED_PORT: dataout_h 0 0 8 0 OUTPUT NODEFVAL "dataout_h[7..0]"
-- Retrieval info: CONNECT: dataout_h 0 0 8 0 @dataout_h 0 0 8 0
-- Retrieval info: USED_PORT: dataout_l 0 0 8 0 OUTPUT NODEFVAL "dataout_l[7..0]"
-- Retrieval info: CONNECT: dataout_l 0 0 8 0 @dataout_l 0 0 8 0
-- Retrieval info: USED_PORT: inclock 0 0 0 0 INPUT_CLK_EXT NODEFVAL "inclock"
-- Retrieval info: CONNECT: @inclock 0 0 0 0 inclock 0 0 0 0
-- Retrieval info: GEN_FILE: TYPE_NORMAL ddio_in.vhd TRUE FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL ddio_in.qip TRUE FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL ddio_in.bsf FALSE TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL ddio_in_inst.vhd FALSE TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL ddio_in.inc FALSE TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL ddio_in.cmp FALSE TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL ddio_in.ppf TRUE FALSE
-- Retrieval info: LIB_FILE: altera_mf

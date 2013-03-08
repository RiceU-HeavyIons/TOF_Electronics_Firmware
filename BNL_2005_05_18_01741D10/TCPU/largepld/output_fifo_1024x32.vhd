-- megafunction wizard: %FIFO%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: scfifo 

-- ============================================================
-- File Name: output_fifo_1024x32.vhd
-- Megafunction Name(s):
-- 			scfifo
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

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY output_fifo_1024x32 IS
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		wrreq		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		aclr		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		full		: OUT STD_LOGIC ;
		empty		: OUT STD_LOGIC 
	);
END output_fifo_1024x32;


ARCHITECTURE SYN OF output_fifo_1024x32 IS

	SIGNAL sub_wire0	: STD_LOGIC ;
	SIGNAL sub_wire1	: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL sub_wire2	: STD_LOGIC ;



	COMPONENT scfifo
	GENERIC (
		intended_device_family		: STRING;
		lpm_width		: NATURAL;
		lpm_numwords		: NATURAL;
		lpm_widthu		: NATURAL;
		lpm_type		: STRING;
		lpm_showahead		: STRING;
		overflow_checking		: STRING;
		underflow_checking		: STRING;
		use_eab		: STRING;
		add_ram_output_register		: STRING
	);
	PORT (
			rdreq	: IN STD_LOGIC ;
			empty	: OUT STD_LOGIC ;
			aclr	: IN STD_LOGIC ;
			clock	: IN STD_LOGIC ;
			q	: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
			wrreq	: IN STD_LOGIC ;
			data	: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			full	: OUT STD_LOGIC 
	);
	END COMPONENT;

BEGIN
	empty    <= sub_wire0;
	q    <= sub_wire1(31 DOWNTO 0);
	full    <= sub_wire2;

	scfifo_component : scfifo
	GENERIC MAP (
		intended_device_family => "Stratix",
		lpm_width => 32,
		lpm_numwords => 1024,
		lpm_widthu => 10,
		lpm_type => "scfifo",
		lpm_showahead => "ON",
		overflow_checking => "ON",
		underflow_checking => "ON",
		use_eab => "ON",
		add_ram_output_register => "ON"
	)
	PORT MAP (
		rdreq => rdreq,
		aclr => aclr,
		clock => clock,
		wrreq => wrreq,
		data => data,
		empty => sub_wire0,
		q => sub_wire1,
		full => sub_wire2
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: Width NUMERIC "32"
-- Retrieval info: PRIVATE: Depth NUMERIC "1024"
-- Retrieval info: PRIVATE: Clock NUMERIC "0"
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Stratix"
-- Retrieval info: PRIVATE: CLOCKS_ARE_SYNCHRONIZED NUMERIC "0"
-- Retrieval info: PRIVATE: Full NUMERIC "1"
-- Retrieval info: PRIVATE: Empty NUMERIC "1"
-- Retrieval info: PRIVATE: UsedW NUMERIC "0"
-- Retrieval info: PRIVATE: AlmostFull NUMERIC "0"
-- Retrieval info: PRIVATE: AlmostEmpty NUMERIC "0"
-- Retrieval info: PRIVATE: AlmostFullThr NUMERIC "-1"
-- Retrieval info: PRIVATE: AlmostEmptyThr NUMERIC "-1"
-- Retrieval info: PRIVATE: sc_aclr NUMERIC "1"
-- Retrieval info: PRIVATE: sc_sclr NUMERIC "0"
-- Retrieval info: PRIVATE: rsFull NUMERIC "0"
-- Retrieval info: PRIVATE: rsEmpty NUMERIC "1"
-- Retrieval info: PRIVATE: rsUsedW NUMERIC "0"
-- Retrieval info: PRIVATE: wsFull NUMERIC "1"
-- Retrieval info: PRIVATE: wsEmpty NUMERIC "0"
-- Retrieval info: PRIVATE: wsUsedW NUMERIC "0"
-- Retrieval info: PRIVATE: dc_aclr NUMERIC "0"
-- Retrieval info: PRIVATE: LegacyRREQ NUMERIC "0"
-- Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
-- Retrieval info: PRIVATE: LE_BasedFIFO NUMERIC "0"
-- Retrieval info: PRIVATE: Optimize NUMERIC "1"
-- Retrieval info: PRIVATE: OVERFLOW_CHECKING NUMERIC "0"
-- Retrieval info: PRIVATE: UNDERFLOW_CHECKING NUMERIC "0"
-- Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Stratix"
-- Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "32"
-- Retrieval info: CONSTANT: LPM_NUMWORDS NUMERIC "1024"
-- Retrieval info: CONSTANT: LPM_WIDTHU NUMERIC "10"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "scfifo"
-- Retrieval info: CONSTANT: LPM_SHOWAHEAD STRING "ON"
-- Retrieval info: CONSTANT: OVERFLOW_CHECKING STRING "ON"
-- Retrieval info: CONSTANT: UNDERFLOW_CHECKING STRING "ON"
-- Retrieval info: CONSTANT: USE_EAB STRING "ON"
-- Retrieval info: CONSTANT: ADD_RAM_OUTPUT_REGISTER STRING "ON"
-- Retrieval info: USED_PORT: data 0 0 32 0 INPUT NODEFVAL data[31..0]
-- Retrieval info: USED_PORT: q 0 0 32 0 OUTPUT NODEFVAL q[31..0]
-- Retrieval info: USED_PORT: wrreq 0 0 0 0 INPUT NODEFVAL wrreq
-- Retrieval info: USED_PORT: rdreq 0 0 0 0 INPUT NODEFVAL rdreq
-- Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL clock
-- Retrieval info: USED_PORT: full 0 0 0 0 OUTPUT NODEFVAL full
-- Retrieval info: USED_PORT: empty 0 0 0 0 OUTPUT NODEFVAL empty
-- Retrieval info: USED_PORT: aclr 0 0 0 0 INPUT NODEFVAL aclr
-- Retrieval info: CONNECT: @data 0 0 32 0 data 0 0 32 0
-- Retrieval info: CONNECT: q 0 0 32 0 @q 0 0 32 0
-- Retrieval info: CONNECT: @wrreq 0 0 0 0 wrreq 0 0 0 0
-- Retrieval info: CONNECT: @rdreq 0 0 0 0 rdreq 0 0 0 0
-- Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
-- Retrieval info: CONNECT: full 0 0 0 0 @full 0 0 0 0
-- Retrieval info: CONNECT: empty 0 0 0 0 @empty 0 0 0 0
-- Retrieval info: CONNECT: @aclr 0 0 0 0 aclr 0 0 0 0
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
-- Retrieval info: GEN_FILE: TYPE_NORMAL output_fifo_1024x32.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL output_fifo_1024x32.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL output_fifo_1024x32.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL output_fifo_1024x32.bsf FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL output_fifo_1024x32_inst.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL output_fifo_1024x32_waveforms.html TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL output_fifo_1024x32_wave*.jpg FALSE
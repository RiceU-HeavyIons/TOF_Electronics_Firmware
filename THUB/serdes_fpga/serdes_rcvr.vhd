-- $Id: serdes_rcvr.vhd,v 1.7 2008-12-04 20:38:54 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_rcvr.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2008-01-09
-- Last update: 2008-12-04
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top Level Component for the THUB SERDES FPGAs
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-01-09  1.0      jschamba        Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera;
USE altera.altera_primitives_components.ALL;
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

ENTITY serdes_rcvr IS
  PORT
    (
      areset_n   : IN  std_logic;       -- asynchronous reset, active low
      clk40mhz   : IN  std_logic;       -- Master clock
      rdreq_in   : IN  std_logic;
      fifo_aclr  : IN  std_logic;
      ch_rclk    : IN  std_logic;
      ch_rxd     : IN  std_logic_vector (17 DOWNTO 0);
      geo_id     : IN  std_logic_vector (6 DOWNTO 0);
      dataout    : OUT std_logic_vector (15 DOWNTO 0);
      fifo_empty : OUT std_logic
      );
END serdes_rcvr;


ARCHITECTURE a OF serdes_rcvr IS


  SIGNAL s_fifo_wrreq : std_logic;
  SIGNAL s_fifo_rdreq : std_logic;
  SIGNAL s_fifo_empty : std_logic;
  SIGNAL s_fifo_q     : std_logic_vector(31 DOWNTO 0);

  SIGNAL s_geo_id : std_logic_vector(6 DOWNTO 0);

  SIGNAL s_ddr_inh  : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_ddr_inl  : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_latch    : std_logic;
  SIGNAL s_valid    : std_logic;
  SIGNAL s_shiftout : std_logic_vector (31 DOWNTO 0);
  SIGNAL s_dff_q    : std_logic_vector(31 DOWNTO 0);


BEGIN

  -- create a latch signal that has half the frequency of ch_rclk
  -- reset, when there is nothing being sent (chvalid = 0)
  ch_latch : TFF PORT MAP (
    t    => '1',
    clk  => ch_rclk,
    clrn => s_valid,
    prn  => '1',
    q    => s_latch);

  -- shift the incoming data 16 bits at a time on each ch_rclk
  -- reset when nothing is being sent (chvalid = 0)

  -- Shift register
  shiftreg_ch : PROCESS (ch_rclk, areset_n) IS
    VARIABLE b_valid : boolean := false;
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      s_valid    <= '0';
      s_shiftout <= (OTHERS => '0');
      b_valid    := false;
      
    ELSIF ch_rclk'event AND ch_rclk = '1' THEN  -- rising clock edge
      b_valid := (ch_rxd(17) = '1');
      s_valid <= bool2sl(b_valid);

      IF b_valid THEN                   -- use highest bit as shift enable
        s_shiftout(31 DOWNTO 16) <= s_shiftout(15 DOWNTO 0);
        s_shiftout(15 DOWNTO 0)  <= ch_rxd(15 DOWNTO 0);
      END IF;
      
    END IF;
  END PROCESS shiftreg_ch;

  WITH (s_shiftout(31 DOWNTO 28) = X"C") SELECT
    s_geo_id <=
    geo_id                 WHEN true,
    s_shiftout(7 DOWNTO 1) WHEN OTHERS;

  s_fifo_wrreq <= s_latch;  -- will be disabled when FIFO is full due to overflow checking
  rxfifo : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_hint               => "MAXIMIZE_SPEED=5",
      lpm_numwords           => 2048,
      lpm_showahead          => "ON",
      lpm_type               => "dcfifo",
      lpm_width              => 32,
      lpm_widthu             => 11,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 4,
      underflow_checking     => "ON",
      wrsync_delaypipe       => 4)
    PORT MAP (
      wrclk             => NOT ch_rclk,
      rdreq             => s_fifo_rdreq,
      aclr              => fifo_aclr,
      rdclk             => clk40mhz,
      wrreq             => s_fifo_wrreq,
      data(31 DOWNTO 8) => s_shiftout(31 DOWNTO 8),
      data(7 DOWNTO 1)  => s_geo_id,
      data(0)           => s_shiftout(0),
      rdempty           => s_fifo_empty,
      q                 => s_fifo_q
      );

  -- register the outputs of the FIFO with the rising edge
  -- of the 40MHz clock, and the rdreq with the falling edge
  dff_inst: PROCESS (clk40mhz, areset_n) IS
  BEGIN
    IF areset_n = '0' THEN                   -- asynchronous reset (active low)
      s_dff_q    <= (OTHERS => '0');
      fifo_empty <= '1';
      s_fifo_rdreq <= '0';
      
    ELSIF clk40mhz'event AND clk40mhz = '1' THEN  -- rising clock edge
      s_dff_q <= s_fifo_q;
      -- Only put out a valid fifo_empty, when rdreq is valid
      -- otherwise, fifo_emtpy = '1'
      IF rdreq_in = '1' THEN
        fifo_empty   <= s_fifo_empty;
      ELSE
        fifo_empty <= '1';  
      END IF;
    ELSIF clk40mhz'event AND clk40mhz = '0' THEN  -- falling clock edge
        s_fifo_rdreq <= rdreq_in;
    END IF;
  END PROCESS dff_inst;

  WITH clk40mhz SELECT
    dataout <=
    s_dff_q(15 DOWNTO 0)  WHEN '0',
    s_dff_q(31 DOWNTO 16) WHEN OTHERS;
  

END a;

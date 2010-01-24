-- $Id: serdes_rcvr.vhd,v 1.12 2010-01-24 15:48:03 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_rcvr.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2008-01-09
-- Last update: 2010-01-24
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
      clk80mhz   : IN  std_logic;       -- 80MHz PLL clock
      rdreq_in   : IN  std_logic;
      fifo_aclr  : IN  std_logic;
      ch_rclk    : IN  std_logic;
      ch_rxd     : IN  std_logic_vector (17 DOWNTO 0);
      geo_id     : IN  std_logic_vector (6 DOWNTO 0);
      dataout    : OUT std_logic_vector (31 DOWNTO 0);
      fifo_empty : OUT std_logic
      );
END serdes_rcvr;


ARCHITECTURE a OF serdes_rcvr IS


  SIGNAL s_fifo_wrreq   : std_logic;
  SIGNAL s_fifo_rdreq   : std_logic;
  SIGNAL s_fifo_empty   : std_logic;
  SIGNAL syncfifo_empty : std_logic;
  SIGNAL s_fifo_q       : std_logic_vector(31 DOWNTO 0);
  SIGNAL s_geo_id       : std_logic_vector(6 DOWNTO 0);
  SIGNAL s_ddr_inh      : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_ddr_inl      : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_latch        : std_logic;
  SIGNAL s_valid        : std_logic;
  SIGNAL s_shiftout     : std_logic_vector (31 DOWNTO 0);
  SIGNAL s_dff_q        : std_logic_vector(31 DOWNTO 0);
  SIGNAL s_ch_rxd       : std_logic_vector (17 DOWNTO 0);


BEGIN

  PROCESS (ch_rclk) IS
  BEGIN  -- PROCESS
    IF rising_edge(ch_rclk) THEN  -- rising clock edge
      s_ch_rxd <= ch_rxd;
    END IF;
  END PROCESS;

  -- use a mixed width dual-clock FIFO to convert the 2x16bit
  -- words received into 32bit words, and to synchronize between
  -- the serdes clock and the local 80MHz PLL clock
  -- The upper and lower 16-bits need to be exchanged due to  the
  -- order in which they are received
  sync_fifo : dcfifo_mixed_widths
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_hint               => "MAXIMIZE_SPEED=7,",
      lpm_numwords           => 16,
      lpm_showahead          => "ON",
      lpm_type               => "dcfifo",
      lpm_width              => 16,
      lpm_widthu             => 4,
      lpm_widthu_r           => 3,
      lpm_width_r            => 32,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 5,
      underflow_checking     => "ON",
      use_eab                => "ON",
      write_aclr_synch       => "OFF",
      wrsync_delaypipe       => 5
      )
    PORT MAP (
      wrclk           => ch_rclk,
      rdreq           => '1',
      aclr            => fifo_aclr,
      rdclk           => clk80mhz,
      wrreq           => s_ch_rxd(17),
      data            => s_ch_rxd(15 DOWNTO 0),
      rdempty         => syncfifo_empty,
      q(31 DOWNTO 16) => s_shiftout(15 DOWNTO 0),
      q(15 DOWNTO 0)  => s_shiftout(31 DOWNTO 16)
      );

  -- in case of a geographical word, latch the correct geographical information
  WITH (s_shiftout(31 DOWNTO 16) = X"C000") SELECT
    s_geo_id <=
    geo_id                 WHEN true,
    s_shiftout(7 DOWNTO 1) WHEN OTHERS;

  s_fifo_wrreq <= NOT syncfifo_empty;  -- will be disabled when FIFO is full due to overflow checking
  rxfifo : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_hint               => "MAXIMIZE_SPEED=7",
      lpm_numwords           => 2048,
      lpm_showahead          => "OFF",
      lpm_type               => "dcfifo",
      lpm_width              => 32,
      lpm_widthu             => 11,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 4,
      underflow_checking     => "ON",
      wrsync_delaypipe       => 4)
    PORT MAP (
      wrclk             => clk80mhz,
      rdreq             => s_fifo_rdreq,
      aclr              => fifo_aclr,
      rdclk             => clk80mhz,
      wrreq             => s_fifo_wrreq,
      data(31 DOWNTO 8) => s_shiftout(31 DOWNTO 8),
      data(7 DOWNTO 1)  => s_geo_id,
      data(0)           => s_shiftout(0),
      rdempty           => s_fifo_empty,
      q                 => s_fifo_q
      );

  dataout <= s_fifo_q;


--  dff_inst1 : PROCESS (clk80mhz, areset_n) IS
--  BEGIN
--    IF areset_n = '0' THEN              -- asynchronous reset (active low)
--      fifo_empty <= '1';
      
--    ELSIF rising_edge(clk80mhz) THEN
--      -- Only put out a valid fifo_empty, when rdreq is valid
--      -- otherwise, fifo_emtpy = '1'
--      IF rdreq_in = '1' THEN
--        fifo_empty <= s_fifo_empty;
--      ELSE
--        fifo_empty <= '1';
--      END IF;
--    END IF;
--  END PROCESS dff_inst1;

  fifo_empty   <= s_fifo_empty;
  s_fifo_rdreq <= rdreq_in;

END a;

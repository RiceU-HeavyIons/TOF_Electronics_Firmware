-- $Id$
-------------------------------------------------------------------------------
-- Title      : SERDES_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_rcvr.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2008-01-09
-- Last update: 2010-07-21
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
      aclr       : IN  std_logic;
      trigger    : IN  std_logic;
      ch_rclk    : IN  std_logic;
      ch_rxd     : IN  std_logic_vector (17 DOWNTO 0);
      geo_id     : IN  std_logic_vector (6 DOWNTO 0);
      dataout    : OUT std_logic_vector (31 DOWNTO 0);
      fifo_empty : OUT std_logic
      );
END serdes_rcvr;


ARCHITECTURE a OF serdes_rcvr IS


  SIGNAL s_fifo_wrreq : std_logic;
  SIGNAL s_fifo_rdreq : std_logic;
  SIGNAL s_fifo_empty : std_logic;
  SIGNAL s_fifo_q     : std_logic_vector(31 DOWNTO 0);
  SIGNAL s_fifo_data  : std_logic_vector(31 DOWNTO 0);
  SIGNAL s_geo_id     : std_logic_vector(6 DOWNTO 0);
  SIGNAL s_shiftout   : std_logic_vector (31 DOWNTO 0);
  SIGNAL fifo_aclr    : std_logic;
  SIGNAL s_latch0     : std_logic;
  SIGNAL s_latch1     : std_logic;
  SIGNAL s_latch2     : std_logic;
  SIGNAL s_latch3     : std_logic;
  SIGNAL s_latch4     : std_logic;
  SIGNAL s_latch5     : std_logic;
  SIGNAL ctr          : std_logic_vector (1 DOWNTO 0);

BEGIN

  PROCESS (clk80mhz, aclr) IS
  BEGIN
    IF aclr = '1' THEN                  -- asynchronous reset (active high)
      s_shiftout <= (OTHERS => '0');
      s_latch1   <= '0';
      fifo_aclr  <= '1';
      ctr        <= (OTHERS => '0');
      
    ELSIF rising_edge(clk80mhz) THEN

      -- gray counter as workaround for a state machine
      -- to control the number of bits used
      CASE ctr IS
        WHEN "00" =>
          IF (ch_rclk = '1') AND (ch_rxd(17) = '1') THEN
            ctr <= "01";
          END IF;
        WHEN "01" =>
          IF ch_rclk = '0' THEN
            ctr <= "11";
          END IF;
        WHEN "11" =>
          IF (ch_rclk = '1') AND (ch_rxd(17) = '1') THEN
            ctr <= "10";
          END IF;
        WHEN "10" =>
          IF ch_rclk = '0' THEN
            ctr <= "00";
          END IF;

      END CASE;

      -- use the counter to latch the data (16 bit at a time)
      -- and generate a latch
      IF trigger = '1' THEN
        fifo_aclr  <= '1';
        s_latch1   <= '0';
        s_shiftout <= (OTHERS => '0');
      ELSIF ctr = "00" THEN
        s_shiftout(31 DOWNTO 16) <= ch_rxd(15 DOWNTO 0);
        s_latch1                 <= '0';
        fifo_aclr                <= '0';
      ELSIF ctr = "01" THEN
        s_latch1  <= '1';
        fifo_aclr <= '0';
      ELSIF ctr = "11" THEN
        s_shiftout(15 DOWNTO 0) <= ch_rxd(15 DOWNTO 0);
        s_latch1                <= '0';
        fifo_aclr               <= '0';
      ELSE
        s_latch1  <= '0';
        fifo_aclr <= '0';
      END IF;

    END IF;
  END PROCESS;

  -- in case of a geographical word, latch the correct geographical information
  WITH (s_shiftout(31 DOWNTO 16) = X"C000") SELECT
    s_fifo_data(7 DOWNTO 1) <=
    geo_id                 WHEN true,
    s_shiftout(7 DOWNTO 1) WHEN OTHERS;

  s_fifo_data(31 DOWNTO 8) <= s_shiftout(31 DOWNTO 8);
  s_fifo_data(0)           <= s_shiftout(0);

  -- delay and shorten the latch to use as a write request of the FIFO
  PROCESS (clk80mhz, aclr) IS
  BEGIN  -- PROCESS
    IF aclr = '1' THEN                  -- asynchronous reset (active high)
      s_latch2 <= '0';
      s_latch3 <= '0';
      s_latch4 <= '0';
      s_latch5 <= '0';
      
    ELSIF rising_edge(clk80mhz) THEN    -- rising clock edge
      s_latch2 <= s_latch1;
      s_latch3 <= s_latch2;
      s_latch4 <= s_latch3;
      s_latch5 <= s_latch4;
    END IF;
  END PROCESS;

  s_fifo_wrreq <= s_latch4 AND (NOT s_latch5);


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
      wrclk   => clk80mhz,
      rdreq   => s_fifo_rdreq,
      aclr    => fifo_aclr,
      rdclk   => clk80mhz,
      wrreq   => s_fifo_wrreq,
      data    => s_fifo_data,
      rdempty => s_fifo_empty,
      q       => s_fifo_q
      );

  dataout      <= s_fifo_q;
  fifo_empty   <= s_fifo_empty;
  s_fifo_rdreq <= rdreq_in;

END a;

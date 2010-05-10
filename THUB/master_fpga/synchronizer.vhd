-- $Id: synchronizer.vhd,v 1.4 2010-05-10 14:19:53 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : Serdes Syncrhonizer
-- Project    : 
-------------------------------------------------------------------------------
-- File       : synchronizer.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-01-16
-- Last update: 2010-04-29
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: De-multiplexes and synchronizes Serdes FPGA input data
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-01-16  1.0      jschamba        Created
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

ENTITY synchronizer IS
  
  PORT (
    clk80mhz      : IN  std_logic;
    areset_n      : IN  std_logic;
    serdes_indata : IN  std_logic_vector(7 DOWNTO 0);   -- 8 bit on both clock edges
    serdes_clk    : IN  std_logic;                      -- 80MHz clock xmitted with data
    serdes_strb   : IN  std_logic;                      -- strobe every 4 bytes
    sfifo_empty   : OUT std_logic;
    sync_q        : OUT std_logic_vector (31 DOWNTO 0)  -- 32bit data
    );

END ENTITY synchronizer;

ARCHITECTURE a OF synchronizer IS

  COMPONENT ddio_in IS
    PORT (
      datain    : IN  std_logic_vector (7 DOWNTO 0);
      inclock   : IN  std_logic;
      dataout_h : OUT std_logic_vector (7 DOWNTO 0);
      dataout_l : OUT std_logic_vector (7 DOWNTO 0));
  END COMPONENT ddio_in;

  SIGNAL s_ddio_outh : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_ddio_outl : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_ddio_out  : std_logic_vector (15 DOWNTO 0);
  SIGNAL s1_ddio_out : std_logic_vector (15 DOWNTO 0);
  SIGNAL s_d32_out   : std_logic_vector (31 DOWNTO 0);

  SIGNAL s_latch1, s_latch2 : std_logic;
  SIGNAL s_latch3, s_latch4 : std_logic;
  SIGNAL s_latch            : std_logic;
  SIGNAL s_latch32          : std_logic;
  SIGNAL s_fifo_q           : std_logic_vector (31 DOWNTO 0);
  
BEGIN  -- ARCHITECTURE a

  -- first decode both edges of the incoming data stream with the "double data
  -- rate" component. clock is taken from the Serdes input pins
  ddio_in_inst : ddio_in PORT MAP (
    datain    => serdes_indata,
    inclock   => serdes_clk,
    dataout_h => s_ddio_outh,
    dataout_l => s_ddio_outl);

  -- now combine the resulting 16 bit (2x8) data into 32 bit data
  -- with a shift REGISTER
  -- also delay the strobe appropriately

  -- create delayed versions of serdes strobe:
  PROCESS (serdes_clk, areset_n) IS
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      s_latch1 <= '0';
      s_latch2 <= '0';
      s_latch3 <= '0';
    ELSIF rising_edge(serdes_clk) THEN
      s_latch1 <= serdes_strb;
      s_latch2 <= s_latch1;
      s_latch3 <= s_latch2;
    END IF;
  END PROCESS;

  -- shift 16bit data
  PROCESS (serdes_clk, areset_n) IS
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      s_ddio_out  <= (OTHERS => '0');
      s1_ddio_out <= (OTHERS => '0');
    ELSIF rising_edge(serdes_clk) THEN
      -- first stage
      s1_ddio_out(15 DOWNTO 8) <= s_ddio_outl;
      s1_ddio_out(7 DOWNTO 0)  <= s_ddio_outh;
      -- second stage
      s_ddio_out               <= s1_ddio_out;
    END IF;
  END PROCESS;

  -- latch 32bit data
  s_latch32 <= s_latch2;
  PROCESS (serdes_clk, areset_n) IS
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      s_d32_out <= (OTHERS => '0');
    ELSIF falling_edge(serdes_clk) THEN
      IF s_latch32 = '1' THEN
        s_d32_out(31 DOWNTO 16) <= s_ddio_out;
        s_d32_out(15 DOWNTO 0)  <= s1_ddio_out;
      END IF;
    END IF;
  END PROCESS;

  -- synchronize to 80MHz clock with small dual-clock FIFO
  s_latch <= s_latch3;
  sync_fifo : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_hint               => "MAXIMIZE_SPEED=7,",
      lpm_numwords           => 8,
      lpm_showahead          => "ON",
      lpm_type               => "dcfifo",
      lpm_width              => 32,
      lpm_widthu             => 3,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 5,
      underflow_checking     => "ON",
      use_eab                => "ON",
      write_aclr_synch       => "OFF",
      wrsync_delaypipe       => 5
      )
    PORT MAP (
      wrclk   => serdes_clk,
      rdreq   => '1',
      aclr    => NOT areset_n,
      rdclk   => clk80mhz,
      wrreq   => s_latch,
      data    => s_d32_out,
      rdempty => sfifo_empty,
      q       => s_fifo_q
      );

  -- component data output is the FIFO q
  sync_q <= s_fifo_q;
  

END ARCHITECTURE a;

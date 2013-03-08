-- $Id: synchronizer.vhd,v 1.1 2008-01-16 23:10:59 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : Serdes Syncrhonizer
-- Project    : 
-------------------------------------------------------------------------------
-- File       : synchronizer.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-01-16
-- Last update: 2008-01-16
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
    serdes_indata : IN  std_logic_vector(7 DOWNTO 0);  -- 8 bit on both clock edges
    serdes_clk    : IN  std_logic;      -- 80MHz clock xmitted with data
    serdes_strb   : IN  std_logic;      -- strobe every 4 bytes
    sync_q        : OUT std_logic_vector (16 DOWNTO 0)  -- 16bit data + latch
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

  
BEGIN  -- ARCHITECTURE a

  -- first decode both edges of the incoming data stream with the "double data
  -- rate" component. clock is taken from the Serdes input pins
  ddio_in_inst : ddio_in PORT MAP (
    datain    => serdes_indata,
    inclock   => serdes_clk,
    dataout_h => s_ddio_outh,
    dataout_l => s_ddio_outl);

  -- now synchronize the 2 decoded 8bit streams and the latch signal with a
  -- dual-clock FIFO
  syncfifo : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_numwords           => 8,
      lpm_showahead          => "OFF",
      lpm_type               => "dcfifo",
      lpm_width              => 17,
      lpm_widthu             => 3,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 4,
      underflow_checking     => "ON",
      use_eab                => "ON",
      wrsync_delaypipe       => 4
      )
    PORT MAP (
      wrclk             => NOT serdes_clk,
      wrreq             => '1',
      rdclk             => clk80mhz,
      rdreq             => '1',
      data(16)          => serdes_strb,
      data(15 DOWNTO 8) => s_ddio_outl,
      data(7 DOWNTO 0)  => s_ddio_outh,
      q                 => sync_q
      );

END ARCHITECTURE a;

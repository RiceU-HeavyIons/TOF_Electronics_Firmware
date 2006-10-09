-- $Id: serdes_fpga.vhd,v 1.2 2006-10-09 19:02:17 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_fpga.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2005-12-19
-- Last update: 2006-08-03
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top Level Component for the THUB SERDES FPGAs
-------------------------------------------------------------------------------
-- Copyright (c) 2005 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2005-12-19  1.0      jschamba        Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera;
USE altera.maxplus2.ALL;


ENTITY serdes_fpga IS
  PORT
    (
      clk                                                : IN    std_logic;  -- Master clock
      -- ***** Mictor outputs *****
      mt                                                 : OUT   std_logic_vector(31 DOWNTO 0);
      mt_clk                                             : OUT   std_logic;
      -- ***** bus to main fpga *****
      ma                                                 : IN    std_logic_vector(35 DOWNTO 0);
      m_all                                              : IN    std_logic_vector(3 DOWNTO 0);
      -- ***** SRAM *****
      -- ADDR[17] and ADDR[18] on schematic are actually TCK and TDO, so renamed 
      -- ADDR[19] and ADDR[20] to be ADDR[17] and ADDR[18], respectively
      sra_addr, srb_addr                                 : OUT   std_logic_vector(18 DOWNTO 0);
      -- sra_d                                              : IN    std_logic_vector(31 DOWNTO 0);
      sra_d                                              : INOUT std_logic_vector(31 DOWNTO 0);
      srb_d                                              : INOUT std_logic_vector(31 DOWNTO 0);
      sra_tck, srb_tck                                   : OUT   std_logic;  -- JTAG
      sra_tdo, srb_tdo                                   : IN    std_logic;  -- JTAG
      sra_rw, srb_rw                                     : OUT   std_logic;
      sra_oe_n, srb_oe_n                                 : OUT   std_logic;
      sra_bw, srb_bw                                     : OUT   std_logic_vector(3 DOWNTO 0);
      sra_adv, srb_adv                                   : OUT   std_logic;
      sra_clk, srb_clk                                   : OUT   std_logic;
      -- ***** SERDES *****
      ch0_rxd, ch1_rxd, ch2_rxd, ch3_rxd                 : IN    std_logic_vector(17 DOWNTO 0);
      ch0_txd, ch1_txd, ch2_txd, ch3_txd                 : OUT   std_logic_vector(17 DOWNTO 0);
      ch0_den, ch1_den, ch2_den, ch3_den                 : OUT   std_logic;
      ch0_ren, ch1_ren, ch2_ren, ch3_ren                 : OUT   std_logic;
      ch0_sync, ch1_sync, ch2_sync, ch3_sync             : OUT   std_logic;
      ch0_tpwdn_n, ch1_tpwdn_n, ch2_tpwdn_n, ch3_tpwdn_n : OUT   std_logic;
      ch0_rpwdn_n, ch1_rpwdn_n, ch2_rpwdn_n, ch3_rpwdn_n : OUT   std_logic;
      ch0_tck, ch1_tck, ch2_tck, ch3_tck                 : OUT   std_logic;
      ch0_lock_n, ch1_lock_n, ch2_lock_n, ch3_lock_n     : IN    std_logic;
      ch0_refclk, ch1_refclk, ch2_refclk, ch3_refclk     : OUT   std_logic;
      ch0_rclk, ch1_rclk, ch2_rclk, ch3_rclk             : IN    std_logic;
      ch0_loc_le, ch1_loc_le, ch2_loc_le, ch3_loc_le     : OUT   std_logic;
      ch0_line_le, ch1_line_le, ch2_line_le, ch3_line_le : OUT   std_logic;
      -- ***** LEDs *****
      led                                                : OUT   std_logic_vector(1 DOWNTO 0);
      -- ***** test points *****
      tp                                                 : IN    std_logic_vector(15 DOWNTO 1)

      );
END serdes_fpga;


ARCHITECTURE a OF serdes_fpga IS

  COMPONENT pll
    PORT
      (
        areset : IN  std_logic := '0';
        inclk0 : IN  std_logic := '0';
        c0     : OUT std_logic;
        c1     : OUT std_logic;
        locked : OUT std_logic
        );
  END COMPONENT;

  COMPONENT fifo
    PORT
      (
        aclr  : IN  std_logic;
        clock : IN  std_logic;
        data  : IN  std_logic_vector (17 DOWNTO 0);
        rdreq : IN  std_logic;
        wrreq : IN  std_logic;
        empty : OUT std_logic;
        full  : OUT std_logic;
        q     : OUT std_logic_vector (17 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT zbt_ctrl_top
    PORT (
      clk           : IN    std_logic;
      RESET_N       : IN    std_logic;                              -- active LOW asynchronous reset
-- local bus interface
      ADDR          : IN    std_logic_vector(18 DOWNTO 0);
      DATA_IN       : IN    std_logic_vector(31 DOWNTO 0);
      DATA_OUT      : OUT   std_logic_vector(31 DOWNTO 0);
      RD_WR_N       : IN    std_logic;                              -- active LOW write
      ADDR_ADV_LD_N : IN    std_logic;                              -- advance/load address (active LOW load)
      DM            : IN    std_logic_vector(3 DOWNTO 0);  -- data mask bits                   
-- SRAM interface
      SA            : OUT   std_logic_vector(18 DOWNTO 0);   -- address bus to RAM   
      DQ            : INOUT std_logic_vector(31 DOWNTO 0);   -- data to/from RAM
      RW_N          : OUT   std_logic;                              -- active LOW write
      ADV_LD_N      : OUT   std_logic;                              -- active LOW load
      BW_N          : OUT   std_logic_vector(3 DOWNTO 0)   -- active LOW byte enables
      );
  END COMPONENT;

  SIGNAL globalclk       : std_logic;
  SIGNAL clk_160mhz      : std_logic;   -- PLL 4x output
  SIGNAL clkp_160mhz     : std_logic;   -- PLL 4x output with phase shift
  SIGNAL pll_locked      : std_logic;
  SIGNAL counter_q       : std_logic_vector (16 DOWNTO 0);
  SIGNAL txfifo_rdreq    : std_logic;
  SIGNAL txfifo_q        : std_logic_vector (17 DOWNTO 0);
  SIGNAL txfifo_full     : std_logic;
  SIGNAL txfifo_empty    : std_logic;
  SIGNAL rxfifo_rdreq    : std_logic;
  SIGNAL rxfifo_q        : std_logic_vector (17 DOWNTO 0);
  SIGNAL rxfifo_full     : std_logic;
  SIGNAL rxfifo_empty    : std_logic;
  SIGNAL tx_xor_rx       : std_logic_vector (17 DOWNTO 0);
  SIGNAL counter25b_q    : std_logic_vector (24 DOWNTO 0);
  SIGNAL sync_dip        : std_logic;
  SIGNAL local_aclr      : std_logic;
  SIGNAL err_aclr        : std_logic;
  SIGNAL clk20mhz        : std_logic;
  SIGNAL serdes_clk      : std_logic;
  SIGNAL ctr_enable      : std_logic;
  SIGNAL s_rw_n          : std_logic;
  SIGNAL s_addr_adv_ld_n : std_logic;
  SIGNAL s_dm            : std_logic_vector (3 DOWNTO 0);

  TYPE   State_type IS (State0, State1, State1a, State2, State3);
  SIGNAL state : State_type;
  
BEGIN

  global_clk_buffer : global PORT MAP (a_in => clk, a_out => globalclk);

  serdes_clk <= '0';

  -- PLL
  pll_instance : pll PORT MAP (
    areset => '0',
    inclk0 => clk,
    c0     => clk_160mhz,
    c1     => clkp_160mhz,
    locked => pll_locked);

  -- LEDs
  -- led <= "00"; -- used below to show lock status

  -- Mictor defaults
  -- mt     <= (OTHERS => '0');
  mt_clk <= globalclk;
  -- others are used for SERDES channel-1 display below

  -- SRAM defaults
  sra_addr <= (OTHERS => '0');
  -- srb_addr <= (OTHERS => '0');
  sra_tck  <= '0';
  srb_tck  <= '0';
  sra_rw   <= '1';
  -- srb_rw   <= '1';
  sra_oe_n <= '0';
  srb_oe_n <= '0';
  sra_bw   <= (OTHERS => '0');
  -- srb_bw   <= (OTHERS => '0');
  sra_adv  <= '0';
  -- srb_adv  <= '0';
  sra_clk  <= clk_160mhz;
  srb_clk  <= clk_160mhz;

  sra_d <= (OTHERS => 'Z');
  -- srb_d <= (OTHERS => 'Z');

  -- counter to divide clock
  counter25b : lpm_counter
    GENERIC MAP (
      LPM_WIDTH     => 25,
      LPM_TYPE      => "LPM_COUNTER",
      LPM_DIRECTION => "UP")
    PORT MAP (
      clock => globalclk,
      q     => counter25b_q);

  dip_latch : PROCESS (counter25b_q(24)) IS
  BEGIN  -- PROCESS dip_latch
    IF (counter25b_q(24)'event AND (counter25b_q(24) = '1')) THEN
      sync_dip <= m_all(0);
    END IF;
  END PROCESS dip_latch;


  -- SERDES defaults

  -- channel 0
  ch0_den     <= '0';
  ch0_ren     <= '0';
  ch0_sync    <= '0';
  ch0_tpwdn_n <= '0';
  ch0_rpwdn_n <= '0';
  ch0_loc_le  <= '0';
  ch0_line_le <= '0';
  ch0_txd     <= (OTHERS => '0');
  led(0)      <= ch0_lock_n;

  -- channel 1
  ch1_den     <= '0';
  ch1_ren     <= '0';
  ch1_sync    <= '0';
  ch1_tpwdn_n <= '0';
  ch1_rpwdn_n <= '0';
  ch1_loc_le  <= '0';
  ch1_line_le <= '0';
  ch1_txd     <= (OTHERS => '0');
  led(1)      <= ch1_lock_n;
  -- mt(17 DOWNTO 0) <= ch1_rxd;           -- to mictor for display

  -- channel 2
  ch2_den     <= '0';
  ch2_ren     <= '0';
  ch2_sync    <= '0';
  ch2_tpwdn_n <= '0';
  ch2_rpwdn_n <= '0';
  ch2_loc_le  <= '0';
  ch2_line_le <= '0';
  ch2_txd     <= (OTHERS => '0');

  -- channel 3
  ch3_den     <= '0';
  ch3_ren     <= '0';
  ch3_sync    <= '0';
  ch3_tpwdn_n <= '0';
  ch3_rpwdn_n <= '0';
  ch3_loc_le  <= '0';
  ch3_line_le <= '0';
  ch3_txd     <= (OTHERS => '0');


  -- tx clocks and rx refclocks
  -- all of these clocks come directly to the SERDES
  -- daughtercard (differentially), so just put GND ON
  -- those lines.
  ch0_tck    <= serdes_clk;
  ch1_tck    <= serdes_clk;
  ch2_tck    <= '0';
  ch3_tck    <= '0';
  ch0_refclk <= serdes_clk;
  ch1_refclk <= serdes_clk;
  ch2_refclk <= '0';
  ch3_refclk <= '0';


  zbt_ctrl_top_inst1 : zbt_ctrl_top
    PORT MAP (
      clk                   => clkp_160mhz,
      RESET_N               => pll_locked,
-- local bus interface
      ADDR(15 DOWNTO 0)     => ma(15 DOWNTO 0),
      ADDR(18 DOWNTO 16)    => (OTHERS => '0'),
      DATA_IN(17 DOWNTO  0) => ma(33 DOWNTO 16),
      DATA_IN(31 DOWNTO 18) => (OTHERS => '0'),
      DATA_OUT              => mt,
      RD_WR_N               => s_rw_n,
      ADDR_ADV_LD_N         => s_addr_adv_ld_n,
      DM                    => s_dm,
-- SRAM interface
      SA                    => srb_addr,
      DQ                    => srb_d,
      RW_N                  => srb_rw,
      ADV_LD_N              => srb_adv,
      BW_N                  => srb_bw
      );


  sram_sm : PROCESS (clkp_160mhz, pll_locked) IS
  BEGIN  -- PROCESS uc_fpga_sm
    IF pll_locked = '0' THEN                     -- asynchronous reset (active low)
      state    <= State0;
      s_dm <= (OTHERS => '0');
      s_rw_n <= '0';
      s_addr_adv_ld_n <= '1';
    ELSIF clkp_160mhz'event AND clkp_160mhz = '1' THEN  -- rising clock edge
      s_dm <= (OTHERS => '0');
      s_rw_n <= '0';
      s_addr_adv_ld_n <= '1';
      CASE state IS
        WHEN State0 =>
          IF ma(35) = '1' THEN
            state <= State1;
          END IF;
        WHEN State1 =>
          s_addr_adv_ld_n <= '0';
          s_rw_n <= ma(34);
          s_dm <= (OTHERS => '1');
          state <= State1a;
        WHEN State1a =>                 -- this state is for testing of the waveforms only
          s_addr_adv_ld_n <= '0';
          s_rw_n <= ma(34);
          s_dm <= (OTHERS => '1');
          state <= State2;
        WHEN State2 =>
          s_addr_adv_ld_n <= '0';
          state <= State3;
        WHEN State3 =>
          IF ma(35) = '0' THEN
            state <= State0;
          END IF;
      END CASE;
    END IF;
  END PROCESS sram_sm;
  
END a;

-- $Id: serdes_fpga.vhd,v 1.1 2006-07-20 22:05:15 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_fpga.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2005-12-19
-- Last update: 2006-07-20
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
      clk                                                : IN  std_logic;  -- Master clock
      -- ***** Mictor outputs *****
      mt                                                 : OUT std_logic_vector(31 DOWNTO 0);
      mt_clk                                             : OUT std_logic;
      -- ***** bus to main fpga *****
      ma                                                 : OUT std_logic_vector(35 DOWNTO 0);
      m_all                                              : IN  std_logic_vector(3 DOWNTO 0);
      -- ***** SRAM *****
      -- ADDR[17] and ADDR[18] on schematic are actually TCK and TDO, so renamed 
      -- ADDR[19] and ADDR[20] to be ADDR[17] and ADDR[18], respectively
      sra_addr, srb_addr                                 : OUT std_logic_vector(18 DOWNTO 0);
      sra_d, srb_d                                       : IN  std_logic_vector(31 DOWNTO 0);
      sra_tck, srb_tck                                   : OUT std_logic;  -- JTAG
      sra_tdo, srb_tdo                                   : IN  std_logic;  -- JTAG
      sra_rw, srb_rw                                     : OUT std_logic;
      sra_oe_n, srb_oe_n                                 : OUT std_logic;
      sra_bw, srb_bw                                     : OUT std_logic_vector(3 DOWNTO 0);
      sra_adv, srb_adv                                   : OUT std_logic;
      sra_clk, srb_clk                                   : OUT std_logic;
      -- ***** SERDES *****
      ch0_rxd, ch1_rxd, ch2_rxd, ch3_rxd                 : IN  std_logic_vector(17 DOWNTO 0);
      ch0_txd, ch1_txd, ch2_txd, ch3_txd                 : OUT std_logic_vector(17 DOWNTO 0);
      ch0_den, ch1_den, ch2_den, ch3_den                 : OUT std_logic;
      ch0_ren, ch1_ren, ch2_ren, ch3_ren                 : OUT std_logic;
      ch0_sync, ch1_sync, ch2_sync, ch3_sync             : OUT std_logic;
      ch0_tpwdn_n, ch1_tpwdn_n, ch2_tpwdn_n, ch3_tpwdn_n : OUT std_logic;
      ch0_rpwdn_n, ch1_rpwdn_n, ch2_rpwdn_n, ch3_rpwdn_n : OUT std_logic;
      ch0_tck, ch1_tck, ch2_tck, ch3_tck                 : OUT std_logic;
      ch0_lock_n, ch1_lock_n, ch2_lock_n, ch3_lock_n     : IN  std_logic;
      ch0_refclk, ch1_refclk, ch2_refclk, ch3_refclk     : OUT std_logic;
      ch0_rclk, ch1_rclk, ch2_rclk, ch3_rclk             : IN  std_logic;
      ch0_loc_le, ch1_loc_le, ch2_loc_le, ch3_loc_le     : OUT std_logic;
      ch0_line_le, ch1_line_le, ch2_line_le, ch3_line_le : OUT std_logic;
      -- ***** LEDs *****
      led                                                : OUT std_logic_vector(1 DOWNTO 0);
      -- ***** test points *****
      tp                                                 : IN  std_logic_vector(15 DOWNTO 1)

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
    GENERIC (
      FLOWTHROUGH : integer := 0;                                   -- Pipelined if zero, Flowthrough if one
      ASIZE       : integer := 19;                                  -- address bus width
      DSIZE       : integer := 32;                                  -- data bus width
      BWSIZE      : integer := 4                                    -- byte enable bus width
      );
    PORT (
      clk           : IN    std_logic;
      RESET_N       : IN    std_logic;                              -- active LOW asynchronous reset
-- local bus interface
      ADDR          : IN    std_logic_vector(ASIZE - 1 DOWNTO 0);
      DATA_IN       : IN    std_logic_vector(DSIZE - 1 DOWNTO 0);
      DATA_OUT      : OUT   std_logic_vector(DSIZE - 1 DOWNTO 0);
      RD_WR_N       : IN    std_logic;                              -- active LOW write
      ADDR_ADV_LD_N : IN    std_logic;                              -- advance/load address (active LOW load)
      DM            : IN    std_logic_vector(BWSIZE - 1 DOWNTO 0);  -- data mask bits                   
-- SRAM interface
      SA            : OUT   std_logic_vector(ASIZE - 1 DOWNTO 0);   -- address bus to RAM   
      DQ            : INOUT std_logic_vector(DSIZE - 1 DOWNTO 0);   -- data to/from RAM
      RW_N          : OUT   std_logic;                              -- active LOW write
      ADV_LD_N      : OUT   std_logic;                              -- active LOW load
      BW_N          : OUT   std_logic_vector(BWSIZE - 1 DOWNTO 0)   -- active LOW byte enables
      );
  END COMPONENT;

  TYPE   State_type IS (A, B, C, D);
  SIGNAL y : State_type;

  SIGNAL globalclk    : std_logic;
  SIGNAL clk_160mhz   : std_logic;      -- PLL 4x output
  SIGNAL clk_80mhz    : std_logic;      -- PLL 2x output
  SIGNAL pll_locked   : std_logic;
  SIGNAL counter_q    : std_logic_vector (16 DOWNTO 0);
  SIGNAL txfifo_rdreq : std_logic;
  SIGNAL txfifo_q     : std_logic_vector (17 DOWNTO 0);
  SIGNAL txfifo_full  : std_logic;
  SIGNAL txfifo_empty : std_logic;
  SIGNAL rxfifo_rdreq : std_logic;
  SIGNAL rxfifo_q     : std_logic_vector (17 DOWNTO 0);
  SIGNAL rxfifo_full  : std_logic;
  SIGNAL rxfifo_empty : std_logic;
  SIGNAL tx_xor_rx    : std_logic_vector (17 DOWNTO 0);
  SIGNAL counter25b_q : std_logic_vector (24 DOWNTO 0);
  SIGNAL sync_dip     : std_logic;
  SIGNAL local_aclr   : std_logic;
  SIGNAL err_aclr     : std_logic;
  SIGNAL clk20mhz     : std_logic;
  SIGNAL serdes_clk   : std_logic;
  SIGNAL ctr_enable   : std_logic;
  
BEGIN

  global_clk_buffer : global PORT MAP (a_in => clk, a_out => globalclk);

  -- create 20 MHz clock with TFF:
  div2 : TFF PORT MAP (
    t    => '1',
    clk  => globalclk,
    clrn => '1',
    prn  => '1',
    q    => clk20mhz);

  serdes_clk <= clk20mhz;

  -- PLL
  pll_instance : pll PORT MAP (
    areset => '0',
    inclk0 => clk,
    c0     => clk_160mhz,
    c1     => clk_80mhz,
    locked => pll_locked);

  -- LEDs
  -- led <= "00"; -- used below to show lock status

  -- Mictor defaults
  mt(31 DOWNTO 18) <= (OTHERS => '0');
  -- mt     <= (OTHERS => '0');
  -- mt_clk <= globalclk;
  -- mt_clk <= clk;
  -- others are used for SERDES channel-1 display below

  -- Bus to main FPGA defaults
  ma(35 DOWNTO 20) <= (OTHERS => '0');
  ma(19)           <= ch1_lock_n;

  -- SRAM defaults
  sra_addr <= (OTHERS => '0');
  srb_addr <= (OTHERS => '0');
  sra_tck  <= '0';
  srb_tck  <= '0';
  sra_rw   <= '1';
  srb_rw   <= '1';
  sra_oe_n <= '0';
  srb_oe_n <= '0';
  sra_bw   <= (OTHERS => '0');
  srb_bw   <= (OTHERS => '0');
  sra_adv  <= '0';
  srb_adv  <= '0';
  sra_clk  <= clk_160mhz;
  srb_clk  <= clk_160mhz;

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
  -- Counter as data input to channel 0 TX
  counter17b : lpm_counter GENERIC MAP (
    LPM_WIDTH     => 17,
    LPM_TYPE      => "LPM_COUNTER",
    LPM_DIRECTION => "UP")
    PORT MAP (
      clock  => serdes_clk,
      q      => counter_q,
      clk_en => ctr_enable,             -- turned on by dip-switch
      aclr   => local_aclr);            -- clear with dip-switch

  ctr_enable <= sync_dip WHEN (y = A) ELSE '0';

  -- channel 0
  ch0_den              <= '1';          -- enabled
  ch0_ren              <= '0';
  ch0_sync             <= m_all(3);     -- turned on by dip-switch
  ch0_tpwdn_n          <= m_all(2);     -- turned on by dip-switch
  ch0_rpwdn_n          <= '0';
  ch0_loc_le           <= '0';
  ch0_line_le          <= '0';
  ch0_txd(16 DOWNTO 0) <= counter_q;
  ch0_txd(17)          <= sync_dip;
  led(0)               <= ch0_lock_n;

  -- channel 1
  ch1_den     <= '0';
  ch1_ren     <= '1';                   -- enabled
  ch1_sync    <= '0';
  ch1_tpwdn_n <= '0';
  ch1_rpwdn_n <= '1';                   -- powered on
  ch1_loc_le  <= '0';
  ch1_line_le <= '0';
  ch1_txd     <= (OTHERS => '0');
  led(1)      <= ch1_lock_n;
  -- mt(17 DOWNTO 0) <= ch1_rxd;           -- to mictor for display
  mt_clk      <= ch1_rclk;

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

  tx_fifo : fifo
    PORT MAP (
      aclr              => local_aclr,
      clock             => serdes_clk,
      data(16 DOWNTO 0) => counter_q,
      data(17)          => sync_dip,
      rdreq             => txfifo_rdreq,
      wrreq             => sync_dip,
      empty             => txfifo_empty,
      full              => txfifo_full,
      q                 => txfifo_q);

  ma(17 DOWNTO 0) <= txfifo_q;
  -- ma(17 DOWNTO 0) <= tx_xor_rx;
  txfifo_rdreq    <= NOT (txfifo_empty OR rxfifo_empty);
  xor_latch : PROCESS (tx_xor_rx, serdes_clk) IS
  BEGIN  -- PROCESS xor_latch
    IF (serdes_clk'event AND (serdes_clk = '1')) THEN
      IF y = A THEN
        tx_xor_rx <= (txfifo_q XOR rxfifo_q);
      ELSE
        tx_xor_rx <= (OTHERS => '0');
      END IF;
    END IF;
  END PROCESS xor_latch;

  rx_fifo : fifo
    PORT MAP (
      aclr  => local_aclr,
      clock => NOT ch1_rclk,
      data  => ch1_rxd,
      rdreq => rxfifo_rdreq,
      wrreq => ch1_rxd(17),
      empty => rxfifo_empty,
      full  => rxfifo_full,
      q     => rxfifo_q);

  rxfifo_rdreq    <= NOT (rxfifo_empty OR txfifo_empty);
  mt(17 DOWNTO 0) <= rxfifo_q;

  reset_sm : PROCESS (serdes_clk, m_all(1)) IS
  BEGIN  -- PROCESS reset_sm
    IF m_all(1) = '1' THEN
      y <= A;
    ELSIF serdes_clk'event AND serdes_clk = '1' THEN  -- rising clock edge
      CASE y IS
        WHEN A =>
          IF (tx_xor_rx = "000000000000000000") THEN
            y <= A;
          ELSE
            y <= B;
          END IF;
        WHEN B =>
          y <= C;
        WHEN C =>
          y <= D;
        WHEN D =>
          y <= A;
      END CASE;
    END IF;
  END PROCESS reset_sm;
  err_aclr <= '1' WHEN y = B ELSE '0';
  ma(18)   <= err_aclr;

  -- local_aclr <= m_all(1) OR err_aclr;   -- clear with dip switch 2 or error
  local_aclr <= m_all(1);               -- clear with dip switch 2 only


--  zbt_ctrl_top_inst1 : zbt_ctrl_top
--    GENERIC MAP (
--      FLOWTHROUGH => FLOWTHROUGH,
--      ASIZE       => ASIZE,
--      DSIZE       => DSIZE,
--      BWSIZE      => BWSIZE
--      )
--    PORT MAP (
--      clk           => PLL_clk,
--      RESET_N       => RESET_N,
---- local bus interface
--      ADDR          => ADDR,
--      DATA_IN       => DATA_IN,
--      DATA_OUT      => DATA_OUT,
--      RD_WR_N       => RD_WR_N,
--      ADDR_ADV_LD_N => ADDR_ADV_LD_N,
--      DM            => DM,
---- SRAM interface
--      SA            => SA,
--      DQ            => DQ,
--      RW_N          => RW_N,
--      ADV_LD_N      => ADV_LD_N,
--      BW_N          => BW_N
--      );

END a;

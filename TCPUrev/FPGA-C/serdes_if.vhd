-- $Id: serdes_if.vhd,v 1.4 2009-03-13 19:06:35 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES_IF
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_if.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-11-14
-- Last update: 2009-03-11
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Serdes Interface code for TCPU Rev B
-------------------------------------------------------------------------------
-- Copyright (c) 2007 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-11-14  1.0      jschamba        Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY altera;
USE altera.altera_primitives_components.ALL;

ENTITY serdes_if IS
  PORT
    (
      clk        : IN  std_logic;       -- Master clock
      serdata_in : IN  std_logic_vector(17 DOWNTO 0);
      rxd        : IN  std_logic_vector(17 DOWNTO 0);
      txd        : OUT std_logic_vector(17 DOWNTO 0);
      den        : OUT std_logic;
      ren        : OUT std_logic;
      sync       : OUT std_logic;
      tpwdn_n    : OUT std_logic;
      rpwdn_n    : OUT std_logic;
      lock_n     : IN  std_logic;
      rclk       : IN  std_logic;
      areset_n   : IN  std_logic;
      ch_ready   : OUT std_logic;
      pll_locked : IN  std_logic;
      trigger    : OUT std_logic;
      bunch_rst  : OUT std_logic

      );
END serdes_if;


ARCHITECTURE a OF serdes_if IS

  COMPONENT serdes_poweron IS
    PORT (
      clk         : IN  std_logic;      -- Master (40MHz) clock
      tpwdn_n     : OUT std_logic;
      rpwdn_n     : OUT std_logic;
      sync        : OUT std_logic;
      ch_lock_n   : IN  std_logic;
      ch_ready    : OUT std_logic;
      pll_locked  : IN  std_logic;
      rxd         : IN  std_logic_vector (17 DOWNTO 0);
      serdes_data : IN  std_logic_vector (17 DOWNTO 0);
      txd         : OUT std_logic_vector (17 DOWNTO 0);
      areset_n    : IN  std_logic);
  END COMPONENT serdes_poweron;

  SIGNAL s_ch_ready   : std_logic;
  SIGNAL s_txd        : std_logic_vector (17 DOWNTO 0);
  SIGNAL dff1_q       : std_logic;
  SIGNAL dff2_q       : std_logic;
  SIGNAL dff3_q       : std_logic;
  SIGNAL dff4_q       : std_logic;
  SIGNAL dff5_q       : std_logic;
  SIGNAL dff6_q       : std_logic;
  SIGNAL dff7_q       : std_logic;
  SIGNAL ff1_aresetn  : std_logic;
  SIGNAL ff2_aresetn  : std_logic;
  SIGNAL trg_phase0   : std_logic;
  SIGNAL trg_phase1   : std_logic;
  SIGNAL brst_phase1  : std_logic;
  SIGNAL brst_phase0  : std_logic;
  SIGNAL bff1_aresetn : std_logic;
  SIGNAL bff2_aresetn : std_logic;
  SIGNAL bdff1_q      : std_logic;
  SIGNAL bdff2_q      : std_logic;
  SIGNAL bdff3_q      : std_logic;

  FUNCTION bool2sl (b : boolean) RETURN std_logic IS
  BEGIN
    IF b THEN
      RETURN '1';
    ELSE
      RETURN '0';
    END IF;
  END bool2sl;

BEGIN

  den <= '1';                           -- tx enabled
  ren <= '1';                           -- rx enabled
  txd <= s_txd;                         -- from poweron state machine

  ch_ready <= s_ch_ready;

  -- Power Up State Machine for Serdes
  poweron_ch0 : serdes_poweron PORT MAP (
    clk         => clk,
    tpwdn_n     => tpwdn_n,
    rpwdn_n     => rpwdn_n,
    sync        => sync,
    ch_lock_n   => lock_n,
    ch_ready    => s_ch_ready,
    pll_locked  => pll_locked,
    rxd         => rxd,
    serdes_data => serdata_in,
    txd         => s_txd,
    areset_n    => areset_n);

  ff1_aresetn  <= s_ch_ready;
  ff2_aresetn  <= s_ch_ready;
  bff1_aresetn <= s_ch_ready;
  bff2_aresetn <= s_ch_ready;

------------------------------------------------------------------------------------
--      Trigger decode
------------------------------------------------------------------------------------
  -- trigger command from Serdes:
  -- rxd[17:16] = 11 or 10, so just check for rxd[17]
  -- rxd[15:12] = 0000 (phase A) or 0001 (phase B)

  -- Trigger Phase A: sync to 40MHz and shorten
  ff1 : PROCESS (clk, ff1_aresetn)
  BEGIN
    IF ff1_aresetn = '0' THEN           -- asynchronous reset (active low)
      dff1_q <= '0';
      dff2_q <= '0';
      dff3_q <= '0';
      
    ELSIF rising_edge(clk) THEN
      IF rxd(15 DOWNTO 12) = "0000" THEN
        dff1_q <= rxd(17);
      ELSE
        dff1_q <= '0';
      END IF;
      dff2_q <= dff1_q;
      dff3_q <= dff2_q;
    END IF;
  END PROCESS ff1;

  trg_phase0 <= dff2_q AND (NOT dff3_q);

  -- Trigger Phase B: sync to 40MHz, delay and shorten
  ff2 : PROCESS (clk, ff2_aresetn)
  BEGIN
    IF ff2_aresetn = '0' THEN           -- asynchronous reset (active low)
      dff4_q <= '0';
      dff5_q <= '0';
      dff6_q <= '0';
      dff7_q <= '0';
      
    ELSIF rising_edge(clk) THEN
      IF rxd(15 DOWNTO 12) = "0001" THEN
        dff4_q <= rxd(17);
      ELSE
        dff4_q <= '0';
      END IF;
      dff5_q <= dff4_q;
      dff6_q <= dff5_q;
      dff7_q <= dff6_q;
    END IF;
  END PROCESS ff2;

  trg_phase1 <= dff6_q AND (NOT dff7_q);

  -- Final trigger is either Phase A or Phase B trigger
  trigger <= trg_phase1 OR trg_phase0;

------------------------------------------------------------------------------------
--      Bunch Reset decode
------------------------------------------------------------------------------------
  -- bunch reset command from Serdes:
  -- rxd[17:11] = 0100100 (phase A) or 0100101 (phase B)

  -- Bunch Reset Phase A: sync to 40MHz
  bff1 : PROCESS (clk, bff1_aresetn)
  BEGIN
    IF bff1_aresetn = '0' THEN          -- asynchronous reset (active low)
      bdff1_q <= '0';
      
    ELSIF rising_edge(clk) THEN
      IF rxd(17 DOWNTO 11) = "0100100" THEN
        bdff1_q <= '1';
      ELSE
        bdff1_q <= '0';
      END IF;
      brst_phase0 <= bdff1_q;
    END IF;
  END PROCESS bff1;

  -- Bunch Reset Phase B: sync to 40MHz and delay
  bff2 : PROCESS (clk, bff2_aresetn)
  BEGIN
    IF bff2_aresetn = '0' THEN          -- asynchronous reset (active low)
      bdff2_q <= '0';
      bdff3_q <= '0';
      
    ELSIF rising_edge(clk) THEN
      IF rxd(17 DOWNTO 11) = "0100101" THEN
        bdff2_q <= '1';
      ELSE
        bdff2_q <= '0';
      END IF;
      bdff3_q     <= bdff2_q;
      brst_phase1 <= bdff3_q;
    END IF;
  END PROCESS bff2;

  -- Final bunch reset is either Phase A or Phase B bunch reset:
  bunch_rst <= brst_phase0 OR brst_phase1;
  
END a;

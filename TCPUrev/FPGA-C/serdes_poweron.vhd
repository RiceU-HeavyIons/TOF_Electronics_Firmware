-- $Id: serdes_poweron.vhd,v 1.8 2009-04-07 22:27:44 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES Poweron for TCPU
-- Project    : TCPU_B_TOP
-------------------------------------------------------------------------------
-- File       : serdes_poweron.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-05-24
-- Last update: 2009-04-07
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: SERDES Poweron procedure
-------------------------------------------------------------------------------
-- Copyright (c) 2007
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-05-24  1.0      jschamba        Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera;
USE altera.altera_primitives_components.ALL;
-- USE work.my_conversions.ALL;
-- USE work.my_utilities.ALL;

ENTITY serdes_poweron IS
  PORT
    (
      clk         : IN  std_logic;      -- Master clock
      tpwdn_n     : OUT std_logic;
      rpwdn_n     : OUT std_logic;
      sync        : OUT std_logic;
      ch_lock_n   : IN  std_logic;
      ch_ready    : OUT std_logic;
      pll_locked  : IN  std_logic;
      rxd         : IN  std_logic_vector (17 DOWNTO 0);
      txd         : OUT std_logic_vector (17 DOWNTO 0);
      serdes_data : IN  std_logic_vector (17 DOWNTO 0);
      areset_n    : IN  std_logic

      );
END serdes_poweron;


ARCHITECTURE a OF serdes_poweron IS
  CONSTANT LOCK_PATTERN_THUB : std_logic_vector := "000001001000110100";
  CONSTANT LOCK_PATTERN_TCPU : std_logic_vector := "000100001100100001";
  CONSTANT SYNC_PATTERN      : std_logic_vector := "000000000111111111";

  TYPE poweron_state IS (
    PO_INIT,
    PO_WAIT_PLL,
    PO_TURNON,
    PO_WAIT_SYNC,
    PO_REPLY_SYNC,
    PO_SEARCH_PATTERN,
    PO_PATTERN,
    PO_WAIT_LOCK,
    PO_LOCKED
    );

  SIGNAL poweron_present : poweron_state;

  SIGNAL counter_q       : std_logic_vector (4 DOWNTO 0);
  SIGNAL s_serdes_tx_sel : std_logic;
  SIGNAL s1_rxd          : std_logic_vector (17 DOWNTO 0) := "000000000000000000";
  SIGNAL s2_rxd          : std_logic_vector (17 DOWNTO 0) := "000000000000000000";
  SIGNAL s1_ch_lock_n    : std_logic                      := '1';
  SIGNAL s2_ch_lock_n    : std_logic                      := '1';

BEGIN

  s2_ch_lock_n <= ch_lock_n;
  s2_rxd       <= rxd;

  -- sync Serdes signals to 40 MHz clock with 2 DFFs
--  synchronizer : PROCESS (clk, areset_n) IS
--  BEGIN
--    IF areset_n = '0' THEN              -- asynchronous reset (active low)
--      s1_rxd       <= (OTHERS => '0');
--      s2_rxd       <= (OTHERS => '0');
--      s1_ch_lock_n <= '1';
--      s2_ch_lock_n <= '1';

--    ELSIF rising_edge(clk) THEN
--      s2_rxd       <= s1_rxd;
--      s1_rxd       <= rxd;
--      s2_ch_lock_n <= s1_ch_lock_n;
--      s1_ch_lock_n <= ch_lock_n;
--    END IF;
--  END PROCESS synchronizer;

  poweron : PROCESS (clk, areset_n) IS

  BEGIN  -- PROCESS poweron
    IF areset_n = '0' THEN              -- asynchronous reset (active low)

      poweron_present <= PO_INIT;
      tpwdn_n         <= '0';           -- tx powered down
      rpwdn_n         <= '0';           -- rx powered down
      sync            <= '0';           -- sync turned off
      ch_ready        <= '0';
      s_serdes_tx_sel <= '0';
      
    ELSIF rising_edge(clk) THEN         -- rising clock edge

      tpwdn_n         <= '0';           -- tx default: powered down
      rpwdn_n         <= '0';           -- rx default: powered down
      sync            <= '0';
      ch_ready        <= '0';
      s_serdes_tx_sel <= '0';           -- TX data default: "normal" data

      CASE poweron_present IS
        WHEN PO_INIT =>
          counter_q <= (OTHERS => '0');  -- reset counter
          IF pll_locked = '1' THEN       -- wait for clock lock
            poweron_present <= PO_WAIT_PLL;
          END IF;
          
        WHEN PO_WAIT_PLL =>
          counter_q <= counter_q + 1;
          IF counter_q(4) = '1' THEN     -- wait a little
            poweron_present <= PO_TURNON;
          ELSIF pll_locked = '0' THEN    -- if we loose PLL lock
            poweron_present <= PO_INIT;  -- start over
          ELSE
            poweron_present <= PO_WAIT_PLL;
          END IF;

          -- turn on Rx
        WHEN PO_TURNON =>
          rpwdn_n <= '1';               -- rx powered ON

          poweron_present <= PO_WAIT_SYNC;

          -- wait for SERDES lock and sync pattern on Rx
        WHEN PO_WAIT_SYNC =>
          rpwdn_n <= '1';               -- rx powered ON

          IF (s2_ch_lock_n = '0') AND (rxd = SYNC_PATTERN) THEN
            poweron_present <= PO_REPLY_SYNC;
          END IF;

          -- turn on TX and sync pattern
        WHEN PO_REPLY_SYNC =>
          sync    <= '1';               -- sync turned on
          tpwdn_n <= '1';               -- tx powered on
          rpwdn_n <= '1';               -- rx powered ON

          poweron_present <= PO_SEARCH_PATTERN;

          -- while sync is turned on, wait for LOCK pattern from THUB
        WHEN PO_SEARCH_PATTERN =>
          sync    <= '1';               -- sync turned on
          tpwdn_n <= '1';               -- tx powered on
          rpwdn_n <= '1';               -- rx powered ON

          IF s2_rxd = LOCK_PATTERN_THUB THEN  -- wait for pattern on Rx
            poweron_present <= PO_PATTERN;
          ELSIF s2_ch_lock_n = '1' THEN       -- if we loose hardware lock
            poweron_present <= PO_INIT;       -- start all over
          END IF;

          -- reply with TCPU LOCK pattern
        WHEN PO_PATTERN =>
          tpwdn_n         <= '1';       -- tx powered on
          rpwdn_n         <= '1';       -- rx powered on
          s_serdes_tx_sel <= '1';       -- send lock pattern

          poweron_present <= PO_WAIT_LOCK;

          -- hold TCPU LOCK pattern until THUB LOCK pattern goes away
        WHEN PO_WAIT_LOCK =>
          tpwdn_n         <= '1';       -- tx powered on
          rpwdn_n         <= '1';       -- rx powered on
          s_serdes_tx_sel <= '1';       -- send lock pattern

          IF s2_rxd = LOCK_PATTERN_THUB THEN
            poweron_present <= PO_WAIT_LOCK;
          ELSE
            poweron_present <= PO_LOCKED;  -- then move on to "Locked" state
          END IF;

          -- now we are locked and ready, watch for Serdes lock to go away
        WHEN PO_LOCKED =>
          tpwdn_n  <= '1';              -- tx powered on
          rpwdn_n  <= '1';              -- rx powered on
          ch_ready <= '1';              -- signal that  we achieved lock

          IF (s2_ch_lock_n = '1') THEN   -- if we ever loose lock
            poweron_present <= PO_INIT;  -- start all over again
          END IF;

      END CASE;

    END IF;
  END PROCESS poweron;

  -- MUX for serdes TX
  WITH s_serdes_tx_sel SELECT
    txd <=
    serdes_data       WHEN '0',
    LOCK_PATTERN_TCPU WHEN OTHERS;

END a;

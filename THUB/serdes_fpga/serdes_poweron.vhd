-- $Id: serdes_poweron.vhd,v 1.6 2009-03-16 14:59:46 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES Poweron
-- Project    : SERDES_FPGA
-------------------------------------------------------------------------------
-- File       : serdes_poweron.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-05-24
-- Last update: 2009-03-13
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
--USE work.my_conversions.ALL;
--USE work.my_utilities.ALL;

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
    PO_SYNC,
    PO_WAIT_SYNC,
    PO_PATTERN,
    PO_WAIT_PATTERN,
    PO_LOCKED
    );
  SIGNAL poweron_next, poweron_present : poweron_state;

  SIGNAL counter_q       : std_logic_vector (4 DOWNTO 0);
  SIGNAL s_serdes_tx_sel : std_logic;


BEGIN


  -- purpose: power on state machine for channel 0
  -- type   : sequential
  -- inputs : clk, areset_n
  -- outputs: 
  poweron : PROCESS (clk, areset_n) IS
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)

      poweron_present <= PO_INIT;
      poweron_next    <= PO_INIT;
      tpwdn_n         <= '0';           -- tx powered down
      rpwdn_n         <= '0';           -- rx powered down
      sync            <= '0';           -- sync turned off
      ch_ready        <= '0';
      s_serdes_tx_sel <= '1';
      
    ELSIF rising_edge(clk) THEN
      -- defaults:
      tpwdn_n         <= '0';           -- tx powered down
      rpwdn_n         <= '0';           -- rx powered down
      sync            <= '0';           -- sync turned off
      ch_ready        <= '0';           -- channel not ready
      s_serdes_tx_sel <= '0';           -- default: normal data

      CASE poweron_present IS

        -- wait for clock to be stable (PLL is locked)
        WHEN PO_INIT =>
          counter_q <= (OTHERS => '0');  -- reset counter
          IF pll_locked = '1' THEN
            poweron_next <= PO_WAIT_PLL;
          ELSE
            poweron_next <= PO_INIT;
          END IF;

          -- wait a little to let the clock stabilize
        WHEN PO_WAIT_PLL =>
          counter_q <= counter_q + 1;
          IF counter_q(4) = '1' THEN    -- wait a little
            poweron_next <= PO_SYNC;
          ELSIF pll_locked = '0' THEN   -- if we loose PLL lock
            poweron_next <= PO_INIT;    -- start over
          ELSE
            poweron_next <= PO_WAIT_PLL;
          END IF;

          -- start sync pattern
        WHEN PO_SYNC =>
          tpwdn_n <= '1';               -- tx powered on
          rpwdn_n <= '1';               -- rx powered on
          sync    <= '1';               -- sync turned on

          poweron_next <= PO_WAIT_SYNC;

          -- wait for SERDES lock and sync pattern on Rx  
        WHEN PO_WAIT_SYNC =>
          tpwdn_n <= '1';               -- tx powered on
          rpwdn_n <= '1';               -- rx powered on
          sync    <= '1';               -- sync turned on

          IF (ch_lock_n = '0') AND (rxd = SYNC_PATTERN) THEN
            poweron_next <= PO_PATTERN;
          ELSE
            poweron_next <= PO_WAIT_SYNC;
          END IF;

          -- Turn sync off, send lock pattern
        WHEN PO_PATTERN =>
          counter_q       <= (OTHERS => '0');  -- reset counter
          tpwdn_n         <= '1';              -- tx powered on
          rpwdn_n         <= '1';              -- rx powered ON
          s_serdes_tx_sel <= '1';              -- send lock pattern

          poweron_next <= PO_WAIT_PATTERN;

          -- wait for lock pattern response from TCPU
        WHEN PO_WAIT_PATTERN =>
          tpwdn_n         <= '1';       -- tx powered on
          rpwdn_n         <= '1';       -- rx powered on
          s_serdes_tx_sel <= '1';       -- send lock pattern

          IF rxd = LOCK_PATTERN_TCPU THEN  -- look for pattern to be sent back
            poweron_next <= PO_LOCKED;
          ELSIF ch_lock_n = '1' THEN       -- if we loose lock
            poweron_next <= PO_INIT;       -- start over
          ELSE
            poweron_next <= PO_WAIT_PATTERN;
          END IF;

          -- Now we are connected! Watch if we loose lock
        WHEN PO_LOCKED =>
          tpwdn_n  <= '1';              -- tx powered on
          rpwdn_n  <= '1';              -- rx powered on
          ch_ready <= '1';              -- signal that we are locked and ready

          IF (ch_lock_n = '1') THEN     -- if we ever loose lock
            poweron_next <= PO_INIT;    -- start all over
          END IF;

      END CASE;

      -- change state:
      poweron_present <= poweron_next;

    END IF;
  END PROCESS poweron;

  -- MUX for serdes TX
  WITH s_serdes_tx_sel SELECT
    txd <=
    serdes_data       WHEN '0',
    LOCK_PATTERN_THUB WHEN OTHERS;

END a;

-- $Id$
-------------------------------------------------------------------------------
-- Title      : SERDES Poweron
-- Project    : SERDES_FPGA
-------------------------------------------------------------------------------
-- File       : serdes_poweron.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-05-24
-- Last update: 2012-10-31
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

ENTITY serdes_poweron IS
  PORT (
    clk         : IN  std_logic;        -- Master clock
    tpwdn_n     : OUT std_logic;        -- TX power down (active low)
    rpwdn_n     : OUT std_logic;        -- RX power down (active low)
    sync        : OUT std_logic;        -- sync pattern
    ch_lock_n   : IN  std_logic;        -- channel locked (active low)
    ch_ready    : OUT std_logic;        -- channel ready
    pll_locked  : IN  std_logic;
    rxd         : IN  std_logic_vector (17 DOWNTO 0);
    txd         : OUT std_logic_vector (17 DOWNTO 0);
    serdes_data : IN  std_logic_vector (17 DOWNTO 0);
    areset_n    : IN  std_logic
    );
END serdes_poweron;


ARCHITECTURE a OF serdes_poweron IS
  CONSTANT ALL_ZEROS         : std_logic_vector := "00" & x"0000";
  CONSTANT LOCK_PATTERN_THUB : std_logic_vector := "00" & x"1234";
  CONSTANT LOCK_PATTERN_TCPU : std_logic_vector := "00" & x"4321";
  CONSTANT SYNC_PATTERN      : std_logic_vector := "00" & x"01FF";

  TYPE poweronState_type IS (
    PO1, PO2, PO3, PO4, PO5, PO6, PO7
    );
  SIGNAL poweronState : poweronState_type;

  SIGNAL s_rxd        : std_logic_vector(17 DOWNTO 0);
  SIGNAL latch_areset : std_logic;


BEGIN

  -- RX values stay valid long enough relative to board
  -- clock that they don't need to be latched.
  WITH ch_lock_n SELECT
    s_rxd <=
    rxd       WHEN '0',
    ALL_ZEROS WHEN OTHERS;

  -- Power-On state machine
  poweron : PROCESS (clk, areset_n) IS
    VARIABLE vCounter : integer RANGE 0 TO 127 := 0;
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      poweronState <= PO1;
      tpwdn_n      <= '0';              -- tx powered down
      rpwdn_n      <= '0';              -- rx powered down
      sync         <= '0';              -- sync turned off
      ch_ready     <= '0';
      vCounter     := 0;

    ELSIF falling_edge(clk) THEN
      -- defaults:
      tpwdn_n  <= '1';                  -- tx powered up all the time
      rpwdn_n  <= '0';                  -- rx powered down
      sync     <= '0';                  -- sync turned off
      ch_ready <= '0';                  -- channel not ready
      txd      <= serdes_data;          -- default: normal data

      CASE poweronState IS

--      wait for clock to be stable (PLL is locked)
        WHEN PO1 =>
          vCounter := 0;                -- reset counter
          sync     <= '1';              -- sync turned on
          IF pll_locked = '1' THEN
            poweronState <= PO2;
          ELSE
            poweronState <= PO1;
          END IF;

--      wait a little to let the clock stabilize
        WHEN PO2 =>
          sync <= '1';                  -- sync turned on
          IF pll_locked = '0' THEN
            poweronState <= PO1;
          ELSIF vCounter = 4 THEN
            poweronState <= PO3;
          ELSE
            vCounter := vCounter + 1;
          END IF;

--      turn on tx, rx and sync
        WHEN PO3 =>
          vCounter     := 0;
          rpwdn_n      <= '1';          -- rx powered down
          sync         <= '1';          -- sync turned off
          poweronState <= PO4;

--      wait for hardware lock
        WHEN PO4 =>
          tpwdn_n <= '1';               -- tx powered down
          rpwdn_n <= '1';               -- rx powered down
          sync    <= '1';               -- sync turned off

          IF (ch_lock_n = '0') AND (s_rxd = SYNC_PATTERN) AND (vCounter = 32) THEN
            -- if lock has been on long enough
            poweronState <= PO5;
          ELSIF (ch_lock_n = '0') AND (vCounter = 32) THEN
            -- possibly locked on noise, since we don't see the right pattern
            -- try powering down and up again
            poweronState <= PO1;
          ELSIF ch_lock_n = '0' THEN
            vCounter := vCounter + 1;
          ELSE
            -- reset counter if we loose lock again
            vCounter := 0;
          END IF;

--      send LOCK_PATTERN_THUB
        WHEN PO5 =>
          tpwdn_n      <= '1';          -- tx powered down
          rpwdn_n      <= '1';          -- rx powered down
          txd          <= LOCK_PATTERN_THUB;
          poweronState <= PO6;

--      wait for LOCK_PATTERN_TCPU
        WHEN PO6 =>
          tpwdn_n <= '1';               -- tx powered down
          rpwdn_n <= '1';               -- rx powered down
          txd     <= LOCK_PATTERN_THUB;

          IF s_rxd = LOCK_PATTERN_TCPU THEN
            poweronState <= PO7;
          ELSIF ch_lock_n = '1' THEN
            -- if we loose lock, start sync pattern again
            poweronState <= PO3;
          ELSE
            poweronState <= PO6;
          END IF;

--      SerDes ready
        WHEN PO7 =>
          tpwdn_n  <= '1';              -- tx powered down
          rpwdn_n  <= '1';              -- rx powered down
          ch_ready <= '1';              -- channel ready

          IF (ch_lock_n = '1') OR (pll_locked = '0') THEN
            poweronState <= PO1;
          END IF;
          
      END CASE;
    END IF;
  END PROCESS poweron;
END a;

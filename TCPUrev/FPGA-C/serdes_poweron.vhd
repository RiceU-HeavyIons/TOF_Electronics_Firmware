-- $Id$
-------------------------------------------------------------------------------
-- Title      : SERDES Poweron for TCPU
-- Project    : TCPU_B_TOP
-------------------------------------------------------------------------------
-- File       : serdes_poweron.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-05-24
-- Last update: 2012-11-01
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

--  latch_areset <= ch_lock_n;            -- high when NOT locked
--  -- latch receiver data with receiver clock
--  latch_FF : PROCESS (ch_rclk, latch_areset) IS
--  BEGIN  -- PROCESS latch_FF
--    IF latch_areset = '1' THEN          -- asynchronous reset (active high)
--      s_rxd <= (OTHERS => '0');
--    ELSIF rising_edge(ch_rclk) THEN
--      s_rxd <= rxd;
--    END IF;
--  END PROCESS latch_FF;

  WITH ch_lock_n SELECT
    s_rxd <=
    rxd       WHEN '0',
    ALL_ZEROS WHEN OTHERS;

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
      tpwdn_n  <= '0';                  -- tx powered down
      rpwdn_n  <= '0';                  -- rx powered down
      sync     <= '0';                  -- sync turned off
      ch_ready <= '0';                  -- channel not ready
      txd      <= serdes_data;          -- default: normal data

      CASE poweronState IS

--      wait for clock to be stable (PLL is locked)
        WHEN PO1 =>
          vCounter := 0;                -- reset counter
          IF pll_locked = '1' THEN
            poweronState <= PO2;
          ELSE
            poweronState <= PO1;
          END IF;

--      wait a little to let the clock stabilize
        WHEN PO2 =>
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
          tpwdn_n      <= '1';          -- tx powered up
          rpwdn_n      <= '1';          -- rx powered up
          sync         <= '1';          -- sync turned on
          poweronState <= PO4;

--      wait for hardware lock
        WHEN PO4 =>
          tpwdn_n <= '1';               -- tx powered up
          rpwdn_n <= '1';               -- rx powered up
          sync    <= '1';               -- sync turned on

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

--      wait for LOCK_PATTERN_THUB
        WHEN PO5 =>
          tpwdn_n <= '1';               -- tx powered up
          rpwdn_n <= '1';               -- rx powered up
          sync    <= '1';               -- sync turned on
          
          IF s_rxd = LOCK_PATTERN_THUB THEN
            poweronState <= PO6;
          ELSIF ch_lock_n = '1' THEN
            -- if we loose lock, start sync pattern again
            poweronState <= PO3;
          ELSE
             poweronState <= PO5;
          END IF;

--      send LOCK_PATTERN_TCPU
--      wait for LOCK_PATTERN_THUB to stop
        WHEN PO6 =>
          tpwdn_n <= '1';               -- tx powered up
          rpwdn_n <= '1';               -- rx powered up
          txd     <= LOCK_PATTERN_TCPU;

          IF s_rxd = LOCK_PATTERN_THUB THEN
            poweronState <= PO6;
          ELSIF ch_lock_n = '1' THEN
            -- if we loose lock, start sync pattern again
            poweronState <= PO3;
          ELSE
             poweronState <= PO7;
          END IF;

--      SerDes ready
        WHEN PO7 =>
          tpwdn_n  <= '1';              -- tx powered up
          rpwdn_n  <= '1';              -- rx powered up
          ch_ready <= '1';              -- channel ready

          IF (ch_lock_n = '1') OR (pll_locked = '0') THEN
            poweronState <= PO1;
          END IF;
          
      END CASE;
    END IF;
  END PROCESS poweron;

END a;

-- $Id$
-------------------------------------------------------------------------------
-- Title      : SERDES Poweron for TCPU
-- Project    : TCPU_B_TOP
-------------------------------------------------------------------------------
-- File       : serdes_poweron.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-05-24
-- Last update: 2012-11-21
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
      po_state    : OUT std_logic_vector (2 DOWNTO 0);
      areset_n    : IN  std_logic

      );
END serdes_poweron;


ARCHITECTURE a OF serdes_poweron IS
  CONSTANT ALL_ZEROS         : std_logic_vector := "00" & x"0000";
  CONSTANT LOCK_PATTERN_THUB : std_logic_vector := "00" & x"1234";
  CONSTANT LOCK_PATTERN_TCPU : std_logic_vector := "00" & x"4321";
  CONSTANT SYNC_PATTERN      : std_logic_vector := "00" & x"01FF";

  TYPE poweronState_type IS (
    PO1, PO2, PO3, PO4, PO5, PO6
    );
  SIGNAL poweronState : poweronState_type;

  SIGNAL s_rxd        : std_logic_vector(17 DOWNTO 0);
  SIGNAL latch_areset : std_logic;
  SIGNAL s_ch_lock_n  : std_logic;


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

  -- latch the lock signal and the RX data with the system clock
  PROCESS (clk, areset_n) IS
  BEGIN  -- PROCESS
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      s_rxd       <= (OTHERS => '0');
      s_ch_lock_n <= '1';
    ELSIF falling_edge(clk) THEN
      s_ch_lock_n <= ch_lock_n;
      s_rxd       <= rxd;
    END IF;
  END PROCESS;

  -- PowerOn state machine
  poweron : PROCESS (clk, areset_n) IS
    VARIABLE vCounter : integer RANGE 0 TO 127 := 0;
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      po_state     <= "000";
      poweronState <= PO1;
      tpwdn_n      <= '0';              -- tx powered down
      rpwdn_n      <= '0';              -- rx powered down
      sync         <= '0';              -- sync turned off
      txd          <= (OTHERS => '0');  -- all zeros
      ch_ready     <= '0';
      vCounter     := 0;

    ELSIF falling_edge(clk) THEN
      CASE poweronState IS

--      wait for clock to be stable (PLL is locked)
        WHEN PO1 =>
          po_state <= "001";
          tpwdn_n  <= '0';              -- tx powered down
          rpwdn_n  <= '0';              -- rx powered down
          sync     <= '0';              -- sync turned off
          txd      <= (OTHERS => '0');  -- all zeros
          ch_ready <= '0';

          vCounter := 0;                -- reset counter
          IF pll_locked = '1' THEN
            poweronState <= PO2;
          ELSE
            poweronState <= PO1;
          END IF;

--      wait a little to let the clock stabilize
        WHEN PO2 =>
          po_state <= "010";
          tpwdn_n  <= '0';              -- tx powered down
          rpwdn_n  <= '0';              -- rx powered down
          sync     <= '0';              -- sync turned off
          txd      <= (OTHERS => '0');  -- all zeros
          ch_ready <= '0';

          IF pll_locked = '0' THEN
            poweronState <= PO1;
          ELSIF vCounter = 4 THEN
            poweronState <= PO3;
          ELSE
            vCounter := vCounter + 1;
          END IF;

--      turn on tx, rx and sync
        WHEN PO3 =>
          po_state <= "011";
          tpwdn_n  <= '1';              -- tx powered up
          rpwdn_n  <= '1';              -- rx powered up
          sync     <= '1';              -- sync turned on
          txd      <= (OTHERS => '0');  -- all zeros
          ch_ready <= '0';

          vCounter     := 0;
          poweronState <= PO4;

--      wait for hardware lock
        WHEN PO4 =>
          po_state <= "100";
          tpwdn_n  <= '1';              -- tx powered up
          rpwdn_n  <= '1';              -- rx powered up
          sync     <= '1';              -- sync turned on
          txd      <= (OTHERS => '0');  -- all zeros
          ch_ready <= '0';

          IF (s_ch_lock_n = '0') AND (s_rxd = SYNC_PATTERN) AND (vCounter = 32) THEN
            -- if lock has been on long enough
            poweronState <= PO5;
--          ELSIF (ch_lock_n = '0') AND (vCounter = 32) THEN
--            -- possibly locked on noise, since we don't see the right pattern
--            -- try powering down and up again
--            poweronState <= PO1;
          ELSIF (s_ch_lock_n = '0') AND (s_rxd = SYNC_PATTERN) THEN
            vCounter := vCounter + 1;
--          ELSIF (s_ch_lock_n = '0') THEN
--            -- possibly locked on noise, since we don't see the right pattern
--            -- try powering down and up again
--            poweronState <= PO1;
          ELSE
            -- reset counter if we loose lock again
            vCounter := 0;
          END IF;


--      wait for SYNC_PATTERN to stop
        WHEN PO5 =>
          po_state <= "101";
          tpwdn_n  <= '1';              -- tx powered up
          rpwdn_n  <= '1';              -- rx powered up
          sync     <= '0';              -- sync turned off
          txd      <= (OTHERS => '0');  -- all zeros
          ch_ready <= '0';

          IF s_rxd = SYNC_PATTERN THEN
            poweronState <= PO5;
          ELSE
            poweronState <= PO6;
          END IF;

--      SerDes ready
        WHEN PO6 =>
          po_state <= "110";
          tpwdn_n  <= '1';              -- tx powered up
          rpwdn_n  <= '1';              -- rx powered up
          sync     <= '0';              -- sync turned off
          ch_ready <= '1';              -- channel ready
          txd      <= serdes_data;      -- default: normal data

--          IF (s_ch_lock_n = '1') OR (pll_locked = '0') THEN
--            poweronState <= PO1;
--          END IF;
          
      END CASE;
    END IF;
  END PROCESS poweron;

END a;

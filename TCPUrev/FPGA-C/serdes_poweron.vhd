-- $Id: serdes_poweron.vhd,v 1.5 2008-08-05 21:42:32 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES Poweron for TCPU
-- Project    : TCPU_B_TOP
-------------------------------------------------------------------------------
-- File       : serdes_poweron.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-05-24
-- Last update: 2008-06-30
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

  COMPONENT mux18x2 IS
    PORT (
      data0x : IN  std_logic_vector (17 DOWNTO 0);
      data1x : IN  std_logic_vector (17 DOWNTO 0);
      sel    : IN  std_logic;
      result : OUT std_logic_vector (17 DOWNTO 0));
  END COMPONENT mux18x2;

  TYPE poweron_state IS (
    PO_INIT,
    PO_SYNC,
    PO_SEARCH_PATTERN,
    PO_PATTERN,
    PO_LOCKED
    );

  SIGNAL poweron_present : poweron_state;

  SIGNAL counter_q       : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_serdes_tx_sel : std_logic;
  SIGNAL s1_rxd          : std_logic_vector (17 DOWNTO 0) := "000000000000000000";
  SIGNAL s2_rxd          : std_logic_vector (17 DOWNTO 0) := "000000000000000000";
  SIGNAL s1_ch_lock_n    : std_logic                      := '1';
  SIGNAL s2_ch_lock_n    : std_logic                      := '1';

BEGIN

--  s2_ch_lock_n <= ch_lock_n;
--  s2_rxd <= rxd;

  -- sync Serdes signals to 40 MHz clock with 2 DFFs
  synchronizer : PROCESS (clk, areset_n) IS
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      s1_rxd       <= (OTHERS => '0');
      s2_rxd       <= (OTHERS => '0');
      s1_ch_lock_n <= '1';
      s2_ch_lock_n <= '1';
      
    ELSIF clk'event AND clk = '1' THEN  -- rising clock edge
      s2_rxd       <= s1_rxd;
      s1_rxd       <= rxd;
      s2_ch_lock_n <= s1_ch_lock_n;
      s1_ch_lock_n <= ch_lock_n;
    END IF;
  END PROCESS synchronizer;

  -- purpose: power on state machine for Serdes channel
  -- type   : sequential
  -- inputs : clk, areset_n
  -- outputs: 
  poweron : PROCESS (clk, areset_n) IS

  BEGIN  -- PROCESS poweron
    IF areset_n = '0' THEN              -- asynchronous reset (active low)

      poweron_present <= PO_INIT;
      tpwdn_n         <= '0';           -- tx powered down
      rpwdn_n         <= '0';           -- rx powered down
      sync            <= '0';           -- sync turned off
      ch_ready        <= '0';
      s_serdes_tx_sel <= '0';
      
    ELSIF clk'event AND clk = '1' THEN  -- rising clock edge

      tpwdn_n         <= '0';           -- tx default: powered down
      rpwdn_n         <= '0';           -- rx default: powered down
      sync            <= '0';
      ch_ready        <= '0';
      s_serdes_tx_sel <= '0';           -- TX data default: "normal" data

      CASE poweron_present IS
        WHEN PO_INIT =>
          IF pll_locked = '1' THEN            -- wait for clock lock
            poweron_present <= PO_SYNC;
          END IF;
        WHEN PO_SYNC =>
          rpwdn_n <= '1';                     -- rx powered on
          -- wait for SERDES lock and sync pattern on Rx
          IF (s2_ch_lock_n = '0') AND (s2_rxd = SYNC_PATTERN) THEN
            poweron_present <= PO_SEARCH_PATTERN;
          END IF;
        WHEN PO_SEARCH_PATTERN =>
          sync      <= '1';                   -- sync turned on
          tpwdn_n   <= '1';                   -- tx powered on
          rpwdn_n   <= '1';                   -- rx powered on
          counter_q <= (OTHERS => '0');       -- clear counter
          IF s2_rxd = LOCK_PATTERN_THUB THEN  -- wait for pattern on RX
            poweron_present <= PO_PATTERN;
          END IF;
        WHEN PO_PATTERN =>
          tpwdn_n         <= '1';             -- tx powered on
          rpwdn_n         <= '1';             -- rx powered on
          s_serdes_tx_sel <= '1';             -- send lock pattern
          counter_q       <= counter_q + 1;   -- increment counter
          IF counter_q(3) = '1' THEN          -- hold pattern for 7 clocks
            poweron_present <= PO_LOCKED;     -- then move on to "Locked" state
          END IF;
        WHEN PO_LOCKED =>
          tpwdn_n  <= '1';                    -- tx powered on
          rpwdn_n  <= '1';                    -- rx powered on
          ch_ready <= '1';                    -- signal that  we achieved lock

          IF (s2_ch_lock_n = '1') THEN   -- if we ever loose lock
            poweron_present <= PO_INIT;  -- start all over again
          END IF;
        WHEN OTHERS =>
          poweron_present <= PO_INIT;
      END CASE;

    END IF;
  END PROCESS poweron;

  -- MUX for serdes TX
  mux_inst : mux18x2 PORT MAP (
    data0x => serdes_data,
    data1x => LOCK_PATTERN_TCPU,
    sel    => s_serdes_tx_sel,
    result => txd);


END a;

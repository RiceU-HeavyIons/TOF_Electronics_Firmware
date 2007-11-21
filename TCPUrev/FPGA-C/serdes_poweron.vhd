-- $Id: serdes_poweron.vhd,v 1.1 2007-11-21 16:44:06 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES Poweron
-- Project    : SERDES_FPGA
-------------------------------------------------------------------------------
-- File       : serdes_poweron.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-05-24
-- Last update: 2007-11-14
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

  SIGNAL counter_q       : std_logic_vector (11 DOWNTO 0);
  SIGNAL s_ctr_aclr      : std_logic;
  SIGNAL s_serdes_tx_sel : std_logic;


BEGIN

  counter4b : lpm_counter GENERIC MAP (
    LPM_WIDTH     => 12,
    LPM_TYPE      => "LPM_COUNTER",
    LPM_DIRECTION => "UP")
    PORT MAP (
      clock  => clk,
      q      => counter_q,
      clk_en => '1',
      aclr   => s_ctr_aclr);

  -- purpose: power on state machine for channel 0
  -- type   : sequential
  -- inputs : clk, areset_n
  -- outputs: 
  poweron : PROCESS (clk, areset_n) IS

    VARIABLE poweron_present : poweron_state;
    VARIABLE poweron_next    : poweron_state;
    
  BEGIN  -- PROCESS poweron
    IF areset_n = '0' THEN              -- asynchronous reset (active low)

      poweron_present := PO_INIT;
      poweron_next    := PO_INIT;
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
          s_ctr_aclr <= '1';               -- reset timeout ctr
          IF pll_locked = '1' THEN         -- wait for clock lock
            poweron_next := PO_SYNC;
          END IF;
        WHEN PO_SYNC =>
          rpwdn_n <= '1';                  -- rx powered on
          IF ch_lock_n = '0' THEN          -- wait for SERDES lock
            s_ctr_aclr   <= '0';           -- start counter
            poweron_next := PO_SEARCH_PATTERN;
          END IF;
        WHEN PO_SEARCH_PATTERN =>
          sync    <= '1';                  -- sync turned on
          tpwdn_n <= '1';                  -- tx powered on
          rpwdn_n <= '1';                  -- rx powered on
          IF rxd = LOCK_PATTERN_THUB THEN  -- wait for pattern on RX
            poweron_next := PO_PATTERN;
            s_ctr_aclr   <= '1';           -- reset timeout counter
          ELSIF counter_q(11) = '1' THEN   -- timeout (lock seems to take 30us)
            poweron_next := PO_INIT;
          END IF;
        WHEN PO_PATTERN =>
          tpwdn_n         <= '1';          -- tx powered on
          rpwdn_n         <= '1';          -- rx powered on
          s_ctr_aclr      <= '0';          -- start timeout ctr
          s_serdes_tx_sel <= '1';          -- send lock pattern
          IF counter_q(1) = '1' THEN       -- hold pattern for 2 clocks
            poweron_next := PO_LOCKED;     -- then move on to "Locked" state
          END IF;
        WHEN PO_LOCKED =>
          tpwdn_n  <= '1';                 -- tx powered on
          rpwdn_n  <= '1';                 -- rx powered on
          ch_ready <= '1';                 -- signal that  we achieved lock

          IF (ch_lock_n = '1') THEN     -- if we ever loose lock
            poweron_next := PO_INIT;    -- start all over again
          END IF;
        WHEN OTHERS =>
          rpwdn_n <= '1';               -- rx powered on
          tpwdn_n <= '1';               -- tx powered on

          poweron_next := PO_LOCKED;
      END CASE;
      poweron_present := poweron_next;

    END IF;
  END PROCESS poweron;

  -- MUX for serdes TX
  mux_inst : mux18x2 PORT MAP (
    data0x => serdes_data,
    data1x => LOCK_PATTERN_TCPU,
    sel    => s_serdes_tx_sel,
    result => txd);


END a;

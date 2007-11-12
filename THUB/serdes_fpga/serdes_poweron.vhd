-- $Id: serdes_poweron.vhd,v 1.2 2007-11-12 23:38:58 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES Poweron
-- Project    : SERDES_FPGA
-------------------------------------------------------------------------------
-- File       : serdes_poweron.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-05-24
-- Last update: 2007-11-12
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
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

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
  CONSTANT LOCK_PATTERN : std_logic_vector := "000001001000110100";

  COMPONENT mux18x2 IS
    PORT (
      data0x : IN  std_logic_vector (17 DOWNTO 0);
      data1x : IN  std_logic_vector (17 DOWNTO 0);
      sel    : IN  std_logic;
      result : OUT std_logic_vector (17 DOWNTO 0));
  END COMPONENT mux18x2;

  TYPE poweron_state IS (
    PO_INIT,
    PO_WAIT,
    PO_SYNC,
    PO_PATTERN,
    PO_LOCKED
    );

  SIGNAL counter_q       : std_logic_vector (16 DOWNTO 0);
  SIGNAL s_ctr_aclr      : std_logic;
  SIGNAL s_serdes_tx_sel : std_logic;
  SIGNAL s_serdes_start  : std_logic_vector(17 DOWNTO 0);


BEGIN

  counter17b : lpm_counter GENERIC MAP (
    LPM_WIDTH     => 17,
    LPM_TYPE      => "LPM_COUNTER",
    LPM_DIRECTION => "UP")
    PORT MAP (
      clock  => clk,
      q      => counter_q,
      clk_en => '1',
      aclr   => s_ctr_aclr);
  -- s_serdes_start <= '0' & counter_q;

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
      s_serdes_tx_sel <= '1';
      
    ELSIF clk'event AND clk = '1' THEN  -- rising clock edge

      tpwdn_n         <= '0';           -- tx powered down
      rpwdn_n         <= '0';           -- rx powered down
      sync            <= '0';
      ch_ready        <= '0';
      s_serdes_tx_sel <= '1';

      CASE poweron_present IS
        WHEN PO_INIT =>
          s_ctr_aclr <= '1';
          IF pll_locked = '1' THEN      -- wait for clock lock
            poweron_next := PO_WAIT;
          END IF;
        WHEN PO_WAIT =>
          tpwdn_n    <= '1';            -- tx powered on
          rpwdn_n    <= '1';            -- rx powered on
          sync       <= '1';            -- sync turned on
          s_ctr_aclr <= '0';            -- release timeout counter reset
          IF counter_q(16) = '1' THEN   -- when long timeout
            poweron_next := PO_SYNC;
          END IF;
        WHEN PO_SYNC =>
          s_ctr_aclr <= '1';            -- hold timeout ctr in reset
          tpwdn_n <= '1';               -- tx powered on
          rpwdn_n <= '1';               -- rx powered on
          sync    <= '1';               -- sync turned on

          IF ch_lock_n = '0' THEN       -- wait for SERDES lock
            poweron_next := PO_PATTERN;
          END IF;
        WHEN PO_PATTERN =>
          s_ctr_aclr <= '0';            -- release timeout ctr reset
          tpwdn_n <= '1';               -- tx powered on
          rpwdn_n <= '1';               -- rx powered on
          IF rxd = LOCK_PATTERN THEN
            poweron_next := PO_LOCKED;
          ELSIF counter_q(4) = '1' THEN  -- timeout after 16 clocks
            poweron_next := PO_WAIT;
          END IF;
        WHEN PO_LOCKED =>
          tpwdn_n         <= '1';       -- tx powered on
          rpwdn_n         <= '1';       -- rx powered on
          ch_ready        <= '1';
          s_serdes_tx_sel <= '0';

          IF (ch_lock_n = '1') THEN
            poweron_next := PO_INIT;
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
    data1x => LOCK_PATTERN,
    sel    => s_serdes_tx_sel,
    result => txd);


END a;

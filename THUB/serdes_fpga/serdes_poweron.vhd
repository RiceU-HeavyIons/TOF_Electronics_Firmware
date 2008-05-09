-- $Id: serdes_poweron.vhd,v 1.4 2008-05-09 16:15:33 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES Poweron
-- Project    : SERDES_FPGA
-------------------------------------------------------------------------------
-- File       : serdes_poweron.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-05-24
-- Last update: 2008-05-07
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
    PO_PATTERN,
    PO_LOCKED
    );

  SIGNAL counter_q       : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_ctr_aclr      : std_logic;
  SIGNAL s_serdes_tx_sel : std_logic;
  SIGNAL s_serdes_start  : std_logic_vector(17 DOWNTO 0);


BEGIN

  counter8b : lpm_counter GENERIC MAP (
    LPM_WIDTH     => 8,
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
      s_serdes_tx_sel <= '1';
      s_ctr_aclr      <= '1';           -- timeout ctr reset
      
    ELSIF clk'event AND clk = '1' THEN  -- rising clock edge

      tpwdn_n         <= '0';           -- tx powered down
      rpwdn_n         <= '0';           -- rx powered down
      sync            <= '0';
      ch_ready        <= '0';
      s_serdes_tx_sel <= '1';           -- default: lock pattern
      s_ctr_aclr      <= '0';           -- default: no timeout ctr reset

      CASE poweron_present IS
        -- wait for clock to be stable (PLL is locked)
        WHEN PO_INIT =>
          IF pll_locked = '1' THEN
            IF counter_q(4) = '1' THEN  -- wait a little
              poweron_next := PO_SYNC;
            END IF;
          ELSE
            s_ctr_aclr <= '1';
            poweron_next := PO_INIT;
          END IF;

          -- start sync'ing and wait for lock from TCPU
        WHEN PO_SYNC =>
          tpwdn_n    <= '1';            -- tx powered on
          rpwdn_n    <= '1';            -- rx powered on
          sync       <= '1';            -- sync turned on

          IF ch_lock_n = '0' THEN       -- wait for SERDES lock
            IF counter_q(7) = '1' THEN  -- wait a little
              s_ctr_aclr <= '1';
              poweron_next := PO_PATTERN;
            END IF;
          ELSE
            s_ctr_aclr <= '1';            -- reset timeout counter
            poweron_next := PO_SYNC;
          END IF;

          -- Send Pattern and wait for response from TCPU
        WHEN PO_PATTERN =>
          tpwdn_n <= '1';                  -- tx powered on
          rpwdn_n <= '1';                  -- rx powered on
          IF rxd = LOCK_PATTERN_TCPU THEN  -- look for pattern to be sent back
            poweron_next := PO_LOCKED;
          ELSIF counter_q(7) = '1' THEN    -- timeout after 128 clocks
            poweron_next := PO_INIT;
          ELSE
            poweron_next := PO_PATTERN;
          END IF;

          -- Now we are connected! Watch if we loose lock
        WHEN PO_LOCKED =>
          tpwdn_n         <= '1';       -- tx powered on
          rpwdn_n         <= '1';       -- rx powered on
          ch_ready        <= '1';       -- signal that we are locked and  ready
          s_serdes_tx_sel <= '0';       -- send "normal" data
          s_ctr_aclr      <= '1';
          
          IF (ch_lock_n = '1') THEN     -- if we ever loose lock
            poweron_next := PO_INIT;    -- start all over
          END IF;

          -- This state shouldn't happen, so assume we are still locked
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
    data1x => LOCK_PATTERN_THUB,
    sel    => s_serdes_tx_sel,
    result => txd);


END a;

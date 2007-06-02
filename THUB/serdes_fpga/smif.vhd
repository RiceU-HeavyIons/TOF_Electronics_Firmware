-- $Id: smif.vhd,v 1.1 2007-06-02 19:23:44 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : serdes-master-if
-- Project    : SERDES_FPGA
-------------------------------------------------------------------------------
-- File       : smif.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-05-14
-- Last update: 2007-05-24
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: SERDES-MASTER FPGA Interface
-------------------------------------------------------------------------------
-- Copyright (c) 2007
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-05-14  1.0      jschamba        Created
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

ENTITY smif IS
  PORT
    (
      clk40mhz     : IN    std_logic;  -- Master clock
      clk20mhz     : IN    std_logic;  -- SERDES clock
      datain       : IN    std_logic_vector(11 DOWNTO 0);
      data_type    : IN    std_logic_vector(3 DOWNTO 0);
      serdes_out   : OUT   std_logic_vector(17 DOWNTO 0);
      areset       : IN    std_logic

      );
END smif;


ARCHITECTURE a OF smif IS


  TYPE   State_type IS (State0, State1, State2, State3, State4, State5, State6);
  SIGNAL state : State_type;
  SIGNAL s_serdes_out : std_logic_vector(17 DOWNTO 0);

BEGIN

  serdes_out <= s_serdes_out;
  
  trg_sm: PROCESS (clk40mhz, areset) IS
  BEGIN  -- PROCESS trg_sm
    IF areset = '1' THEN                -- asynchronous reset (active high)
      state <= State0;
      s_serdes_out <= (OTHERS => '0');
    ELSIF clk40mhz'event AND clk40mhz = '0' THEN  -- trailing clock edge
      CASE state IS
        WHEN State0 =>
          s_serdes_out <= (OTHERS => '0');
          IF data_type(1) = '1' THEN    -- goto trigger data
            state <= State1;
          ELSIF data_type(2) = '1' THEN  -- goto control data
            state <= State4;
          END IF;
          -- ************************************************
        WHEN State1 =>                  -- here we clock in trigger data
          s_serdes_out(11 DOWNTO 0) <= datain;  -- token
          s_serdes_out(17 DOWNTO 12) <= (OTHERS => '0');
          IF data_type(0) = '1' THEN    -- trigger
            state <= State2;
          ELSIF data_type(1) = '0' THEN
            state <= State0;
          END IF;
        WHEN State2 =>
          s_serdes_out(12) <= clk20mhz;   -- clock phase
          s_serdes_out(16) <= parity(s_serdes_out(11 DOWNTO 0));
          s_serdes_out(17) <= '1';
          state <= State3;
        WHEN State3 =>
          state <= State0;
          -- ************************************************
        WHEN State4 =>                  -- here we clock in control data
          s_serdes_out(11 DOWNTO 0) <= datain;  -- control data
          s_serdes_out(17 DOWNTO 12) <= (OTHERS => '0');
          IF data_type(0) = '1' THEN    -- trigger
            state <= State5;
          ELSIF data_type(2) = '0' THEN
            state <= State0;
          END IF;
        WHEN State5 =>
          s_serdes_out(12) <= clk20mhz;   -- clock phase
          s_serdes_out(16) <= '1';
          state <= State6;
        WHEN State6 =>
          state <= State0;
          -- ************************************************
        WHEN OTHERS =>                  -- shouldn't happen
          state <= State0;
      END CASE;
    END IF;
  END PROCESS trg_sm;

END a;

-- $Id: smif.vhd,v 1.4 2008-01-25 14:34:30 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : serdes-master-if
-- Project    : SERDES_FPGA
-------------------------------------------------------------------------------
-- File       : smif.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-05-14
-- Last update: 2008-01-24
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
      clk40mhz   : IN  std_logic;       -- Master clock
      clk20mhz   : IN  std_logic;       -- SERDES clock
      datain     : IN  std_logic_vector(11 DOWNTO 0);
      data_type  : IN  std_logic_vector(3 DOWNTO 0);
      serdes_out : OUT std_logic_vector(17 DOWNTO 0);
      serdes_reg : OUT std_logic_vector(7 DOWNTO 0);
      trigger    : OUT std_logic;
      areset     : IN  std_logic

      );
END smif;


ARCHITECTURE a OF smif IS

  TYPE State_type IS (State0, State1, State2, State3, State4, State7);
  SIGNAL state        : State_type;
  SIGNAL s_serdes_out : std_logic_vector(17 DOWNTO 0);
  SIGNAL s_datain     : std_logic_vector(11 DOWNTO 0);

BEGIN

  serdes_out <= s_serdes_out;

  -- this state machine assumes that the SERDES and Master FPGA
  -- use the same 40 MHz clock to transmit and receive the
  -- smif data
  trg_sm : PROCESS (clk40mhz, areset) IS
  BEGIN
    IF areset = '1' THEN                -- asynchronous reset (active high)
      state        <= State0;
      s_serdes_out <= (OTHERS => '0');
      serdes_reg   <= (OTHERS => '0');
      trigger      <= '0';
      
    ELSIF clk40mhz'event AND clk40mhz = '1' THEN  -- leading clock edge
      trigger <= '0';
      
      CASE state IS
        -- ************* Waiting... ********************************
        WHEN State0 =>
          -- wait for a valid "data_type" pattern on rising clock edge
          -- latch the input data into signal s_datain
          -- set the SERDES data lines all to '0'
          s_serdes_out <= (OTHERS => '0');      -- normally all 0's
          s_datain     <= datain;               -- latch datain
          IF data_type = "0011" THEN            -- goto "send trigger data"
            state <= State1;
          ELSIF data_type = "0101" THEN         -- goto "send bunch reset"
            state <= State2;
          ELSIF data_type = "1001" THEN         -- goto "send tcpu reset"
            state <= State3;
          ELSIF data_type = "1010" THEN         -- goto "load register"
            state <= State4;
          END IF;

        -- *************** trigger **********************************
        WHEN State1 =>
          trigger <= '1';
          
          -- latch the 20MHz clock phase
          -- calculate the parity
          -- set SERDES data lines to appropriate values
          s_serdes_out(11 DOWNTO 0) <= s_datain;  -- token
          s_serdes_out(12)          <= clk20mhz;  -- clock phase
          s_serdes_out(16)          <= parity(s_datain) XOR clk20mhz;
          s_serdes_out(17)          <= '1';
          state                     <= State7;

        -- *************** bunch reset ******************************
        WHEN State2 =>
          s_serdes_out <= (16 => '1', 13 => '1', OTHERS => '0');
          state        <= State7;

        -- *************** tcpu reset *******************************
        WHEN State3 =>
          s_serdes_out <= (16 => '1', 13 => '1', 12 => '1', OTHERS => '0');
          state        <= State7;

        -- *************** load register ****************************
        WHEN State4 =>
          -- latch the lowest 8 bits of the incoming data into
          -- "serdes_reg" (which has implied memory)
          serdes_reg <= s_datain(7 DOWNTO 0);     -- implied memory
          state      <= State7;
          
        -- *************** wait state *******************************
        WHEN State7 =>
          state <= State0;
          
        -- *************** invalid state ****************************
        WHEN OTHERS =>                  -- shouldn't happen
          state <= State0;
      END CASE;
    END IF;
  END PROCESS trg_sm;

END a;

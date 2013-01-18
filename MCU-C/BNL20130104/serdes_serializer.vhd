-- $Id$
-------------------------------------------------------------------------------
-- Title      : Serdes Serializer
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_serializer.vhd
-- Author     : 
-- Company    : 
-- Created    : 2007-11-20
-- Last update: 2007-12-03
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: takes 32 bit data from a FIFO and generates an 18bit stream
--              synchronized to the 20 MHz clock
-------------------------------------------------------------------------------
-- Copyright (c) 2007 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-11-20  1.0      jschamba        Created
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

ENTITY serdes_serializer IS
  
  PORT (
    clk20mhz     : IN  std_logic;
    areset_n     : IN  std_logic;
    txfifo_empty : IN  std_logic;
    txfifo_q     : IN  std_logic_vector(31 DOWNTO 0);
    txfifo_rdreq : OUT std_logic;
    serdes_data  : OUT std_logic_vector(17 DOWNTO 0));

END ENTITY serdes_serializer;

ARCHITECTURE a OF serdes_serializer IS

  SIGNAL s_serdes_data : std_logic_vector(17 DOWNTO 0);
  SIGNAL lower_nibble  : std_logic_vector(15 DOWNTO 0);
  
  TYPE TState IS (
    State1,
    State2,
    State3
    );

BEGIN  -- ARCHITECTURE a

  serdes_data <= s_serdes_data;

  serializer : PROCESS (clk20mhz, areset_n) IS
    VARIABLE state_present : TState;
    VARIABLE state_next    : TState;
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      state_present := State1;
      state_next    := State1;
      txfifo_rdreq  <= '0';
      s_serdes_data <= (OTHERS => '0');
      lower_nibble  <= (OTHERS => '0');
      
    ELSIF clk20mhz'event AND clk20mhz = '0' THEN  -- rising clock edge
      txfifo_rdreq  <= '0';
      s_serdes_data <= (OTHERS => '0');

      CASE state_present IS
        WHEN State1 =>
          IF txfifo_empty = '0' THEN
            state_next := State2;
          END IF;
          
        WHEN State2 =>
          s_serdes_data (15 DOWNTO 0) <= txfifo_q (31 DOWNTO 16);
          lower_nibble                <= txfifo_q (15 DOWNTO 0);
          s_serdes_data(16)           <= parity(txfifo_q(31 DOWNTO 16));

          IF txfifo_empty = '1' THEN
            state_next        := State1;
            s_serdes_data(17) <= '0';
          ELSE
            state_next        := State3;
            s_serdes_data(17) <= '1';
          END IF;

        WHEN State3 =>
          s_serdes_data (15 DOWNTO 0) <= lower_nibble;
          txfifo_rdreq                <= '1';
          s_serdes_data(16)           <= parity(lower_nibble);
          s_serdes_data(17)           <= '1';

          state_next := State2;

        WHEN OTHERS => NULL;
      END CASE;
      state_present := state_next;
      
    END IF;
  END PROCESS serializer;
  
END ARCHITECTURE a;

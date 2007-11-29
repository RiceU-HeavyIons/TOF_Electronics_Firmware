-- $Id: LFSR.vhd,v 1.1 2007-11-29 15:20:27 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : LFSR
-- Project    : 
-------------------------------------------------------------------------------
-- File       : LFSR.vhd
-- Author     : 
-- Company    : 
-- Created    : 2007-11-29
-- Last update: 2007-11-29
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: create pseudo randmom data 17bit wide with a
--              "Linear Feedback Shift Register" (LFSR)
-------------------------------------------------------------------------------
-- Copyright (c) 2007 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-11-29  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY work;

ENTITY LFSR IS
  PORT
    (
      clock  : IN  std_logic;
      RESETn : IN  std_logic;
      d      : OUT std_logic_vector(16 DOWNTO 0)
      );
END LFSR;

ARCHITECTURE bdf_type OF LFSR IS

  SIGNAL s_dff    : std_logic_vector(16 DOWNTO 0);
  SIGNAL s_wire_0 : std_logic;
  SIGNAL s_wire_1 : std_logic;


BEGIN

  PROCESS(clock, RESETn)
  BEGIN
    IF (RESETn = '0') THEN
      s_dff <= (OTHERS => '0');
    ELSIF (rising_edge(clock)) THEN
      s_dff(0)  <= s_wire_0;
      s_dff(1)  <= s_dff(0);
      s_dff(2)  <= s_dff(1);
      s_dff(3)  <= s_dff(2);
      s_dff(4)  <= s_dff(3);
      s_dff(5)  <= s_dff(4);
      s_dff(6)  <= s_dff(5);
      s_dff(7)  <= s_dff(6);
      s_dff(8)  <= s_dff(7);
      s_dff(9)  <= s_dff(8);
      s_dff(10) <= s_dff(9);
      s_dff(11) <= s_dff(10);
      s_dff(12) <= s_dff(11);
      s_dff(13) <= s_dff(12);
      s_dff(14) <= s_dff(13);
      s_dff(15) <= s_dff(14);
      s_dff(16) <= s_dff(15);
    END IF;
  END PROCESS;

  s_wire_0 <= NOT(s_wire_1);
  s_wire_1 <= s_dff(13) XOR s_dff(16);

  d <= s_dff;

END;

--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: my_utilities.vhd,v 1.3 2011-02-08 19:55:00 jschamba Exp $
--******************************************************************************
--*
--* Package         : MY_UTILITIES
--* File            : my_utilities.vhd
--* Library         : ieee
--* Description     : It is a VHDL package with overloade and other operators.
--* Simulator       : Modelsim
--* Synthesizer     : Lenoardo Spectrum + Quartus II
--* Author/Designer : C. SOOS ( Csaba.Soos@cern.ch)
--*
--******************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE my_utilities IS
  FUNCTION "+" (l    : std_logic_vector; r : std_logic_vector) RETURN std_logic_vector;
  FUNCTION "-" (l    : std_logic_vector; r : std_logic_vector) RETURN std_logic_vector;
  FUNCTION "+" (l    : std_logic_vector; r : integer) RETURN std_logic_vector;
  FUNCTION "-" (l    : std_logic_vector; r : integer) RETURN std_logic_vector;
  FUNCTION inc (v    : std_logic_vector) RETURN std_logic_vector;
  FUNCTION dec (v    : std_logic_vector) RETURN std_logic_vector;
  FUNCTION parity (a : std_logic_vector) RETURN std_logic;
END my_utilities;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE work.my_conversions.ALL;

PACKAGE BODY my_utilities IS
  FUNCTION "+" (l : std_logic_vector; r : std_logic_vector) RETURN std_logic_vector IS
  BEGIN
    RETURN unsigned(l) + unsigned(r);
  END;
  FUNCTION "-" (l : std_logic_vector; r : std_logic_vector) RETURN std_logic_vector IS
  BEGIN
    RETURN unsigned(l) - unsigned(r);
  END;
  FUNCTION "+" (l : std_logic_vector; r : integer) RETURN std_logic_vector IS
  BEGIN
    RETURN unsigned(l) + unsigned(int2slv(r, 32)(l'length-1 DOWNTO 0));
  END;
  FUNCTION "-" (l : std_logic_vector; r : integer) RETURN std_logic_vector IS
  BEGIN
    RETURN unsigned(l) - unsigned(int2slv(r, 32)(l'length-1 DOWNTO 0));
  END;
  FUNCTION inc (v : std_logic_vector) RETURN std_logic_vector IS
  BEGIN
    RETURN unsigned(v) + unsigned'("1");
  END;
  FUNCTION dec (v : std_logic_vector) RETURN std_logic_vector IS
  BEGIN
    RETURN unsigned(v) - unsigned'("1");
  END;
  FUNCTION parity (a : std_logic_vector) RETURN std_logic IS
    VARIABLE y : std_logic := '0';
  BEGIN
    FOR i IN a'range LOOP
      y := y XOR a(i);
    END LOOP;
    RETURN y;
  END;

END my_utilities;

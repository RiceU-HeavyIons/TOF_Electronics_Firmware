--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: my_utilities.vhd,v 1.1 2007-04-27 19:26:37 jschamba Exp $
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

library ieee;
use ieee.std_logic_1164.all;

package my_utilities is
  function "+" (l : std_logic_vector; r : std_logic_vector) return std_logic_vector;
  function "-" (l : std_logic_vector; r : std_logic_vector) return std_logic_vector;
  function "+" (l : std_logic_vector; r : integer) return std_logic_vector;
  function "-" (l : std_logic_vector; r : integer) return std_logic_vector;
  function inc (v : std_logic_vector) return std_logic_vector;
  function dec (v : std_logic_vector) return std_logic_vector;
end my_utilities;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.my_conversions.all;

package body my_utilities is
  function "+" (l : std_logic_vector; r : std_logic_vector) return std_logic_vector is
  begin
    return unsigned(l) + unsigned(r);
  end;
  function "-" (l : std_logic_vector; r : std_logic_vector) return std_logic_vector is
  begin
    return unsigned(l) - unsigned(r);
  end;
  function "+" (l : std_logic_vector; r : integer) return std_logic_vector is
  begin
    return unsigned(l) + unsigned(int2slv(r, 32)(l'length-1 downto 0));
  end;
  function "-" (l : std_logic_vector; r : integer) return std_logic_vector is
  begin
    return unsigned(l) - unsigned(int2slv(r, 32)(l'length-1 downto 0));
  end;
  function inc (v : std_logic_vector) return std_logic_vector is
  begin
    return unsigned(v) + unsigned'("1");
  end;
  function dec (v : std_logic_vector) return std_logic_vector is
  begin
    return unsigned(v) - unsigned'("1");
  end;
end my_utilities;

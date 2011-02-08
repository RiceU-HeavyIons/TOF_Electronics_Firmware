--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: my_conversions.vhd,v 1.2 2011-02-08 19:19:25 jschamba Exp $
--******************************************************************************
--*
--* Package         : MY_CONVERSIONS
--* File            : my_conversions.vhd
--* Library         : ieee
--* Description     : It is a package with custom functions for conversion.
--* Simulator       : Modelsim
--* Synthesizer     : Lenoardo Spectrum + Quartus II
--* Author/Designer : C. SOOS ( Csaba.Soos@cern.ch)
--*
--******************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE my_conversions IS
  FUNCTION bool2sl (b    : boolean) RETURN std_logic;
  FUNCTION int2slv (int  : integer; w : natural) RETURN std_logic_vector;
  FUNCTION slv2int (slv  : std_logic_vector) RETURN integer;
  FUNCTION sl2int (sl    : std_logic) RETURN integer;
  FUNCTION slv2hstr (slv : std_logic_vector) RETURN string;
  FUNCTION rotate (slv   : std_logic_vector) RETURN std_logic_vector;
END my_conversions;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.numeric_std.ALL;

PACKAGE BODY my_conversions IS

  FUNCTION bool2sl (b : boolean) RETURN std_logic IS
  BEGIN
    IF b THEN
      RETURN '1';
    ELSE
      RETURN '0';
    END IF;
  END bool2sl;

  FUNCTION int2slv (int : integer; w : natural) RETURN std_logic_vector IS
  BEGIN
    RETURN std_logic_vector(to_unsigned(int, w));
  END int2slv;

  FUNCTION sl2int (sl : std_logic) RETURN integer IS
  BEGIN  -- sl2int
    IF sl = '0' THEN
      RETURN 0;
    ELSE
      RETURN 1;
    END IF;
  END sl2int;

  FUNCTION slv2int (slv : std_logic_vector) RETURN integer IS
    VARIABLE result : integer;
  BEGIN
-- pragma synthesis_off
    ASSERT (slv'length < 33) REPORT "Too long vector";
-- pragma synthesis_on
    result := 0;
    FOR i IN slv'range LOOP
      IF (slv(i) = '1') THEN
        result := result + 2**i;
      END IF;
    END LOOP;
    RETURN result;
  END slv2int;

  FUNCTION slv2hstr (slv : std_logic_vector) RETURN string IS
    VARIABLE slv32   : std_logic_vector (31 DOWNTO 0);
    VARIABLE nib_slv : std_logic_vector (3 DOWNTO 0);
    VARIABLE nib_int : integer;
    VARIABLE result  : string (10 DOWNTO 1) := "0x00000000";
  BEGIN  -- slv2str
    -- pragma synthesis_off
    ASSERT (slv'length < 33) REPORT "Too long vector";
    -- pragma synthesis_on
    IF slv'length < 32 THEN
      slv32 := int2slv(slv2int(slv), 32);
    ELSE
      slv32 := slv;
    END IF;
    FOR i IN 7 DOWNTO 0 LOOP
      nib_slv := slv32(i*4+3 DOWNTO i*4);
      nib_int := slv2int(nib_slv);
      IF nib_int < 10 THEN
        result(i+1) := character'val(character'pos('0')+nib_int);
      ELSE
        result(i+1) := character'val(character'pos('A')+nib_int-10);
      END IF;
    END LOOP;  -- i
    RETURN result;
  END slv2hstr;

  FUNCTION rotate (slv : std_logic_vector) RETURN std_logic_vector IS
    VARIABLE result : std_logic_vector (slv'range);
  BEGIN
    FOR i IN slv'range LOOP
      result(slv'length - 1 - i) := slv(i);
    END LOOP;
    RETURN result;
  END;

END my_conversions;




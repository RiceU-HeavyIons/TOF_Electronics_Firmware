-- $Id: TDIG_E_primitives.vhd,v 1.2 2008-02-15 20:08:43 jschamba Exp $

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;

PACKAGE TDIG_E_primitives IS

  COMPONENT GLOBAL
    PORT (a_in  : IN  std_logic;
          a_out : OUT std_logic);
  END COMPONENT;
  
-- state machines ************************************  

  COMPONENT short
    PORT (
      clk, input_hi, reset : IN  std_logic;
      out_hi               : OUT std_logic);
  END COMPONENT;

END PACKAGE TDIG_E_primitives;

-- $Id: SHORT.vhd,v 1.1 2008-02-15 20:09:15 jschamba Exp $

--  C:\1PROJECTS\PICOTOF 2006\TDIG MAY 2006\PLD\VER6\SHORT.vhd
--  VHDL code created by Xilinx's StateCAD 6.2i
--  Thu Feb 08 12:36:17 2007

--  This VHDL code (for use with IEEE compliant tools) was generated using: 
--  enumerated state assignment with structured code format.
--  Minimization is enabled,  implied else is enabled, 
--  and outputs are area optimized.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY SHORT IS
  PORT
    (
      CLK      : IN  std_logic;
      INPUT_HI : IN  std_logic;
      RESET    : IN  std_logic;
      OUT_HI   : OUT std_logic
      );
END;

ARCHITECTURE BEHAVIOR OF SHORT IS
  TYPE type_sreg IS (STATE0, STATE1, STATE2);
  SIGNAL sreg, next_sreg : type_sreg;
BEGIN
  PROCESS (CLK, RESET, next_sreg)
  BEGIN
    IF (RESET = '1') THEN
      sreg <= STATE0;
    ELSIF CLK = '1' AND CLK'event THEN
      sreg <= next_sreg;
    END IF;
  END PROCESS;

  PROCESS (sreg, INPUT_HI)
  BEGIN
    OUT_HI <= '0';

    next_sreg <= STATE0;

    CASE sreg IS
      WHEN STATE0 =>
        OUT_HI <= '0';
        IF (INPUT_HI = '1') THEN
          next_sreg <= STATE1;
        END IF;
        IF (INPUT_HI = '0') THEN
          next_sreg <= STATE0;
        END IF;
      WHEN STATE1 =>
        OUT_HI    <= '1';
        next_sreg <= STATE2;
      WHEN STATE2 =>
        OUT_HI <= '0';
        IF (INPUT_HI = '0') THEN
          next_sreg <= STATE0;
        END IF;
        IF (INPUT_HI = '1') THEN
          next_sreg <= STATE2;
        END IF;
      WHEN OTHERS =>
    END CASE;
  END PROCESS;
END BEHAVIOR;

-- $Id: poweron.vhd,v 1.1 2008-10-16 20:10:49 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : Power On Initialization
-- Project    : 
-------------------------------------------------------------------------------
-- File       : poweron.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-10-15
-- Last update: 2008-10-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-10-15  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY UNISIM;
USE UNISIM.vcomponents.ALL;


-------------------------------------------------------------------------------

ENTITY poweron IS
  PORT (
    -- clocks and reset
    BRD_RESET_n : IN std_logic;         -- board reset (active low)
    BRD_40M     : IN std_logic;         -- Board 40 MHz clock

    PO_RESET : OUT std_logic
    );
END ENTITY poweron;

-------------------------------------------------------------------------------

ARCHITECTURE str3 OF poweron IS

  TYPE poState_type IS (
    S1, S2, S3, S4
    );
  SIGNAL poState : poState_type;
  
BEGIN

  poreset : PROCESS (BRD_40M, BRD_RESET_n) IS
    VARIABLE poCtr : integer RANGE 0 TO 53248 := 0;
  BEGIN
    IF BRD_RESET_n = '0' THEN           -- asynchronous reset (active low)
      poState  <= S1;
      poCtr    := 0;
      PO_RESET <= '0';
      
    ELSIF BRD_40M'event AND BRD_40M = '1' THEN  -- rising clock edge
      PO_RESET <= '0';

      CASE poState IS
        WHEN S1 =>
          poCtr   := 0;
          poState <= S2;
        WHEN S2 =>
          poCtr := poCtr + 1;
          IF poCtr = 53232 THEN         -- about 1ms
            poState <= S3;
          ELSE
            poState <= S2;
          END IF;
        WHEN S3 =>                      -- keep PO_RESET high for 16 clocks
          PO_RESET <= '1';
          poCtr    := poCtr + 1;
          IF poCtr = 53248 THEN
            poState <= S4;
          ELSE
            poState <= S3;
          END IF;
        WHEN S4 =>
          IF BRD_RESET_n = '0' THEN
            poState <= S1;
          ELSE
            poState <= S4;
          END IF;
        WHEN OTHERS =>
          poState <= S1;
      END CASE;
    END IF;
  END PROCESS poreset;
  
END ARCHITECTURE str3;

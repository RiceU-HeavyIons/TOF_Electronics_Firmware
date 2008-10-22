-- $Id: poweron.vhd,v 1.2 2008-10-22 20:01:28 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : Power On Initialization
-- Project    : 
-------------------------------------------------------------------------------
-- File       : poweron.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-10-15
-- Last update: 2008-10-22
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
    RESET_n : IN std_logic;             -- reset (active low)
    CLK_10M : IN std_logic;             -- DCM 10 MHz clock

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

  poreset : PROCESS (CLK_10M, RESET_n) IS
    VARIABLE poCtr : integer RANGE 0 TO 131071 := 0;
  BEGIN
    IF RESET_n = '0' THEN               -- asynchronous reset (active low)
      poState  <= S1;
      poCtr    := 0;
      PO_RESET <= '0';
      
    ELSIF CLK_10M'event AND CLK_10M = '1' THEN  -- rising clock edge
      PO_RESET <= '0';

      CASE poState IS
        WHEN S1 =>
          poCtr   := 0;
          poState <= S2;
        WHEN S2 =>
          poCtr := poCtr + 1;
          IF poCtr = 131056 THEN        -- about 13ms
            poState <= S3;
          ELSE
            poState <= S2;
          END IF;
        WHEN S3 =>                      -- keep PO_RESET high for 16 clocks
          PO_RESET <= '1';
          poCtr    := poCtr + 1;
          IF poCtr = 131071 THEN
            poState <= S4;
          ELSE
            poState <= S3;
          END IF;
        WHEN S4 =>
          IF RESET_n = '0' THEN
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

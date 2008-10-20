-- $Id: adc_bitslip.vhd,v 1.2 2008-10-20 22:47:14 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : Serdes Bitslip for ADCs
-- Project    : 
-------------------------------------------------------------------------------
-- File       : adc_bitslip.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-10-13
-- Last update: 2008-10-20
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-10-13  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY UNISIM;
USE UNISIM.vcomponents.ALL;


-------------------------------------------------------------------------------

ENTITY adc_bitslip IS
  PORT (
    -- clocks and reset
    RESET       : IN std_logic;             -- reset (active high)
    ADC_FCLK    : IN std_logic;             -- ADC frame clock
    BITSLIP_CNT : IN integer RANGE 0 TO 7;  -- number of bits to slip

    SERDES_RDY   : OUT std_logic;
    BITSLIP_CTRL : OUT std_logic
    );
END ENTITY adc_bitslip;

-------------------------------------------------------------------------------

ARCHITECTURE str2 OF adc_bitslip IS


  TYPE bsState_type IS (
    S0, S1, S2, S3, S4
    );
  SIGNAL bsState : bsState_type;
  
BEGIN  -- ARCHITECTURE str2

  -- bit slip control 
  bitslip : PROCESS (ADC_FCLK, RESET) IS
    VARIABLE bsCtr   : integer RANGE 0 TO 7 := 0;
    VARIABLE timeout : integer RANGE 0 TO 7 := 0;
  BEGIN
    IF RESET = '1' THEN                 -- asynchronous reset (active high)
      bsState      <= S1;
      bsCtr        := 0;
      timeout      := 0;
      BITSLIP_CTRL <= '0';
      SERDES_RDY   <= '0';
      
    ELSIF ADC_FCLK'event AND ADC_FCLK = '0' THEN  -- falling clock edge
      BITSLIP_CTRL <= '0';
      SERDES_RDY   <= '0';

      CASE bsState IS
        WHEN S0 =>
          timeout := 0;
          bsState <= S1;
        WHEN S1 =>
          bsCtr   := 0;
          timeout := timeout + 1;
          IF timeout = 7 THEN          -- wait a little before starting bitslip
            bsState <= S2;
          END IF;
          -- bit slip signal needs to toggle between 1 and 0
        WHEN S2 =>                      -- bit slip = 1
          BITSLIP_CTRL <= '1';
          bsState      <= S3;
        WHEN S3 =>                      -- bit slip = 0
          bsCtr := bsCtr + 1;
          IF bsCtr = BITSLIP_CNT THEN   -- slip even bits by CNT to the right
            bsState <= S4;
          ELSE
            bsState <= S2;
          END IF;
        WHEN S4 =>
          SERDES_RDY <= '1';
          IF RESET = '1' THEN
            bsState <= S0;
          END IF;
        WHEN OTHERS =>
          bsState <= S0;
      END CASE;
    END IF;
  END PROCESS bitslip;
  
END ARCHITECTURE str2;

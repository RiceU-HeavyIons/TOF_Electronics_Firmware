-- $Id: adc_serial_tx.vhd,v 1.1 2008-10-14 22:11:15 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : ADC Serial Transmitter
-- Project    : TRU
-------------------------------------------------------------------------------
-- File       : adc_serial_tx.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-08-18
-- Last update: 2008-08-19
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-08-18  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY UNISIM;
USE UNISIM.vcomponents.ALL;


-------------------------------------------------------------------------------

ENTITY adc_serial_tx IS


  PORT (
    RESET_n : IN  std_logic;            -- reset (active low)
    SCLK    : IN  std_logic;
    SDATA   : OUT std_logic;
    CS_n    : OUT std_logic;
    PDATA   : IN  std_logic_vector(15 DOWNTO 0);
    ADDR    : IN  std_logic_vector (7 DOWNTO 0);
    LOAD    : IN  std_logic;
    READY   : OUT std_logic
    );

END ENTITY adc_serial_tx;

-------------------------------------------------------------------------------

ARCHITECTURE str OF adc_serial_tx IS

  -----------------------------------------------------------------------------
  -- Component Declarations
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  TYPE TxState_type IS (
    SIdle,
    SLatchData,
    SStartTx,
    SSendData,
    SFinish
    );
  SIGNAL TxState : TxState_type;

  SIGNAL s_shiftreg : std_logic_vector(23 DOWNTO 0);

BEGIN  -- ARCHITECTURE str

  SDATA <= s_shiftreg(23);

  -- use a state machine to control the serial data TX
  txControl : PROCESS (SCLK, RESET_n) IS
    VARIABLE dataCtr : integer RANGE 0 TO 23 := 0;
  BEGIN
    IF RESET_n = '0' THEN               -- asynchronous reset (active low)
      TxState    <= SIdle;
      dataCtr    := 0;
      CS_n       <= '1';
      READY      <= '0';
      s_shiftreg <= (OTHERS => '0');
      
    ELSIF SCLK'event AND SCLK = '0' THEN  -- falling clock edge
      CS_n  <= '1';                       -- default is high (disabled)
      READY <= '0';                       -- default is not ready

      CASE TxState IS
        WHEN SIdle =>

          s_shiftreg <= (OTHERS => '0');
          READY      <= '1';

          IF LOAD = '1' THEN
            TxState <= SLatchData;
          END IF;


        WHEN SLatchData =>
          dataCtr    := 0;
          s_shiftreg <= ADDR & PDATA;

          TxState <= SStartTx;

        WHEN SStartTx =>
          CS_n <= '0';

          TxState <= SSendData;
          
        WHEN SSendData =>
          CS_n       <= '0';
          s_shiftreg <= s_shiftreg(22 DOWNTO 0) & '0';
          dataCtr    := dataCtr + 1;

          IF dataCtr = 23 THEN
            TxState <= SFinish;
          END IF;

        WHEN SFinish =>
          TxState <= SIdle;
          
        WHEN OTHERS =>
          TxState <= SIdle;
          
      END CASE;

    END IF;
  END PROCESS txControl;


END ARCHITECTURE str;

-- $Id: adc_init.vhd,v 1.4 2008-10-16 20:44:43 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : ADC Initialization
-- Project    : TRU
-------------------------------------------------------------------------------
-- File       : adc_init.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-08-27
-- Last update: 2008-10-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-08-27  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY UNISIM;
USE UNISIM.vcomponents.ALL;


-------------------------------------------------------------------------------

ENTITY adc_init IS


  PORT (
    RESET       : IN  std_logic;        -- reset (active high)
    CLK10M      : IN  std_logic;
    LOCKED      : IN  std_logic;
    ADC_RESET_n : OUT std_logic;
    SDATA       : OUT std_logic;
    CS_n        : OUT std_logic;
    READY       : OUT std_logic
    );

END ENTITY adc_init;

-------------------------------------------------------------------------------

ARCHITECTURE str1 OF adc_init IS

  -----------------------------------------------------------------------------
  -- Component Declarations
  -----------------------------------------------------------------------------
  COMPONENT adc_serial_tx
    PORT (
      RESET : IN  std_logic;            -- reset (active high)
      SCLK  : IN  std_logic;
      SDATA : OUT std_logic;
      CS_n  : OUT std_logic;
      PDATA : IN  std_logic_vector(15 DOWNTO 0);
      ADDR  : IN  std_logic_vector (7 DOWNTO 0);
      LOAD  : IN  std_logic;
      READY : OUT std_logic);
  END COMPONENT;

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  TYPE IState_type IS (
    SLock,
    SWaitReset,
    SReset,
    SWaitInit,
    SStartInit1,
    SWaitInit1,
    SStartInit2,
    SWaitInit2,
    SStartInit3,
    SWaitInit3,
    SStartInit4,
    SWaitInit4,
    SStartInit5,
    SWaitInit5,
    SFinish
    );
  SIGNAL IState : IState_type;

  SIGNAL s_pdata : std_logic_vector (15 DOWNTO 0);
  SIGNAL s_addr  : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_load  : std_logic;
  SIGNAL s_ready : std_logic;


BEGIN  -- ARCHITECTURE str

  adc_serial_tx_inst : adc_serial_tx PORT MAP (
    RESET => RESET,
    SCLK  => CLK10M,
    SDATA => SDATA,
    CS_n  => CS_n,
    PDATA => s_pdata,
    ADDR  => s_addr,
    LOAD  => s_load,
    READY => s_ready);

  -- use a state machine to control the serial data TX
  IControl : PROCESS (CLK10M, RESET) IS
    VARIABLE timeoutCtr : integer RANGE 0 TO 131071 := 0;  -- 17 bits
  BEGIN
    IF RESET = '1' THEN                 -- asynchronous reset (active high)
      IState      <= SLock;
      s_pdata     <= x"0000";
      s_addr      <= x"00";
      s_load      <= '0';
      timeoutCtr  := 0;
      ADC_RESET_n <= '1';
      READY       <= '0';
      
    ELSIF CLK10M'event AND CLK10M = '1' THEN  -- rising clock edge
      s_load      <= '0';
      ADC_RESET_n <= '1';
      READY       <= '0';

      CASE IState IS
        WHEN SLock =>
          timeoutCtr := 0;
          IF LOCKED = '1' THEN
            IState <= SWaitReset;
          END IF;

        WHEN SWaitReset =>
          timeoutCtr := timeoutCtr + 1;

          IF timeoutCtr = 106496 THEN   --  >10ms
            timeoutCtr := 0;
            IState     <= SReset;
          END IF;

        WHEN SReset =>
          timeoutCtr  := timeoutCtr + 1;
          ADC_RESET_n <= '0';
          IF timeoutCtr = 4 THEN        --  >100ns
            IState <= SWaitInit;
          END IF;

          -- First Initialization register
        WHEN SWaitInit =>
          timeoutCtr := 0;
          s_addr     <= x"03";
          s_pdata    <= x"0002";

          IState <= SStartInit1;

        WHEN SStartInit1 =>
          timeoutCtr := timeoutCtr + 1;
          s_load     <= '1';

          IF timeoutCtr = 2 THEN
            IState <= SWaitInit1;
          END IF;

          -- Second Initialization register
        WHEN SWaitInit1 =>
          timeoutCtr := 0;
          s_addr     <= x"01";
          s_pdata    <= x"0010";
          IF s_ready = '1' THEN
            IState <= SStartInit2;
          END IF;

        WHEN SStartInit2 =>
          timeoutCtr := timeoutCtr + 1;
          s_load     <= '1';

          IF timeoutCtr = 2 THEN
            IState <= SWaitInit2;
          END IF;

          -- Third Initialization register
        WHEN SWaitInit2 =>
          timeoutCtr := 0;
          s_addr     <= x"C7";
          s_pdata    <= x"8001";
          IF s_ready = '1' THEN
            IState <= SStartInit3;
          END IF;

        WHEN SStartInit3 =>
          timeoutCtr := timeoutCtr + 1;
          s_load     <= '1';

          IF timeoutCtr = 2 THEN
            IState <= SWaitInit3;
          END IF;

          -- Fourth Initialization register
        WHEN SWaitInit3 =>
          timeoutCtr := 0;
          s_addr     <= x"DE";
          s_pdata    <= x"01C0";
          IF s_ready = '1' THEN
            IState <= SStartInit4;
          END IF;

        WHEN SStartInit4 =>
          timeoutCtr := timeoutCtr + 1;
          s_load     <= '1';

          IF timeoutCtr = 2 THEN
            IState <= SWaitInit4;
          END IF;

          -- LVDS Test Pattern register
        WHEN SWaitInit4 =>
          timeoutCtr := 0;
          s_addr     <= x"25";
--          s_pdata    <= x"002D";        -- DUALCUSTOM_PAT: 1 = 0xc00, 2 = 0x400
          s_pdata    <= x"0040";        -- EN_RAMP
--          s_addr     <= x"45";
--          s_pdata    <= x"0002";        -- PAT_SYNC
--          s_pdata <= x"0001";           -- PAT_DESKEW
          IF s_ready = '1' THEN
            IState <= SStartInit5;
          END IF;

        WHEN SStartInit5 =>
          timeoutCtr := timeoutCtr + 1;
          s_load     <= '1';

          IF timeoutCtr = 2 THEN
            IState <= SWaitInit5;
          END IF;

        WHEN SWaitInit5 =>
          timeoutCtr := 0;
          IF s_ready = '1' THEN
            IState <= SFinish;
          END IF;


          -- Finished with serial registers
        WHEN SFinish =>
          READY <= '1';
          IF LOCKED = '0' THEN
            IState <= SLock;
          END IF;
          
        WHEN OTHERS =>
          IState <= SLock;
          
      END CASE;

    END IF;
  END PROCESS IControl;


END ARCHITECTURE str1;

-- $Id: adc_init.vhd,v 1.9 2008-11-26 16:31:06 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : ADC Initialization
-- Project    : TRU
-------------------------------------------------------------------------------
-- File       : adc_init.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-08-27
-- Last update: 2008-11-19
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
    RESET         : IN  std_logic;      -- reset (active high)
    CLK10M        : IN  std_logic;
    LOCKED        : IN  std_logic;
    RX_DATA_OUT   : IN  std_logic_vector (15 DOWNTO 0);
    RX_DATA_READY : IN  std_logic;
    ADC_RESET_n   : OUT std_logic;
    SDATA         : OUT std_logic;
    CS_n          : OUT std_logic;
    READY         : OUT std_logic
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
    SStartInit,
    SWaitInit1,
    SStartInit1,
    SWaitInit2,
    SFinish,
    SetTestPattern,
    SStartInit2,
    SWaitInit3
    );
  SIGNAL IState : IState_type;

  CONSTANT NUM_INIT : integer := 8;     -- number of registers to write

  SIGNAL s_pdata    : std_logic_vector (15 DOWNTO 0);
  SIGNAL s_addr     : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_load     : std_logic;
  SIGNAL s_ready    : std_logic;
  SIGNAL l_register : std_logic_vector (15 DOWNTO 0) := x"0000";
  SIGNAL reg_reset  : std_logic;

  TYPE data_array IS ARRAY (0 TO NUM_INIT-1) OF std_logic_vector (15 DOWNTO 0);
  TYPE addr_array IS ARRAY (0 TO NUM_INIT-1) OF std_logic_vector (7 DOWNTO 0);
  SIGNAL idata : data_array;
  SIGNAL iaddr : addr_array;
  
BEGIN  -- ARCHITECTURE str

  -- the first four are the recommended initialization as described
  -- in the manual on page 3:
  iaddr(0) <= x"03";
  idata(0) <= x"0002";

  iaddr(1) <= x"01";
  idata(1) <= x"0010";

  iaddr(2) <= x"C7";
  idata(2) <= x"8001";

  iaddr(3) <= x"DE";
  idata(3) <= x"01C0";


  -- these registers determine the test pattern outputs:
  iaddr(4) <= x"25";                    -- LVDS Test Pattern register
--  idata(4) <= x"0029";                  -- DUALCUSTOM_PAT: 1 = 0x400, 2 = 0x800
  idata(4) <= x"0000";                  -- inactive
--  idata(4) <= x"002C";                  -- DUALCUSTOM_PAT: 1 = 0x000, 2 = 0xC00
--  idata(4) <= x"0040";                  -- EN_RAMP

  iaddr(5) <= x"26";                    -- BITS_CUSTOM1
  idata(5) <= x"5540";                  -- 1 + 0x155 = 0x555
--  idata(5) <= x"0000";                  -- 1 + 0x000 = 0x000

  iaddr(6) <= x"27";                    -- BITS_CUSTOM2
  idata(6) <= x"AA80";                  -- 2 + 0x2AA = 0xAAA
--  idata(6) <= x"FFC0";                  -- 2 + 0x3FF = 0xFFF

  iaddr(7) <= x"45";
  idata(7) <= x"0000";                  -- inactive
--  idata(7) <= x"0002";                  -- PAT_SYNC
--  idata(7) <= x"0001";                  -- PAT_DESKEW
  
  
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
    VARIABLE timeoutCtr : integer RANGE 0 TO 131071   := 0;  -- 17 bits
    VARIABLE inum       : integer RANGE 0 TO NUM_INIT := 0;
  BEGIN
    IF RESET = '1' THEN                 -- asynchronous reset (active high)
      IState      <= SLock;
      s_pdata     <= x"0000";
      s_addr      <= x"00";
      s_load      <= '0';
      timeoutCtr  := 0;
      ADC_RESET_n <= '1';
      READY       <= '0';
      reg_reset   <= '0';
      
    ELSIF CLK10M'event AND CLK10M = '1' THEN  -- rising clock edge
      s_load      <= '0';
      ADC_RESET_n <= '1';
      READY       <= '0';
      reg_reset   <= '1';

      CASE IState IS
        WHEN SLock =>
          timeoutCtr := 0;
          IF LOCKED = '1' THEN
            IState <= SWaitReset;
          END IF;

        WHEN SWaitReset =>
          timeoutCtr := timeoutCtr + 1;

--          IF timeoutCtr = 2 THEN        -- for testing only
          IF timeoutCtr = 106496 THEN   --  >10ms
            timeoutCtr := 0;
            IState     <= SReset;
          END IF;

        WHEN SReset =>
          timeoutCtr  := timeoutCtr + 1;
          inum        := 0;
          ADC_RESET_n <= '0';
          IF timeoutCtr = 4 THEN        --  >100ns
            IState <= SWaitInit;
          END IF;

        WHEN SWaitInit =>
          timeoutCtr := 0;
          s_addr     <= iaddr(inum);
          s_pdata    <= idata(inum);

          IState <= SStartInit;

        WHEN SStartInit =>
          timeoutCtr := timeoutCtr + 1;
          inum       := 1;
          s_load     <= '1';

          IF timeoutCtr = 2 THEN
            IState <= SWaitInit1;
          END IF;

        WHEN SWaitInit1 =>
          timeoutCtr := 0;
          s_addr     <= iaddr(inum);
          s_pdata    <= idata(inum);
          IF s_ready = '1' THEN
            inum   := inum + 1;
            IState <= SStartInit1;
          END IF;

        WHEN SStartInit1 =>
          timeoutCtr := timeoutCtr + 1;
          s_load     <= '1';

          IF timeoutCtr = 2 THEN
            IF inum = NUM_INIT THEN
              IState <= SWaitInit2;
            ELSE
              IState <= SWaitInit1;
              
            END IF;
          END IF;

        WHEN SWaitInit2 =>
          IF s_ready = '1' THEN
            IState <= SFinish;
          END IF;

          -- Finished with serial registers
        WHEN SFinish =>
          READY <= '1';
          IF LOCKED = '0' THEN
            IState <= SLock;
          ELSIF l_register /= x"0000" THEN
            IState <= SetTestPattern;
          ELSE
            IState <= SFinish;
          END IF;

          -- set a new test pattern when GTL I2c register write
        WHEN SetTestPattern =>
          timeoutCtr := 0;
          s_addr     <= x"25";
          
          IF l_register = x"0001" THEN
            s_pdata <= x"0040";         -- ramp
          ELSIF l_register = x"0002" THEN
            s_pdata <= x"0029";         -- dual pattern 0xAAA 0x555
          ELSE
            s_pdata <= x"0000";         -- normal data
          END IF;

          IState <= SStartInit2;
          
        WHEN SStartInit2 =>
          timeoutCtr := timeoutCtr + 1;
          s_load     <= '1';

          IF timeoutCtr = 2 THEN
            IState <= SWaitInit3;
          END IF;

        WHEN SWaitInit3 =>
          reg_reset <= '0';
          IF s_ready = '1' THEN
            IState <= SFinish;
          END IF;
          
        WHEN OTHERS =>
          IState <= SLock;
          
      END CASE;

    END IF;
  END PROCESS IControl;

  PROCESS (RX_DATA_READY, reg_reset) IS
  BEGIN
    IF reg_reset = '0' THEN             -- asynchronous reset (active low)
      l_register <= x"0000";
    ELSIF RX_DATA_READY'event AND RX_DATA_READY = '1' THEN  -- rising clock edge
      l_register <= RX_DATA_OUT;
    END IF;
  END PROCESS;

END ARCHITECTURE str1;

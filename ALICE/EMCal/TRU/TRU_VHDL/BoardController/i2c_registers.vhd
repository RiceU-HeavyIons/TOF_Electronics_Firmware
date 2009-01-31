-- $Id: i2c_registers.vhd,v 1.1 2009-01-31 20:44:31 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : I2C registers
-- Project    : 
-------------------------------------------------------------------------------
-- File       : i2c_registers.vhd
-- Author     : 
-- Company    : 
-- Created    : 2009-01-19
-- Last update: 2009-01-23
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2009 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2009-01-19  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY i2c_registers IS
  PORT (
    clock       : IN  std_logic;
    reset       : IN  std_logic;
    reg_data    : IN  std_logic_vector (15 DOWNTO 0);
    reg_addr    : IN  std_logic_vector (7 DOWNTO 0);
    reg_load    : IN  std_logic;
    acknSAdc    : IN  std_logic;
    versionStr  : IN  std_logic_vector (15 DOWNTO 0);
    loadSAdcReg : OUT std_logic;
    readRegOut  : OUT std_logic_vector (15 DOWNTO 0);
    reg0_out    : OUT std_logic_vector (15 DOWNTO 0);
    reg1_out    : OUT std_logic_vector (15 DOWNTO 0);
    reg2_out    : OUT std_logic_vector (15 DOWNTO 0);
    reg3_out    : OUT std_logic_vector (15 DOWNTO 0);
    reg4_out    : OUT std_logic_vector (15 DOWNTO 0);
    sAdc_addr   : OUT std_logic_vector (7 DOWNTO 0);
    sAdc_data   : OUT std_logic_vector (15 DOWNTO 0)
    );
END i2c_registers;

ARCHITECTURE SYN OF i2c_registers IS
  SIGNAL s_reg0      : std_logic_vector(15 DOWNTO 0);
  SIGNAL s_reg1      : std_logic_vector(15 DOWNTO 0);
  SIGNAL s_reg2      : std_logic_vector(15 DOWNTO 0);
  SIGNAL s_reg3      : std_logic_vector(15 DOWNTO 0);
  SIGNAL s_reg4      : std_logic_vector(15 DOWNTO 0);
  SIGNAL s_sAdc_addr : std_logic_vector (15 DOWNTO 0);
  SIGNAL s_sAdc_data : std_logic_vector (15 DOWNTO 0);
  
  TYPE I2CState_type IS (
    State1,
    State2,
    State3
    );
  SIGNAL I2CState : I2CState_type;
  
BEGIN  -- ARCHITECTURE SYN

  reg0_out  <= s_reg0;
  reg1_out  <= s_reg1;
  reg2_out  <= s_reg2;
  reg3_out  <= s_reg3;
  reg4_out  <= s_reg4;
  sAdc_addr <= s_sAdc_addr(7 DOWNTO 0);
  sAdc_data <= s_sAdc_data;

  main : PROCESS (clock, reset) IS
    VARIABLE reg0_enable     : boolean;
    VARIABLE reg1_enable     : boolean;
    VARIABLE reg2_enable     : boolean;
    VARIABLE reg3_enable     : boolean;
    VARIABLE reg4_enable     : boolean;
    VARIABLE sAdcAddr_enable : boolean;
    VARIABLE sAdcData_enable : boolean;
  BEGIN  -- PROCESS main
    IF reset = '1' THEN                 -- asynchronous reset (active high)
      reg0_enable     := false;
      reg1_enable     := false;
      reg2_enable     := false;
      reg3_enable     := false;
      reg4_enable     := false;
      sAdcAddr_enable := false;
      sAdcData_enable := false;
      s_reg0          <= (OTHERS => '0');
      s_reg1          <= (OTHERS => '0');
      s_reg2          <= (OTHERS => '0');
      s_reg3          <= (OTHERS => '0');
      s_reg4          <= (OTHERS => '0');
      s_sAdc_addr     <= (OTHERS => '0');
      s_sAdc_data     <= (OTHERS => '0');
      I2CState        <= State1;
      
    ELSIF (clock'event AND clock = '0') THEN  -- falling clock edge
      reg0_enable := ((reg_load = '1') AND (reg_addr = x"00"));
      IF (reg0_enable) THEN
        s_reg0 <= reg_data;
      END IF;

      reg1_enable := ((reg_load = '1') AND (reg_addr = x"01"));
      IF (reg1_enable) THEN
        s_reg1 <= reg_data;
      END IF;

      reg2_enable := ((reg_load = '1') AND (reg_addr = x"02"));
      IF (reg2_enable) THEN
        s_reg2 <= reg_data;
      END IF;

      reg3_enable := ((reg_load = '1') AND (reg_addr = x"03"));
      IF (reg3_enable) THEN
        s_reg3 <= reg_data;
      END IF;

      reg4_enable := ((reg_load = '1') AND (reg_addr = x"04"));
      IF (reg4_enable) THEN
        s_reg4 <= reg_data;
      END IF;

      sAdcAddr_enable := ((reg_load = '1') AND (reg_addr = x"f0"));
      IF (sAdcAddr_enable) THEN
        s_sAdc_addr <= reg_data;
      END IF;

      sAdcData_enable := ((reg_load = '1') AND (reg_addr = x"f1"));
      IF (sAdcData_enable) THEN
        s_sAdc_data <= reg_data;
      END IF;

      -- When register 0 gets loaded, load a new ADC test pattern
      loadSAdcReg <= '0';
      CASE I2CState IS
        WHEN State1 =>
          IF sAdcData_enable THEN       -- only on sAdcData_enable
            I2CState <= State2;
          END IF;
        WHEN State2 =>
          IF NOT sAdcData_enable THEN   -- wait for enable to go false
            I2CState <= State3;
          END IF;
        WHEN State3 =>
          loadSAdcReg <= '1';          -- load pattern after register is loaded
          IF acknSAdc = '1' THEN        -- wait for acknowledge
            I2CState <= State1;
          END IF;
        WHEN OTHERS =>
          I2CState <= State1;
      END CASE;

    END IF;
  END PROCESS main;


  readRegOut <=
    s_reg0      WHEN reg_addr = x"00" ELSE
    s_reg1      WHEN reg_addr = x"01" ELSE
    s_reg2      WHEN reg_addr = x"02" ELSE
    s_reg3      WHEN reg_addr = x"03" ELSE
    s_reg4      WHEN reg_addr = x"04" ELSE
    s_sAdc_addr WHEN reg_addr = x"f0" ELSE
    s_sAdc_data WHEN reg_addr = x"f1" ELSE
    versionStr  WHEN reg_addr = x"ff" ELSE
    x"FFFF";

END ARCHITECTURE SYN;


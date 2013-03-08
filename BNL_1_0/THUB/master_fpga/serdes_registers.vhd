-- $Id: serdes_registers.vhd,v 1.1 2007-06-20 19:27:40 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : serdes registers
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_registers.vhd
-- Author     : 
-- Company    : 
-- Created    : 2007-06-15
-- Last update: 2007-06-19
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2007 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-06-15  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY serdes_registers IS
  PORT (
    clock    : IN  std_logic;
    arstn    : IN  std_logic;
    reg_data : IN  std_logic_vector (7 DOWNTO 0);
    reg_addr : IN  std_logic_vector (3 DOWNTO 0);
    reg_load : IN  std_logic;
    reg_out  : OUT std_logic_vector (7 DOWNTO 0)
    );
END serdes_registers;

ARCHITECTURE SYN OF serdes_registers IS

  SIGNAL register1 : std_logic_vector (7 DOWNTO 0);
  SIGNAL register2 : std_logic_vector (7 DOWNTO 0);
  SIGNAL register3 : std_logic_vector (7 DOWNTO 0);
  SIGNAL register4 : std_logic_vector (7 DOWNTO 0);
  SIGNAL register5 : std_logic_vector (7 DOWNTO 0);
  SIGNAL register6 : std_logic_vector (7 DOWNTO 0);
  SIGNAL register7 : std_logic_vector (7 DOWNTO 0);
  SIGNAL register8 : std_logic_vector (7 DOWNTO 0);

BEGIN  -- ARCHITECTURE SYN

  main : PROCESS (clock, arstn) IS
    VARIABLE reg1_enable  : boolean;
    VARIABLE reg2_enable  : boolean;
    VARIABLE reg3_enable  : boolean;
    VARIABLE reg4_enable  : boolean;
    VARIABLE reg5_enable  : boolean;
    VARIABLE reg6_enable  : boolean;
    VARIABLE reg7_enable  : boolean;
    VARIABLE reg8_enable  : boolean;
    VARIABLE reg_data_int : std_logic_vector (7 DOWNTO 0);
  BEGIN  -- PROCESS main
    IF arstn = '0' THEN                 -- asynchronous reset (active low)
      reg1_enable := false;
      reg2_enable := false;
      reg3_enable := false;
      reg4_enable := false;
      reg5_enable := false;
      reg6_enable := false;
      reg7_enable := false;
      reg8_enable := false;
      register1   <= (OTHERS => '0');
      register2   <= (OTHERS => '0');
      register3   <= (OTHERS => '0');
      register4   <= (OTHERS => '0');
      register5   <= (OTHERS => '0');
      register6   <= (OTHERS => '0');
      register7   <= (OTHERS => '0');
      register8   <= (OTHERS => '0');
    ELSIF (clock'event AND clock = '1') THEN  -- rising clock edge
      reg_data_int := reg_data;

      IF (reg1_enable) THEN
        register1 <= reg_data_int;
      END IF;
      reg1_enable := ((reg_load = '1') AND (reg_addr = "0001"));

      IF (reg2_enable) THEN
        register2 <= reg_data_int;
      END IF;
      reg2_enable := ((reg_load = '1') AND (reg_addr = "0010"));

      IF (reg3_enable) THEN
        register3 <= reg_data_int;
      END IF;
      reg3_enable := ((reg_load = '1') AND (reg_addr = "0011"));

      IF (reg4_enable) THEN
        register4 <= reg_data_int;
      END IF;
      reg4_enable := ((reg_load = '1') AND (reg_addr = "0100"));

      IF (reg5_enable) THEN
        register5 <= reg_data_int;
      END IF;
      reg5_enable := ((reg_load = '1') AND (reg_addr = "0101"));

      IF (reg6_enable) THEN
        register6 <= reg_data_int;
      END IF;
      reg6_enable := ((reg_load = '1') AND (reg_addr = "0110"));

      IF (reg7_enable) THEN
        register7 <= reg_data_int;
      END IF;
      reg7_enable := ((reg_load = '1') AND (reg_addr = "0111"));

      IF (reg8_enable) THEN
        register8 <= reg_data_int;
      END IF;
      reg8_enable := ((reg_load = '1') AND (reg_addr = "1000"));
      
      
    END IF;
  END PROCESS main;

  WITH reg_addr SELECT
    reg_out <=
    register1  WHEN "0001",
    register2  WHEN "0010",
    register3  WHEN "0011",
    register4  WHEN "0100",
    register5  WHEN "0101",
    register6  WHEN "0110",
    register7  WHEN "0111",
    register8  WHEN "1000",
    "00000000" WHEN "1001",
    "11111111" WHEN OTHERS;

END ARCHITECTURE SYN;


-- $Id: control_registers.vhd,v 1.2 2009-01-09 16:03:13 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : control registers
-- Project    : 
-------------------------------------------------------------------------------
-- File       : control_registers.vhd
-- Author     : 
-- Company    : 
-- Created    : 2006-06-26
-- Last update: 2009-01-09
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2006 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2006-06-26  1.0      jschamba	Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY control_registers IS
  PORT (
    clock       : IN  std_logic;
    arstn       : IN  std_logic;
    reg_data    : IN  std_logic_vector ( 7 DOWNTO 0);
    reg_addr    : IN  std_logic_vector ( 2 DOWNTO 0);
    reg_load    : IN  std_logic;
    reg0_out    : OUT std_logic_vector ( 7 DOWNTO 0);
    reg1_out    : OUT std_logic_vector ( 7 DOWNTO 0);
    reg2_out    : OUT std_logic_vector ( 7 DOWNTO 0);
    reg3_out    : OUT std_logic_vector ( 7 DOWNTO 0);
    reg4_out    : OUT std_logic_vector ( 7 DOWNTO 0)
    );
END control_registers;

ARCHITECTURE SYN OF control_registers IS

BEGIN  -- ARCHITECTURE SYN

  main: PROCESS (clock, arstn) IS
    VARIABLE reg0_enable : boolean;
    VARIABLE reg1_enable : boolean;
    VARIABLE reg2_enable : boolean;
    VARIABLE reg3_enable : boolean;
    VARIABLE reg4_enable : boolean;
    VARIABLE reg_data_int : std_logic_vector (7 DOWNTO 0);
  BEGIN  -- PROCESS main
    IF arstn = '0' THEN                 -- asynchronous reset (active low)
      reg0_enable := false;
      reg1_enable := false;
      reg2_enable := false;
      reg3_enable := false;
      reg4_enable := false;
      reg0_out    <= (OTHERS => '0');
      reg1_out    <= (OTHERS => '0');
      reg2_out    <= (OTHERS => '0');
      reg3_out    <= (OTHERS => '0');
      reg4_out    <= (OTHERS => '0');
    ELSIF (clock'event AND clock = '1') THEN  -- rising clock edge
      reg_data_int := reg_data;
      
      IF (reg0_enable) THEN
        reg0_out <= reg_data_int;
      END IF;
      reg0_enable := ((reg_load = '1') AND (reg_addr = "000"));
      
      IF (reg1_enable) THEN
        reg1_out <= reg_data_int;
      END IF;
      reg1_enable := ((reg_load = '1') AND (reg_addr = "001"));
      
      IF (reg2_enable) THEN
        reg2_out <= reg_data_int;
      END IF;
      reg2_enable := ((reg_load = '1') AND (reg_addr = "010"));
      
      IF (reg3_enable) THEN
        reg3_out <= reg_data_int;
      END IF;
      reg3_enable := ((reg_load = '1') AND (reg_addr = "011"));
      
      IF (reg4_enable) THEN
        reg4_out <= reg_data_int;
      END IF;
      reg4_enable := ((reg_load = '1') AND (reg_addr = "100"));
      
    END IF;
  END PROCESS main;

END ARCHITECTURE SYN;
    

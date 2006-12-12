-- $Id: uc_fpga_interface.vhd,v 1.3 2006-12-12 23:27:05 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : Micro-FPGA Interface
-- Project    : 
-------------------------------------------------------------------------------
-- File       : uc_fpga_interface.vhd
-- Author     : 
-- Company    : 
-- Created    : 2006-06-27
-- Last update: 2006-12-12
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Interface for bus between Micro and Main FPGA
-------------------------------------------------------------------------------
-- Copyright (c) 2006 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2006-06-27  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY uc_fpga_interface IS
  PORT (
    clock       : IN  std_logic;
    arstn       : IN  std_logic;
    dir         : IN  std_logic;
    ctl         : IN  std_logic;
    ds          : IN  std_logic;
    uc_data_in  : IN  std_logic_vector(7 DOWNTO 0);
    reg1        : IN  std_logic_vector(7 DOWNTO 0);
    reg2        : IN  std_logic_vector(7 DOWNTO 0);
    reg3        : IN  std_logic_vector(7 DOWNTO 0);
    reg4        : IN  std_logic_vector(7 DOWNTO 0);
    reg5        : IN  std_logic_vector(7 DOWNTO 0);
    reg6        : IN  std_logic_vector(7 DOWNTO 0);
    reg7        : IN  std_logic_vector(7 DOWNTO 0);
    reg8        : IN  std_logic_vector(7 DOWNTO 0);
    reg_addr    : OUT std_logic_vector(2 DOWNTO 0);
    reg_load    : OUT std_logic;
    reg_clr     : OUT std_logic;
    uc_data_out : OUT std_logic_vector(7 DOWNTO 0)
    );
END uc_fpga_interface;

ARCHITECTURE SYN OF uc_fpga_interface IS

  TYPE State_type IS (State0, State1, State2, State3, State4,
                      State5, State6, State7);
  SIGNAL state : State_type;

  SIGNAL is_address : boolean;
  SIGNAL is_data_w  : boolean;
  SIGNAL addr       : std_logic_vector(2 DOWNTO 0) := "111";

BEGIN  -- ARCHITECTURE SYN

  is_address <= (ctl = '1') AND (ds = '1') AND (dir = '1');
  is_data_w  <= (ctl = '0') AND (ds = '1') AND (dir = '1');

  reg_addr <= addr;

  uc_fpga_sm : PROCESS (clock, arstn) IS
  BEGIN  -- PROCESS uc_fpga_sm
    IF arstn = '0' THEN                     -- asynchronous reset (active low)
      addr     <= (OTHERS => '1');
      reg_load <= '0';
    ELSIF clock'event AND clock = '1' THEN  -- rising clock edge
      reg_load <= '0';
      reg_clr  <= '0';

      IF is_address AND (uc_data_in(7 DOWNTO 3) = "10000") THEN
        addr <= uc_data_in(2 DOWNTO 0);
      END IF;

      IF is_data_w AND (addr /= "111") THEN
        reg_load <= '1';
      ELSIF is_data_w AND (addr = "111") THEN
        reg_clr <= '1';
      END IF;

    END IF;
  END PROCESS uc_fpga_sm;
  
  WITH addr SELECT
    uc_data_out <=
    reg1 WHEN "000",
    reg2 WHEN "001",
    reg3 WHEN "010",
    reg4 WHEN "011",
    reg5 WHEN "100",
    reg6 WHEN "101",
    reg7 WHEN "110",
    reg8 WHEN "111";
  
END ARCHITECTURE SYN;

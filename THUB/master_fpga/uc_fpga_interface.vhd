-- $Id: uc_fpga_interface.vhd,v 1.1 2006-07-24 22:19:44 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : Micro-FPGA Interface
-- Project    : 
-------------------------------------------------------------------------------
-- File       : uc_fpga_interface.vhd
-- Author     : 
-- Company    : 
-- Created    : 2006-06-27
-- Last update: 2006-07-24
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
    reg_addr    : OUT std_logic_vector(2 DOWNTO 0);
    reg_load    : OUT std_logic;
    uc_data_out : OUT std_logic_vector(7 DOWNTO 0)
    );
END uc_fpga_interface;

ARCHITECTURE SYN OF uc_fpga_interface IS

  TYPE   State_type IS (State0, State1, State2, State3, State4,
                        State5, State6);
  SIGNAL state : State_type;

  SIGNAL is_address : boolean;
  SIGNAL is_idle_w  : boolean;
  SIGNAL is_data_w  : boolean;
  SIGNAL is_data_r  : boolean;
  SIGNAL is_idle_r  : boolean;
  SIGNAL addr       : std_logic_vector(2 DOWNTO 0) := "111";

BEGIN  -- ARCHITECTURE SYN

  is_address <= (dir = '1') AND (ctl = '1') AND (ds = '1');
  is_idle_w  <= (dir = '1') AND (ctl = '0') AND (ds = '0');
  is_data_w  <= (dir = '1') AND (ctl = '0') AND (ds = '1');
  is_data_r  <= (dir = '0') AND (ctl = '0') AND (ds = '1');
  is_idle_r  <= (dir = '0') AND (ctl = '0') AND (ds = '0');

  reg_addr <= addr;

  uc_fpga_sm : PROCESS (clock, arstn) IS
  BEGIN  -- PROCESS uc_fpga_sm
    IF arstn = '0' THEN                     -- asynchronous reset (active low)
      state    <= State0;
      addr <= (OTHERS => '1');
      reg_load <= '0';
    ELSIF clock'event AND clock = '1' THEN  -- rising clock edge
      reg_load <= '0';
      CASE state IS
        WHEN State0 =>
          IF is_address THEN
            state <= State1;
          END IF;
        WHEN State1 =>
          IF (uc_data_in(7 DOWNTO 3) = "10000") THEN
            state <= State2;
          ELSE
            state <= State6;
          END IF;
        WHEN State2 =>
          addr  <= uc_data_in(2 DOWNTO 0);
          state <= State3;
        WHEN State3 =>
          IF is_idle_w THEN
            state <= State4;
          END IF;
        WHEN State4 =>
          IF is_data_w THEN
            state <= State5;
          ELSIF is_data_r THEN
            state <= State6;
          END IF;
        WHEN State5 =>
          reg_load <= '1';
          state    <= State6;
        WHEN State6 =>
          IF is_idle_w OR is_idle_r THEN
            state <= State0;
          END IF;
        WHEN OTHERS => NULL;
      END CASE;
    END IF;
  END PROCESS uc_fpga_sm;

  WITH addr SELECT
    uc_data_out <=
    reg1       WHEN "000",
    reg2       WHEN "001",
    reg3       WHEN "010",
    reg4       WHEN "011",
    reg5       WHEN "100",
    "11111111" WHEN OTHERS;
  
END ARCHITECTURE SYN;

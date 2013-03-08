-- $Id: zbt_ctrl_top.vhd,v 1.1 2007-06-02 19:37:06 jschamba Exp $
--                                               
--  LOGIC CORE:          ZBT Controller Top level Module
--  MODULE NAME:         zbt_ctrl_top()
--  COMPANY:             Northwest Logic, Inc.
--  CLIENT:             Altera, Inc.    
--                              
--  REVISION HISTORY:                 
--                              
--    Revision 1.0                    
--    Description: Initial Release.   
--                              
--                              
--  FUNCTIONAL DESCRIPTION:           
--                              
--  Top level module for ZBT SRAM controller.
--                                                                      
--                                                                      
--  Copyright © 2000 Northwest Logic, Inc. All rights reserved.  
--  Altera products are protected under numerous U.S. and foreign patents, maskwork 
--  rights, copyrights and other intellectual property laws.  
--
--  This reference design file, and your use thereof, is subject to and governed by 
--  the terms and conditions of the applicable Altera Reference Design License 
--  Agreement (either as signed by you or found at www.altera.com).  By using this 
--  reference design file, you indicate your acceptance of such terms and conditions 
--  between you and Altera Corporation.  In the event that you do not agree with such 
--  terms and conditions, you may not use the reference design file and please 
--  promptly destroy any copies you have made.
--
--  This reference design file is being provided on an “as-is” basis and as an 
--  accommodation and therefore all warranties, representations or guarantees of any 
--  kind (whether express, implied or statutory) including, without limitation, 
--  warranties of merchantability, non-infringement, or fitness for a particular 
--  purpose, are specifically disclaimed.  By making this reference design file 
--  available, Altera expressly does not recommend, suggest or require that this 
--  reference design file be used in combination with any other product not provided 
--  by Altera.  
--                                                                      
--                                                                       

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY altera_mf;
USE altera_mf.ALL;


ENTITY zbt_ctrl_top IS

  PORT (

    clk     : IN std_logic;
    RESET_N : IN std_logic;             -- active LOW asynchronous reset

-- local bus interface
    ADDR          : IN  std_logic_vector(18 DOWNTO 0);
    DATA_IN       : IN  std_logic_vector(31 DOWNTO 0);
    DATA_OUT      : OUT std_logic_vector(31 DOWNTO 0);
    RD_WR_N       : IN  std_logic;                     -- active LOW write
    ADDR_ADV_LD_N : IN  std_logic;                     -- advance/load address (active LOW load)
    DM            : IN  std_logic_vector(3 DOWNTO 0);  -- data mask bits                   

-- SRAM interface
    SA       : OUT   std_logic_vector(18 DOWNTO 0);  -- address bus to RAM   
    DQ       : INOUT std_logic_vector(31 DOWNTO 0);  -- data to/from RAM
    RW_N     : OUT   std_logic;                      -- active LOW write
    ADV_LD_N : OUT   std_logic;                      -- active LOW load
    BW_N     : OUT   std_logic_vector(3 DOWNTO 0)    -- active LOW byte enables
    );
END zbt_ctrl_top;

ARCHITECTURE RTL OF zbt_ctrl_top IS


-- signal declarations

  SIGNAL reset                    : std_logic;
  SIGNAL delay_rw_n               : std_logic_vector(31 DOWNTO 0);
  SIGNAL delay_data_in, read_data : std_logic_vector(31 DOWNTO 0);

  SIGNAL data_in_reg, lb_data_out       : std_logic_vector(31 DOWNTO 0);
  SIGNAL addr_reg                       : std_logic_vector(31 DOWNTO 0);
  SIGNAL dm_reg                         : std_logic_vector(31 DOWNTO 0);
  SIGNAL rd_wr_n_reg, addr_adv_ld_n_reg : std_logic;

  SIGNAL write_pipe : std_logic_vector (2 DOWNTO 0);
  SIGNAL read_pipe  : std_logic_vector (3 DOWNTO 0);

  SIGNAL rdreq      : std_logic;
  SIGNAL wrreq      : std_logic;
  SIGNAL fifo_empty : std_logic;
  SIGNAL fifo_full  : std_logic;
  SIGNAL fifo_q     : std_logic_vector(31 DOWNTO 0);

  SIGNAL data_pipe1 : std_logic_vector(31 DOWNTO 0);
  -- SIGNAL data_pipe2 : std_logic_vector(31 DOWNTO 0);
  
BEGIN

  reset <= RESET_N;

-- directly tie these signals to SRAM
  SA       <= ADDR;
  RW_N     <= RD_WR_N;
  ADV_LD_N <= ADDR_ADV_LD_N;
  BW_N     <= NOT DM;


-- create the delayed write signal
  write_delay : PROCESS (clk, reset) IS
  BEGIN  -- PROCESS write_delay
    IF reset = '0' THEN                 -- asynchronous reset (active low)
      write_pipe <= (OTHERS => '0');
      data_pipe1 <= (OTHERS => '0');
      -- data_pipe2 <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN  -- rising clock edge
      IF ((RD_WR_N = '0') AND (DM = "1111")) THEN
        write_pipe(0) <= '1';
      ELSE
        write_pipe(0) <= '0';
      END IF;
      data_pipe1 <= DATA_IN;
      -- data_pipe2 <= data_pipe1;
      write_pipe(2 DOWNTO 1) <= write_pipe(1 DOWNTO 0);
    END IF;
  END PROCESS write_delay;

  --  gen : FOR i IN 31 DOWNTO 0 GENERATE
  --    DQ(i) <= data_pipe1(i) WHEN write_pipe(1) = '1' ELSE 'Z';
  --  END GENERATE gen;

  DQ <= data_pipe1 WHEN write_pipe(1) = '1' ELSE (OTHERS => 'Z');

-- create the delayed read signal
  read_delay : PROCESS (clk, reset) IS
  BEGIN  -- PROCESS read_delay
    IF reset = '0' THEN                 -- asynchronous reset (active low)
      read_pipe <= (OTHERS => '0');
    ELSIF clk'event AND clk = '0' THEN  -- falling clock edge
      IF ((RD_WR_N = '1') AND (DM = "1111")) THEN
        read_pipe(0) <= '1';
      ELSE
        read_pipe(0) <= '0';
      END IF;
      read_pipe(3 DOWNTO 1) <= read_pipe(2 DOWNTO 0);
    END IF;
  END PROCESS read_delay;

  PROCESS (clk, reset) IS
  BEGIN  -- PROCESS
    IF reset = '0' THEN                 -- asynchronous reset (active low)
      DATA_OUT <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN  -- rising clock edge
      IF read_pipe(3) = '1' THEN
        DATA_OUT <= DQ;
      END IF;
    END IF;
  END PROCESS;
END RTL;




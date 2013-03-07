-- $Id$
--                                               
--  LOGIC CORE:          ZBT Controller Address and Control Output Module
--  MODULE NAME:         addr_ctrl_out()
--  COMPANY:             Northwest Logic, Inc.
--  CLIENT:              Altera, Inc.   
--                              
--  REVISION HISTORY:                 
--                              
--    Revision 1.0                    
--    Description: Initial Release.   
--                              
--                              
--  FUNCTIONAL DESCRIPTION:           
--                              
--  Address and control bits output module.
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

ENTITY addr_ctrl_out IS

  GENERIC (
    ASIZE  : integer := 19;             -- address bus width
    BWSIZE : integer := 4               -- byte enable bus width
    );

  PORT (
    clk   : IN std_logic;
    reset : IN std_logic;

    lb_addr      : IN  std_logic_vector(ASIZE - 1 DOWNTO 0);   -- local bus addr input
    ram_addr     : OUT std_logic_vector(ASIZE - 1 DOWNTO 0);   -- addr to RAM
    lb_rw_n      : IN  std_logic;                              -- local bus read/write signal
    ram_rw_n     : OUT std_logic;                              -- read/write to RAM
    lb_adv_ld_n  : IN  std_logic;                              -- local bus advance/load signal
    ram_adv_ld_n : OUT std_logic;                              -- advance/load to RAM
    lb_bw        : IN  std_logic_vector(BWSIZE - 1 DOWNTO 0);  -- local bus byte write selects
    ram_bw_n     : OUT std_logic_vector(BWSIZE - 1 DOWNTO 0)   -- byte write selects to RAM
    );
END addr_ctrl_out;



ARCHITECTURE RTL OF addr_ctrl_out IS

-- signal declarations

  SIGNAL lb_bw_n : std_logic_vector(BWSIZE - 1 DOWNTO 0);


BEGIN

  lb_bw_n <= NOT lb_bw;

-- register output signals

  PROCESS (clk, reset)
  BEGIN
    IF (reset = '1') THEN
      ram_addr     <= (OTHERS => '0');
      ram_rw_n     <= '0';
      ram_adv_ld_n <= '0';
      ram_bw_n     <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      ram_addr     <= lb_addr;
      ram_rw_n     <= lb_rw_n;
      ram_adv_ld_n <= lb_adv_ld_n;
      ram_bw_n     <= lb_bw_n;
    END IF;
  END PROCESS;

END RTL;


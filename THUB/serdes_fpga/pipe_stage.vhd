-- $Id: pipe_stage.vhd,v 1.1 2007-06-02 19:36:13 jschamba Exp $
--                                               
--  LOGIC CORE:          ZBT Controller Pipe Stage Module
--  MODULE NAME:         pipe_stage()
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
--  Register level for getting signals on/off chip fast (not needed if controller is
--  interfaced with another design on chip).
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


ENTITY pipe_stage IS

  GENERIC (
    DSIZE  : integer := 32;             -- data bus width
    ASIZE  : integer := 19;             -- address bus width
    BWSIZE : integer := 4               -- byte enable bus width
    );

  PORT (
    clk   : IN std_logic;
    reset : IN std_logic;

    addr          : IN std_logic_vector(ASIZE - 1 DOWNTO 0);
    data_in       : IN std_logic_vector(DSIZE - 1 DOWNTO 0);
    data_out      : IN std_logic_vector(DSIZE - 1 DOWNTO 0);
    rd_wr_n       : IN std_logic;                              -- active LOW write
    addr_adv_ld_n : IN std_logic;                              -- advance/load address (active LOW load)
    dm            : IN std_logic_vector(BWSIZE - 1 DOWNTO 0);  -- data mask bits                   

    addr_reg          : OUT std_logic_vector(ASIZE - 1 DOWNTO 0);
    data_in_reg       : OUT std_logic_vector(DSIZE - 1 DOWNTO 0);
    data_out_reg      : OUT std_logic_vector(DSIZE - 1 DOWNTO 0);
    rd_wr_n_reg       : OUT std_logic;
    addr_adv_ld_n_reg : OUT std_logic;
    dm_reg            : OUT std_logic_vector(BWSIZE - 1 DOWNTO 0)
    );
END pipe_stage;



ARCHITECTURE RTL OF pipe_stage IS

BEGIN

-- register all signals

  PROCESS(clk, reset)
  BEGIN
    IF (reset = '1') THEN
      addr_reg          <= (OTHERS => '0');
      data_in_reg       <= (OTHERS => '0');
      data_out_reg      <= (OTHERS => '0');
      rd_wr_n_reg       <= '0';
      addr_adv_ld_n_reg <= '0';
      dm_reg            <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      addr_reg          <= addr;
      data_in_reg       <= data_in;
      data_out_reg      <= data_out;
      rd_wr_n_reg       <= rd_wr_n;
      addr_adv_ld_n_reg <= addr_adv_ld_n;
      dm_reg            <= dm;
    END IF;
  END PROCESS;


END RTL;


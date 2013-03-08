-- $Id: pipe_delay.vhd,v 1.1 2007-06-02 19:35:47 jschamba Exp $
--                                               
--  LOGIC CORE:          ZBT Controller Pipeline delay Module
--  MODULE NAME:         pipe_delay()
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
--  Pipeline delay module for flowthrough and pipelined ZBT SRAM.
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
--use synplify.attributes.all;


ENTITY pipe_delay IS

  GENERIC (
    FLOWTHROUGH : integer := 0;         -- Pipelined if zero, Flowthrough if one
    DSIZE       : integer := 32;        -- bit width of data
    BWSIZE      : integer := 4          -- byte enable bus width
    );

  PORT (
    clk   : IN std_logic;
    reset : IN std_logic;

    lb_rw_n    : IN  std_logic;                             -- local bus read/write signal
    delay_rw_n : OUT std_logic_vector(DSIZE - 1 DOWNTO 0);  -- read/write to tri-state enable

    lb_data_in    : IN  std_logic_vector(DSIZE - 1 DOWNTO 0);  -- data from local bus
    delay_data_in : OUT std_logic_vector(DSIZE - 1 DOWNTO 0);  -- data to RAM

    lb_data_out  : OUT std_logic_vector(DSIZE - 1 DOWNTO 0);  -- data to local bus
    ram_data_out : IN  std_logic_vector(DSIZE - 1 DOWNTO 0)   -- data from RAM
    );

--attribute syn_preserve of delay_rw_n : signal is true;

END pipe_delay;



ARCHITECTURE RTL OF pipe_delay IS

-- signal declarations
  SIGNAL rw_n_pipe : std_logic_vector(3 DOWNTO 0);

  TYPE my_array IS ARRAY(1 DOWNTO 0) OF std_logic_vector(DSIZE - 1 DOWNTO 0);

  SIGNAL data_in_pipe : my_array;


BEGIN

  delay_data_in <= data_in_pipe(1 - FLOWTHROUGH);

-- fan out rw_n_pipe
  PROCESS (rw_n_pipe(0), rw_n_pipe(1), rw_n_pipe(2))
  BEGIN
    --for i in BWSIZE - 1 downto 0 loop
    delay_rw_n(DSIZE - 1)  <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 2)  <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 3)  <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 4)  <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 5)  <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 6)  <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 7)  <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 8)  <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 9)  <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 10) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 11) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 12) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 13) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 14) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 15) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 16) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 17) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 18) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 19) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 20) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 21) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 22) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 23) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 24) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 25) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 26) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 27) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 28) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 29) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 30) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 31) <= rw_n_pipe(1 - FLOWTHROUGH);
    delay_rw_n(DSIZE - 32) <= rw_n_pipe(1 - FLOWTHROUGH);

    --end loop;
  END PROCESS;


-- pipeline read/write signal and data
  PROCESS (clk, reset)
  BEGIN
    IF (reset = '1') THEN
      rw_n_pipe       <= (OTHERS => '0');
      data_in_pipe(0) <= (OTHERS => '0');
      data_in_pipe(1) <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      rw_n_pipe(0)          <= lb_rw_n;
      rw_n_pipe(3 DOWNTO 1) <= rw_n_pipe(2 DOWNTO 0);

      data_in_pipe(0) <= lb_data_in;
      data_in_pipe(1) <= data_in_pipe(0);
    END IF;
  END PROCESS;


  PROCESS (clk, reset)
  BEGIN
    IF (reset = '1') THEN
      lb_data_out <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      IF (rw_n_pipe(2) = '1') THEN
        lb_data_out <= ram_data_out;
      END IF;
    END IF;
  END PROCESS;

END RTL;






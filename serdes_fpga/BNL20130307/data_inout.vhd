-- $Id$
--                                               
--  LOGIC CORE:          ZBT Controller Data Input/Output Module
--  MODULE NAME:         data_inout()
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
--  Data input/output module.
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

ENTITY data_inout IS

  GENERIC (
    DSIZE  : integer := 32;             -- data bus width
    BWSIZE : integer := 4               -- byte enable bus width
    );

  PORT (
    clk   : IN std_logic;
    reset : IN std_logic;

    ctrl_in_rw_n : IN    std_logic_vector(DSIZE - 1 DOWNTO 0);  -- delayed read/write signal
    data_in      : IN    std_logic_vector(DSIZE - 1 DOWNTO 0);  -- input data to RAM
    dq           : INOUT std_logic_vector(DSIZE - 1 DOWNTO 0);  -- bi-directional to/from RAM
    read_data    : OUT   std_logic_vector(DSIZE - 1 DOWNTO 0)   -- data from RAM
    );
END data_inout;


ARCHITECTURE RTL OF data_inout IS

-- signal declarations

  SIGNAL tri_r_n_w  : std_logic_vector(DSIZE - 1 DOWNTO 0);
  SIGNAL write_data : std_logic_vector(DSIZE - 1 DOWNTO 0);

--attribute syn_preserve of tri_r_n_w : signal is true;


BEGIN

-- tri-state output bus
-- assume there are 4 segments of the DQ bus, assign a separate tri-state enable to each of them

  --    gen:    for i in DSIZE - 1 downto 0 generate
  dq(0)  <= write_data(0)  WHEN tri_r_n_w(0) = '1'  ELSE 'Z';
  dq(1)  <= write_data(1)  WHEN tri_r_n_w(1) = '1'  ELSE 'Z';
  dq(2)  <= write_data(2)  WHEN tri_r_n_w(2) = '1'  ELSE 'Z';
  dq(3)  <= write_data(3)  WHEN tri_r_n_w(3) = '1'  ELSE 'Z';
  dq(4)  <= write_data(4)  WHEN tri_r_n_w(4) = '1'  ELSE 'Z';
  dq(5)  <= write_data(5)  WHEN tri_r_n_w(5) = '1'  ELSE 'Z';
  dq(6)  <= write_data(6)  WHEN tri_r_n_w(6) = '1'  ELSE 'Z';
  dq(7)  <= write_data(7)  WHEN tri_r_n_w(7) = '1'  ELSE 'Z';
  dq(8)  <= write_data(8)  WHEN tri_r_n_w(8) = '1'  ELSE 'Z';
  dq(9)  <= write_data(9)  WHEN tri_r_n_w(9) = '1'  ELSE 'Z';
  dq(10) <= write_data(10) WHEN tri_r_n_w(10) = '1' ELSE 'Z';
  dq(11) <= write_data(11) WHEN tri_r_n_w(11) = '1' ELSE 'Z';
  dq(12) <= write_data(12) WHEN tri_r_n_w(12) = '1' ELSE 'Z';
  dq(13) <= write_data(13) WHEN tri_r_n_w(13) = '1' ELSE 'Z';
  dq(14) <= write_data(14) WHEN tri_r_n_w(14) = '1' ELSE 'Z';
  dq(15) <= write_data(15) WHEN tri_r_n_w(15) = '1' ELSE 'Z';
  dq(16) <= write_data(16) WHEN tri_r_n_w(16) = '1' ELSE 'Z';
  dq(17) <= write_data(17) WHEN tri_r_n_w(17) = '1' ELSE 'Z';
  dq(18) <= write_data(18) WHEN tri_r_n_w(18) = '1' ELSE 'Z';
  dq(19) <= write_data(19) WHEN tri_r_n_w(19) = '1' ELSE 'Z';
  dq(20) <= write_data(20) WHEN tri_r_n_w(20) = '1' ELSE 'Z';
  dq(21) <= write_data(21) WHEN tri_r_n_w(21) = '1' ELSE 'Z';
  dq(22) <= write_data(22) WHEN tri_r_n_w(22) = '1' ELSE 'Z';
  dq(23) <= write_data(23) WHEN tri_r_n_w(23) = '1' ELSE 'Z';
  dq(24) <= write_data(24) WHEN tri_r_n_w(24) = '1' ELSE 'Z';
  dq(25) <= write_data(25) WHEN tri_r_n_w(25) = '1' ELSE 'Z';
  dq(26) <= write_data(26) WHEN tri_r_n_w(26) = '1' ELSE 'Z';
  dq(27) <= write_data(27) WHEN tri_r_n_w(27) = '1' ELSE 'Z';
  dq(28) <= write_data(28) WHEN tri_r_n_w(28) = '1' ELSE 'Z';
  dq(29) <= write_data(29) WHEN tri_r_n_w(29) = '1' ELSE 'Z';
  dq(30) <= write_data(30) WHEN tri_r_n_w(30) = '1' ELSE 'Z';
  dq(31) <= write_data(31) WHEN tri_r_n_w(31) = '1' ELSE 'Z';

  read_data <= dq;

-- register data_in and tri-state control signal
  PROCESS (clk, reset)
  BEGIN
    IF (reset = '1') THEN
      tri_r_n_w  <= (OTHERS => '0');
      write_data <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      tri_r_n_w  <= NOT ctrl_in_rw_n;
      write_data <= data_in;
    END IF;
  END PROCESS;

END RTL;






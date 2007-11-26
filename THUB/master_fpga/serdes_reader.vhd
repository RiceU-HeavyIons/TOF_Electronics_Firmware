-- $Id: serdes_reader.vhd,v 1.1 2007-11-26 21:59:05 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : Serdes Reader
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_reader.vhd
-- Author     : 
-- Company    : 
-- Created    : 2007-11-21
-- Last update: 2007-11-21
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Reads the data from the Serdes FPGA and generates the
--              necessary signals to latch it into a (dual clock) FIFO
-------------------------------------------------------------------------------
-- Copyright (c) 2007 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-11-21  1.0      jschamba        Created
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera;
USE altera.altera_primitives_components.ALL;
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

ENTITY serdes_reader IS
  
  PORT (
    clk80mhz   : IN  std_logic;
    areset_n   : IN  std_logic;
    indata     : IN  std_logic_vector(15 DOWNTO 0);
    fifo_empty : IN  std_logic;
    rdsel_out  : OUT std_logic_vector(1 DOWNTO 0);
    rdreq_out  : OUT std_logic;
    wrreq_out  : OUT std_logic;         -- assuming FIFO clk is clk80mhz
    outdata    : OUT std_logic_vector(31 DOWNTO 0)
    );


END ENTITY serdes_reader;

ARCHITECTURE a OF serdes_reader IS

  SIGNAL s_outdata   : std_logic_vector (31 DOWNTO 0);
  SIGNAL s_wrreq_out : std_logic;
  
BEGIN  -- ARCHITECTURE a

  rdsel_out <= "00";
  wrreq_out <= s_wrreq_out;
  outdata   <= s_outdata;
  rdreq_out <= '1';


  shifter : PROCESS (clk80mhz, areset_n) IS
    VARIABLE ctr : integer RANGE 0 TO 2 := 0;
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      s_outdata <= (OTHERS => '0');
      ctr       := 0;
      
    ELSIF clk80mhz'event AND clk80mhz = '1' THEN  -- rising clock edge
      s_wrreq_out <= '0';

      IF fifo_empty = '0' THEN
        ctr                     := ctr + 1;
        s_outdata(15 DOWNTO 0)  <= indata;
        s_outdata(31 DOWNTO 16) <= s_outdata(15 DOWNTO 0);
      END IF;

      IF ctr = 2 THEN
        s_wrreq_out <= '1';
        ctr         := 0;
      END IF;
      
    END IF;
  END PROCESS shifter;

  
END ARCHITECTURE a;

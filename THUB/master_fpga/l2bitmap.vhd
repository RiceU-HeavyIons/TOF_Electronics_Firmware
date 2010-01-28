-- $Id: l2bitmap.vhd,v 1.1 2010-01-28 22:07:35 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : MASTER_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : l2bitmap.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2009-12-11
-- Last update: 2009-12-11
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Component for the THUB MASTER FPGAs to calculate L2 bitmap
-------------------------------------------------------------------------------
-- Copyright (c) 2009 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2009-12-11  1.0      jschamba        Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera;
USE altera.altera_primitives_components.ALL;
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

ENTITY l2bitmap IS
  PORT
    (
      areset_n   : IN  std_logic;       -- asynchronous reset, active low
      clk        : IN  std_logic;
      rdreq_in   : IN  std_logic;
      data_in    : IN  std_logic_vector (31 DOWNTO 0);
      bm_out     : OUT std_logic_vector (191 DOWNTO 0)
      );
END l2bitmap;


ARCHITECTURE a OF l2bitmap IS

  
  SIGNAL hilo_tray : std_logic := '1';  -- indicates if at hi or lo end of tray
  SIGNAL bm_index : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_bm_out : std_logic_vector (191 DOWNTO 0);
  SIGNAL s_bitmap : std_logic_vector(255 DOWNTO 0);
  
BEGIN
  bm_index <= hilo_tray & data_in(27 DOWNTO 21);
  bm_out <= s_bm_out;

  s_bm_out <= s_bitmap(247 DOWNTO 224) & s_bitmap(215 DOWNTO 192)
              & s_bitmap(183 DOWNTO 160) & s_bitmap(151 DOWNTO 128)
              & s_bitmap(119 DOWNTO 96) & s_bitmap(87 DOWNTO 64)
              & s_bitmap(55 DOWNTO 32) & s_bitmap(23 DOWNTO 0);

  
  latch_bitmap: PROCESS (clk, areset_n) IS
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      s_bitmap <= (OTHERS => '0');
      hilo_tray <= '1';
      
    ELSIF rising_edge(clk) THEN  -- rising clock edge

      IF rdreq_in = '0' THEN
        
        IF data_in(31 DOWNTO 28) = X"4" THEN
          -- leading edge value
          s_bitmap(slv2int(bm_index)) <= '1';
        ELSIF data_in(31 DOWNTO  24) = X"E0" THEN
          -- end of low end of tray, switch to hi end
          hilo_tray <= '1';
        ELSIF data_in(31 DOWNTO 24) = X"E1" THEN
          -- end of hi end of tray, switch to lo end
          hilo_tray <= '0';
        END IF;

      END IF;

    END IF;
  END PROCESS latch_bitmap;

  
END a;

-- $Id: ped_average.vhd,v 1.1 2009-01-31 20:45:59 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : Average pedestal calculation
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ped_average.vhd
-- Author     : 
-- Company    : 
-- Created    : 2009-01-22
-- Last update: 2009-01-24
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2009 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2009-01-22  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

-------------------------------------------------------------------------------

ENTITY ped_average IS
  GENERIC (
    WIDTH : integer := 12;              -- data sample width
    POW   : integer := 4);              -- 2^(POW) samples to average
  PORT (
    -- clocks and reset
    reset  : IN std_logic;              -- reset (active high)
    clk    : IN std_logic;              -- ADC sample clock
    sample : IN std_logic_vector(WIDTH-1 DOWNTO 0);

    average : OUT std_logic_vector(WIDTH-1 DOWNTO 0)
    );
END ENTITY ped_average;

-------------------------------------------------------------------------------

ARCHITECTURE str5 OF ped_average IS
  SIGNAL count : std_logic_vector(POW DOWNTO 0);
  SIGNAL sum   : std_logic_vector((WIDTH+POW-1) DOWNTO 0);

  SIGNAL NULL_BUS : std_logic_vector(POW-1 DOWNTO 0);
  SIGNAL MODULUS  : std_logic_vector(POW DOWNTO 0);

BEGIN
  NULL_BUS <= (OTHERS => '0');
  MODULUS  <= '1' & NULL_BUS;

  -- counter that is reset one clock after it reaches "MODULUS"
  counter_inst : PROCESS (clk, reset) IS
  BEGIN
    IF reset = '1' THEN                 -- asynchronous reset (active high)
      count <= (OTHERS => '0');
    ELSIF clk'event AND clk = '1' THEN  -- rising clock edge
      IF count = MODULUS THEN
        count <= (OTHERS => '0');
      ELSE
        count <= count + 1;
      END IF;
    END IF;
  END PROCESS counter_inst;

  -- average over 2^(POW+1) samples
  ave_inst : PROCESS (clk, reset) IS
  BEGIN
    IF reset = '1' THEN                 -- asynchronous reset (active high)
      sum     <= (OTHERS => '0');
      average <= (OTHERS => '0');
      
    ELSIF clk'event AND clk = '1' THEN  -- rising clock edge
      IF count = MODULUS THEN
        -- update average and reset sum
        average <= sum((WIDTH+POW-1) DOWNTO POW);
        sum     <= (OTHERS => '0');
      ELSE
        sum <= sum + sample;
      END IF;
    END IF;
  END PROCESS ave_inst;

  
END ARCHITECTURE str5;

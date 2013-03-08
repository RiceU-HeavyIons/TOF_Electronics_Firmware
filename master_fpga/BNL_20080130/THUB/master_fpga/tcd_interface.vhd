-- $Id: tcd_interface.vhd,v 1.5 2007-11-16 21:50:34 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : TCD Interface
-- Project    : THUB
-------------------------------------------------------------------------------
-- File       : tcd_interface.vhd
-- Author     : 
-- Company    : 
-- Created    : 2006-09-01
-- Last update: 2007-11-16
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Interface to TCD signals
-------------------------------------------------------------------------------
-- Copyright (c) 2006 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2006-09-01  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
LIBRARY altera;
USE altera.altera_primitives_components.ALL;

ENTITY tcd IS
  
  PORT (
    rhic_strobe : IN  std_logic;        -- TCD RHIC strobe
    data_strobe : IN  std_logic;        -- TCD data clock
    data        : IN  std_logic_vector (3 DOWNTO 0);   -- TCD data
    clock       : IN  std_logic;        -- 40 MHz clock
    trgword     : OUT std_logic_vector (19 DOWNTO 0);  -- captured 20bit word
    trigger     : OUT std_logic;        -- strobe signal sync'd to clock
    evt_trg     : OUT std_logic         -- this signal indicates an event
    );

END ENTITY tcd;

ARCHITECTURE a OF tcd IS

  SIGNAL s_reg1       : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg2       : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg3       : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg4       : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg5       : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg20_1    : std_logic_vector (19 DOWNTO 0);
  SIGNAL s_trg_unsync : std_logic;
  SIGNAL s_stage1     : std_logic;
  SIGNAL s_stage2     : std_logic;
  SIGNAL s_stage3     : std_logic;
  SIGNAL s_stage4     : std_logic;
  
BEGIN  -- ARCHITECTURE a

  -- inv_data_strobe <= NOT data_strobe;

  -- capture the trigger data in a cascade of 5 4-bit registers
  -- with the tcd data clock on trailing clock edge.

  dff_cascade : PROCESS (data_strobe) IS
  BEGIN
    IF data_strobe'event AND data_strobe = '0' THEN  -- falling clock edge
      s_reg1 <= data;
      s_reg2 <= s_reg1;
      s_reg3 <= s_reg2;
      s_reg4 <= s_reg3;
      s_reg5 <= s_reg4;
      
    END IF;
  END PROCESS dff_cascade;

  -- On the rising edge of the RHIC strobe, latch the 5 4-bit registers into a
  -- 20-bit register.
  reg20_1 : PROCESS (rhic_strobe) IS
  BEGIN
    IF rhic_strobe'event AND rhic_strobe = '1' THEN  -- rising clock edge
      s_reg20_1 (19 DOWNTO 16) <= s_reg5;
      s_reg20_1 (15 DOWNTO 12) <= s_reg4;
      s_reg20_1 (11 DOWNTO 8)  <= s_reg3;
      s_reg20_1 (7 DOWNTO 4)   <= s_reg2;
      s_reg20_1 (3 DOWNTO 0)   <= s_reg1;
    END IF;
  END PROCESS reg20_1;

  -- use this as the trigger word output
  trgword <= s_reg20_1;

  -- now check if there is a valid trigger command:
  trg : PROCESS (s_reg20_1(19 DOWNTO 16)) IS
  BEGIN
    CASE s_reg20_1(19 DOWNTO 16) IS
      WHEN "0100" =>                    -- "4" (trigger0)
        s_trg_unsync <= '1';
        evt_trg      <= '1';
      WHEN "0101" =>                    -- "5" (trigger1)
        s_trg_unsync <= '1';
        evt_trg      <= '1';
      WHEN "0110" =>                    -- "6" (trigger2)
        s_trg_unsync <= '1';
        evt_trg      <= '1';
      WHEN "0111" =>                    -- "7" (trigger3)
        s_trg_unsync <= '1';
        evt_trg      <= '1';
      WHEN "1000" =>                    -- "8" (pulser0)
        s_trg_unsync <= '1';
        evt_trg      <= '1';
      WHEN "1001" =>                    -- "9" (pulser1)
        s_trg_unsync <= '1';
        evt_trg      <= '1';
      WHEN "1010" =>                    -- "10" (pulser2)
        s_trg_unsync <= '1';
        evt_trg      <= '1';
      WHEN "1011" =>                    -- "11" (pulser3)
        s_trg_unsync <= '1';
        evt_trg      <= '1';
      WHEN "1100" =>                    -- "12" (config)
        s_trg_unsync <= '1';
        evt_trg      <= '1';
      WHEN "1101" =>                    -- "13" (abort)
        s_trg_unsync <= '1';
        evt_trg      <= '0';
      WHEN "1110" =>                    -- "14" (L1accept)
        s_trg_unsync <= '1';
        evt_trg      <= '0';
      WHEN "1111" =>                    -- "15" (L2accept)
        s_trg_unsync <= '1';
        evt_trg      <= '0';
      WHEN OTHERS =>
        s_trg_unsync <= '0';
        evt_trg      <= '0';
    END CASE;
  END PROCESS trg;

  -- when a valid trigger command is found, synchronize the resulting trigger
  -- to the 40MHz clock with a 4 stage DFF cascade and to make the signal
  -- exactly 1 clock wide

  syncit : PROCESS (clock) IS
  BEGIN
    IF clock'event AND clock = '1' THEN  -- rising clock edge
      s_stage1 <= s_trg_unsync;
      s_stage2 <= s_stage1;
      s_stage3 <= s_stage2;
      s_stage4 <= s_stage3;
    END IF;
  END PROCESS syncit;

  trigger <= s_stage3 AND (NOT s_stage4);
  
END ARCHITECTURE a;

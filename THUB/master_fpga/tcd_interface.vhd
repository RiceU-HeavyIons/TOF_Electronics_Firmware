-- $Id: tcd_interface.vhd,v 1.12 2010-01-07 17:24:16 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : TCD Interface
-- Project    : THUB
-------------------------------------------------------------------------------
-- File       : tcd_interface.vhd
-- Author     : 
-- Company    : 
-- Created    : 2006-09-01
-- Last update: 2010-01-04
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
USE ieee.std_logic_unsigned.ALL;

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
    reset_n     : IN  std_logic;
    working     : OUT std_logic;
    trgword     : OUT std_logic_vector (19 DOWNTO 0);  -- captured 20bit word
    master_rst  : OUT std_logic;        -- indicates master reset command
    trigger     : OUT std_logic;        -- strobe signal sync'd to clock
    evt_trg     : OUT std_logic         -- this signal indicates an event
    );

END ENTITY tcd;

ARCHITECTURE a OF tcd IS
  TYPE type_sreg IS (S1, S2, S3, S4, S5);
  SIGNAL sreg : type_sreg;

  TYPE resetState_type IS (rss1, rss2, rss3);
  SIGNAL resetState : resetState_type;

  TYPE rsState_type IS (R0l, R0h, R1, R2, R3, R4, R5);
  SIGNAL rsState : rsState_type;


  SIGNAL s_reg1           : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg2           : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg3           : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg4           : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg5           : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg20_1        : std_logic_vector (19 DOWNTO 0);
  SIGNAL s_reg20_2        : std_logic_vector (19 DOWNTO 0);
  SIGNAL s_trg_unsync     : std_logic;
  SIGNAL s_trg_short      : std_logic;
  SIGNAL s_stage1         : std_logic;
  SIGNAL s_stage2         : std_logic;
  SIGNAL s_stage3         : std_logic;
  SIGNAL s_mstage1        : std_logic;
  SIGNAL s_mstage2        : std_logic;
  SIGNAL s_mstage3        : std_logic;
  SIGNAL s_l0like         : std_logic;
  SIGNAL s_trigger        : std_logic;
  SIGNAL s_reset_n        : std_logic;
  SIGNAL s_mstr_rst       : std_logic;
  SIGNAL edges            : std_logic_vector(2 DOWNTO 0);
  SIGNAL missing_strobe_n : std_logic;
  SIGNAL edgeRst_n        : std_logic;
  SIGNAL counter          : integer RANGE 0 TO 15;
  
BEGIN  -- ARCHITECTURE a

  -- reset the state machine on both an external reset (PLL lock)
  -- and missing RHICstrobes
  s_reset_n <= reset_n AND missing_strobe_n;

  -- capture the trigger data in a cascade of 5 4-bit registers
  -- with the tcd data clock on trailing clock edge.
  latchTrig : PROCESS (data_strobe, s_reset_n) IS
  BEGIN
    IF s_reset_n = '0' THEN             -- asynchronous reset (active low)
      s_reg1    <= (OTHERS => '0');
      s_reg2    <= (OTHERS => '0');
      s_reg3    <= (OTHERS => '0');
      s_reg4    <= (OTHERS => '0');
      s_reg5    <= (OTHERS => '0');
      s_reg20_1 <= (OTHERS => '0');
      working   <= '0';
      rsState   <= R0l;
      
    ELSIF falling_edge(data_strobe) THEN
      working <= '1';                   -- default: "it works"
      CASE rsState IS
        WHEN R0l =>
          working   <= '0';             -- not "working right" (yet)
          s_reg1    <= (OTHERS => '0');
          s_reg2    <= (OTHERS => '0');
          s_reg3    <= (OTHERS => '0');
          s_reg4    <= (OTHERS => '0');
          s_reg5    <= (OTHERS => '0');
          s_reg20_1 <= (OTHERS => '0');
          -- wait for RHICstrobe to be low
          IF rhic_strobe = '0' THEN
            rsState <= R0h;
          END IF;
        WHEN R0h =>
          working <= '0';               -- not "working right" (yet)
          s_reg1  <= data;              -- latch current nibble
          -- wait for RHICstrobe to go hi
          IF rhic_strobe = '1' THEN
            rsState <= R2;
          END IF;

          -- now the state machine should be aligned to the RHICstrobe
        WHEN R1 =>

          -- make sure we see RHICstrobe being high during this nibble
          IF rhic_strobe = '1' THEN
            -- latch current nibbles into 20bit register
            s_reg20_1 (19 DOWNTO 16) <= s_reg1;
            s_reg20_1 (15 DOWNTO 12) <= s_reg2;
            s_reg20_1 (11 DOWNTO 8)  <= s_reg3;
            s_reg20_1 (7 DOWNTO 4)   <= s_reg4;
            s_reg20_1 (3 DOWNTO 0)   <= s_reg5;

            s_reg1 <= data;

            rsState <= R2;
          ELSE
            s_reg20_1 <= (OTHERS => '0');
            -- try new sync, if not
            rsState   <= R0l;
          END IF;
        WHEN R2 =>
          trgWord <= s_reg20_1;
          s_reg2  <= data;
          rsState <= R3;
        WHEN R3 =>
          s_reg3  <= data;
          rsState <= R4;
        WHEN R4 =>
          s_reg4  <= data;
          rsState <= R5;
        WHEN R5 =>
          s_reg5  <= data;
          rsState <= R1;

      END CASE;
      
    END IF;
  END PROCESS latchTrig;


  -- now check if there is a valid trigger command:
  trg : PROCESS (data_strobe, s_reset_n) IS
  BEGIN
    IF s_reset_n = '0' THEN             -- asynchronous reset (active low)
      s_trg_unsync <= '0';
      s_l0like     <= '0';
      s_mstr_rst   <= '0';

    ELSIF rising_edge(data_strobe) THEN  -- only on rising edge of data strobe
      CASE s_reg20_1(19 DOWNTO 16) IS
        WHEN "0100" =>                   -- "4" (trigger0)
          s_trg_unsync <= '1';
          s_l0like     <= '1';
        WHEN "0101" =>                   -- "5" (trigger1)
          s_trg_unsync <= '1';
          s_l0like     <= '1';
        WHEN "0110" =>                   -- "6" (trigger2)
          s_trg_unsync <= '1';
          s_l0like     <= '1';
        WHEN "0111" =>                   -- "7" (trigger3)
          s_trg_unsync <= '1';
          s_l0like     <= '1';
        WHEN "1000" =>                   -- "8" (pulser0)
          s_trg_unsync <= '1';
          s_l0like     <= '1';
        WHEN "1001" =>                   -- "9" (pulser1)
          s_trg_unsync <= '1';
          s_l0like     <= '1';
        WHEN "1010" =>                   -- "10" (pulser2)
          s_trg_unsync <= '1';
          s_l0like     <= '1';
        WHEN "1011" =>                   -- "11" (pulser3)
          s_trg_unsync <= '1';
          s_l0like     <= '1';
        WHEN "1100" =>                   -- "12" (config)
          s_trg_unsync <= '1';
          s_l0like     <= '1';
        WHEN "1101" =>                   -- "13" (abort)
          s_trg_unsync <= '1';
          s_l0like     <= '0';
        WHEN "1110" =>                   -- "14" (L1accept)
          s_trg_unsync <= '1';
          s_l0like     <= '0';
        WHEN "1111" =>                   -- "15" (L2accept)
          s_trg_unsync <= '1';
          s_l0like     <= '0';
        WHEN OTHERS =>
          s_trg_unsync <= '0';
          s_l0like     <= '0';
      END CASE;

      -- master reset command
      IF s_reg20_1(19 DOWNTO 16) = "0010" THEN
        s_mstr_rst <= '1';
      ELSE
        s_mstr_rst <= '0';
      END IF;
    END IF;
  END PROCESS trg;

  -- shorten s_trg_unsync to 2 data strobe clock cycles
  -- so two consecutive triggers are distinguished
  shorten : PROCESS (data_strobe, s_reset_n) IS
  BEGIN
    IF s_reset_n = '0' THEN             -- asynchronous reset (active low)
      s_trg_short <= '0';
      sreg        <= S1;
    ELSIF falling_edge(data_strobe) THEN
      s_trg_short <= '0';

      CASE sreg IS
        WHEN S1 =>
          s_trg_short <= s_trg_unsync;
          IF s_trg_unsync = '1' THEN
            sreg <= S2;
          END IF;
        WHEN S2 =>
          s_trg_short <= s_trg_unsync;
          sreg        <= S3;
        WHEN S3 =>
          sreg <= S4;
        WHEN S4 =>
          sreg <= S5;
        WHEN S5 =>
          sreg <= S1;
        WHEN OTHERS =>
          sreg <= S1;
      END CASE;
      
    END IF;
  END PROCESS shorten;


  -- when a valid trigger command is found, synchronize the resulting trigger
  -- to the 40MHz clock with a 3 stage DFF cascade and make the signal
  -- exactly 1 clock wide
  syncit : PROCESS (clock) IS
  BEGIN
    IF rising_edge(clock) THEN
      s_stage1 <= s_trg_short;
      s_stage2 <= s_stage1;
      s_stage3 <= s_stage2;

      s_mstage1 <= s_mstr_rst;
      s_mstage2 <= s_mstage1;
      s_mstage3 <= s_mstage2;
    END IF;
  END PROCESS syncit;

  s_trigger <= s_stage2 AND (NOT s_stage3);

  trigger <= s_trigger;
  evt_trg <= s_trigger AND s_l0like;

  master_rst <= s_mstage2 AND (NOT s_mstage3);


-------------------------------------------------------------------------------
-- Attempt to discover a missing RHICstrobe
-------------------------------------------------------------------------------
  -- count the RHICstrobe edges
  countingEdges : PROCESS (rhic_strobe, edgeRst_n) IS
  BEGIN
    IF edgeRst_n = '0' THEN             -- asynchronous reset (active low)
      edges <= (OTHERS => '0');
      
    ELSIF rising_edge(rhic_strobe) THEN
      edges <= edges + 1;
    END IF;
  END PROCESS;


  -- if no RHICstrobe edges are seen within 8 40MHz clock periods, reset the
  -- latchTrigger state machine
  resetSM : PROCESS (clock, reset_n) IS
  BEGIN
    IF reset_n = '0' THEN               -- asynchronous reset (active low)
      counter          <= 0;
      missing_strobe_n <= '1';
      resetState       <= rss1;
      
    ELSIF rising_edge(clock) THEN
      missing_strobe_n <= '1';
      edgeRst_n        <= '1';
      CASE resetState IS
        WHEN rss1 =>
          counter    <= 0;
          edgeRst_n  <= '0';
          resetState <= rss2;
        WHEN rss2 =>
          counter <= counter + 1;
          IF (counter = 8) THEN
            IF edges = "000" THEN
              resetState <= rss3;
            ELSE
              resetState <= rss1;
            END IF;
          END IF;
        WHEN rss3 =>
          missing_strobe_n <= '0';
          resetState       <= rss1;

        WHEN OTHERS =>
          -- shouldn't happen, just start at beginning
          resetState <= rss1;
      END CASE;
      
    END IF;
  END PROCESS;

END ARCHITECTURE a;

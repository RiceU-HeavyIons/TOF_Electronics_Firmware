-- $Id: smif.vhd,v 1.5 2008-01-21 21:09:36 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : master-serdes-if
-- Project    : SERDES_FPGA
-------------------------------------------------------------------------------
-- File       : smif.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-06-18
-- Last update: 2008-01-21
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: MASTER-SERDES FPGA Interface
-------------------------------------------------------------------------------
-- Copyright (c) 2007
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-06-18  1.0      jschamba        Created
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

ENTITY smif IS
  PORT
    (
      clock       : IN  std_logic;
      dataout_a   : OUT std_logic_vector(11 DOWNTO 0);
      data_type_a : OUT std_logic_vector(3 DOWNTO 0);
      dataout_b   : OUT std_logic_vector(11 DOWNTO 0);
      data_type_b : OUT std_logic_vector(3 DOWNTO 0);
      dataout_c   : OUT std_logic_vector(11 DOWNTO 0);
      data_type_c : OUT std_logic_vector(3 DOWNTO 0);
      dataout_d   : OUT std_logic_vector(11 DOWNTO 0);
      data_type_d : OUT std_logic_vector(3 DOWNTO 0);
      dataout_e   : OUT std_logic_vector(11 DOWNTO 0);
      data_type_e : OUT std_logic_vector(3 DOWNTO 0);
      dataout_f   : OUT std_logic_vector(11 DOWNTO 0);
      data_type_f : OUT std_logic_vector(3 DOWNTO 0);
      dataout_g   : OUT std_logic_vector(11 DOWNTO 0);
      data_type_g : OUT std_logic_vector(3 DOWNTO 0);
      dataout_h   : OUT std_logic_vector(11 DOWNTO 0);
      data_type_h : OUT std_logic_vector(3 DOWNTO 0);
      serdes_reg  : IN  std_logic_vector(7 DOWNTO 0);
      sreg_addr   : IN  std_logic_vector(3 DOWNTO 0);
      sreg_load   : IN  std_logic;
      evt_trg     : IN  std_logic;
      trgtoken    : IN  std_logic_vector(11 DOWNTO 0);
      rstin       : IN  std_logic;
      rstout      : OUT std_logic;
      areset_n    : IN  std_logic
      );
END smif;


ARCHITECTURE a OF smif IS

  TYPE   State_type IS (State0, State1a, State1, State2, State3, State4);
  SIGNAL state : State_type;

  SIGNAL s_dataout_reg   : std_logic_vector (11 DOWNTO 0);
  SIGNAL s_datatype_trig : std_logic_vector(3 DOWNTO 0);
  SIGNAL s_datatype_reg  : std_logic_vector(3 DOWNTO 0);
  SIGNAL s_datatype_br   : std_logic_vector(3 DOWNTO 0);
  SIGNAL s_datatype_rst  : std_logic_vector(3 DOWNTO 0);

  SIGNAL sa_sel : std_logic_vector(1 DOWNTO 0);
  SIGNAL sb_sel : std_logic_vector(1 DOWNTO 0);
  SIGNAL sc_sel : std_logic_vector(1 DOWNTO 0);
  SIGNAL sd_sel : std_logic_vector(1 DOWNTO 0);
  SIGNAL se_sel : std_logic_vector(1 DOWNTO 0);
  SIGNAL sf_sel : std_logic_vector(1 DOWNTO 0);
  SIGNAL sg_sel : std_logic_vector(1 DOWNTO 0);
  SIGNAL sh_sel : std_logic_vector(1 DOWNTO 0);

  SIGNAL is_bunch_reset : std_logic;
  SIGNAL is_reset       : std_logic;
  SIGNAL is_regload     : std_logic;

BEGIN

  s_dataout_reg <= "0000" & serdes_reg;  -- extend SERDES register data to 12bit

  -- Master->Serdes data type
  -- 1. Trigger:
  s_datatype_trig <= "0011" WHEN evt_trg = '1' ELSE
                     "0000";            -- only valid when actual trigger occurs

  -- 2. Bunch reset
  s_datatype_br <= "0101" WHEN is_bunch_reset = '1' ELSE
                   "0000";

  -- 3. SERDES register load only valid during reg_load
  s_datatype_reg <= "1010" WHEN is_regload = '1' ELSE
                    "0000";

  -- 4. Reset
  s_datatype_rst <= "0000";             -- data type 'reset' is not yet implemented

  -- muxes for the "Master <-> Serdes" interface data: 12 bit data & 4 bit data type
  -- Serdes A:
  WITH sa_sel SELECT
    dataout_a <=
    trgtoken       WHEN "00",
    s_dataout_reg  WHEN "01",
    "000000000000" WHEN OTHERS;

  WITH sa_sel SELECT
    data_type_a <=
    s_datatype_trig WHEN "00",
    s_datatype_reg  WHEN "01",
    s_datatype_br   WHEN "10",
    s_datatype_rst  WHEN OTHERS;
  
  -- Serdes B:
  WITH sb_sel SELECT
    dataout_b <=
    trgtoken       WHEN "00",
    s_dataout_reg  WHEN "01",
    "000000000000" WHEN OTHERS;

  WITH sb_sel SELECT
    data_type_b <=
    s_datatype_trig WHEN "00",
    s_datatype_reg  WHEN "01",
    s_datatype_br   WHEN "10",
    s_datatype_rst  WHEN OTHERS;
  
  -- Serdes C:
  WITH sc_sel SELECT
    dataout_c <=
    trgtoken       WHEN "00",
    s_dataout_reg  WHEN "01",
    "000000000000" WHEN OTHERS;

  WITH sc_sel SELECT
    data_type_c <=
    s_datatype_trig WHEN "00",
    s_datatype_reg  WHEN "01",
    s_datatype_br   WHEN "10",
    s_datatype_rst  WHEN OTHERS;
  
  -- Serdes D:
  WITH sd_sel SELECT
    dataout_d <=
    trgtoken       WHEN "00",
    s_dataout_reg  WHEN "01",
    "000000000000" WHEN OTHERS;

  WITH sd_sel SELECT
    data_type_d <=
    s_datatype_trig WHEN "00",
    s_datatype_reg  WHEN "01",
    s_datatype_br   WHEN "10",
    s_datatype_rst  WHEN OTHERS;
  
  -- Serdes E:
  WITH se_sel SELECT
    dataout_e <=
    trgtoken       WHEN "00",
    s_dataout_reg  WHEN "01",
    "000000000000" WHEN OTHERS;

  WITH se_sel SELECT
    data_type_e <=
    s_datatype_trig WHEN "00",
    s_datatype_reg  WHEN "01",
    s_datatype_br   WHEN "10",
    s_datatype_rst  WHEN OTHERS;
  
  -- Serdes F:
  WITH sf_sel SELECT
    dataout_f <=
    trgtoken       WHEN "00",
    s_dataout_reg  WHEN "01",
    "000000000000" WHEN OTHERS;

  WITH sf_sel SELECT
    data_type_f <=
    s_datatype_trig WHEN "00",
    s_datatype_reg  WHEN "01",
    s_datatype_br   WHEN "10",
    s_datatype_rst  WHEN OTHERS;
  
  -- Serdes G:
  WITH sg_sel SELECT
    dataout_g <=
    trgtoken       WHEN "00",
    s_dataout_reg  WHEN "01",
    "000000000000" WHEN OTHERS;

  WITH sg_sel SELECT
    data_type_g <=
    s_datatype_trig WHEN "00",
    s_datatype_reg  WHEN "01",
    s_datatype_br   WHEN "10",
    s_datatype_rst  WHEN OTHERS;
  
  -- Serdes H:
  WITH sh_sel SELECT
    dataout_h <=
    trgtoken       WHEN "00",
    s_dataout_reg  WHEN "01",
    "000000000000" WHEN OTHERS;

  WITH sh_sel SELECT
    data_type_h <=
    s_datatype_trig WHEN "00",
    s_datatype_reg  WHEN "01",
    s_datatype_br   WHEN "10",
    s_datatype_rst  WHEN OTHERS;

  -- Process to control the "Serdes <-> Master" interface line Mux's
  smif_sm : PROCESS (clock, areset_n) IS
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      state  <= State0;
      sa_sel <= "00";                   -- default is "trigger data"
      sb_sel <= "00";
      sc_sel <= "00";
      sd_sel <= "00";
      se_sel <= "00";
      sf_sel <= "00";
      sg_sel <= "00";
      sh_sel <= "00";
      rstout <= '0';                    -- active high

      is_bunch_reset <= '0';
      is_reset       <= '0';
      is_regload     <= '0';
      
    ELSIF clock'event AND clock = '1' THEN  -- leading clock edge
      sa_sel <= "00";                   -- default is "trigger data"
      sb_sel <= "00";
      sc_sel <= "00";
      sd_sel <= "00";
      se_sel <= "00";
      sf_sel <= "00";
      sg_sel <= "00";
      sh_sel <= "00";
      rstout <= '0';                    -- active high

      is_bunch_reset <= '0';
      is_reset       <= '0';
      is_regload     <= '0';

      CASE state IS
        WHEN State0 =>                  -- Trigger happens in this state
          IF (sreg_load = '1') AND (sreg_addr = "1001") THEN
            state <= State2;            -- bunch reset
          ELSIF sreg_load = '1' THEN
            state <= State1a;           -- Serdes register load
          ELSIF rstin = '1' THEN        -- active high
            state <= State2;            -- bunch reset
          END IF;
        WHEN State1a =>                 -- wait a little to let register settle
          IF sreg_addr = "0001" THEN sa_sel    <= "01";
          ELSIF sreg_addr = "0010" THEN sb_sel <= "01";
          ELSIF sreg_addr = "0011" THEN sc_sel <= "01";
          ELSIF sreg_addr = "0100" THEN sd_sel <= "01";
          ELSIF sreg_addr = "0101" THEN se_sel <= "01";
          ELSIF sreg_addr = "0110" THEN sf_sel <= "01";
          ELSIF sreg_addr = "0111" THEN sg_sel <= "01";
          ELSIF sreg_addr = "1000" THEN sh_sel <= "01";
          END IF;

          state <= State1;
        WHEN State1 =>                  -- Serdes register load for registers 1 - 8
          is_regload <= '1';

          IF sreg_addr = "0001" THEN sa_sel    <= "01";
          ELSIF sreg_addr = "0010" THEN sb_sel <= "01";
          ELSIF sreg_addr = "0011" THEN sc_sel <= "01";
          ELSIF sreg_addr = "0100" THEN sd_sel <= "01";
          ELSIF sreg_addr = "0101" THEN se_sel <= "01";
          ELSIF sreg_addr = "0110" THEN sf_sel <= "01";
          ELSIF sreg_addr = "0111" THEN sg_sel <= "01";
          ELSIF sreg_addr = "1000" THEN sh_sel <= "01";
          END IF;

          state <= State4;
        WHEN State2 =>                  -- Bunch reset (register 9)
          is_bunch_reset <= '1';

          sa_sel <= "10";
          sb_sel <= "10";
          sc_sel <= "10";
          sd_sel <= "10";
          se_sel <= "10";
          sf_sel <= "10";
          sg_sel <= "10";
          sh_sel <= "10";

          rstout <= '1';                -- active high

          state <= State3;
        WHEN State3 =>                  -- Bunch reset (continued)
          rstout <= '1';                -- active high

          state <= State4;
        WHEN State4 =>                  -- wait for load and reset to go back to default again
          rstout <= '0';                -- active high
          IF (sreg_load = '0') AND (rstin = '0') THEN
            state <= State0;
          END IF;
        WHEN OTHERS =>                  -- shouldn't happen (invalid state)
          state <= State0;
      END CASE;
    END IF;
    
  END PROCESS smif_sm;
END a;

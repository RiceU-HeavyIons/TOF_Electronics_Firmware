-- $Id: smif.vhd,v 1.2 2007-11-26 22:00:48 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : master-serdes-if
-- Project    : SERDES_FPGA
-------------------------------------------------------------------------------
-- File       : smif.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2007-06-18
-- Last update: 2007-11-12
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

  COMPONENT mux16x4 IS
    PORT (
      data0x : IN  std_logic_vector (15 DOWNTO 0);
      data1x : IN  std_logic_vector (15 DOWNTO 0);
      data2x : IN  std_logic_vector (15 DOWNTO 0);
      data3x : IN  std_logic_vector (15 DOWNTO 0);
      sel    : IN  std_logic_vector (1 DOWNTO 0);
      result : OUT std_logic_vector (15 DOWNTO 0));
  END COMPONENT mux16x4;


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

  s_datatype_trig <= "0011" WHEN evt_trg = '1' ELSE
                     "0000";            -- only valid when actual trigger occurs

  -- bunch reset
  s_datatype_br <= "0101" WHEN is_bunch_reset = '1' ELSE
                   "0000";

  -- SERDES register load only valid during reg_load
  s_datatype_reg <= "1010" WHEN is_regload = '1' ELSE
                    "0000";

  s_datatype_rst <= "0000";             -- data type 'reset' is not yet implemented

  -- muxes for the "Master <-> Serdes" interface data: 12 bit data & 4 bit data type
  muxa_inst : mux16x4
    PORT MAP (
      data0x(15 DOWNTO 12) => s_datatype_trig,
      data0x(11 DOWNTO 0)  => trgtoken,
      data1x(15 DOWNTO 12) => s_datatype_reg,
      data1x(11 DOWNTO 0)  => s_dataout_reg,
      data2x(15 DOWNTO 12) => s_datatype_br,
      data2x(11 DOWNTO 0)  => (OTHERS => '0'),
      data3x(15 DOWNTO 12) => s_datatype_rst,
      data3x(11 DOWNTO 0)  => (OTHERS => '0'),
      sel                  => sa_sel,
      result(15 DOWNTO 12) => data_type_a,
      result(11 DOWNTO 0)  => dataout_a);

  muxb_inst : mux16x4
    PORT MAP (
      data0x(15 DOWNTO 12) => s_datatype_trig,
      data0x(11 DOWNTO 0)  => trgtoken,
      data1x(15 DOWNTO 12) => s_datatype_reg,
      data1x(11 DOWNTO 0)  => s_dataout_reg,
      data2x(15 DOWNTO 12) => s_datatype_br,
      data2x(11 DOWNTO 0)  => (OTHERS => '0'),
      data3x(15 DOWNTO 12) => s_datatype_rst,
      data3x(11 DOWNTO 0)  => (OTHERS => '0'),
      sel                  => sb_sel,
      result(15 DOWNTO 12) => data_type_b,
      result(11 DOWNTO 0)  => dataout_b);

  muxc_inst : mux16x4
    PORT MAP (
      data0x(15 DOWNTO 12) => s_datatype_trig,
      data0x(11 DOWNTO 0)  => trgtoken,
      data1x(15 DOWNTO 12) => s_datatype_reg,
      data1x(11 DOWNTO 0)  => s_dataout_reg,
      data2x(15 DOWNTO 12) => s_datatype_br,
      data2x(11 DOWNTO 0)  => (OTHERS => '0'),
      data3x(15 DOWNTO 12) => s_datatype_rst,
      data3x(11 DOWNTO 0)  => (OTHERS => '0'),
      sel                  => sc_sel,
      result(15 DOWNTO 12) => data_type_c,
      result(11 DOWNTO 0)  => dataout_c);

  muxd_inst : mux16x4
    PORT MAP (
      data0x(15 DOWNTO 12) => s_datatype_trig,
      data0x(11 DOWNTO 0)  => trgtoken,
      data1x(15 DOWNTO 12) => s_datatype_reg,
      data1x(11 DOWNTO 0)  => s_dataout_reg,
      data2x(15 DOWNTO 12) => s_datatype_br,
      data2x(11 DOWNTO 0)  => (OTHERS => '0'),
      data3x(15 DOWNTO 12) => s_datatype_rst,
      data3x(11 DOWNTO 0)  => (OTHERS => '0'),
      sel                  => sd_sel,
      result(15 DOWNTO 12) => data_type_d,
      result(11 DOWNTO 0)  => dataout_d);

  muxe_inst : mux16x4
    PORT MAP (
      data0x(15 DOWNTO 12) => s_datatype_trig,
      data0x(11 DOWNTO 0)  => trgtoken,
      data1x(15 DOWNTO 12) => s_datatype_reg,
      data1x(11 DOWNTO 0)  => s_dataout_reg,
      data2x(15 DOWNTO 12) => s_datatype_br,
      data2x(11 DOWNTO 0)  => (OTHERS => '0'),
      data3x(15 DOWNTO 12) => s_datatype_rst,
      data3x(11 DOWNTO 0)  => (OTHERS => '0'),
      sel                  => se_sel,
      result(15 DOWNTO 12) => data_type_e,
      result(11 DOWNTO 0)  => dataout_e);

  muxf_inst : mux16x4
    PORT MAP (
      data0x(15 DOWNTO 12) => s_datatype_trig,
      data0x(11 DOWNTO 0)  => trgtoken,
      data1x(15 DOWNTO 12) => s_datatype_reg,
      data1x(11 DOWNTO 0)  => s_dataout_reg,
      data2x(15 DOWNTO 12) => s_datatype_br,
      data2x(11 DOWNTO 0)  => (OTHERS => '0'),
      data3x(15 DOWNTO 12) => s_datatype_rst,
      data3x(11 DOWNTO 0)  => (OTHERS => '0'),
      sel                  => sf_sel,
      result(15 DOWNTO 12) => data_type_f,
      result(11 DOWNTO 0)  => dataout_f);

  muxg_inst : mux16x4
    PORT MAP (
      data0x(15 DOWNTO 12) => s_datatype_trig,
      data0x(11 DOWNTO 0)  => trgtoken,
      data1x(15 DOWNTO 12) => s_datatype_reg,
      data1x(11 DOWNTO 0)  => s_dataout_reg,
      data2x(15 DOWNTO 12) => s_datatype_br,
      data2x(11 DOWNTO 0)  => (OTHERS => '0'),
      data3x(15 DOWNTO 12) => s_datatype_rst,
      data3x(11 DOWNTO 0)  => (OTHERS => '0'),
      sel                  => sg_sel,
      result(15 DOWNTO 12) => data_type_g,
      result(11 DOWNTO 0)  => dataout_g);

  muxh_inst : mux16x4
    PORT MAP (
      data0x(15 DOWNTO 12) => s_datatype_trig,
      data0x(11 DOWNTO 0)  => trgtoken,
      data1x(15 DOWNTO 12) => s_datatype_reg,
      data1x(11 DOWNTO 0)  => s_dataout_reg,
      data2x(15 DOWNTO 12) => s_datatype_br,
      data2x(11 DOWNTO 0)  => (OTHERS => '0'),
      data3x(15 DOWNTO 12) => s_datatype_rst,
      data3x(11 DOWNTO 0)  => (OTHERS => '0'),
      sel                  => sh_sel,
      result(15 DOWNTO 12) => data_type_h,
      result(11 DOWNTO 0)  => dataout_h);

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
      rstout <= '1';                    -- active low

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
      rstout <= '1';                    -- active low

      is_bunch_reset <= '0';
      is_reset       <= '0';
      is_regload     <= '0';

      CASE state IS
        WHEN State0 =>
          IF (sreg_load = '1') AND (sreg_addr = "1001") THEN
            state <= State2;
          ELSIF sreg_load = '1' THEN
            state <= State1a;
          ELSIF rstin = '0' THEN        -- active low
            state <= State2;
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

          rstout <= '0';                -- active low

          state <= State3;
        WHEN State3 =>                  -- Bunch reset (continued)
          rstout <= '0';                -- active low

          state <= State4;
        WHEN State4 =>                  -- wait for load and reset to go back to default again
          IF (sreg_load = '0') AND (rstin = '1') THEN
            state <= State0;
          END IF;
        WHEN OTHERS =>                  -- shouldn't happen (invalid state)
          state <= State0;
      END CASE;
    END IF;
    
  END PROCESS smif_sm;
END a;

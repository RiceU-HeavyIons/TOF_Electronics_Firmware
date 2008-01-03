-- $Id: cpld.vhd,v 1.5 2008-01-03 17:41:14 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : CPLD
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cpld.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2005-12-15
-- Last update: 2008-01-03
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top Level Component for the THUB CPLD
-------------------------------------------------------------------------------
-- Copyright (c) 2005 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2005-12-15  1.0      jschamba        Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.my_conversions.ALL;

ENTITY cpld IS
  PORT
    (
      -- clock and reset
      clk                    : IN  std_logic;
      rst_n                  : IN  std_logic;
      -- active serial eprom lines: A - H = 1 - 8 (SERDES FPGAs), M = 0 (Master)
      datao                  : IN  std_logic_vector(8 DOWNTO 0);  -- Active Serial Input
      -- dclk, ncs, asdi        : IN  std_logic_vector(8 DOWNTO 0);  -- Active Serial Outputs
      dclk, ncs, asdi        : OUT std_logic_vector(8 DOWNTO 0);  -- Active Serial Outputs
      -- JTAG lines
      tck_fp, tms_fp, tdi_fp : OUT std_logic;  -- JTAG Ouputs
      tdo_fp                 : IN  std_logic;  -- JTAG Input
      -- buses to micro and master FPGA
      cpld                   : OUT std_logic_vector(9 DOWNTO 0);  -- CPLD/FPGA bus
      uc_cpld                : IN  std_logic_vector(9 DOWNTO 1);  -- CPLD/Micro bus
      uc_cpld0               : OUT std_logic;  -- CPLD/Micro bus
      uc_cpld10              : OUT std_logic;  -- CPLD/Micro bus
      -- switch, button and LEDs
      cpld_sw                : IN  std_logic_vector(3 DOWNTO 0);  -- switch
      cpld_led               : OUT std_logic_vector(3 DOWNTO 0);  -- LEDs
      aux_butn_n             : IN  std_logic;  -- button
      -- PLD configuration pins
      nce, nconfig           : OUT std_logic;  -- PLD configuration pins
      conf_done              : IN  std_logic_vector(8 DOWNTO 0);  -- PLD configuration pins
      nstatus                : IN  std_logic;  -- PLD configuration pins
      nce_2, nconfig_2       : OUT std_logic;  -- PLD configuration pins
      nstatus_2              : IN  std_logic;  -- PLD configuration pins
      crc_error              : IN  std_logic_vector(8 DOWNTO 0)
      );
END cpld;


ARCHITECTURE a OF cpld IS
  
  SIGNAL uc_dclk     : std_logic;
  SIGNAL uc_data     : std_logic;
  SIGNAL uc_asdi     : std_logic;
  SIGNAL uc_ncs      : std_logic;
  SIGNAL uc_nce      : std_logic;
  SIGNAL uc_nconfig  : std_logic;
  SIGNAL as_enable   : std_logic;
  SIGNAL s_dclk      : std_logic_vector (8 DOWNTO 0);
  SIGNAL s_ncs       : std_logic_vector (8 DOWNTO 0);
  SIGNAL s_asdi      : std_logic_vector (8 DOWNTO 0);
  SIGNAL s_nce       : std_logic;
  SIGNAL s_nce_2     : std_logic;
  SIGNAL s_nconfig   : std_logic;
  SIGNAL s_nconfig_2 : std_logic;
  SIGNAL s_ctrClk    : std_logic;
  SIGNAL s_ctrRst    : std_logic;
  SIGNAL uc_tck      : std_logic;
  SIGNAL uc_tdi      : std_logic;
  SIGNAL uc_tms      : std_logic;
  SIGNAL s_crc_error : std_logic;
  SIGNAL count       : integer RANGE 0 TO 9;
  
BEGIN

  -- cpld_led         <= uc_cpld(3 DOWNTO 0); -- route bottom 4 micro signals
  -- cpld_led         <= cpld_sw; -- show the switch position
  -- cpld_led         <= "0101";           -- arbitrary pattern
  cpld_led         <= int2slv(15-count, 4);  -- show the currently selected FPGA
  cpld(3 DOWNTO 0) <= cpld_sw;
  cpld(9 DOWNTO 4) <= (OTHERS => '0');

  -- Micro-CPLD bus signal definitions:
  uc_cpld0   <= uc_data;                -- output
  uc_dclk    <= uc_cpld(1);
  uc_asdi    <= uc_cpld(2);
  uc_ncs     <= uc_cpld(3);
  uc_nce     <= uc_cpld(4);
  uc_nconfig <= uc_cpld(5);
  as_enable  <= uc_cpld(6);
  s_ctrClk   <= uc_cpld(8);
  s_ctrRst   <= uc_cpld(9);
  uc_cpld10  <= s_crc_error;            -- output

  -- counter to select the FPGA to operate ON
  -- increased by pulsing uc_cpld(8) (s_ctrClk)
  -- reset by pulsing uc_cpld(9) (s_ctrRst)
  selCounter : PROCESS (s_ctrClk, s_ctrRst) IS
  BEGIN
    IF s_ctrRst = '1' THEN              -- asynchronous reset (active high)
      count <= 0;
    ELSIF s_ctrClk'event AND s_ctrClk = '1' THEN  -- rising clock edge
      count <= count + 1;
    END IF;
  END PROCESS selCounter;

  -- input signals assigned according to value in "count"
  gen1 : FOR i IN 0 TO 8 GENERATE
    s_dclk(i) <= uc_dclk WHEN count = i ELSE '0';
    s_ncs(i)  <= uc_ncs  WHEN count = i ELSE '1';
    s_asdi(i) <= uc_asdi WHEN count = i ELSE '0';
  END GENERATE gen1;

  -- JTAG signals for count = 9
  uc_tck <= uc_cpld(1) WHEN count = 9 ELSE '0';
  uc_tdi <= uc_cpld(2) WHEN count = 9 ELSE '1';
  uc_tms <= uc_cpld(3) WHEN count = 9 ELSE '1';

  -- output signals
  uc_data     <= tdo_fp WHEN count = 9 ELSE datao(count);
  s_crc_error <= '0' WHEN count = 9    ELSE crc_error(count);

  -- SERDES FPGAs A,B,C,D (1,2,3,4) are on nce and nconfig
  -- SERDES FPGAs E,F,G,H (5,6,7,8) are on nce_2 and nconfig_2
  -- Master FPGA M (0)is on nce and nconfig with A,B,C,D
  s_nce       <= uc_nce     WHEN count < 5 ELSE '0';
  s_nconfig   <= uc_nconfig WHEN count < 5 ELSE '1';
  s_nce_2     <= uc_nce     WHEN count > 4 ELSE '0';
  s_nconfig_2 <= uc_nconfig WHEN count > 4 ELSE '1';

  dclk      <= s_dclk      WHEN as_enable = '1' ELSE (OTHERS => 'Z');
  ncs       <= s_ncs       WHEN as_enable = '1' ELSE (OTHERS => 'Z');
  asdi      <= s_asdi      WHEN as_enable = '1' ELSE (OTHERS => 'Z');
  nce       <= s_nce       WHEN as_enable = '1' ELSE 'Z';
  nconfig   <= s_nconfig   WHEN as_enable = '1' ELSE 'Z';
  nce_2     <= s_nce_2     WHEN as_enable = '1' ELSE 'Z';
  nconfig_2 <= s_nconfig_2 WHEN as_enable = '1' ELSE 'Z';

  -- these function as JTAG signals to the FPGA JTAG chain
  tck_fp <= uc_tck WHEN as_enable = '1' ELSE 'Z';
  tms_fp <= uc_tms WHEN as_enable = '1' ELSE 'Z';
  tdi_fp <= uc_tdi WHEN as_enable = '1' ELSE 'Z';

END a;

-- $Id: cpld.vhd,v 1.1 2006-10-09 18:29:07 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : CPLD
-- Project    : 
-------------------------------------------------------------------------------
-- File       : cpld.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2005-12-15
-- Last update: 2006-10-09
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
      -- active serial eprom lines
      datao                  : IN  std_logic_vector(8 DOWNTO 0);      -- Active Serial Input
      -- dclk, ncs, asdi        : IN  std_logic_vector(8 DOWNTO 0);  -- Active Serial Outputs
      dclk, ncs, asdi        : OUT std_logic_vector(8 DOWNTO 0);      -- Active Serial Outputs
      -- JTAG lines
      tck_fp, tms_fp, tdi_fp : IN  std_logic;                         -- JTAG Ouputs
      tdo_fp                 : IN  std_logic;                         -- JTAG Input
      -- buses to micro and master FPGA
      cpld                   : OUT std_logic_vector(9 DOWNTO 0);      -- CPLD/FPGA bus
      uc_cpld                : IN  std_logic_vector(10 DOWNTO 1);     -- CPLD/Micro bus
      uc_cpld0               : OUT std_logic;                         -- CPLD/Micro bus
      -- switch, button and LEDs
      cpld_sw                : IN  std_logic_vector(3 DOWNTO 0);      -- switch
      cpld_led               : OUT std_logic_vector(3 DOWNTO 0);      -- LEDs
      aux_butn_n             : IN  std_logic;                         -- button
      -- PLD configuration pins
      nce, nconfig           : OUT std_logic;                         -- PLD configuration pins
      conf_done, nstatus     : IN  std_logic;                         -- PLD configuration pins
      nce_2, nconfig_2       : OUT std_logic;                         -- PLD configuration pins
      conf_done_2, nstatus_2 : IN  std_logic;                         -- PLD configuration pins
      -- test pins
      tp                     : IN  std_logic_vector(135 DOWNTO 113);  -- testpoints
      tpu                    : IN  std_logic_vector(173 DOWNTO 169);  -- testpoints
      tph                    : IN  std_logic_vector(317 DOWNTO 315)   -- testpoints
      );
END cpld;


ARCHITECTURE a OF cpld IS
  
  SIGNAL uc_dclk     : std_logic;
  SIGNAL uc_data     : std_logic;
  SIGNAL uc_asdi     : std_logic;
  SIGNAL uc_ncs      : std_logic;
  SIGNAL uc_nce      : std_logic;
  SIGNAL uc_nconfig  : std_logic;
  SIGNAL as_select   : std_logic_vector (2 DOWNTO 0);
  SIGNAL as_enable   : std_logic;
  SIGNAL s_dclk      : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_ncs       : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_asdi      : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_nce       : std_logic;
  SIGNAL s_nce_2     : std_logic;
  SIGNAL s_nconfig   : std_logic;
  SIGNAL s_nconfig_2 : std_logic;
  
BEGIN
  -- route bottom 4 micro signals to LEDs
  -- cpld_led         <= uc_cpld(3 DOWNTO 0);
  -- cpld_led         <= cpld_sw;
  cpld_led         <= "0101";           -- arbitrary pattern
  cpld(3 DOWNTO 0) <= cpld_sw;
  cpld(9 DOWNTO 4) <= (OTHERS => '0');

  uc_cpld0   <= uc_data;
  uc_dclk    <= uc_cpld(1);
  uc_asdi    <= uc_cpld(2);
  uc_ncs     <= uc_cpld(3);
  uc_nce     <= uc_cpld(4);
  uc_nconfig <= uc_cpld(5);
  as_enable  <= uc_cpld(6);
  as_select  <= uc_cpld(10 DOWNTO 8);


  gen1 : FOR i IN 0 TO 7 GENERATE
    s_dclk(i) <= uc_dclk WHEN slv2int(as_select) = i ELSE '0';
    s_ncs(i)  <= uc_ncs  WHEN slv2int(as_select) = i ELSE '1';
    s_asdi(i) <= uc_asdi WHEN slv2int(as_select) = i ELSE '0';
  END GENERATE gen1;

  uc_data <=    datao(0) WHEN slv2int(as_select) = 0 ELSE
                datao(1) WHEN slv2int(as_select) = 1 ELSE
                datao(2) WHEN slv2int(as_select) = 2 ELSE
                datao(3) WHEN slv2int(as_select) = 3 ELSE
                datao(4) WHEN slv2int(as_select) = 4 ELSE
                datao(5) WHEN slv2int(as_select) = 5 ELSE
                datao(6) WHEN slv2int(as_select) = 6 ELSE
                datao(7);

  s_nce       <= uc_nce     WHEN as_select(2) = '0' ELSE '0';
  s_nconfig   <= uc_nconfig WHEN as_select(2) = '0' ELSE '1';
  s_nce_2     <= uc_nce     WHEN as_select(2) = '1' ELSE '0';
  s_nconfig_2 <= uc_nconfig WHEN as_select(2) = '1' ELSE '1';

  dclk(7 DOWNTO 0) <= s_dclk      WHEN as_enable = '1' ELSE (OTHERS => 'Z');
  ncs(7 DOWNTO 0)  <= s_ncs       WHEN as_enable = '1' ELSE (OTHERS => 'Z');
  asdi(7 DOWNTO 0) <= s_asdi      WHEN as_enable = '1' ELSE (OTHERS => 'Z');
  nce              <= s_nce       WHEN as_enable = '1' ELSE 'Z';
  nconfig          <= s_nconfig   WHEN as_enable = '1' ELSE 'Z';
  nce_2            <= s_nce_2     WHEN as_enable = '1' ELSE 'Z';
  nconfig_2        <= s_nconfig_2 WHEN as_enable = '1' ELSE 'Z';

  dclk(8) <= 'Z';
  ncs(8)  <= 'Z';
  asdi(8) <= 'Z';
  
END a;

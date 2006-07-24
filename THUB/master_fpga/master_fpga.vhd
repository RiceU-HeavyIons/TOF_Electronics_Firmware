-- $Id: master_fpga.vhd,v 1.1 2006-07-24 22:19:44 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : MASTER_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : master_fpga.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2005-12-22
-- Last update: 2006-07-07
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top Level Component for the THUB MASTER FPGAs
-------------------------------------------------------------------------------
-- Copyright (c) 2005 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2005-12-22  1.0      jschamba        Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY altera;
USE altera.maxplus2.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;


ENTITY master_fpga IS
  PORT
    (
      clk            : IN    std_logic;                      -- Master clock
      -- Mictor outputs
      mic            : OUT   std_logic_vector(64 DOWNTO 0);
      -- bus to serdes fpga's
      ma, mb, mc, md : IN    std_logic_vector(35 DOWNTO 0);
      me, mf, mg, mh : IN    std_logic_vector(35 DOWNTO 0);
      m_all          : OUT   std_logic_vector(3 DOWNTO 0);
      -- CPLD and Micro connections
      cpld           : IN    std_logic_vector(9 DOWNTO 0);   -- CPLD/FPGA bus
      uc_fpga_hi     : IN    std_logic_vector(10 DOWNTO 8);  -- FPGA/Micro bus
      uc_fpga_lo     : INOUT std_logic_vector(7 DOWNTO 0);   -- FPGA/Micro bus
      -- Buttons & LEDs
      butn           : IN    std_logic_vector(2 DOWNTO 0);   -- buttons
      led            : OUT   std_logic_vector(1 DOWNTO 0);   -- LEDs
      -- TCD
      tcd_d          : IN    std_logic_vector(3 DOWNTO 0);
      tcd_busy_p     : OUT   std_logic;
      tcd_strb       : IN    std_logic;                      -- RHIC strobe
      tcd_clk        : IN    std_logic;                      -- RHIC Data Clock
      -- SIU
      fbctrl_n       : INOUT std_logic;                      -- INOUT std_logic;
      fbten_n        : INOUT std_logic;                      -- INOUT std_logic;
      fidir          : IN    std_logic;
      fiben_n        : IN    std_logic;
      filf_n         : IN    std_logic;
      fobsy_n        : OUT   std_logic;
      foclk          : OUT   std_logic;
      fbd            : INOUT std_logic_vector(31 DOWNTO 0);  -- INOUT std_logic_vector(31 DOWNTO 0)
      -- Resets
      rstin          : IN    std_logic;
      rstout         : OUT   std_logic

      );
END master_fpga;


ARCHITECTURE a OF master_fpga IS

  COMPONENT control_registers IS
    PORT (
      clock    : IN  std_logic;
      arstn    : IN  std_logic;
      reg_data : IN  std_logic_vector (7 DOWNTO 0);
      reg_addr : IN  std_logic_vector (2 DOWNTO 0);
      reg_load : IN  std_logic;
      reg1_out : OUT std_logic_vector (7 DOWNTO 0);
      reg2_out : OUT std_logic_vector (7 DOWNTO 0);
      reg3_out : OUT std_logic_vector (7 DOWNTO 0);
      reg4_out : OUT std_logic_vector (7 DOWNTO 0);
      reg5_out : OUT std_logic_vector (7 DOWNTO 0)
      );
  END COMPONENT control_registers;

  COMPONENT uc_fpga_interface IS
    PORT (
      clock       : IN  std_logic;
      arstn       : IN  std_logic;
      dir         : IN  std_logic;
      ctl         : IN  std_logic;
      ds          : IN  std_logic;
      uc_data_in  : IN  std_logic_vector(7 DOWNTO 0);
      reg1        : IN  std_logic_vector(7 DOWNTO 0);
      reg2        : IN  std_logic_vector(7 DOWNTO 0);
      reg3        : IN  std_logic_vector(7 DOWNTO 0);
      reg4        : IN  std_logic_vector(7 DOWNTO 0);
      reg5        : IN  std_logic_vector(7 DOWNTO 0);
      reg_addr    : OUT std_logic_vector(2 DOWNTO 0);
      reg_load    : OUT std_logic;
      uc_data_out : OUT std_logic_vector(7 DOWNTO 0)
      );
  END COMPONENT uc_fpga_interface;

  SIGNAL globalclk : std_logic;
  SIGNAL arstn     : std_logic;

  -- ********************************************************************************
  -- DDL bidir signals separated into IN and OUT (JS)
  -- ********************************************************************************
  SIGNAL s_fiD      : std_logic_vector (31 DOWNTO 0);  -- corresponds to ddl_fbd (IN)
  SIGNAL s_foD      : std_logic_vector (31 DOWNTO 0);  -- corresponds to ddl_fbd (OUT)
  SIGNAL s_fiTEN_N  : std_logic;                       -- corresponds to ddl_fbten_N (IN)
  SIGNAL s_foTEN_N  : std_logic;                       -- corresponds to ddl_fbten_N (OUT)
  SIGNAL s_fiCTRL_N : std_logic;                       -- corresponds to ddl_fbctrl_N (IN)
  SIGNAL s_foCTRL_N : std_logic;                       -- corresponds to ddl_fbctrl_N (OUT)

  -- ********************************************************************************
  -- uc_fpga signals
  -- ********************************************************************************
  SIGNAL s_ucDIR    : std_logic;
  SIGNAL s_ucCTL    : std_logic;
  SIGNAL s_ucDS     : std_logic;
  SIGNAL s_uc_o     : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_uc_i     : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg_addr : std_logic_vector(2 DOWNTO 0);
  SIGNAL s_reg_load : std_logic;
  SIGNAL s_reg1     : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg2     : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg3     : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg4     : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg5     : std_logic_vector(7 DOWNTO 0);

BEGIN

  global_clk_buffer : global PORT MAP (a_in => clk, a_out => globalclk);

  arstn <= '1';                         -- no reset for now

  -- LEDs
  led <= "00";

  -- bus to SERDES FPGA is driven by CPLD
  m_all <= cpld(3 DOWNTO 0);

  -- Mictor defaults
  -- this one for the TCD:
  -- mic( 3 DOWNTO  0) <= tcd_d;
  -- mic( 4)           <= tcd_clk;
  -- mic( 5)           <= tcd_strb;
  -- mic( 7 DOWNTO  6) <= s_fiD( 7 DOWNTO  6);

  -- and this one for the DDL:
  mic(7 DOWNTO 0) <= s_fiD(7 DOWNTO 0);

  --  mic( 7 DOWNTO  0) <= s_fiD( 7 DOWNTO  0);
  mic(8)            <= '0';
  mic(9)            <= s_fiTEN_N;
  mic(10)           <= s_fiCTRL_N;
  mic(11)           <= fiDIR;
  mic(12)           <= fiBEN_N;
  mic(14 DOWNTO 13) <= (OTHERS => '0');
  mic(15)           <= globalclk;
  mic(31 DOWNTO 16) <= (OTHERS => '0');
  -- mic(47 DOWNTO 32) <= s_fiD(27 DOWNTO 12);
  -- mic(63 DOWNTO 48) <= (OTHERS => '0');
  mic(63 DOWNTO 50) <= (OTHERS => '0');

  mic(49)           <= ma(19);
  mic(48)           <= ma(18);
  mic(47 DOWNTO 32) <= ma(15 DOWNTO 0);

  -- mic(63 DOWNTO  0) <= (OTHERS => '0');
  mic(64) <= clk;

  -- Other defaults

  tcd_busy_p <= '0';
  rstout     <= '0';

  -- ********************************************************************************
  -- ddl_interface defaults
  -- ********************************************************************************

  -- detector data link interface signals
  fobsy_n    <= '1';
  foclk      <= globalclk;
  s_fiTEN_N  <= fbten_n;
  s_fiCTRL_N <= fbctrl_n;
  s_fiD      <= fbd;

  s_foTEN_N  <= '1';
  s_foCTRL_N <= '1';
  s_foD      <= (OTHERS => '0');

  ddlbus : PROCESS (fiben_n, fidir, s_foTEN_N, s_foCTRL_N, fbd, s_foD)
  BEGIN
    IF (fiben_n = '1') OR (fidir = '0') THEN
      fbten_n  <= 'Z';
      fbctrl_n <= 'Z';
      fbd      <= (OTHERS => 'Z');
    ELSE
      fbten_n  <= s_foTEN_N;
      fbctrl_n <= s_foCTRL_N;
      fbd      <= s_foD;
    END IF;
  END PROCESS;

  -- ********************************************************************************
  -- micro interface defaults
  -- ********************************************************************************
  s_ucDIR <= uc_fpga_hi(10);
  s_ucCTL <= uc_fpga_hi(9);
  s_ucDS  <= uc_fpga_hi(8);
  s_uc_i  <= uc_fpga_lo;

  uc_bus : PROCESS (s_ucDIR) IS
  BEGIN  -- PROCESS uc_bus
    IF (s_ucDIR = '1') THEN
      uc_fpga_lo <= (OTHERS => 'Z');
    ELSE
      uc_fpga_lo <= s_uc_o;
    END IF;
  END PROCESS uc_bus;

  control_reg_inst : control_registers
    PORT MAP (
      clock    => globalclk,
      arstn    => arstn,
      reg_data => s_uc_i,
      reg_addr => s_reg_addr,
      reg_load => s_reg_load,
      reg1_out => s_reg1,
      reg2_out => s_reg2,
      reg3_out => s_reg3,
      reg4_out => s_reg4,
      reg5_out => s_reg5);

  uc_fpga_inst : uc_fpga_interface
    PORT MAP (
      clock       => globalclk,
      arstn       => arstn,
      dir         => s_ucDIR,
      ctl         => s_ucCTL,
      ds          => s_ucDS,
      uc_data_in  => s_uc_i,
      reg1        => s_reg1,
      reg2        => s_reg2,
      reg3        => s_reg3,
      reg4        => s_reg4,
      reg5        => s_reg5,
      reg_addr    => s_reg_addr,
      reg_load    => s_reg_load,
      uc_data_out => s_uc_o);


END a;

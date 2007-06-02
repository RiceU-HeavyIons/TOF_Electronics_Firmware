-- $Id: master_fpga.vhd,v 1.8 2007-06-02 19:06:04 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : MASTER_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : master_fpga.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2005-12-22
-- Last update: 2007-05-14
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
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera_mf; 
USE altera_mf.altera_mf_components.all; 
LIBRARY altera;
USE altera.altera_primitives_components.ALL;


ENTITY master_fpga IS
  PORT
    (
      clk        : IN    std_logic;     -- Master clock
      -- Mictor outputs
      mic        : OUT   std_logic_vector(64 DOWNTO 0);
      -- bus to serdes fpga's
      ma         : INOUT std_logic_vector(35 DOWNTO 0);
      mb, mc, md : INOUT std_logic_vector(35 DOWNTO 0);
      mf, mg, mh : INOUT std_logic_vector(35 DOWNTO 0);
      me         : INOUT std_logic_vector(35 DOWNTO 0);
      m_all      : OUT   std_logic_vector(3 DOWNTO 0);
      -- CPLD and Micro connections
      cpld       : IN    std_logic_vector(9 DOWNTO 0);   -- CPLD/FPGA bus
      uc_fpga_hi : IN    std_logic_vector(10 DOWNTO 8);  -- FPGA/Micro bus
      uc_fpga_lo : INOUT std_logic_vector(7 DOWNTO 0);   -- FPGA/Micro bus
      -- Buttons & LEDs
      butn       : IN    std_logic_vector(2 DOWNTO 0);   -- buttons
      led        : OUT   std_logic_vector(1 DOWNTO 0);   -- LEDs
      -- TCD
      tcd_d      : IN    std_logic_vector(3 DOWNTO 0);
      tcd_busy_p : OUT   std_logic;
      tcd_strb   : IN    std_logic;     -- RHIC strobe
      tcd_clk    : IN    std_logic;     -- RHIC Data Clock
      -- SIU
      fbctrl_n   : INOUT std_logic;     -- INOUT std_logic;
      fbten_n    : INOUT std_logic;     -- INOUT std_logic;
      fidir      : IN    std_logic;
      fiben_n    : IN    std_logic;
      filf_n     : IN    std_logic;
      fobsy_n    : OUT   std_logic;
      foclk      : OUT   std_logic;
      fbd        : INOUT std_logic_vector(31 DOWNTO 0);  -- INOUT std_logic_vector(31 DOWNTO 0)
      -- Resets
      rstin      : IN    std_logic;
      rstout     : OUT   std_logic

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
      reg6        : IN  std_logic_vector(7 DOWNTO 0);
      reg7        : IN  std_logic_vector(7 DOWNTO 0);
      reg8        : IN  std_logic_vector(7 DOWNTO 0);
      reg_addr    : OUT std_logic_vector(2 DOWNTO 0);
      reg_clr     : OUT std_logic;
      reg_load    : OUT std_logic;
      uc_data_out : OUT std_logic_vector(7 DOWNTO 0)
      );
  END COMPONENT uc_fpga_interface;

  COMPONENT tcd IS
    PORT (
      rhic_strobe : IN  std_logic;
      data_strobe : IN  std_logic;
      data        : IN  std_logic_vector (3 DOWNTO 0);
      clock       : IN  std_logic;
      trgword     : OUT std_logic_vector (19 DOWNTO 0);
      trigger     : OUT std_logic;
      evt_trg     : OUT std_logic
      );
  END COMPONENT tcd;

  COMPONENT ddl IS
    PORT (
      reset      : IN  std_logic;
      fiCLK      : IN  std_logic;
      fiTEN_N    : IN  std_logic;
      fiDIR      : IN  std_logic;
      fiBEN_N    : IN  std_logic;
      fiLF_N     : IN  std_logic;
      fiCTRL_N   : IN  std_logic;
      fiD        : IN  std_logic_vector(31 DOWNTO 0);
      fifo_q     : IN  std_logic_vector(31 DOWNTO 0);  -- interface fifo data output port
      fifo_empty : IN  std_logic;       -- interface fifo "emtpy" signal
      ext_trg    : IN  std_logic;       -- external trigger
      run_reset  : OUT std_logic;       -- reset external logic at Run Start
      foD        : OUT std_logic_vector(31 DOWNTO 0);
      foBSY_N    : OUT std_logic;
      foCTRL_N   : OUT std_logic;
      foTEN_N    : OUT std_logic;
      fifo_rdreq : OUT std_logic        -- interface fifo read request
      );
  END COMPONENT ddl;

  SIGNAL globalclk : std_logic;
  SIGNAL arstn     : std_logic;

  -- ********************************************************************************
  -- DDL bidir signals separated into IN and OUT (JS)
  -- ********************************************************************************
  SIGNAL s_fiD      : std_logic_vector (31 DOWNTO 0);  -- corresponds to ddl_fbd (IN)
  SIGNAL s_foD      : std_logic_vector (31 DOWNTO 0);  -- corresponds to ddl_fbd (OUT)
  SIGNAL s_fiTEN_N  : std_logic;        -- corresponds to ddl_fbten_N (IN)
  SIGNAL s_foTEN_N  : std_logic;        -- corresponds to ddl_fbten_N (OUT)
  SIGNAL s_fiCTRL_N : std_logic;        -- corresponds to ddl_fbctrl_N (IN)
  SIGNAL s_foCTRL_N : std_logic;        -- corresponds to ddl_fbctrl_N (OUT)

  -- ********************************************************************************
  -- uc_fpga signals
  -- ********************************************************************************
  SIGNAL s_ucDIR         : std_logic;
  SIGNAL s_ucCTL         : std_logic;
  SIGNAL s_ucDS          : std_logic;
  SIGNAL s_uc_o          : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_uc_i          : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg_addr      : std_logic_vector(2 DOWNTO 0);
  SIGNAL s_reg_load      : std_logic;
  SIGNAL s_reg_clr       : std_logic;
  SIGNAL s_reg1          : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg2          : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg3          : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg4          : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg5          : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg6          : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg7          : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg8          : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_trigger       : std_logic;
  SIGNAL s_evt_trg       : std_logic;
  SIGNAL s_runReset      : std_logic;
  SIGNAL ddl_data        : std_logic_vector (31 DOWNTO 0);
  SIGNAL ddlfifo_empty   : std_logic;
  SIGNAL rd_ddl_fifo     : std_logic;
  SIGNAL s_triggerword   : std_logic_vector(19 DOWNTO 0);
  SIGNAL s_trgfifo_empty : std_logic;
  SIGNAL s_trgfifo_q     : std_logic_vector(19 DOWNTO 0);
  SIGNAL s_trg_mcu_word  : std_logic_vector (19 DOWNTO 0);

BEGIN

  global_clk_buffer : global PORT MAP (a_in => clk, a_out => globalclk);

  arstn <= '1';                         -- no reset for now

  -- LEDs
  led <= "00";

  -- SERDES FPGA interfaces:
  mb <= (OTHERS => 'Z');
  mc <= (OTHERS => 'Z');
  md <= (OTHERS => 'Z');
  me <= (OTHERS => 'Z');
  mf <= (OTHERS => 'Z');
  mg <= (OTHERS => 'Z');
  mh <= (OTHERS => 'Z');

  -- bus to SERDES FPGA is driven by CPLD
  m_all <= cpld(3 DOWNTO 0);

  -- Mictor defaults

  -- mic(0) <= s_ucDIR;
  -- mic(1) <= s_ucCTL;
  -- mic(2) <= s_ucDS;
  -- mic(3) <= s_reg_load;
  -- mic(4) <= s_reg_clr;
  -- mic(7 DOWNTO 5) <= s_reg_addr;
  -- mic(15 DOWNTO 8) <= s_uc_i;
  -- mic(15 DOWNTO 8) <= (OTHERS => '0');

  -- this one for the TCD:
  -- mic( 3 DOWNTO  0) <= tcd_d;
  -- mic( 4)           <= tcd_clk;
  -- mic( 5)           <= tcd_strb;
  -- mic( 7 DOWNTO  6) <= s_fiD( 7 DOWNTO  6);

  -- and this one for the DDL:
--  mic(7 DOWNTO 0) <= s_fiD(7 DOWNTO 0);

--  mic(0)          <= tcd_strb;
--  mic(1)          <= tcd_clk;
--  mic(5 DOWNTO 2) <= tcd_d;
--  mic(7 DOWNTO 6) <= "00";

--  mic(8)            <= '0';
--  mic(9)            <= s_fiTEN_N;
--  mic(10)           <= s_fiCTRL_N;
--  mic(11)           <= fiDIR;
--  mic(12)           <= fiBEN_N;
--  mic(14 DOWNTO 13) <= (OTHERS => '0');
--  mic(15)           <= globalclk;
-- mic(63 DOWNTO 16) <= (OTHERS => '0');
--  mic(47 DOWNTO 32) <= s_fiD(27 DOWNTO 12);
--  mic(63 DOWNTO 48) <= (OTHERS => '0');
--  mic(31 DOWNTO 16) <= (OTHERS => '0');
  -- mic(63 DOWNTO  0) <= (OTHERS => '0');

  mic(64) <= clk;

  -- Other defaults

  tcd_busy_p <= '0';
  rstout     <= '0';

  -- ********************************************************************************
  -- ddl_interface defaults
  -- ********************************************************************************

  -- detector data link interface signals
  foclk      <= globalclk;
  s_fiTEN_N  <= fbten_n;
  s_fiCTRL_N <= fbctrl_n;
  s_fiD      <= fbd;

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

  -- unused for now:
  ddl_data      <= (OTHERS => '0');
  ddlfifo_empty <= '1';
  
  ddl_inst : ddl PORT MAP (             -- DDL
    fiD        => s_fiD,
    foD        => s_foD,
    foBSY_N    => fobsy_n,
    fiCLK      => globalclk,
    fiDIR      => fidir,
    fiBEN_N    => fiben_n,
    fiLF_N     => filf_n,
    fiCTRL_N   => s_fiCTRL_N,
    foCTRL_N   => s_foCTRL_N,
    fiTEN_N    => s_fiTEN_N,
    foTEN_N    => s_foTEN_N,
    ext_trg    => '0',                  -- external trigger (for testing)
    run_reset  => s_runReset,           -- external logic reset at run start
    reset      => '0',                  -- reset,
    fifo_q     => ddl_data,
    fifo_empty => ddlfifo_empty,
    fifo_rdreq => rd_ddl_fifo
    );

  -- ********************************************************************************
  -- micro interface defaults
  -- ********************************************************************************
  s_ucDIR <= uc_fpga_hi(10);
  s_ucCTL <= uc_fpga_hi(9);
  s_ucDS  <= uc_fpga_hi(8);
  s_uc_i  <= uc_fpga_lo;

  uc_bus : PROCESS (s_ucDIR, s_uc_o) IS
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
      reg6        => s_reg6,
      reg7        => s_reg7,
      reg8        => s_reg8,
      reg_addr    => s_reg_addr,
      reg_load    => s_reg_load,
      reg_clr     => s_reg_clr,
      uc_data_out => s_uc_o);

  -- ********************************************************************************
  -- TCD interface
  -- ********************************************************************************
  tcd_inst : tcd
    PORT MAP (
      rhic_strobe => tcd_strb,
      data_strobe => tcd_clk,
      data        => tcd_d,
      clock       => globalclk,
      trgword     => s_triggerword,
      trigger     => s_trigger,
      evt_trg     => s_evt_trg);

  -- display trigger word on Mictor
  mic(19 DOWNTO 0)  <= s_triggerword;
  mic(20)           <= s_trigger;
  mic(21)           <= s_evt_trg;
  mic(63 DOWNTO 22) <= (OTHERS => '0');

  -- store the TCD info in a dual clock FIFO for later retrieval.
  -- s_trigger is high when a valid trigger is received, so USE
  -- it as the write request.
  -- s_reg_clr advances the FIFO to the next word on the read port.
  dcfifo_inst : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_numwords           => 256,
      lpm_showahead          => "ON",
      lpm_type               => "dcfifo",
      lpm_width              => 20,
      lpm_widthu             => 8,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 4,
      underflow_checking     => "ON",
      use_eab                => "ON",
      wrsync_delaypipe       => 4
      )
    PORT MAP (
      wrclk   => globalclk,
      wrreq   => s_trigger,
      rdclk   => s_reg_clr,
      rdreq   => '1',
      data    => s_triggerword,
      rdempty => s_trgfifo_empty,
      q       => s_trgfifo_q
      );

  s_trg_mcu_word <= (OTHERS => '0') WHEN (s_trgfifo_empty = '1') ELSE s_trgfifo_q;

  s_reg8 (7 DOWNTO 4) <= "0000";
  s_reg8 (3 DOWNTO 0) <= s_trg_mcu_word(19 DOWNTO 16);
  s_reg7              <= s_trg_mcu_word(15 DOWNTO 8);
  s_reg6              <= s_trg_mcu_word(7 DOWNTO 0);

  -- registers 1 through 5 are presented to SERDES FPGA A:
--  ma(7 DOWNTO 0)   <= s_reg1;
--  ma(15 DOWNTO 8)  <= s_reg2;
--  ma(23 DOWNTO 16) <= s_reg3;
--  ma(31 DOWNTO 24) <= s_reg4;
--  ma(35 DOWNTO 32) <= s_reg5(3 DOWNTO 0);

  ma <= (OTHERS => 'Z');

END a;

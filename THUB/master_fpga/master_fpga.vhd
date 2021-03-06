-- $Id$
-------------------------------------------------------------------------------
-- Title      : MASTER_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : master_fpga.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2005-12-22
-- Last update: 2013-03-07
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
USE ieee.std_logic_unsigned.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
LIBRARY altera;
USE altera.altera_primitives_components.ALL;


ENTITY master_fpga IS
  PORT
    (
      clk           : IN    std_logic;  -- Master clock
      -- Mictor outputs
      mic           : OUT   std_logic_vector(28 DOWNTO 0);
      -- bus to serdes fpga's
      maI, mbI, mcI : IN    std_logic_vector(16 DOWNTO 0);
      mdI, meI, mfI : IN    std_logic_vector(16 DOWNTO 0);
      mgI, mhI      : IN    std_logic_vector(16 DOWNTO 0);
      maO, mbO, mcO : OUT   std_logic_vector(35 DOWNTO 17);
      mdO, meO, mfO : OUT   std_logic_vector(35 DOWNTO 17);
      mgO, mhO      : OUT   std_logic_vector(35 DOWNTO 17);
      m_all         : OUT   std_logic_vector(3 DOWNTO 0);
      -- CPLD and Micro connections
      cpld          : IN    std_logic_vector(9 DOWNTO 0);  -- CPLD/FPGA bus (0-3 = dip-switches)
      uc_fpga_hi    : IN    std_logic_vector(10 DOWNTO 8);  -- FPGA/Micro bus
      uc_fpga_lo    : INOUT std_logic_vector(7 DOWNTO 0);  -- FPGA/Micro bus
      -- Buttons & LEDs
      butn          : IN    std_logic_vector(1 DOWNTO 0);  -- buttons
      led           : OUT   std_logic_vector(1 DOWNTO 0);  -- LEDs
      -- TCD
      tcd_d         : IN    std_logic_vector(3 DOWNTO 0);
      tcd_busy_p    : OUT   std_logic;
      tcd_strb      : IN    std_logic;  -- RHIC strobe
      tcd_clk       : IN    std_logic;  -- RHIC Data Clock
      -- SIU
      fbctrl_n      : INOUT std_logic;
      fbten_n       : INOUT std_logic;
      fidir         : IN    std_logic;
      fiben_n       : IN    std_logic;
      filf_n        : IN    std_logic;
      fobsy_n       : OUT   std_logic;
      foclk         : OUT   std_logic;
      fbd           : INOUT std_logic_vector(31 DOWNTO 0);
      -- Level-2 SIU
      l2_fbctrl_n   : INOUT std_logic;
      l2_fbten_n    : INOUT std_logic;
      l2_fidir      : IN    std_logic;
      l2_fiben_n    : IN    std_logic;
      l2_filf_n     : IN    std_logic;
      l2_fobsy_n    : OUT   std_logic;
      l2_foclk      : OUT   std_logic;
      l2_fbd        : INOUT std_logic_vector(31 DOWNTO 0);
      -- Resets
      rstin         : IN    std_logic;
      rstout        : OUT   std_logic

      );
END master_fpga;


ARCHITECTURE a OF master_fpga IS

  COMPONENT pll
    PORT (
      inclk0 : IN  std_logic := '0';
      c0     : OUT std_logic;
      c1     : OUT std_logic;
      c2     : OUT std_logic;
      locked : OUT std_logic
      );
  END COMPONENT;

  COMPONENT serdes_registers IS
    PORT (
      clock    : IN  std_logic;
      arstn    : IN  std_logic;
      reg_data : IN  std_logic_vector (7 DOWNTO 0);
      reg_addr : IN  std_logic_vector (3 DOWNTO 0);
      reg_load : IN  std_logic;
      reg_out  : OUT std_logic_vector (7 DOWNTO 0));
  END COMPONENT serdes_registers;

  COMPONENT control_registers IS
    PORT (
      clock    : IN  std_logic;
      arstn    : IN  std_logic;
      reg_data : IN  std_logic_vector (7 DOWNTO 0);
      reg_addr : IN  std_logic_vector (2 DOWNTO 0);
      reg_load : IN  std_logic;
      reg0_out : OUT std_logic_vector (7 DOWNTO 0);
      reg1_out : OUT std_logic_vector (7 DOWNTO 0);
      reg2_out : OUT std_logic_vector (7 DOWNTO 0);
      reg3_out : OUT std_logic_vector (7 DOWNTO 0);
      reg4_out : OUT std_logic_vector (7 DOWNTO 0)
      );
  END COMPONENT control_registers;

  COMPONENT uc_fpga_interface IS
    PORT (
      clock         : IN  std_logic;
      arstn         : IN  std_logic;
      dir           : IN  std_logic;
      ctl           : IN  std_logic;
      ds            : IN  std_logic;
      uc_data_in    : IN  std_logic_vector(7 DOWNTO 0);
      reg0          : IN  std_logic_vector(7 DOWNTO 0);
      reg1          : IN  std_logic_vector(7 DOWNTO 0);
      reg2          : IN  std_logic_vector(7 DOWNTO 0);
      reg3          : IN  std_logic_vector(7 DOWNTO 0);
      reg4          : IN  std_logic_vector(7 DOWNTO 0);
      reg5          : IN  std_logic_vector(7 DOWNTO 0);
      reg6          : IN  std_logic_vector(7 DOWNTO 0);
      reg7          : IN  std_logic_vector(7 DOWNTO 0);
      alert_data    : IN  std_logic_vector(7 DOWNTO 0);
      alert_latch   : IN  std_logic;
      serdes_reg    : IN  std_logic_vector(7 DOWNTO 0);
      serdes_statma : IN  std_logic_vector(3 DOWNTO 0);
      serdes_statmb : IN  std_logic_vector(3 DOWNTO 0);
      serdes_statmc : IN  std_logic_vector(3 DOWNTO 0);
      serdes_statmd : IN  std_logic_vector(3 DOWNTO 0);
      serdes_statme : IN  std_logic_vector(3 DOWNTO 0);
      serdes_statmf : IN  std_logic_vector(3 DOWNTO 0);
      serdes_statmg : IN  std_logic_vector(3 DOWNTO 0);
      serdes_statmh : IN  std_logic_vector(3 DOWNTO 0);
      reg_addr      : OUT std_logic_vector(2 DOWNTO 0);
      sreg_addr     : OUT std_logic_vector(3 DOWNTO 0);
      reg_load      : OUT std_logic;
      sreg_load     : OUT std_logic;
      reg_clr       : OUT std_logic;
      uc_data_out   : OUT std_logic_vector(7 DOWNTO 0)
      );
  END COMPONENT uc_fpga_interface;

  COMPONENT tcd IS
    PORT (
      rhic_strobe : IN  std_logic;
      data_strobe : IN  std_logic;
      data        : IN  std_logic_vector (3 DOWNTO 0);
      clock       : IN  std_logic;
      reset_n     : IN  std_logic;
      working     : OUT std_logic;
      trgword     : OUT std_logic_vector (19 DOWNTO 0);
      master_rst  : OUT std_logic;
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
      special_wr : OUT std_logic;  -- FECTRL with "special" parameter "0xabc0"
      event_read : OUT std_logic;
      foD        : OUT std_logic_vector(31 DOWNTO 0);
      foBSY_N    : OUT std_logic;
      foCTRL_N   : OUT std_logic;
      foTEN_N    : OUT std_logic;
      fifo_rdreq : OUT std_logic        -- interface fifo read request
      );
  END COMPONENT ddl;

  COMPONENT smif IS
    PORT (
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
  END COMPONENT smif;

  COMPONENT serdes_reader IS
    PORT (
      clk80mhz            : IN  std_logic;
      areset_n            : IN  std_logic;
      sync_q              : IN  std_logic_vector(31 DOWNTO 0);
      sync_latch          : IN  std_logic;
      ser_status          : IN  std_logic_vector (3 DOWNTO 0);
      fifo_empty          : IN  std_logic;
      outfifo_almost_full : IN  std_logic;
      evt_trg             : IN  std_logic;
      triggerWord         : IN  std_logic_vector (19 DOWNTO 0);
      trgFifo_empty       : IN  std_logic;
      trgFifo_q           : IN  std_logic_vector (19 DOWNTO 0);
      clk_10mhz           : IN  std_logic;
      serSel              : OUT std_logic_vector (2 DOWNTO 0);
      trgFifo_rdreq       : OUT std_logic;
      busy_n              : OUT std_logic;
      rdsel_out           : OUT std_logic_vector (1 DOWNTO 0);
      rdreq_out           : OUT std_logic;
      l2_wrreq_out        : OUT std_logic;
      l2_outdata          : OUT std_logic_vector (31 DOWNTO 0);
      wrreq_out           : OUT std_logic;
      outdata             : OUT std_logic_vector (31 DOWNTO 0)
      );
  END COMPONENT serdes_reader;

  COMPONENT synchronizer IS
    PORT (
      clk80mhz      : IN  std_logic;
      areset_n      : IN  std_logic;
      serdes_indata : IN  std_logic_vector (7 DOWNTO 0);
      serdes_clk    : IN  std_logic;
      serdes_strb   : IN  std_logic;
      sync_latch    : OUT std_logic;
      sync_q        : OUT std_logic_vector (31 DOWNTO 0)
      );
  END COMPONENT synchronizer;

  COMPONENT serdesRdDecoder IS
    PORT (
      clk    : IN  std_logic;
      rdSel  : IN  std_logic_vector (1 DOWNTO 0);
      rdreq  : IN  std_logic;
      adr    : IN  std_logic_vector(2 DOWNTO 0);
      rdSelA : OUT std_logic_vector (1 DOWNTO 0);
      rdreqA : OUT std_logic;
      rdSelB : OUT std_logic_vector (1 DOWNTO 0);
      rdreqB : OUT std_logic;
      rdSelC : OUT std_logic_vector (1 DOWNTO 0);
      rdreqC : OUT std_logic;
      rdSelD : OUT std_logic_vector (1 DOWNTO 0);
      rdreqD : OUT std_logic;
      rdSelE : OUT std_logic_vector (1 DOWNTO 0);
      rdreqE : OUT std_logic;
      rdSelF : OUT std_logic_vector (1 DOWNTO 0);
      rdreqF : OUT std_logic;
      rdSelG : OUT std_logic_vector (1 DOWNTO 0);
      rdreqG : OUT std_logic;
      rdSelH : OUT std_logic_vector (1 DOWNTO 0);
      rdreqH : OUT std_logic
      );
  END COMPONENT serdesRdDecoder;

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

  SIGNAL s_l2fiD      : std_logic_vector (31 DOWNTO 0);  -- corresponds to ddl_fbd (IN)
  SIGNAL s_l2foD      : std_logic_vector (31 DOWNTO 0);  -- corresponds to ddl_fbd (OUT)
  SIGNAL s_l2fiTEN_N  : std_logic;      -- corresponds to ddl_fbten_N (IN)
  SIGNAL s_l2foTEN_N  : std_logic;      -- corresponds to ddl_fbten_N (OUT)
  SIGNAL s_l2fiCTRL_N : std_logic;      -- corresponds to ddl_fbctrl_N (IN)
  SIGNAL s_l2foCTRL_N : std_logic;      -- corresponds to ddl_fbctrl_N (OUT)

  -- ********************************************************************************
  -- uc_fpga signals
  -- ********************************************************************************
  SIGNAL s_ucDIR        : std_logic;
  SIGNAL s_ucCTL        : std_logic;
  SIGNAL s_ucDS         : std_logic;
  SIGNAL s_uc_o         : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_uc_i         : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg_addr     : std_logic_vector(2 DOWNTO 0);
  SIGNAL s_sreg_addr    : std_logic_vector(3 DOWNTO 0);
  SIGNAL s_reg_load     : std_logic;
  SIGNAL s_sreg_load    : std_logic;
  SIGNAL s_reg_clr      : std_logic;
  SIGNAL s_reg0         : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg1         : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg2         : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg3         : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg3_ctr     : std_logic_vector(7 DOWNTO 0);
  SIGNAL trgctr_arst    : std_logic;
  SIGNAL s_reg4         : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg4_stat    : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg5         : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg6         : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg7         : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_serdes_reg   : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_tcd_working  : std_logic;
  SIGNAL s_tcd_rst_n    : std_logic;
  SIGNAL s_tcd_strb     : std_logic;
  SIGNAL s_tcd_clk      : std_logic;
  SIGNAL s_master_rst   : std_logic;
  SIGNAL s_trigger      : std_logic;
  SIGNAL s_evt_trg      : std_logic;
  SIGNAL s_tcdevt_trg   : std_logic;
  SIGNAL s_plsevt_trg   : std_logic;
  SIGNAL s_runReset     : std_logic;
  SIGNAL s_l2runReset   : std_logic;
  SIGNAL s_event_read   : std_logic;
  SIGNAL s_l2event_read : std_logic;
  SIGNAL s_special_wr   : std_logic;
  SIGNAL s_l2special_wr : std_logic;
  SIGNAL s_stage1       : std_logic;
  SIGNAL s_stage2       : std_logic;

  SIGNAL ddl_data            : std_logic_vector (31 DOWNTO 0);
  SIGNAL l2ddl_data          : std_logic_vector (31 DOWNTO 0);
  SIGNAL ddlfifo_usedw       : std_logic_vector (12 DOWNTO 0);
  SIGNAL l2fifo_usedw        : std_logic_vector (10 DOWNTO 0);
  SIGNAL ddlfifo_aclr        : std_logic;
  SIGNAL l2fifo_aclr         : std_logic;
  SIGNAL ddlfifo_empty       : std_logic;
  SIGNAL l2ddlfifo_empty     : std_logic;
  SIGNAL rd_ddl_fifo         : std_logic;
  SIGNAL rd_l2ddl_fifo       : std_logic;
  SIGNAL ddlfifo_almost_full : std_logic;

  SIGNAL s_triggerword   : std_logic_vector(19 DOWNTO 0);
  SIGNAL s_trgfifo_empty : std_logic;
  SIGNAL s_trgfifo_q     : std_logic_vector(19 DOWNTO 0);
  SIGNAL s_trg_mcu_word  : std_logic_vector (19 DOWNTO 0);
  SIGNAL counter23b_q    : std_logic_vector(22 DOWNTO 0);
  SIGNAL s_internal_plsr : std_logic;
  SIGNAL clk_80mhz       : std_logic;
  SIGNAL clk_10mhz       : std_logic;
  SIGNAL sclk_80mhz      : std_logic;
  SIGNAL sclk_10mhz      : std_logic;
  SIGNAL pll_locked      : std_logic;
  SIGNAL test_clk        : std_logic;

  SIGNAL s_serSel        : std_logic_vector (2 DOWNTO 0);
  SIGNAL s_serStatus     : std_logic_vector (3 DOWNTO 0);
  SIGNAL smif_fifo_empty : std_logic;
  SIGNAL smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL smif_rdenable   : std_logic;
  SIGNAL s_sync_q        : std_logic_vector (31 DOWNTO 0);
  SIGNAL s_sync_latch    : std_logic;
  SIGNAL s_smif_trigger  : std_logic;

  SIGNAL sa_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sa_sync_q          : std_logic_vector (31 DOWNTO 0);
  SIGNAL sa_sync_latch      : std_logic;
  SIGNAL sa_smif_fifo_empty : std_logic;
  SIGNAL sa_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sa_smif_rdenable   : std_logic;
  SIGNAL sa_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sa_smif_datatype   : std_logic_vector(3 DOWNTO 0);
  SIGNAL sr_areset_n        : std_logic;
  SIGNAL sr_wrreq_out       : std_logic;
  SIGNAL l2_wrreq_out       : std_logic;
  SIGNAL sr_outdata         : std_logic_vector(31 DOWNTO 0);
  SIGNAL l2_outdata         : std_logic_vector(31 DOWNTO 0);

  SIGNAL sb_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sb_sync_q          : std_logic_vector (31 DOWNTO 0);
  SIGNAL sb_sync_latch      : std_logic;
  SIGNAL sb_smif_fifo_empty : std_logic;
  SIGNAL sb_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sb_smif_rdenable   : std_logic;
  SIGNAL sb_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sb_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sc_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sc_sync_q          : std_logic_vector (31 DOWNTO 0);
  SIGNAL sc_sync_latch      : std_logic;
  SIGNAL sc_smif_fifo_empty : std_logic;
  SIGNAL sc_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sc_smif_rdenable   : std_logic;
  SIGNAL sc_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sc_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sd_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sd_sync_q          : std_logic_vector (31 DOWNTO 0);
  SIGNAL sd_sync_latch      : std_logic;
  SIGNAL sd_smif_fifo_empty : std_logic;
  SIGNAL sd_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sd_smif_rdenable   : std_logic;
  SIGNAL sd_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sd_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL se_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL se_sync_q          : std_logic_vector (31 DOWNTO 0);
  SIGNAL se_sync_latch      : std_logic;
  SIGNAL se_smif_fifo_empty : std_logic;
  SIGNAL se_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL se_smif_rdenable   : std_logic;
  SIGNAL se_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL se_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sf_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sf_sync_q          : std_logic_vector (31 DOWNTO 0);
  SIGNAL sf_sync_latch      : std_logic;
  SIGNAL sf_smif_fifo_empty : std_logic;
  SIGNAL sf_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sf_smif_rdenable   : std_logic;
  SIGNAL sf_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sf_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sg_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sg_sync_q          : std_logic_vector (31 DOWNTO 0);
  SIGNAL sg_sync_latch      : std_logic;
  SIGNAL sg_smif_fifo_empty : std_logic;
  SIGNAL sg_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sg_smif_rdenable   : std_logic;
  SIGNAL sg_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sg_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sh_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sh_sync_q          : std_logic_vector (31 DOWNTO 0);
  SIGNAL sh_sync_latch      : std_logic;
  SIGNAL sh_smif_fifo_empty : std_logic;
  SIGNAL sh_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sh_smif_rdenable   : std_logic;
  SIGNAL sh_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sh_smif_datatype   : std_logic_vector(3 DOWNTO 0);
  SIGNAL s_tcd_busy_n       : std_logic;
  SIGNAL s_tcd_trigger      : std_logic;

  SIGNAL sr_fifo_q     : std_logic_vector(31 DOWNTO 0);
  SIGNAL sr_fifo_empty : std_logic;

  SIGNAL s_ddltrgFifo_rdreq : std_logic;
  SIGNAL s_ddltrgFifo_empty : std_logic;
  SIGNAL s_ddltrgFifo_aclr  : std_logic;
  SIGNAL s_ddltrgFifo_q     : std_logic_vector (19 DOWNTO 0);

BEGIN

  -----------------------------------------------------------------------------
  -- Clocks, LEDs, and other defaults
  -----------------------------------------------------------------------------

  arstn <= '1';                         -- no reset for now

  -- PLL
--  pll_instance : pll PORT MAP (
--    inclk0 => clk,
--    c0     => clk_80mhz,
--    locked => pll_locked);

  -- this one for testing only:
  pll_instance : pll PORT MAP (
    inclk0 => clk,
    c0     => sclk_80mhz,
    c1     => test_clk,
    c2     => sclk_10mhz,
    locked => pll_locked);

  global_clk_buffer1 : global PORT MAP (a_in => clk, a_out => globalclk);
  global_clk_buffer2 : global PORT MAP (a_in => sclk_80mhz, a_out => clk_80mhz);
  global_clk_buffer3 : global PORT MAP (a_in => sclk_10mhz, a_out => clk_10mhz);
  global_clk_buffer4 : global PORT MAP (a_in => tcd_strb, a_out => s_tcd_strb);
  global_clk_buffer5 : global PORT MAP (a_in => tcd_clk, a_out => s_tcd_clk);

  -- counter to divide clock
  counter23b : lpm_counter
    GENERIC MAP (
      LPM_WIDTH     => 23,
      LPM_TYPE      => "LPM_COUNTER",
      LPM_DIRECTION => "UP")
    PORT MAP (
      clock  => clk_10mhz,
      clk_en => pll_locked,
      q      => counter23b_q);

  -- LEDs
  -- led <= "00";
  led(0) <= counter23b_q(22);  -- this should indicate if clock is present
  led(1) <= rstin;

  -- Other defaults

  ------------------- NO L2 AT THIS POINT ------------------------------
--  tcd_busy_p <= s_tcd_busy_n AND filf_n AND l2_filf_n;  -- active "low"
  tcd_busy_p <= s_tcd_busy_n AND filf_n;  -- active "low"

--  tcd_busy_p <= s_tcd_busy_n;           -- active "low"
  -- tcd_busy_p <= '1';                    -- active "low"
  -- rstout     <= '0';


  -----------------------------------------------------------------------------
  -- Mictor signals
  -----------------------------------------------------------------------------

  -- display trigger word on Mictor
--  mic(19 DOWNTO 0)  <= s_triggerword;
--  mic(20)           <= s_trigger;
--  mic(21)           <= s_evt_trg;
--  mic(27 DOWNTO 22) <= (OTHERS => '0');

--  -- mictor clock
--  mic(28) <= globalclk;

  mic <= (OTHERS => '0');

  -----------------------------------------------------------------------------
  -- SERDES-MAIN FPGA interface
  -----------------------------------------------------------------------------
  -- ***************** SERDES "A" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sa_smif_datain     <= maI(15 DOWNTO 0);  -- 16bit data from S to M
  sa_smif_fifo_empty <= maI(16);        -- FIFO empty indicator from S to M
  maO(18 DOWNTO 17)  <= sa_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  maO(19)            <= sa_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  maO(31 DOWNTO 20) <= sa_smif_dataout;   -- 12bit data from M to S 
  maO(35 DOWNTO 32) <= sa_smif_datatype;  -- 4bit data type indicator from M to S

  -- sync incoming data to 80MHz clock
  syncA : synchronizer PORT MAP (
    clk80mhz      => clk_80mhz,
    areset_n      => sr_areset_n,
    serdes_indata => sa_smif_datain(7 DOWNTO 0),
    serdes_clk    => sa_smif_datain(15),
    serdes_strb   => sa_smif_datain(8),
    sync_latch    => sa_sync_latch,
    sync_q        => sa_sync_q);

  -- ***************** SERDES "B" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sb_smif_datain     <= mbI(15 DOWNTO 0);  -- 16bit data from S to M
  sb_smif_fifo_empty <= mbI(16);        -- FIFO empty indicator from S to M
  mbO(18 DOWNTO 17)  <= sb_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  mbO(19)            <= sb_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  mbO(31 DOWNTO 20) <= sb_smif_dataout;   -- 12bit data from M to S 
  mbO(35 DOWNTO 32) <= sb_smif_datatype;  -- 4bit data type indicator from M to S

  -- sync incoming data to 80MHz clock
  syncB : synchronizer PORT MAP (
    clk80mhz      => clk_80mhz,
    areset_n      => sr_areset_n,
    serdes_indata => sb_smif_datain(7 DOWNTO 0),
    serdes_clk    => sb_smif_datain(15),
    serdes_strb   => sb_smif_datain(8),
    sync_latch    => sb_sync_latch,
    sync_q        => sb_sync_q);

  -- ***************** SERDES "C" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sc_smif_datain     <= mcI(15 DOWNTO 0);  -- 16bit data from S to M
  sc_smif_fifo_empty <= mcI(16);        -- FIFO empty indicator from S to M
  mcO(18 DOWNTO 17)  <= sc_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  mcO(19)            <= sc_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  mcO(31 DOWNTO 20) <= sc_smif_dataout;   -- 12bit data from M to S 
  mcO(35 DOWNTO 32) <= sc_smif_datatype;  -- 4bit data type indicator from M to S

  -- sync incoming data to 80MHz clock
  syncC : synchronizer PORT MAP (
    clk80mhz      => clk_80mhz,
    areset_n      => sr_areset_n,
    serdes_indata => sc_smif_datain(7 DOWNTO 0),
    serdes_clk    => sc_smif_datain(15),
    serdes_strb   => sc_smif_datain(8),
    sync_latch    => sc_sync_latch,
    sync_q        => sc_sync_q);

  -- ***************** SERDES "D" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sd_smif_datain     <= mdI(15 DOWNTO 0);  -- 16bit data from S to M
  sd_smif_fifo_empty <= mdI(16);        -- FIFO empty indicator from S to M
  mdO(18 DOWNTO 17)  <= sd_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  mdO(19)            <= sd_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  mdO(31 DOWNTO 20) <= sd_smif_dataout;   -- 12bit data from M to S 
  mdO(35 DOWNTO 32) <= sd_smif_datatype;  -- 4bit data type indicator from M to S

  -- sync incoming data to 80MHz clock
  syncD : synchronizer PORT MAP (
    clk80mhz      => clk_80mhz,
    areset_n      => sr_areset_n,
    serdes_indata => sd_smif_datain(7 DOWNTO 0),
    serdes_clk    => sd_smif_datain(15),
    serdes_strb   => sd_smif_datain(8),
    sync_latch    => sd_sync_latch,
    sync_q        => sd_sync_q);

  -- ***************** SERDES "E" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  se_smif_datain     <= meI(15 DOWNTO 0);  -- 16bit data from S to M
  se_smif_fifo_empty <= meI(16);        -- FIFO empty indicator from S to M
  meO(18 DOWNTO 17)  <= se_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  meO(19)            <= se_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  meO(31 DOWNTO 20) <= se_smif_dataout;   -- 12bit data from M to S 
  meO(35 DOWNTO 32) <= se_smif_datatype;  -- 4bit data type indicator from M to S

  -- sync incoming data to 80MHz clock
  syncE : synchronizer PORT MAP (
    clk80mhz      => clk_80mhz,
    areset_n      => sr_areset_n,
    serdes_indata => se_smif_datain(7 DOWNTO 0),
    serdes_clk    => se_smif_datain(15),
    serdes_strb   => se_smif_datain(8),
    sync_latch    => se_sync_latch,
    sync_q        => se_sync_q);

  -- ***************** SERDES "F" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sf_smif_datain     <= mfI(15 DOWNTO 0);  -- 16bit data from S to M
  sf_smif_fifo_empty <= mfI(16);        -- FIFO empty indicator from S to M
  mfO(18 DOWNTO 17)  <= sf_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  mfO(19)            <= sf_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  mfO(31 DOWNTO 20) <= sf_smif_dataout;   -- 12bit data from M to S 
  mfO(35 DOWNTO 32) <= sf_smif_datatype;  -- 4bit data type indicator from M to S

  -- sync incoming data to 80MHz clock
  syncF : synchronizer PORT MAP (
    clk80mhz      => clk_80mhz,
    areset_n      => sr_areset_n,
    serdes_indata => sf_smif_datain(7 DOWNTO 0),
    serdes_clk    => sf_smif_datain(15),
    serdes_strb   => sf_smif_datain(8),
    sync_latch    => sf_sync_latch,
    sync_q        => sf_sync_q);

  -- ***************** SERDES "G" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sg_smif_datain     <= mgI(15 DOWNTO 0);  -- 16bit data from S to M
  sg_smif_fifo_empty <= mgI(16);        -- FIFO empty indicator from S to M
  mgO(18 DOWNTO 17)  <= sg_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  mgO(19)            <= sg_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  mgO(31 DOWNTO 20) <= sg_smif_dataout;   -- 12bit data from M to S 
  mgO(35 DOWNTO 32) <= sg_smif_datatype;  -- 4bit data type indicator from M to S

  -- sync incoming data to 80MHz clock
  syncG : synchronizer PORT MAP (
    clk80mhz      => clk_80mhz,
    areset_n      => sr_areset_n,
    serdes_indata => sg_smif_datain(7 DOWNTO 0),
    serdes_clk    => sg_smif_datain(15),
    serdes_strb   => sg_smif_datain(8),
    sync_latch    => sg_sync_latch,
    sync_q        => sg_sync_q);

  -- ***************** SERDES "H" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sh_smif_datain     <= mhI(15 DOWNTO 0);  -- 16bit data from S to M
  sh_smif_fifo_empty <= mhI(16);        -- FIFO empty indicator from S to M
  mhO(18 DOWNTO 17)  <= sh_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  mhO(19)            <= sh_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  mhO(31 DOWNTO 20) <= sh_smif_dataout;   -- 12bit data from M to S 
  mhO(35 DOWNTO 32) <= sh_smif_datatype;  -- 4bit data type indicator from M to S

  -- sync incoming data to 80MHz clock
  syncH : synchronizer PORT MAP (
    clk80mhz      => clk_80mhz,
    areset_n      => sr_areset_n,
    serdes_indata => sh_smif_datain(7 DOWNTO 0),
    serdes_clk    => sh_smif_datain(15),
    serdes_strb   => sh_smif_datain(8),
    sync_latch    => sh_sync_latch,
    sync_q        => sh_sync_q);

  -- ******* Serdes Readout State Machine *******************************************
  -- take 16 bit data from synchronizer, generate 32 bit  data and latch for
  -- DDL FIFO
  serdes_reader_inst : serdes_reader PORT MAP (
    clk80mhz            => clk_80mhz,
    areset_n            => sr_areset_n,
    sync_q              => s_sync_q,
    sync_latch          => s_sync_latch,
    ser_status          => s_serStatus,
    fifo_empty          => smif_fifo_empty,
    outfifo_almost_full => ddlfifo_almost_full,
    evt_trg             => s_smif_trigger,  -- s_evt_trg,
    triggerWord         => s_triggerword,
    trgFifo_empty       => s_ddltrgFifo_empty,
    trgFifo_q           => s_ddltrgFifo_q,
    clk_10mhz           => clk_10mhz,
    serSel              => s_serSel,
    trgFifo_rdreq       => s_ddltrgFifo_rdreq,
    busy_n              => s_tcd_busy_n,
    rdsel_out           => smif_select,
    rdreq_out           => smif_rdenable,
    l2_wrreq_out        => l2_wrreq_out,
    l2_outdata          => l2_outdata,
    wrreq_out           => sr_wrreq_out,
    outdata             => sr_outdata);
  -- control reader with ddl fiber connect: when not connected, reset
  -- also reset when reg0.0 is high
  sr_areset_n <= s_event_read AND (NOT s_reg0(0));
--  sr_areset_n <= s_reg0(0);             -- control reader with Register 0 bit 0

  -- connect the selected sync'd data to serdes_reader
  WITH s_serSel SELECT
    s_sync_q <=
    sa_sync_q WHEN "000",
    sb_sync_q WHEN "001",
    sc_sync_q WHEN "010",
    sd_sync_q WHEN "011",
    se_sync_q WHEN "100",
    sf_sync_q WHEN "101",
    sg_sync_q WHEN "110",
    sh_sync_q WHEN OTHERS;

  WITH s_serSel SELECT
    s_sync_latch <=
    sa_sync_latch WHEN "000",
    sb_sync_latch WHEN "001",
    sc_sync_latch WHEN "010",
    sd_sync_latch WHEN "011",
    se_sync_latch WHEN "100",
    sf_sync_latch WHEN "101",
    sg_sync_latch WHEN "110",
    sh_sync_latch WHEN OTHERS;

  -- connect selected status bits
  WITH s_serSel SELECT
    s_serStatus <=
    sa_smif_datain(13 DOWNTO 10) WHEN "000",
    sb_smif_datain(13 DOWNTO 10) WHEN "001",
    sc_smif_datain(13 DOWNTO 10) WHEN "010",
    sd_smif_datain(13 DOWNTO 10) WHEN "011",
    se_smif_datain(13 DOWNTO 10) WHEN "100",
    sf_smif_datain(13 DOWNTO 10) WHEN "101",
    sg_smif_datain(13 DOWNTO 10) WHEN "110",
    sh_smif_datain(13 DOWNTO 10) WHEN OTHERS;

  -- connect selected FIFO Empty
  WITH s_serSel SELECT
    smif_fifo_empty <=
    sa_smif_fifo_empty WHEN "000",
    sb_smif_fifo_empty WHEN "001",
    sc_smif_fifo_empty WHEN "010",
    sd_smif_fifo_empty WHEN "011",
    se_smif_fifo_empty WHEN "100",
    sf_smif_fifo_empty WHEN "101",
    sg_smif_fifo_empty WHEN "110",
    sh_smif_fifo_empty WHEN OTHERS;

  -- output to selected rdreq and Channel select
  serRdDec_inst : serdesRdDecoder
    PORT MAP (
      clk    => NOT clk_80mhz,
      rdSel  => smif_select,
      rdreq  => smif_rdenable,
      adr    => s_serSel,
      rdSelA => sa_smif_select,
      rdreqA => sa_smif_rdenable,
      rdSelB => sb_smif_select,
      rdreqB => sb_smif_rdenable,
      rdSelC => sc_smif_select,
      rdreqC => sc_smif_rdenable,
      rdSelD => sd_smif_select,
      rdreqD => sd_smif_rdenable,
      rdSelE => se_smif_select,
      rdreqE => se_smif_rdenable,
      rdSelF => sf_smif_select,
      rdreqF => sf_smif_rdenable,
      rdSelG => sg_smif_select,
      rdreqG => sg_smif_rdenable,
      rdSelH => sh_smif_select,
      rdreqH => sh_smif_rdenable);

  -- ***************** Master-Serdes FPGA Interface Control **************************
--  s_smif_trigger <= s_evt_trg AND s_tcd_busy_n AND s_reg0(0);
  s_smif_trigger <= s_evt_trg AND s_tcd_busy_n AND s_event_read;
  smif_inst : smif
    PORT MAP (
      clock       => globalclk,
      dataout_a   => sa_smif_dataout,
      data_type_a => sa_smif_datatype,
      dataout_b   => sb_smif_dataout,
      data_type_b => sb_smif_datatype,
      dataout_c   => sc_smif_dataout,
      data_type_c => sc_smif_datatype,
      dataout_d   => sd_smif_dataout,
      data_type_d => sd_smif_datatype,
      dataout_e   => se_smif_dataout,
      data_type_e => se_smif_datatype,
      dataout_f   => sf_smif_dataout,
      data_type_f => sf_smif_datatype,
      dataout_g   => sg_smif_dataout,
      data_type_g => sg_smif_datatype,
      dataout_h   => sh_smif_dataout,
      data_type_h => sh_smif_datatype,
      serdes_reg  => s_serdes_reg,
      sreg_addr   => s_sreg_addr,
      sreg_load   => s_sreg_load,
      evt_trg     => s_smif_trigger,
      trgtoken    => s_triggerword(11 DOWNTO 0),
      rstin       => rstin,
      rstout      => rstout,
      areset_n    => arstn);

  -- ********************************************************************************
  -- Level-2 DDL Interface (currently, just the test patterns are implemented)
  -- ********************************************************************************
  l2_foclk     <= globalclk;
  s_l2fiTEN_N  <= l2_fbten_n;
  s_l2fiCTRL_N <= l2_fbctrl_n;
  s_l2fiD      <= l2_fbd;

  -- bi-directional signals state machine
  l2ddlbus : PROCESS (l2_fiben_n, l2_fidir, s_l2foTEN_N, s_l2foCTRL_N, l2_fbd, s_l2foD)
  BEGIN
    IF (l2_fiben_n = '1') OR (l2_fidir = '0') THEN
      l2_fbten_n  <= 'Z';
      l2_fbctrl_n <= 'Z';
      l2_fbd      <= (OTHERS => 'Z');
    ELSE
      l2_fbten_n  <= s_l2foTEN_N;
      l2_fbctrl_n <= s_l2foCTRL_N;
      l2_fbd      <= s_l2foD;
    END IF;
  END PROCESS;

  -- DDL state machines
  l2ddl_inst : ddl PORT MAP (
    fiD        => s_l2fiD,
    foD        => s_l2foD,
    foBSY_N    => l2_fobsy_n,
    fiCLK      => globalclk,
    fiDIR      => l2_fidir,
    fiBEN_N    => l2_fiben_n,
    fiLF_N     => l2_filf_n,
    fiCTRL_N   => s_l2fiCTRL_N,
    foCTRL_N   => s_l2foCTRL_N,
    fiTEN_N    => s_l2fiTEN_N,
    foTEN_N    => s_l2foTEN_N,
    ext_trg    => s_evt_trg,            -- external trigger (for testing)
    run_reset  => s_l2runReset,         -- external logic reset at run start
    special_wr => s_l2special_wr,   -- indicates FECTRL with parameter "0xabc0"
    event_read => s_l2event_read,       -- indicates run in progress
    reset      => s_reg0(2),            -- reset,
    fifo_q     => l2ddl_data,  -- "data" from external FIFO with event data
    fifo_empty => l2ddlfifo_empty,      -- "empty" from external FIFO
    fifo_rdreq => rd_l2ddl_fifo         -- "rdreq" for external FIFO
    );

  ------------------------- NO L2 AT THIS POINT --------------------------
  l2ddl_data      <= (OTHERS => '0');
  l2ddlfifo_empty <= '1';
  l2fifo_usedw    <= (OTHERS => '0');

  -- FIFO to store the L2 data.
  -- This FIFO is then read by the L2 DDL state machines to transfer 
  -- over the L2 DDL fibers
--  l2fifo : dcfifo
--    GENERIC MAP (
--      intended_device_family => "Cyclone II",
--      lpm_hint               => "MAXIMIZE_SPEED=7,",
--      lpm_numwords           => 2048,
--      lpm_showahead          => "OFF",
--      lpm_type               => "dcfifo",
--      lpm_width              => 32,
--      lpm_widthu             => 11,
--      overflow_checking      => "ON",
--      rdsync_delaypipe       => 5,
--      underflow_checking     => "ON",
--      use_eab                => "ON",
--      wrsync_delaypipe       => 5
--      )
--    PORT MAP (
--      wrclk   => clk_80mhz,
--      wrreq   => (l2_wrreq_out AND s_l2event_read),  -- only write when L2 fiber is connnected
--      rdclk   => NOT globalclk,
--      rdreq   => rd_l2ddl_fifo,
--      data    => l2_outdata,
--      aclr    => l2fifo_aclr,
--      rdempty => l2ddlfifo_empty,
--      wrusedw => l2fifo_usedw,
--      q       => l2ddl_data
--      );

--  l2fifo_aclr <= s_runReset OR s_l2runReset;  -- clear at Begin Run
--                                              -- or any time L2 sends ready to receive

  -- ********************************************************************************
  -- DAQ DDL Interface
  -- ********************************************************************************

  -- detector data link interface signals
  foclk      <= globalclk;
  s_fiTEN_N  <= fbten_n;
  s_fiCTRL_N <= fbctrl_n;
  s_fiD      <= fbd;

  -- bi-directional signals state machine
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

  -- DDL state machines
  ddl_inst : ddl PORT MAP (
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
    ext_trg    => s_evt_trg,            -- external trigger (for testing)
    run_reset  => s_runReset,           -- external logic reset at run start
    special_wr => s_special_wr,         -- use this for CANbus alert message
    event_read => s_event_read,         -- indicates run in progress
    reset      => s_reg0(2),            -- reset,
    fifo_q     => ddl_data,       -- "data" from external FIFO with event data
    fifo_empty => ddlfifo_empty,        -- "empty" from external FIFO
    fifo_rdreq => rd_ddl_fifo           -- "rdreq" for external FIFO
    );

  -- FIFO to store the data received from the Serdes FPGA.
  -- This FIFO is then read by the DDL state machines to transfer 
  -- over the DDL fibers
  ddlfifo : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_hint               => "MAXIMIZE_SPEED=7,",
      lpm_numwords           => 8192,
      lpm_showahead          => "OFF",
      lpm_type               => "dcfifo",
      lpm_width              => 32,
      lpm_widthu             => 13,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 5,
      underflow_checking     => "ON",
      use_eab                => "ON",
      wrsync_delaypipe       => 5
      )
    PORT MAP (
      wrclk   => clk_80mhz,
      wrreq   => sr_wrreq_out,
      rdclk   => NOT globalclk,
      rdreq   => rd_ddl_fifo,
      data    => sr_outdata,
      aclr    => ddlfifo_aclr,
      rdempty => ddlfifo_empty,
      wrusedw => ddlfifo_usedw,
      q       => ddl_data
      );

  ddlfifo_aclr <= s_runReset;           -- clear at Begin Run

  -- if there are less than 2048 words left:
--  ddlfifo_almost_full <= (ddlfifo_usedw(12 DOWNTO 11) = "11");
  ddlfifo_almost_full <= '1' WHEN ((ddlfifo_usedw(12 DOWNTO 11) = "11") OR  -- 2048 words
                                   (l2fifo_usedw(10 DOWNTO 8) = "111"))  -- 256 words
                         ELSE '0';

  -- ********************************************************************************
  -- Micro Controller interface
  -- ********************************************************************************
  s_ucDIR <= uc_fpga_hi(10);
  s_ucCTL <= uc_fpga_hi(9);
  s_ucDS  <= uc_fpga_hi(8);
  s_uc_i  <= uc_fpga_lo;

  -- bi-directional signals
  -- DIR = 0: uc -> FPGA
  -- DIR = 1: FPGA -> uc
  uc_bus : PROCESS (s_ucDIR, s_uc_o) IS
  BEGIN
    IF (s_ucDIR = '0') THEN
      uc_fpga_lo <= (OTHERS => 'Z');
    ELSE
      uc_fpga_lo <= s_uc_o;
    END IF;
  END PROCESS uc_bus;

  -- registers that interface with Serdes FPGAs
  serdes_reg_inst : serdes_registers
    PORT MAP (
      clock    => globalclk,
      arstn    => arstn,
      reg_data => s_uc_i,
      reg_addr => s_sreg_addr,
      reg_load => s_sreg_load,
      reg_out  => s_serdes_reg);

  -- Master FPGA control registers (currently not used)
  control_reg_inst : control_registers
    PORT MAP (
      clock    => globalclk,
      arstn    => arstn,
      reg_data => s_uc_i,
      reg_addr => s_reg_addr,
      reg_load => s_reg_load,
      reg0_out => s_reg0,
      reg1_out => s_reg1,
      reg2_out => s_reg2,
      reg3_out => s_reg3,
      reg4_out => s_reg4);

  -- use a read to reg4 as status register
  s_reg4_stat(7 DOWNTO 3) <= s_reg4(7 DOWNTO 3);
  s_reg4_stat(2)          <= s_tcd_working;  -- TCD acquire status
  s_reg4_stat(1)          <= s_event_read;   -- Fiber status (active high)
  s_reg4_stat(0)          <= s_tcd_busy_n;   -- busy status (active low)

  -- Micro - FPGA interface state machine
  uc_fpga_inst : uc_fpga_interface
    PORT MAP (
      clock         => globalclk,
      arstn         => pll_locked,
      dir           => s_ucDIR,
      ctl           => s_ucCTL,
      ds            => s_ucDS,
      uc_data_in    => s_uc_i,
      reg0          => s_reg0,
      reg1          => s_reg1,
      reg2          => s_reg2,
      reg3          => s_reg3_ctr,      -- trigger counter
      reg4          => s_reg4_stat,     -- status register
      reg5          => s_reg5,
      reg6          => s_reg6,
      reg7          => s_reg7,
      alert_data    => "01010101",
      alert_latch   => s_special_wr,
      serdes_reg    => s_serdes_reg,
      serdes_statma => sa_smif_datain(13 DOWNTO 10),
      serdes_statmb => sb_smif_datain(13 DOWNTO 10),
      serdes_statmc => sc_smif_datain(13 DOWNTO 10),
      serdes_statmd => sd_smif_datain(13 DOWNTO 10),
      serdes_statme => se_smif_datain(13 DOWNTO 10),
      serdes_statmf => sf_smif_datain(13 DOWNTO 10),
      serdes_statmg => sg_smif_datain(13 DOWNTO 10),
      serdes_statmh => sh_smif_datain(13 DOWNTO 10),
      reg_addr      => s_reg_addr,
      sreg_addr     => s_sreg_addr,
      reg_load      => s_reg_load,
      sreg_load     => s_sreg_load,
      reg_clr       => s_reg_clr,
      uc_data_out   => s_uc_o);

  -- common bus to SERDES FPGA's is driven by register 1 bits 0 - 3 
  m_all <= s_reg1(3 DOWNTO 0);

  -- ********************************************************************************
  -- Trigger interface
  -- ********************************************************************************
  -- tcd trigger
  -- reset when pll NOT locked, or when reg0(2) or runReset from DDL is high
  s_tcd_rst_n <= pll_locked AND (NOT (s_runReset OR s_reg0(2)));
  tcd_inst : tcd
    PORT MAP (
      rhic_strobe => s_tcd_strb,
      data_strobe => s_tcd_clk,
      data        => tcd_d,
      clock       => globalclk,
      reset_n     => s_tcd_rst_n,
      working     => s_tcd_working,     -- TCD is getting trigger data
      trgword     => s_triggerword,
      master_rst  => s_master_rst,
      trigger     => s_trigger,
      evt_trg     => s_tcdevt_trg);

  -- count event triggers
  trg_ctr : PROCESS (s_tcdevt_trg, trgctr_arst) IS
  BEGIN
    IF trgctr_arst = '1' THEN             -- asynchronous reset (active high)
      s_reg3_ctr <= (OTHERS => '0');
    ELSIF rising_edge(s_tcdevt_trg) THEN  -- rising clock edge
      s_reg3_ctr <= s_reg3_ctr + 1;
    END IF;
  END PROCESS trg_ctr;
  -- clear counter at "Begin Run" or with Register 0 bit 0
  trgctr_arst <= s_runReset OR s_reg0(0);

  -- pulser trigger: choose freq with register 0 bits [5..4]
  WITH s_reg0(5 DOWNTO 4) SELECT
    s_internal_plsr <=
    counter23b_q(22) WHEN "00",         -- ~1.2 Hz
    counter23b_q(18) WHEN "01",         -- ~19 Hz
    counter23b_q(15) WHEN "10",         -- ~152 Hz
    counter23b_q(11) WHEN OTHERS;       -- ~2440 Hz

  -- pulser trigger: shorten counter signal to 25ns
  shorten_pls : PROCESS (globalclk) IS
  BEGIN
    IF rising_edge(globalclk) THEN
      s_stage2 <= s_stage1;
      s_stage1 <= s_internal_plsr;
    END IF;
  END PROCESS shorten_pls;
  s_plsevt_trg <= s_stage1 AND (NOT s_stage2);

  -- select trigger with register 0 bit 1
  WITH s_reg0(1) SELECT
    s_evt_trg <=
    s_tcdevt_trg WHEN '0',
    s_plsevt_trg WHEN OTHERS;

  -- store the TCD info in a dual clock FIFO for later retrieval.
  -- s_trigger is high when a valid trigger is received, so USE
  -- it as the write request.
  -- s_reg_clr advances the FIFO to the next word on the read port.
  tcdfifo_inst : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_hint               => "MAXIMIZE_SPEED=7,",
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

  -- let the MCU read from this FIFO via registers 5,6, and 7
  s_trg_mcu_word <= (OTHERS => '0') WHEN (s_trgfifo_empty = '1') ELSE s_trgfifo_q;

  s_reg7 (7 DOWNTO 4) <= "0000";
  s_reg7 (3 DOWNTO 0) <= s_trg_mcu_word(19 DOWNTO 16);
  s_reg6              <= s_trg_mcu_word(15 DOWNTO 8);
  s_reg5              <= s_trg_mcu_word(7 DOWNTO 0);

  -- use a second dual-clock FIFO to store the trigger data for
  -- one event, so it can be attached to the ddl FIFO at the
  -- end after the event is read out from the Serdes channels
  ddltrgFifo_inst : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_hint               => "MAXIMIZE_SPEED=7,",
      lpm_numwords           => 32,     -- maximum 32 words
      lpm_showahead          => "ON",
      lpm_type               => "dcfifo",
      lpm_width              => 20,
      lpm_widthu             => 5,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 4,
      underflow_checking     => "ON",
      use_eab                => "ON",
      wrsync_delaypipe       => 4
      )
    PORT MAP (
      wrclk   => globalclk,
      wrreq   => s_trigger,
      rdclk   => NOT clk_80mhz,
      rdreq   => s_ddltrgFifo_rdreq,
      data    => s_triggerword,
      aclr    => s_ddltrgFifo_aclr,
      rdempty => s_ddltrgFifo_empty,
      q       => s_ddltrgFifo_q
      );

  s_ddltrgFifo_aclr <= s_runReset;      -- clear at Begin Run

END a;

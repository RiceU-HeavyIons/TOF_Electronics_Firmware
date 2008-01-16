-- $Id: master_fpga.vhd,v 1.24 2008-01-16 23:13:23 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : MASTER_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : master_fpga.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2005-12-22
-- Last update: 2008-01-16
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
      cpld          : IN    std_logic_vector(9 DOWNTO 0);   -- CPLD/FPGA bus
      uc_fpga_hi    : IN    std_logic_vector(10 DOWNTO 8);  -- FPGA/Micro bus
      uc_fpga_lo    : INOUT std_logic_vector(7 DOWNTO 0);   -- FPGA/Micro bus
      -- Buttons & LEDs
      butn          : IN    std_logic_vector(1 DOWNTO 0);   -- buttons
      led           : OUT   std_logic_vector(1 DOWNTO 0);   -- LEDs
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

--  COMPONENT pll
--    PORT
--      (
--        inclk0 : IN  std_logic := '0';
--        c0     : OUT std_logic;
--        locked : OUT std_logic
--        );
--  END COMPONENT;

  -- this one for testing only:
  COMPONENT pll
    PORT
      (
        inclk0 : IN  std_logic := '0';
        c0     : OUT std_logic;
        c1     : OUT std_logic;
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
      reg1_out : OUT std_logic_vector (7 DOWNTO 0);
      reg2_out : OUT std_logic_vector (7 DOWNTO 0);
      reg3_out : OUT std_logic_vector (7 DOWNTO 0);
      reg4_out : OUT std_logic_vector (7 DOWNTO 0);
      reg5_out : OUT std_logic_vector (7 DOWNTO 0)
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
      reg1          : IN  std_logic_vector(7 DOWNTO 0);
      reg2          : IN  std_logic_vector(7 DOWNTO 0);
      reg3          : IN  std_logic_vector(7 DOWNTO 0);
      reg4          : IN  std_logic_vector(7 DOWNTO 0);
      reg5          : IN  std_logic_vector(7 DOWNTO 0);
      reg6          : IN  std_logic_vector(7 DOWNTO 0);
      reg7          : IN  std_logic_vector(7 DOWNTO 0);
      reg8          : IN  std_logic_vector(7 DOWNTO 0);
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
      areset_n    : IN  std_logic);
  END COMPONENT smif;

  COMPONENT serdes_reader IS
    PORT (
      clk80mhz            : IN  std_logic;
      areset_n            : IN  std_logic;
      sync_q              : IN  std_logic_vector(16 DOWNTO 0);
      ser_status          : IN  std_logic_vector (3 DOWNTO 0);
      fifo_empty          : IN  std_logic;
      outfifo_almost_full : IN  boolean;
      evt_trg             : IN  std_logic;
      triggerWord         : IN  std_logic_vector (19 DOWNTO 0);
      trgFifo_empty       : IN  std_logic;
      trgFifo_q           : IN  std_logic_vector (19 DOWNTO 0);
      serSel              : OUT std_logic_vector (2 DOWNTO 0);
      trgFifo_rdreq       : OUT std_logic;
      busy                : OUT std_logic;
      rdsel_out           : OUT std_logic_vector (1 DOWNTO 0);
      rdreq_out           : OUT std_logic;
      wrreq_out           : OUT std_logic;
      outdata             : OUT std_logic_vector (31 DOWNTO 0));
  END COMPONENT serdes_reader;

  COMPONENT synchronizer IS
    PORT (
      clk80mhz      : IN  std_logic;
      areset_n      : IN  std_logic;
      serdes_indata : IN  std_logic_vector (7 DOWNTO 0);
      serdes_clk    : IN  std_logic;
      serdes_strb   : IN  std_logic;
      sync_q        : OUT std_logic_vector (16 DOWNTO 0));
  END COMPONENT synchronizer;

  COMPONENT serdesRdDecoder IS
    PORT (
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
      rdreqH : OUT std_logic);
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

  -- ********************************************************************************
  -- uc_fpga signals
  -- ********************************************************************************
  SIGNAL s_ucDIR      : std_logic;
  SIGNAL s_ucCTL      : std_logic;
  SIGNAL s_ucDS       : std_logic;
  SIGNAL s_uc_o       : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_uc_i       : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg_addr   : std_logic_vector(2 DOWNTO 0);
  SIGNAL s_sreg_addr  : std_logic_vector(3 DOWNTO 0);
  SIGNAL s_reg_load   : std_logic;
  SIGNAL s_sreg_load  : std_logic;
  SIGNAL s_reg_clr    : std_logic;
  SIGNAL s_reg1       : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg2       : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg3       : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg4       : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg5       : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg6       : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg7       : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_reg8       : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_serdes_reg : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_trigger    : std_logic;
  SIGNAL s_evt_trg    : std_logic;
  SIGNAL s_runReset   : std_logic;

  SIGNAL ddl_data            : std_logic_vector (31 DOWNTO 0);
  SIGNAL ddlfifo_usedw       : std_logic_vector (12 DOWNTO 0);
  SIGNAL ddlfifo_aclr        : std_logic;
  SIGNAL ddlfifo_empty       : std_logic;
  SIGNAL rd_ddl_fifo         : std_logic;
  SIGNAL ddlfifo_almost_full : boolean;

  SIGNAL s_triggerword   : std_logic_vector(19 DOWNTO 0);
  SIGNAL s_trgfifo_empty : std_logic;
  SIGNAL s_trgfifo_q     : std_logic_vector(19 DOWNTO 0);
  SIGNAL s_trg_mcu_word  : std_logic_vector (19 DOWNTO 0);
  SIGNAL counter25b_q    : std_logic_vector(24 DOWNTO 0);
  SIGNAL clk_80mhz       : std_logic;
  SIGNAL pll_locked      : std_logic;
  SIGNAL test_clk        : std_logic;
  
  SIGNAL s_serSel           : std_logic_vector (2 DOWNTO 0);
  SIGNAL s_serStatus        : std_logic_vector (3 DOWNTO 0);
  SIGNAL smif_fifo_empty : std_logic;
  SIGNAL smif_select : std_logic_vector(1 DOWNTO 0);
  SIGNAL smif_rdenable : std_logic;
  SIGNAL s_sync_q : std_logic_vector (16 DOWNTO 0);
  
  SIGNAL sa_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sa_sync_q          : std_logic_vector (16 DOWNTO 0);
  SIGNAL sa_smif_fifo_empty : std_logic;
  SIGNAL sa_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sa_smif_rdenable   : std_logic;
  SIGNAL sa_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sa_smif_datatype   : std_logic_vector(3 DOWNTO 0);
  SIGNAL sr_areset_n       : std_logic;
  SIGNAL sr_wrreq_out      : std_logic;
  SIGNAL sr_outdata        : std_logic_vector(31 DOWNTO 0);

  SIGNAL sb_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sb_sync_q          : std_logic_vector (16 DOWNTO 0);
  SIGNAL sb_smif_fifo_empty : std_logic;
  SIGNAL sb_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sb_smif_rdenable   : std_logic;
  SIGNAL sb_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sb_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sc_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sc_sync_q          : std_logic_vector (16 DOWNTO 0);
  SIGNAL sc_smif_fifo_empty : std_logic;
  SIGNAL sc_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sc_smif_rdenable   : std_logic;
  SIGNAL sc_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sc_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sd_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sd_sync_q          : std_logic_vector (16 DOWNTO 0);
  SIGNAL sd_smif_fifo_empty : std_logic;
  SIGNAL sd_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sd_smif_rdenable   : std_logic;
  SIGNAL sd_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sd_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL se_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL se_sync_q          : std_logic_vector (16 DOWNTO 0);
  SIGNAL se_smif_fifo_empty : std_logic;
  SIGNAL se_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL se_smif_rdenable   : std_logic;
  SIGNAL se_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL se_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sf_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sf_sync_q          : std_logic_vector (16 DOWNTO 0);
  SIGNAL sf_smif_fifo_empty : std_logic;
  SIGNAL sf_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sf_smif_rdenable   : std_logic;
  SIGNAL sf_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sf_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sg_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sg_sync_q          : std_logic_vector (16 DOWNTO 0);
  SIGNAL sg_smif_fifo_empty : std_logic;
  SIGNAL sg_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sg_smif_rdenable   : std_logic;
  SIGNAL sg_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sg_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sh_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sh_sync_q          : std_logic_vector (16 DOWNTO 0);
  SIGNAL sh_smif_fifo_empty : std_logic;
  SIGNAL sh_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sh_smif_rdenable   : std_logic;
  SIGNAL sh_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sh_smif_datatype   : std_logic_vector(3 DOWNTO 0);
  SIGNAL s_tcd_busy_n       : std_logic;

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

  global_clk_buffer : global PORT MAP (a_in => clk, a_out => globalclk);

  arstn <= '1';                         -- no reset for now

  -- PLL
--  pll_instance : pll PORT MAP (
--    inclk0 => clk,
--    c0     => clk_80mhz,
--    locked => pll_locked);

  -- this one for testing only:
  pll_instance : pll PORT MAP (
    inclk0 => clk,
    c0     => clk_80mhz,
    c1     => test_clk,
    locked => pll_locked);


  -- counter to divide clock
  counter25b : lpm_counter
    GENERIC MAP (
      LPM_WIDTH     => 25,
      LPM_TYPE      => "LPM_COUNTER",
      LPM_DIRECTION => "UP")
    PORT MAP (
      clock  => globalclk,
      clk_en => pll_locked,
      q      => counter25b_q);

  -- LEDs
  -- led <= "00";
  led(0) <= counter25b_q(24);  -- this should indicate if clock is present
  led(1) <= rstin;

  -- Other defaults

  tcd_busy_p <= s_tcd_busy_n;           -- active "low"
  -- tcd_busy_p <= '1';                    -- active "low"
  -- rstout     <= '0';


  -----------------------------------------------------------------------------
  -- Mictor signals
  -----------------------------------------------------------------------------

  -- display trigger word on Mictor
  mic(19 DOWNTO 0)  <= s_triggerword;
  mic(20)           <= s_trigger;
  mic(21)           <= s_evt_trg;
  mic(27 DOWNTO 22) <= (OTHERS => '0');

  -- mictor clock
  mic(28) <= globalclk;

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
    sync_q        => sh_sync_q);

  -- ******* Serdes Readout State Machine *******************************************
  -- take 16 bit data from synchronizer, generate 32 bit  data and latch for
  -- DDL FIFO
  serdes_reader_inst : serdes_reader PORT MAP (
    clk80mhz            => clk_80mhz,
    areset_n            => sr_areset_n,
    sync_q              => s_sync_q,
    ser_status          => s_serStatus,
    fifo_empty          => smif_fifo_empty,
    outfifo_almost_full => ddlfifo_almost_full,
    evt_trg             => (s_evt_trg AND s_trigger),
    triggerWord         => s_triggerword,
    trgFifo_empty       => s_ddltrgFifo_empty,
    trgFifo_q           => s_ddltrgFifo_q,
    serSel              => s_serSel,
    trgFifo_rdreq       => s_ddltrgFifo_rdreq,
    busy                => s_tcd_busy_n,
    rdsel_out           => smif_select,
    rdreq_out           => smif_rdenable,
    wrreq_out           => sr_wrreq_out,
    outdata             => sr_outdata);
  sr_areset_n <= s_reg1(0);            -- control reader with Register 1 bit 0

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
  serRdDec_inst : serdesRdDecoder PORT MAP (
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
      evt_trg     => (s_evt_trg AND s_trigger AND s_tcd_busy_n),
      trgtoken    => s_triggerword(11 DOWNTO 0),
      rstin       => rstin,
      rstout      => rstout,
      areset_n    => arstn);

  -- ********************************************************************************
  -- Level-2 DDL Interface
  -- ********************************************************************************
  -- not yet implemented, set all signals to reasonable defaults
  l2_fbten_n  <= 'Z';
  l2_fbctrl_n <= 'Z';
  l2_fbd      <= (OTHERS => 'Z');
  l2_foclk    <= '0';
  l2_fobsy_n  <= '0';

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
    ext_trg    => '0',                  -- external trigger (for testing)
    run_reset  => s_runReset,           -- external logic reset at run start
    reset      => '0',                  -- reset,
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
      lpm_numwords           => 8192,
      lpm_showahead          => "OFF",
      lpm_type               => "dcfifo",
      lpm_width              => 32,
      lpm_widthu             => 13,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 4,
      underflow_checking     => "ON",
      use_eab                => "ON",
      wrsync_delaypipe       => 4
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

  -- if there are less than 512 words left:
  ddlfifo_almost_full <= (ddlfifo_usedw(12 DOWNTO 9) = "1111");

  -- ********************************************************************************
  -- Micro Controller interface
  -- ********************************************************************************
  s_ucDIR <= uc_fpga_hi(10);
  s_ucCTL <= uc_fpga_hi(9);
  s_ucDS  <= uc_fpga_hi(8);
  s_uc_i  <= uc_fpga_lo;

  -- bi-directional signals
  uc_bus : PROCESS (s_ucDIR, s_uc_o) IS
  BEGIN  -- PROCESS uc_bus
    IF (s_ucDIR = '1') THEN
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
      reg1_out => s_reg1,
      reg2_out => s_reg2,
      reg3_out => s_reg3,
      reg4_out => s_reg4,
      reg5_out => s_reg5);

  -- Micro - FPGA interface state machine
  uc_fpga_inst : uc_fpga_interface
    PORT MAP (
      clock         => globalclk,
      arstn         => arstn,
      dir           => s_ucDIR,
      ctl           => s_ucCTL,
      ds            => s_ucDS,
      uc_data_in    => s_uc_i,
      reg1          => s_reg1,
      reg2          => s_reg2,
      reg3          => s_reg3,
      reg4          => s_reg4,
      reg5          => s_reg5,
      reg6          => s_reg6,
      reg7          => s_reg7,
      reg8          => s_reg8,
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

  -- common bus to SERDES FPGA's is driven by register 2 bits 0 - 3 
  m_all <= s_reg2(3 DOWNTO 0);

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

  -- let the MCU read from this FIFO via registers 6,7, and 8
  s_trg_mcu_word <= (OTHERS => '0') WHEN (s_trgfifo_empty = '1') ELSE s_trgfifo_q;

  s_reg8 (7 DOWNTO 4) <= "0000";
  s_reg8 (3 DOWNTO 0) <= s_trg_mcu_word(19 DOWNTO 16);
  s_reg7              <= s_trg_mcu_word(15 DOWNTO 8);
  s_reg6              <= s_trg_mcu_word(7 DOWNTO 0);

  -- use a second dual-clock FIFO to store the trigger data FOR
  -- one event, so it can be attached to the ddl FIFO at the
  -- end after the event is read out from the Serdes channels
  ddltrgFifo_inst : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_numwords           => 16,     -- maximum 16 words
      lpm_showahead          => "ON",
      lpm_type               => "dcfifo",
      lpm_width              => 20,
      lpm_widthu             => 4,
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

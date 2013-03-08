-- $Id: master_fpga.vhd,v 1.14 2007-12-14 14:59:21 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : MASTER_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : master_fpga.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2005-12-22
-- Last update: 2007-12-14
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
      clk        : IN    std_logic;     -- Master clock
      -- Mictor outputs
      mic        : OUT   std_logic_vector(28 DOWNTO 0);
      -- bus to serdes fpga's
      ma, mb, mc : INOUT std_logic_vector(35 DOWNTO 0);
      md, me, mf : INOUT std_logic_vector(35 DOWNTO 0);
      mg, mh     : INOUT std_logic_vector(35 DOWNTO 0);
      m_all      : OUT   std_logic_vector(3 DOWNTO 0);
      -- CPLD and Micro connections
      cpld       : IN    std_logic_vector(9 DOWNTO 0);   -- CPLD/FPGA bus
      uc_fpga_hi : IN    std_logic_vector(10 DOWNTO 8);  -- FPGA/Micro bus
      uc_fpga_lo : INOUT std_logic_vector(7 DOWNTO 0);   -- FPGA/Micro bus
      -- Buttons & LEDs
      butn       : IN    std_logic_vector(1 DOWNTO 0);   -- buttons
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
      -- Level-2 SIU
      l2_fbctrl_n : INOUT std_logic;
      l2_fbten_n  : INOUT std_logic;
      l2_fidir    : IN    std_logic;
      l2_fiben_n  : IN    std_logic;
      l2_filf_n   : IN    std_logic;
      l2_fobsy_n  : OUT   std_logic;
      l2_foclk    : OUT   std_logic;
      l2_fbd      : INOUT std_logic_vector(31 DOWNTO 0);
      -- Resets
      rstin      : IN    std_logic;
      rstout     : OUT   std_logic

      );
END master_fpga;


ARCHITECTURE a OF master_fpga IS

  COMPONENT pll
    PORT
      (
        inclk0 : IN  std_logic := '0';
        c0     : OUT std_logic;
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
      serdes_reg  : IN  std_logic_vector(7 DOWNTO 0);
      reg_addr    : OUT std_logic_vector(2 DOWNTO 0);
      sreg_addr   : OUT std_logic_vector(3 DOWNTO 0);
      reg_load    : OUT std_logic;
      sreg_load   : OUT std_logic;
      reg_clr     : OUT std_logic;
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
      indata              : IN  std_logic_vector (15 DOWNTO 0);
      fifo_empty          : IN  std_logic;
      outfifo_almost_full : IN  boolean;
      rdsel_out           : OUT std_logic_vector (1 DOWNTO 0);
      rdreq_out           : OUT std_logic;
      wrreq_out           : OUT std_logic;
      outdata             : OUT std_logic_vector (31 DOWNTO 0));
  END COMPONENT serdes_reader;

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

  SIGNAL sa_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sa_smif_fifo_empty : std_logic;
  SIGNAL sa_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sa_smif_rdenable   : std_logic;
  SIGNAL sa_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sa_smif_datatype   : std_logic_vector(3 DOWNTO 0);
  SIGNAL sAr_areset_n       : std_logic;
  SIGNAL sAr_wrreq_out      : std_logic;
  SIGNAL sAr_outdata        : std_logic_vector(31 DOWNTO 0);

  SIGNAL sb_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sb_smif_fifo_empty : std_logic;
  SIGNAL sb_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sb_smif_rdenable   : std_logic;
  SIGNAL sb_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sb_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sc_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sc_smif_fifo_empty : std_logic;
  SIGNAL sc_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sc_smif_rdenable   : std_logic;
  SIGNAL sc_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sc_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sd_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sd_smif_fifo_empty : std_logic;
  SIGNAL sd_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sd_smif_rdenable   : std_logic;
  SIGNAL sd_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sd_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL se_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL se_smif_fifo_empty : std_logic;
  SIGNAL se_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL se_smif_rdenable   : std_logic;
  SIGNAL se_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL se_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sf_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sf_smif_fifo_empty : std_logic;
  SIGNAL sf_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sf_smif_rdenable   : std_logic;
  SIGNAL sf_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sf_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sg_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sg_smif_fifo_empty : std_logic;
  SIGNAL sg_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sg_smif_rdenable   : std_logic;
  SIGNAL sg_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sg_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sh_smif_datain     : std_logic_vector (15 DOWNTO 0);
  SIGNAL sh_smif_fifo_empty : std_logic;
  SIGNAL sh_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL sh_smif_rdenable   : std_logic;
  SIGNAL sh_smif_dataout    : std_logic_vector(11 DOWNTO 0);
  SIGNAL sh_smif_datatype   : std_logic_vector(3 DOWNTO 0);

  SIGNAL sArfifo_q     : std_logic_vector(31 DOWNTO 0);
  SIGNAL sArfifo_empty : std_logic;


BEGIN

  global_clk_buffer : global PORT MAP (a_in => clk, a_out => globalclk);

  arstn <= '1';                         -- no reset for now

  -- PLL
  pll_instance : pll PORT MAP (
    inclk0 => clk,
    c0     => clk_80mhz,
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
  -- led(1) <= '0';
  led(1) <= rstin;

  -- bus to SERDES FPGA is driven by CPLD
  m_all <= cpld(3 DOWNTO 0);

  -----------------------------------------------------------------------------
  -- SERDES-MAIN FPGA interface
  -----------------------------------------------------------------------------
  ma(16 DOWNTO 0) <= (OTHERS => 'Z');
  mb(16 DOWNTO 0) <= (OTHERS => 'Z');
  mc(16 DOWNTO 0) <= (OTHERS => 'Z');
  md(16 DOWNTO 0) <= (OTHERS => 'Z');
  me(16 DOWNTO 0) <= (OTHERS => 'Z');
  mf(16 DOWNTO 0) <= (OTHERS => 'Z');
  mg(16 DOWNTO 0) <= (OTHERS => 'Z');
  mh(16 DOWNTO 0) <= (OTHERS => 'Z');


  -- ***************** SERDES "A" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sa_smif_datain     <= ma(15 DOWNTO 0);   -- 16bit data from S to M
  sa_smif_fifo_empty <= ma(16);         -- FIFO empty indicator from S to M
  ma(18 DOWNTO 17)   <= sa_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  ma(19)             <= sa_smif_rdenable;  -- read enable from M to S for FIFO

  serdesA_reader : serdes_reader PORT MAP (
    clk80mhz            => clk_80mhz,
    areset_n            => sAr_areset_n,
    indata              => sa_smif_datain,
    fifo_empty          => sa_smif_fifo_empty,
    outfifo_almost_full => ddlfifo_almost_full,
    rdsel_out           => sa_smif_select,
    rdreq_out           => sa_smif_rdenable,
    wrreq_out           => sAr_wrreq_out,
    outdata             => sAr_outdata);
  sAr_areset_n <= '1';

  -- MASTER (M) to SERDES (S) interface
  ma(31 DOWNTO 20) <= sa_smif_dataout;  -- 12bit data from M to S 
  ma(35 DOWNTO 32) <= sa_smif_datatype;  -- 4bit data type indicator from M to S

--  sa_smif_select   <= "00";
--  sa_smif_rdenable <= '0';


  -- ***************** SERDES "B" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sb_smif_datain     <= mb(15 DOWNTO 0);   -- 16bit data from S to M
  sb_smif_fifo_empty <= mb(16);         -- FIFO empty indicator from S to M
  mb(18 DOWNTO 17)   <= sb_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  mb(19)             <= sb_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  mb(31 DOWNTO 20) <= sb_smif_dataout;  -- 12bit data from M to S 
  mb(35 DOWNTO 32) <= sb_smif_datatype;  -- 4bit data type indicator from M to S

  sb_smif_select   <= "00";
  sb_smif_rdenable <= '0';

  -- ***************** SERDES "C" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sc_smif_datain     <= mc(15 DOWNTO 0);   -- 16bit data from S to M
  sc_smif_fifo_empty <= mc(16);         -- FIFO empty indicator from S to M
  mc(18 DOWNTO 17)   <= sc_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  mc(19)             <= sc_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  mc(31 DOWNTO 20) <= sc_smif_dataout;  -- 12bit data from M to S 
  mc(35 DOWNTO 32) <= sc_smif_datatype;  -- 4bit data type indicator from M to S

  sc_smif_select   <= "00";
  sc_smif_rdenable <= '0';

  -- ***************** SERDES "D" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sd_smif_datain     <= md(15 DOWNTO 0);   -- 16bit data from S to M
  sd_smif_fifo_empty <= md(16);         -- FIFO empty indicator from S to M
  md(18 DOWNTO 17)   <= sd_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  md(19)             <= sd_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  md(31 DOWNTO 20) <= sd_smif_dataout;  -- 12bit data from M to S 
  md(35 DOWNTO 32) <= sd_smif_datatype;  -- 4bit data type indicator from M to S

  sd_smif_select   <= "00";
  sd_smif_rdenable <= '0';

  -- ***************** SERDES "E" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  se_smif_datain     <= me(15 DOWNTO 0);   -- 16bit data from S to M
  se_smif_fifo_empty <= me(16);         -- FIFO empty indicator from S to M
  me(18 DOWNTO 17)   <= se_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  me(19)             <= se_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  me(31 DOWNTO 20) <= se_smif_dataout;  -- 12bit data from M to S 
  me(35 DOWNTO 32) <= se_smif_datatype;  -- 4bit data type indicator from M to S

  se_smif_select   <= "00";
  se_smif_rdenable <= '0';

  -- ***************** SERDES "F" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sf_smif_datain     <= mf(15 DOWNTO 0);   -- 16bit data from S to M
  sf_smif_fifo_empty <= mf(16);         -- FIFO empty indicator from S to M
  mf(18 DOWNTO 17)   <= sf_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  mf(19)             <= sf_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  mf(31 DOWNTO 20) <= sf_smif_dataout;  -- 12bit data from M to S 
  mf(35 DOWNTO 32) <= sf_smif_datatype;  -- 4bit data type indicator from M to S

  sf_smif_select   <= "00";
  sf_smif_rdenable <= '0';

  -- ***************** SERDES "G" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sg_smif_datain     <= mg(15 DOWNTO 0);   -- 16bit data from S to M
  sg_smif_fifo_empty <= mg(16);         -- FIFO empty indicator from S to M
  mg(18 DOWNTO 17)   <= sg_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  mg(19)             <= sg_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  mg(31 DOWNTO 20) <= sg_smif_dataout;  -- 12bit data from M to S 
  mg(35 DOWNTO 32) <= sg_smif_datatype;  -- 4bit data type indicator from M to S

  sg_smif_select   <= "00";
  sg_smif_rdenable <= '0';

  -- ***************** SERDES "H" *************************************************** 
  -- SERDES (S) to MASTER (M) interface
  sh_smif_datain     <= mh(15 DOWNTO 0);   -- 16bit data from S to M
  sh_smif_fifo_empty <= mh(16);         -- FIFO empty indicator from S to M
  mh(18 DOWNTO 17)   <= sh_smif_select;  -- select from M to S to select 1 of 4 FIFOs
  mh(19)             <= sh_smif_rdenable;  -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  mh(31 DOWNTO 20) <= sh_smif_dataout;  -- 12bit data from M to S 
  mh(35 DOWNTO 32) <= sh_smif_datatype;  -- 4bit data type indicator from M to S

  sh_smif_select   <= "00";
  sh_smif_rdenable <= '0';

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
      evt_trg     => (s_evt_trg AND s_trigger),
      trgtoken    => s_triggerword(11 DOWNTO 0),
      rstin       => rstin,
      rstout      => rstout,
      areset_n    => arstn);

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
      wrclk   => NOT clk_80mhz,
      wrreq   => sAr_wrreq_out,
      rdclk   => NOT globalclk,
      rdreq   => rd_ddl_fifo,
      data    => sAr_outdata,
      rdempty => ddlfifo_empty,
      wrusedw => ddlfifo_usedw,
      q       => ddl_data
      );

  -- if there are less than 512 words left:
  ddlfifo_almost_full <= (ddlfifo_usedw(12 DOWNTO 9) = "1111");

  -- (need a state machine to control what goes into this FIFO, i.e. switch
  -- from Serdes to Serdes) 

  -----------------------------------------------------------------------------
  -- Mictor defaults
  -----------------------------------------------------------------------------

-- mic(63 DOWNTO  0) <= (OTHERS => '0');

  -- display trigger word on Mictor
  mic(19 DOWNTO 0)  <= s_triggerword;
  mic(20)           <= s_trigger;
  mic(21)           <= s_evt_trg;
--  mic(27 DOWNTO 22) <= (OTHERS => '0');
--  mic(63 DOWNTO 32) <= ddl_data;
--  mic(31)           <= ddlfifo_empty;

  -- mictor clock
  mic(28) <= globalclk;

  -- Other defaults

  tcd_busy_p <= '1';                    -- active "low"
  -- rstout     <= '0';

  -- ********************************************************************************
  -- Level-2 ddl_interface defaults
  -- ********************************************************************************
  -- not yet implemented, set all to reasonable defaults
  l2_fbten_n  <= 'Z';
  l2_fbctrl_n <= 'Z';
  l2_fbd      <= (OTHERS => 'Z');
  l2_foclk    <= '0';
  l2_fobsy_n  <= '0';

  -- ********************************************************************************
  -- ddl_interface defaults
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

  ddl_inst : ddl PORT MAP (             -- DDL state machines
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

  -- ********************************************************************************
  -- micro interface defaults
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
      serdes_reg  => s_serdes_reg,
      reg_addr    => s_reg_addr,
      sreg_addr   => s_sreg_addr,
      reg_load    => s_reg_load,
      sreg_load   => s_sreg_load,
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



END a;
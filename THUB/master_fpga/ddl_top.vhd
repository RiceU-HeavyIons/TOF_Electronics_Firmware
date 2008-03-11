-- $Id: ddl_top.vhd,v 1.2 2008-03-11 15:59:17 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : DDL
-- Project    : TOF
-------------------------------------------------------------------------------
-- File       : ddl_top.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2004-12-09
-- Last update: 2008-03-05
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Top Level Component for the DDL interface
-------------------------------------------------------------------------------

LIBRARY altera;
USE altera.maxplus2.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

LIBRARY lpm;
USE lpm.lpm_components.ALL;

--  Entity Declaration
ENTITY ddl IS
  PORT
    (
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
      event_read : OUT std_logic;       -- indicates run in progress
      foD        : OUT std_logic_vector(31 DOWNTO 0);
      foBSY_N    : OUT std_logic;
      foCTRL_N   : OUT std_logic;
      foTEN_N    : OUT std_logic;
      fifo_rdreq : OUT std_logic        -- interface fifo read request
      );
END ddl;

-- Architecture body
ARCHITECTURE a OF ddl IS

  COMPONENT ddl_registers
    PORT (
      clock    : IN  std_logic;
      arstn    : IN  std_logic;
      reg_data : IN  std_logic_vector (7 DOWNTO 0);
      reg_addr : IN  std_logic_vector (5 DOWNTO 0);
      reg_load : IN  std_logic;
      reg_lock : IN  std_logic;
      ps_reg   : OUT std_logic_vector (7 DOWNTO 0);
      bl_reg   : OUT std_logic_vector (7 DOWNTO 0);
      dt_reg   : OUT std_logic_vector (7 DOWNTO 0);
      fc_reg   : OUT std_logic_vector (7 DOWNTO 0);
      te_reg   : OUT std_logic_vector (7 DOWNTO 0);
      xx_reg   : OUT std_logic_vector (7 DOWNTO 0)
      );
  END COMPONENT;

  COMPONENT ddl_receiver
    PORT (
      clock       : IN  std_logic;
      arstn       : IN  std_logic;
      fc_reg      : IN  std_logic_vector (7 DOWNTO 0);
      block_read  : OUT std_logic;
      block_write : OUT std_logic;
      event_read  : OUT std_logic;
      reset_evid  : OUT std_logic;
      im_din      : OUT std_logic_vector (31 DOWNTO 0);
      im_dinval   : OUT std_logic;
      reg_data    : OUT std_logic_vector (7 DOWNTO 0);
      reg_addr    : OUT std_logic_vector (5 DOWNTO 0);
      reg_load    : OUT std_logic;
      reg_read    : OUT std_logic;
      reg_lock    : OUT std_logic;
      tid         : OUT std_logic_vector (3 DOWNTO 0);
      fiD         : IN  std_logic_vector (31 DOWNTO 0);
      fiTEN_N     : IN  std_logic;
      fiCTRL_N    : IN  std_logic;
      fiDIR       : IN  std_logic;
      fiBEN_N     : IN  std_logic;
      foBSY_N     : OUT std_logic
      );
  END COMPONENT;

  COMPONENT ddl_transmitter
    PORT (
      clock      : IN  std_logic;
      arstn      : IN  std_logic;
      trigger    : IN  std_logic;
      gap_active : OUT std_logic;
      block_read : IN  std_logic;
      event_read : IN  std_logic;
      reg_read   : IN  std_logic;
      reg_addr   : IN  std_logic_vector (5 DOWNTO 0);
      tid        : IN  std_logic_vector (3 DOWNTO 0);
      ps_reg     : IN  std_logic_vector (7 DOWNTO 0);
      bl_reg     : IN  std_logic_vector (7 DOWNTO 0);
      dt_reg     : IN  std_logic_vector (7 DOWNTO 0);
      fc_reg     : IN  std_logic_vector (7 DOWNTO 0);
      te_reg     : IN  std_logic_vector (7 DOWNTO 0);
      xx_reg     : IN  std_logic_vector (7 DOWNTO 0);
      pg_dout    : IN  std_logic_vector (32 DOWNTO 0);
      pg_doutval : IN  std_logic;
      pg_enable  : OUT std_logic;
      im_dout    : IN  std_logic_vector (32 DOWNTO 0);
      im_doutval : IN  std_logic;
      im_enable  : OUT std_logic;
      foD        : OUT std_logic_vector (31 DOWNTO 0);
      foTEN_N    : OUT std_logic;
      foCTRL_N   : OUT std_logic;
      fiDIR      : IN  std_logic;
      fiBEN_N    : IN  std_logic;
      fiLF_N     : IN  std_logic
      );
  END COMPONENT;

  COMPONENT ddl_pattern_generator
    PORT (
      clock       : IN  std_logic;
      arstn       : IN  std_logic;
      ps_reg      : IN  std_logic_vector (7 DOWNTO 0);
      bl_reg      : IN  std_logic_vector (7 DOWNTO 0);
      xx_reg      : IN  std_logic_vector (7 DOWNTO 0);
      tid         : IN  std_logic_vector (3 DOWNTO 0);
      enable      : IN  std_logic;
      suspend     : IN  std_logic;
      reset_evid  : IN  std_logic;
      fifo_q      : IN  std_logic_vector (31 DOWNTO 0);
      fifo_empty  : IN  std_logic;
      fifo_rdreq  : OUT std_logic;
      datao       : OUT std_logic_vector (32 DOWNTO 0);
      datao_valid : OUT std_logic
      );
  END COMPONENT;

  COMPONENT ddl_trigger_generator
    PORT (
      clock      : IN  std_logic;
      arstn      : IN  std_logic;
      ext_tr_in  : IN  std_logic;
      gap_active : IN  std_logic;
      dt_reg     : IN  std_logic_vector (7 DOWNTO 0);
      fifo_empty : IN  std_logic;
      trigger    : OUT std_logic
      );
  END COMPONENT;

  COMPONENT ddl_internal_memory
    PORT (
      clock       : IN  std_logic;
      arstn       : IN  std_logic;
      block_read  : IN  std_logic;
      block_write : IN  std_logic;
      tid         : IN  std_logic_vector (3 DOWNTO 0);
      datai       : IN  std_logic_vector (31 DOWNTO 0);
      datai_valid : IN  std_logic;
      suspend     : IN  std_logic;
      datao       : OUT std_logic_vector (32 DOWNTO 0);
      datao_valid : OUT std_logic
      );
  END COMPONENT;

  SIGNAL s_arstn       : std_logic;
  SIGNAL s_clock       : std_logic;
  SIGNAL s_reg_data    : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_reg_addr    : std_logic_vector (5 DOWNTO 0);
  SIGNAL s_reg_load    : std_logic;
  SIGNAL s_reg_lock    : std_logic;
  SIGNAL s_reg_read    : std_logic;
  SIGNAL s_ps_reg      : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_bl_reg      : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_dt_reg      : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_fc_reg      : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_te_reg      : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_xx_reg      : std_logic_vector (7 DOWNTO 0);
  SIGNAL s_block_read  : std_logic;
  SIGNAL s_block_write : std_logic;
  SIGNAL s_event_read  : std_logic;
  SIGNAL s_reset_evid  : std_logic;
  SIGNAL s_im_din      : std_logic_vector (31 DOWNTO 0);
  SIGNAL s_im_dinval   : std_logic;
  SIGNAL s_tid         : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_pg_dout     : std_logic_vector (32 DOWNTO 0);
  SIGNAL s_pg_doutval  : std_logic;
  SIGNAL s_pg_enable   : std_logic;
  SIGNAL s_pg_suspend  : std_logic;
  SIGNAL s_im_dout     : std_logic_vector (32 DOWNTO 0);
  SIGNAL s_im_doutval  : std_logic;
  SIGNAL s_im_enable   : std_logic;
  SIGNAL s_im_suspend  : std_logic;
  SIGNAL s_gap_active  : std_logic;
  SIGNAL s_trigger     : std_logic;
  SIGNAL s_fifo_empty  : std_logic;

BEGIN
  -- Process Statements
  s_clock      <= fiCLK;
  s_fifo_empty <= fifo_empty;

  run_reset  <= s_reset_evid;           -- do ext. logic reset at start of run
  event_read <= s_event_read;

  PROCESS (s_clock)
    VARIABLE fidir_d1 : std_logic := '0';
    VARIABLE fidir_d2 : std_logic := '0';
  BEGIN  -- process
    IF (s_clock'event AND (s_clock = '1')) THEN
      IF ((fidir_d2 = '1') AND (fidir_d1 = '0') AND (fiBEN_N = '0')) THEN
        s_arstn <= '0';
      ELSE
        s_arstn <= NOT reset;
      END IF;
      fidir_d2 := fidir_d1;
      fidir_d1 := fiDIR;
    END IF;
  END PROCESS;

  -- Conditional Signal Assignment
  s_pg_suspend <= NOT fiLF_N;
  s_im_suspend <= NOT fiLF_N;

  -- Selected Signal Assignment

  -- Component Instantiation Statements
  CTRL_REGS : ddl_registers PORT MAP (
    clock    => s_clock,
    arstn    => s_arstn,
    reg_data => s_reg_data,
    reg_addr => s_reg_addr,
    reg_load => s_reg_load,
    reg_lock => s_reg_lock,
    ps_reg   => s_ps_reg,
    bl_reg   => s_bl_reg,
    dt_reg   => s_dt_reg,
    fc_reg   => s_fc_reg,
    te_reg   => s_te_reg,
    xx_reg   => s_xx_reg
    );

  RX : ddl_receiver PORT MAP (
    clock       => s_clock,
    arstn       => s_arstn,
    fc_reg      => s_fc_reg,
    block_read  => s_block_read,
    block_write => s_block_write,
    event_read  => s_event_read,
    reset_evid  => s_reset_evid,
    im_din      => s_im_din,
    im_dinval   => s_im_dinval,
    reg_data    => s_reg_data,
    reg_addr    => s_reg_addr,
    reg_load    => s_reg_load,
    reg_read    => s_reg_read,
    reg_lock    => s_reg_lock,
    tid         => s_tid,
    fiD         => fiD,
    fiTEN_N     => fiTEN_N,
    fiCTRL_N    => fiCTRL_N,
    fiDIR       => fiDIR,
    fiBEN_N     => fiBEN_N,
    foBSY_N     => foBSY_N
    );

  TX : ddl_transmitter PORT MAP (
    clock      => s_clock,
    arstn      => s_arstn,
    trigger    => s_trigger,
    gap_active => s_gap_active,
    block_read => s_block_read,
    event_read => s_event_read,
    reg_read   => s_reg_read,
    reg_addr   => s_reg_addr,
    tid        => s_tid,
    ps_reg     => s_ps_reg,
    bl_reg     => s_bl_reg,
    dt_reg     => s_dt_reg,
    fc_reg     => s_fc_reg,
    te_reg     => s_te_reg,
    xx_reg     => s_xx_reg,
    pg_dout    => s_pg_dout,
    pg_doutval => s_pg_doutval,
    pg_enable  => s_pg_enable,
    im_dout    => s_im_dout,
    im_doutval => s_im_doutval,
    im_enable  => s_im_enable,
    foD        => foD,
    foTEN_N    => foTEN_N,
    foCTRL_N   => foCTRL_N,
    fiDIR      => fiDIR,
    fiBEN_N    => fiBEN_N,
    fiLF_N     => fiLF_N
    );

  PG : ddl_pattern_generator PORT MAP (
    clock       => s_clock,
    arstn       => s_arstn,
    ps_reg      => s_ps_reg,
    bl_reg      => s_bl_reg,
    xx_reg      => s_xx_reg,
    tid         => s_tid,
    enable      => s_pg_enable,
    suspend     => s_pg_suspend,
    reset_evid  => s_reset_evid,
    fifo_q      => fifo_q,
    fifo_empty  => s_fifo_empty,
    fifo_rdreq  => fifo_rdreq,
    datao       => s_pg_dout,
    datao_valid => s_pg_doutval
    );

  TRG_GEN : ddl_trigger_generator PORT MAP (
    clock      => s_clock,
    arstn      => s_arstn,
    ext_tr_in  => ext_trg,
    gap_active => s_gap_active,
    dt_reg     => s_dt_reg,
    fifo_empty => s_fifo_empty,
    trigger    => s_trigger
    );

  IM : ddl_internal_memory PORT MAP (
    clock       => s_clock,
    arstn       => s_arstn,
    block_read  => s_im_enable,
    block_write => s_block_write,
    tid         => s_tid,
    datai       => s_im_din,
    datai_valid => s_im_dinval,
    suspend     => s_im_suspend,
    datao       => s_im_dout,
    datao_valid => s_im_doutval
    );

END a;

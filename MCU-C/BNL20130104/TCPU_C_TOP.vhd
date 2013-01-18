-- $Id$
-------------------------------------------------------------------------------
-- Title      : TCPU C TOP
-- Project    : 
-------------------------------------------------------------------------------
-- File       : TCPU_C_TOP.vhd
-- Author     : 
-- Company    : 
-- Created    : 2007-11-20
-- Last update: 2012-12-20
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Top Level code for TCPU Rev C
-------------------------------------------------------------------------------
-- Copyright (c) 2007 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-11-20  1.0      jschamba        Created

-- Multiplicity output, including test output 6 Dec 08
-------------------------------------------------------------------------------

-- ********************************************************************
-- LIBRARY DEFINITIONS
-- ********************************************************************     

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera;
USE altera.altera_primitives_components.ALL;
USE work.tcpu_new_primitives.ALL;

-- ********************************************************************
-- TOP LEVEL ENTITY
-- ********************************************************************

ENTITY TCPU_C_TOP IS
  PORT
    (
      --
      -- CLOCKS
      --  
      pld_clkin1 : IN std_logic;  -- 40 Mhz clock input; pin M1 I/O bank 1

      --
      -- EXTERNAL RESET
      --
      -- Compiler option  is set to make pin B3 from MCU a full hardware reset (DEV_CLRN) active low

      --
      -- BANK 1, Schematic Sheet 3, Downstream Interface -- 
      --  

      c1_ddaisy_data    : IN std_logic;  -- N1
      c1_ddaisy_tok_out : IN std_logic;  -- N2 token in/out is from pov of TDC
      c1_dstatus        : IN std_logic_vector(1 DOWNTO 0);  -- N4, N3

      c1_ddaisy_tok_in  : OUT std_logic;  -- N6  token in/out is from pov of TDC
      c1_ddaisy_clk     : OUT std_logic;
      c1_tray_token     : OUT std_logic;
      c1_dspare_out1    : OUT std_logic;  -- P5, P4    
      c1_ser_out        : IN  std_logic;
      c1_token_out      : IN  std_logic;
      c1_strobe_out     : IN  std_logic;
      c1_flex_reset_out : OUT std_logic;  -- R7
      c1_bunch_rst      : OUT std_logic;
      c1_dconfig_out    : OUT std_logic;
      c1_trigger        : OUT std_logic;
      c1_clk_10mhz      : OUT std_logic;
      c1_dmult          : IN  std_logic_vector (3 DOWNTO 0);  -- W1 thru V1
      c1_mcu_resetb     : OUT std_logic;

      --
      -- BANK 2, Schematic Sheet 8, USB Interface --
      --
      c2_ddaisy_data    : IN  std_logic;  -- N1
      c2_ddaisy_tok_out : IN  std_logic;  -- N2 token in/out is from pov of TDC
      c2_dstatus        : IN  std_logic_vector(1 DOWNTO 0);   -- N4, N3
      c2_ddaisy_tok_in  : OUT std_logic;  -- N6  token in/out is from pov of TDC
      c2_ddaisy_clk     : OUT std_logic;  -- P1
      c2_tray_token     : OUT std_logic;
      c2_dspare_out1    : OUT std_logic;  -- P5, P4    
      c2_ser_out        : IN  std_logic;
      c2_token_out      : IN  std_logic;
      c2_strobe_out     : IN  std_logic;
      c2_flex_reset_out : OUT std_logic;  -- R7
      c2_dmult          : IN  std_logic_vector (3 DOWNTO 0);  -- W1 thru V1
      c2_bunch_rst      : OUT std_logic;
      c2_dconfig_out    : OUT std_logic;
      c2_trigger        : OUT std_logic;
      c2_clk_10mhz      : OUT std_logic;
      c2_mcu_resetb     : OUT std_logic;

--      pld_crc_error     : OUT std_logic;  -- D3. This one is assigned by Quartus for CRC error

      --
      -- BANK 3, Schematic Sheet 7 - none used

      --
      -- BANK 4, Schematic Sheet 6, H2 and H3 Interface -- 
      --  
      trig_clk_in_clk : IN  std_logic;
      trig_clk_in     : IN  std_logic;
      trig_data_out   : OUT std_logic_vector(4 DOWNTO 0);

      -- ***** new pins for TCPU-C

      pll_bwsel    : OUT std_logic_vector(1 DOWNTO 0) := "00";
      pll_frqsel   : OUT std_logic_vector(2 DOWNTO 0) := "000";
      pll_infrqsel : OUT std_logic_vector(2 DOWNTO 0) := "010";
      pll_bwboost  : OUT std_logic                    := '0';

      dh_actv   : IN std_logic;
      PLL_RESET : IN std_logic;
      cal_actv  : IN std_logic;
      PLL_LOS   : IN std_logic;

      --
      -- BANK 5, Schematic Sheet 4 -- 
      --
      tx_d     : OUT std_logic_vector(17 DOWNTO 0);
      ext_test : IN  std_logic_vector(4 DOWNTO 1);

      --
      -- BANK 6, Schematic Sheet 2, Upstream Interface -- 
      --
      ser_rec_clk : IN  std_logic;
      th_local_le : OUT std_logic;
      th_line_le  : OUT std_logic;
      th_den      : OUT std_logic;
      th_sync     : OUT std_logic;
      th_tpwdnb   : OUT std_logic;
      th_tclk     : OUT std_logic;
      rx_d        : IN  std_logic_vector(17 DOWNTO 0);
      th_ren      : OUT std_logic;
      th_lockb    : IN  std_logic;
      th_rpwdnb   : OUT std_logic;
      th_refclk   : OUT std_logic;

      --
      -- BANK 7, Schematic Sheet 1, MCU and Test Interface -- 
      --
      mcu_pld_data : INOUT std_logic_vector (7 DOWNTO 0);  -- R14 thru V14
      mcu_pld_ctrl : IN    std_logic_vector (4 DOWNTO 0);  -- W14 thru Y14


      -- test_at_J9                : OUT std_logic; -- AA20
      test_at_J9 : IN std_logic;        -- AA20


      pld_pushbutton : IN  std_logic;  -- AB17   -- input is LOW when button is pushed
      pld_led        : OUT std_logic;   -- AB20

      --
      -- BANK 8, Schematic Sheet 1, MCU Interface -- 
      --
      mcu_pld_spare : IN std_logic_vector(2 DOWNTO 0);  -- U9, U8, T11

      test18 : IN  std_logic;
      test17 : OUT std_logic;
      test16 : IN  std_logic;
      test15 : OUT std_logic;
      test14 : IN  std_logic;
      test13 : OUT std_logic;
      test12 : IN  std_logic;
      test11 : OUT std_logic;
      test10 : IN  std_logic;
      test9  : OUT std_logic;
      test8  : IN  std_logic;
      test7  : OUT std_logic;
      test6  : OUT std_logic;
      test5  : OUT std_logic;
      test4  : OUT std_logic;
      test3  : OUT std_logic;
      test2  : OUT std_logic;
      test1  : OUT std_logic;

      pld_serin  : IN  std_logic;       -- AB4
      pld_serout : OUT std_logic        -- AB5
      );

END TCPU_C_TOP;  -- end.entity

-- ********************************************************************
-- TOP LEVEL ARCHITECTURE
-- ********************************************************************

ARCHITECTURE a OF TCPU_C_TOP IS

  CONSTANT TCPU_VERSION : std_logic_vector := x"8f";

  TYPE SState_type IS (s1, s2, s3, s4);
  SIGNAL sState, sStateNext : SState_type;

  COMPONENT pll
    PORT
      (
        inclk0 : IN  std_logic := '0';
        c0     : OUT std_logic;
        c1     : OUT std_logic;
        locked : OUT std_logic
        );
  END COMPONENT;

  COMPONENT ser_rdo IS
    PORT (
      strb_out       : IN  std_logic;
      token_out      : IN  std_logic;
      ser_out        : IN  std_logic;
      rdout_en       : IN  std_logic;
      SW             : IN  std_logic;
      reset          : IN  std_logic;
      token_in       : OUT std_logic;
      rdo_32b_data   : OUT std_logic_vector (31 DOWNTO 0);
      rdo_data_valid : OUT std_logic);
  END COMPONENT ser_rdo;

  COMPONENT FIFO_RD2 IS
    PORT (
      CLK        : IN  std_logic;
      MCU_STROBE : IN  std_logic;
      RD_ADR14   : IN  std_logic;
      RESET      : IN  std_logic;
      OUT_HI     : OUT std_logic);
  END COMPONENT FIFO_RD2;

  COMPONENT serdes_if IS
    PORT (
      clk        : IN  std_logic;
      serdata_in : IN  std_logic_vector (17 DOWNTO 0);
      rxd        : IN  std_logic_vector (17 DOWNTO 0);
      txd        : OUT std_logic_vector (17 DOWNTO 0);
      den        : OUT std_logic;
      ren        : OUT std_logic;
      sync       : OUT std_logic;
      tpwdn_n    : OUT std_logic;
      rpwdn_n    : OUT std_logic;
      lock_n     : IN  std_logic;
      rclk       : IN  std_logic;
      areset_n   : IN  std_logic;
      ch_ready   : OUT std_logic;
      pll_locked : IN  std_logic;
      trigger    : OUT std_logic;
      po_state   : OUT std_logic_vector(2 DOWNTO 0);
      bunch_rst  : OUT std_logic
      );
  END COMPONENT serdes_if;

  COMPONENT serdes_serializer IS
    PORT (
      clk20mhz     : IN  std_logic;
      areset_n     : IN  std_logic;
      txfifo_empty : IN  std_logic;
      txfifo_q     : IN  std_logic_vector (31 DOWNTO 0);
      txfifo_rdreq : OUT std_logic;
      serdes_data  : OUT std_logic_vector (17 DOWNTO 0));
  END COMPONENT serdes_serializer;

  --*****************************************************************************************************
  -- multiplicity components

  COMPONENT adder_4_by_4_bits
    PORT
      (
        dataa  : IN  std_logic_vector (3 DOWNTO 0);
        datab  : IN  std_logic_vector (3 DOWNTO 0);
        cout   : OUT std_logic;
        result : OUT std_logic_vector (3 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT PLL_multiplier_4x
    PORT
      (
        inclk0 : IN  std_logic := '0';
        c0     : OUT std_logic;         -- input divided by 4
        c1     : OUT std_logic          -- input divided by 4, different phase
        );
  END COMPONENT;

  COMPONENT REG_5BIT
    PORT
      (
        aclr  : IN  std_logic;
        clock : IN  std_logic;
        data  : IN  std_logic_vector (4 DOWNTO 0);
        q     : OUT std_logic_vector (4 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT Counter_5bit
    PORT
      (
        aclr  : IN  std_logic;
        clock : IN  std_logic;
        q     : OUT std_logic_vector (4 DOWNTO 0)
        );
  END COMPONENT;

  --*****************************************************************************************************
  -- end of multiplicity components
  --
  -- ****************************************************************************************************

  SIGNAL clk_40mhz       : std_logic;
  SIGNAL clk_20mhz       : std_logic;
  SIGNAL pll_240mhz      : std_logic;
  SIGNAL pll_20mhz       : std_logic;
  SIGNAL pll_locked      : std_logic;
  SIGNAL mcu_strobe      : std_logic;
  SIGNAL mcu_dataOutEn   : std_logic;
  SIGNAL mcu_dataInEn    : std_logic;
  SIGNAL mcu_input_data  : std_logic_vector (7 DOWNTO 0);
  SIGNAL mcu_output_data : std_logic_vector (7 DOWNTO 0);
  SIGNAL mcu_read        : std_logic;
  SIGNAL mcu_addr        : std_logic_vector (3 DOWNTO 0);
  SIGNAL addr_eq         : std_logic_vector (15 DOWNTO 0);
  SIGNAL config0_data    : std_logic_vector (7 DOWNTO 0);
  SIGNAL config1_data    : std_logic_vector (7 DOWNTO 0);
  SIGNAL config2_data    : std_logic_vector (7 DOWNTO 0);
  SIGNAL config3_data    : std_logic_vector (7 DOWNTO 0);
  SIGNAL config7_data    : std_logic_vector (7 DOWNTO 0);
  SIGNAL config8_data    : std_logic_vector (7 DOWNTO 0);
  SIGNAL config9_data    : std_logic_vector (7 DOWNTO 0);
  SIGNAL config12_data   : std_logic_vector (7 DOWNTO 0);
  SIGNAL config14_data   : std_logic_vector (7 DOWNTO 0);
  SIGNAL status_data     : std_logic_vector (7 DOWNTO 0);
  SIGNAL load_config0    : std_logic;
  SIGNAL load_config1    : std_logic;
  SIGNAL load_config2    : std_logic;
  SIGNAL load_config3    : std_logic;
  SIGNAL load_config7    : std_logic;
  SIGNAL load_config8    : std_logic;
  SIGNAL load_config9    : std_logic;
  SIGNAL load_config12   : std_logic;
  SIGNAL load_config14   : std_logic;
  SIGNAL mcu_fifo_level  : std_logic_vector(5 DOWNTO 0);
  SIGNAL mcu_fifo_status : std_logic_vector (7 DOWNTO 0);
  SIGNAL mcu_fifo_empty  : std_logic;
  SIGNAL mcu_fifo_full   : std_logic;
  SIGNAL mcu_fifo_parity : std_logic;
  SIGNAL mcu_fifo_rdreq  : std_logic;
  SIGNAL mcu_fifo_wrreq  : std_logic;
  SIGNAL mcu_fifo_q      : std_logic_vector (31 DOWNTO 0);
  SIGNAL addr_equ        : std_logic_vector(15 DOWNTO 0);

  SIGNAL c1Sel_strob_out   : std_logic;
  SIGNAL c1Sel_token_out   : std_logic;
  SIGNAL c1Sel_ser_out     : std_logic;
  SIGNAL c1_rdout_en       : std_logic;
  SIGNAL c1_sm_reset       : std_logic;
  SIGNAL c1Sel_token_in    : std_logic;
  SIGNAL c1_rdo_data       : std_logic_vector (31 DOWNTO 0);
  SIGNAL c1_rdo_data_valid : std_logic;
  SIGNAL c1_fifo_rdreq     : std_logic;
  SIGNAL c1_fifo_aclr      : std_logic;
  SIGNAL c1_fifo_empty     : std_logic;
  SIGNAL c1_fifo_full      : std_logic;
  SIGNAL c1_fifo_q         : std_logic_vector (31 DOWNTO 0);

  SIGNAL c2Sel_strob_out   : std_logic;
  SIGNAL c2Sel_token_out   : std_logic;
  SIGNAL c2Sel_ser_out     : std_logic;
  SIGNAL c2_rdout_en       : std_logic;
  SIGNAL c2_sm_reset       : std_logic;
  SIGNAL c2Sel_token_in    : std_logic;
  SIGNAL c2_rdo_data       : std_logic_vector (31 DOWNTO 0);
  SIGNAL c2_rdo_data_valid : std_logic;
  SIGNAL c2_fifo_rdreq     : std_logic;
  SIGNAL c2_fifo_aclr      : std_logic;
  SIGNAL c2_fifo_empty     : std_logic;
  SIGNAL c2_fifo_full      : std_logic;
  SIGNAL c2_fifo_q         : std_logic_vector (31 DOWNTO 0);

  SIGNAL read_from_adr14 : std_logic;
  SIGNAL sm_reset        : std_logic;
  SIGNAL reg_clr         : std_logic;
  SIGNAL buf_clr         : std_logic;
  SIGNAL test_pls_bits   : std_logic_vector (19 DOWNTO 0);
  SIGNAL internal_pulser : std_logic;
  SIGNAL test_pulse_raw  : std_logic;
  SIGNAL test_pulse      : std_logic;
  SIGNAL dff1_q          : std_logic;
  SIGNAL dff2_q          : std_logic;
  SIGNAL dff3_q          : std_logic;
  SIGNAL shift_out       : std_logic;
  SIGNAL trigger_delay   : std_logic_vector(5 DOWNTO 0);

  SIGNAL fifoSmReset     : std_logic;
  SIGNAL finalFifo_rdreq : std_logic;
  SIGNAL finalFifo_aclr  : std_logic;
  SIGNAL finalFifo_wrreq : std_logic;
  SIGNAL finalFifo_data  : std_logic_vector (31 DOWNTO 0);

  SIGNAL serdes_trigger  : std_logic;
  SIGNAL trigger_pulse   : std_logic;
  SIGNAL serdes_areset_n : std_logic;
  SIGNAL serdes_ready    : std_logic;
  SIGNAL serdes_b_rst    : std_logic;
  SIGNAL ser_tx_clk      : std_logic;

  SIGNAL serdesFifo_rdreq : std_logic;
  SIGNAL serdesFifo_aclr  : std_logic;
  SIGNAL serdesFifo_empty : std_logic;
  SIGNAL serdesFifo_q     : std_logic_vector (31 DOWNTO 0);
  SIGNAL s_serdes_data    : std_logic_vector(17 DOWNTO 0);

  SIGNAL s_po_state : std_logic_vector(2 DOWNTO 0);
  
-- ******************** multiplicity signals
  SIGNAL s_rhic_clk   : std_logic;
  SIGNAL s_c1_trigger : std_logic;
  SIGNAL s_c2_trigger : std_logic;

  SIGNAL s_mult_count : std_logic_vector (4 DOWNTO 0);
  SIGNAL s_ctr_reset  : std_logic;

  SIGNAL multiplicity_carry            : std_logic;
  SIGNAL rhic_16x_locked, dummy        : std_logic;
  SIGNAL phase1_10mhz, phase2_10mhz    : std_logic;
  SIGNAL c1_dmult_inv, c2_dmult_inv    : std_logic_vector(3 DOWNTO 0);
  SIGNAL final_sum, trig_data_from_mux : std_logic_vector(4 DOWNTO 0);
  SIGNAL trig_data_reg1                : std_logic_vector(4 DOWNTO 0);

  SIGNAL sel_phase_of_mult_clk_to_tray   : std_logic_vector(3 DOWNTO 0);
  SIGNAL sel_phase_of_final_mult_reg_clk : std_logic_vector(3 DOWNTO 0);
  SIGNAL rhic_clk_16x, rhic_clk_1x       : std_logic;
  SIGNAL mult_clk_to_tray                : std_logic;
  SIGNAL final_reg_clk_for_mult          : std_logic;
  SIGNAL delayed_rhic_clk                : std_logic_vector(15 DOWNTO 0);
  SIGNAL clock_delay                     : std_logic_vector(3 DOWNTO 0);
  SIGNAL multiplicity_out_sel            : std_logic;

----------------------------------------------------------

BEGIN

  -- these signals have no source, so set them to some default now
  c2_mcu_resetb     <= '1';
  c1_mcu_resetb     <= '1';
  pld_serout        <= '0';
  c1_ddaisy_clk     <= '0';
  c1_dspare_out1    <= '0';
  c1_flex_reset_out <= '0';
  c1_dconfig_out    <= '0';
  c2_ddaisy_clk     <= '0';
  c2_dspare_out1    <= '0';
  c2_flex_reset_out <= '0';
  c2_dconfig_out    <= '0';
  reg_clr           <= '0';
  pll_bwsel         <= "00";
  pll_frqsel        <= "000";
  pll_infrqsel      <= "010";
  pll_bwboost       <= '0';

  -- test header:
  test17 <= '0';
  test15 <= '0';
  test13 <= '0';
  test11 <= '0';
  test9  <= '0';
  test7  <= '0';
  test6  <= '0';
  test5  <= '0';
--  test4 <= s_c1_trigger;
  test4  <= '0';
  test3  <= '0';
  test2  <= '0';
--  test1 <= pld_clkin1;
  test1  <= '0';

  pld_led <= NOT pll_locked;

  -- PLL
  pll_instance : pll PORT MAP (
    inclk0 => pld_clkin1,
    c0     => pll_240mhz,
    c1     => pll_20mhz,
    locked => pll_locked);

  -- GLOBAL CLOCK BUFFER
  global_clk_buffer1 : global PORT MAP (a_in => pld_clkin1, a_out => clk_40mhz);
  global_clk_buffer2 : global PORT MAP (a_in => pll_20mhz, a_out => clk_20mhz);

--**********************************************************************************
-- Control for serial THUB link
--********************************************************************************** 
  ser_tx_clk <= clk_20mhz;
--  ser_tx_clk  <= ser_rec_clk;

  th_tclk     <= ser_tx_clk;
  th_refclk   <= clk_20mhz;
  th_local_le <= '0';                   -- DISABLE LOCAL LOOPBACK
  th_line_le  <= '0';                   -- DISABLE LINE LOOPBACK

  serdes_areset_n <= config2_data(3);   -- control this from CANbus
  
  serdes_if_inst : serdes_if PORT MAP (
    clk        => clk_40mhz,
    serdata_in => s_serdes_data,
    rxd        => rx_d,
    txd        => tx_d,
    den        => th_den,
    ren        => th_ren,
    sync       => th_sync,
    tpwdn_n    => th_tpwdnb,
    rpwdn_n    => th_rpwdnb,
    lock_n     => th_lockb,
    rclk       => ser_rec_clk,
    areset_n   => serdes_areset_n,
    ch_ready   => serdes_ready,
    pll_locked => pll_locked,
    trigger    => serdes_trigger,
    po_state   => s_po_state,
    bunch_rst  => serdes_b_rst
    );

------------------------------------------------------------------------------------
--      MCU INTERFACE : BIDIR BUFFER AND ADDRESS DECODE
------------------------------------------------------------------------------------

  mcu_read <= mcu_pld_ctrl(4);
  mcu_addr <= mcu_pld_ctrl(3 DOWNTO 0);

  -- synchronize mcu inputs
  sync_dff : DFF PORT MAP (
    d    => mcu_pld_spare(1),
    clk  => clk_40mhz,
    clrn => '1',
    prn  => '1',
    q    => mcu_strobe);

  -- BIDIRECTIONAL BUFFER FOR MCU DATA BUS

  mcu_dataOutEn <= mcu_strobe AND mcu_read;
  mcu_dataInEn  <= NOT mcu_dataOutEn;

  MCU_bidir_bus_buffer : lpm_bustri
    GENERIC MAP (
      lpm_type  => "LPM_BUSTRI",
      lpm_width => 8)
    PORT MAP (
      data     => mcu_output_data,
      enabledt => mcu_dataOutEn,
      enabletr => mcu_dataInEn,
      result   => mcu_input_data,
      tridata  => mcu_pld_data);

----------------------------------------------------------------------------------

  MCU_address_decoder : lpm_decode
    GENERIC MAP (
      lpm_decodes  => 16,
      lpm_pipeline => 1,
      lpm_type     => "LPM_DECODE",
      lpm_width    => 4)
    PORT MAP (
      clock  => clk_40mhz,
      data   => mcu_addr,
      enable => mcu_strobe,
      eq     => addr_equ
      );

-- ********************************************************************************
--      MCU INTERFACE : CONFIGURATION REGISTERS
--      Use same registers that Lloyd used
--*********************************************************************************
  
  load_config0  <= (NOT (mcu_read)) AND mcu_strobe AND addr_equ(0);
  load_config1  <= (NOT (mcu_read)) AND mcu_strobe AND addr_equ(1);
  load_config2  <= (NOT (mcu_read)) AND mcu_strobe AND addr_equ(2);
  load_config3  <= (NOT (mcu_read)) AND mcu_strobe AND addr_equ(3);
  load_config8  <= (NOT (mcu_read)) AND mcu_strobe AND addr_equ(8);
  load_config9  <= (NOT (mcu_read)) AND mcu_strobe AND addr_equ(9);
  load_config14 <= (NOT (mcu_read)) AND mcu_strobe AND addr_equ(14);

  -- Configuration Register Address 0x0
  config0_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8)
    PORT MAP (
      clock  => clk_40mhz,
      data   => mcu_input_data,
      enable => load_config0,
      aclr   => reg_clr,
      q      => config0_data);

  -- Configuration Register Address 0x1
  config1_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8)
    PORT MAP (
      clock  => clk_40mhz,
      data   => mcu_input_data,
      enable => load_config1,
      aclr   => reg_clr,
      q      => config1_data);

  -- use this  register to reset all state machines (data = 0x1)
  -- and clear buffers (data = 0x2)
  sm_reset <= config1_data(0);
  buf_clr  <= config1_data(1);

  -- Configuration Register Address 0x2
  -- use to enable readout (data = 0x1)
  -- and to switch to serdes-triggers (data = 0x2)
  -- turn off CANbus data packets (data = 0x4)
  -- turn on Serdes link (data = 0x8)
  config2_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8)
    PORT MAP (
      clock  => clk_40mhz,
      data   => mcu_input_data,
      enable => load_config2,
      aclr   => reg_clr,
      q      => config2_data);

  -- Configuration Register Address 0x3
  config3_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8)
    PORT MAP (
      clock  => clk_40mhz,
      data   => mcu_input_data,
      enable => load_config3,
      aclr   => reg_clr,
      q      => config3_data);

-- Configuration Register Address 0x9
  config9_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8)
    PORT MAP (
      clock  => clk_40mhz,
      data   => mcu_input_data,
      enable => load_config9,
      aclr   => reg_clr,
      q      => config9_data);

  -- Configuration register address 0xc
  -- 4 lsbs are rhic clk delay selection: "clock_delay"
  config8_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8)
    PORT MAP (
      clock  => clk_40mhz,
      data   => mcu_input_data,
      enable => load_config8,
      aclr   => reg_clr,
      q      => config8_data);         

  -- Configuration Register Address 0xe
  -- used for internal pulser (data = 0x8 - 0xf)
  -- and bunch reset (data = 0x10)
  -- switch to AUX path for readout (data = 0x80)
  config14_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8)
    PORT MAP (
      clock  => clk_40mhz,
      data   => mcu_input_data,
      enable => load_config14,
      aclr   => reg_clr,
      q      => config14_data);             

  -- READOUT MUX FOR DATA GOING FROM FPGA TO MCU

--  WITH config0_data(1) SELECT
--    mcu_fifo_empty <=
--    c1_fifo_empty WHEN '0',
--    c2_fifo_empty WHEN OTHERS;

--  WITH config0_data(1) SELECT
--    mcu_fifo_full <=
--    c1_fifo_full WHEN '0',
--    c2_fifo_full WHEN OTHERS;

--  WITH config0_data(1) SELECT
--    mcu_fifo_q <=
--    c1_fifo_q WHEN '0',
--    c2_fifo_q WHEN OTHERS;

--  finalFifo_rdreq <= mcu_fifo_rdreq;
--  mcu_fifo_q      <= finalFifo_q;
--  mcu_fifo_empty  <= finalFifo_empty;
--  mcu_fifo_full   <= finalFifo_full;

  mcu_fifo_parity <= '0';
  mcu_fifo_level  <= (OTHERS => '0');

  mcu_fifo_status(7)          <= mcu_fifo_empty;
  mcu_fifo_status(6)          <= mcu_fifo_full;
  mcu_fifo_status(5)          <= mcu_fifo_parity;
  mcu_fifo_status(4 DOWNTO 0) <= mcu_fifo_level(4 DOWNTO 0);

  -- status_data <= config3_data(7 DOWNTO 2) & serdes_ready & th_lockb;
  status_data <= '0' & s_po_state & "00" & serdes_ready & th_lockb;
  WITH mcu_addr SELECT
    mcu_output_data <=
    config0_data             WHEN x"0",
    config1_data             WHEN x"1",
    config2_data             WHEN x"2",
    status_data              WHEN x"3",
    TCPU_VERSION             WHEN x"7",
    config8_data             WHEN x"8",
    config9_data             WHEN x"9",
    mcu_fifo_q(7 DOWNTO 0)   WHEN x"b",
    mcu_fifo_q(15 DOWNTO 8)  WHEN x"c",
    mcu_fifo_q(23 DOWNTO 16) WHEN x"d",
    mcu_fifo_q(31 DOWNTO 24) WHEN x"e",
    mcu_fifo_status          WHEN x"f",
    "00000000" WHEN OTHERS;

  read_from_adr14 <= mcu_read AND addr_equ(14);

  --- sends 1 clock pulse at end of input pulse
  output_fifo_read_after_MCU_reads_msbyte : fifo_rd2 PORT MAP (
    clk        => clk_40mhz,
    mcu_strobe => mcu_strobe,
    rd_adr14   => read_from_adr14,
    reset      => sm_reset,
    out_hi     => mcu_fifo_rdreq);


--  c1_fifo_rdreq <= mcu_fifo_rdreq AND (NOT config0_data(1));
--  c2_fifo_rdreq <= mcu_fifo_rdreq AND config0_data(1);

-- END OF CONFIGURATION REGISTERS ****************************************

--------------------------------------------------------------------------
--      SERIAL READOUT FROM TDCs
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--      Trigger signal derivation
--------------------------------------------------------------------------
  -- internal pulser
  -- purpose: counter to generate internal pulser of selectable frequency
  -- type   : sequential
  -- inputs : clk_40mhz, sm_reset
  -- outputs: test_pls_bits
  PROCESS (clk_40mhz, sm_reset) IS
  BEGIN
    IF sm_reset = '1' THEN              -- asynchronous reset (active high)
      test_pls_bits <= (OTHERS => '0');
    ELSIF clk_40mhz'event AND clk_40mhz = '1' THEN  -- rising clock edge
      test_pls_bits <= test_pls_bits + 1;
    END IF;
  END PROCESS;

  -- this determines the internal pulser frequency:
  WITH config14_data(2 DOWNTO 0) SELECT
    internal_pulser <=
    test_pls_bits(19) WHEN "000",
    test_pls_bits(18) WHEN "001",
    test_pls_bits(17) WHEN "010",
    test_pls_bits(16) WHEN "011",
    test_pls_bits(15) WHEN "100",
    test_pls_bits(14) WHEN "101",
    test_pls_bits(13) WHEN "110",
    test_pls_bits(12) WHEN OTHERS;

  -- MUX for trigger pulse
  WITH config14_data(3) SELECT
    test_pulse_raw <=
    test_at_j9      WHEN '0',           -- J9 input
    internal_pulser WHEN OTHERS;        -- internal pulser

  -- now sync and shorten with a chain of DFFs
  ff : PROCESS (clk_40mhz)
  BEGIN  -- PROCESS ff
    IF clk_40mhz'event AND clk_40mhz = '1' THEN
      dff1_q <= test_pulse_raw;
      dff2_q <= dff1_q;
      dff3_q <= dff2_q;
    END IF;
  END PROCESS ff;

  test_pulse <= dff2_q AND (NOT dff3_q);

  -- select between internal/test-pulse triggers and Serdes triggers
  WITH config2_data(1) SELECT
    trigger_pulse <=
    test_pulse     WHEN '0',
    serdes_trigger WHEN OTHERS;

  -- shift register to delay the trigger pulse phase relative to the 40MHz clock:
  -- use trailing edge to move trigger by another half 240MHz clock cycle 
  trigger_shiftreg : lpm_shiftreg GENERIC MAP (
    lpm_direction => "RIGHT",
    lpm_type      => "LPM_SHIFTREG",
    lpm_width     => 6)
    PORT MAP (
      sclr    => sm_reset,
      clock   => NOT pll_240mhz,
      shiftin => trigger_pulse,
      q       => trigger_delay);
  -- trigger_delay vector provides 6 different phases of trigger pulse
--  s_c1_trigger <= trigger_delay(0);
--  s_c2_trigger <= trigger_delay(0);

  -- changed this delay from "0" to "2" in version 0x88
  -- because the start detector didn't work with the
  -- earlier delay
  s_c1_trigger <= trigger_delay(2);
  s_c2_trigger <= trigger_delay(2);

---------------------------------------------------------------------------
-- Muxes for AUX / NORMAL serial readout for cable1
---------------------------------------------------------------------------          

  WITH config14_data(7) SELECT
    c1Sel_ser_out <=
    c1_ddaisy_data WHEN '1',            -- signal from FPGA
    c1_ser_out     WHEN OTHERS;         -- signal from Aux path

  WITH config14_data(7) SELECT
    c1Sel_token_out <=
    c1_ddaisy_tok_out WHEN '1',         -- signal from FPGA
    c1_token_out      WHEN OTHERS;      -- signal from Aux path

  WITH config14_data(7) SELECT
    c1Sel_strob_out <=
    c1_dstatus(0) WHEN '1',             -- signal from FPGA
    c1_strobe_out WHEN OTHERS;          -- signal from Aux path


---------------------------------------------------------------------------
-- CABLE 1 READOUT
---------------------------------------------------------------------------

  c1_trigger       <= s_c1_trigger;
  c1_ddaisy_tok_in <= c1Sel_token_in AND config14_data(7);  -- signal to FPGA
  c1_tray_token    <= c1Sel_token_in AND (NOT config14_data(7));  -- signal to Aux path
  c1_bunch_rst     <= config14_data(4) OR serdes_b_rst;
  c1_sm_reset      <= sm_reset;
  c1_rdout_en      <= config2_data(0) AND trigger_pulse;
  
  c1_ser_rdo_inst : ser_rdo PORT MAP (
    strb_out       => c1Sel_strob_out,
    token_out      => c1Sel_token_out,
    ser_out        => c1Sel_ser_out,
    rdout_en       => c1_rdout_en,
    SW             => '1',              -- TDIG boards 4 - 7
    reset          => c1_sm_reset,
    token_in       => c1Sel_token_in,
    rdo_32b_data   => c1_rdo_data,
    rdo_data_valid => c1_rdo_data_valid);

  c1_fifo_aclr <= buf_clr;
  cable1_fifo : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_hint               => "MAXIMIZE_SPEED=5",
      lpm_numwords           => 1024,
      lpm_showahead          => "ON",
      lpm_type               => "dcfifo",
      lpm_width              => 32,
      lpm_widthu             => 10,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 4,
      underflow_checking     => "ON",
      wrsync_delaypipe       => 4)
    PORT MAP (
      wrclk   => c1Sel_strob_out,
      rdreq   => c1_fifo_rdreq,
      aclr    => c1_fifo_aclr,
      rdclk   => clk_40mhz,
      wrreq   => c1_rdo_data_valid,
      data    => c1_rdo_data,
      rdempty => c1_fifo_empty,
      -- rdfull  => c1_fifo_full,
      q       => c1_fifo_q
      );


---------------------------------------------------------------------------
-- Muxes for AUX / NORMAL serial readout for cable2
---------------------------------------------------------------------------          

  WITH config14_data(7) SELECT
    c2Sel_ser_out <=
    c2_ddaisy_data WHEN '1',            -- signal from FPGA
    c2_ser_out     WHEN OTHERS;         -- signal from Aux path

  WITH config14_data(7) SELECT
    c2Sel_token_out <=
    c2_ddaisy_tok_out WHEN '1',         -- signal from FPGA
    c2_token_out      WHEN OTHERS;      -- signal from Aux path

  WITH config14_data(7) SELECT
    c2Sel_strob_out <=
    c2_dstatus(0) WHEN '1',             -- signal from FPGA
    c2_strobe_out WHEN OTHERS;          -- signal from Aux path


---------------------------------------------------------------------------
-- CABLE 2 READOUT
---------------------------------------------------------------------------
  
  c2_trigger       <= s_c2_trigger;
  c2_ddaisy_tok_in <= c2Sel_token_in AND config14_data(7);  -- signal to FPGA
  c2_tray_token    <= c2Sel_token_in AND (NOT config14_data(7));  -- signal to Aux path
  c2_bunch_rst     <= config14_data(4) OR serdes_b_rst;
  c2_sm_reset      <= sm_reset;
  c2_rdout_en      <= config2_data(0) AND trigger_pulse;
  
  c2_ser_rdo_inst : ser_rdo PORT MAP (
    strb_out       => c2Sel_strob_out,
    token_out      => c2Sel_token_out,
    ser_out        => c2Sel_ser_out,
    rdout_en       => c2_rdout_en,
    SW             => '0',              -- TDIG boards 0 - 3
    reset          => c2_sm_reset,
    token_in       => c2Sel_token_in,
    rdo_32b_data   => c2_rdo_data,
    rdo_data_valid => c2_rdo_data_valid);

  c2_fifo_aclr <= buf_clr;
  cable2_fifo : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_hint               => "MAXIMIZE_SPEED=5",
      lpm_numwords           => 1024,
      lpm_showahead          => "ON",
      lpm_type               => "dcfifo",
      lpm_width              => 32,
      lpm_widthu             => 10,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 4,
      underflow_checking     => "ON",
      wrsync_delaypipe       => 4)
    PORT MAP (
      wrclk   => c2Sel_strob_out,
      rdreq   => c2_fifo_rdreq,
      aclr    => c2_fifo_aclr,
      rdclk   => clk_40mhz,
      wrreq   => c2_rdo_data_valid,
      data    => c2_rdo_data,
      rdempty => c2_fifo_empty,
      -- rdfull  => c2_fifo_full,
      q       => c2_fifo_q
      );

---------------------------------------------------------------------------
-- Final FIFO for MCU or THUB to read
---------------------------------------------------------------------------
  
  finalFifo_aclr <= buf_clr;

  -- this let's one turn off CANbus data packets
  WITH config2_data(2) SELECT
    mcu_fifo_wrreq <=
    finalFifo_wrreq WHEN '0',
    '0' WHEN OTHERS;

  mcu_fifo : scfifo
    GENERIC MAP (
      add_ram_output_register => "ON",
      intended_device_family  => "Cyclone II",
      lpm_numwords            => 512,
      lpm_showahead           => "ON",
      lpm_type                => "scfifo",
      lpm_width               => 32,
      lpm_widthu              => 9,
      overflow_checking       => "ON",
      underflow_checking      => "ON",
      use_eab                 => "ON"
      )
    PORT MAP (
      rdreq => mcu_fifo_rdreq,
      aclr  => finalFifo_aclr,
      clock => clk_40mhz,
      wrreq => mcu_fifo_wrreq,
      data  => finalFifo_data,
      empty => mcu_fifo_empty,
      q     => mcu_fifo_q,
      full  => mcu_fifo_full
      );

  serdes_fifo : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_hint               => "MAXIMIZE_SPEED=5",
      lpm_numwords           => 2048,
      lpm_showahead          => "ON",
      lpm_type               => "dcfifo",
      lpm_width              => 32,
      lpm_widthu             => 11,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 4,
      underflow_checking     => "ON",
      wrsync_delaypipe       => 4)
    PORT MAP (
      wrclk   => clk_40mhz,
      wrreq   => finalFifo_wrreq,
      rdreq   => serdesFifo_rdreq,
      rdclk   => ser_tx_clk,
      aclr    => serdesFifo_aclr,
      data    => finalFifo_data,
      rdempty => serdesFifo_empty,
      q       => serdesFifo_q
      );

  -- serdes FIFO cleared when Serdes is not connected and at every event
  serdesFifo_aclr <= NOT serdes_ready OR trigger_pulse;

  -- FIFO state machine reset with configuration reset and at every event
  fifoSmReset <= sm_reset OR trigger_pulse;

  -- Process to control data from c1 or c2 FIFO to Final FIFO
  PROCESS (clk_40mhz, fifoSmReset) IS
  BEGIN  -- PROCESS
    IF fifoSmReset = '1' THEN           -- asynchronous reset (active high)
      sState          <= s1;
      c1_fifo_rdreq   <= '0';
      c2_fifo_rdreq   <= '0';
      finalFifo_wrreq <= '0';
    ELSIF clk_40mhz'event AND clk_40mhz = '0' THEN  -- falling clock edge
      c1_fifo_rdreq   <= '0';
      c2_fifo_rdreq   <= '0';
      finalFifo_wrreq <= '0';
      finalFifo_data  <= (OTHERS => '1');

      CASE sState IS                    -- wait until c1 fifo is not empty
        WHEN s1 =>
          IF c1_fifo_empty = '0' THEN
            sState <= s2;
          END IF;

        WHEN s2 =>                      -- transfer c1 fifo to final fifo
          c1_fifo_rdreq   <= '1';
          finalFifo_wrreq <= NOT c1_fifo_empty;
          finalFifo_data  <= c1_fifo_q;

          IF c1_fifo_empty = '1' THEN   -- go back to s1 if fifo empty
            sState <= s1;
          ELSIF c1_fifo_q(31 DOWNTO 28) = x"e" THEN  -- go on to c2 fifo
            sState <= s3;
          END IF;

        WHEN s3 =>                      -- wait until c2 fifo is not empty
          IF c2_fifo_empty = '0' THEN
            sState <= s4;
          END IF;

        WHEN s4 =>                      -- transfer c2 fifo to final fifo
          c2_fifo_rdreq   <= '1';
          finalFifo_wrreq <= NOT c2_fifo_empty;
          finalFifo_data  <= c2_fifo_q;

          IF c2_fifo_empty = '1' THEN   -- go back to s3 if fifo empty
            sState <= s3;
          ELSIF c2_fifo_q(31 DOWNTO 28) = x"e" THEN  -- go back to c1 fifo
            sState <= s1;
          END IF;
      END CASE;
    END IF;
  END PROCESS;

  -- "Serialize" the data from the Serdes FIFO and send it over SerDes to THUB
  serdes_ser_inst : serdes_serializer PORT MAP (
    clk20mhz     => ser_tx_clk,
    areset_n     => serdes_ready,
    txfifo_empty => serdesFifo_empty,
    txfifo_q     => serdesFifo_q,
    txfifo_rdreq => serdesFifo_rdreq,
    serdes_data  => s_serdes_data);

---------------------------------------------------------------------------
-- MULTIPLICITY
---------------------------------------------------------------------------
  -- This PLL uses the 40 mhz clock to generate a fake rhic clk in the absence of the 10mhz
  -- from the multiplicity connector

  -- This PLL is for actual use when the rhic clk is available on the multiplicity connector 
  PLL_1x_and_16x_inst : PLL_1x_and_16x PORT MAP (
    inclk0 => trig_clk_in_clk,  -- rhic clk from multiplicity connector (J16)
    c0     => rhic_clk_1x,              -- 1x output 
    c1     => rhic_clk_16x);    -- 16x output with 0 deg phase shift           

  clock_delay_shift_register : SHIFT_REG_16BITS PORT MAP (
    aclr    => '0',
    clock   => rhic_clk_16x,
    shiftin => rhic_clk_1x,
    q       => delayed_rhic_clk
    );

  -- select phase of multiplicity clock to tray
  clk_to_tray_select : MUX_16TO1 PORT MAP (
    data0  => delayed_rhic_clk(15),
    data1  => delayed_rhic_clk(14),
    data2  => delayed_rhic_clk(13),
    data3  => delayed_rhic_clk(12),
    data4  => delayed_rhic_clk(11),
    data5  => delayed_rhic_clk(10),
    data6  => delayed_rhic_clk(9),
    data7  => delayed_rhic_clk(8),
    data8  => delayed_rhic_clk(7),
    data9  => delayed_rhic_clk(6),
    data10 => delayed_rhic_clk(5),
    data11 => delayed_rhic_clk(4),
    data12 => delayed_rhic_clk(3),
    data13 => delayed_rhic_clk(2),
    data14 => delayed_rhic_clk(1),
    data15 => delayed_rhic_clk(0),
    sel    => config8_data(7 DOWNTO 4),  -- selects phase of tray clock
                                         -- default = 0
    result => mult_clk_to_tray
    );                  

  -- JS: shift so default of 0 aligns data at DSMI
  -- to the middle of the data valid
  clk_for_final_register_select : MUX_16TO1 PORT MAP (
    data0  => delayed_rhic_clk(14),
    data1  => delayed_rhic_clk(13),
    data2  => delayed_rhic_clk(12),
    data3  => delayed_rhic_clk(11),
    data4  => delayed_rhic_clk(10),
    data5  => delayed_rhic_clk(9),
    data6  => delayed_rhic_clk(8),
    data7  => delayed_rhic_clk(7),
    data8  => delayed_rhic_clk(6),
    data9  => delayed_rhic_clk(5),
    data10 => delayed_rhic_clk(4),
    data11 => delayed_rhic_clk(3),
    data12 => delayed_rhic_clk(2),
    data13 => delayed_rhic_clk(1),
    data14 => delayed_rhic_clk(0),
    data15 => delayed_rhic_clk(15),
    sel    => config8_data(3 DOWNTO 0),
    result => final_reg_clk_for_mult
    ); 

  c1_clk_10mhz <= mult_clk_to_tray;
  c2_clk_10mhz <= mult_clk_to_tray;

  c1_dspare_out1 <= '0';                -- clk_16x_to_downstream;
  c2_dspare_out1 <= '0';                -- clk_16x_to_downstream;

  c1_dmult_inv <= NOT c1_dmult;
  c2_dmult_inv <= NOT c2_dmult;
  
  final_multiplicity_adder : adder_4_by_4_bits PORT MAP (
    dataa  => c1_dmult_inv,
    datab  => c2_dmult_inv,
    cout   => multiplicity_carry,
    result => final_sum(3 DOWNTO 0)
    );
  final_sum(4) <= multiplicity_carry;
  
  final_multiplicity_register : REG_5BIT PORT MAP (
    aclr  => '0',
    clock => mult_clk_to_tray,
    data  => final_sum,
    q     => trig_data_reg1);

--  Test data generator 
--  s_ctr_reset <= '0'; -- use this line to disable test data counter
  s_ctr_reset <= '1';
  s_rhic_clk  <= mult_clk_to_tray;
  mult_ctr : PROCESS (s_rhic_clk, s_ctr_reset) IS
  BEGIN
    IF s_ctr_reset = '0' THEN           -- asynchronous reset (active low)
      s_mult_count <= "00000";
    ELSIF s_rhic_clk'event AND s_rhic_clk = '1' THEN  -- rising clock edge
      s_mult_count <= s_mult_count + 1;
    END IF;
  END PROCESS mult_ctr;

-- Multiplexer to select test or normal data
  multiplicity_out_sel <= config9_data(7);  -- hook this to a configuration bit
  WITH multiplicity_out_sel SELECT
    trig_data_from_mux <=
    s_mult_count   WHEN '1',
    trig_data_reg1 WHEN OTHERS;
  
  data_phase_adjust_register : REG_5BIT PORT MAP (
    aclr  => '0',
    clock => final_reg_clk_for_mult,
    data  => trig_data_from_mux,
    q     => trig_data_out);

END ARCHITECTURE a;

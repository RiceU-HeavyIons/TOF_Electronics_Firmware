-- $Id: TCPU_B_TOP.vhd,v 1.1 2007-11-06 18:59:58 jschamba Exp $
--
-- TCPU_B_TOP.vhd


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

-- ********************************************************************
-- TOP LEVEL ENTITY
-- ********************************************************************

ENTITY TCPU_B_TOP IS
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

      --
      -- BANK 2, Schematic Sheet 8, USB Interface --
      --
      c2_ddaisy_data    : IN  std_logic;  -- N1
      c2_ddaisy_tok_out : IN  std_logic;  -- N2 token in/out is from pov of TDC
      c2_dstatus        : IN  std_logic_vector(1 DOWNTO 0);   -- N4, N3
      pld_crc_error     : OUT std_logic;  -- D3
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

      --
      -- BANK 3, Schematic Sheet 7 - none used

      --
      -- BANK 4, Schematic Sheet 6, H2 and H3 Interface -- 
      --  
      trig_clk_in_clk : IN  std_logic;
      trig_clk_in     : IN  std_logic;
      trig_data_out   : OUT std_logic_vector(4 DOWNTO 0);

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


      --test_at_J9                : OUT std_logic; -- AA20
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
      test4  : IN  std_logic;
      test3  : OUT std_logic;
      test2  : IN  std_logic;
      test1  : IN  std_logic;

      pld_serin  : IN  std_logic;       -- AB4
      pld_serout : OUT std_logic        -- AB5
      );

END TCPU_B_TOP;  -- end.entity

-- ********************************************************************
-- TOP LEVEL ARCHITECTURE
-- ********************************************************************

ARCHITECTURE a OF TCPU_B_TOP IS

  TYPE   SState_type IS (s1, s2, s3, s4);
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
  SIGNAL config12_data   : std_logic_vector (7 DOWNTO 0);
  SIGNAL config14_data   : std_logic_vector (7 DOWNTO 0);
  SIGNAL load_config0    : std_logic;
  SIGNAL load_config1    : std_logic;
  SIGNAL load_config2    : std_logic;
  SIGNAL load_config3    : std_logic;
  SIGNAL load_config7    : std_logic;
  SIGNAL load_config12   : std_logic;
  SIGNAL load_config14   : std_logic;
  SIGNAL mcu_fifo_level  : std_logic_vector(5 DOWNTO 0);
  SIGNAL mcu_fifo_status : std_logic_vector (7 DOWNTO 0);
  SIGNAL mcu_fifo_empty  : std_logic;
  SIGNAL mcu_fifo_full   : std_logic;
  SIGNAL mcu_fifo_parity : std_logic;
  SIGNAL mcu_fifo_rdreq  : std_logic;
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

  SIGNAL finalFifo_rdreq : std_logic;
  SIGNAL finalFifo_aclr  : std_logic;
  SIGNAL finalFifo_wrreq : std_logic;
  SIGNAL finalFifo_data  : std_logic_vector (31 DOWNTO 0);
  SIGNAL finalFifo_q     : std_logic_vector (31 DOWNTO 0);
  SIGNAL finalFifo_empty : std_logic;
  SIGNAL finalFifo_full  : std_logic;

----------------------------------------------------------

BEGIN

  -- these signals have no source, so set them to some default now
  c1_clk_10mhz      <= '0';
  c2_clk_10mhz      <= '0';
  c2_mcu_resetb     <= '1';
  trig_data_out     <= (OTHERS => '0');
  pld_crc_error     <= '0';
  pld_serout        <= '0';
  c1_ddaisy_clk     <= '0';
  c1_dspare_out1    <= '0';
  c1_flex_reset_out <= '0';
  c1_dconfig_out    <= '0';
  c2_ddaisy_clk     <= '0';
  c2_dspare_out1    <= '0';
  c2_flex_reset_out <= '0';
  c2_dconfig_out    <= '0';
  test17            <= '0';
  test15            <= '0';
  test13            <= '0';
  test11            <= '0';
  test9             <= '0';
  test7             <= '0';
  test6             <= '0';
  test5             <= '0';
  test3             <= '0';
  reg_clr           <= '0';

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

  th_den      <= '0';
  th_sync     <= '0';
  th_ren      <= '0';
  th_tpwdnb   <= '0';                   -- powered down for now
  th_rpwdnb   <= '0';                   -- powered down for now
  th_refclk   <= clk_20mhz;
  th_tclk     <= ser_rec_clk;           -- recovered receive clock
  th_local_le <= '0';                   -- DISABLE LOCAL LOOPBACK
  th_line_le  <= '0';                   -- DISABLE LINE LOOPBACK
  tx_d        <= (OTHERS => '0');
  -- th_lockb;


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
  load_config14 <= (NOT (mcu_read)) AND mcu_strobe AND addr_equ(14);

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

  sm_reset <= config1_data(0);
  buf_clr  <= config1_data(1);

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

  mcu_fifo_q      <= finalFifo_q;
  mcu_fifo_empty  <= finalFifo_empty;
  mcu_fifo_full   <= finalFifo_full;
  mcu_fifo_parity <= '0';
  mcu_fifo_level  <= (OTHERS => '0');

  mcu_fifo_status(7)          <= mcu_fifo_empty;
  mcu_fifo_status(6)          <= mcu_fifo_full;
  mcu_fifo_status(5)          <= mcu_fifo_parity;
  mcu_fifo_status(4 DOWNTO 0) <= mcu_fifo_level(4 DOWNTO 0);

  WITH mcu_addr SELECT
    mcu_output_data <=
    config0_data             WHEN x"0",
    config1_data             WHEN x"1",
    config2_data             WHEN x"2",
    config3_data             WHEN x"3",
    x"76"                    WHEN x"7",
    mcu_fifo_q(7 DOWNTO 0)   WHEN x"b",
    mcu_fifo_q(15 DOWNTO 8)  WHEN x"c",
    mcu_fifo_q(23 DOWNTO 16) WHEN x"d",
    mcu_fifo_q(31 DOWNTO 24) WHEN x"e",
    mcu_fifo_status          WHEN x"f",
    "00000000"               WHEN OTHERS;

  read_from_adr14 <= mcu_read AND addr_equ(14);

  --- sends 1 clock pulse at end of input pulse
  output_fifo_read_after_MCU_reads_msbyte : fifo_rd2 PORT MAP (
    clk        => clk_40mhz,
    mcu_strobe => mcu_strobe,
    rd_adr14   => read_from_adr14,
    reset      => sm_reset,
    out_hi     => mcu_fifo_rdreq);

  finalFifo_rdreq <= mcu_fifo_rdreq;

--  c1_fifo_rdreq <= mcu_fifo_rdreq AND (NOT config0_data(1));
--  c2_fifo_rdreq <= mcu_fifo_rdreq AND config0_data(1);

-- END OF CONFIGURATION REGISTERS ****************************************

--------------------------------------------------------------------------
--      SERIAL READOUT FROM TDCs
--------------------------------------------------------------------------

  -- internal pulser
  -- purpose: counter to generate internal pulser of selectable frequency
  -- type   : sequential
  -- inputs : clk_40mhz, sm_reset
  -- outputs: test_pls_bits
  PROCESS (clk_40mhz, sm_reset) IS
  BEGIN  -- PROCESS
    IF sm_reset = '1' THEN              -- asynchronous reset (active low)
      test_pls_bits <= (OTHERS => '0');
    ELSIF clk_40mhz'event AND clk_40mhz = '1' THEN  -- rising clock edge
      test_pls_bits <= test_pls_bits + 1;
    END IF;
  END PROCESS;

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

  WITH config14_data(3) SELECT
    test_pulse_raw <=
    test_at_j9      WHEN '0',
    internal_pulser WHEN OTHERS;

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

  -- shift register to delay the trigger pulse phase relative to the 40MHz clock:
  trigger_shiftreg : lpm_shiftreg GENERIC MAP (
    lpm_direction => "RIGHT",
    lpm_type      => "LPM_SHIFTREG",
    lpm_width     => 6)
    PORT MAP (
      sclr    => sm_reset,
      clock   => pll_240mhz,
      shiftin => test_pulse,
      q       => trigger_delay);
  -- trigger_delay vector provides 6 different phases of trigger pulse


---------------------------------------------------------------------------
-- Muxes for AUX / NORMAL serial readout for cable1
---------------------------------------------------------------------------          

  WITH config14_data(7) SELECT
    c1Sel_ser_out <=
    c1_ddaisy_data WHEN '0',            -- signal from FPGA
    c1_ser_out     WHEN OTHERS;         -- signal from Aux path

  WITH config14_data(7) SELECT
    c1Sel_token_out <=
    c1_ddaisy_tok_out WHEN '0',         -- signal from FPGA
    c1_token_out      WHEN OTHERS;      -- signal from Aux path

  WITH config14_data(7) SELECT
    c1Sel_strob_out <=
    c1_dstatus(0) WHEN '0',             -- signal from FPGA
    c1_strobe_out WHEN OTHERS;          -- signal from Aux path


---------------------------------------------------------------------------
-- CABLE 1 READOUT
---------------------------------------------------------------------------

  c1_trigger       <= trigger_delay(2);
  c1_ddaisy_tok_in <= c1Sel_token_in AND (NOT config14_data(7));
  c1_tray_token    <= c1Sel_token_in AND config14_data(7);
  c1_bunch_rst     <= config14_data(4);
  c1_sm_reset      <= sm_reset;
--  c1_rdout_en       <= test_pulse;
  c1_rdout_en      <= config2_data(0);
  
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
    c2_ddaisy_data WHEN '0',            -- signal from FPGA
    c2_ser_out     WHEN OTHERS;         -- signal from Aux path

  WITH config14_data(7) SELECT
    c2Sel_token_out <=
    c2_ddaisy_tok_out WHEN '0',         -- signal from FPGA
    c2_token_out      WHEN OTHERS;      -- signal from Aux path

  WITH config14_data(7) SELECT
    c2Sel_strob_out <=
    c2_dstatus(0) WHEN '0',             -- signal from FPGA
    c2_strobe_out WHEN OTHERS;          -- signal from Aux path


---------------------------------------------------------------------------
-- CABLE 2 READOUT
---------------------------------------------------------------------------
  
  c2_trigger       <= trigger_delay(2);
  c2_ddaisy_tok_in <= c2Sel_token_in AND (NOT config14_data(7));
  c2_tray_token    <= c2Sel_token_in AND config14_data(7);
  c2_bunch_rst     <= config14_data(4);
  c2_sm_reset      <= sm_reset;
--  c2_rdout_en       <= test_pulse;
  c2_rdout_en      <= config2_data(0);
  
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
  final_fifo : scfifo
    GENERIC MAP (
      add_ram_output_register => "ON",
      intended_device_family  => "Cyclone II",
      lpm_numwords            => 2048,
      lpm_showahead           => "ON",
      lpm_type                => "scfifo",
      lpm_width               => 32,
      lpm_widthu              => 11,
      overflow_checking       => "ON",
      underflow_checking      => "ON",
      use_eab                 => "ON"
      )
    PORT MAP (
      rdreq => finalFifo_rdreq,
      aclr  => finalFifo_aclr,
      clock => clk_40mhz,
      wrreq => finalFifo_wrreq,
      data  => finalFifo_data,
      empty => finalFifo_empty,
      q     => finalFifo_q,
      full  => finalFifo_full
      );


  -- Process to control data from c1 or c2 FIFO to Final FIFO
  PROCESS (clk_40mhz, sm_reset) IS
  BEGIN  -- PROCESS
    IF sm_reset = '1' THEN              -- asynchronous reset (active high)
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

END ARCHITECTURE a;

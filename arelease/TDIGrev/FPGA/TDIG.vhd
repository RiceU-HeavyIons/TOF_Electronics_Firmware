-- $Id: TDIG.vhd,v 1.1.1.1 2008-02-12 21:01:52 jschamba Exp $
-- TDIG.vhd

-- L. Bridges
-- Blue Sky Electronics, LLC
-- Houston, TX
-- 2007

-- These SBIR data are furnished with SBIR/STTR rights under Grant No. DE-FG03-02ER83373 and BNL Contract No. 
-- 79217.  For a period of 4 years after acceptance of all items delivered under this Grant, the Government, BNL and 
-- Rice agree to use these data for the following purposes only: Government purposes, research purposes, research 
-- publication purposes, research presentation purposes and for purposes of Rice to fulfill its obligations to provide 
-- deliverables to BNL and DOE under the Prime Award; and they shall not be disclosed outside the Government, BNL or 
-- Rice (including disclosure for procurement purposes) during such period without permission of Blue Sky, LLC except 
-- that, subject to the foregoing use and disclosure prohibitions, such data may be disclosed for use by support 
-- contractors. After the aforesaid 4-year period the Government has a royalty-free license to use, and to authorize others 
-- to use on its behalf, these data for Government purposes, and the Government, BNL and Rice shall be relieved of all 
-- disclosure prohibitions and have no liability for unauthorized use of these data by third parties.  This Notice shall be 
-- affixed to any reproductions of these data in whole or in part.


-- may 7, 2007 : temporarily set "fifo_empty" status signal to MCU = HI so that MCU won't read fifo and send CAN msgs
-- aug 31, 2007 : redesigned muxes to provide upstream / downstream connectivity for ATP
-- sep 6, 2007 : changed firmware version code to 0x06 in READ REGISTER 7 - code construct is "read_mux : data7x"

-- 
-- ********************************************************************
-- LIBRARY DEFINITIONS
-- ********************************************************************     

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
USE work.TDIG_E_primitives.ALL;

-- ********************************************************************
-- TOP LEVEL ENTITY
-- ********************************************************************

ENTITY TDIG IS
  PORT
    (
      --
      -- CLOCKS
      --        
      pld_clkin1 : IN std_logic;  -- 40 Mhz clock input; pin M1 I/O bank 1

      --
      -- BANK 1, Schematic Sheet 3, Downstream Interface -- 
      --        
      usb_slrd : IN std_logic;          -- M5 ?NEED TO CHANGE PIN ASSIGNMENT
      usb_slwr : IN std_logic;          -- M6 ?NEED TO CHANGE PIN ASSIGNMENT

      ddaisy_data    : IN  std_logic;   -- N1
      ddaisy_tok_out : IN  std_logic;   -- N2 token in/out is from pov of TDC
      ddaisy_tok_in  : OUT std_logic;   -- N6  token in/out is from pov of TDC
      dstatus        : IN  std_logic_vector(1 DOWNTO 0);  -- N4, N3
      ddaisy_clk     : OUT std_logic;   -- P1
      dspare_out     : OUT std_logic;   -- P6       

      flex_reset_out : OUT std_logic;                      -- R7
      dmult          : IN  std_logic_vector (3 DOWNTO 0);  -- W1 thru V1
      multa          : IN  std_logic;                      -- W3
      multb          : IN  std_logic;                      -- W4
      multc          : IN  std_logic;                      -- W5
      dspare_in      : IN  std_logic_vector(2 DOWNTO 0);
      --
      -- BANK 2, Schematic Sheet 8, USB Interface --
      --
      usb_if_clk     : OUT std_logic;                      -- C2
      usb_wakeup     : OUT std_logic;                      -- D1

      usb_flagb     : IN    std_logic;  -- D4
      usb_24m_clk   : OUT   std_logic;  -- D5 ON SCHEMATIC AS USB_CLK_FPGA
      usb_ready     : IN    std_logic;  -- D6  dedicated clk input
      usb_intb      : IN    std_logic;  -- E1  dedicated clk input
      usb_sloe      : OUT   std_logic;  -- E2
      usb_adr       : OUT   std_logic_vector (2 DOWNTO 0);   -- E3,J3,J2
      pld_usb       : INOUT std_logic_vector (15 DOWNTO 0);  -- H6 thru E4
      usb_flagc     : IN    std_logic;  -- J1
      usb_pktend    : OUT   std_logic;  -- J4
      usb_slcsb     : OUT   std_logic;  -- J5
      pld_crc_error : OUT   std_logic;  -- D3

      --
      -- BANK 3, Schematic Sheet 6, H1 and H2 Interface -- 
      --
      h1_test       : IN  std_logic;                      -- A3
      h1_error      : IN  std_logic;                      -- A4
      h1_ser_in     : OUT std_logic;                      -- A6
      h1_tck        : OUT std_logic;                      -- A7
      h1_tms        : OUT std_logic;                      -- A8
      h1_tdi        : OUT std_logic;                      -- A9
      h1_tdo        : IN  std_logic;                      -- A10
      h1_trst       : OUT std_logic;                      -- A11
      h1_token_in   : OUT std_logic;                      -- B4
      h1_rst        : OUT std_logic;                      -- B5
      h1_bunch_rst  : OUT std_logic;                      -- B6
      h1_event_rst  : OUT std_logic;                      -- B7
      h1_trig       : OUT std_logic;                      -- B8
      h1_ser_out    : IN  std_logic;                      -- B9
      h1_token_out  : IN  std_logic;                      -- B10
      h1_strobe_out : IN  std_logic;                      -- B11
      tdc_tst       : OUT std_logic_vector (3 DOWNTO 1);  -- C7, C9, C10

      h2_test     : IN  std_logic;      -- D9
      h2_error    : IN  std_logic;      -- d11
      h2_tck      : OUT std_logic;      -- E9
      h2_tms      : OUT std_logic;      -- E11
      h2_tdi      : OUT std_logic;      -- F8
      h2_tdo      : IN  std_logic;      -- F9
      h2_trst     : OUT std_logic;      -- F10
      h2_ser_in   : OUT std_logic;      -- F11
      h2_token_in : OUT std_logic;      -- G7

      --
      -- BANK 4, Schematic Sheet 6, H2 and H3 Interface -- 
      --
      h2_rst              : OUT std_logic;                      -- A13
      h2_bunch_rst        : OUT std_logic;                      -- A14
      h2_event_rst        : OUT std_logic;                      -- A15
      h2_trig             : OUT std_logic;                      -- A16
      h2_ser_out          : IN  std_logic;                      -- A17
      h2_token_out        : IN  std_logic;                      -- A18
      h2_strobe_out       : IN  std_logic;                      -- A19
      h3_test             : IN  std_logic;                      -- B13
      h3_error            : IN  std_logic;                      -- B14
      h3_tck              : OUT std_logic;                      -- B17
      h3_tms              : OUT std_logic;                      -- B18
      h3_tdi              : OUT std_logic;                      -- B19
      h3_tdo              : IN  std_logic;                      -- B20
      h3_trst             : OUT std_logic;                      -- C13
      h3_ser_in           : OUT std_logic;                      -- C16
      h3_token_in         : OUT std_logic;                      -- C17
      h3_rst              : OUT std_logic;                      -- D16
      h3_bunch_rst        : OUT std_logic;                      -- E14
      h3_event_rst        : OUT std_logic;                      -- E15
      h3_trig             : OUT std_logic;                      -- F3
      h3_ser_out          : IN  std_logic;                      -- F14
      h3_token_out        : IN  std_logic;                      -- F15
      h3_strobe_out       : IN  std_logic;                      -- G16
      --
      -- BANK 5, Schematic Sheet 9 -- 
      --
      -- no signals in use on this bank
      --
      -- BANK 6, Schematic Sheet 2, Upstream Interface -- 
      --
      umult               : OUT std_logic_vector (3 DOWNTO 0);  -- M19 thru M15
      udaisy_data         : OUT std_logic;                      -- N15
      udaisy_tok_out      : OUT std_logic;                      -- N21
      ustrobe_out         : OUT std_logic;                      -- N22
      ustatus             : OUT std_logic;                      -- T21
      udaisy_clk          : IN  std_logic;                      -- P17
      udaisy_tok_in       : IN  std_logic;                      -- P18
      flex_reset_in       : IN  std_logic;                      -- P20
      uspare_in           : IN  std_logic;                      -- V22
      clk_10mhz_on_io_pin : IN  std_logic;                      -- R22
      trigger             : IN  std_logic;                      -- T18

      bunch_rst      : IN    std_logic;                      -- U21
      --
      -- BANK 7, Schematic Sheet 1, MCU and Test Interface -- 
      --
      mcu_pld_data   : INOUT std_logic_vector (7 DOWNTO 0);  -- R14 thru V14
      mcu_pld_ctrl   : IN    std_logic_vector (4 DOWNTO 0);  -- W14 thru Y14
      mcu_tdc_tdi    : IN    std_logic;                      -- AA12
      mcu_tdc_tdo    : OUT   std_logic;                      -- AA13
      mcu_tdc_tck    : IN    std_logic;                      -- AA14
      mcu_tdc_tms    : IN    std_logic;                      -- AA15
      usb_flaga      : IN    std_logic;                      -- AA19
      test_at_J9     : OUT   std_logic;                      -- AA20
      tino_test_pld  : OUT   std_logic;                      -- AB13
      pld_pushbutton : IN    std_logic;  -- AB17   -- input is LOW when button is pushed
      pld_led        : OUT   std_logic;                      -- AB20

      --
      -- BANK 8, Schematic Sheet 1, MCU Interface -- 
      --
      mcu_pld_spare : IN std_logic_vector(2 DOWNTO 0);  -- U9, U8, T11

      test19 : OUT std_logic;
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
      pld_serout : OUT std_logic;       -- AB5
      spare_pld  : IN  std_logic   -- AB11  from/to IO expander U36/pin19   
      );

  --    DEDICATED PINS NOT EXPLICITLY NAMED IN VHDL CODE:

  -- pld_clkin1         : IN    std_logic; -- M1
  -- pld_clkin2         : IN    std_logic; -- V12
  -- pld _devoe         pin AA3     Pulled high; pulling low will tri-state all I/O pins
  -- clk_10mhz          : IN    std_logic; -- M22
  -- local_osc          : IN    std_logic; -- D12 

END TDIG;  -- end.entity

-- ********************************************************************
-- TOP LEVEL ARCHITECTURE
-- ********************************************************************

ARCHITECTURE a OF TDIG IS

  SIGNAL global_40mhz, clk_160mhz, pll_locked : std_logic;  -- global clock signal
  SIGNAL byteblaster_tdi                      : std_logic;
  SIGNAL byteblaster_tdo                      : std_logic;
  SIGNAL byteblaster_tms                      : std_logic;
  SIGNAL byteblaster_tck                      : std_logic;
  SIGNAL tdc_tdi, tdc_tdo, tdc_tms, tdc_tck   : std_logic;
  SIGNAL jtag_sel                             : std_logic;
  SIGNAL no_select                            : std_logic;
  SIGNAL select_tdc1                          : std_logic;
  SIGNAL select_tdc2                          : std_logic;
  SIGNAL select_tdc3                          : std_logic;
  SIGNAL jtag_mode                            : std_logic_vector(1 DOWNTO 0);  --  

  SIGNAL debounced_button, dbounce1, dbounce2          : std_logic;
  SIGNAL hit_counter_load, hit_counter_enable          : std_logic;
  SIGNAL hit_counter_value, frequency_control_value    : std_logic_vector(15 DOWNTO 0);
  SIGNAL delay_count_a                                 : std_logic_vector(15 DOWNTO 0);
  SIGNAL bunch_reset_test, internal_bunch_reset        : std_logic;
  SIGNAL test_pulse, hit_counter_carry, hit_counter_tc : std_logic;

  SIGNAL test_mcu_tdc_tdi, test_mcu_tdc_tdo    : std_logic;
  SIGNAL test_mcu_tdc_tck                      : std_logic;
  SIGNAL test_mcu_tdc_tms, test_mcu_pld_spare0 : std_logic;
  SIGNAL hit1_for_readout_test                 : std_logic;
  SIGNAL bunch_reset_for_readout_test          : std_logic;

  SIGNAL par_data_clock                            : std_logic;
  SIGNAL tdc_par_data                              : std_logic_vector(31 DOWNTO 0);
  SIGNAL test_trigger, reset                       : std_logic;
  SIGNAL pulse_gen_input, short_pulse_gen          : std_logic;
  SIGNAL sig_h1_token_in                           : std_logic;
  SIGNAL button_trigger, button_reset              : std_logic;
  SIGNAL token_signal_issued_by_readout_controller : std_logic;


-- MCU I/F SIGNALS

  SIGNAL bidir_data_bus, input_data                       : std_logic_vector(7 DOWNTO 0);
  SIGNAL output_data, config0_data                        : std_logic_vector(7 DOWNTO 0);
  SIGNAL config1_data, config2_data, config3_data         : std_logic_vector(7 DOWNTO 0);
  SIGNAL config12_data, config14_data                     : std_logic_vector(7 DOWNTO 0);
  SIGNAL output_sel                                       : std_logic_vector(3 DOWNTO 0);
  SIGNAL adr_equ                                          : std_logic_vector(15 DOWNTO 0);
  SIGNAL enable_data_out_to_mcu, enable_data_in_from_mcu  : std_logic;
  SIGNAL config0_clk_en, config1_clk_en, config2_clk_en   : std_logic;
  SIGNAL config3_clk_en, config12_clk_en, config14_clk_en : std_logic;
  SIGNAL strobe, strobe_clocked                           : std_logic;
  SIGNAL mcu_read, read_clocked, clock                    : std_logic;
  SIGNAL mcu_adr                                          : std_logic_vector(3 DOWNTO 0);
  SIGNAL mcu_data, read_mux_output                        : std_logic_vector(7 DOWNTO 0);
  SIGNAL test_cnt_cout, mcu_fifo_wrreq                    : std_logic;
  SIGNAL fifo_test_data, fifo_input_data, mcu_fifo_out    : std_logic_vector(32 DOWNTO 0);
  SIGNAL mcu_fifo_read, mcu_fifo_clear                    : std_logic;
  SIGNAL mcu_fifo_parity                                  : std_logic;
  SIGNAL mcu_fifo_level                                   : std_logic_vector(5 DOWNTO 0);

  SIGNAL sel_test_to_MCU_FIFO                : std_logic;
  SIGNAL sel_as_first_board_in_readout_chain : std_logic;
  SIGNAL sel_test_token_from_MCU             : std_logic;
  SIGNAL sel_test_mode_for_TDC_data          : std_logic;
  SIGNAL sel_test_mode_for_TDC_trigger       : std_logic;
  SIGNAL mcu_token, token_to_start_of_chain  : std_logic;

  SIGNAL mcu_strobe, mcu_strobe_short : std_logic_vector(15 DOWNTO 4);
  SIGNAL read_from_adr14              : std_logic;

  SIGNAL sel_test_mode_for_TDC_bunch_reset : std_logic;
  SIGNAL sel_test_mode_for_TDC_event_reset : std_logic;
  SIGNAL tdc_reset, reset_readout_sm       : std_logic;

  SIGNAL substitute_h1_token_in : std_logic;

  SIGNAL mcu_test_reset                : std_logic;
  SIGNAL mcu_fifo_full, mcu_fifo_empty : std_logic;

  SIGNAL initiate_readout     : std_logic;
  SIGNAL test_init_readout, x : std_logic;
  SIGNAL button_short         : std_logic;

  SIGNAL tdc_trigger, event_reset, bunch_reset : std_logic;
  SIGNAL trigger_to_tdcs                       : std_logic;

  SIGNAL tst_strobe4, tst_strobe5, tst_strobe9, tst_strobe10 : std_logic;
  SIGNAL dummy1, dummy2, dummy3, dummy4, dummy5              : std_logic;
  SIGNAL dummy6, dummy7, dummy8, dummy9                      : std_logic;

  SIGNAL tray_bunch_reset, test_bunch_reset, local_bunch_reset : std_logic;

  -- signals for test data shift register
  SIGNAL tapped_delay  : std_logic_vector(31 DOWNTO 0);
  SIGNAL start_readout : std_logic;

  SIGNAL test_hit_pattern : std_logic_vector(3 DOWNTO 1);
  SIGNAL tst_ctr_out      : std_logic_vector(15 DOWNTO 0);

  SIGNAL sig_udaisy_data, inv_udaisy_data                  : std_logic;
  SIGNAL sig_udaisy_tok_out, inv_udaisy_tok_out            : std_logic;
  SIGNAL sig_dstatus                                       : std_logic_vector(1 DOWNTO 0);
  SIGNAL sig_ustatus, inv_ustatus, ops_ustatus             : std_logic;
  SIGNAL sig_ustrobe_out, inv_ustrobe_out, ops_ustrobe_out : std_logic;
  SIGNAL sig_umult, sig_dmult, ops_umult, inv_umult        : std_logic_vector(3 DOWNTO 0);

  SIGNAL sig_trigger, sig_bunch_rst, sig_udaisy_clk   : std_logic;
  SIGNAL sig_udaisy_tok_in, sig_ddaisy_tok_in         : std_logic;
  SIGNAL sig_uspare_in, sig_flex_reset_in, tst_ctr_tc : std_logic;

  SIGNAL sig_ddaisy_clk, sig_dspare_out, sig_flex_reset_out : std_logic;
  SIGNAL sig_ddaisy_data, sig_ddaisy_tok_out                : std_logic;


  SIGNAL ops_bunch_rst, ops_ddaisy_tok_in                 : std_logic;
  SIGNAL ops_udaisy_data, ops_udaisy_tok_out              : std_logic;
  SIGNAL data_to_first_TDC, token_in_to_first_TDC, temp20 : std_logic;

  SIGNAL test_mux_sel : std_logic_vector(2 DOWNTO 0);
  SIGNAL out_to_j9    : std_logic_vector(3 DOWNTO 0);

  CONSTANT zero_byte      : std_logic_vector := x"00";
  CONSTANT five_five_byte : std_logic_vector := x"55";
  CONSTANT a_seven_byte   : std_logic_vector := x"a7";

----------------------------------------------------------

-- INDEX TO CODE

  -- 0. UPSTREAM SIGNAL INVERSION
  -- 1. GLOBAL CLOCK BUFFER
  -- 2.         MCU INTERFACE : BIDIR BUFFER AND ADDRESS DECODE
  -- 3. MCU INTERFACE : CONFIGURATION REGISTERS
  -- 4. MCU INTERFACE: MCU STROBES
  -- 5. TEST STROBES            
  -- 6. JTAG readout from TDCs  
  -- 7. TEST DATA TO TDCs               
  -- 8. SERIAL READOUT FROM TDCs
  -- 9. TEST STRUCTURE FOR SERIAL READOUT       
  
BEGIN

  -- 0. UPSTREAM SIGNAL INVERSION

  -- Due to placement of the upstream ribbon cable connector on the top side of the
  -- circuit card, the ribbon cables invert the polarity of their differential signals. 

  -- All signals discussed in this section are labelled as
  -- OUT (from TDIG to upstream) or 
  -- IN (from upstream to TDIG)

  -- The re-inversions take place on the UPSTREAM  side of TDIG only.

  -- Some  signals are re-inverted by swapping pin polarities
  --  at the receiver/driver devices:
  --
  -- UCLK_40MHZ (IN)
  -- CAN (BIDIRECTIONAL)
  -- TRIGGER (IN)
  -- BUNCH_RST (IN)

  -- Some signals should be re-inverted by swapping pin polarities at the
  -- receiver/driver devices, but are NOT so far (TDIG-E circuit card). These will be
  -- swapped on future versions of the board. These signals are used only in the
  -- auxilliary serial readout data path:
  --
  -- H3_SER_OUT
  -- H3_TOKEN_OUT
  -- H3_STROBE_OUT
  -- 
  -- The signals below are re-inverted at the UPSTREAM input/output of the TDIG FPGA.
  -- No inversion takes place on the DOWNSTREAM side.
  --
  -- UDAISY_DATA (OUT)
  -- UDAISY_TOK_OUT (OUT)
  -- USTATUS0 (OUT)
  -- ustatus (OUT)
  -- UMULT[3:0} (OUT)

  -- UDAISY_CLK (IN)                                      
  -- UDAISY_TOK_IN (IN)

  -- FLEX_RESET_IN (IN)
  -- USPARE_IN (IN)


  -- INVERTED SIGNALS ARE FOR TDIG-E, remove inversion for TDIG-D
  
  inv_udaisy_data    <= NOT sig_udaisy_data;
  inv_udaisy_tok_out <= NOT sig_udaisy_tok_out;
  inv_ustatus        <= NOT sig_ustatus;
  inv_ustrobe_out    <= NOT sig_ustrobe_out;
  inv_umult(3)       <= NOT sig_umult(3);
  inv_umult(2)       <= NOT sig_umult(2);
  inv_umult(1)       <= NOT sig_umult(1);
  inv_umult(0)       <= NOT sig_umult(0);

--  inv_udaisy_data    <= sig_udaisy_data;
--  inv_udaisy_tok_out <= sig_udaisy_tok_out;
--  inv_ustatus        <= sig_ustatus;
--  inv_ustrobe_out    <= sig_ustrobe_out;
--  inv_umult(3)       <= sig_umult(3);
--  inv_umult(2)       <= sig_umult(2);
--  inv_umult(1)       <= sig_umult(1);
--  inv_umult(0)       <= sig_umult(0);

  -- ********************************************************        

  -- UPSTREAM CABLE
  -- OUTPUT signals going UPSTREAM from TDIG (to TCPU or the next TDIG)

  udaisy_data    <= inv_udaisy_data;
  udaisy_tok_out <= inv_udaisy_tok_out;
  ustatus        <= inv_ustatus;
  ustrobe_out    <= inv_ustrobe_out;
  umult(3)       <= inv_umult(3);
  umult(2)       <= inv_umult(2);
  umult(1)       <= inv_umult(1);
  umult(0)       <= inv_umult(0);

  -- INPUT signals going DOWNSTREAM (from TCPU or another TDIG)  to TDIG

  sig_trigger   <= trigger;
  sig_bunch_rst <= bunch_rst;

  -- INVERTED SIGNALS ARE FOR TDIG-E, remove inversion for TDIG-D          

  sig_udaisy_clk    <= NOT udaisy_clk;
  sig_udaisy_tok_in <= NOT udaisy_tok_in;
  sig_flex_reset_in <= NOT flex_reset_in;
  sig_uspare_in     <= NOT uspare_in;

-- sig_udaisy_clk                       <=       udaisy_clk;
-- sig_udaisy_tok_in    <=       udaisy_tok_in;
-- sig_flex_reset_in        <=   flex_reset_in;
-- sig_uspare_in                        <=       uspare_in;

  -- ********************************************************

  -- DOWNSTREAM CABLE
  -- OUTPUT signals going DOWNSTREAM to next TDIG

  ddaisy_clk     <= sig_ddaisy_clk;
  dspare_out     <= sig_dspare_out;
  ddaisy_tok_in  <= sig_ddaisy_tok_in;
  flex_reset_out <= sig_flex_reset_out;

  -- INPUT signals coming UPSTREAM from TDIG farther from TCPU

  sig_ddaisy_data    <= ddaisy_data;
  sig_ddaisy_tok_out <= ddaisy_tok_out;
  sig_dstatus        <= dstatus;

  sig_dmult <= dmult;

  -- ops_udaisy_tok_out <= ddaisy_tok_out;      
  -- ops_udaisy_data <= ddaisy_data;

  ops_umult <= dmult;


  -- 1. GLOBAL CLOCK BUFFER
  
  global_clk_buffer : global PORT MAP (
    a_in  => pld_clkin1,
    a_out => global_40mhz);

  PLL_clk_mult_by3_inst : PLL_clk_mult_by3 PORT MAP (
    areset => '0',
    inclk0 => global_40mhz,
    c0     => clk_160mhz,
    locked => pll_locked
    );

  -- TEST I/O SIGNALS (going upstream to TCPU)

  -- DIFFERENT OUTPUT FREQUENCIES are used for CABLE TEST  
  counter_source_for_cable_test_signals : hit_counter_16bits PORT MAP (
    clock  => global_40mhz,
    cnt_en => '1',
    data   => x"FFFF",
    sclr   => '0',
    sload  => tst_ctr_tc,
    cout   => tst_ctr_tc,
    q      => tst_ctr_out);

  test_mux_sel <= config12_data(2 DOWNTO 0);

  ops_ustrobe_out <= h3_strobe_out;
  
  UPSTREAM_outputs : mux_2to1_8bits PORT MAP (
    -- test signals from downstream connector
    data0x(0) => ddaisy_tok_out,
    data0x(1) => ddaisy_data,
    data0x(2) => dstatus(1),
    data0x(3) => dstatus(0),
    data0x(4) => dmult(3),
    data0x(5) => dmult(2),
    data0x(6) => dmult(1),
    data0x(7) => dmult(0),
    -- operational signals
    data1x(0) => ops_udaisy_tok_out,
    data1x(1) => ops_udaisy_data,
    data1x(2) => ops_ustatus,
    data1x(3) => ops_ustrobe_out,
    data1x(4) => ops_umult(3),
    data1x(5) => ops_umult(2),
    data1x(6) => ops_umult(1),
    data1x(7) => ops_umult(0),
    sel       => NOT config14_data(0),  -- 
    -- outputs to upstream cable
    result(0) => sig_udaisy_tok_out,
    result(1) => sig_udaisy_data,
    result(2) => sig_ustatus,
    result(3) => sig_ustrobe_out,
    result(4) => sig_umult(3),
    result(5) => sig_umult(2),
    result(6) => sig_umult(1),
    result(7) => sig_umult(0)
    );

  DOWNSTREAM_outputs : mux_2to1_8bits PORT MAP (

    -- test signals from upstream connector

    data0x(0) => sig_udaisy_clk,
    data0x(1) => sig_uspare_in,
    data0x(2) => sig_flex_reset_in,
    data0x(3) => '0',
    data0x(4) => '0',
    data0x(5) => '0',
    data0x(6) => sig_udaisy_tok_in,
    data0x(7) => '0',

    -- operational signals

    data1x(0) => sig_udaisy_clk,
    data1x(1) => sig_uspare_in,
    data1x(2) => sig_flex_reset_in,
    data1x(3) => '0',
    data1x(4) => '0',
    data1x(5) => '0',
    data1x(6) => sig_udaisy_tok_in,
    data1x(7) => '0',

    sel => NOT config14_data(0),        --  '0',        

    -- outputs to downstream cable
    result(0) => sig_ddaisy_clk,
    result(1) => sig_dspare_out,
    result(2) => sig_flex_reset_out,
    result(3) => dummy4,
    result(4) => dummy5,
    result(5) => dummy6,
    result(6) => sig_ddaisy_tok_in,
    result(7) => dummy7
    );

  -- signal observation muxes for downstream and upstream signals
  
  UPstream_INPUT_observation_mux : mux_8to1_1bit_wide PORT MAP (
    data0  => sig_udaisy_clk,
    data1  => sig_uspare_in,
    data2  => sig_flex_reset_in,
    data3  => '0',
    data4  => sig_bunch_rst,
    data5  => sig_trigger,
    data6  => sig_udaisy_tok_in,
    data7  => '0',
    sel    => test_mux_sel,
    result => out_to_J9(3)
    );  

  DOWNstream_OUTPUT_observation_mux : mux_8to1_1bit_wide PORT MAP (
    data0  => sig_ddaisy_clk,
    data1  => sig_dspare_out,
    data2  => sig_flex_reset_out,
    data3  => '0',
    data4  => '0',
    data5  => '0',
    data6  => sig_ddaisy_tok_in,
    data7  => '0',
    sel    => test_mux_sel,
    result => out_to_J9(2)
    );  

  DOWNstream_INPUT_observation_mux : mux_8to1_1bit_wide PORT MAP (
    data0  => sig_ddaisy_tok_out,
    data1  => sig_ddaisy_data,
    data2  => sig_dstatus(1),
    data3  => sig_dstatus(0),
    data4  => sig_dmult(3),
    data5  => sig_dmult(2),
    data6  => sig_dmult(1),
    data7  => sig_dmult(0),
    sel    => test_mux_sel,
    result => out_to_J9(1)
    );

  UPstream_OUTPUT_observation_mux : mux_8to1_1bit_wide PORT MAP (
    data0  => sig_udaisy_tok_out,
    data1  => sig_udaisy_data,
    data2  => sig_ustatus,
    data3  => sig_ustrobe_out,
    data4  => sig_umult(3),
    data5  => sig_umult(2),
    data6  => sig_umult(1),
    data7  => sig_umult(0),
    sel    => test_mux_sel,
    result => out_to_J9(0)
    );

  second_level_mux_for_test_signals_out_to_J9 : mux_4to1_1bit_wide PORT MAP (
    data0  => out_to_J9(0),  -- observe outputs to upstream cable at J9
    data1  => out_to_J9(1),  -- observe inputs from downstream cable at J9
    data2  => out_to_J9(2),             -- observe outputs to downstream  at J9
    data3  => out_to_J9(3),             -- observe inputs from ustream at J9
    sel    => b"11",
    result => test_at_j9
    );                                          
  ----------------------------------------------------------------------------------------------
  -- 2.         MCU INTERFACE : BIDIR BUFFER AND ADDRESS DECODE
  ----------------------------------------------------------------------------------------------

  -- hookup signals to pins

  mcu_read <= mcu_pld_ctrl(4);
  strobe   <= mcu_pld_spare(1);
  -- mcu_pld_data(7 downto 0) <= mcu_data(7 downto 0);
  mcu_adr  <= mcu_pld_ctrl(3 DOWNTO 0);
  clock    <= global_40mhz;

-- BIDIRECTIONAL BUFFER FOR MCU DATA BUS

  enable_data_out_to_mcu  <= strobe AND mcu_read;
  enable_data_in_from_mcu <= NOT enable_data_out_to_mcu;
  
  MCU_bidir_bus_buffer : bidir_buffer_8bit PORT MAP (
    data     => output_data,
    enabledt => enable_data_out_to_mcu,
    enabletr => enable_data_in_from_mcu,
    result   => input_data,
    tridata  => mcu_pld_data);

----------------------------------------------------------------------------------

  MCU_address_decoder : decoder_4to16_reg PORT MAP (
    clock  => global_40mhz,
    data   => mcu_adr,
    enable => strobe,
    eq0    => adr_equ(0),
    eq1    => adr_equ(1),
    eq2    => adr_equ(2),
    eq3    => adr_equ(3),
    eq4    => adr_equ(4),               -- strobe4 for token from MCU
    eq5    => adr_equ(5),
    eq6    => adr_equ(6),
    eq7    => adr_equ(7),
    eq8    => adr_equ(8),
    eq9    => adr_equ(9),
    eq10   => adr_equ(10),
    eq11   => adr_equ(11),
    eq12   => adr_equ(12),
    eq13   => adr_equ(13),
    eq14   => adr_equ(14),
    eq15   => adr_equ(15)
    );

-- **************************************************************************************
--      3. MCU INTERFACE : CONFIGURATION REGISTERS
--***************************************************************************************
  
  config0_clk_en  <= (NOT (mcu_read)) AND strobe AND adr_equ(0);
  config1_clk_en  <= (NOT (mcu_read)) AND strobe AND adr_equ(1);
  config2_clk_en  <= (NOT (mcu_read)) AND strobe AND adr_equ(2);
  config3_clk_en  <= (NOT (mcu_read)) AND strobe AND adr_equ(3);
  config12_clk_en <= (NOT (mcu_read)) AND strobe AND adr_equ(12);
  config14_clk_en <= (NOT (mcu_read)) AND strobe AND adr_equ(14);
  
  config0_register : reg_8bit PORT MAP (
    clock  => clock,
    data   => input_data,
    enable => config0_clk_en,
    sclr   => reset,
    q      => config0_data);

  sel_test_to_MCU_FIFO <= config0_data(0);
  -- select test input to MCU FIFO, rather than
  -- TDC data from the serial readout controller

  sel_as_first_board_in_readout_chain <= config0_data(1);
  -- first board gets token from upstream controller 
  -- other boards get token from downstream       

  sel_test_token_from_MCU <= config0_data(2);
  -- controls mux to select MCU strobe (for select = 1) or upstream/downstream token
  -- as token_in to       first TDC on board (U2).

  sel_test_mode_for_TDC_data <= config0_data(3);
  -- selects data pulse from MCU as source for TDC chan 1

  sel_test_mode_for_TDC_trigger <= config0_data(4);

  sel_test_mode_for_TDC_bunch_reset <= config0_data(5);

  sel_test_mode_for_TDC_event_reset <= config0_data(6);
  
  config1_register : reg_8bit PORT MAP (
    clock  => clock,
    data   => input_data,
    enable => config1_clk_en,
    sclr   => reset,
    q      => config1_data);

  config2_register : reg_8bit PORT MAP (
    clock  => clock,
    data   => input_data,
    enable => config2_clk_en,
    sclr   => reset,
    q      => config2_data);

  TDC_reset <= config2_data(0);
  
  config3_register : reg_8bit PORT MAP (
    clock  => clock,
    data   => input_data,
    enable => config3_clk_en,
    sclr   => reset,
    q      => config3_data);

  config12_register : reg_8bit PORT MAP (
    clock  => clock,
    data   => input_data,
    enable => config12_clk_en,
    sclr   => reset,
    q      => config12_data);           -- 3 lsbs hold board tray position

  config14_register : reg_8bit PORT MAP (
    clock  => clock,
    data   => input_data,
    enable => config14_clk_en,
    sclr   => reset,
    q      => config14_data);  -- 3 lsbs hold board tray position                      

  -- DATA READ MUX FOR DATA FROM FPGA TO MCU
  
  read_mux : mux_8bits_16inputs PORT MAP (

    data0x => config0_data,
    data1x => config1_data,
    data2x => config2_data,
    data3x => config3_data,
    data4x => zero_byte,
    data5x => zero_byte,
    data6x => zero_byte,

    data7x => x"61",                    -- THIS VALUE GIVES THE CODE VERSION #

    data8x              => zero_byte,   -- status0,
    data9x              => zero_byte,   -- status1,
    data10x             => zero_byte,   -- status2,
    data11x             => mcu_fifo_out(7 DOWNTO 0),
    data12x             => mcu_fifo_out(15 DOWNTO 8),
    data13x             => mcu_fifo_out(23 DOWNTO 16),
    data14x             => mcu_fifo_out(31 DOWNTO 24),
    data15x(7)          => '1',  -- mcu_fifo_empty, -- temporarily set fifo = empty so mcu won't read and chatter on can bus
    data15x(6)          => mcu_fifo_full,
    data15x(5)          => mcu_fifo_parity,
    data15x(4 DOWNTO 0) => mcu_fifo_level(4 DOWNTO 0),
    sel                 => mcu_adr,
    result              => output_data
    );                                  
-- END OF CONFIGURATION REGISTERS ****************************************

-- ****************************************************************************************
--  4. MCU INTERFACE: MCU STROBES
--
--*****************************************************************************************

-- strobe logic is identical to configuration register clock enable logic
-- strobes are then shortened so they are one clock wide

  strobe_signals : FOR i IN 4 TO 15 GENERATE
    
    mcu_strobe(i) <= (NOT (mcu_read)) AND strobe AND adr_equ(i);
    
  END GENERATE;
  
  shorten_strobe4 : short PORT MAP (
    clk      => clock,
    input_hi => mcu_strobe(4),
    reset    => reset,
    out_hi   => mcu_strobe_short(4));

  test_init_readout <= mcu_strobe_short(4) OR '0';  -- tst_strobe4;
  
  shorten_strobe5 : short PORT MAP (
    clk      => clock,
    input_hi => mcu_strobe(5),
    reset    => reset,
    out_hi   => mcu_strobe_short(5));

  shorten_strobe6 : short PORT MAP (
    clk      => clock,
    input_hi => mcu_strobe(6),
    reset    => reset,
    out_hi   => mcu_strobe_short(6));

  shorten_strobe7 : short PORT MAP (
    clk      => clock,
    input_hi => mcu_strobe(7),
    reset    => reset,
    out_hi   => mcu_strobe_short(7));

  shorten_strobe8 : short PORT MAP (
    clk      => clock,
    input_hi => mcu_strobe(8),
    reset    => reset,
    out_hi   => mcu_strobe_short(8));

  shorten_strobe9 : short PORT MAP (
    clk      => clock,
    input_hi => mcu_strobe(9),
    reset    => reset,
    out_hi   => mcu_strobe_short(9));

  shorten_strobe10 : short PORT MAP (
    clk      => clock,
    input_hi => mcu_strobe(10),
    reset    => reset,
    out_hi   => mcu_strobe_short(10));

  mcu_fifo_clear <= mcu_strobe_short(10) OR tst_strobe10;
  
  shorten_strobe11 : short PORT MAP (
    clk      => clock,
    input_hi => mcu_strobe(11),
    reset    => reset,
    out_hi   => mcu_strobe_short(11));  -- used for test ctr clk enable
                                        -- and MCU_fifo input clk enable
  
  shorten_strobe12 : short PORT MAP (
    clk      => clock,
    input_hi => mcu_strobe(12),
    reset    => '0',
    out_hi   => mcu_strobe_short(12));

  reset <= mcu_strobe_short(12);

-- END OF MCU STROBES *****************************************************************

-- 5. TEST STROBES ********************************************************************

  push_button_state_machine : push_tst PORT MAP (
    clk          => clock,
    push         => button_short,
    reset        => reset,
    --tst_strobe4 => tst_strobe4,
    tst_strobe5  => tst_strobe5,
    tst_strobe9  => tst_strobe9,
    tst_strobe10 => tst_strobe10
    );

  h2_rst <= TDC_reset;
  h1_rst <= TDC_reset;
  h3_rst <= TDC_reset;

  -- mux input to fifo: 
  -- port 0 : parallel readout from TDC readout component
  -- port 1: counter for testing
  -- selection is stubbed for now but will come from a configuration register bit
  
  test_input_for_MCU_fifo : counter_33bit PORT MAP (
    clk_en => mcu_strobe_short(11),  -- counter increments only with mcu_strobe(11)
    clock  => clock,
    sclr   => test_cnt_cout,
    cout   => test_cnt_cout,
    q      => fifo_test_data
    );

  MCU_FIFO_data_input_mux : mux_2to1_33bits PORT MAP (
    data0x(31 DOWNTO 0) => tdc_par_data,
    data0x(32)          => '0',  -- stubbed. msb will be parity bit from TDC data
    data1x(32 DOWNTO 0) => fifo_test_data,
    sel                 => sel_test_to_MCU_FIFO,  -- CONFIG_0.0
    result(32 DOWNTO 0) => fifo_input_data
    );

  -- mux for FIFO input clock
  MCU_FIFO_input_clock_mux : mux_2_to_1_1bit_wide PORT MAP (
    data0  => par_data_clock,        -- pulse from serial readout state machine
    data1  => mcu_strobe_short(11),  -- pulse from write strobe 11, 1 clock wide
    sel    => sel_test_to_MCU_FIFO,     -- CONFIG_0.0
    result => mcu_fifo_wrreq
    );

  read_from_adr14 <= mcu_read AND strobe AND adr_equ(14);

  --- sends 1 clock pulse at end of input pulse
  output_fifo_read_after_MCU_reads_msbyte : fifo_rd PORT MAP (
    clk      => clock,
    rd_adr14 => read_from_adr14,
    reset    => reset,
    out_hi   => mcu_fifo_read
    );

  -- FIFO : input from TDC serial readout, output to MCU --------------------------------------------------
  
  MCU_FIFO : FIFO_33wide_64deep PORT MAP (
    clock => clock,
    data  => fifo_input_data,
    rdreq => mcu_fifo_read,
    sclr  => mcu_fifo_clear,  -- shortened strobe 10 from MCU OR pushbutton
    wrreq => mcu_fifo_wrreq,            -- 2 sources: serial read state machine
    -- or test clock (simple version is always hi)
    empty => mcu_fifo_empty,
    full  => mcu_fifo_full,
    q     => mcu_fifo_out,
    usedw => mcu_fifo_level
    );          

  -- *****************************************************************************************
  --            6. JTAG readout from TDCs
  --
  -- *****************************************************************************************  

  --            2 sources: Byteblaster or MCU
  --            3 destinations : TDC1, TDC2 or TDC3
  --      4 signals: TCK, TMS, TDI inputs to TDC, TDO output from TDC

  jtag_mode(1 DOWNTO 0) <= config1_data(1 DOWNTO 0);
  jtag_sel              <= NOT config1_data(2);  -- HI on config bit selects MCU for JTAG configuration

  -- Test code to hardwire select for TDC#1
  --jtag_sel <= '1';
  --jtag_mode <= "01";
  
  TDC_select : decoder_4to1 PORT MAP (
    data   => jtag_mode(1 DOWNTO 0),
    enable => '1',
    eq0    => no_select,
    eq1    => select_tdc1,
    eq2    => select_tdc2,
    eq3    => select_tdc3);

  -- select TDC signals from either byteblaster or MC
  
  TDC_JTAG_input_mux : mux_2to1_3bit_wide PORT MAP (

    data0x(2) => mcu_tdc_tck,
    data0x(1) => mcu_tdc_tdi,
    data0x(0) => mcu_tdc_tms,

    data1x(2) => byteblaster_tck,
    data1x(1) => byteblaster_tdi,
    data1x(0) => byteblaster_tms,

    sel       => jtag_sel,
    result(2) => tdc_tck,
    result(1) => tdc_tdi,
    result(0) => tdc_tms);

  -- selected TDO signal goes from TDC to byteblaster and MCU
  
  tdo_mux : mux_4to1_1bit_wide PORT MAP (
    data0  => '0',
    data1  => h1_tdo,
    data2  => h2_tdo,
    data3  => h3_tdo,
    sel    => jtag_mode(1 DOWNTO 0),
    result => byteblaster_tdo);

  mcu_tdc_tdo <= byteblaster_tdo;

  -- The selected TDC receives tck, tdi, tms signals from Byteblaster,
  -- according to the selection made via "jtag_mode()"
  
  tdc1_jtag_select_mux : mux_2to1_3bit_wide PORT MAP (
    data0x    => "000",
    data1x(2) => tdc_tck,
    data1x(1) => tdc_tdi,
    data1x(0) => tdc_tms,
    sel       => select_tdc1,
    result(2) => h1_tck,
    result(1) => h1_tdi,
    result(0) => h1_tms);

  tdc2_jtag_select_mux : mux_2to1_3bit_wide PORT MAP (
    data0x    => "000",
    data1x(2) => tdc_tck,
    data1x(1) => tdc_tdi,
    data1x(0) => tdc_tms,
    sel       => select_tdc2,
    result(2) => h2_tck,
    result(1) => h2_tdi,
    result(0) => h2_tms);       

  tdc3_jtag_select_mux : mux_2to1_3bit_wide PORT MAP (
    data0x    => "000",
    data1x(2) => tdc_tck,
    data1x(1) => tdc_tdi,
    data1x(0) => tdc_tms,
    sel       => select_tdc3,
    result(2) => h3_tck,
    result(1) => h3_tdi,
    result(0) => h3_tms);               

  -- JTAG reset is always disabled (signal is active low)

  h1_trst <= '1';                       -- JTAG reset is disabled
  h2_trst <= '1';                       -- JTAG reset is disabled
  h3_trst <= '1';                       -- JTAG reset is disabled

  -- *****************************************************************************************                          
  -- end of TDC JTAG control    
  -- *****************************************************************************************  

  --*****************************************************************************************
  --    TEST DATA TO TDCs
  --
  --****************************************************************************************

  --pulse_gen_input <= test_at_J9;  -- test1 is an input from external pulse generator
  
  shorten_pulse_from_J9 : short PORT MAP (
    clk      => clock,
    input_hi => pulse_gen_input,        -- input from test1
    reset    => reset,
    out_hi   => short_pulse_gen);       

  shift32_inst : shift32 PORT MAP (
    clock    => global_40mhz,
    sclr     => '0',
    shiftin  => short_pulse_gen,  -- signal from ext pulse gen, 1 clock wide
    q        => tapped_delay,           -- 32 bit tapped delay line
    shiftout => dummy2                  -- not used
    );

  --    External signal generator drives shift register.
  --            External pulse is first shortened to be one clock (25 ns) wide

  -- high order tapped delay bits happen first, so order of signals is:
  --            bunch reset
  --    `       hits to test input (channel 1) on TDCs
  --            start pulse  to readout state machine

  test_hit_pattern(1) <= tapped_delay(23) OR tapped_delay(21) OR tapped_delay(19);
  test_hit_pattern(2) <= tapped_delay(23) OR tapped_delay(21) OR tapped_delay(19);
  test_hit_pattern(3) <= tapped_delay(23) OR tapped_delay(21) OR tapped_delay(19);
  
  TDC_test_hit_enable_mux : mux_2to1_3bit_wide PORT MAP (
    data0x(2) => '0',
    data0x(1) => '0',
    data0x(0) => '0',
    data1x(2) => test_hit_pattern(3),
    data1x(1) => test_hit_pattern(2),
    data1x(0) => test_hit_pattern(1),
    sel       => '0',                   -- sel_test_mode_for_TDC_data,
    result(2) => tdc_tst(3),
    result(1) => tdc_tst(2),
    result(0) => tdc_tst(1));           


  --****************************************************************************************
  -- END OF TEST DATA TO TDCs
  --****************************************************************************************

  ----------------------------------------------------------------------------------------------
  --    SERIAL READOUT FROM TDCs
  ----------------------------------------------------------------------------------------------

  --mux_for_test_or_upstream_readout_init : mux_2_to_1_1bit_wide PORT MAP (
  --data0        => udaisy_tok_in,
  --data1        => test_init_readout, 
  --sel  =>   '1',              --sel_test_token_from_MCU,  -- config_0.2
  --result       =>  initiate_readout );

  --reset_readout_sm <=  button_short;  -- mcu_strobe_short(12) OR tst_strobe9; 

  --serial_read_block : ser_read PORT MAP (  
  --clk                                         =>   global_40mhz,
  --data                                =>   h3_ser_out,                -- serial data out from TDC3
  --data_clk                    =>   global_40mhz,       
  --reset                               =>   reset_readout_sm,      
  --tdc_token_out =>   h3_token_out,        -- token out from TDC3
  --trigger                     =>   start_readout,     -- initiate_readout,      
  --par_clk                     =>   par_data_clock,      
  --tdc_token_in        =>   h1_token_in,               
  --par_data                    =>   tdc_par_data  );

  -- The first board in readout chain gets zero data, 
  -- and a token from the upstream readout controller. 
  -- Subsequent boards get data and  token from the 
  -- downstream connector.

  -- **************** 
  --    SERIAL DATA PATH :
  --          MUX FOR DOWNSTREAM DATA -> TDC1 -> TDC2 -> TDC3 -> TO UPSTREAM
  -- *****************************************************************************************************      
  mux_for_downstream_serial_data : mux_2_to_1_1bit_wide PORT MAP (
    data0  => ddaisy_data,
    data1  => '0',
    sel    => sel_as_first_board_in_readout_chain,  -- config_0.1
    result => data_to_first_TDC);    

  h1_ser_in <= data_to_first_TDC;
  h2_ser_in <= h1_ser_out;
  h3_ser_in <= h2_ser_out;

  ops_udaisy_data <= h3_ser_out;

  --  END OF SERIAL DATA PATH
  --
  -- ****************************************************************
  
  mux_for_token : mux_2_to_1_1bit_wide PORT MAP (
    data0  => ddaisy_tok_out,  -- not first board, so get token from downstream connector
    data1  => sig_udaisy_tok_in,  -- first board in chain, so get token from on-board
    sel    => sel_as_first_board_in_readout_chain,  -- config_0.1
    result => token_in_to_first_TDC);   -- h1_token_in  );      

  h1_token_in <= token_in_to_first_TDC;
  h2_token_in <= h1_token_out;
  h3_token_in <= h2_token_out;

  ops_udaisy_tok_out <= h3_token_out;  -- h3_token_out also goes to on-board serial readout state machine


  -- Bunch reset select logic
  --      Config_0.5 "sel_test_mode_for_TDC_bunch_reset" selects whether the bunch reset 
  --      comes from upstream (tray_bunch_reset) or is an on-board test signal
  --
  --      Config_2.1 selects whether the on-board test signal for bunch reset comes
  --            from an MCU generated strobe (strobe 7), or from the test data shift register

  tray_bunch_reset <= bunch_rst;
  
  test_or_tray_bunch_reset_select : mux_2_to_1_1bit_wide PORT MAP (
    data0  => tray_bunch_reset,
    data1  => test_bunch_reset,
    sel    => sel_test_mode_for_TDC_bunch_reset,
    result => local_bunch_reset);       

  mux_to_select_which_test_bunch_reset : mux_2_to_1_1bit_wide PORT MAP (
    data0  => tapped_delay(30),
    data1  => mcu_strobe_short(7),  -- test pulse from write strobe 7, 1 clock wide
    sel    => config2_data(1),
    result => test_bunch_reset);        

  h1_bunch_rst <= local_bunch_reset;
  h2_bunch_rst <= local_bunch_reset;
  h3_bunch_rst <= local_bunch_reset;

  -- Event reset select logic
  
  event_reset_mux : mux_2_to_1_1bit_wide PORT MAP (
    data0  => '0',                      -- event reset not used at tray level
    data1  => mcu_strobe_short(8),  -- test pulse from write strobe 8, 1 clock wide
    sel    => config0_data(6),
    result => trigger_to_tdcs
    );

  h1_event_rst <= event_reset;
  h2_event_rst <= event_reset;
  h3_event_rst <= event_reset;

  -- Trigger select logic
  
  trigger_mux : mux_2_to_1_1bit_wide PORT MAP (
    data0  => trigger,              -- pulse from serial readout state machine
    data1  => mcu_strobe_short(6),  -- pulse from write strobe 11, 1 clock wide
    sel    => config0_data(4),
    result => tdc_trigger
    );

  h1_trig <= tdc_trigger;
  h2_trig <= tdc_trigger;
  h3_trig <= tdc_trigger;


  ----------------------------------------------------------------------------------------------
  -- TEST STRUCTURE FOR SERIAL READOUT
  --
  --                    debounced input button (SW2) loads counter
  --                    counter counts down
  --                    during count down, 'hit_signal_delay' comparator generates a test hit
  --                    at terminal count, the trigger signal for the readout state machine is generated        
  
  delayed_debounce_counter : hit_counter_16bits PORT MAP (
    clock  => global_40mhz,
    cnt_en => '1',                      -- hit_counter_enable,
    data   => x"0100",  -- frequency_control_value, freq = value x 25ns
    sclr   => '0',                      -- hit_counter_clear,
    sload  => pulse_gen_input,  -- debounced_button,       -- hit_counter_load,
    cout   => test_trigger,
    q      => delay_count_a);                   

  bunch_reset_xxx : compare_16bit PORT MAP (
    clock => global_40mhz,
    dataa => delay_count_a,
    datab => x"0080",
    AeB   => bunch_reset_for_readout_test);     

  hit_signal_delay : compare_16bit PORT MAP (
    clock => global_40mhz,
    dataa => delay_count_a,
    datab => x"0030",
    AeB   => hit1_for_readout_test);    

  ------------------------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------------------

  -- Counter values are decoded to send bunch reset and 'tdc_tst' signals to TDCs.
  -- Reload register value determines hit frequency.
  -- OR Pushbutton causes one cycle per push.
  
  hit_counter_16bits_inst : hit_counter_16bits PORT MAP (
    clock  => global_40mhz,
    cnt_en => '1',                      -- hit_counter_enable,
    data   => x"0040",         -- frequency_control_value, freq = value x 25ns
    sclr   => '0',                      -- hit_counter_clear,
    sload  => hit_counter_tc,           -- hit_counter_load,
    cout   => hit_counter_carry,
    q      => hit_counter_value);                       

  bunch_reset_delay : compare_16bit PORT MAP (
    clock => global_40mhz,
    dataa => hit_counter_value,
    datab => x"0030",
    AeB   => internal_bunch_reset);

  hit_delay : compare_16bit PORT MAP (
    clock => global_40mhz,
    dataa => hit_counter_value,
    datab => x"0018",
    AeB   => test_pulse);                               

  terminal_count : compare_16bit PORT MAP (
    clock => global_40mhz,
    dataa => hit_counter_value,
    datab => x"0000",
    AeB   => hit_counter_tc);                   

  -- end of TEST HIT signals            
  ----------------------------------------------------------------------------------------------                                

  ----------------------------------------------------------------------------------------------
  -- DEBOUNCE pushbutton input
  
  Debounce_ff1 : DFLOP PORT MAP (
    aclr  => debounced_button,
    clock => pld_pushbutton,
    data  => '1',
    sclr  => '0',
    q     => dbounce1);

  Debounce_ff2 : DFLOP PORT MAP (
    aclr  => '0',
    clock => global_40mhz,
    data  => dbounce1,
    sclr  => '0',
    q     => dbounce2);

  Debounce_ff3 : DFLOP PORT MAP (
    aclr  => '0',
    clock => global_40mhz,
    data  => dbounce2,
    sclr  => '0',
    q     => debounced_button);                 

  -- end of DEBOUNCE            
  
  shorten_pulse_from_button : short PORT MAP (
    clk      => clock,
    input_hi => debounced_button,
    reset    => '0',
    out_hi   => button_short);

  ----------------------------------------------------------------------------------------------                                
  ----------------------------------------------------------------------------------------------        
  -- TEST HEADER signals

  -- ------------------------------------------------------------------------------------------

  -- HOOK UP BYTEBLASTER SIGNAL TO TEST HEADER
  --            FOR TDC CONFIGURATION
  --
  --------------------------------------------------------------------------------------------

  test6           <= byteblaster_tdo;
  byteblaster_tms <= test10;
  byteblaster_tdi <= test18;
  byteblaster_tck <= test2;

  -- END OF BYTEBLASTER / TDC HOOKUP
  --------------------------------------------------------------------------------------------

  --bunch_reset_test            <= test3;  -- signal input from DG535 (test3 is header pin3)

  test3  <= test_pulse;
  test5  <= bunch_reset_for_readout_test;
  test7  <= hit1_for_readout_test;
  test9  <= test_trigger;
  test11 <= sig_h1_token_in;
  test13 <= '0';
  test15 <= '0';
  test17 <= par_data_clock;
  test19 <= '0';

  -- test1              <= mcu_pld_spare(0); --  (test1 is header pin1)
  -- test3              <= mcu_tdc_tms;
  -- test5              <= byteblaster_tdo;
  -- test7              <= mcu_tdc_tdi;
  -- test9              <= mcu_tdc_tck;


  -- test13             <=   byteblaster_tms;
  -- test15             <=      byteblaster_tdo;
  -- test17             <=      byteblaster_tdi;
  -- test19             <=      byteblaster_tck;

  -- TEST SIGNALS FOR JTAG TDC COFIGURATION FROM MCU            
  --                test_mcu_tdc_tdi <= mcu_tdc_tdi;
  --                    test_mcu_tdc_tdo <= byteblaster_tdo;
  --               test_mcu_tdc_tck <= mcu_tdc_tck;
  --               test_mcu_tdc_tms <= mcu_tdc_tms;
  --               test_mcu_pld_spare0 <= 

  --                    test5           <=  test_mcu_tdc_tdi;
  --                    test7           <= test_mcu_tdc_tdo;
  --                    test9           <= test_mcu_tdc_tck;
  --                    test11                  <= test_mcu_tdc_tms;

  --                    test13                  <= mcu_pld_spare(0);
  --test13 <= pld_pushbutton;


  --test(15)            <= '1';         
  --test(17)            <= '1';
  --test(19)            <= '1';                                 
  -- test(4)            <= '1';
  -- test(8)            <= '1';         
  -- test(12)           <= '1';         
  --test(14)            <= '1';         
  --test(16)            <= '1';

  -- led output is D11, pushbutton is SW2

  -- pld_led <= config14_data(0);

  pld_led <= NOT pld_pushbutton;

  --pld_led                     <= '0'; 

  -- end of TEST HIT signals            
  ----------------------------------------------------------------------------------------------        

  -- Initialization of Outputs
  -- ************************************************************
  --
  -- BANK 1, Schematic Sheet 3, Downstream Interface -- 
  --

  -- usb_slrd           <= '0';
  --  usb_slwr          <= '0';         
  --
  -- BANK 2, Schematic Sheet 8, USB Interface --
  --
  usb_if_clk  <= '0';
  usb_wakeup  <= '0';
  usb_24m_clk <= '0';
  usb_sloe    <= '0';
  usb_adr     <= "000";
  usb_pktend  <= '0';
  usb_slcsb   <= '0';

  --- muxes for selecting between operational and test signal for
  --- TDC bunch reset, event reset and trigger

  --
  -- BANK 5, Schematic Sheet 9 -- 
  --
  -- no signals in use on this bank
  --
  -- BANK 7, Schematic Sheet 1, MCU and Test Interface -- 
  --
  pld_crc_error <= '0';
  tino_test_pld <= '0';

  --
  -- BANK 8, Schematic Sheet 1, MCU Interface -- 
  --
  pld_serout <= '0';
  
END ARCHITECTURE a;

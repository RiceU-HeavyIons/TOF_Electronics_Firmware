-- $Id: TDIGb.vhd,v 1.1 2012-06-01 15:13:22 jschamba Exp $
-- TDIG.vhd

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
USE work.mult_primitives.ALL;

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
      rhic_clkin : IN std_logic;  -- rhic clk input; pin M22 I/O bank 6; signal "CLK_10MHZ" on schematic page 2  

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

      usb_flagb   : IN    std_logic;    -- D4
      usb_24m_clk : OUT   std_logic;    -- D5 ON SCHEMATIC AS USB_CLK_FPGA
      usb_ready   : IN    std_logic;    -- D6  dedicated clk input
      usb_intb    : IN    std_logic;    -- E1  dedicated clk input
      usb_sloe    : OUT   std_logic;    -- E2
      usb_adr     : OUT   std_logic_vector (2 DOWNTO 0);   -- E3,J3,J2
      pld_usb     : INOUT std_logic_vector (15 DOWNTO 0);  -- H6 thru E4
      usb_flagc   : IN    std_logic;    -- J1
      usb_pktend  : OUT   std_logic;    -- J4
      usb_slcsb   : OUT   std_logic;    -- J5

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
      h2_rst              : OUT   std_logic;                      -- A13
      h2_bunch_rst        : OUT   std_logic;                      -- A14
      h2_event_rst        : OUT   std_logic;                      -- A15
      h2_ser_out          : IN    std_logic;                      -- A17
      h2_token_out        : IN    std_logic;                      -- A18
      h2_strobe_out       : IN    std_logic;                      -- A19
      h3_test             : IN    std_logic;                      -- B13
      h3_error            : IN    std_logic;                      -- B14
      h3_tck              : OUT   std_logic;                      -- B17
      h3_tms              : OUT   std_logic;                      -- B18
      h3_tdi              : OUT   std_logic;                      -- B19
      h3_tdo              : IN    std_logic;                      -- B20
      h3_trst             : OUT   std_logic;                      -- C13
      h3_ser_in           : OUT   std_logic;                      -- C16
      h3_token_in         : OUT   std_logic;                      -- C17
      h3_rst              : OUT   std_logic;                      -- D16
      h3_bunch_rst        : OUT   std_logic;                      -- E14
      h3_event_rst        : OUT   std_logic;                      -- E15
      h3_ser_out          : IN    std_logic;                      -- F14
      h3_token_out        : IN    std_logic;                      -- F15
      h3_strobe_out       : IN    std_logic;                      -- G16
      --
      -- BANK 5, Schematic Sheet 9 -- 
      --
      -- no signals in use on this bank
      --
      -- BANK 6, Schematic Sheet 2, Upstream Interface -- 
      --
      umult               : OUT   std_logic_vector (3 DOWNTO 0);  -- M19 thru M15
      udaisy_data         : OUT   std_logic;                      -- N15
      udaisy_tok_out      : OUT   std_logic;                      -- N21
      ustrobe_out         : OUT   std_logic;                      -- N22
      ustatus             : OUT   std_logic;                      -- T21
      udaisy_clk          : IN    std_logic;                      -- P17
      udaisy_tok_in       : IN    std_logic;                      -- P18
      flex_reset_in       : IN    std_logic;                      -- P20
      uspare_in           : IN    std_logic;                      -- V22
      clk_10mhz_on_io_pin : IN    std_logic;                      -- R22
      trigger             : IN    std_logic;                      -- T18
      bunch_rst           : IN    std_logic;                      -- U21
      --
      -- BANK 7, Schematic Sheet 1, MCU and Test Interface -- 
      --
      mcu_pld_data        : INOUT std_logic_vector (7 DOWNTO 0);  -- R14 thru V14
      mcu_pld_ctrl        : IN    std_logic_vector (4 DOWNTO 0);  -- W14 thru Y14
      mcu_tdc_tdi         : IN    std_logic;                      -- AA12
      mcu_tdc_tdo         : OUT   std_logic;                      -- AA13
      mcu_tdc_tck         : IN    std_logic;                      -- AA14
      mcu_tdc_tms         : IN    std_logic;                      -- AA15
      usb_flaga           : IN    std_logic;                      -- AA19
      test_at_J9          : OUT   std_logic;                      -- AA20
      tino_test_pld       : OUT   std_logic;                      -- AB13
      pld_pushbutton      : IN    std_logic;  -- AB17   -- input is LOW when button is pushed
      pld_led             : OUT   std_logic;                      -- AB20

      --
      -- BANK 8, Schematic Sheet 1, MCU Interface -- 
      --
      mcu_pld_spare : IN  std_logic_vector(2 DOWNTO 0);  -- U9, U8, T11
      test19        : OUT std_logic;
      test18        : IN  std_logic;
      test17        : OUT std_logic;
      test16        : IN  std_logic;
      test15        : OUT std_logic;
      test14        : IN  std_logic;
      test13        : OUT std_logic;
      test12        : IN  std_logic;
      test11        : OUT std_logic;
      test10        : IN  std_logic;
      test9         : OUT std_logic;
      test8         : IN  std_logic;
      test7         : OUT std_logic;
      test6         : OUT std_logic;
      test5         : OUT std_logic;
      test4         : IN  std_logic;
      test3         : OUT std_logic;
      test2         : IN  std_logic;
      test1         : IN  std_logic;

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

  CONSTANT TDIG_VERSION : std_logic_vector := x"A9";

  SIGNAL global_40mhz                       : std_logic;  -- global clock signal
  SIGNAL byteblaster_tdi                    : std_logic;
  SIGNAL byteblaster_tdo                    : std_logic;
  SIGNAL byteblaster_tms                    : std_logic;
  SIGNAL byteblaster_tck                    : std_logic;
  SIGNAL tdc_tdi, tdc_tdo, tdc_tms, tdc_tck : std_logic;
  SIGNAL jtag_sel                           : std_logic;
  SIGNAL jtag_mode                          : std_logic_vector(1 DOWNTO 0);

  SIGNAL debounced_button, dbounce1, dbounce2 : std_logic;

  SIGNAL reset                            : std_logic;
  SIGNAL pulse_gen_input, short_pulse_gen : std_logic;
  SIGNAL sig_h1_token_in                  : std_logic;

-- MCU I/F SIGNALS
  SIGNAL input_data                                       : std_logic_vector(7 DOWNTO 0);
  SIGNAL output_data, config0_data                        : std_logic_vector(7 DOWNTO 0);
  SIGNAL config1_data, config2_data, config3_data         : std_logic_vector(7 DOWNTO 0);
  SIGNAL config12_data, config13_data                     : std_logic_vector(7 DOWNTO 0);
  SIGNAL status3_data                                     : std_logic_vector(7 DOWNTO 0);
  SIGNAL output_sel                                       : std_logic_vector(3 DOWNTO 0);
  SIGNAL adr_equ                                          : std_logic_vector(15 DOWNTO 0);
  SIGNAL enable_data_out_to_mcu, enable_data_in_from_mcu  : std_logic;
  SIGNAL config0_clk_en, config1_clk_en, config2_clk_en   : std_logic;
  SIGNAL config3_clk_en, config12_clk_en, config13_clk_en : std_logic;
  SIGNAL strobe, strobe_clocked                           : std_logic;
  SIGNAL mcu_read, read_clocked, clock                    : std_logic;
  SIGNAL mcu_adr                                          : std_logic_vector(3 DOWNTO 0);
  SIGNAL mcu_data, read_mux_output                        : std_logic_vector(7 DOWNTO 0);
  SIGNAL test_cnt_cout, mcu_fifo_wrreq                    : std_logic;
  SIGNAL fifo_test_data, fifo_input_data, mcu_fifo_out    : std_logic_vector(32 DOWNTO 0);
  SIGNAL mcu_fifo_read, mcu_fifo_clear                    : std_logic;
  SIGNAL mcu_fifo_parity                                  : std_logic;
  SIGNAL mcu_fifo_level                                   : std_logic_vector(4 DOWNTO 0);
  SIGNAL data15x                                          : std_logic_vector(7 DOWNTO 0);

  SIGNAL sel_as_first_board_in_readout_chain : std_logic;
  SIGNAL mcu_token, token_to_start_of_chain  : std_logic;

  SIGNAL mcu_strobe8, mcu_strobe_short8 : std_logic;
  SIGNAL mcu_strobe12                   : std_logic;

  SIGNAL TDC_reset : std_logic;

  SIGNAL mcu_fifo_full, mcu_fifo_empty : std_logic;

  SIGNAL button_short : std_logic;

  SIGNAL tdc_trigger, event_reset, bunch_reset : std_logic;

  SIGNAL sig_udaisy_data, inv_udaisy_data       : std_logic;
  SIGNAL sig_udaisy_tok_out, inv_udaisy_tok_out : std_logic;
  SIGNAL sig_dstatus                            : std_logic_vector(1 DOWNTO 0);
  SIGNAL sig_ustatus, inv_ustatus               : std_logic;
  SIGNAL sig_ustrobe_out, inv_ustrobe_out       : std_logic;
  SIGNAL sig_umult, sig_dmult, inv_umult        : std_logic_vector(3 DOWNTO 0);

  SIGNAL sig_trigger, sig_bunch_rst, sig_udaisy_clk   : std_logic;
  SIGNAL sig_udaisy_tok_in, sig_ddaisy_tok_in         : std_logic;
  SIGNAL sig_uspare_in, sig_flex_reset_in, tst_ctr_tc : std_logic;

  SIGNAL sig_ddaisy_clk, sig_dspare_out, sig_flex_reset_out : std_logic;
  SIGNAL sig_ddaisy_data, sig_ddaisy_tok_out                : std_logic;
  SIGNAL data_to_first_TDC, token_in_to_first_TDC           : std_logic;

  -- new multiplicity signals
  SIGNAL rhic_clk_16x, buffered_rhic_clk_16x    : std_logic;
  SIGNAL dummy1, multiplicity_overflow          : std_logic;
  SIGNAL buffered_rhic_clkin, rhic_clk_from_pll : std_logic;
  SIGNAL view_mult_gate, overflow_gate_width    : std_logic;
  SIGNAL dmult_after_mux, dmult_inv             : std_logic_vector(3 DOWNTO 0);
  SIGNAL board_position                         : std_logic_vector(2 DOWNTO 0);
  SIGNAL gate_delay, gate_width                 : std_logic_vector(3 DOWNTO 0);
  SIGNAL end_of_gate_value, prog_gate_width     : std_logic_vector(3 DOWNTO 0);

  -- bunch reset timing signals
  SIGNAL br_inclk, br_outclk : std_logic;
  SIGNAL s_bunchrst_in       : std_logic;
  SIGNAL s_bunchrst_out      : std_logic;

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
  -- TDIG-E:
  inv_udaisy_data    <= NOT sig_udaisy_data;
  inv_udaisy_tok_out <= NOT sig_udaisy_tok_out;
  inv_ustatus        <= NOT sig_ustatus;
  inv_ustrobe_out    <= NOT sig_ustrobe_out;
--  inv_umult(3)       <= NOT sig_umult(3);
--  inv_umult(2)       <= NOT sig_umult(2);
--  inv_umult(1)       <= NOT sig_umult(1);
--  inv_umult(0)       <= NOT sig_umult(0);

  -- TDIG-D:
--  inv_udaisy_data    <= sig_udaisy_data;
--  inv_udaisy_tok_out <= sig_udaisy_tok_out;
--  inv_ustatus        <= sig_ustatus;
--  inv_ustrobe_out    <= sig_ustrobe_out;
--  inv_umult(3)       <= sig_umult(3);
--  inv_umult(2)       <= sig_umult(2);
--  inv_umult(1)       <= sig_umult(1);
--  inv_umult(0)       <= sig_umult(0);

  sig_udaisy_tok_out <= h3_token_out;
  sig_udaisy_data    <= h3_ser_out;
  sig_ustatus        <= '0';
  sig_ustrobe_out    <= h3_strobe_out;

--  sig_umult(3)       <= dmult(3);
--  sig_umult(2)       <= dmult(2);
--  sig_umult(1)       <= dmult(1);
--  sig_umult(0)       <= dmult(0);

  sig_ddaisy_clk     <= sig_udaisy_clk;
  sig_dspare_out     <= sig_uspare_in;
  sig_flex_reset_out <= sig_flex_reset_in;
  sig_ddaisy_tok_in  <= sig_udaisy_tok_in;

  -- ********************************************************        

  -- UPSTREAM CABLE
  -- OUTPUT signals going UPSTREAM from TDIG (to TCPU or the next TDIG)

  udaisy_data    <= inv_udaisy_data;
  udaisy_tok_out <= inv_udaisy_tok_out;
  ustatus        <= inv_ustatus;
  ustrobe_out    <= inv_ustrobe_out;
--  umult(3)       <= inv_umult(3);
--  umult(2)       <= inv_umult(2);
--  umult(1)       <= inv_umult(1);
--  umult(0)       <= inv_umult(0);

  -- INPUT signals going DOWNSTREAM (from TCPU or another TDIG)  to TDIG

  -- INVERTED SIGNALS ARE FOR TDIG-E, remove inversion for TDIG-D          

  sig_udaisy_clk    <= NOT udaisy_clk;
  sig_udaisy_tok_in <= NOT udaisy_tok_in;
  sig_flex_reset_in <= NOT flex_reset_in;
  sig_uspare_in     <= NOT uspare_in;


  -- ********************************************************

  -- DOWNSTREAM CABLE
  -- OUTPUT signals going DOWNSTREAM to next TDIG

  ddaisy_clk     <= sig_ddaisy_clk;
  dspare_out     <= sig_dspare_out;
  ddaisy_tok_in  <= sig_ddaisy_tok_in;
  flex_reset_out <= sig_flex_reset_out;

  -- 1. GLOBAL CLOCK BUFFER
  
  global_clk_buffer : global PORT MAP (
    a_in  => pld_clkin1,
    a_out => global_40mhz);

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

  MCU_bidir_bus_buffer : lpm_bustri
    GENERIC MAP (
      lpm_type  => "LPM_BUSTRI",
      lpm_width => 8
      )
    PORT MAP (
      enabletr => enable_data_in_from_mcu,
      enabledt => enable_data_out_to_mcu,
      data     => output_data,
      result   => input_data,
      tridata  => mcu_pld_data
      );

----------------------------------------------------------------------------------

  MCU_address_decoder : lpm_decode
    GENERIC MAP (
      lpm_decodes  => 16,
      lpm_pipeline => 1,
      lpm_type     => "LPM_DECODE",
      lpm_width    => 4)
    PORT MAP (
      clock  => global_40mhz,
      data   => mcu_adr,
      enable => strobe,
      eq     => adr_equ
      );

-- **************************************************************************************
--      3. MCU INTERFACE : CONFIGURATION REGISTERS
--***************************************************************************************

  config0_clk_en  <= (NOT (mcu_read)) AND strobe AND adr_equ(0);
  config1_clk_en  <= (NOT (mcu_read)) AND strobe AND adr_equ(1);
  config2_clk_en  <= (NOT (mcu_read)) AND strobe AND adr_equ(2);
  config3_clk_en  <= (NOT (mcu_read)) AND strobe AND adr_equ(3);
  config12_clk_en <= (NOT (mcu_read)) AND strobe AND adr_equ(12);
  config13_clk_en <= (NOT (mcu_read)) AND strobe AND adr_equ(13);

  config0_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8
      )
    PORT MAP (
      enable => config0_clk_en,
      sclr   => reset,
      clock  => clock,
      data   => input_data,
      q      => config0_data
      );

  sel_as_first_board_in_readout_chain <= config0_data(1);
  -- first board gets token from upstream controller 
  -- other boards get token from downstream       

  config1_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8
      )
    PORT MAP (
      enable => config1_clk_en,
      sclr   => reset,
      clock  => clock,
      data   => input_data,
      q      => config1_data
      );

  config2_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8
      )
    PORT MAP (
      enable => config2_clk_en,
      sclr   => reset,
      clock  => clock,
      data   => input_data,
      q      => config2_data
      );

  TDC_reset <= config2_data(0);

  config3_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8
      )
    PORT MAP (
      enable => config3_clk_en,
      sclr   => reset,
      clock  => clock,
      data   => input_data,
      q      => config3_data
      );

  config12_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8
      )
    PORT MAP (
      enable => config12_clk_en,
      sclr   => reset,
      clock  => clock,
      data   => input_data,
      q      => config12_data
      );

  board_position <= config12_data(2 DOWNTO 0);  -- low 3 bits are board position

  config13_register : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 8
      )
    PORT MAP (
      enable => config13_clk_en,
      sclr   => reset,
      clock  => clock,
      data   => input_data,
      q      => config13_data
      );

  prog_gate_width <= config13_data(3 DOWNTO 0);  -- low 4 bits are gate width

  -- DATA READ MUX FOR DATA FROM FPGA TO MCU

  -- dummy values, since we are not using the FIFO anymore:
  mcu_fifo_level  <= (OTHERS => '0');
  mcu_fifo_empty  <= '1';
  mcu_fifo_full   <= '0';
  mcu_fifo_parity <= '0';

  data15x(7)          <= mcu_fifo_empty;
  data15x(6)          <= mcu_fifo_full;
  data15x(5)          <= mcu_fifo_parity;
  data15x(4 DOWNTO 0) <= mcu_fifo_level;

  status3_data(0)          <= h1_error;
  status3_data(1)          <= h2_error;
  status3_data(2)          <= h3_error;
  status3_data(7 DOWNTO 3) <= config3_data(7 DOWNTO 3);

  WITH mcu_adr SELECT
    output_data <=
    config0_data  WHEN x"0",
    config1_data  WHEN x"1",
    config2_data  WHEN x"2",
    status3_data  WHEN x"3",
    TDIG_VERSION  WHEN x"7",            -- THIS VALUE GIVES THE CODE VERSION #
    config12_data WHEN x"C",
    config13_data WHEN x"D",
    data15x       WHEN x"F",
    zero_byte     WHEN OTHERS;

-- END OF CONFIGURATION REGISTERS ****************************************

-- ****************************************************************************************
--  4. MCU INTERFACE: MCU STROBES
--
--*****************************************************************************************

-- strobe logic is identical to configuration register clock enable logic
-- strobes are then shortened so they are one clock wide

  mcu_strobe8  <= (NOT (mcu_read)) AND strobe AND adr_equ(8);
  mcu_strobe12 <= (NOT (mcu_read)) AND strobe AND adr_equ(12);

  shorten_strobe8 : short PORT MAP (
    clk      => clock,
    input_hi => mcu_strobe8,
    reset    => reset,
    out_hi   => mcu_strobe_short8);

  shorten_strobe12 : short PORT MAP (
    clk      => clock,
    input_hi => mcu_strobe12,
    reset    => '0',
    out_hi   => reset);

-- END OF MCU STROBES *****************************************************************

-- 5. TEST STROBES ********************************************************************


  -- make input latch clock for bunch reset board position dependent
--  WITH board_position SELECT
--    br_inclk <=
--    NOT global_40mhz WHEN "000",
--    NOT global_40mhz WHEN "100",
--    global_40mhz     WHEN OTHERS;

  -- in case of the start & MTD detectors, use the following line instead
  -- of the above WITH statement:
  br_inclk <= global_40mhz;             -- always for the start detector

  -- the clock with which the bunch reset is strobed out is fixed:
  br_outclk <= global_40mhz;

  PROCESS (br_inclk) IS
  BEGIN
    IF rising_edge(br_inclk) THEN
      s_bunchrst_in <= bunch_rst;
    END IF;
  END PROCESS;

  PROCESS (br_outclk) IS
  BEGIN
    IF rising_edge(br_outclk) THEN
      s_bunchrst_out <= s_bunchrst_in;
    END IF;
  END PROCESS;


  h2_rst <= TDC_reset OR s_bunchrst_out;
  h1_rst <= TDC_reset OR s_bunchrst_out;
  h3_rst <= TDC_reset OR s_bunchrst_out;

  -- *****************************************************************************************
  --            6. JTAG readout from TDCs
  --
  -- *****************************************************************************************  

  --            2 sources: Byteblaster or MCU
  --            3 destinations : TDC1, TDC2 or TDC3
  --      4 signals: TCK, TMS, TDI inputs to TDC, TDO output from TDC

  jtag_mode <= config1_data(1 DOWNTO 0);
  jtag_sel  <= NOT config1_data(2);  -- HI on config bit selects MCU for JTAG configuration

  -- Test code to hardwire select for TDC#1
  --jtag_sel <= '1';
  --jtag_mode <= "01";

  -- select TDC signals from either byteblaster or MC
  tdc_tms <= byteblaster_tms WHEN jtag_sel = '1' ELSE mcu_tdc_tms;
  tdc_tdi <= byteblaster_tdi WHEN jtag_sel = '1' ELSE mcu_tdc_tdi;
  tdc_tck <= byteblaster_tck WHEN jtag_sel = '1' ELSE mcu_tdc_tck;

  -- selected TDO signal goes from TDC to byteblaster and MCU
  WITH jtag_mode SELECT
    byteblaster_tdo <=
    h3_tdo WHEN "11",
    h2_tdo WHEN "10",
    h1_tdo WHEN "01",
    '0' WHEN OTHERS;
  
  mcu_tdc_tdo <= byteblaster_tdo;

  -- The selected TDC receives tck, tdi, tms signals from Byteblaster,
  -- according to the selection made via "jtag_mode()"
  h1_tms <= tdc_tms WHEN jtag_mode = "01" ELSE '0';
  h1_tdi <= tdc_tdi WHEN jtag_mode = "01" ELSE '0';
  h1_tck <= tdc_tck WHEN jtag_mode = "01" ELSE '0';

  h2_tms <= tdc_tms WHEN jtag_mode = "10" ELSE '0';
  h2_tdi <= tdc_tdi WHEN jtag_mode = "10" ELSE '0';
  h2_tck <= tdc_tck WHEN jtag_mode = "10" ELSE '0';

  h3_tms <= tdc_tms WHEN jtag_mode = "11" ELSE '0';
  h3_tdi <= tdc_tdi WHEN jtag_mode = "11" ELSE '0';
  h3_tck <= tdc_tck WHEN jtag_mode = "11" ELSE '0';

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

  tdc_tst <= (OTHERS => '0');

  --****************************************************************************************
  -- END OF TEST DATA TO TDCs
  --****************************************************************************************


  -- **************** 
  --    SERIAL DATA PATH :
  --          MUX FOR DOWNSTREAM DATA -> TDC1 -> TDC2 -> TDC3 -> TO UPSTREAM
  -- *****************************************************************************************************      
  data_to_first_TDC <= ddaisy_data WHEN sel_as_first_board_in_readout_chain = '0'
                       ELSE '0';

  h1_ser_in <= data_to_first_TDC;
  h2_ser_in <= h1_ser_out;
  h3_ser_in <= h2_ser_out;

  --  END OF SERIAL DATA PATH
  --
  -- ****************************************************************

  -- Token select logic
  WITH sel_as_first_board_in_readout_chain SELECT
    token_in_to_first_TDC <=
    ddaisy_tok_out    WHEN '0',  -- not first board, so get token from downstream connector
    sig_udaisy_tok_in WHEN OTHERS;  -- first board in chain, so get token from on-board
  
  h1_token_in <= token_in_to_first_TDC;
  h2_token_in <= h1_token_out;
  h3_token_in <= h2_token_out;


  -- Bunch reset
  h1_bunch_rst <= '0';
  h2_bunch_rst <= '0';
  h3_bunch_rst <= '0';

--  h1_bunch_rst <= bunch_rst;
--  h2_bunch_rst <= bunch_rst;
--  h3_bunch_rst <= bunch_rst;

  -- Event reset select logic
  event_reset <= mcu_strobe_short8 WHEN config0_data(6) = '1' ELSE '0';

  h1_event_rst <= event_reset;
  h2_event_rst <= event_reset;
  h3_event_rst <= event_reset;

  ------------------------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------------------


  ----------------------------------------------------------------------------------------------
  -- DEBOUNCE pushbutton input

  EdgeFF : PROCESS (pld_pushbutton, debounced_button) IS
  BEGIN
    IF debounced_button = '1' THEN      -- asynchronous reset (active hi)
      dbounce1 <= '0';
    ELSIF pld_pushbutton'event AND pld_pushbutton = '1' THEN  -- rising clock edge
      dbounce1 <= '1';
    END IF;
  END PROCESS;

  Debounce : PROCESS (global_40mhz) IS
  BEGIN
    IF global_40mhz'event AND global_40mhz = '1' THEN  -- rising clock edge
      debounced_button <= dbounce2;
      dbounce2         <= dbounce1;
    END IF;
  END PROCESS Debounce;

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

--  test3 <= pld_clkin1;
--  test5 <= bunch_rst;
--  test7 <= trigger;

  test3  <= '0';
  test5  <= '0';
  test7  <= '0';
  test9  <= '0';
  test11 <= '0';
  test13 <= '0';
  test15 <= '0';
  test17 <= '0';
  test19 <= '0';

  pld_led <= NOT pld_pushbutton;

  -- end of TEST HIT signals            
  ----------------------------------------------------------------------------------------------        

  -- Initialization of Outputs
  -- ************************************************************
  --
  -- BANK 1, Schematic Sheet 3, Downstream Interface -- 
  --
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

  pld_usb <= (OTHERS => 'Z');

  --- muxes for selecting between operational and test signal for
  --- TDC bunch reset, event reset and trigger

  --
  -- BANK 5, Schematic Sheet 9 -- 
  --
  -- no signals in use on this bank
  --
  -- BANK 7, Schematic Sheet 1, MCU and Test Interface -- 
  --
  tino_test_pld <= '0';

  --
  -- BANK 8, Schematic Sheet 1, MCU Interface -- 
  --
  pld_serout <= '0';

-------------------------------------------------------------------------------------------------
-- 10. MULTIPLICITY
--
-------------------------------------------------------------------------------------------------

  -- Generate 16x rhic clk. Input is from upstream signal pair "ULV_N16 / P16",
  -- which is converted TTL signal "CLK_10MHZ" and is an input to the FPGA
  -- at dedicated input clock pin  M22 (CLK6). Schematic name is "CLK_10MHZ".
  -- NOTE: THIS SIGNAL HAS CORRECT POLARITY BECAUSE IT IS INVERTED 
  -- BY THE UPSTREAM CONNECTOR, AND THEN AGAIN AT THE INPUT TO THE LVDS BUFFER.

  PLL_multiplier_16x_inst : PLL_multiplier_16x PORT MAP (
    inclk0 => rhic_clkin,
    c0     => rhic_clk_16x,
    c1     => rhic_clk_from_pll
    );          

  --test_at_j9 <= rhic_clkin;
  test_at_j9 <= view_mult_gate;

  -- Undriven dmult inputs will float high. At the same time, downstream outputs that do drive
  -- dmult will invert the signals. So dmult inputs are always inverted.

  dmult_inv(3) <= NOT dmult(3);
  dmult_inv(2) <= NOT dmult(2);
  dmult_inv(1) <= NOT dmult(1);
  dmult_inv(0) <= NOT dmult(0);

  -- gate_delay based on board position

  WITH board_position SELECT
    gate_delay <=
    x"2" WHEN "000",
    x"3" WHEN "001",
    x"4" WHEN "010",
    x"5" WHEN "011",
    x"3" WHEN "100",
    x"4" WHEN "101",
    x"5" WHEN "110",
    x"6" WHEN "111",
    x"0" WHEN OTHERS;

  -- gate_width can be hard-coded, as below, or taken from the 4 lsbs of reg13 with the following statement:

  --gate_width <= prog_gate_width;
  gate_width <= "1000";
  
  add_gate_width_to_gate_delay : adder_2by4bit PORT MAP (
    dataa    => gate_delay,
    datab    => gate_width,
    overflow => overflow_gate_width,
    result   => end_of_gate_value);

  multiplicity_gated_adder : multiplicity_ver2 PORT MAP (
    rhic_clk   => rhic_clk_from_pll,
    rhic16x    => rhic_clk_16x,
    reset      => reset,
    gate_delay => gate_delay,           -- 4 bit input from register
    gate_width => end_of_gate_value,  -- 4 bit input from adder: gate_delay + gate_width
    mult_a     => multa,
    mult_b     => multb,
    mult_c     => multc,
    dmult      => dmult_inv,
    result     => umult,
    overflow   => multiplicity_overflow,
    view_gate  => view_mult_gate
    );

-------------------------------------------------------------------------------------------------

END ARCHITECTURE a;

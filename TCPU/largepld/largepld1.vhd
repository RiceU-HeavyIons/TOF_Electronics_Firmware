-- $Id: largepld1.vhd,v 1.3 2004-12-08 22:52:28 tofp Exp $
-- notes:

-- 1. 9/10/04: c1_m24, c2_m24, c3_m24, c4_m24   signals are used as the
--        data strobe for 4bit tdig tdc data. These are nominally the m24 data,
--    but m24 data is not implemented in RUN5.


-- Revisions:

-- 11/17 Added DDL interface code

-- 11/3
--      added mux to select internal or external trigger
--
-- 10/23/2004: 
--      added mcu interface
--      added test path the ctlv1 state machine for trigger only acquisition



-- ********************************************************************
-- LIBRARY DEFINITIONS
-- ********************************************************************     

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
USE work.tcpu_package.ALL;
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

-- ********************************************************************
-- TOP LEVEL ENTITY
-- ********************************************************************



ENTITY largepld1 IS
  PORT
    (
      sloclk3 : IN std_logic;
      pldclk0 : IN std_logic;

      tst37               : OUT std_logic;
      tst39               : OUT std_logic;
      tsthi               : OUT std_logic_vector(35 DOWNTO 21);
      tst19, tst17, tst13 : OUT std_logic;
      tstlo               : OUT std_logic_vector(11 DOWNTO 1);

      MS_HI      : OUT std_logic;  -- Pin used as HI in master/slave selection scheme
      MS_LO      : OUT std_logic;  -- Pin used as LO in master/slave selection scheme
      MS_sel     : IN  std_logic;  -- Pin used as master/slave input.  will be externally
                                   -- shorted to MS_HI *or* MS_LO.         
      MS_sel_out : OUT std_logic;  -- Output to small PLD to determine clock source from M/S select


      -- detector data link interface signals 
      ddl_fbd      : INOUT std_logic_vector(31 DOWNTO 0);
      ddl_spare    : OUT   std_logic;
      ddl_fobsy_N  : OUT   std_logic;
      ddl_foclk    : OUT   std_logic;
      ddl_fidir    : IN    std_logic;
      ddl_fiben_N  : IN    std_logic;
      ddl_filf_N   : IN    std_logic;
      ddl_fbctrl_N : INOUT std_logic;
      ddl_fbten_N  : INOUT std_logic;

      -- trigger/clock distribution board (TCD) inputs
      tcd_cclk1          : IN  std_logic;
      tcd_cclk2          : IN  std_logic;
      tcd_50mhz          : IN  std_logic;
      tcd_10_mhz         : IN  std_logic;
      tcd_d              : IN  std_logic_vector(3 DOWNTO 0);
      systrigin          : IN  std_logic;
      systrig1, systrig2 : OUT std_logic;

      -- microcontroller interface signals
      mcuctl     : IN    std_logic_vector(3 DOWNTO 0);  -- ctl3 = !read / write ; 2 downto 0 = adr
      mcud       : INOUT std_logic_vector(7 DOWNTO 0);  -- bidirectional data
      pld_int    : IN    std_logic;     -- data strobe
      fifo_empty : OUT   std_logic;     -- mcu fifo empty

      -- user interface signals
      led1 : OUT std_logic;             -- led 1 is io118 (D2)
      led2 : OUT std_logic;             -- led 2 is io119 (D3)
      led3 : OUT std_logic;             -- led 3 is io120 (D6)

      button : IN std_logic;            -- button is io117, LABEL SW2 ON PCB

      -- rs232 interface signals
      rs232sel : OUT std_logic_vector(2 DOWNTO 0);
      rs232enb : OUT std_logic;

      -- board status and configuration signals
      enable_trayclks : OUT std_logic;

      -- switches pages in config device
      -- default grounded by jumpers JU23, JU24, JU25
      pgm : IN std_logic_vector(2 DOWNTO 0);

      -- outputs to TDIG cards
      m7_gate : OUT std_logic;
      tdctrig : OUT std_logic;
      cmd1    : OUT std_logic;
      reset_c : OUT std_logic_vector(4 DOWNTO 1);
      spare_c : OUT std_logic_vector(4 DOWNTO 1);

      -- inputs from TDIG cards
      c1_m7d, c2_m7d   : IN std_logic_vector(5 DOWNTO 0);
      c3_m7d, c4_m7d   : IN std_logic_vector(5 DOWNTO 0);
      c1_tdc, c2_tdc   : IN std_logic_vector(3 DOWNTO 0);
      c3_tdc, c4_tdc   : IN std_logic_vector(3 DOWNTO 0);
      c1_m24, c2_m24   : IN std_logic;
      c3_m24, c4_m24   : IN std_logic;
      c1_dclk, c2_dclk : IN std_logic;
      c3_dclk, c4_dclk : IN std_logic;

      -- unused signals
      -- pulled low externally with 0 ohm resistor
      io5, io19, io36    : IN std_logic;
      io37, io278, io279 : IN std_logic;
      io295, io296       : IN std_logic

      -- uncommitted pin used for simulation only
      --reset_function :                                : IN    std_logic

      );

END largepld1;

-- ********************************************************************
-- TOP LEVEL ARCHITECTURE
-- ********************************************************************

ARCHITECTURE ver_four OF largepld1 IS
  
  COMPONENT GLOBAL
    PORT (a_in  : IN  std_logic;
          a_out : OUT std_logic);
  END COMPONENT;

  -- ****************************************************************
  -- SIGNAL DECLARATIONS
  -- ****************************************************************

  -- global signals

  SIGNAL global40mhz : std_logic;
  SIGNAL reset       : std_logic;

  -- source for global reset
  -- this signal is set currently to inactive
  -- it can be sourced from pushbutton (debounced), mcu, etc.

  SIGNAL reset_function : std_logic;


  -- TCD interface signals

  SIGNAL tcd_data   : std_logic_vector(19 DOWNTO 0);
  SIGNAL tcd_strobe : std_logic;

  -- input signals from TDIG after demux

  SIGNAL tdig1_data, tdig2_data, tdig3_data, tdig4_data : std_logic_vector(31 DOWNTO 0);
  SIGNAL tdig_strobe                                    : std_logic_vector(4 DOWNTO 1);  -- signal from cable demux to input fifo

  -- clock enable strobes for TDIG data after demux : used to clock data into input fifos

  SIGNAL tdig1_clken, tdig2_clken, tdig3_clken, tdig4_clken : std_logic;

  -- combined final data from ping/pong output muxes
  -- this data will go to DDL interface (and to MCU for debug)

  SIGNAL ping_pong_out : std_logic_vector(31 DOWNTO 0);

  -- control signals for core data path 

  SIGNAL ping_pong_read_enable, ping_pong_empty : std_logic;

  -- test signals

  SIGNAL button_debounced : std_logic;  -- debounced 1 clock wide, active high pulse from button  push 
                                        -- button is labelled 

  SIGNAL opmode, error_word : std_logic_vector(7 DOWNTO 0);
  SIGNAL ddl_read_fifo      : std_logic;

  SIGNAL test_pattern_1234     : std_logic_vector(15 DOWNTO 0);
  SIGNAL test_pattern_aaaa     : std_logic_vector(15 DOWNTO 0);
  SIGNAL test_pattern_5555     : std_logic_vector(15 DOWNTO 0);
  SIGNAL test_pattern_0000     : std_logic_vector(15 DOWNTO 0);
  SIGNAL test_pattern_ffff     : std_logic_vector(15 DOWNTO 0);
  SIGNAL test_pattern_ffffffff : std_logic_vector(31 DOWNTO 0);
  SIGNAL test_pattern_00000000 : std_logic_vector(31 DOWNTO 0);
  SIGNAL test_pattern_aaaaaaaa : std_logic_vector(31 DOWNTO 0);
  SIGNAL test_pattern_55555555 : std_logic_vector(31 DOWNTO 0);

  SIGNAL bus_enable, tristate_signal_enable, trigger_strobe_to_tdig, star_trigger_level_zero : std_logic;

  SIGNAL data_strobe, readbar_write                                              : std_logic;
  SIGNAL mcu_adr                                                                 : std_logic_vector(2 DOWNTO 0);
  SIGNAL mcu_data, pld_to_mcu_before_buffer, mcu_to_pld_after_buffer, mcu_decode : std_logic_vector(7 DOWNTO 0);
  SIGNAL mcu_mode_data, mcu_config_data, mcu_filter_sel                          : std_logic_vector(7 DOWNTO 0);
  SIGNAL mcu_write_to_pld, mcu_read_from_pld, mode_reg_write, config_reg_write   : std_logic;
  SIGNAL mcu_fifo_empty, mcu_filter_reg_write, mcu_bunch_reset, mcu_reset_to_pld : std_logic;
  SIGNAL mcu_fifo_out                                                            : std_logic_vector(31 DOWNTO 0);
  SIGNAL dummy_counter_out                                                       : std_logic_vector(14 DOWNTO 0);
  SIGNAL internal_trigger                                                        : std_logic;
  SIGNAL mcu_strobes_fifo                                                        : std_logic;
  SIGNAL cout, delaya, delayb, stretch, trig_presync                             : std_logic;

  -- INPUT FIFOS
  SIGNAL infifo0_dout : std_logic_vector (19 DOWNTO 0);  -- from tcd fifo
  SIGNAL infifo1_dout : std_logic_vector (31 DOWNTO 0);  -- from tdig  1 fifo
  SIGNAL infifo2_dout : std_logic_vector (31 DOWNTO 0);  -- from tdig  2 fifo
  SIGNAL infifo3_dout : std_logic_vector (31 DOWNTO 0);  -- from tdig  3 fifo
  SIGNAL infifo4_dout : std_logic_vector (31 DOWNTO 0);  -- from tcd  4 fifo

  SIGNAL read_input_fifo, infifo_full, infifo_empty : std_logic_vector(4 DOWNTO 0);

  SIGNAL inmux_dout  : std_logic_vector (31 DOWNTO 0);
  SIGNAL inmux_clken : std_logic;
  SIGNAL inmux_sel   : std_logic_vector (2 DOWNTO 0);

  -- PING_PONG OUTPUT FIFOS

  SIGNAL outfifo0_dout                               : std_logic_vector (31 DOWNTO 0);
  SIGNAL outfifo1_dout                               : std_logic_vector (31 DOWNTO 0);
  SIGNAL outfifo_in_enable, outfifo_out_enable       : std_logic_vector (1 DOWNTO 0);
  SIGNAL outfifo_full, outfifo_empty, write_ddl_fifo : std_logic_vector (1 DOWNTO 0);

  SIGNAL outmux_write       : std_logic;  -- control for 2:1 output DDL mux
  SIGNAL outmux_sel, toggle : std_logic;

  -- MCU interface

  SIGNAL wr_mcu_fifo, rd_mcu_fifo, mcu_fifo_full : std_logic;
  SIGNAL mcu_data_sel                            : std_logic_vector(1 DOWNTO 0);
  SIGNAL mcu_fifoq                               : std_logic_vector(31 DOWNTO 0);

  -- test fifo signals -- test fifo output goes to DDL in test mode    
  SIGNAL wr_final_fifo, rd_test_fifo, test_fifo_full, test_fifo_empty : std_logic;
  SIGNAL wr_ddl_fifo, rd_ddl_fifo, ddlfifo_full, ddlfifo_empty        : std_logic;
  SIGNAL ping_pong_data, ddl_data, ddl_fifo_indata                    : std_logic_vector(31 DOWNTO 0);

  -- signals to control which state machine controls the main data mux
  SIGNAL data_mux_sel, mcu_sel, main_data_sel, ctlv1_sel_input : std_logic_vector(2 DOWNTO 0);
  SIGNAL mcu_sel_empty                                         : std_logic;

  SIGNAL dummy                                                   : std_logic;
  SIGNAL error1                                                  : std_logic_vector(7 DOWNTO 0);
  SIGNAL ctlv1_read_fe_fifo, input_fifo_empty, ctlv1_wr_mcu_fifo : std_logic;
  SIGNAL alwon_read_fe_fifo, alwon_wr_mcu_fifo, write_mcu_fifo   : std_logic;
  SIGNAL clk, read_fifo_enable, ctlv1_write_mcu_fifo             : std_logic;
  SIGNAL end_record_tc, incr_end_of_record_cnt                   : std_logic;
  SIGNAL dummy7b                                                 : std_logic_vector(6 DOWNTO 0);

  -- ********************************************************************************
  -- DDL bidir signals separated into IN and OUT (JS)
  -- ********************************************************************************
  SIGNAL s_fiD      : std_logic_vector (31 DOWNTO 0);  -- corresponds to ddl_fbd (IN)
  SIGNAL s_foD      : std_logic_vector (31 DOWNTO 0);  -- corresponds to ddl_fbd (OUT)
  SIGNAL s_fiTEN_N  : std_logic;        -- corresponds to ddl_fbten_N (IN)
  SIGNAL s_foTEN_N  : std_logic;        -- corresponds to ddl_fbten_N (OUT)
  SIGNAL s_fiCTRL_N : std_logic;        -- corresponds to ddl_fbctrl_N (IN)
  SIGNAL s_foCTRL_N : std_logic;        -- corresponds to ddl_fbctrl_N (OUT)

-- ****************************************************************
-- ARCHITECTURE BEGINS HERE
-- ****************************************************************     
  
BEGIN

  -- ************************************************************
  -- MASTER / SLAVE assignment:
  
  MS_LO      <= '0';
  MS_HI      <= '1';
  MS_sel_out <= MS_sel;


  -- ************************************************************
  --
  -- TEST SIGNALS TO TEST HEADER

  -- MAPPING TDC DATA NIBBLES FROM TDC1 TO TEST HEADER

  --            tstlo(1)        <= inmux_dout(0);
  --            tstlo(3)        <= inmux_dout(1);
  --            tstlo(5)        <= inmux_dout(2);
  --            tstlo(7)        <= inmux_dout(3);

  --            tstlo(9)        <= c2_m7d(0);
  --            tstlo(11)       <= c2_m7d(1);
  --            tst13           <= c2_m7d(2);
  --            tst17           <= c2_m7d(3);                   
  --            tst19           <= tdig_strobe(2);
  --            tsthi(21)       <= read_input_fifo(2);
  --            tsthi(23)       <= stretch;
  --            tsthi(25)       <= main_data_sel(0);
  --            tsthi(27)       <= main_data_sel(1);
  --            tsthi(29)       <= main_data_sel(2);
  --            tsthi(31)       <= input_fifo_empty;

  tstlo(1)  <= tcd_d(0);
  tstlo(3)  <= tcd_d(1);
  tstlo(5)  <= tcd_d(2);
  tstlo(7)  <= tcd_d(3);
  tstlo(9)  <= tcd_50mhz;
  tstlo(11) <= tcd_10_mhz;
  tst13     <= tcd_cclk1;
  tst17     <= tcd_cclk2;
  tst19     <= tcd_data(0);
  tsthi(21) <= tcd_data(1);
  tsthi(23) <= tcd_data(2);
  tsthi(25) <= tcd_data(3);
  tsthi(27) <= tcd_data(4);
  tsthi(29) <= tcd_data(5);
  tsthi(31) <= tcd_data(6);
  tsthi(33) <= tcd_data(7);

  -- TDIG MCU MASTER RESET CONTROL! -----------------------------------------------------

  reset_c <= "1111";
  -- For now, just hold these outputs high.  IN the future, TCPU will reset TDIG on startup
  -- and also under CAN control.        

  -- TRIGGER INTERFACE -------------------------------------------------------------------

  -- INTERNAL TRIGGER COUNTER
  
  internal_trigger_counter : trigger_counter_15bit PORT MAP (
    clock  => global40mhz,
    cnt_en => '1',
    aclr   => '0',
    q      => dummy_counter_out,
    cout   => cout );

  -- ROUTING TRIGGER INPUT TO tdc trigger input over ribbon cable                       

  -- use ext trigger if config bit not set
  -- or internal trigger if config bit set

  choose_trigger_source : mux_2to1_1bit PORT MAP (
    data1  => cout,
    data0  => '0',                      -- THIS WILL BE A PULSE OUTPUT FROM
                            -- THE TCD CONTROLLER STATE MACHINE
                                -- so change this from '0' once that exists.
    sel    => mcu_config_data(0),
    result => trig_presync );           

  DFF_a : DFF_sclr PORT MAP (
    clock => global40mhz,
    sclr  => '0',
    aclr  => '0',
    data  => trig_presync,
    q     => delaya );

  DFF_b : DFF_sclr PORT MAP (
    clock => global40mhz,
    sclr  => '0',
    aclr  => '0',
    data  => delaya,
    q     => delayb );

  stretch <= delaya OR delayb;

  tdctrig <= stretch;                   -- after stretching to 50ns width

  -- tdctrig <= systrigin;   -- external pulse generator at J39 (remember PECL input levels)

  -- Turning on TDIG clocks:

  enable_trayclks <= '1';

  --------------------------------------------------------------------------------------


  ddl_read_fifo <= '1';

  opmode <= "00000001";

  test_pattern_ffffffff <= X"ffffffff";

  -- make clock and reset global

  global_clk_buffer : global PORT MAP (a_in => pldclk0, a_out => global40mhz);
  clk <= global40mhz;

  global_reset_buffer : global PORT MAP (a_in => '0', a_out => reset);  -- input for this will be changed to
                                        -- reset function

  -- reset_function <= '0'; -- global reset source set to inactive reset
  -- for simulation purposes this signal is given above in the entity declaration
  -- as a device pin

  -- reset_function <= '0';

  -- led status / version indicators

  led1 <= MS_sel;                       -- labelled 'D2' on pcb
  led2 <= NOT MS_sel;                   -- labelled 'D3' on pcb

  -- CONTROL LED3 WITH BUTTON 'SW2'
  led3 <= button;                       -- labelled 'D6' on pcb

  -- pushbutton input
  
  button_sync : pushbutton_pulse PORT MAP (
    clk        => global40mhz,
    reset      => reset,
    pushbutton => button,
    pulseout   => button_debounced );


  -- ********************************************************************************
  -- ddl_interface defaults (JS)
  -- ********************************************************************************

  -- detector data link interface signals
  ddl_spare  <= button;
  ddl_foclk  <= global40mhz;
  s_fiTEN_N  <= ddl_fbten_N;
  s_fiCTRL_N <= ddl_fbctrl_N;
  s_fiD      <= ddl_fbd;

  ddlbus : PROCESS (ddl_fiben_N, ddl_fidir, s_foTEN_N, s_foCTRL_N, ddl_fbD, s_foD)
  BEGIN
    IF (ddl_fiben_N = '1') OR (ddl_fidir = '0') THEN
      ddl_fbten_N  <= 'Z';
      ddl_fbctrl_N <= 'Z';
      ddl_fbd      <= (OTHERS => 'Z');
    ELSE
      ddl_fbten_N  <= s_foTEN_N;
      ddl_fbctrl_N <= s_foCTRL_N;
      ddl_fbd      <= s_foD;
    END IF;
  END PROCESS;

  ddl_inst : ddl PORT MAP (             -- DDL
    fiD        => s_fiD,
    foD        => s_foD,
    foBSY_N    => ddl_fobsy_N,
    fiCLK      => global40mhz,
    fiDIR      => ddl_fidir,
    fiBEN_N    => ddl_fiben_N,
    fiLF_N     => ddl_filf_N,
    fiCTRL_N   => s_fiCTRL_N,
    foCTRL_N   => s_foCTRL_N,
    fiTEN_N    => s_fiTEN_N,
    foTEN_N    => s_foTEN_N,
    ext_trg    => button_debounced,     -- external trigger
    reset      => reset,
    fifo_q     => ddl_data,  -- lwb: 11/17/04 I'm attaching the ddl fifo output to here
    fifo_empty => ddlfifo_empty,  -- lwb: 11/17/04 I'm attaching the ddl fifo empty to here
    fifo_rdreq => rd_ddl_fifo
    );

  -- INPUT SECTION *******************************************************************************      

  tdig_input_1 : COMPONENT ser_4bit_to_par PORT MAP (
    clk           => global40mhz, reset => reset,
    din           => c1_m7d(3 DOWNTO 0),
    dclk          => c1_dclk,
    dstrobe       => c1_m7d(4),         -- data strobe is active for 8 dclks 
    dout          => tdig1_data,
    output_strobe => tdig_strobe(1) );

  tdc1_fifo : COMPONENT input_fifo_64x32 PORT MAP (
    clock => clk,
    aclr  => reset,
    data  => tdig1_data,
    wrreq => tdig_strobe(1),
    rdreq => read_input_fifo(1),
    q     => infifo1_dout,
    full  => infifo_full(1),
    empty => infifo_empty(1) );

  tdig_input_2 : COMPONENT ser_4bit_to_par PORT MAP (
    clk           => global40mhz, reset => reset,
    din           => c2_m7d(3 DOWNTO 0),
    dclk          => c2_dclk,
    dstrobe       => c2_m7d(4),         -- data strobe is active for 8 dclks 
    dout          => tdig2_data,
    output_strobe => tdig_strobe(2) );

  tdc2_fifo : COMPONENT input_fifo_64x32 PORT MAP (
    clock => clk,
    aclr  => reset,
    data  => tdig2_data,
    wrreq => tdig_strobe(2),
    rdreq => read_input_fifo(2),
    q     => infifo2_dout,
    full  => infifo_full(2),
    empty => infifo_empty(2) ); 

  tdig_input_3 : COMPONENT ser_4bit_to_par PORT MAP (
    clk           => global40mhz, reset => reset,
    din           => c3_m7d(3 DOWNTO 0),
    dclk          => c3_dclk,
    dstrobe       => c3_m7d(4),         -- data strobe is active for 8 dclks 
    dout          => tdig3_data,
    output_strobe => tdig_strobe(3) );

  tdc3_fifo : COMPONENT input_fifo_64x32 PORT MAP (
    clock => clk,
    aclr  => reset,
    data  => tdig3_data,
    wrreq => tdig_strobe(3),
    rdreq => read_input_fifo(3),
    q     => infifo3_dout,
    full  => infifo_full(3),
    empty => infifo_empty(3) );

  tdig_input_4 : COMPONENT ser_4bit_to_par PORT MAP (
    clk           => global40mhz, reset => reset,
    din           => c4_m7d(3 DOWNTO 0),
    dclk          => c4_dclk,
    dstrobe       => c4_m7d(4),         -- data strobe is active for 8 dclks 
    dout          => tdig4_data,
    output_strobe => tdig_strobe(4) );

  tdc4_fifo : COMPONENT input_fifo_64x32 PORT MAP (
    clock => clk,
    aclr  => reset,
    data  => tdig4_data,
    wrreq => tdig_strobe(4),
    rdreq => read_input_fifo(4),
    q     => infifo4_dout,
    full  => infifo_full(4),
    empty => infifo_empty(4) );

  tcd_input : COMPONENT trigger_interface PORT MAP (
    clk           => global40mhz,
    reset         => reset,
    tcd_4bit_data => tcd_d,
    tcd_clk_50mhz => tcd_50mhz,
    tcd_clk_10mhz => tcd_10_mhz,
    tcd_word      => tcd_data,
    tcd_strobe    => tcd_strobe );  -- data valid strobe to clock data to fifo      

  tcd_input_fifo : COMPONENT input_fifo64dx20w PORT MAP (  -- tcd data
    clock => clk,
    aclr  => reset,
    data  => tcd_data,
    wrreq => tcd_strobe,
    rdreq => read_input_fifo(0),
    q     => infifo0_dout,
    full  => infifo_full(0),
    empty => infifo_empty(0) );

  infifo_mux : COMPONENT mux_5x32_unreg PORT MAP (
    data0x(31 DOWNTO 20) => "101000000000",  --"000000000000",
    data0x(19 DOWNTO 0)  => infifo0_dout,
    data1x               => infifo1_dout,
    data2x               => infifo2_dout,
    data3x               => infifo3_dout,
    data4x               => infifo4_dout,
    sel                  => main_data_sel,
    result               => inmux_dout );                        

  -- CONTROL SECTION *******************************************************************************            
  
  inmux_clken <= '1';

  -- 2 possible controllers
  -- Active controller is selected by MCU configuration bits.
  -- Then multiplexers select signals to/from the active controller to go to/from data path

  -- data_path_ctl : component data_path_control PORT MAP (
  --        clk                         => clk, 
  --        reset               => reset, 
  --            op_mode                 => op_mode,
  --            current_data    => inmux_dout,                                                            
  --            in_fifo_empty  => infifo_empty,         
  --            select_input    => inmux_sel,                           
  --            read_input_fifo => read_input_fifo,                             
  --            write_ddl_fifo => write_ddl_fifo, 
  --            ddl_fifo_sel    => outmux_sel,  
  --            error1                  => error1,
  --            trigger_pulse   => tdc_strobe,          -- goes to all TDCs on all TDIG cards   
  --            wr_final_fifo  => wr_final_fifo,
  --            mcu_mode                => mcu_mode,
  --            mcu_config      => mcu_config,
  --            mcu_filter_sel => mcu_filter_sel,
  --            wr_mcu_fifo    => wr_mcu_fifo,
  --            rd_mcu_fifo     => rd_mcu_fifo   );     

  -- this controller always reads front end fifo and writes mcu fifo if fe fifo is not empty
  simple_control : COMPONENT alwread PORT MAP (
    CLK      => clk,
    RESET    => reset,
    empty    => input_fifo_empty,
    rd_fifo  => alwon_read_fe_fifo,
    wr_fifo  => alwon_wr_mcu_fifo,
    incr_cnt => incr_end_of_record_cnt);  -- increment end of record counter
                                          -- ovf from counter selects "E700 0000" word            

  -- CHOOSE INPUT DATA SOURCE
  
  mcu_sel         <= mcu_config_data(3 DOWNTO 1);
  ctlv1_sel_input <= "000";  -- stub for control from large state machine
  
  choose_source_for_input_selection : two_by_3bit_mux PORT MAP (
    data1x => mcu_sel,
    data0x => ctlv1_sel_input,          -- stub
    sel    => '1',                      -- hardcoded for mcu control
    result => main_data_sel );

  -- SELECT FIFO EMPTY SIGNAL FROM CURRENT INPUT FIFO
  
  empty_signal_mux : COMPONENT mux_5_to_1 PORT MAP (
    data4  => infifo_empty(4),
    data3  => infifo_empty(3),
    data2  => infifo_empty(2),
    data1  => infifo_empty(1),
    data0  => infifo_empty(0),
    sel    => main_data_sel,
    result => input_fifo_empty );

  -- ROUTE INPUT FIFO READ SIGNAL TO CURRENT INPUT FIFO

  ctlv1_read_fe_fifo <= '0';  -- stub for control from large controller
  
  choose_source_for_input_read : mux_2to1_1bit PORT MAP (
    data1  => alwon_read_fe_fifo,
    data0  => ctlv1_read_fe_fifo,       -- stub
    sel    => '1',  -- hardcoded for control by "alwonctl"                                                      
    result => read_fifo_enable );                       

  fifo_read_decoder : decode_3to5_en PORT MAP (
    data   => main_data_sel,
    enable => read_fifo_enable,
    eq0    => read_input_fifo(0),
    eq1    => read_input_fifo(1),
    eq2    => read_input_fifo(2),
    eq3    => read_input_fifo(3),
    eq4    => read_input_fifo(4) );             

  -- SELECT SOURCE FOR WRITING TO MCU FIFO

  ctlv1_write_mcu_fifo <= '0';  -- stub for control from large controller
  
  choose_source_for_write_to_mcu_fifo : mux_2to1_1bit PORT MAP (
    data1  => alwon_wr_mcu_fifo,
    data0  => ctlv1_wr_mcu_fifo,        -- stub
    sel    => '1',  -- hardcoded for control by "alwonctl"                                                      
    result => write_mcu_fifo );                 

  -- shorten read fifo pulse from MCU
  
  shorten_mcu_rdfifo : COMPONENT SHORTEN PORT MAP (
    CLK         => clk,
    RESET       => reset,
    read_strobe => mcu_strobes_fifo,
    rd_fifo     => rd_mcu_fifo);

  -- OUTPUT TO MCU FIFO ******************************************************************************* 

  -- MCU FIFO:
  
  mcu_outfifo : COMPONENT output_fifo_256x32 PORT MAP (
    data  => inmux_dout,
    wrreq => write_mcu_fifo,
    rdreq => rd_mcu_fifo,
    clock => clk,
    aclr  => reset,
    q     => mcu_fifo_out,
    full  => mcu_fifo_full,
    empty => mcu_fifo_empty );

  -- OUTPUT TO DDL FIFOS *******************************************************************************        

  -- State machine "alwread" reads input fifo and writes to both mcu and ddl fifos. Each write 
  -- increments end_of_record_counter. When this counter reaches terminal count, then "end of record"
  -- input is selected as input to DDL FIFO.
  
  end_of_record_counter : count127 PORT MAP (
    clock  => clk,
    cnt_en => incr_end_of_record_cnt,
    aclr   => reset,
    q      => dummy7b,
    cout   => end_record_tc);   

  ddl_input_mux : mux_2x32 PORT MAP (
    data1x => X"EA000000",
    data0x => inmux_dout,
    sel    => end_record_tc,
    result => ddl_fifo_indata );

  -- final DDL fifo 
  
  final_ddl_fifo : COMPONENT output_fifo_256x32 PORT MAP (
    clock => clk,
    aclr  => reset,
    data  => ddl_fifo_indata,
    wrreq => write_mcu_fifo,
    rdreq => rd_ddl_fifo,
    q     => ddl_data,
    full  => ddlfifo_full,
    empty => ddlfifo_empty );   


  -- ********************************************************************************
  -- MCU interface
  -- ********************************************************************************
  
  mcu_adr(0)    <= mcuctl(0);
  mcu_adr(1)    <= mcuctl(1);
  mcu_adr(2)    <= mcuctl(2);
  readbar_write <= mcuctl(3);

  data_strobe <= pld_int;
  mcu_data    <= mcud;
  fifo_empty  <= mcu_fifo_empty;

  mcu_write_to_pld  <= data_strobe AND readbar_write;
  mcu_read_from_pld <= data_strobe AND (NOT readbar_write);
  
  mcu_bus : bus_tri_8 PORT MAP (
    data     => pld_to_mcu_before_buffer,  -- output data from pld logic to tristate bus
    enabledt => mcu_read_from_pld,      -- sets bidirectional pins to OUT
    enabletr => mcu_write_to_pld,       -- sets bidirectional pins to IN
    tridata  => mcu_data,               -- bidirectional to/from pins
    result   => mcu_to_pld_after_buffer );  -- input data from tristate bus to pld logic

  mcu_write_decoder : decoder_3_to_8 PORT MAP (
    data => mcu_adr,
    eq0  => mcu_decode(0),              -- write to mode register
    eq1  => mcu_decode(1),              -- write to config register
    eq2  => mcu_decode(2),              -- write to filter register
    eq3  => mcu_decode(3),
    eq4  => mcu_decode(4),
    eq5  => mcu_decode(5),
    eq6  => mcu_decode(6),              -- reset pld
    eq7  => mcu_decode(7) );            -- send bunch reset

  -- mcu writes to registers when strobe and adr produce valid register clk enables                
  -- registers that are written to by MCU  -------------------------------

  mode_reg_write <= mcu_decode(0) AND mcu_write_to_pld;
  
  mode_register : reg8_en PORT MAP (
    clock  => global40mhz,
    enable => mode_reg_write,
    sclr   => reset,
    data   => mcu_to_pld_after_buffer,
    q      => mcu_mode_data );

  -- config register:
  --            address = 1
  --            data(0) : 1 = ext trigger, 0 = internal trigger
  --                    controls trigger mux for trigger to TDIG boards

  config_reg_write <= mcu_decode(1) AND mcu_write_to_pld;
  
  config_register : reg8_en PORT MAP (
    clock  => global40mhz,
    enable => config_reg_write,
    sclr   => reset,
    data   => mcu_to_pld_after_buffer,
    q      => mcu_config_data );

  mcu_filter_reg_write <= mcu_decode(2) AND mcu_write_to_pld;
  
  mcu_filter_register : reg8_en PORT MAP (
    clock  => global40mhz,
    enable => mcu_filter_reg_write,
    sclr   => reset,
    data   => mcu_to_pld_after_buffer,
    q      => mcu_filter_sel );

  -- writing to adr = 6 resets the pld state machines, etc.
  mcu_reset_to_pld <= mcu_decode(6) AND mcu_write_to_pld;

  -- writing to adr = 7 sends bunch reset
  -- this signal is distributed to all TDCs from the master TCPU
  -- this signal must be gated with a configuration bit to differentiate
  -- between a master tcpu, which sends this signal, and a slave which receives it
  mcu_bunch_reset <= mcu_decode(7) AND mcu_write_to_pld;

  -- This pulse is synchronized because it comes from the MCU.
  -- it is 200ns wide, which is believed to be ok.  
  -- HPTDC will exit reset when the pulse goes low, regardless of
  -- the number of cycles it was held hi.

  cmd1 <= (MS_sel AND mcu_bunch_reset) OR (NOT MS_sel AND systrigin);

  systrig1 <= (MS_sel AND mcu_bunch_reset);
  systrig2 <= (MS_sel AND mcu_bunch_reset);


  -- MCU READS FROM PLD

  -- data mux that is read by MCU  -------------------------------
  
  mcu_read_mux : mux_8_by_8bit PORT MAP (
    data7x => X"00",
    data6x => X"00",  -- generate mcu fifo read pulse see 'mcu_strobes_fifo' signal
    data5x => mcu_fifo_out(7 DOWNTO 0),  -- read low byte                        
    data4x => mcu_fifo_out(15 DOWNTO 8),   -- read 2nd  byte
    data3x => mcu_fifo_out(23 DOWNTO 16),  -- read 3rd  byte
    data2x => mcu_fifo_out(31 DOWNTO 24),  -- read high fifo byte
    data1x => mcu_config_data,          -- readback config register
    data0x => mcu_mode_data,            -- readback mode register
    sel    => mcu_adr,
    result => pld_to_mcu_before_buffer );

  -- clock fifo strobe -- needs to be shortened to one clock wide
  -- Each time the mcu reads a 32b tdc word, it performs 4 data reads (1 byte each) and then
  -- a read to adr = 6, which generates a strobe that gives a read_enable pulse to the mcu fifo
  
  mcu_strobes_fifo <= mcu_read_from_pld AND mcu_adr(2) AND mcu_adr(1) AND ( NOT mcu_adr(0));
  
END ARCHITECTURE ver_four;

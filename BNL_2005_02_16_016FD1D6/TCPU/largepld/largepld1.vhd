-- $Id: largepld1.vhd,v 1.13 2005-02-15 22:25:15 jschamba Exp $
-- notes:

-- 1. 9/10/04: c1_m24, c2_m24, c3_m24, c4_m24   signals are used as the
--        data strobe for 4bit tdig tdc data. These are nominally the m24 data,
--    but m24 data is not implemented in RUN5.


-- Revisions:

-- 12/18/2004 Expanded control select muxes. Added state machine for 
-- reading all 4 input cables on receipt of L0 trigger.

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
      pld_int    : IN    std_logic;                     -- data strobe
      fifo_empty : OUT   std_logic;                     -- mcu fifo empty

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

  SIGNAL tdig1_data, tdig2_data : std_logic_vector(31 DOWNTO 0);
  SIGNAL tdig3_data, tdig4_data : std_logic_vector(31 DOWNTO 0);
  SIGNAL tdig_strobe            : std_logic_vector( 4 DOWNTO 1);  -- signal from cable demux to input fifo

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

  SIGNAL bus_enable, tristate_signal_enable, trigger_strobe_to_tdig, star_trigger_level_zero : std_logic;

  SIGNAL data_strobe, readbar_write                                              : std_logic;
  SIGNAL mcu_adr                                                                 : std_logic_vector(2 DOWNTO 0);
  SIGNAL mcu_data, pld_to_mcu_before_buffer, mcu_to_pld_after_buffer, mcu_decode : std_logic_vector(7 DOWNTO 0);
  SIGNAL mcu_mode_data, mcu_config_data, mcu_filter_sel                          : std_logic_vector(7 DOWNTO 0);
  SIGNAL mcu_write_to_pld, mcu_read_from_pld, mode_reg_write, config_reg_write   : std_logic;
  SIGNAL mcu_fifo_empty, mcu_filter_reg_write, mcu_bunch_reset, mcu_reset_to_pld : std_logic;
  SIGNAL mcu_fifo_out                                                            : std_logic_vector(31 DOWNTO 0);
  SIGNAL dummy_counter_out                                                       : std_logic_vector(14 DOWNTO 0);
  SIGNAL trig_from_ctr                                                           : std_logic;
  SIGNAL mcu_strobes_fifo                                                        : std_logic;
  SIGNAL cout, delaya, delayb, stretch, trig_presync                             : std_logic;

  -- INPUT FIFOS
  SIGNAL infifo0_dout : std_logic_vector (19 DOWNTO 0);  -- from tcd fifo
  SIGNAL infifo1_dout : std_logic_vector (31 DOWNTO 0);  -- from tdig  1 fifo
  SIGNAL infifo2_dout : std_logic_vector (31 DOWNTO 0);  -- from tdig  2 fifo
  SIGNAL infifo3_dout : std_logic_vector (31 DOWNTO 0);  -- from tdig  3 fifo
  SIGNAL infifo4_dout : std_logic_vector (31 DOWNTO 0);  -- from tcd  4 fifo

  SIGNAL read_input_fifo, infifo_full, infifo_empty : std_logic_vector(4 DOWNTO 0);

  -- JS: selectively disable infifo's for reading:
  SIGNAL infifo_emptyFlt : std_logic_vector (4 DOWNTO 1);
  -- JS: input FIFO reset signal to empty the FIFOs:
  SIGNAL infifo_reset : std_logic;

  SIGNAL inmux_dout : std_logic_vector (31 DOWNTO 0);
  SIGNAL inmux_sel  : std_logic_vector (2 DOWNTO 0);

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
  SIGNAL data_mux_sel, mcu_sel, main_data_sel, ctl_one_sel_input : std_logic_vector(2 DOWNTO 0);
  SIGNAL mcu_sel_empty                                           : std_logic;

  SIGNAL dummy                                                       : std_logic;
  SIGNAL error1                                                      : std_logic_vector(7 DOWNTO 0);
  SIGNAL ctl_one_read_fe_fifo, input_fifo_empty, ctl_one_wr_mcu_fifo : std_logic;
  SIGNAL ctl0_read_fe_fifo, ctl0_wr_mcu_fifo, write_mcu_fifo         : std_logic;
  SIGNAL clk, read_fifo_enable, ctl_one_write_mcu_fifo               : std_logic;
  SIGNAL end_record_tc, incr_end_of_record_cnt                       : std_logic;
  SIGNAL dummy7b                                                     : std_logic_vector(6 DOWNTO 0);

  -- signal which selects which state machine is in control (set by MCU config bit)
  SIGNAL control_select, incr_sel, clr_sel, sel_eq_0 : std_logic;
  SIGNAL sel_eq_3                                    : std_logic;
  SIGNAL clr_timeout, timeout_valid                  : std_logic;
  SIGNAL ctr_sel                                     : std_logic_vector(2 DOWNTO 0);

  SIGNAL ctl_one_trigger_to_tdc : std_logic;

  -- signals decoded from trigger command bits
  SIGNAL CMD_L0, CMD_L2, CMD_ABORT, CMD_RESET, CMD_IGNORE : std_logic;
  SIGNAL separator                                        : std_logic;

  -- signals to control input to DDL fifo 
  SIGNAL stuff_sel_dout            : std_logic_vector(31 DOWNTO 0);
  SIGNAL ddl_in_sel, ctl_one_stuff : std_logic;

  -- ********************************************************************************
  -- DDL bidir signals separated into IN and OUT (JS)
  -- ********************************************************************************
  SIGNAL s_fiD      : std_logic_vector (31 DOWNTO 0);   -- corresponds to ddl_fbd (IN)
  SIGNAL s_foD      : std_logic_vector (31 DOWNTO 0);   -- corresponds to ddl_fbd (OUT)
  SIGNAL s_fiTEN_N  : std_logic;                        -- corresponds to ddl_fbten_N (IN)
  SIGNAL s_foTEN_N  : std_logic;                        -- corresponds to ddl_fbten_N (OUT)
  SIGNAL s_fiCTRL_N : std_logic;                        -- corresponds to ddl_fbctrl_N (IN)
  SIGNAL s_foCTRL_N : std_logic;                        -- corresponds to ddl_fbctrl_N (OUT)
  SIGNAL s_runReset : std_logic;        		-- Reset external logic at Run Start
  SIGNAL s_fifoRst : std_logic;         		-- signal to empty the FIFOs
  
  -- new signals

  SIGNAL mode_0_reset, mode_1_reset : std_logic;            -- state machine reset signals decoded from mode bit(s)
  
  SIGNAL geo_data       : std_logic_vector (31 DOWNTO 0);
  SIGNAL stuff_value    : std_logic_vector (31 DOWNTO 0);   -- stuff value selected by control_one state machine
  SIGNAL stuff          : std_logic_vector ( 1 DOWNTO 0);   -- control signal from control_one which selects stuff value

  CONSTANT separator_id : std_logic_vector (3 DOWNTO 0) := "1110";


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
  
  trig_from_ctr_counter : trigger_counter_15bit PORT MAP (
    clock  => global40mhz,
    cnt_en => '1',
    aclr   => '0',
    q      => dummy_counter_out,
    cout   => cout );

  -- ROUTING TRIGGER INPUT TO tdc trigger input over ribbon cable                       

  -- use ext trigger if config bit not set
  -- or internal trigger if config bit set
  
  turn_off_trigger : mux_2to1_1bit PORT MAP (
    data0  => '0',
    data1  => cout,
    sel    => mcu_config_data(0),
    result => trig_from_ctr ); 

  trigger_mux : mux_2to1_1bit PORT MAP (
    data0  => trig_from_ctr,
    data1  => ctl_one_trigger_to_tdc,
    sel    => control_select,
    result => trig_presync );  

  -- stretch final trigger pulse and send to TDCs over ribbon cable          
  
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

  -- TO TEST USING AN EXTERNAL PULSE GENERATOR, USE THE FOLLOWING LINE:

  -- tdctrig <= systrigin;   -- external pulse generator at J39 (remember PECL input levels)

  -- Turn on TDIG clocks:

  enable_trayclks <= '1';

  --------------------------------------------------------------------------------------

  ddl_read_fifo <= '1';

  opmode <= "00000001";

  -- make clock and reset global

  global_clk_buffer : global PORT MAP (a_in => pldclk0, a_out => global40mhz);
  clk <= global40mhz;

  -- global_reset_buffer : global PORT MAP (a_in => '0', a_out => reset);
  global_reset_buffer : global PORT MAP (a_in   => mcu_reset_to_pld,   
                                         a_out  => reset);  

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
    ext_trg    => button_debounced,	-- external trigger (for testing)
    run_reset  => s_runReset, 		-- external logic reset at run start
    reset      => reset,
    fifo_q     => ddl_data,
    fifo_empty => ddlfifo_empty,
    fifo_rdreq => rd_ddl_fifo
    );

  -- INPUT SECTION ******************************************************************************* 
  --
  -- TCPU receives input data from 5 sources: 4 TDIG tray cables and 1 TCD cable
  -- This section demultiplexes each of these data streams and writes the data to
  -- a fifo. A 5 input mux selects which of the sources will feed the data path to
  -- the DDL and MCU fifos. The mux control and the fifo controls come from the 
  -- currently selected control state machine.   

  s_fifoRst <= reset OR s_runReset;
  infifo_reset <= s_fifoRst OR ctl_one_trigger_to_tdc;
  
  tdig_input_1 : COMPONENT ser_4bit_to_par PORT MAP (
    clk           => global40mhz,
    reset         => reset,
    din           => c1_m7d(3 DOWNTO 0),
    dclk          => c1_dclk,
    dstrobe       => c1_m7d(4),         -- data strobe is active for 8 dclks 
    dout          => tdig1_data,
    output_strobe => tdig_strobe(1) );

  -- tdc1_fifo : COMPONENT input_fifo_64x32 PORT MAP (
  tdc1_fifo : COMPONENT input_fifo_256x32 PORT MAP (
    clock => clk,
    aclr  => infifo_reset, -- reset,
    data  => tdig1_data,
    wrreq => tdig_strobe(1),
    rdreq => read_input_fifo(1),
    q     => infifo1_dout,
    full  => infifo_full(1),
    empty => infifo_empty(1) );

  tdig_input_2 : COMPONENT ser_4bit_to_par PORT MAP (
    clk           => global40mhz,
    reset         => reset,
    din           => c2_m7d(3 DOWNTO 0),
    dclk          => c2_dclk,
    dstrobe       => c2_m7d(4),         -- data strobe is active for 8 dclks 
    dout          => tdig2_data,
    output_strobe => tdig_strobe(2) );

  -- tdc2_fifo : COMPONENT input_fifo_64x32 PORT MAP (
  tdc2_fifo : COMPONENT input_fifo_256x32 PORT MAP (
    clock => clk,
    aclr  => infifo_reset, -- reset,
    data  => tdig2_data,
    wrreq => tdig_strobe(2),
    rdreq => read_input_fifo(2),
    q     => infifo2_dout,
    full  => infifo_full(2),
    empty => infifo_empty(2) ); 

  tdig_input_3 : COMPONENT ser_4bit_to_par PORT MAP (
    clk           => global40mhz,
    reset         => reset,
    din           => c3_m7d(3 DOWNTO 0),
    dclk          => c3_dclk,
    dstrobe       => c3_m7d(4),         -- data strobe is active for 8 dclks 
    dout          => tdig3_data,
    output_strobe => tdig_strobe(3) );

  -- tdc3_fifo : COMPONENT input_fifo_64x32 PORT MAP (
  tdc3_fifo : COMPONENT input_fifo_256x32 PORT MAP (
    clock => clk,
    aclr  => infifo_reset, -- reset,
    data  => tdig3_data,
    wrreq => tdig_strobe(3),
    rdreq => read_input_fifo(3),
    q     => infifo3_dout,
    full  => infifo_full(3),
    empty => infifo_empty(3) );

  tdig_input_4 : COMPONENT ser_4bit_to_par PORT MAP (
    clk           => global40mhz,
    reset         => reset,
    din           => c4_m7d(3 DOWNTO 0),
    dclk          => c4_dclk,
    dstrobe       => c4_m7d(4),         -- data strobe is active for 8 dclks 
    dout          => tdig4_data,
    output_strobe => tdig_strobe(4) );

  -- tdc4_fifo : COMPONENT input_fifo_64x32 PORT MAP (
  tdc4_fifo : COMPONENT input_fifo_256x32 PORT MAP (
    clock => clk,
    aclr  => infifo_reset, -- reset,
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
    aclr  => s_fifoRst, -- reset,
    data  => tcd_data,
    wrreq => tcd_strobe,
    rdreq => read_input_fifo(0),
    q     => infifo0_dout,
    full  => infifo_full(0),
    empty => infifo_empty(0) );

  infifo_mux : COMPONENT mux_5x32_unreg PORT MAP (
    data0x(31 DOWNTO 20) => X"A00",
    data0x(19 DOWNTO 0)  => infifo0_dout,
    data1x               => infifo1_dout,
    data2x               => infifo2_dout,
    data3x               => infifo3_dout,
    data4x               => infifo4_dout,
    sel                  => main_data_sel,
    result               => inmux_dout );                        

  -- CONTROL SECTION *******************************************************************************            

  control_select <= mcu_mode_data(0);  -- selects between CTL0 and ctl_one as main controller

  -- Currently 2 possible controllers:

  -- Active controller is selected by mcu_mode_data(0).
  -- Then multiplexers select signals to/from the active controller to go to/from data path     

  -- CTL0: This controller always reads a single front-end fifo that is selected by the mcu.

  mode_0_reset <= control_select;       -- "control_select" = mcu_config[0]
  
  CTL0 : COMPONENT alwread PORT MAP (
    CLK      => clk,
    RESET    => mode_0_reset,
    empty    => input_fifo_empty,
    rd_fifo  => ctl0_read_fe_fifo,
    wr_fifo  => ctl0_wr_mcu_fifo,
    incr_cnt => incr_end_of_record_cnt);  -- increment end of record counter
                                          -- ovf from counter selects "E700 0000" word 

  -- control_one: This controller looks for L0 commands and then builds an event record from all
  -- 4 TDIG data streams.


  -- this signal detects that select ctr has rolled over to initial state
  sel_eq_0 <= bool2sl(ctr_sel = "000");
  -- this signal detects that select ctr has moved to next half tray
  sel_eq_3 <= bool2sl(ctr_sel = "011");
  
  mode_1_reset <= NOT control_select;   -- "control_select" = mcu_config[0]
  
  Control_one : COMPONENT CTL_ONE PORT MAP (
    clk           => clk,
    reset         => mode_1_reset,
    cmd_l0        => CMD_L0,
    fifo_empty    => input_fifo_empty,
    sel_eq_0      => sel_eq_0,
    sel_eq_3	  => sel_eq_3,
    separator     => separator,
    timeout       => timeout_valid,
    clr_sel       => clr_sel,
    clr_timeout   => clr_timeout,
    incr_sel      => incr_sel,
    rd_fifo       => ctl_one_read_fe_fifo,
    trig_to_tdc   => ctl_one_trigger_to_tdc,
    wr_fifo       => ctl_one_wr_mcu_fifo,
    ctl_one_stuff => ctl_one_stuff,
    stuff0        => stuff(0),
    stuff1        => stuff(1) );

  -- controllers increment this counter to cycle through the input fifos
  -- counter counts from 0 to 4
  main_mux_select_counter : COMPONENT data_sel_ctr PORT MAP (
    clock  => clk,
    cnt_en => incr_sel,
    sclr   => clr_sel,
    aclr   => reset,
    q      => ctr_sel );                -- 3 bits

  -- controllers use this timeout counter to switch between input fifos if 
  -- there is no separator from a TDIG link within the timeout period
  timeout_counter : COMPONENT timeout PORT MAP (
    clk           => clk,
    reset         => reset,
    clr_timeout   => clr_timeout,
    timeout_valid => timeout_valid );

  -- decoder for trigger commands and separator word
  command_decode : PROCESS (inmux_dout) IS
  BEGIN
    IF (inmux_dout(31 DOWNTO 28) = separator_id) THEN
      separator <= '1';
    ELSE
      separator <= '0';
    END IF;

    CMD_L0     <= '0';
    CMD_L2     <= '0';
    CMD_ABORT  <= '0';
    CMD_RESET  <= '0';
    CMD_IGNORE <= '0';

    CASE inmux_dout(19 DOWNTO 16) IS    -- trigger_command
      WHEN "0000" => CMD_IGNORE <= '1';
      WHEN "0001" => CMD_IGNORE <= '1';
      WHEN "0010" => CMD_RESET  <= '1';
      WHEN "0011" => CMD_IGNORE <= '1';
      WHEN "0100" => CMD_L0     <= '1';
      WHEN "0101" => CMD_L0     <= '1';
      WHEN "0110" => CMD_L0     <= '1';
      WHEN "0111" => CMD_L0     <= '1';
      WHEN "1000" => CMD_L0     <= '1';
      WHEN "1001" => CMD_L0     <= '1';
      WHEN "1010" => CMD_L0     <= '1'; 
      WHEN "1011" => CMD_L0     <= '1'; 
      WHEN "1100" => CMD_L0     <= '1'; 
      WHEN "1101" => CMD_ABORT  <= '1';
      WHEN "1110" => CMD_IGNORE <= '1';
      WHEN "1111" => CMD_L2     <= '1';
    END CASE;
  END PROCESS command_decode;

  -- CHOOSE INPUT DATA SOURCE

  mcu_sel           <= mcu_config_data(3 DOWNTO 1);
  ctl_one_sel_input <= "000";  -- stub for control from large state machine
  
  choose_source_for_input_mux_select_bits : two_by_3bit_mux PORT MAP (
    data0x => mcu_sel,  -- mcu config register selects data at mux
    data1x => ctr_sel,  -- mux select counter selects data at mux (controller clocks counter)
    sel    => control_select,
    result => main_data_sel );

  -- SELECT FIFO EMPTY SIGNAL FROM CURRENT INPUT FIFO
  -- JS: first, selectively set each fifo_empty to '1'
  G1: FOR i IN 0 TO 3 GENERATE
    WITH mcu_config_data(4+i) SELECT
      infifo_emptyFlt(1+i) <=
      infifo_empty(1+i) WHEN '0',
      '1'               WHEN OTHERS;
    
  END GENERATE G1;

  empty_signal_mux : COMPONENT mux_5_to_1 PORT MAP (
    data4  => infifo_emptyFlt(4),
    data3  => infifo_emptyFlt(3),
    data2  => infifo_emptyFlt(2),
    data1  => infifo_emptyFlt(1),
    data0  => infifo_empty(0),
    sel    => main_data_sel,
    result => input_fifo_empty );

  -- ROUTE INPUT FIFO READ SIGNAL TO CURRENT INPUT FIFO
  
  choose_source_for_input_read : mux_2to1_1bit PORT MAP (
    data0  => ctl0_read_fe_fifo,
    data1  => ctl_one_read_fe_fifo,
    sel    => control_select,
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
  
  choose_source_for_write_to_mcu_fifo : mux_2to1_1bit PORT MAP (
    data0  => ctl0_wr_mcu_fifo,
    data1  => ctl_one_wr_mcu_fifo,
    sel    => control_select,
    result => write_mcu_fifo );                 

  -- shorten read fifo pulse from MCU
  
  shorten_mcu_rdfifo : COMPONENT SHORTEN PORT MAP (
    CLK         => clk,
    RESET       => reset,
    read_strobe => mcu_strobes_fifo,
    rd_fifo     => rd_mcu_fifo);

  -- OUTPUT TO MCU FIFO ******************************************************************************* 

  -- MCU FIFO:
  
  -- mcu_outfifo : COMPONENT output_fifo_1024x32 PORT MAP (
  mcu_outfifo : COMPONENT output_fifo_2048x32 PORT MAP (
    data  => inmux_dout,
    wrreq => write_mcu_fifo,
    rdreq => rd_mcu_fifo,
    clock => clk,
    aclr  => reset,
    q     => mcu_fifo_out,
    full  => mcu_fifo_full,
    empty => mcu_fifo_empty );

  -- OUTPUT TO DDL FIFOS *******************************************************************************        

  -- State machine CTL0 reads input fifo and writes to both mcu and ddl fifos. Each write 
  -- increments end_of_record_counter. When this counter reaches terminal count, then "end of record"
  -- input is selected as input to DDL FIFO.
  
  end_of_record_counter : count127 PORT MAP (  -- used with ctl0 to select "end of record" value
                                               -- after set number of noise values
    clock  => clk,
    cnt_en => incr_end_of_record_cnt,
    aclr   => reset,
    q      => dummy7b,                  -- q output not used
    cout   => end_record_tc); 

  ddl_stuff_ctl : mux_2to1_1bit PORT MAP (  -- selects which state machine controls the mux
                                            -- to stuff non data values into DDL
    data1  => ctl_one_stuff,
    data0  => end_record_tc,
    sel    => control_select,
    result => ddl_in_sel );  

  -- Geographical data depends on the grey cable currently selected:
  geo_data <= X"C00000BA" OR (X"0000000" & "000" & sel_eq_3);
  
  ddl_stuff_mux1 : mux_4x32 PORT MAP (  -- selects between data path value and stuff value
                                        -- according to select input from ddl_stuff_ctl mux
    data3x => geo_data,                 -- geographical data, tray 93, half tray 0 or 1
    data2x => X"EA000000",
    data1x => X"DEADFACE",
    data0x => X"B0000000",
    sel    => stuff,
    result => stuff_value );

  ddl_stuff_mux2 : mux_2x32 PORT MAP (  -- mux to select between static stuff value "EA000000" from control zero
                                        -- or dynamic stuff value from control one
    data1x => stuff_value,
    data0x => X"EA000000",
    sel    => control_select,
    result => stuff_sel_dout );	
    
  ddl_input_mux : mux_2x32 PORT MAP (   -- selects between stuff values and main data mux values
    data1x => stuff_sel_dout,           -- from stuff data mux       
    data0x => inmux_dout,               -- from main 5 way data path mux
    sel    => ddl_in_sel,
    result => ddl_fifo_indata );

  -- final DDL fifo 
  
  -- final_ddl_fifo : COMPONENT output_fifo_1024x32 PORT MAP (
  final_ddl_fifo : COMPONENT output_fifo_2048x32 PORT MAP (
    clock => clk,
    aclr  => s_fifoRst, -- reset,
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
    data     => pld_to_mcu_before_buffer,   -- output data from pld logic to tristate bus
    enabledt => mcu_read_from_pld,          -- sets bidirectional pins to OUT
    enabletr => mcu_write_to_pld,           -- sets bidirectional pins to IN
    tridata  => mcu_data,                   -- bidirectional to/from pins
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
    data6x => X"00",                       -- generate mcu fifo read pulse see 'mcu_strobes_fifo' signal
    data5x => mcu_fifo_out(7 DOWNTO 0),    -- read low byte                        
    data4x => mcu_fifo_out(15 DOWNTO 8),   -- read 2nd  byte
    data3x => mcu_fifo_out(23 DOWNTO 16),  -- read 3rd  byte
    data2x => mcu_fifo_out(31 DOWNTO 24),  -- read high fifo byte
    data1x => mcu_config_data,             -- readback config register
    data0x => mcu_mode_data,               -- readback mode register
    sel    => mcu_adr,
    result => pld_to_mcu_before_buffer );

  -- clock fifo strobe -- needs to be shortened to one clock wide
  -- Each time the mcu reads a 32b tdc word, it performs 4 data reads (1 byte each) and then
  -- a read to adr = 6, which generates a strobe that gives a read_enable pulse to the mcu fifo
  
  mcu_strobes_fifo <= mcu_read_from_pld AND mcu_adr(2) AND mcu_adr(1) AND ( NOT mcu_adr(0));
  
END ARCHITECTURE ver_four;

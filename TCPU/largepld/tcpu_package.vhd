LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;

PACKAGE tcpu_package IS

  -- components from primitives

  -- to use the global primitive in modelsim: add the following lines
  -- to the source file:

  -- LIBRARY altera_mf;
  -- USE altera_mf.altera_mf_components.all;


  --COMPONENT GLOBAL
  --PORT (a_in : IN STD_LOGIC;
  --a_out: OUT STD_LOGIC);
  --END COMPONENT;

  -- tri-state and bidirectional buffers *****************************       
  
  COMPONENT bus_tri_8 PORT (
    data     : IN    std_logic_vector (7 DOWNTO 0);
    enabledt : IN    std_logic;
    enabletr : IN    std_logic;
    tridata  : INOUT std_logic_vector (7 DOWNTO 0);
    result   : OUT   std_logic_vector (7 DOWNTO 0));
  END COMPONENT;

  -- ********************************************************************************
  -- DDL COMPONENT definition (JS)
  -- ********************************************************************************
  COMPONENT ddl
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
        fifo_empty : IN  std_logic;                      -- interface fifo "emtpy" signal
        ext_trg    : IN  std_logic;                      -- external trigger
        run_reset  : OUT std_logic;                      -- external logic reset at Run Start
        foD        : OUT std_logic_vector(31 DOWNTO 0);
        foBSY_N    : OUT std_logic;
        foCTRL_N   : OUT std_logic;
        foTEN_N    : OUT std_logic;
        fifo_rdreq : OUT std_logic                       -- interface fifo read request
                                                         -- (fifo should be clocked by same clock that 
                                                         --  drives fiCLK)
        );
  END COMPONENT;

  -- test module to fill the interface FIFO
  COMPONENT fifo_filler
    PORT (
      clock      : IN  std_logic;
      arstn      : IN  std_logic;
      trigger    : IN  std_logic;
      rdreq      : IN  std_logic;
      q          : OUT std_logic_vector (31 DOWNTO 0);
      fifo_empty : OUT std_logic
      );
  END COMPONENT;

  COMPONENT timer IS
    GENERIC (CTR_WIDTH : positive);
    PORT (
      clk     : IN  std_logic;
      trigger : OUT std_logic
      );
  END COMPONENT;

  -- controllers and state machines *****************************
  
  COMPONENT CTL_ONE IS PORT (
    CLK, CMD_ABORT, CMD_L0, CMD_L2, FIFO_EMPTY, L2_TIMEOUT : IN  std_logic;
    RESET, SEL_EQ_0, SEPARATOR, TIMEOUT, SEL_EQ_3          : IN  std_logic;
    CLR_L2, CLR_SEL, CLR_TIMEOUT, CTL_ONE_STUFF, INCR_SEL  : OUT std_logic;
    RD_FIFO, STUFF0, STUFF1, TRIG_TO_TDC, WR_FIFO, XFER_L2 : OUT std_logic);
  END COMPONENT;
  
  COMPONENT ALWREAD IS PORT (
    CLK, empty, RESET          : IN  std_logic;
    incr_cnt, rd_fifo, wr_fifo : OUT std_logic);
  END COMPONENT;
  
  COMPONENT SHORTEN IS PORT (
    CLK, read_strobe, RESET : IN  std_logic;
    rd_fifo                 : OUT std_logic);
  END COMPONENT;

  COMPONENT CTL32TO4 IS PORT (
    CTR                    : OUT std_logic_vector (3 DOWNTO 0);
    CLK, DIN_STROBE, RESET : IN  std_logic;
    DOUT_STROBE, READY     : OUT std_logic);
  END COMPONENT;

  COMPONENT MCU_BOSS IS PORT (
    CLK, mcu_boss_enable, read_strobe, RESET : IN  std_logic;
    rd_fifo, wr_fifo                         : OUT std_logic);
  END COMPONENT;

  COMPONENT pushbutton_pulse
    PORT(clk, reset  : IN  std_logic;
          pushbutton : IN  std_logic;
          pulseout   : OUT std_logic);
  END COMPONENT;
  
  COMPONENT TDIGCTL IS PORT (
    CLK, DATA_ENABLE, FIFO_DS_EMPTY, OUTPUT_BUSY, POS_DNSTRM, RESET, SEPARATOR,
    TDC_FIFO_EMPTY, TRIGGER_PULSE                               : IN  std_logic;
    EN_TDC_RDO, RD_DS_FIFO, RD_TDC_FIFO, SEL_DS_FIFO, WR_OUTPUT : OUT std_logic);
  END COMPONENT;
  
  COMPONENT ser_rdo PORT (
    ser_out   : IN  std_logic;
    strb_out  : IN  std_logic;
    token_out : IN  std_logic;
    trigger   : IN  std_logic;
    trg_reset : IN  std_logic;
    token_in  : OUT std_logic;

    clk, reset     : IN  std_logic;
    mcu_pld_int    : IN  std_logic;
    pld_mcu_int    : OUT std_logic;
    mcu_byte       : OUT std_logic_vector (7 DOWNTO 0);
    fifo_empty     : OUT std_logic;
    rdo_32b_data   : OUT std_logic_vector(31 DOWNTO 0);
    rdo_data_valid : OUT std_logic;
    sw             : IN  std_logic_vector(2 DOWNTO 0);  -- position switch input for separator word );       
    no_separator   : IN  std_logic;                     -- TDIG config bit for noise testing
    no_trigger     : IN  std_logic);                    -- TDIG config bit for noise testing
  END COMPONENT;

  COMPONENT ctl4to32 IS
    PORT (CLK, DSTROBE, RESET : IN  std_logic;
          REGA_EN             : OUT std_logic);
  END COMPONENT;

  COMPONENT sm_sync_enable IS
    PORT(rega_enable   : IN  std_logic;
          clk, reset   : IN  std_logic;  -- reset is async               
          regb_enable  : OUT std_logic;  -- clock enable for register b
          output_valid : OUT std_logic
          ); 
  END COMPONENT;
  
  COMPONENT data_path_control IS PORT (
    clk, reset      : IN  std_logic;
    op_mode         : IN  std_logic_vector(7 DOWNTO 0);
    current_data    : IN  std_logic_vector(31 DOWNTO 0);
    in_fifo_empty   : IN  std_logic_vector(4 DOWNTO 0);
    select_input    : OUT std_logic_vector(2 DOWNTO 0);
    read_input_fifo : OUT std_logic_vector(4 DOWNTO 0);
    write_ddl_fifo  : OUT std_logic_vector(1 DOWNTO 0);
    ddl_fifo_sel    : OUT std_logic;    -- select signal for ping-pong output fifos    
    error1          : OUT std_logic_vector(7 DOWNTO 0);
    trigger_pulse   : OUT std_logic;
    wr_final_fifo   : OUT std_logic;
    mcu_mode        : IN  std_logic_vector(7 DOWNTO 0);
    mcu_config      : IN  std_logic_vector(7 DOWNTO 0);
    mcu_filter_sel  : IN  std_logic_vector(7 DOWNTO 0);
    wr_mcu_fifo     : OUT std_logic;
    rd_mcu_fifo     : IN  std_logic);                                                       
  END COMPONENT;

  COMPONENT CTLV1 IS
    PORT (CLK, CMD_ABORT, CMD_IGNORE, CMD_L0, CMD_L2, CMD_RESET, FIFO_EMPTY, OPMODE1,
          RESET, SEL_EQ_0, SEPARATOR, TIMEOUT, TRIG_EQ_TOKEN : IN std_logic;

          CLR_FIFO_OUT, CLR_INFIFO, CLR_OUTFIFO, CLR_SEL, CLR_TDC, CLR_TIMEOUT, CLR_TOGGLE,
          CLR_TOKEN, ERROR2, INCR_SEL, RD_FIFO, SW_DDL_FIFO, TRIG_TO_TDC, WR_DDL, WR_FIFO,
          WR_L2_REG, WR_MCU, WR_MCU_ERROR, WR_MCU_FIFO : OUT std_logic);
  END COMPONENT;

  -- data path elements *****************************
  
  COMPONENT par32_to_ser4 IS PORT(
    clk              : IN  std_logic;
    reset            : IN  std_logic;
    din              : IN  std_logic_vector(31 DOWNTO 0);
    din_strobe       : IN  std_logic;                     -- synchronous with input data: used as clock enable 
    -- for input register and initiates state machine ctr         
    dout             : OUT std_logic_vector(3 DOWNTO 0);
    dclk             : OUT std_logic;                     -- source synchronous clock transmitted with data over cable
    dout_strobe      : OUT std_logic;                     -- data strobe transmitted with data over cable
    -- this signal goes low after last of 8 4bit words is xmitted
    ready            : OUT std_logic;                     -- status that counter is idle
    vis_ctr_val      : OUT std_logic_vector(3 DOWNTO 0);  -- state machine counter
    vis_count_enable : OUT std_logic                      -- control flip flop output
    );
  END COMPONENT par32_to_ser4;

  COMPONENT ser_4bit_to_par IS
    PORT(din            : IN  std_logic_vector(3 DOWNTO 0);   -- data from xmit board
          dclk          : IN  std_logic;                      -- source synchronous clock from xmit board
          dstrobe       : IN  std_logic;                      -- strobe from xmit board that marks word boundary
                                                              -- serves as data valid to enable clock to 4bit register
          clk           : IN  std_logic;                      -- master receive clk
          reset         : IN  std_logic;                      -- synchronous reset 
                                                              -- dclk and clk must have constant phase difference
          dout          : OUT std_logic_vector(31 DOWNTO 0);  -- parallel data word output to TCPU fifo 
          output_strobe : OUT std_logic
          --rega_en, regb_en : out std_logic -- test pins
          );

  END COMPONENT ser_4bit_to_par;

  COMPONENT trigger_interface IS
    PORT(clk, reset     : IN  std_logic;
          tcd_4bit_data : IN  std_logic_vector(3 DOWNTO 0);
          tcd_clk_50mhz : IN  std_logic;
          tcd_clk_10mhz : IN  std_logic;
          tcd_word      : OUT std_logic_vector(19 DOWNTO 0);
          tcd_strobe    : OUT std_logic);           
  END COMPONENT;

  COMPONENT core_data_path_verb IS
    PORT(clk, reset            : IN  std_logic;
          trigger_input_strobe : IN  std_logic;
          tdig_input_strobe    : IN  std_logic_vector(4 DOWNTO 1);
          tcd_data             : IN  std_logic_vector(19 DOWNTO 0);
          tdig1_data           : IN  std_logic_vector(31 DOWNTO 0);
          tdig2_data           : IN  std_logic_vector(31 DOWNTO 0);
          tdig3_data           : IN  std_logic_vector(31 DOWNTO 0);
          tdig4_data           : IN  std_logic_vector(31 DOWNTO 0);
          final_data           : OUT std_logic_vector(31 DOWNTO 0);
          mcu_fifo_out         : OUT std_logic_vector(31 DOWNTO 0);
          mcu_fifo_empty       : OUT std_logic;
          ddl_read_fifo        : IN  std_logic;
          error                : OUT std_logic_vector(7 DOWNTO 0);
          op_mode              : IN  std_logic_vector(7 DOWNTO 0);
          tdc_strobe           : OUT std_logic;
          mcu_filter_sel       : IN  std_logic_vector(7 DOWNTO 0);
          mcu_config           : IN  std_logic_vector(7 DOWNTO 0);
          mcu_mode             : IN  std_logic_vector(7 DOWNTO 0);
          mcu_strobes_fifo     : IN  std_logic);
  END COMPONENT;

  -- registers **********************************
  
  COMPONENT reg8_en PORT (
    clock  : IN  std_logic;
    enable : IN  std_logic;
    sclr   : IN  std_logic;
    data   : IN  std_logic_vector (7 DOWNTO 0);
    q      : OUT std_logic_vector (7 DOWNTO 0));
  END COMPONENT;

  COMPONENT reg4_en_aclr IS
    PORT (clock   : IN  std_logic;
           enable : IN  std_logic;
           aclr   : IN  std_logic;
           data   : IN  std_logic_vector (3 DOWNTO 0);
           q      : OUT std_logic_vector (3 DOWNTO 0));
  END COMPONENT;

  COMPONENT reg4_en IS
    PORT(clock  : IN  std_logic;
         enable : IN  std_logic;
         sclr   : IN  std_logic;
         data   : IN  std_logic_vector (3 DOWNTO 0);
         q      : OUT std_logic_vector (3 DOWNTO 0));
  END COMPONENT;


  COMPONENT reg20_en
    PORT (clock   : IN  std_logic;
           enable : IN  std_logic;
           sclr   : IN  std_logic;
           aclr   : IN  std_logic;
           data   : IN  std_logic_vector (19 DOWNTO 0);
           q      : OUT std_logic_vector (19 DOWNTO 0));
  END COMPONENT;

  COMPONENT reg32_en                    -- 32 bit D register with clock enable
    PORT
      (
        clock  : IN  std_logic;
        enable : IN  std_logic;
        sclr   : IN  std_logic;
        data   : IN  std_logic_vector (31 DOWNTO 0);
        q      : OUT std_logic_vector (31 DOWNTO 0)
        );
  END COMPONENT;

  -- flip flops ***********************************
  
  COMPONENT DFF_generic PORT (
    clock  : IN  std_logic;
    enable : IN  std_logic;
    sclr   : IN  std_logic;
    sset   : IN  std_logic;
    aclr   : IN  std_logic;
    aset   : IN  std_logic;
    data   : IN  std_logic;
    q      : OUT std_logic);
  END COMPONENT;

  COMPONENT DFF_sclr
    PORT (clock : IN  std_logic;
           sclr : IN  std_logic;
           aclr : IN  std_logic;
           data : IN  std_logic;
           q    : OUT std_logic);
  END COMPONENT;

  COMPONENT DFF_sclr_sset
    PORT(clock : IN  std_logic;
         sclr  : IN  std_logic;
         sset  : IN  std_logic;
         data  : IN  std_logic;
         q     : OUT std_logic);
  END COMPONENT;

  COMPONENT tff_sclr PORT (
    clock : IN  std_logic;
    sclr  : IN  std_logic;
    q     : OUT std_logic);
  END COMPONENT;

  -- decoders  ***************************************************
  
  COMPONENT decoder_3_to_8 PORT (
    data : IN  std_logic_vector (2 DOWNTO 0);
    eq0  : OUT std_logic;
    eq1  : OUT std_logic;
    eq2  : OUT std_logic;
    eq3  : OUT std_logic;
    eq4  : OUT std_logic;
    eq5  : OUT std_logic;
    eq6  : OUT std_logic;
    eq7  : OUT std_logic);
  END COMPONENT;

  -- multiplexers ***************************************************

  COMPONENT mux_2x32 PORT (
    data1x : IN  std_logic_vector (31 DOWNTO 0);
    data0x : IN  std_logic_vector (31 DOWNTO 0);
    sel    : IN  std_logic;
    result : OUT std_logic_vector (31 DOWNTO 0));
  END COMPONENT;

  COMPONENT mux_2to1_1bit PORT (
    data1  : IN  std_logic;
    data0  : IN  std_logic;
    sel    : IN  std_logic;
    result : OUT std_logic);
  END COMPONENT;

  COMPONENT mux_5_to_1 PORT (
    data4  : IN  std_logic;
    data3  : IN  std_logic;
    data2  : IN  std_logic;
    data1  : IN  std_logic;
    data0  : IN  std_logic;
    sel    : IN  std_logic_vector (2 DOWNTO 0);
    result : OUT std_logic);
  END COMPONENT;
  
  COMPONENT mux_3_by_32 PORT (
    data2x : IN  std_logic_vector (31 DOWNTO 0);
    data1x : IN  std_logic_vector (31 DOWNTO 0);
    data0x : IN  std_logic_vector (31 DOWNTO 0);
    sel    : IN  std_logic_vector (1 DOWNTO 0);
    result : OUT std_logic_vector (31 DOWNTO 0));
  END COMPONENT;

  COMPONENT mux_4x32 PORT (
    data3x : IN  std_logic_vector (31 DOWNTO 0);
    data2x : IN  std_logic_vector (31 DOWNTO 0);
    data1x : IN  std_logic_vector (31 DOWNTO 0);
    data0x : IN  std_logic_vector (31 DOWNTO 0);
    sel    : IN  std_logic_vector (1 DOWNTO 0);
    result : OUT std_logic_vector (31 DOWNTO 0));
  END COMPONENT;

  COMPONENT mux_8_by_8bit PORT (
    data7x : IN  std_logic_vector (7 DOWNTO 0);
    data6x : IN  std_logic_vector (7 DOWNTO 0);
    data5x : IN  std_logic_vector (7 DOWNTO 0);
    data4x : IN  std_logic_vector (7 DOWNTO 0);
    data3x : IN  std_logic_vector (7 DOWNTO 0);
    data2x : IN  std_logic_vector (7 DOWNTO 0);
    data1x : IN  std_logic_vector (7 DOWNTO 0);
    data0x : IN  std_logic_vector (7 DOWNTO 0);
    sel    : IN  std_logic_vector (2 DOWNTO 0);
    result : OUT std_logic_vector (7 DOWNTO 0));
  END COMPONENT;

  COMPONENT two_by_3bit_mux PORT (
    data1x : IN  std_logic_vector (2 DOWNTO 0);
    data0x : IN  std_logic_vector (2 DOWNTO 0);
    sel    : IN  std_logic;
    result : OUT std_logic_vector (2 DOWNTO 0));
  END COMPONENT;

  COMPONENT two_by_8bit_mux
    PORT (data1x  : IN  std_logic_vector (7 DOWNTO 0);
           data0x : IN  std_logic_vector (7 DOWNTO 0);
           sel    : IN  std_logic;
           result : OUT std_logic_vector (7 DOWNTO 0));
  END COMPONENT;

  COMPONENT mux_2x32_registered
    PORT (clock   : IN  std_logic;
           aclr   : IN  std_logic := '0';
           clken  : IN  std_logic := '1';
           data1x : IN  std_logic_vector (31 DOWNTO 0);
           data0x : IN  std_logic_vector (31 DOWNTO 0);
           sel    : IN  std_logic;
           result : OUT std_logic_vector (31 DOWNTO 0));
  END COMPONENT;

  COMPONENT mux_32_to_4
    PORT (clock   : IN  std_logic;
           aclr   : IN  std_logic := '0';
           clken  : IN  std_logic := '1';
           data8x : IN  std_logic_vector (3 DOWNTO 0);
           data7x : IN  std_logic_vector (3 DOWNTO 0);
           data6x : IN  std_logic_vector (3 DOWNTO 0);
           data5x : IN  std_logic_vector (3 DOWNTO 0);
           data4x : IN  std_logic_vector (3 DOWNTO 0);
           data3x : IN  std_logic_vector (3 DOWNTO 0);
           data2x : IN  std_logic_vector (3 DOWNTO 0);
           data1x : IN  std_logic_vector (3 DOWNTO 0);
           data0x : IN  std_logic_vector (3 DOWNTO 0);
           sel    : IN  std_logic_vector (3 DOWNTO 0);
           result : OUT std_logic_vector (3 DOWNTO 0));
  END COMPONENT;

  -- 4 input by 32bit mux with registered output to select data
  -- from TDIG input fifos
  COMPONENT mux_4x32_registered
    PORT (clock   : IN  std_logic;
           aclr   : IN  std_logic := '0';
           clken  : IN  std_logic := '1';
           data3x : IN  std_logic_vector (31 DOWNTO 0);
           data2x : IN  std_logic_vector (31 DOWNTO 0);
           data1x : IN  std_logic_vector (31 DOWNTO 0);
           data0x : IN  std_logic_vector (31 DOWNTO 0);
           sel    : IN  std_logic_vector (1 DOWNTO 0);
           result : OUT std_logic_vector (31 DOWNTO 0));
  END COMPONENT;
  
  COMPONENT mux_5x32_unreg PORT (
    data4x : IN  std_logic_vector (31 DOWNTO 0);
    data3x : IN  std_logic_vector (31 DOWNTO 0);
    data2x : IN  std_logic_vector (31 DOWNTO 0);
    data1x : IN  std_logic_vector (31 DOWNTO 0);
    data0x : IN  std_logic_vector (31 DOWNTO 0);
    sel    : IN  std_logic_vector (2 DOWNTO 0);
    result : OUT std_logic_vector (31 DOWNTO 0));
  END COMPONENT;

  COMPONENT mux_5x32_registered
    PORT (clock  : IN  std_logic;
          aclr   : IN  std_logic := '0';
          clken  : IN  std_logic := '1';
          data4x : IN  std_logic_vector (31 DOWNTO 0);
          data3x : IN  std_logic_vector (31 DOWNTO 0);
          data2x : IN  std_logic_vector (31 DOWNTO 0);
          data1x : IN  std_logic_vector (31 DOWNTO 0);
          data0x : IN  std_logic_vector (31 DOWNTO 0);
          sel    : IN  std_logic_vector (2 DOWNTO 0);
          result : OUT std_logic_vector (31 DOWNTO 0));
  END COMPONENT;

  COMPONENT mux_4x8_reg
    PORT (clock   : IN  std_logic;
           aclr   : IN  std_logic := '0';
           clken  : IN  std_logic := '1';
           data3x : IN  std_logic_vector (7 DOWNTO 0);
           data2x : IN  std_logic_vector (7 DOWNTO 0);
           data1x : IN  std_logic_vector (7 DOWNTO 0);
           data0x : IN  std_logic_vector (7 DOWNTO 0);
           sel    : IN  std_logic_vector (1 DOWNTO 0);
           result : OUT std_logic_vector (7 DOWNTO 0));
  END COMPONENT;

  -- counters ***************************************************

  COMPONENT count127 PORT (
    clock  : IN  std_logic;
    cnt_en : IN  std_logic;
    aclr   : IN  std_logic;
    q      : OUT std_logic_vector (6 DOWNTO 0);
    cout   : OUT std_logic);
  END COMPONENT;

  COMPONENT trigger_counter_15bit PORT (
    clock  : IN  std_logic;
    cnt_en : IN  std_logic;
    aclr   : IN  std_logic;
    q      : OUT std_logic_vector (14 DOWNTO 0);
    cout   : OUT std_logic);
  END COMPONENT;

  COMPONENT trigger_counter_12bit PORT (
    clock  : IN  std_logic;
    cnt_en : IN  std_logic;
    aclr   : IN  std_logic;
    q      : OUT std_logic_vector (11 DOWNTO 0);
    cout   : OUT std_logic);
  END COMPONENT;

  COMPONENT data_sel_ctr
    PORT(clock   : IN  std_logic;
          cnt_en : IN  std_logic;
          sclr   : IN  std_logic;
          aclr   : IN  std_logic;
          q      : OUT std_logic_vector (2 DOWNTO 0));
  END COMPONENT;

  COMPONENT timeout
    GENERIC (
      nbit : integer);
    PORT(clk, reset     : IN  std_logic;
          clr_timeout   : IN  std_logic;
          timeout_valid : OUT std_logic);
  END COMPONENT timeout;

  COMPONENT ctr_9state
    PORT
      (clock   : IN  std_logic;
        clk_en : IN  std_logic;
        aclr   : IN  std_logic;
        q      : OUT std_logic_vector (3 DOWNTO 0));
  END COMPONENT;

  -- decoders  ***************************************************  
  
  COMPONENT decode_3to5_en PORT (
    data   : IN  std_logic_vector (2 DOWNTO 0);
    enable : IN  std_logic;
    eq0    : OUT std_logic;
    eq1    : OUT std_logic;
    eq2    : OUT std_logic;
    eq3    : OUT std_logic;
    eq4    : OUT std_logic);
  END COMPONENT;

  -- fifos  ***************************************************

  -- tdig data input fifo
  COMPONENT input_fifo_64x32
    PORT (data  : IN  std_logic_vector (31 DOWNTO 0);
          wrreq : IN  std_logic;
          rdreq : IN  std_logic;
          clock : IN  std_logic;
          aclr  : IN  std_logic;
          q     : OUT std_logic_vector (31 DOWNTO 0);
          full  : OUT std_logic;
          empty : OUT std_logic);
  END COMPONENT;

  COMPONENT input_fifo_256x32
    PORT (data  : IN  std_logic_vector (31 DOWNTO 0);
          wrreq : IN  std_logic;
          rdreq : IN  std_logic;
          clock : IN  std_logic;
          aclr  : IN  std_logic;
          q     : OUT std_logic_vector (31 DOWNTO 0);
          full  : OUT std_logic;
          empty : OUT std_logic);
  END COMPONENT;

  COMPONENT input_fifo64dx20w
    PORT (data   : IN  std_logic_vector (19 DOWNTO 0);
           wrreq : IN  std_logic;
           rdreq : IN  std_logic;
           clock : IN  std_logic;
           aclr  : IN  std_logic;
           q     : OUT std_logic_vector (19 DOWNTO 0);
           full  : OUT std_logic;
           empty : OUT std_logic);
  END COMPONENT;

  COMPONENT output_fifo_256x32
    PORT (data   : IN  std_logic_vector (31 DOWNTO 0);
           wrreq : IN  std_logic;
           rdreq : IN  std_logic;
           clock : IN  std_logic;
           aclr  : IN  std_logic;
           q     : OUT std_logic_vector (31 DOWNTO 0);
           full  : OUT std_logic;
           empty : OUT std_logic);
  END COMPONENT;

  COMPONENT mcu_fifo_256x24
    PORT (data   : IN  std_logic_vector (23 DOWNTO 0);
           wrreq : IN  std_logic;
           rdreq : IN  std_logic;
           clock : IN  std_logic;
           aclr  : IN  std_logic;
           q     : OUT std_logic_vector (23 DOWNTO 0);
           full  : OUT std_logic;
           empty : OUT std_logic);
  END COMPONENT;

  COMPONENT output_fifo_1024x32
    PORT
      (data   : IN  std_logic_vector (31 DOWNTO 0);
        wrreq : IN  std_logic;
        rdreq : IN  std_logic;
        clock : IN  std_logic;
        aclr  : IN  std_logic;
        q     : OUT std_logic_vector (31 DOWNTO 0);
        full  : OUT std_logic;
        empty : OUT std_logic);
  END COMPONENT;

  COMPONENT output_fifo_2048x32
    PORT
      (data   : IN  std_logic_vector (31 DOWNTO 0);
        wrreq : IN  std_logic;
        rdreq : IN  std_logic;
        clock : IN  std_logic;
        aclr  : IN  std_logic;
        q     : OUT std_logic_vector (31 DOWNTO 0);
        full  : OUT std_logic;
        empty : OUT std_logic);
  END COMPONENT;
  

END PACKAGE tcpu_package;

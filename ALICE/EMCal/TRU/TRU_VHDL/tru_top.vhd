-- $Id: tru_top.vhd,v 1.6 2008-11-26 16:32:35 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : TRU TOP
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tru_top.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-07-25
-- Last update: 2008-11-21
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-07-25  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY UNISIM;
USE UNISIM.vcomponents.ALL;


-------------------------------------------------------------------------------

ENTITY tru IS
  GENERIC (
    includeChipscope : boolean := true);

  PORT (
    -- clocks and reset
    BRD_RESET_n : IN std_logic;         -- reset switch (active low)
    BRD_40M     : IN std_logic;

    -- ADC inputs (14 ADCs, 8 channels each)
    ADC_CLK_P, ADC_CLK_N   : IN std_logic_vector (13 DOWNTO 0);  -- LVDS frame clock
    ADC_QUAD_P, ADC_QUAD_N : IN std_logic_vector (111 DOWNTO 0);  -- LVDS data
    ADC_LCLK_P, ADC_LCLK_N : IN std_logic_vector (13 DOWNTO 0);  -- LVDS clock

    -- ADC registers serial interface
    ADC_SDATA : OUT std_logic;          -- serial data
    ADC_SCLK  : OUT std_logic;          -- serial clock
    ADC_CS_n  : OUT std_logic_vector (13 DOWNTO 0);  -- serial enable chip select (active low)

    ADC_INTEXT                 : OUT std_logic;  -- Internal (1)/External (0) reference
    ADC_RESET_n                : OUT std_logic;  -- active low reset
    ADC_PDWN                   : OUT std_logic;  -- power down
    ADC_CLK40M_P, ADC_CLK40M_N : OUT std_logic;  -- clock to ADC

    -- Altro/GTL bus
    ALT_TRSF_EN            : IN    std_logic;  -- (TRSF_GT) ALTRO chip controls bus (not used)
    ALT_ACKN_EN            : IN    std_logic;  -- (ACKN_GT) TRU Ack. read/write (not used)
    ALT_DOLO_EN            : IN    std_logic;  -- (not used)
    ALT_SCLK_P, ALT_SCLK_N : IN    std_logic;  -- (SCLK_DP/N) (not used)
    ALT_RDOCLK             : IN    std_logic;  -- (RCLK_GT) 40 MHz Readout Clock.
    ALT_TRSF               : OUT   std_logic;  -- (TRSF_GT) Asserted when ALTROchip controls the bus
    ALT_DSTB               : OUT   std_logic;  -- (DSTB_GT) Each word are validated by the DataStrobe
    ALT_ACKN               : OUT   std_logic;  -- (ACKN_GT) Asserted by TRU. Ack. read/write.
    ALT_ERROR              : OUT   std_logic;  -- (ERROR_GT) Indicate parity or instruction error
    ALT_RST_TBC            : IN    std_logic;  -- (RST_GT) Reset from RCU.
    ALT_L1                 : IN    std_logic;  -- (L1_GT)
    ALT_L2                 : IN    std_logic;  -- (L2_GT)
    ALT_WRITE              : IN    std_logic;  -- (WRITE_GT) Driven by RCU. Def. transf. dir.
    ALT_CSTB               : IN    std_logic;  -- (CSTB_GT) Driven by RCU. Ctr. transfers.
    RCU_SCL                : IN    std_logic;  -- (SCCLK_GT) 5MHz Slow Clock for I2C Transfers.
    RCU_SDA_IN             : IN    std_logic;  -- (SCDIN_GT) Slow Control Serial Data from RCU.
    RCU_SDA_OUT            : OUT   std_logic;  -- (SCDOUT_GT) Slow Control Serial Data to RCU.
    ALT_BD                 : INOUT std_logic_vector (39 DOWNTO 0);  -- GTL DATA BUS
    ALT_CARDADD            : IN    std_logic_vector (4 DOWNTO 0);
    -- these 6 signals are named "GTL_CTRL[x]" on schematics:
    GTL_OEBA_L             : OUT   std_logic;  -- RCU -> TRU
    GTL_OEAB_L             : OUT   std_logic;  -- TRU -> RCU
    GTL_OEBA_H             : OUT   std_logic;  -- RCU -> TRU
    GTL_OEAB_H             : OUT   std_logic;  -- TRU -> RCU
    GTL_CTRL_IN            : OUT   std_logic;  -- RCU -> TRU
    GTL_CTRL_OUT           : OUT   std_logic;  -- TRU -> RCU

    -- ???
    TRU_INTERRUPT_n              : OUT std_logic;  -- active low
    BRD_CLK125M_P, BRD_CLK125M_N : IN  std_logic;  -- ?

    -- LEDs
    LED_LVDS_RXTX : OUT std_logic;
    LED_AUX1      : OUT std_logic;
    LED_AUX2      : OUT std_logic;
    LED_BUSY      : OUT std_logic;
    LED_L0        : OUT std_logic;
    LED_L1        : OUT std_logic;
    LED_RCU_RXTX  : OUT std_logic;
    LED_SYS_OK    : OUT std_logic;
    LED_PWR_ERR   : OUT std_logic;
    LED_SYS_ERR   : OUT std_logic;

    -- Power Regulator flags
    LDO_2V5_DIG : IN std_logic;
    LDO_3V3_DIG : IN std_logic;
    LDO_3V3_ADC : IN std_logic;
    LDO_2V5_ADC : IN std_logic;

    -- ADC power enable
    LDO_ADC_EN : OUT std_logic;

    -- Test header (arbitrarily 5 IN, 5 OUT, redefine as necessary)
    TST_AUX9 : OUT std_logic;
    TST_AUX8 : OUT std_logic;
    TST_AUX7 : OUT std_logic;
    TST_AUX6 : OUT std_logic;
    TST_AUX5 : OUT std_logic;
    TST_AUX4 : OUT std_logic;
    TST_AUX3 : OUT std_logic;
    TST_AUX2 : OUT std_logic;
    TST_AUX1 : OUT std_logic;
    TST_AUX0 : OUT std_logic;

    -- Actel interface (missing some signals)
    X2A_CLK : IN std_logic;             -- Actel clock

    -- Two Monitoring ADCs (temp, volt, amp)
    SNS_OTI    : IN    std_logic_vector (1 DOWNTO 0);  -- over temperature indicator
    SNS_SDA    : INOUT std_logic;       -- bidir data
    SNS_SCL    : OUT   std_logic;       -- serial clock
    SNS_CONV_n : OUT   std_logic;       -- convert start (active low)

    -- external LVDS communications
    EXT_LVDS_IO_P, EXT_LVDS_IO_N : IN std_logic_vector (7 DOWNTO 0)

    );

--  ATTRIBUTE clock_buffer               : string;
--  ATTRIBUTE clock_buffer OF ALT_RDOCLK : SIGNAL IS "ibuf";
--  ATTRIBUTE period: string;
--  ATTRIBUTE period OF BRD_40M: signal IS "25ns";  -- 40 MHz
--  ATTRIBUTE period OF ADC_LCLK_P: signal IS "4.16667ns";  -- 240 MHz
--  ATTRIBUTE period OF ADC_CLK_P: signal IS "25ns";  -- 40 MHz

END ENTITY tru;

-------------------------------------------------------------------------------

ARCHITECTURE str OF tru IS

  -----------------------------------------------------------------------------
  -- Component Declarations
  -----------------------------------------------------------------------------

  COMPONENT clockDCM
    PORT (
      CLKIN_IN        : IN  std_logic;
      RST_IN          : IN  std_logic;
      CLKDV_OUT       : OUT std_logic;
      CLKFX_OUT       : OUT std_logic;
      CLKIN_IBUFG_OUT : OUT std_logic;
      CLK0_OUT        : OUT std_logic;
      LOCKED_OUT      : OUT std_logic);
  END COMPONENT;

  COMPONENT adc_init
    PORT (
      RESET         : IN  std_logic;
      CLK10M        : IN  std_logic;
      LOCKED        : IN  std_logic;
      RX_DATA_OUT   : IN  std_logic_vector (15 DOWNTO 0);
      RX_DATA_READY : IN  std_logic;
      ADC_RESET_n   : OUT std_logic;
      SDATA         : OUT std_logic;
      CS_n          : OUT std_logic;
      READY         : OUT std_logic);
  END COMPONENT adc_init;

  -- chipscope control core
  COMPONENT tru_chipscope
    PORT (
      CONTROL0 : INOUT std_logic_vector(35 DOWNTO 0));
  END COMPONENT;

  -- chipscope integrated logic analyzer
  COMPONENT tru_ila
    PORT (
      CONTROL : INOUT std_logic_vector(35 DOWNTO 0);
      CLK     : IN    std_logic;
      TRIG0   : IN    std_logic_vector(195 DOWNTO 0));
  END COMPONENT;

  -- deserializer for ADCs
  COMPONENT adc_deserializer
    PORT (
      RESET          : IN  std_logic;
      ADC_READY      : IN  std_logic;
      ADC_CLK_P      : IN  std_logic_vector (13 DOWNTO 0);
      ADC_CLK_N      : IN  std_logic_vector (13 DOWNTO 0);
      ADC_QUAD_P     : IN  std_logic_vector (111 DOWNTO 0);
      ADC_QUAD_N     : IN  std_logic_vector (111 DOWNTO 0);
      ADC_LCLK_P     : IN  std_logic_vector (13 DOWNTO 0);
      ADC_LCLK_N     : IN  std_logic_vector (13 DOWNTO 0);
      SERDESe_RDY    : OUT std_logic_vector (13 DOWNTO 0);
      SERDESo_RDY    : OUT std_logic_vector (13 DOWNTO 0);
      ADC_SERDES_OUT : OUT std_logic_vector (1343 DOWNTO 0));
  END COMPONENT;

  COMPONENT poweron IS
    PORT (
      RESET_n  : IN  std_logic;
      CLK_10M  : IN  std_logic;
      PO_RESET : OUT std_logic);
  END COMPONENT poweron;

  COMPONENT rcui2c_top IS
    PORT (
      reset            : IN  std_logic;
      clk_40m          : IN  std_logic;
      rcu_scl_i        : IN  std_logic;
      rcu_sda_in_i     : IN  std_logic;
      tx_data_in       : IN  std_logic_vector (15 DOWNTO 0);
      card_addr        : IN  std_logic_vector (4 DOWNTO 0);
      tx_data_req      : OUT std_logic;
      rx_data_out      : OUT std_logic_vector (15 DOWNTO 0);
      rx_data_ready    : OUT std_logic;
      rcu_sda_out      : OUT std_logic;
      reg_addr_reg     : OUT std_logic_vector (7 DOWNTO 0);
      rcui2c_busy_flag : OUT std_logic);
  END COMPONENT rcui2c_top;

  COMPONENT fake_altro IS
    PORT (
      rcu_clk  : IN std_logic;
      clk_dstb : IN std_logic;
      g_clk    : IN std_logic;
      reset    : IN std_logic;

      L0 : IN std_logic;
      L1 : IN std_logic;
      L2 : IN std_logic;

      shift_data : IN std_logic_vector(1343 DOWNTO 0);

      cstb    : IN std_logic;
      write_r : IN std_logic;

      ctrl_out : OUT std_logic;
      oeab_l   : OUT std_logic;
      oeab_h   : OUT std_logic;
      oeba_l   : OUT std_logic;
      oeba_h   : OUT std_logic;

      ackn : OUT std_logic;
      dstb : OUT std_logic;
      trsf : OUT std_logic;

      bd       : OUT std_logic_vector(39 DOWNTO 0);
      chipview : OUT std_logic_vector(41 DOWNTO 0)
      );
  END COMPONENT fake_altro;
  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  SIGNAL s_alt_bd_in    : std_logic_vector (39 DOWNTO 0);
  SIGNAL s_alt_bd_out   : std_logic_vector (39 DOWNTO 0);
  SIGNAL s_sns_sda_in   : std_logic;
  SIGNAL s_dcm_locked   : std_logic;
  SIGNAL global_clk40M  : std_logic;
  SIGNAL global_clk10M  : std_logic;
  SIGNAL clk_200M       : std_logic;
  SIGNAL s_serdes_out   : std_logic_vector (1343 DOWNTO 0);  -- 12 * 112
  SIGNAL s_IdlyCtrl_Rdy : std_logic;
  SIGNAL ctr_val        : std_logic_vector (24 DOWNTO 0) := "0000000000000000000000000";
  SIGNAL global_ilaclk  : std_logic;
  SIGNAL s_pll_locked   : std_logic;
  SIGNAL s_control0     : std_logic_vector (35 DOWNTO 0);
  SIGNAL s_adc_cs_n     : std_logic;
  SIGNAL s_adc_ready    : std_logic;
  SIGNAL s_serdese_rdy  : std_logic_vector(13 DOWNTO 0);
  SIGNAL s_serdeso_rdy  : std_logic_vector(13 DOWNTO 0);
  SIGNAL s_intReset     : std_logic;
  SIGNAL s_poReset      : std_logic;
  SIGNAL s_clk0_out     : std_logic;

  SIGNAL chipscope_data : std_logic_vector (195 DOWNTO 0);

  SIGNAL ctrl_out         : std_logic;
  SIGNAL rcui2c_busy_flag : std_logic;
  SIGNAL rcu_clk          : std_logic;
  SIGNAL rcu_clkio        : std_logic;
  SIGNAL rx_data_out      : std_logic_vector (15 DOWNTO 0);
  SIGNAL rx_data_ready    : std_logic;
  SIGNAL reg_addr_reg     : std_logic_vector (7 DOWNTO 0);
  SIGNAL chipview         : std_logic_vector (41 DOWNTO 0);


  
  
BEGIN  -- ARCHITECTURE str

  -- internal reset:
--  s_intReset <= NOT BRD_RESET_n;
  s_intReset <= NOT BRD_RESET_n OR s_poReset;

  poreset_inst : poweron
    PORT MAP (
      RESET_n  => s_dcm_locked,
      CLK_10M  => global_clk10M,
      PO_RESET => s_poReset);


  -----------------------------------------------------------------------------
  -- clock generation
  -----------------------------------------------------------------------------

  clockDCM_inst : clockDCM PORT MAP (
    CLKIN_IN        => BRD_40M,
    RST_IN          => '0',
    CLKDV_OUT       => global_clk10M,
    CLKFX_OUT       => clk_200M,
    CLKIN_IBUFG_OUT => global_clk40M,
    CLK0_OUT        => s_clk0_out,
    LOCKED_OUT      => s_dcm_locked);

  -- use 200MHz clock for IDELAYCTRL
  IdlyCtrl_inst : IDELAYCTRL PORT MAP (
    REFCLK => clk_200M,
    RST    => NOT BRD_RESET_n,
    RDY    => s_IdlyCtrl_Rdy);


  -----------------------------------------------------------------------------
  -- set all outputs to some reasonable default for now
  -----------------------------------------------------------------------------

  -- ADC register serial interface clock
  ADC_SCLK <= global_clk10M;

  -- ADC control
  ADC_INTEXT <= '0';
  ADC_PDWN   <= '0';                    -- don't power down ADCs

  -- ADC power, also powers down the PROM, so don't set to 0
  LDO_ADC_EN <= '1';                    -- powered on


  -- ADC clock derived from board clock for now
  adcClk_inst : OBUFDS
    GENERIC MAP (
      IOSTANDARD => "LVPECL_25")
    PORT MAP (
      O  => ADC_CLK40M_P,
      OB => ADC_CLK40M_N,
      I  => global_clk40M);

  -------------------------------------------------------------------------------
  -- LEDs
  -------------------------------------------------------------------------------
  LED_LVDS_RXTX <= '0';
--  LED_AUX1    <= '0';
--  LED_AUX2    <= '0';
--  LED_BUSY    <= '0';
  LED_L0        <= '0';
  LED_L1        <= '0';
  LED_RCU_RXTX  <= '0';
  LED_SYS_OK    <= '0';
  LED_PWR_ERR   <= '0';
  LED_SYS_ERR   <= '0';

  -----------------------------------------------------------------------------
  -- sample Counter to make LEDs blink
  -----------------------------------------------------------------------------
  PROCESS (global_clk40M, BRD_RESET_n)
  BEGIN
    IF BRD_RESET_n = '0' THEN
      ctr_val <= (OTHERS => '0');
      
    ELSIF global_clk40M = '1' AND global_clk40M'event THEN
      ctr_val <= ctr_val + 1;
    END IF;
  END PROCESS;

  LED_AUX1 <= ctr_val(24);
  LED_AUX2 <= ctr_val(23);
  LED_BUSY <= ctr_val(22);


-- test pins
  TST_AUX9 <= '0';
  TST_AUX8 <= '0';
  TST_AUX7 <= '0';
  TST_AUX6 <= '0';
  TST_AUX5 <= '0';
  TST_AUX4 <= '0';
  TST_AUX3 <= '0';
  TST_AUX2 <= '0';
  TST_AUX1 <= '0';
  TST_AUX0 <= '0';

--  TST_AUX0 <= s_adc_fclk(0);
--  TST_AUX1 <= s_adc_dclk(0);
--  TST_AUX2 <= s_adc_quad(0);
--  TST_AUX3 <= s_adc_quad(1);
--  TST_AUX4 <= s_adc_quad(2);
--  TST_AUX5 <= s_adc_quad(3);
--  TST_AUX6 <= s_adc_quad(4);
--  TST_AUX7 <= s_adc_quad(5);
--  TST_AUX8 <= s_adc_quad(6);
--  TST_AUX9 <= '0';                      -- Ground for scope

  TRU_INTERRUPT_n <= '1';


  -- monitoring ADCs
  snsDataInst : IOBUF PORT MAP (
    T  => '1',                          -- enable 3-state
    I  => '0',
    O  => s_sns_sda_in,
    IO => SNS_SDA);
  SNS_SCL    <= '0';
  SNS_CONV_n <= '1';                    -- active low

  -----------------------------------------------------------------------------
  -- ADC serial control
  -----------------------------------------------------------------------------
  adc_init_inst : adc_init PORT MAP (
    RESET         => s_intReset,
    CLK10M        => global_clk10M,
    LOCKED        => s_dcm_locked,
    RX_DATA_OUT   => rx_data_out,
    RX_DATA_READY => rx_data_ready,
    ADC_RESET_n   => ADC_RESET_n,
    SDATA         => ADC_SDATA,
    CS_n          => s_adc_cs_n,
    READY         => s_adc_ready
    );

  -- this line configures ADC 3 and 5
--  ADC_CS_n <= (5 => s_adc_cs_n, 3 => s_adc_cs_n, OTHERS => '1');

  -- this line configures all ADCs
  ADC_CS_n <= (OTHERS => s_adc_cs_n);

  -----------------------------------------------------------------------------
  -- ADC Deserializer
  -----------------------------------------------------------------------------
  serdes_inst : adc_deserializer
    PORT MAP (
      RESET          => s_intReset,
      ADC_READY      => s_adc_ready,
      ADC_CLK_P      => ADC_CLK_P,
      ADC_CLK_N      => ADC_CLK_N,
      ADC_QUAD_P     => ADC_QUAD_P,
      ADC_QUAD_N     => ADC_QUAD_N,
      ADC_LCLK_P     => ADC_LCLK_P,
      ADC_LCLK_N     => ADC_LCLK_N,
      SERDESe_RDY    => s_serdese_rdy,
      SERDESo_RDY    => s_serdeso_rdy,
      ADC_SERDES_OUT => s_serdes_out);

  -----------------------------------------------------------------------------
  -- GTL BUS
  -----------------------------------------------------------------------------
  ALT_ERROR    <= '1';
  GTL_CTRL_IN  <= '0';                                  --control in
  GTL_CTRL_OUT <= (NOT rcui2c_busy_flag) AND ctrl_out;  --control out 
  
  -- put GTL RDO clock through a global clock buffer
  rdoclk_inst : BUFG PORT MAP (
    I => ALT_RDOCLK,
    O => rcu_clk);
    
  -- slow controls code from Dong:
  rcui2c_top_inst : rcui2c_top PORT MAP (
    reset            => ALT_RST_TBC,
    clk_40m          => rcu_clk,
    rcu_scl_i        => RCU_SCL,
    rcu_sda_in_i     => RCU_SDA_IN,
    tx_data_in       => x"abcd",
    card_addr        => b"00000",
    rx_data_out      => rx_data_out,
    rx_data_ready    => rx_data_ready,
    reg_addr_reg     => reg_addr_reg,
    rcu_sda_out      => RCU_SDA_OUT,
    rcui2c_busy_flag => rcui2c_busy_flag
    );    

  -- Fake Altro code from Dong
  fake_altro_inst : fake_altro PORT MAP (
    rcu_clk  => rcu_clk,
    clk_dstb => rcu_clk,
    g_clk    => global_clk40M,
    reset    => ALT_RST_TBC,

    L0 => '0',
    L1 => ALT_L1,
    L2 => ALT_L2,

    shift_data => s_serdes_out,

    cstb    => ALT_CSTB,
    write_r => ALT_WRITE,

    ctrl_out => ctrl_out,
    oeab_l   => GTL_OEAB_L,
    oeab_h   => GTL_OEAB_H,
    oeba_l   => GTL_OEBA_L,
    oeba_h   => GTL_OEBA_H,

    ackn => ALT_ACKN,
    dstb => ALT_DSTB,
    trsf => ALT_TRSF,

    bd       => ALT_BD,
    chipview => chipview
    );             


  -- This "generate" statement makes it so we can include
  -- or exclude the following code snippet by re-defining
  -- the generic parameter "includeChipscope" at the
  -- beginning of the file

  -- This gets invoked if "includeChipscope" is set to "true"
  IncChipScope : IF includeChipscope GENERATE

    -----------------------------------------------------------------------------
    -- Chipscope connections
    -----------------------------------------------------------------------------

    -- the clock for the chipscope analyzer
--    global_ilaclk <= clk_200M;
    global_ilaclk <= global_clk40M;
    -- the chipscope controller
    icon_inst : tru_chipscope
      PORT MAP (
        CONTROL0 => s_control0
        );

    -- the chipscope logic analyzer:

    -- put one chip's worth of deserialized data on ILA:
--    chipscope_data <= s_serdes_out(383 DOWNTO 288);
--
--    GCS : FOR i IN 0 TO 12 GENERATE
--      chipscope_data(i*14+11 DOWNTO i*14) <= s_serdes_out(i*8*12 + 11 DOWNTO i*8*12);
--      chipscope_data(i*14+12)             <= s_serdese_rdy(i);
--      chipscope_data(i*14+13)             <= s_serdeso_rdy(i);
--      
--    END GENERATE GCS;
--
--    chipscope_data(193 DOWNTO 182) <= s_serdes_out(1259 DOWNTO 1248);
--    chipscope_data(194)            <= global_clk40M;
--    chipscope_data(195)            <= s_adc_ready;

    chipscope_data(11 DOWNTO 0)    <= s_serdes_out(71 DOWNTO 60);      -- 5
    chipscope_data(23 DOWNTO 12)   <= s_serdes_out(83 DOWNTO 72);      -- 6
    chipscope_data(35 DOWNTO 24)   <= s_serdes_out(155 DOWNTO 144);    -- 12
    chipscope_data(47 DOWNTO 36)   <= s_serdes_out(911 DOWNTO 900);    -- 75
    chipscope_data(59 DOWNTO 48)   <= s_serdes_out(1055 DOWNTO 1044);  -- 87
    chipscope_data(71 DOWNTO 60)   <= s_serdes_out(1331 DOWNTO 1320);  -- 110
    chipscope_data(83 DOWNTO 72)   <= s_serdes_out(179 DOWNTO 168);    -- 14
    chipscope_data(95 DOWNTO 84)   <= s_serdes_out(575 DOWNTO 564);    -- 47
    chipscope_data(107 DOWNTO 96)  <= s_serdes_out(11 DOWNTO 0);       -- 0
    chipscope_data(119 DOWNTO 108) <= s_serdes_out(23 DOWNTO 12);      -- 1
    chipscope_data(131 DOWNTO 120) <= s_serdes_out(35 DOWNTO 24);      -- 2
    chipscope_data(143 DOWNTO 132) <= s_serdes_out(47 DOWNTO 36);      -- 3
--    chipscope_data(155 DOWNTO 144) <= s_serdes_out(59 DOWNTO 48);      -- 4
--    chipscope_data(167 DOWNTO 156) <= s_serdes_out(95 DOWNTO 84);      -- 7
--    chipscope_data(179 DOWNTO 168) <= s_serdes_out(107 DOWNTO 96);     -- 8
--    chipscope_data(191 DOWNTO 180) <= s_serdes_out(119 DOWNTO 108);    -- 9
--    chipscope_data(195 DOWNTO 192) <= (OTHERS => '0');
    chipscope_data(185 DOWNTO 144) <= chipview;
    chipscope_data(186)            <= ALT_RDOCLK;
    chipscope_data(187)            <= global_clk40M;
    chipscope_data(195 DOWNTO 188) <= (OTHERS => '0');

    ila_inst : tru_ila
      PORT MAP (
        CONTROL => s_control0,
        CLK     => global_ilaclk,
        TRIG0   => chipscope_data
        );

--    -- for now: use the parallel data, so it doesn't get optimized away:
--    PROCESS (s_serdes_out) IS
--      VARIABLE dummy : std_logic;
--    BEGIN  -- PROCESS
--      dummy := '0';
--      FOR i IN 1343 DOWNTO 0 LOOP
--        dummy := dummy XOR s_serdes_out(i);
--      END LOOP;  -- i
--      TST_AUX0 <= dummy;
--    END PROCESS;

  END GENERATE IncChipScope;

--  -- this gets invoked when the GENERIC parameter
--  -- "includeChipscope" is "false"
  DontIncChipscope : IF NOT includeChipscope GENERATE
    -- need to do something with the ADC signals or we get a
    -- compiler warning about unconnected signals
--
--    -- for now: use the parallel data, so it doesn't get optimized away:
--    PROCESS (s_serdes_out) IS
--      VARIABLE dummy : std_logic;
--    BEGIN  -- PROCESS
--      dummy := '0';
--      FOR i IN 1343 DOWNTO 0 LOOP
--        dummy := dummy XOR s_serdes_out(i);
--      END LOOP;  -- i
--      TST_AUX0 <= dummy;
--    END PROCESS;
--
  END GENERATE DontIncChipscope;
  

END ARCHITECTURE str;

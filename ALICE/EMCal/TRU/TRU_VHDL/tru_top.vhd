-- $Id: tru_top.vhd,v 1.5 2008-10-22 20:00:38 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : TRU TOP
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tru_top.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-07-25
-- Last update: 2008-10-22
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
    ALT_TRSF_EN            : OUT   std_logic;  -- (TRSF_GT) ALTRO chip controls bus
    ALT_ACKN_EN            : OUT   std_logic;  -- (ACKN_GT) TRU Ack. read/write
    ALT_DOLO_EN            : IN    std_logic;  -- 
    ALT_SCLK_P, ALT_SCLK_N : IN    std_logic;  -- (SCLK_DP/N)
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
    GTL_OEBA_L             : OUT   std_logic;  --  RCU -> TRU
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
      RESET       : IN  std_logic;
      CLK10M      : IN  std_logic;
      LOCKED      : IN  std_logic;
      ADC_RESET_n : OUT std_logic;
      SDATA       : OUT std_logic;
      CS_n        : OUT std_logic;
      READY       : OUT std_logic);
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
--  SIGNAL s_adc_dclk_p, s_adc_dclk_n : std_logic_vector (13 DOWNTO 0);
--  SIGNAL s_adc_dclk_r               : std_logic_vector (13 DOWNTO 0);
--  SIGNAL s_adc_data_p, s_adc_data_n : std_logic_vector (111 DOWNTO 0);
--  SIGNAL s_adc_fclk     : std_logic_vector (13 DOWNTO 0);
--  SIGNAL s_adc_quad     : std_logic_vector (111 DOWNTO 0);
--  SIGNAL s_adc_dclk     : std_logic_vector (13 DOWNTO 0);
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

  SIGNAL chipscope_data : std_logic_vector(195 DOWNTO 0);
  
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

  -- ADC register serial interface
--  ADC_SDATA <= '0';
  ADC_SCLK <= global_clk10M;
--  ADC_CS_n  <= (OTHERS => '1');         -- active low
--  ADC_CS_n(13 DOWNTO 1) <= (OTHERS => '1');  -- active low

  -- ADC control
  ADC_INTEXT <= '0';
--  ADC_RESET_n <= '1';                   -- active low
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

  -- GTL bus
  ALT_TRSF_EN <= '0';
  ALT_ACKN_EN <= '0';
  ALT_TRSF    <= '0';
  ALT_DSTB    <= '0';
  ALT_ACKN    <= '0';
  ALT_ERROR   <= '0';
  RCU_SDA_OUT <= '0';
  GB1 : FOR i IN 0 TO 39 GENERATE
    altBDInsts : IOBUF PORT MAP (
      T  => '1',                        -- enable 3-state
      I  => s_alt_bd_out(i),
      O  => s_alt_bd_in(i),
      IO => ALT_BD(i));
  END GENERATE GB1;

  s_alt_bd_out <= (OTHERS => '0');

  TRU_INTERRUPT_n <= '1';               -- active low

  GTL_OEAB_H   <= '1';
  GTL_OEAB_L   <= '1';
  GTL_OEBA_L   <= '0';
  GTL_OEBA_H   <= '0';
  GTL_CTRL_IN  <= '0';
  GTL_CTRL_OUT <= '1';

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
--  TST_AUX0 <= '0';

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


  -- monitoring ADCs
  snsDataInst : IOBUF PORT MAP (
    T  => '1',                          -- enable 3-state
    I  => '0',
    O  => s_sns_sda_in,
    IO => SNS_SDA);
  SNS_SCL    <= '0';
  SNS_CONV_n <= '1';                    -- active low



  -----------------------------------------------------------------------------
  -- sample ADC serial control
  -----------------------------------------------------------------------------
  adc_init_inst : adc_init PORT MAP (
    RESET       => s_intReset,
    CLK10M      => global_clk10M,
    LOCKED      => s_dcm_locked,
    ADC_RESET_n => ADC_RESET_n,
    SDATA       => ADC_SDATA,
    CS_n        => s_adc_cs_n,
    READY       => s_adc_ready
    );

  -- this line configures ADC 3 and 5
--  ADC_CS_n <= (5 => s_adc_cs_n, 3 => s_adc_cs_n, OTHERS => '1');
  -- this line configures all ADCs
  ADC_CS_n <= (OTHERS => s_adc_cs_n);

  -----------------------------------------------------------------------------
  -- sample Serdes
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



  -- here is an example on how the serdes_out need to be  inverted:
--  s_alt_bd_out(0)  <= s_serdes_out(0);
--  s_alt_bd_out(1)  <= NOT s_serdes_out(1);
--  s_alt_bd_out(2)  <= s_serdes_out(2);
--  s_alt_bd_out(3)  <= NOT s_serdes_out(3);
--  s_alt_bd_out(4)  <= s_serdes_out(4);
--  s_alt_bd_out(5)  <= NOT s_serdes_out(5);
--  s_alt_bd_out(6)  <= s_serdes_out(6);
--  s_alt_bd_out(7)  <= NOT s_serdes_out(7);
--  s_alt_bd_out(8)  <= s_serdes_out(8);
--  s_alt_bd_out(9)  <= NOT s_serdes_out(9);
--  s_alt_bd_out(10) <= s_serdes_out(10);
--  s_alt_bd_out(11) <= NOT s_serdes_out(11);

  -----------------------------------------------------------------------------
  -- sample serdes conversion for chipscope
  -----------------------------------------------------------------------------
--  G2 : FOR j IN 0 TO 87 GENERATE
--    adcDataInst : IBUFDS
--      GENERIC MAP (
--        IOSTANDARD => "LVDS_25",
--        DIFF_TERM  => true)
--      PORT MAP (
--        I  => ADC_QUAD_P(j),
--        IB => ADC_QUAD_N(j),
--        O  => s_adc_quad(j));
--  END GENERATE G2;

--  G2a : FOR j IN 89 TO 111 GENERATE
--    adcDataInst : IBUFDS
--      GENERIC MAP (
--        IOSTANDARD => "LVDS_25",
--        DIFF_TERM  => true)
--      PORT MAP (
--        I  => ADC_QUAD_P(j),
--        IB => ADC_QUAD_N(j),
--        O  => s_adc_quad(j));
--  END GENERATE G2a;

--  adcDataInst : IBUFDS
--    GENERIC MAP (
--      IOSTANDARD => "LVDS_25",
--      DIFF_TERM  => true)
--    PORT MAP (
--      I  => ADC_QUAD_N(88),
--      IB => ADC_QUAD_P(88),
--      O  => s_adc_quad(88));

--  G3 : FOR j IN 0 TO 13 GENERATE
--    adcFrameClk_inst : IBUFDS
--      GENERIC MAP (
--        IOSTANDARD => "LVDS_25",
--        DIFF_TERM  => true)
--      PORT MAP (
--        I  => ADC_CLK_P(j),
--        IB => ADC_CLK_N(j),
--        O  => s_adc_fclk(j));
--  END GENERATE G3;

--  G4 : FOR j IN 0 TO 8 GENERATE
--    adcDClk_inst : IBUFDS
--      GENERIC MAP (
--        IOSTANDARD => "LVDS_25",
--        DIFF_TERM  => true)
--      PORT MAP (
--        I  => ADC_LCLK_P(j),
--        IB => ADC_LCLK_N(j),
--        O  => s_adc_dclk(j));
--  END GENERATE G4;

--  G4a : FOR j IN 10 TO 13 GENERATE
--    adcDClk_inst : IBUFDS
--      GENERIC MAP (
--        IOSTANDARD => "LVDS_25",
--        DIFF_TERM  => true)
--      PORT MAP (
--        I  => ADC_LCLK_P(j),
--        IB => ADC_LCLK_N(j),
--        O  => s_adc_dclk(j));
--  END GENERATE G4a;

--  adcDClk_inst : IBUFDS
--    GENERIC MAP (
--      IOSTANDARD => "LVDS_25",
--      DIFF_TERM  => true)
--    PORT MAP (
--      I  => ADC_LCLK_N(9),
--      IB => ADC_LCLK_P(9),
--      O  => s_adc_dclk(9));




  -- This "generate" statement makes it so we can include
  -- or exclude the following code snippet by re-defining
  -- the generic parameter "includeChipscope" at the
  -- beginning of the file

  -- This gets invoked if "includeChipscope" is set to "true"
  IncChipScope : IF includeChipscope GENERATE

    -----------------------------------------------------------------------------
    -- Chipscope connections
    -----------------------------------------------------------------------------

    global_ilaclk <= clk_200M;
    -- the chipscope controller
    icon_inst : tru_chipscope
      PORT MAP (
        CONTROL0 => s_control0
        );

    -- the chipscope logic analyzer:

    -- put one chip's worth of deserialized data on ILA:
--    chipscope_data <= s_serdes_out(383 DOWNTO 288);

    GCS : FOR i IN 0 TO 12 GENERATE
      chipscope_data(i*14+11 DOWNTO i*14) <= s_serdes_out(i*8*12 + 11 DOWNTO i*8*12);
      chipscope_data(i*14+12)             <= s_serdese_rdy(i);
      chipscope_data(i*14+13)             <= s_serdeso_rdy(i);
      
    END GENERATE GCS;

    chipscope_data(193 DOWNTO 182) <= s_serdes_out(1259 DOWNTO 1248);
    chipscope_data(194)            <= global_clk40M;
    chipscope_data(195)            <= s_adc_ready;

    ila_inst : tru_ila
      PORT MAP (
        CONTROL => s_control0,
        CLK     => global_ilaclk,
        TRIG0   => chipscope_data
        );

    -- for now: use the parallel data, so it doesn't get optimized away:
    PROCESS (s_serdes_out) IS
      VARIABLE dummy : std_logic;
    BEGIN  -- PROCESS
      dummy := '0';
      FOR i IN 1343 DOWNTO 0 LOOP
        dummy := dummy XOR s_serdes_out(i);
      END LOOP;  -- i
      TST_AUX0 <= dummy;
    END PROCESS;

--    ila_inst : tru_ila
--      PORT MAP (
--        CONTROL               => s_control0,
--        CLK                   => global_ilaclk,
--        TRIG0(0)              => s_adc_fclk(0),
--        TRIG0(1)              => s_adc_dclk(0),
--        TRIG0(9 DOWNTO 2)     => s_adc_quad(7 DOWNTO 0),
--        TRIG0(10)             => s_adc_fclk(1),
--        TRIG0(11)             => s_adc_dclk(1),
--        TRIG0(19 DOWNTO 12)   => s_adc_quad(15 DOWNTO 8),
--        TRIG0(20)             => s_adc_fclk(2),
--        TRIG0(21)             => s_adc_dclk(2),
--        TRIG0(29 DOWNTO 22)   => s_adc_quad(23 DOWNTO 16),
--        TRIG0(30)             => s_adc_fclk(3),
--        TRIG0(31)             => s_adc_dclk(3),
--        TRIG0(39 DOWNTO 32)   => s_adc_quad(31 DOWNTO 24),
--        TRIG0(40)             => s_adc_fclk(4),
--        TRIG0(41)             => s_adc_dclk(4),
--        TRIG0(49 DOWNTO 42)   => s_adc_quad(39 DOWNTO 32),
--        TRIG0(50)             => s_adc_fclk(5),
--        TRIG0(51)             => s_adc_dclk(5),
--        TRIG0(59 DOWNTO 52)   => s_adc_quad(47 DOWNTO 40),
--        TRIG0(60)             => s_adc_fclk(6),
--        TRIG0(61)             => s_adc_dclk(6),
--        TRIG0(69 DOWNTO 62)   => s_adc_quad(55 DOWNTO 48),
--        TRIG0(70)             => s_adc_fclk(7),
--        TRIG0(71)             => s_adc_dclk(7),
--        TRIG0(79 DOWNTO 72)   => s_adc_quad(63 DOWNTO 56),
--        TRIG0(80)             => s_adc_fclk(8),
--        TRIG0(81)             => s_adc_dclk(8),
--        TRIG0(89 DOWNTO 82)   => s_adc_quad(71 DOWNTO 64),
--        TRIG0(90)             => s_adc_fclk(9),
--        TRIG0(91)             => s_adc_dclk(9),
--        TRIG0(99 DOWNTO 92)   => s_adc_quad(79 DOWNTO 72),
--        TRIG0(100)            => s_adc_fclk(10),
--        TRIG0(101)            => s_adc_dclk(10),
--        TRIG0(109 DOWNTO 102) => s_adc_quad(87 DOWNTO 80),
--        TRIG0(110)            => s_adc_fclk(11),
--        TRIG0(111)            => s_adc_dclk(11),
--        TRIG0(119 DOWNTO 112) => s_adc_quad(95 DOWNTO 88),
--        TRIG0(120)            => s_adc_fclk(12),
--        TRIG0(121)            => s_adc_dclk(12),
--        TRIG0(129 DOWNTO 122) => s_adc_quad(103 DOWNTO 96),
--        TRIG0(130)            => s_adc_fclk(13),
--        TRIG0(131)            => s_adc_dclk(13),
--        TRIG0(139 DOWNTO 132) => s_adc_quad(111 DOWNTO 104)
--        );



  END GENERATE IncChipScope;

  -- this gets invoked when the GENERIC parameter
  -- "includeChipscope" is "false"
  DontIncChipscope : IF NOT includeChipscope GENERATE
    -- need to do something with the ADC signals or we get a
    -- compiler warning about unconnected signals
--    TST_AUX0 <= '1' WHEN (s_adc_fclk = "11111111111111" AND
--                          s_adc_dclk = "11111111111111" AND
--                          s_adc_quad = x"ffffffffffffffffffffffffffff")
-- ELSE '0';

    -- for now: use the parallel data, so it doesn't get optimized away:
    PROCESS (s_serdes_out) IS
      VARIABLE dummy : std_logic;
    BEGIN  -- PROCESS
      dummy := '0';
      FOR i IN 1343 DOWNTO 0 LOOP
        dummy := dummy XOR s_serdes_out(i);
      END LOOP;  -- i
      TST_AUX0 <= dummy;
    END PROCESS;

  END GENERATE DontIncChipscope;

END ARCHITECTURE str;

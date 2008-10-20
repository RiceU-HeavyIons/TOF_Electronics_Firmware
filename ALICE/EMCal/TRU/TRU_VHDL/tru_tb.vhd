-- $Id: tru_tb.vhd,v 1.2 2008-10-20 13:55:48 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : TRU Testbench
-- Project    : TRU
-------------------------------------------------------------------------------
-- File       : tru_tb.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-08-19
-- Last update: 2008-10-17
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Testbench for TRU code
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-08-19  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY UNISIM;
USE UNISIM.vcomponents.ALL;
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE STD.TEXTIO.ALL;

ENTITY tru_tb IS
END tru_tb;

ARCHITECTURE testbench_arch OF tru_tb IS
  FILE RESULTS : text OPEN write_mode IS "results.txt";

  COMPONENT tru
    PORT (
      BRD_RESET_n     : IN    std_logic;
      BRD_40M         : IN    std_logic;
      ADC_CLK_P       : IN    std_logic_vector (13 DOWNTO 0);
      ADC_CLK_N       : IN    std_logic_vector (13 DOWNTO 0);
      ADC_QUAD_P      : IN    std_logic_vector (111 DOWNTO 0);
      ADC_QUAD_N      : IN    std_logic_vector (111 DOWNTO 0);
      ADC_LCLK_P      : IN    std_logic_vector (13 DOWNTO 0);
      ADC_LCLK_N      : IN    std_logic_vector (13 DOWNTO 0);
      ADC_SDATA       : OUT   std_logic;
      ADC_SCLK        : OUT   std_logic;
      ADC_CS_n        : OUT   std_logic_vector (13 DOWNTO 0);
      ADC_INTEXT      : OUT   std_logic;
      ADC_RESET_n     : OUT   std_logic;
      ADC_PDWN        : OUT   std_logic;
      ADC_CLK40M_P    : OUT   std_logic;
      ADC_CLK40M_N    : OUT   std_logic;
      ALT_TRSF_EN     : OUT   std_logic;
      ALT_ACKN_EN     : OUT   std_logic;
      ALT_DOLO_EN     : IN    std_logic;
      ALT_SCLK_P      : IN    std_logic;
      ALT_SCLK_N      : IN    std_logic;
      ALT_RDOCLK      : IN    std_logic;
      ALT_TRSF        : OUT   std_logic;
      ALT_DSTB        : OUT   std_logic;
      ALT_ACKN        : OUT   std_logic;
      ALT_ERROR       : OUT   std_logic;
      ALT_RST_TBC     : IN    std_logic;
      ALT_L1          : IN    std_logic;
      ALT_L2          : IN    std_logic;
      ALT_WRITE       : IN    std_logic;
      ALT_CSTB        : IN    std_logic;
      RCU_SCL         : IN    std_logic;
      RCU_SDA_IN      : IN    std_logic;
      RCU_SDA_OUT     : OUT   std_logic;
      ALT_BD          : INOUT std_logic_vector (39 DOWNTO 0);
      ALT_CARDADD     : IN    std_logic_vector (4 DOWNTO 0);
      GTL_OEBA_L      : OUT   std_logic;
      GTL_OEAB_L      : OUT   std_logic;
      GTL_OEBA_H      : OUT   std_logic;
      GTL_OEAB_H      : OUT   std_logic;
      GTL_CTRL_IN     : OUT   std_logic;
      GTL_CTRL_OUT    : OUT   std_logic;
      TRU_INTERRUPT_n : OUT   std_logic;
      BRD_CLK125M_P   : IN    std_logic;
      BRD_CLK125M_N   : IN    std_logic;
      LED_LVDS_RXTX   : OUT   std_logic;
      LED_AUX1        : OUT   std_logic;
      LED_AUX2        : OUT   std_logic;
      LED_BUSY        : OUT   std_logic;
      LED_L0          : OUT   std_logic;
      LED_L1          : OUT   std_logic;
      LED_RCU_RXTX    : OUT   std_logic;
      LED_SYS_OK      : OUT   std_logic;
      LED_PWR_ERR     : OUT   std_logic;
      LED_SYS_ERR     : OUT   std_logic;
      LDO_2V5_DIG     : IN    std_logic;
      LDO_3V3_DIG     : IN    std_logic;
      LDO_3V3_ADC     : IN    std_logic;
      LDO_2V5_ADC     : IN    std_logic;
      LDO_ADC_EN      : OUT   std_logic;
      TST_AUX9        : OUT   std_logic;
      TST_AUX8        : OUT   std_logic;
      TST_AUX7        : OUT   std_logic;
      TST_AUX6        : OUT   std_logic;
      TST_AUX5        : OUT   std_logic;
      TST_AUX4        : OUT   std_logic;
      TST_AUX3        : OUT   std_logic;
      TST_AUX2        : OUT   std_logic;
      TST_AUX1        : OUT   std_logic;
      TST_AUX0        : OUT   std_logic;
      X2A_CLK         : IN    std_logic;
      SNS_OTI         : IN    std_logic_vector (1 DOWNTO 0);
      SNS_SDA         : INOUT std_logic;
      SNS_SCL         : OUT   std_logic;
      SNS_CONV_n      : OUT   std_logic;
      EXT_LVDS_IO_P   : IN    std_logic_vector (7 DOWNTO 0);
      EXT_LVDS_IO_N   : IN    std_logic_vector (7 DOWNTO 0)
      );
  END COMPONENT;

  SIGNAL BRD_RESET_n     : std_logic                       := '1';
  SIGNAL BRD_40M         : std_logic                       := '0';
  SIGNAL ADC_CLK_P       : std_logic_vector (13 DOWNTO 0)  := "00000000000000";
  SIGNAL ADC_CLK_N       : std_logic_vector (13 DOWNTO 0)  := "00000000000000";
  SIGNAL ADC_QUAD_P      : std_logic_vector (111 DOWNTO 0) := x"0000000000000000000000000000";
  SIGNAL ADC_QUAD_N      : std_logic_vector (111 DOWNTO 0) := x"FFFFFFFFFFFFFFFFFFFFFFFFFFFF";
  SIGNAL ADC_LCLK_P      : std_logic_vector (13 DOWNTO 0)  := "00000000000000";
  SIGNAL ADC_LCLK_N      : std_logic_vector (13 DOWNTO 0)  := "00000000000000";
  SIGNAL ADC_SDATA       : std_logic                       := '0';
  SIGNAL ADC_SCLK        : std_logic                       := '0';
  SIGNAL ADC_CS_n        : std_logic_vector (13 DOWNTO 0)  := "11111111111111";
  SIGNAL ADC_INTEXT      : std_logic                       := '0';
  SIGNAL ADC_RESET_n     : std_logic                       := '1';
  SIGNAL ADC_PDWN        : std_logic                       := '0';
  SIGNAL ADC_CLK40M_P    : std_logic                       := '0';
  SIGNAL ADC_CLK40M_N    : std_logic                       := '0';
  SIGNAL ALT_TRSF_EN     : std_logic                       := '0';
  SIGNAL ALT_ACKN_EN     : std_logic                       := '0';
  SIGNAL ALT_DOLO_EN     : std_logic                       := '0';
  SIGNAL ALT_SCLK_P      : std_logic                       := '0';
  SIGNAL ALT_SCLK_N      : std_logic                       := '0';
  SIGNAL ALT_RDOCLK      : std_logic                       := '0';
  SIGNAL ALT_TRSF        : std_logic                       := '0';
  SIGNAL ALT_DSTB        : std_logic                       := '0';
  SIGNAL ALT_ACKN        : std_logic                       := '0';
  SIGNAL ALT_ERROR       : std_logic                       := '0';
  SIGNAL ALT_RST_TBC     : std_logic                       := '0';
  SIGNAL ALT_L1          : std_logic                       := '0';
  SIGNAL ALT_L2          : std_logic                       := '0';
  SIGNAL ALT_WRITE       : std_logic                       := '0';
  SIGNAL ALT_CSTB        : std_logic                       := '0';
  SIGNAL RCU_SCL         : std_logic                       := '0';
  SIGNAL RCU_SDA_IN      : std_logic                       := '0';
  SIGNAL RCU_SDA_OUT     : std_logic                       := '0';
  SIGNAL ALT_BD          : std_logic_vector (39 DOWNTO 0)  := "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
  SIGNAL ALT_CARDADD     : std_logic_vector (4 DOWNTO 0)   := "00000";
  SIGNAL GTL_OEBA_L      : std_logic                       := '0';
  SIGNAL GTL_OEAB_L      : std_logic                       := '0';
  SIGNAL GTL_OEBA_H      : std_logic                       := '0';
  SIGNAL GTL_OEAB_H      : std_logic                       := '0';
  SIGNAL GTL_CTRL_IN     : std_logic                       := '0';
  SIGNAL GTL_CTRL_OUT    : std_logic                       := '0';
  SIGNAL TRU_INTERRUPT_n : std_logic                       := '0';
  SIGNAL BRD_CLK125M_P   : std_logic                       := '0';
  SIGNAL BRD_CLK125M_N   : std_logic                       := '0';
  SIGNAL LED_LVDS_RXTX   : std_logic                       := '0';
  SIGNAL LED_AUX1        : std_logic                       := '0';
  SIGNAL LED_AUX2        : std_logic                       := '0';
  SIGNAL LED_BUSY        : std_logic                       := '0';
  SIGNAL LED_L0          : std_logic                       := '0';
  SIGNAL LED_L1          : std_logic                       := '0';
  SIGNAL LED_RCU_RXTX    : std_logic                       := '0';
  SIGNAL LED_SYS_OK      : std_logic                       := '0';
  SIGNAL LED_PWR_ERR     : std_logic                       := '0';
  SIGNAL LED_SYS_ERR     : std_logic                       := '0';
  SIGNAL LDO_2V5_DIG     : std_logic                       := '0';
  SIGNAL LDO_3V3_DIG     : std_logic                       := '0';
  SIGNAL LDO_3V3_ADC     : std_logic                       := '0';
  SIGNAL LDO_2V5_ADC     : std_logic                       := '0';
  SIGNAL LDO_ADC_EN      : std_logic                       := '0';
  SIGNAL TST_AUX9        : std_logic                       := '0';
  SIGNAL TST_AUX8        : std_logic                       := '0';
  SIGNAL TST_AUX7        : std_logic                       := '0';
  SIGNAL TST_AUX6        : std_logic                       := '0';
  SIGNAL TST_AUX5        : std_logic                       := '0';
  SIGNAL TST_AUX4        : std_logic                       := '0';
  SIGNAL TST_AUX3        : std_logic                       := '0';
  SIGNAL TST_AUX2        : std_logic                       := '0';
  SIGNAL TST_AUX1        : std_logic                       := '0';
  SIGNAL TST_AUX0        : std_logic                       := '0';
  SIGNAL X2A_CLK         : std_logic                       := '0';
  SIGNAL SNS_OTI         : std_logic_vector (1 DOWNTO 0)   := "00";
  SIGNAL SNS_SDA         : std_logic                       := 'Z';
  SIGNAL SNS_SCL         : std_logic                       := '0';
  SIGNAL SNS_CONV_n      : std_logic                       := '0';
  SIGNAL EXT_LVDS_IO_P   : std_logic_vector (7 DOWNTO 0)   := "00000000";
  SIGNAL EXT_LVDS_IO_N   : std_logic_vector (7 DOWNTO 0)   := "00000000";

  CONSTANT PERIOD     : time := 25 ns;
  CONSTANT DUTY_CYCLE : real := 0.5;
  CONSTANT OFFSET     : time := 0 ns;

BEGIN
  UUT : tru
    PORT MAP (
      BRD_RESET_n     => BRD_RESET_n,
      BRD_40M         => BRD_40M,
      ADC_CLK_P       => ADC_CLK_P,
      ADC_CLK_N       => ADC_CLK_N,
      ADC_QUAD_P      => ADC_QUAD_P,
      ADC_QUAD_N      => ADC_QUAD_N,
      ADC_LCLK_P      => ADC_LCLK_P,
      ADC_LCLK_N      => ADC_LCLK_N,
      ADC_SDATA       => ADC_SDATA,
      ADC_SCLK        => ADC_SCLK,
      ADC_CS_n        => ADC_CS_n,
      ADC_INTEXT      => ADC_INTEXT,
      ADC_RESET_n     => ADC_RESET_n,
      ADC_PDWN        => ADC_PDWN,
      ADC_CLK40M_P    => ADC_CLK40M_P,
      ADC_CLK40M_N    => ADC_CLK40M_N,
      ALT_TRSF_EN     => ALT_TRSF_EN,
      ALT_ACKN_EN     => ALT_ACKN_EN,
      ALT_DOLO_EN     => ALT_DOLO_EN,
      ALT_SCLK_P      => ALT_SCLK_P,
      ALT_SCLK_N      => ALT_SCLK_N,
      ALT_RDOCLK      => ALT_RDOCLK,
      ALT_TRSF        => ALT_TRSF,
      ALT_DSTB        => ALT_DSTB,
      ALT_ACKN        => ALT_ACKN,
      ALT_ERROR       => ALT_ERROR,
      ALT_RST_TBC     => ALT_RST_TBC,
      ALT_L1          => ALT_L1,
      ALT_L2          => ALT_L2,
      ALT_WRITE       => ALT_WRITE,
      ALT_CSTB        => ALT_CSTB,
      RCU_SCL         => RCU_SCL,
      RCU_SDA_IN      => RCU_SDA_IN,
      RCU_SDA_OUT     => RCU_SDA_OUT,
      ALT_BD          => ALT_BD,
      ALT_CARDADD     => ALT_CARDADD,
      GTL_OEBA_L      => GTL_OEBA_L,
      GTL_OEAB_L      => GTL_OEAB_L,
      GTL_OEBA_H      => GTL_OEBA_H,
      GTL_OEAB_H      => GTL_OEAB_H,
      GTL_CTRL_IN     => GTL_CTRL_IN,
      GTL_CTRL_OUT    => GTL_CTRL_OUT,
      TRU_INTERRUPT_n => TRU_INTERRUPT_n,
      BRD_CLK125M_P   => BRD_CLK125M_P,
      BRD_CLK125M_N   => BRD_CLK125M_N,
      LED_LVDS_RXTX   => LED_LVDS_RXTX,
      LED_AUX1        => LED_AUX1,
      LED_AUX2        => LED_AUX2,
      LED_BUSY        => LED_BUSY,
      LED_L0          => LED_L0,
      LED_L1          => LED_L1,
      LED_RCU_RXTX    => LED_RCU_RXTX,
      LED_SYS_OK      => LED_SYS_OK,
      LED_PWR_ERR     => LED_PWR_ERR,
      LED_SYS_ERR     => LED_SYS_ERR,
      LDO_2V5_DIG     => LDO_2V5_DIG,
      LDO_3V3_DIG     => LDO_3V3_DIG,
      LDO_3V3_ADC     => LDO_3V3_ADC,
      LDO_2V5_ADC     => LDO_2V5_ADC,
      LDO_ADC_EN      => LDO_ADC_EN,
      TST_AUX9        => TST_AUX9,
      TST_AUX8        => TST_AUX8,
      TST_AUX7        => TST_AUX7,
      TST_AUX6        => TST_AUX6,
      TST_AUX5        => TST_AUX5,
      TST_AUX4        => TST_AUX4,
      TST_AUX3        => TST_AUX3,
      TST_AUX2        => TST_AUX2,
      TST_AUX1        => TST_AUX1,
      TST_AUX0        => TST_AUX0,
      X2A_CLK         => X2A_CLK,
      SNS_OTI         => SNS_OTI,
      SNS_SDA         => SNS_SDA,
      SNS_SCL         => SNS_SCL,
      SNS_CONV_n      => SNS_CONV_n,
      EXT_LVDS_IO_P   => EXT_LVDS_IO_P,
      EXT_LVDS_IO_N   => EXT_LVDS_IO_N
      );

  PROCESS                               -- clock process for BRD_40M
  BEGIN
    WAIT FOR OFFSET;
    CLOCK_LOOP : LOOP
      BRD_40M <= '0';
      WAIT FOR (PERIOD - (PERIOD * DUTY_CYCLE));
      BRD_40M <= '1';
      WAIT FOR (PERIOD * DUTY_CYCLE);
    END LOOP CLOCK_LOOP;
  END PROCESS;

  PROCESS
  BEGIN
    -- -------------  Current Time:  107ns
    WAIT FOR 107 ns;
    BRD_RESET_n <= '0';
    -- -------------------------------------
    -- -------------  Current Time:  203ns
    WAIT FOR 96 ns;
    BRD_RESET_n <= '1';
    -- -------------------------------------
    -- -------------  Current Time:  999ns
    WAIT FOR 796 ns;
--    TST_AUX9    <= '1';
    -- -------------------------------------
    -- -------------  Current Time:  1287ns
    WAIT FOR 288 ns;
--    TST_AUX9    <= '0';
    -- -------------------------------------
    WAIT FOR 18713 ns;                   --
    -- Total time = 20,000 ns      

  END PROCESS;

  PROCESS           -- clock process for ADC_LCLK (data clock)
  BEGIN
    WAIT FOR 4 ns;                      -- offset
    CLOCK_LOOP : LOOP
      ADC_LCLK_P(0) <= '0';
      ADC_LCLK_N(0) <= '1';
      WAIT FOR 2 ns;
      ADC_LCLK_P(0) <= '1';
      ADC_LCLK_N(0) <= '0';
      WAIT FOR 2 ns;
    END LOOP CLOCK_LOOP;
  END PROCESS;

  PROCESS            -- clock process for ADC_CLK (frame clock)
  BEGIN
    WAIT FOR 27 ns;                     -- offset
    CLOCK_LOOP : LOOP
      ADC_CLK_P(0) <= '1';
      ADC_CLK_N(0) <= '0';
      WAIT FOR 12 ns;
      ADC_CLK_P(0) <= '0';
      ADC_CLK_N(0) <= '1';
      WAIT FOR 12 ns;
    END LOOP CLOCK_LOOP;
  END PROCESS;


  PROCESS
  BEGIN

    WAIT FOR 250 ns;                    -- offset = 10 + n*24
    ADC_QUAD_P(0) <= '1';               -- 0
    ADC_QUAD_N(0) <= '0';

    WAIT FOR 2 ns;                      -- 1
    ADC_QUAD_P(0) <= '0';
    ADC_QUAD_N(0) <= '1';

    WAIT FOR 2 ns;                      -- 2
    ADC_QUAD_P(0) <= '1';
    ADC_QUAD_N(0) <= '0';

    WAIT FOR 2 ns;                      -- 3
    ADC_QUAD_P(0) <= '0';
    ADC_QUAD_N(0) <= '1';

    WAIT FOR 2 ns;                      -- 4
    ADC_QUAD_P(0) <= '1';
    ADC_QUAD_N(0) <= '0';

    WAIT FOR 2 ns;                      -- 5
    ADC_QUAD_P(0) <= '0';
    ADC_QUAD_N(0) <= '1';

    WAIT FOR 2 ns;                      -- 6, 7, 8
    ADC_QUAD_P(0) <= '1';
    ADC_QUAD_N(0) <= '0';

    WAIT FOR 6 ns;                      -- 9, 10, 11
    ADC_QUAD_P(0) <= '0';
    ADC_QUAD_N(0) <= '1';

    WAIT FOR 6 ns;                      -- data = 0 for the rest
    ADC_QUAD_P(0) <= '0';
    ADC_QUAD_N(0) <= '1';

    WAIT FOR 230 ns;

  END PROCESS;

  PROCESS
  BEGIN

    WAIT FOR 200 ns;
    ADC_QUAD_P(1) <= '1';
    ADC_QUAD_N(1) <= '0';

    WAIT FOR 100 ns;
    ADC_QUAD_P(1) <= '0';
    ADC_QUAD_N(1) <= '1';

    WAIT FOR 100 ns;
    ADC_QUAD_P(1) <= '1';
    ADC_QUAD_N(1) <= '0';

    WAIT FOR 100 ns;
    ADC_QUAD_P(1) <= '0';
    ADC_QUAD_N(1) <= '1';

    WAIT FOR 9500 ns;

  END PROCESS;




  
END testbench_arch;


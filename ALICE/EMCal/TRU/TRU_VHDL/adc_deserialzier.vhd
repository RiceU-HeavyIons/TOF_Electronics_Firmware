-- $Id: adc_deserialzier.vhd,v 1.1 2008-10-14 22:11:15 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : ADC Deserializer
-- Project    : 
-------------------------------------------------------------------------------
-- File       : adc_deserializer.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-10-08
-- Last update: 2008-10-14
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-10-08  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY UNISIM;
USE UNISIM.vcomponents.ALL;


-------------------------------------------------------------------------------

ENTITY adc_deserializer IS
  PORT (
    -- clocks and reset
    RESET     : IN std_logic;           -- reset (active high)
    ADC_READY : IN std_logic;           -- ADC is configured

    -- ADC inputs (14 ADCs, 8 channels each)
    ADC_CLK_P, ADC_CLK_N   : IN  std_logic_vector (13 DOWNTO 0);  -- LVDS frame clock
    ADC_QUAD_P, ADC_QUAD_N : IN  std_logic_vector (111 DOWNTO 0);  -- LVDS data
    ADC_LCLK_P, ADC_LCLK_N : IN  std_logic_vector (13 DOWNTO 0);  -- LVDS clock
    -- resulting output
    SERDESe_RDY            : OUT std_logic_vector (13 DOWNTO 0);
    SERDESo_RDY            : OUT std_logic_vector (13 DOWNTO 0);
    ADC_SERDES_OUT         : OUT std_logic_vector (1343 DOWNTO 0)  -- de-serialized ADC data
    );
END ENTITY adc_deserializer;

-------------------------------------------------------------------------------

ARCHITECTURE str1 OF adc_deserializer IS

  -- Two LVDS signals were routed to opposite pads on the FPGA and need to be inverted.
  -- These two constants are used below to do this inversion.
  CONSTANT ADC_LCLK_POLARITY_FLIP   : std_logic_vector(0 TO 13)  := (9  => '1', OTHERS => '0');
  CONSTANT ADC_QUAD_POLARITY_FLIP   : std_logic_vector(0 TO 111) := (88 => '1', OTHERS => '0');
  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  SIGNAL s_adc_fclk, s_adc_fclkp    : std_logic_vector (13 DOWNTO 0);
--  SIGNAL s_adc_dclk_p, s_adc_dclk_n : std_logic_vector (13 DOWNTO 0);
  SIGNAL s_adc_dclk_r               : std_logic_vector (13 DOWNTO 0);
  SIGNAL s_adc_data_p, s_adc_data_n : std_logic_vector (111 DOWNTO 0);
  SIGNAL s_serdes_out               : std_logic_vector (1343 DOWNTO 0);  -- 12 * 112
  SIGNAL s_adc_dclk                 : std_logic_vector (13 DOWNTO 0);
  SIGNAL bse, bso                   : std_logic_vector (13 DOWNTO 0);
  SIGNAL serdes_rste, serdes_rsto   : std_logic_vector (13 DOWNTO 0);
  SIGNAL s_bitslip_rst              : std_logic;

  TYPE BS_CNT IS ARRAY (0 TO 13) OF integer RANGE 0 TO 7;
  CONSTANT bs_cnt_even : BS_CNT := (5, 5, 5, 4, 5, 5, 5, 5, 5, 5, 4, 5, 5, 5);
  CONSTANT bs_cnt_odd  : BS_CNT := (4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4);

  COMPONENT adc_bitslip IS
    PORT (
      RESET        : IN  std_logic;
      ADC_FCLK     : IN  std_logic;
      BITSLIP_CNT  : IN  integer RANGE 0 TO 7;
      SERDES_RDY   : OUT std_logic;
      BITSLIP_CTRL : OUT std_logic);
  END COMPONENT adc_bitslip;
  
BEGIN  -- ARCHITECTURE str1

  -- 671 = (14 ADC * 8 channel * 12 bits)/2 - 1
  Gfinal : FOR j IN 0 TO 671 GENERATE
    ADC_SERDES_OUT(j*2)   <= s_serdes_out(j*2);
    -- odd bits are inverted
    ADC_SERDES_OUT(j*2+1) <= NOT s_serdes_out(j*2+1);
  END GENERATE Gfinal;

  -----------------------------------------------------------------------------
  -- Frame clock
  -----------------------------------------------------------------------------
  G1 : FOR j IN 0 TO 13 GENERATE
    adcFrameClk_inst : IBUFDS
      GENERIC MAP (
        IOSTANDARD => "LVDS_25",
        DIFF_TERM  => true)
      PORT MAP (
        I  => ADC_CLK_P(j),
        IB => ADC_CLK_N(j),
        O  => s_adc_fclkp(j));

    -- use BUFRs to distribute frame clocks
    adcFrameClkg_inst : BUFR
      GENERIC MAP (
        BUFR_DIVIDE => "BYPASS",
        SIM_DEVICE  => "VIRTEX5")
      PORT MAP (
        O   => s_adc_fclk(j),
        CE  => '1',
        CLR => '0',
        I   => s_adc_fclkp(j)
        );
  END GENERATE G1;

  -----------------------------------------------------------------------------
  -- Data (bit) clock
  -----------------------------------------------------------------------------
  G2 : FOR j IN 0 TO 13 GENERATE
    G2a : IF ADC_LCLK_POLARITY_FLIP(j) = '0' GENERATE
      dclock_inst : IBUFDS
        GENERIC MAP (
          IOSTANDARD => "LVDS_25",
          DIFF_TERM  => true)
        PORT MAP (
          I  => ADC_LCLK_P(j),
          IB => ADC_LCLK_N(j),
          O  => s_adc_dclk(j)
          );
    END GENERATE G2a;

    -- inverted routing:
    G2b : IF ADC_LCLK_POLARITY_FLIP(j) = '1' GENERATE
      dclock_inst : IBUFDS
        GENERIC MAP (
          IOSTANDARD => "LVDS_25",
          DIFF_TERM  => true)
        PORT MAP (
          I  => ADC_LCLK_N(j),
          IB => ADC_LCLK_P(j),
          O  => s_adc_dclk(j)
          );
    END GENERATE G2b;

    -- use BUFIOs to distribute the bit clock
    dclockrp_inst : BUFIO
      PORT MAP (
        O => s_adc_dclk_r(j),
        I => s_adc_dclk(j)
        );

  END GENERATE G2;

  -----------------------------------------------------------------------------
  -- LVDS data
  -----------------------------------------------------------------------------
  G3 : FOR j IN 0 TO 111 GENERATE
    G3a : IF ADC_QUAD_POLARITY_FLIP(j) = '0' GENERATE
      data_inst : IBUFDS_DIFF_OUT
        GENERIC MAP (
          IOSTANDARD => "LVDS_25")
        PORT MAP (
          I  => ADC_QUAD_P(j),
          IB => ADC_QUAD_N(j),
          O  => s_adc_data_p(j),
          OB => s_adc_data_n(j)
          );
    END GENERATE G3a;

    -- inverted routing:
    G3b : IF ADC_QUAD_POLARITY_FLIP(j) = '1' GENERATE
      data_inst : IBUFDS_DIFF_OUT
        GENERIC MAP (
          IOSTANDARD => "LVDS_25")
        PORT MAP (
          I  => ADC_QUAD_N(j),
          IB => ADC_QUAD_P(j),
          O  => s_adc_data_n(j),
          OB => s_adc_data_p(j)
          );
    END GENERATE G3b;
    
  END GENERATE G3;


-- Application Note 866 states that the Virtex 5 ISERDES_NODELAY can be
-- replaced by the Virtex 4 ISERDES, and the ISE software will substitute a
-- ISERDES_NODELAY combined with a IODELAY element to implement this primitive.
-- So this gives us the ISERDES with an adjustable delay on the input.

  G4 : FOR i IN 0 TO 13 GENERATE        -- 14 ADCs
    G4a : FOR j IN 0 TO 7 GENERATE      -- 8 channels each

      G4a1 : IF ADC_LCLK_POLARITY_FLIP(i) = '0' GENERATE
        -----------------------------------------------------------------------------
        -- deserialize all of the positive data lines with the positive clock;
        -----------------------------------------------------------------------------
        ISERDES_even : ISERDES
          GENERIC MAP (
            BITSLIP_ENABLE => true,  -- TRUE/FALSE to enable bitslip controller
            DATA_RATE      => "SDR",    -- Specify data rate of "DDR" or "SDR" 
            DATA_WIDTH     => 6,        -- Specify data width - 
            INTERFACE_TYPE => "NETWORKING",  -- Use model - "MEMORY" or "NETWORKING" 
            IOBDELAY       => "IFD",  -- Specify outputs where delay chain will be applied
            -- "NONE", "IBUF", "IFD", or "BOTH" 
            IOBDELAY_TYPE  => "FIXED",  -- Set tap delay "DEFAULT", "FIXED", or "VARIABLE" 
            IOBDELAY_VALUE => 0,  -- Set initial tap delay to an integer from 0 to 63
            NUM_CE         => 1,  -- Define number or clock enables to an integer of 1 or 2
            SERDES_MODE    => "MASTER")  -- Set SERDES mode to "MASTER" or "SLAVE" 
          PORT MAP (
            O         => OPEN,
            Q1        => s_serdes_out((i*8+j)*12+10),  -- 1-bit registered SERDES output
            Q2        => s_serdes_out((i*8+j)*12+8),  -- 1-bit registered SERDES output
            Q3        => s_serdes_out((i*8+j)*12+6),  -- 1-bit registered SERDES output
            Q4        => s_serdes_out((i*8+j)*12+4),  -- 1-bit registered SERDES output
            Q5        => s_serdes_out((i*8+j)*12+2),  -- 1-bit registered SERDES output
            Q6        => s_serdes_out((i*8+j)*12+0),  -- 1-bit registered SERDES output
            SHIFTOUT1 => OPEN,          -- 1-bit cascade Master/Slave output
            SHIFTOUT2 => OPEN,          -- 1-bit cascade Master/Slave output
            BITSLIP   => bse(i),        -- 1-bit Bitslip enable input
            CE1       => '1',           -- 1-bit clock enable input
            CE2       => '0',           -- 1-bit clock enable input
            CLK       => s_adc_dclk_r(i),    -- 1-bit master clock input
            CLKDIV    => s_adc_fclk(i),  -- 1-bit divided clock input
            D         => s_adc_data_p(i*8+j),  -- 1-bit data input, connects to IODELAY or input buffer
            DLYCE     => '0',           -- 1-bit input
            DLYINC    => '0',           -- 1-bit input
            DLYRST    => '0',           -- 1-bit input
            OCLK      => '0',           -- 1-bit fast output clock input
            SR        => serdes_rste(i),     -- 1-bit asynchronous reset input
            REV       => '0',           -- Must be tied to logic zero
            SHIFTIN1  => '0',           -- 1-bit cascade Master/Slave input
            SHIFTIN2  => '0'            -- 1-bit cascade Master/Slave input
            );

        -----------------------------------------------------------------------------
        -- deserialize all of the negative data lines with the negative clock;
        -----------------------------------------------------------------------------
        ISERDES_odd : ISERDES
          GENERIC MAP (
            BITSLIP_ENABLE => true,  -- TRUE/FALSE to enable bitslip controller
            DATA_RATE      => "SDR",    -- Specify data rate of "DDR" or "SDR" 
            DATA_WIDTH     => 6,        -- Specify data width - 
            INTERFACE_TYPE => "NETWORKING",  -- Use model - "MEMORY" or "NETWORKING" 
            IOBDELAY       => "IFD",  -- Specify outputs where delay chain will be applied
            -- "NONE", "IBUF", "IFD", or "BOTH" 
            IOBDELAY_TYPE  => "FIXED",  -- Set tap delay "DEFAULT", "FIXED", or "VARIABLE" 
            IOBDELAY_VALUE => 0,  -- Set initial tap delay to an integer from 0 to 63
            NUM_CE         => 1,  -- Define number or clock enables to an integer of 1 or 2
            SERDES_MODE    => "MASTER")  -- Set SERDES mode to "MASTER" or "SLAVE" 
          PORT MAP (
            O         => OPEN,
            Q1        => s_serdes_out((i*8+j)*12+11),  -- 1-bit registered SERDES output
            Q2        => s_serdes_out((i*8+j)*12+9),  -- 1-bit registered SERDES output
            Q3        => s_serdes_out((i*8+j)*12+7),  -- 1-bit registered SERDES output
            Q4        => s_serdes_out((i*8+j)*12+5),  -- 1-bit registered SERDES output
            Q5        => s_serdes_out((i*8+j)*12+3),  -- 1-bit registered SERDES output
            Q6        => s_serdes_out((i*8+j)*12+1),  -- 1-bit registered SERDES output
            SHIFTOUT1 => OPEN,          -- 1-bit cascade Master/Slave output
            SHIFTOUT2 => OPEN,          -- 1-bit cascade Master/Slave output
            BITSLIP   => bso(i),        -- 1-bit Bitslip enable input
            CE1       => '1',           -- 1-bit clock enable input
            CE2       => '0',           -- 1-bit clock enable input
            CLK       => NOT s_adc_dclk_r(i),  -- 1-bit master clock input
            CLKDIV    => s_adc_fclk(i),  -- 1-bit divided clock input
            D         => s_adc_data_n(i*8+j),  -- 1-bit data input, connects to IODELAY or input buffer
            DLYCE     => '0',           -- 1-bit input
            DLYINC    => '0',           -- 1-bit input
            DLYRST    => '0',           -- 1-bit input
            OCLK      => '0',           -- 1-bit fast output clock input
            SR        => serdes_rsto(i),     -- 1-bit asynchronous reset input
            REV       => '0',           -- Must be tied to logic zero
            SHIFTIN1  => '0',           -- 1-bit cascade Master/Slave input
            SHIFTIN2  => '0'            -- 1-bit cascade Master/Slave input
            );
      END GENERATE G4a1;

      -------------------------------------------------------------------------
      -- ADC_LCLK[9] is inverted,
      -- so these data lines need to use the opposite clock
      -------------------------------------------------------------------------
      G4a2 : IF ADC_LCLK_POLARITY_FLIP(i) = '1' GENERATE
        -----------------------------------------------------------------------------
        -- deserialize all of the positive data lines;
        -- use opposite clock for these to compensate for inverted routing
        -----------------------------------------------------------------------------
        ISERDES_even : ISERDES
          GENERIC MAP (
            BITSLIP_ENABLE => true,  -- TRUE/FALSE to enable bitslip controller
            DATA_RATE      => "SDR",    -- Specify data rate of "DDR" or "SDR" 
            DATA_WIDTH     => 6,        -- Specify data width - 
            INTERFACE_TYPE => "NETWORKING",  -- Use model - "MEMORY" or "NETWORKING" 
            IOBDELAY       => "IFD",  -- Specify outputs where delay chain will be applied
            -- "NONE", "IBUF", "IFD", or "BOTH" 
            IOBDELAY_TYPE  => "FIXED",  -- Set tap delay "DEFAULT", "FIXED", or "VARIABLE" 
            IOBDELAY_VALUE => 0,  -- Set initial tap delay to an integer from 0 to 63
            NUM_CE         => 1,  -- Define number or clock enables to an integer of 1 or 2
            SERDES_MODE    => "MASTER")  -- Set SERDES mode to "MASTER" or "SLAVE" 
          PORT MAP (
            O         => OPEN,
            Q1        => s_serdes_out((i*8+j)*12+10),  -- 1-bit registered SERDES output
            Q2        => s_serdes_out((i*8+j)*12+8),  -- 1-bit registered SERDES output
            Q3        => s_serdes_out((i*8+j)*12+6),  -- 1-bit registered SERDES output
            Q4        => s_serdes_out((i*8+j)*12+4),  -- 1-bit registered SERDES output
            Q5        => s_serdes_out((i*8+j)*12+2),  -- 1-bit registered SERDES output
            Q6        => s_serdes_out((i*8+j)*12+0),  -- 1-bit registered SERDES output
            SHIFTOUT1 => OPEN,          -- 1-bit cascade Master/Slave output
            SHIFTOUT2 => OPEN,          -- 1-bit cascade Master/Slave output
            BITSLIP   => bse(i),        -- 1-bit Bitslip enable input
            CE1       => '1',           -- 1-bit clock enable input
            CE2       => '0',           -- 1-bit clock enable input
            CLK       => NOT s_adc_dclk_r(i),  -- 1-bit master clock input
            CLKDIV    => s_adc_fclk(i),  -- 1-bit divided clock input
            D         => s_adc_data_p(i*8+j),  -- 1-bit data input, connects to IODELAY or input buffer
            DLYCE     => '0',           -- 1-bit input
            DLYINC    => '0',           -- 1-bit input
            DLYRST    => '0',           -- 1-bit input
            OCLK      => '0',           -- 1-bit fast output clock input
            SR        => serdes_rste(i),     -- 1-bit asynchronous reset input
            REV       => '0',           -- Must be tied to logic zero
            SHIFTIN1  => '0',           -- 1-bit cascade Master/Slave input
            SHIFTIN2  => '0'            -- 1-bit cascade Master/Slave input
            );

        -----------------------------------------------------------------------------
        -- deserialize all of the negative data lines;
        -- use opposite clock for these to compensate for inverted routing
        -----------------------------------------------------------------------------
        ISERDES_odd : ISERDES
          GENERIC MAP (
            BITSLIP_ENABLE => true,  -- TRUE/FALSE to enable bitslip controller
            DATA_RATE      => "SDR",    -- Specify data rate of "DDR" or "SDR" 
            DATA_WIDTH     => 6,        -- Specify data width - 
            INTERFACE_TYPE => "NETWORKING",  -- Use model - "MEMORY" or "NETWORKING" 
            IOBDELAY       => "IFD",  -- Specify outputs where delay chain will be applied
            -- "NONE", "IBUF", "IFD", or "BOTH" 
            IOBDELAY_TYPE  => "FIXED",  -- Set tap delay "DEFAULT", "FIXED", or "VARIABLE" 
            IOBDELAY_VALUE => 0,  -- Set initial tap delay to an integer from 0 to 63
            NUM_CE         => 1,  -- Define number or clock enables to an integer of 1 or 2
            SERDES_MODE    => "MASTER")  -- Set SERDES mode to "MASTER" or "SLAVE" 
          PORT MAP (
            O         => OPEN,
            Q1        => s_serdes_out((i*8+j)*12+11),  -- 1-bit registered SERDES output
            Q2        => s_serdes_out((i*8+j)*12+9),  -- 1-bit registered SERDES output
            Q3        => s_serdes_out((i*8+j)*12+7),  -- 1-bit registered SERDES output
            Q4        => s_serdes_out((i*8+j)*12+5),  -- 1-bit registered SERDES output
            Q5        => s_serdes_out((i*8+j)*12+3),  -- 1-bit registered SERDES output
            Q6        => s_serdes_out((i*8+j)*12+1),  -- 1-bit registered SERDES output
            SHIFTOUT1 => OPEN,          -- 1-bit cascade Master/Slave output
            SHIFTOUT2 => OPEN,          -- 1-bit cascade Master/Slave output
            BITSLIP   => bso(i),        -- 1-bit Bitslip enable input
            CE1       => '1',           -- 1-bit clock enable input
            CE2       => '0',           -- 1-bit clock enable input
            CLK       => s_adc_dclk_r(i),    -- 1-bit master clock input
            CLKDIV    => s_adc_fclk(i),  -- 1-bit divided clock input
            D         => s_adc_data_n(i*8+j),  -- 1-bit data input, connects to IODELAY or input buffer
            DLYCE     => '0',           -- 1-bit input
            DLYINC    => '0',           -- 1-bit input
            DLYRST    => '0',           -- 1-bit input
            OCLK      => '0',           -- 1-bit fast output clock input
            SR        => serdes_rsto(i),     -- 1-bit asynchronous reset input
            REV       => '0',           -- Must be tied to logic zero
            SHIFTIN1  => '0',           -- 1-bit cascade Master/Slave input
            SHIFTIN2  => '0'            -- 1-bit cascade Master/Slave input
            );
      END GENERATE G4a2;

    END GENERATE G4a;
  END GENERATE G4;


  -- bitslip control
  s_bitslip_rst <= (NOT ADC_READY) OR RESET;

  GBS : FOR i IN 0 TO 13 GENERATE
    -- hold serdes in reset while ADCs are initialized
    serdes_rste(i) <= NOT ADC_READY;
    serdes_rsto(i) <= NOT ADC_READY;

    bitslipe : adc_bitslip PORT MAP (
      RESET        => s_bitslip_rst,
      ADC_FCLK     => s_adc_fclk(i),
      BITSLIP_CNT  => bs_cnt_even(i),
      SERDES_RDY   => SERDESe_RDY(i),
      BITSLIP_CTRL => bse(i));
    bitslipo : adc_bitslip PORT MAP (
      RESET        => s_bitslip_rst,
      ADC_FCLK     => s_adc_fclk(i),
      BITSLIP_CNT  => bs_cnt_odd(i),
      SERDES_RDY   => SERDESo_RDY(i),
      BITSLIP_CTRL => bso(i));

  END GENERATE GBS;
  
END ARCHITECTURE str1;

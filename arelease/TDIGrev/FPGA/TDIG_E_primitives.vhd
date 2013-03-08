-- $Id: TDIG_E_primitives.vhd,v 1.1.1.1 2008-02-12 21:01:52 jschamba Exp $

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;

PACKAGE TDIG_E_primitives IS

  COMPONENT GLOBAL
    PORT (a_in  : IN  std_logic;
          a_out : OUT std_logic);
  END COMPONENT;

  COMPONENT PLL_clk_mult_by3
    PORT
      (
        areset : IN  std_logic := '0';
        inclk0 : IN  std_logic := '0';
        c0     : OUT std_logic;
        locked : OUT std_logic
        );
  END COMPONENT;

  COMPONENT bidir_buffer_8bit
    PORT
      (
        data     : IN    std_logic_vector (7 DOWNTO 0);
        enabledt : IN    std_logic;
        enabletr : IN    std_logic;
        result   : OUT   std_logic_vector (7 DOWNTO 0);
        tridata  : INOUT std_logic_vector (7 DOWNTO 0)
        );
  END COMPONENT;

-- FIFOS **********************************************

  COMPONENT FIFO_33wide_64deep
    PORT
      (
        clock : IN  std_logic;
        data  : IN  std_logic_vector (32 DOWNTO 0);
        rdreq : IN  std_logic;
        sclr  : IN  std_logic;
        wrreq : IN  std_logic;
        empty : OUT std_logic;
        full  : OUT std_logic;
        q     : OUT std_logic_vector (32 DOWNTO 0);
        usedw : OUT std_logic_vector (5 DOWNTO 0)
        );
  END COMPONENT;

-- state machines ************************************  

  COMPONENT ser_ctl1
    PORT (
      CLK, DATA, DELAY_OUT, RESET, TOKEN_OUT, TRIGGER : IN  std_logic;
      DELAY_IN, PAR_CLK, TOKEN_IN                     : OUT std_logic);
  END COMPONENT;

  COMPONENT ser_read
    PORT (
      CLK, DATA, DATA_CLK, RESET, TDC_TOKEN_OUT, TRIGGER : IN  std_logic;
      PAR_CLK, TDC_TOKEN_IN                              : OUT std_logic;
      PAR_DATA                                           : OUT std_logic_vector(31 DOWNTO 0));
  END COMPONENT;

  COMPONENT short
    PORT (
      clk, input_hi, reset : IN  std_logic;
      out_hi               : OUT std_logic);
  END COMPONENT;

  COMPONENT fifo_rd IS  --- sends 1 clock pulse at end of input pulse
    PORT (
      clk, rd_adr14, reset : IN  std_logic;
      out_hi               : OUT std_logic);
  END COMPONENT;

  COMPONENT push_tst IS
    PORT (
      clk, push, reset                       : IN  std_logic;
      tst_strobe5, tst_strobe9, tst_strobe10 : OUT std_logic);
  END COMPONENT;

-- quartus generated functions ***********************

  COMPONENT shift32
    PORT
      (
        clock    : IN  std_logic;
        sclr     : IN  std_logic;
        shiftin  : IN  std_logic;
        q        : OUT std_logic_vector (31 DOWNTO 0);
        shiftout : OUT std_logic
        );
  END COMPONENT;

  COMPONENT shift31
    PORT
      (
        clock    : IN  std_logic;
        sclr     : IN  std_logic;
        shiftin  : IN  std_logic;
        q        : OUT std_logic_vector (30 DOWNTO 0);
        shiftout : OUT std_logic
        );
  END COMPONENT;

-- counters *****************************************   

  COMPONENT hit_counter_16bits
    PORT
      (
        clock  : IN  std_logic;
        cnt_en : IN  std_logic;
        data   : IN  std_logic_vector (15 DOWNTO 0);
        sclr   : IN  std_logic;
        sload  : IN  std_logic;
        cout   : OUT std_logic;
        q      : OUT std_logic_vector (15 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT counter_33bit
    PORT
      (
        clk_en : IN  std_logic;
        clock  : IN  std_logic;
        sclr   : IN  std_logic;
        cout   : OUT std_logic;
        q      : OUT std_logic_vector (32 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT compare_16bit
    PORT
      (
        clock : IN  std_logic;
        dataa : IN  std_logic_vector (15 DOWNTO 0);
        datab : IN  std_logic_vector (15 DOWNTO 0);
        AeB   : OUT std_logic
        );
  END COMPONENT;

-- registers *****************************************

  COMPONENT reg_32bit
    PORT
      (
        clock  : IN  std_logic;
        data   : IN  std_logic_vector (31 DOWNTO 0);
        enable : IN  std_logic;
        sclr   : IN  std_logic;
        q      : OUT std_logic_vector (31 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT reg_16bit
    PORT
      (
        clock  : IN  std_logic;
        data   : IN  std_logic_vector (15 DOWNTO 0);
        enable : IN  std_logic;
        q      : OUT std_logic_vector (15 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT reg_8bit
    PORT
      (
        clock  : IN  std_logic;
        data   : IN  std_logic_vector (7 DOWNTO 0);
        enable : IN  std_logic;
        sclr   : IN  std_logic;
        q      : OUT std_logic_vector (7 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT DFLOP
    PORT
      (
        aclr  : IN  std_logic;
        clock : IN  std_logic;
        data  : IN  std_logic;
        sclr  : IN  std_logic;
        q     : OUT std_logic
        );
  END COMPONENT;

-- DECODERS

  COMPONENT decoder_4to16 PORT (
    data   : IN  std_logic_vector (3 DOWNTO 0);
    enable : IN  std_logic;
    eq0    : OUT std_logic;
    eq1    : OUT std_logic;
    eq2    : OUT std_logic;
    eq3    : OUT std_logic;
    eq4    : OUT std_logic;
    eq5    : OUT std_logic;
    eq6    : OUT std_logic;
    eq7    : OUT std_logic;
    eq8    : OUT std_logic;
    eq9    : OUT std_logic;
    eq10   : OUT std_logic;
    eq11   : OUT std_logic;
    eq12   : OUT std_logic;
    eq13   : OUT std_logic;
    eq14   : OUT std_logic;
    eq15   : OUT std_logic);
  END COMPONENT;

  COMPONENT decoder_4to16_reg
    PORT
      (
        clock  : IN  std_logic;
        data   : IN  std_logic_vector (3 DOWNTO 0);
        enable : IN  std_logic;
        eq0    : OUT std_logic;
        eq1    : OUT std_logic;
        eq10   : OUT std_logic;
        eq11   : OUT std_logic;
        eq12   : OUT std_logic;
        eq13   : OUT std_logic;
        eq14   : OUT std_logic;
        eq15   : OUT std_logic;
        eq2    : OUT std_logic;
        eq3    : OUT std_logic;
        eq4    : OUT std_logic;
        eq5    : OUT std_logic;
        eq6    : OUT std_logic;
        eq7    : OUT std_logic;
        eq8    : OUT std_logic;
        eq9    : OUT std_logic
        );
  END COMPONENT;

  COMPONENT decoder_4to1
    PORT
      (
        data   : IN  std_logic_vector (1 DOWNTO 0);
        enable : IN  std_logic;
        eq0    : OUT std_logic;
        eq1    : OUT std_logic;
        eq2    : OUT std_logic;
        eq3    : OUT std_logic
        );
  END COMPONENT;

-- MULTIPLEXERS

  COMPONENT mux_2to1_8bits PORT (
    data0x : IN  std_logic_vector (7 DOWNTO 0);
    data1x : IN  std_logic_vector (7 DOWNTO 0);
    sel    : IN  std_logic;
    result : OUT std_logic_vector (7 DOWNTO 0));
  END COMPONENT;

  COMPONENT mux_8bits_16inputs
    PORT
      (
        data0x  : IN  std_logic_vector (7 DOWNTO 0);
        data10x : IN  std_logic_vector (7 DOWNTO 0);
        data11x : IN  std_logic_vector (7 DOWNTO 0);
        data12x : IN  std_logic_vector (7 DOWNTO 0);
        data13x : IN  std_logic_vector (7 DOWNTO 0);
        data14x : IN  std_logic_vector (7 DOWNTO 0);
        data15x : IN  std_logic_vector (7 DOWNTO 0);
        data1x  : IN  std_logic_vector (7 DOWNTO 0);
        data2x  : IN  std_logic_vector (7 DOWNTO 0);
        data3x  : IN  std_logic_vector (7 DOWNTO 0);
        data4x  : IN  std_logic_vector (7 DOWNTO 0);
        data5x  : IN  std_logic_vector (7 DOWNTO 0);
        data6x  : IN  std_logic_vector (7 DOWNTO 0);
        data7x  : IN  std_logic_vector (7 DOWNTO 0);
        data8x  : IN  std_logic_vector (7 DOWNTO 0);
        data9x  : IN  std_logic_vector (7 DOWNTO 0);
        sel     : IN  std_logic_vector (3 DOWNTO 0);
        result  : OUT std_logic_vector (7 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT mux_2to1_33bits
    PORT
      (
        data0x : IN  std_logic_vector (32 DOWNTO 0);
        data1x : IN  std_logic_vector (32 DOWNTO 0);
        sel    : IN  std_logic;
        result : OUT std_logic_vector (32 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT mux_2_to_1_1bit_wide
    PORT
      (
        data0  : IN  std_logic;
        data1  : IN  std_logic;
        sel    : IN  std_logic;
        result : OUT std_logic
        );
  END COMPONENT;

  COMPONENT mux_4to1_1bit_wide
    PORT
      (
        data0  : IN  std_logic;
        data1  : IN  std_logic;
        data2  : IN  std_logic;
        data3  : IN  std_logic;
        sel    : IN  std_logic_vector (1 DOWNTO 0);
        result : OUT std_logic
        );
  END COMPONENT;

  COMPONENT mux_2to1_3bit_wide
    PORT
      (
        data0x : IN  std_logic_vector (2 DOWNTO 0);
        data1x : IN  std_logic_vector (2 DOWNTO 0);
        sel    : IN  std_logic;
        result : OUT std_logic_vector (2 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT mux_8to1_1bit_wide
    PORT
      (
        data0  : IN  std_logic;
        data1  : IN  std_logic;
        data2  : IN  std_logic;
        data3  : IN  std_logic;
        data4  : IN  std_logic;
        data5  : IN  std_logic;
        data6  : IN  std_logic;
        data7  : IN  std_logic;
        sel    : IN  std_logic_vector (2 DOWNTO 0);
        result : OUT std_logic);
  END COMPONENT;

END PACKAGE TDIG_E_primitives;

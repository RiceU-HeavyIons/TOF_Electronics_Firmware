LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;

PACKAGE mult_primitives IS

  COMPONENT mux_2in_by_4_bit
    PORT
      (
        data0x : IN  std_logic_vector (3 DOWNTO 0);
        data1x : IN  std_logic_vector (3 DOWNTO 0);
        sel    : IN  std_logic;
        result : OUT std_logic_vector (3 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT PLL_240M_for_signaltap  -- for multiplying 40 mhz clock to use for signaltap
    PORT
      (
        inclk0 : IN  std_logic := '0';
        c0     : OUT std_logic
        );
  END COMPONENT;

  COMPONENT PLL_multiplier_16x
    PORT
      (
        inclk0 : IN  std_logic := '0';
        c0     : OUT std_logic;
        c1     : OUT std_logic
        );
  END COMPONENT;
  
  COMPONENT Mult_VER1 PORT (
    rhic_clk   : IN  std_logic;
    rhic16x    : IN  std_logic;
    reset      : IN  std_logic;
    gate_delay : IN  std_logic_vector(3 DOWNTO 0);
    gate_width : IN  std_logic_vector(3 DOWNTO 0);
    mult_a     : IN  std_logic;
    mult_b     : IN  std_logic;
    mult_c     : IN  std_logic;
    dmult      : IN  std_logic_vector(3 DOWNTO 0);
    -- test_in :                        IN std_logic;                   
    result     : OUT std_logic_vector(3 DOWNTO 0);
    overflow   : OUT std_logic;
    view_gate  : OUT std_logic
    );
  END COMPONENT;

  COMPONENT multiplicity_ver2 PORT (

    rhic_clk   : IN std_logic;
    rhic16x    : IN std_logic;
    reset      : IN std_logic;
    gate_delay : IN std_logic_vector(3 DOWNTO 0);
    gate_width : IN std_logic_vector(3 DOWNTO 0);
    mult_a     : IN std_logic;
    mult_b     : IN std_logic;
    mult_c     : IN std_logic;
    dmult      : IN std_logic_vector(3 DOWNTO 0);
    -- test_in :                        IN std_logic;

    result   : OUT std_logic_vector(3 DOWNTO 0);
    overflow : OUT std_logic;

    view_gate : OUT std_logic
    --  view_gate_start, view_gate_end                  : OUT std_logic;
    -- view_clear_gate, view_clear_end_of_gate          : OUT std_logic;
    -- view_load_width                  : OUT std_logic;
    -- view_delayed_rhic_clk : OUT std_logic_vector(15 downto 0);
    -- view_local_sum                           : OUT std_logic_vector(1 downto 0)              
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

  COMPONENT ctr_4bit
    PORT
      (
        clock  : IN  std_logic;
        cnt_en : IN  std_logic;
        data   : IN  std_logic_vector (3 DOWNTO 0);
        sclr   : IN  std_logic;
        sload  : IN  std_logic;
        cout   : OUT std_logic;
        q      : OUT std_logic_vector (3 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT adder_2by4bit
    PORT
      (
        dataa    : IN  std_logic_vector (3 DOWNTO 0);
        datab    : IN  std_logic_vector (3 DOWNTO 0);
        overflow : OUT std_logic;
        result   : OUT std_logic_vector (3 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT register_4bits
    PORT
      (
        clock : IN  std_logic;
        data  : IN  std_logic_vector (3 DOWNTO 0);
        sclr  : IN  std_logic;
        q     : OUT std_logic_vector (3 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT MUX_16TO1
    PORT
      (
        data0  : IN  std_logic;
        data1  : IN  std_logic;
        data10 : IN  std_logic;
        data11 : IN  std_logic;
        data12 : IN  std_logic;
        data13 : IN  std_logic;
        data14 : IN  std_logic;
        data15 : IN  std_logic;
        data2  : IN  std_logic;
        data3  : IN  std_logic;
        data4  : IN  std_logic;
        data5  : IN  std_logic;
        data6  : IN  std_logic;
        data7  : IN  std_logic;
        data8  : IN  std_logic;
        data9  : IN  std_logic;
        sel    : IN  std_logic_vector (3 DOWNTO 0);
        result : OUT std_logic
        );
  END COMPONENT;

  COMPONENT MUX_6TO1
    PORT
      (
        data0  : IN  std_logic;
        data1  : IN  std_logic;
        data2  : IN  std_logic;
        data3  : IN  std_logic;
        data4  : IN  std_logic;
        data5  : IN  std_logic;
        sel    : IN  std_logic_vector (2 DOWNTO 0);
        result : OUT std_logic
        );
  END COMPONENT;

  COMPONENT SHIFT_REG_16BITS
    PORT
      (
        aclr    : IN  std_logic;
        clock   : IN  std_logic;
        shiftin : IN  std_logic;
        q       : OUT std_logic_vector (15 DOWNTO 0)
        );
  END COMPONENT;

  COMPONENT SHIFT_REG_5BITS
    PORT
      (
        aclr    : IN  std_logic;
        clock   : IN  std_logic;
        shiftin : IN  std_logic;
        q       : OUT std_logic_vector (4 DOWNTO 0)
        );
  END COMPONENT;
  COMPONENT gate_ctl
    PORT
      (
        CLK, DELAY_TC, RESET, RHIC_CLK, WIDTH_TC, rhic_edge_pulse, no_delay : IN  std_logic;
        DELAY_ENABLE, LOAD_CTRS, RESET_EDGE_FFS, WIDTH_ENABLE               : OUT std_logic
        );      
  END COMPONENT;

  COMPONENT adder_3by1bit
    PORT
      (
        data0x : IN  std_logic_vector (0 DOWNTO 0);
        data1x : IN  std_logic_vector (0 DOWNTO 0);
        data2x : IN  std_logic_vector (0 DOWNTO 0);
        result : OUT std_logic_vector (1 DOWNTO 0)
        );
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
END PACKAGE mult_primitives;

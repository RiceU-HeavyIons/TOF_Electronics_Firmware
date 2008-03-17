-- multiplicity_ver2.vhd

-- ********************************************************************
-- LIBRARY DEFINITIONS
-- ********************************************************************     

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
USE work.mult_primitives.ALL;

ENTITY multiplicity_ver2 IS
  PORT (

    rhic_clk   : IN  std_logic;
    rhic16x    : IN  std_logic;
    reset      : IN  std_logic;
    gate_delay : IN  std_logic_vector(3 DOWNTO 0);
    gate_width : IN  std_logic_vector(3 DOWNTO 0);
    mult_a     : IN  std_logic;
    mult_b     : IN  std_logic;
    mult_c     : IN  std_logic;
    dmult      : IN  std_logic_vector(3 DOWNTO 0);
    result     : OUT std_logic_vector(3 DOWNTO 0);
    overflow   : OUT std_logic;
    view_gate  : OUT std_logic
--    view_gate_start, view_gate_end : OUT std_logic;
--    view_clear_gate, view_clear_end_of_gate   : OUT std_logic;
--    view_load_width                           : OUT std_logic;
--    view_delayed_rhic_clk                     : OUT std_logic_vector(15 DOWNTO 0);
--    view_local_sum                            : OUT std_logic_vector(1 DOWNTO 0)
    );

END multiplicity_ver2;

ARCHITECTURE ver_zero OF multiplicity_ver2 IS

  
  SIGNAL a_in_valid, b_in_valid, c_in_valid : std_logic;

  SIGNAL delay_enable       : std_logic;
  SIGNAL width_enable       : std_logic;
  SIGNAL load_ctrs          : std_logic;
  SIGNAL delay_tc, width_tc : std_logic;
  SIGNAL width_cnt          : std_logic_vector(3 DOWNTO 0);
  SIGNAL local_mult         : std_logic_vector(3 DOWNTO 0);


  SIGNAL delayed_rhic_clk             : std_logic_vector(15 DOWNTO 0);
  SIGNAL gate_start, gate_end         : std_logic;
  SIGNAL clear_gate, gate, clear_data : std_logic;
  SIGNAL clear_end_of_gate            : std_logic;
  SIGNAL local_sum                    : std_logic_vector(1 DOWNTO 0);

  
BEGIN

  view_gate <= gate;

--  view_delayed_rhic_clk  <= delayed_rhic_clk;
--  view_gate_start        <= gate_start;
--  view_gate_end          <= gate_end;
--  view_clear_gate        <= clear_gate;
--  view_clear_end_of_gate <= clear_end_of_gate;


--  view_local_sum        <= local_sum;
--  view_delayed_rhic_clk <= delayed_rhic_clk;

  -- ********************************************************
  -- create gate for data capture
  -- ********************************************************
  
  SHIFT_REG_16BITS_inst : SHIFT_REG_16BITS PORT MAP (
    aclr    => '0',
    clock   => rhic16x,
    shiftin => rhic_clk,
    q       => delayed_rhic_clk
    );

  begin_gate_select : MUX_16TO1 PORT MAP (
    data0  => delayed_rhic_clk(15),
    data1  => delayed_rhic_clk(14),
    data2  => delayed_rhic_clk(13),
    data3  => delayed_rhic_clk(12),
    data4  => delayed_rhic_clk(11),
    data5  => delayed_rhic_clk(10),
    data6  => delayed_rhic_clk(9),
    data7  => delayed_rhic_clk(8),
    data8  => delayed_rhic_clk(7),
    data9  => delayed_rhic_clk(6),
    data10 => delayed_rhic_clk(5),
    data11 => delayed_rhic_clk(4),
    data12 => delayed_rhic_clk(3),
    data13 => delayed_rhic_clk(2),
    data14 => delayed_rhic_clk(1),
    data15 => delayed_rhic_clk(0),
    sel    => gate_delay,
    result => gate_start
    );

  -- select end_gate with 'gate_delay' + 'gate_width'
  
  end_gate_select : MUX_16TO1 PORT MAP (
    data0  => delayed_rhic_clk(15),
    data1  => delayed_rhic_clk(14),
    data2  => delayed_rhic_clk(13),
    data3  => delayed_rhic_clk(12),
    data4  => delayed_rhic_clk(11),
    data5  => delayed_rhic_clk(10),
    data6  => delayed_rhic_clk(9),
    data7  => delayed_rhic_clk(8),
    data8  => delayed_rhic_clk(7),
    data9  => delayed_rhic_clk(6),
    data10 => delayed_rhic_clk(5),
    data11 => delayed_rhic_clk(4),
    data12 => delayed_rhic_clk(3),
    data13 => delayed_rhic_clk(2),
    data14 => delayed_rhic_clk(1),
    data15 => delayed_rhic_clk(0),
    sel    => gate_width,
    result => gate_end
    );

  -- set gate DFF with 'gate_start' and clear with 'gate_end'
  
  gate_flip_flop : DFLOP PORT MAP (
    aclr  => clear_gate,
    clock => gate_start,
    data  => '1',
    sclr  => reset,
    q     => gate);

  end_of_gate : DFLOP PORT MAP (
    aclr  => NOT gate,
    clock => gate_end,
    data  => '1',
    sclr  => reset,
    q     => clear_gate);

  clr_end_of_gate : DFLOP PORT MAP (
    aclr  => '0',
    clock => rhic16x,
    data  => clear_gate,
    sclr  => reset,
    q     => clear_end_of_gate);                

  -- ********************************************************
  -- capture data
  -- ********************************************************

  clear_data <= NOT gate;
  
  capture_multa_edge : DFLOP PORT MAP (
    aclr  => clear_data,
    clock => mult_a,
    data  => '1',
    sclr  => reset,
    q     => a_in_valid);

  capture_multb_edge : DFLOP PORT MAP (
    aclr  => clear_data,
    clock => mult_b,
    data  => '1',
    sclr  => reset,
    q     => b_in_valid);       

  capture_multc_edge : DFLOP PORT MAP (
    aclr  => clear_data,
    clock => mult_c,
    data  => '1',
    sclr  => reset,
    q     => c_in_valid);       

  edge_capture_register : register_4bits PORT MAP (
    clock   => NOT gate,
    data(3) => '0',                     -- test_input,  not used
    data(2) => c_in_valid,
    data(1) => b_in_valid,
    data(0) => a_in_valid,
    sclr    => reset,
    q       => local_mult               -- msb is a test signal
    );

  -- ********************************************************
  -- create multiplicity sum
  -- ********************************************************
  
  add_3_local_bits_in_parallel : adder_3by1bit PORT MAP (
    data0x => local_mult(0 DOWNTO 0),
    data1x => local_mult(1 DOWNTO 1),
    data2x => local_mult(2 DOWNTO 2),
    result => local_sum
    );

  add_local_and_ds_mult : adder_2by4bit PORT MAP (
    dataa(1 DOWNTO 0) => local_sum,
    dataa(3 DOWNTO 2) => "00",
    datab             => dmult,
    overflow          => overflow,
    result            => result
    );

END ARCHITECTURE ver_zero;



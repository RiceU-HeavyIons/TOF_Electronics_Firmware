-- $Id: MCU_IF.VHD,v 1.1.1.1 2008-02-12 21:01:52 jschamba Exp $
-- mcu_if.vhd

-- ********************************************************************
-- LIBRARY DEFINITIONS
-- ********************************************************************     

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
USE work.TDIG_D_primitives.ALL;

ENTITY mcu_if IS
  PORT (clock               : IN    std_logic;
        reset               : IN    std_logic;
        read_writeb         : IN    std_logic;
        strobe              : IN    std_logic;
        mcu_adr             : IN    std_logic_vector(3 DOWNTO 0);
        mcu_data            : INOUT std_logic_vector(7 DOWNTO 0);
        peek_at_output_data : OUT   std_logic_vector(7 DOWNTO 0);
        peek_at_input_data  : OUT   std_logic_vector(7 DOWNTO 0);
        pk_endat_to_mcu     : OUT   std_logic;
        pk_endat_from_mcu   : OUT   std_logic
        );
END mcu_if;

ARCHITECTURE one OF mcu_if IS

  SIGNAL bidir_data_bus, input_data, output_data         : std_logic_vector(7 DOWNTO 0);
  SIGNAL write0_data, write1_data, write2_data           : std_logic_vector(7 DOWNTO 0);
  SIGNAL output_sel                                      : std_logic_vector(3 DOWNTO 0);
  SIGNAL adr_equ                                         : std_logic_vector(15 DOWNTO 0);
  SIGNAL enable_data_out_to_mcu, enable_data_in_from_mcu : std_logic;
  SIGNAL write0_enable, write1_enable, write2_enable     : std_logic;

  CONSTANT zero_byte : std_logic_vector := x"00";
  
BEGIN

  -- test signal
  peek_at_input_data  <= input_data;
  peek_at_output_data <= output_data;
  pk_endat_to_mcu     <= enable_data_out_to_mcu;
  pk_endat_from_mcu   <= enable_data_in_from_mcu;

  enable_data_out_to_mcu <= (strobe) AND (read_writeb);

  enable_data_in_from_mcu <= (strobe) AND (NOT (read_writeb));
  
  bus_buffer : bidir_buffer_8bit PORT MAP (
    data     => output_data,
    enabledt => enable_data_out_to_mcu,
    enabletr => enable_data_in_from_mcu,
    result   => input_data,
    tridata  => mcu_data
    );

  decoder_4to16_inst : decoder_4to16 PORT MAP (
    data   => mcu_adr,
    enable => '1',
    eq0    => adr_equ(0),
    eq1    => adr_equ(1),
    eq2    => adr_equ(2),
    eq3    => adr_equ(3),
    eq4    => adr_equ(4),
    eq5    => adr_equ(5),
    eq6    => adr_equ(6),
    eq7    => adr_equ(7),
    eq8    => adr_equ(8),
    eq9    => adr_equ(9),
    eq10   => adr_equ(10),
    eq11   => adr_equ(11),
    eq12   => adr_equ(12),
    eq13   => adr_equ(13),
    eq14   => adr_equ(14),
    eq15   => adr_equ(15)
    );

  write0_enable <= NOT read_writeb AND adr_equ(0);
  write1_enable <= NOT read_writeb AND adr_equ(1);
  write2_enable <= NOT read_writeb AND adr_equ(2);
  
  write0_configuration_register : reg_8bit PORT MAP (
    clock  => clock,
    data   => input_data,
    enable => write0_enable,
    sclr   => reset,
    q      => write0_data);

  write1_configuration_register : reg_8bit PORT MAP (
    clock  => clock,
    data   => input_data,
    enable => write1_enable,
    sclr   => reset,
    q      => write1_data);

  write2_configuration_register : reg_8bit PORT MAP (
    clock  => clock,
    data   => input_data,
    enable => write2_enable,
    sclr   => reset,
    q      => write2_data);

  mux_8bits_16inputs_inst : mux_8bits_16inputs PORT MAP (
    data0x  => write0_data,
    data1x  => write1_data,
    data2x  => write2_data,
    data3x  => zero_byte,
    data4x  => zero_byte,
    data5x  => zero_byte,
    data6x  => zero_byte,
    data7x  => zero_byte,
    data8x  => zero_byte,
    data9x  => zero_byte,
    data10x => zero_byte,
    data11x => zero_byte,
    data12x => zero_byte,
    data13x => zero_byte,
    data14x => zero_byte,
    data15x => zero_byte,
    sel     => output_sel,
    result  => output_data
    );

END one;

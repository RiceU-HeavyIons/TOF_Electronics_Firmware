--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: internal_memory.vhd,v 1.1.1.1 2004-12-03 19:29:46 tofp Exp $
--******************************************************************************
--*  INTERNAL_MEMORY.VHD
--*
--*
--*  REVISION HISTORY:
--*    11-Oct-2001 CS  Original coding
--*    31-Oct-2002 CS  Interface has been revised
--*                    Memory is going to be written and read using user defined
--*                    block write and read, respectively.
--*
--******************************************************************************

library ieee;
use ieee.std_logic_1164.all;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity internal_memory is
  port (
    clock       : in  std_logic;
    arstn       : in  std_logic;
    block_read  : in  std_logic;
    block_write : in  std_logic;
    tid         : in  std_logic_vector (3 downto 0);
    datai       : in  std_logic_vector (31 downto 0);
    datai_valid : in  std_logic;
    suspend     : in  std_logic;
    datao       : out std_logic_vector (32 downto 0);
    datao_valid : out std_logic
  );
end internal_memory;

library ieee;
use ieee.std_logic_1164.all;

library lpm;
use lpm.lpm_components.all;

use work.my_conversions.all;
use work.my_utilities.all;

architecture SYN of internal_memory is

  constant LENGTH512 : std_logic_vector := "0000000001000000000";

  type write_state is (
    WRSTOP,
    WRINIT,
    WRDATA);

  type read_state is (
    RDSTOP,
    RDINIT,
    RDFETCH,
    RDDATA,
    RDIDLE,
    RDCLOSE,
    RDEND);

  signal s_im_address : std_logic_vector (8 downto 0);
  signal s_im_we      : std_logic;
  signal s_im_outenab : std_logic;
  signal s_im_dio     : std_logic_vector (31 downto 0);
  signal s_im_din     : std_logic_vector (31 downto 0);
  signal s_im_dout    : std_logic_vector (31 downto 0);

begin

  s_im_we  <= datai_valid and block_write;
  s_im_din <= datai;

	altsyncram_component : altsyncram
	GENERIC MAP (
		operation_mode => "SINGLE_PORT",
		width_a => 32,
		widthad_a => 9,
		numwords_a => 512,
		lpm_type => "altsyncram",
		width_byteena_a => 1,
		outdata_reg_a => "UNREGISTERED",
		outdata_aclr_a => "NONE",
		indata_aclr_a => "NONE",
		wrcontrol_aclr_a => "NONE",
		address_aclr_a => "NONE",
		read_during_write_mode_mixed_ports => "DONT_CARE",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		intended_device_family => "Stratix"
	)
	PORT MAP (
		wren_a => s_im_we,
		clock0 => clock,
		address_a => s_im_address,
		data_a => s_im_din,
		q_a => s_im_dout
	);

  main : process (clock, arstn)
    variable address_counter : std_logic_vector (8 downto 0);
    variable word_counter    : std_logic_vector (19 downto 0);
    variable block_end       : std_logic;
    variable write_present   : write_state;
    variable write_next      : write_state;
    variable read_present    : read_state;
    variable read_next       : read_state;
    variable write_enable    : std_logic;
    variable read_enable     : std_logic;
  begin
    if (arstn = '0') then
      s_im_address <= (others => '0');
      datao_valid  <= '0';
      datao        <= (others => '0');

      address_counter := (others => '0');
      word_counter    := (others => '0');
      block_end       := '0';
      write_present   := WRSTOP;
      write_next      := WRSTOP;
      read_present    := RDSTOP;
      read_next       := RDSTOP;
      write_enable    := '0';
      read_enable     := '0';
    elsif (clock'event and clock = '1') then
      write_enable := datai_valid;
      if (write_present = WRINIT) or (read_present = RDINIT) then
        address_counter := (others => '0');
      elsif (write_enable = '1') or
            ((read_enable = '1') and (suspend = '0')) then
        address_counter := inc(address_counter);
      end if;
      s_im_address <= address_counter;

      case write_present is
        when WRSTOP =>
          if (block_write = '1') then
            write_next := WRINIT;
          else
            write_next := WRSTOP;
          end if;
        when WRINIT =>
          write_next := WRDATA;
        when WRDATA =>
          if (block_write = '0') then
            write_next := WRSTOP;
          else
            write_next := WRDATA;
          end if;
      end case;
      write_present := write_next;

      if (read_present = RDCLOSE) then
        datao     <= "10" & LENGTH512 & tid & "01100100";
      else
        datao     <=  '0' & s_im_dout;
      end if;

      block_end := word_counter(19);
      case read_present is
        when RDSTOP  =>
          word_counter := '0' & LENGTH512;
          datao_valid <= '0';
          read_enable := '0';
          if (block_read = '1') then
            read_next := RDINIT;
          else
            read_next := RDSTOP;
          end if;
        when RDINIT =>
          word_counter := dec(word_counter);
          datao_valid <= '0';
          read_enable := '1';
          read_next := RDFETCH;
        when RDFETCH =>
          word_counter := dec(word_counter);
          datao_valid <= '0';
          read_enable := '1';
          if (suspend = '0') then
            read_next := RDDATA;
          else
            read_next := RDIDLE;
          end if;
        when RDIDLE  =>
          datao_valid <= '0';
          read_enable := '1';
          if (suspend = '0') then
            read_next := RDDATA;
          else
            read_next := RDIDLE;
          end if;
        when RDDATA  =>
          word_counter := dec(word_counter);
          datao_valid <= '1';
          read_enable := '1';
          if (block_end = '1') then
            read_next := RDCLOSE;
          elsif (suspend = '1') then
            read_next := RDIDLE;
          else
            read_next := RDDATA;
          end if;
        when RDCLOSE =>
          datao_valid <= '1';
          read_enable := '1';
          read_next := RDEND;
        when RDEND =>
          datao_valid <= '0';
          read_enable := '0';
          if block_read = '0' then
            read_next := RDSTOP;
          else
            read_next := RDEND;
          end if;
      end case;
      read_present := read_next;

    end if;
  end process;      

end SYN;

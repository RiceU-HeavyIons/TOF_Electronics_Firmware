--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: internal_memory.vhd,v 1.3 2006-03-29 18:56:07 jschamba Exp $
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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;

ENTITY internal_memory IS
  PORT (
    clock       : IN  std_logic;
    arstn       : IN  std_logic;
    block_read  : IN  std_logic;
    block_write : IN  std_logic;
    tid         : IN  std_logic_vector (3 DOWNTO 0);
    datai       : IN  std_logic_vector (31 DOWNTO 0);
    datai_valid : IN  std_logic;
    suspend     : IN  std_logic;
    datao       : OUT std_logic_vector (32 DOWNTO 0);
    datao_valid : OUT std_logic
    );
END internal_memory;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY lpm;
USE lpm.lpm_components.ALL;

USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

ARCHITECTURE SYN OF internal_memory IS

  CONSTANT LENGTH512 : std_logic_vector := "0000000001000000000";

  TYPE write_state IS (
    WRSTOP,
    WRINIT,
    WRDATA);

  TYPE read_state IS (
    RDSTOP,
    RDINIT,
    RDFETCH,
    RDDATA,
    RDIDLE,
    RDCLOSE,
    RDEND);

  SIGNAL s_im_address : std_logic_vector (8 DOWNTO 0);
  SIGNAL s_im_we      : std_logic;
  SIGNAL s_im_din     : std_logic_vector (31 DOWNTO 0);
  SIGNAL s_im_dout    : std_logic_vector (31 DOWNTO 0);

BEGIN

  s_im_we  <= datai_valid AND block_write;
  s_im_din <= datai;

  altsyncram_component : altsyncram
    GENERIC MAP (
      operation_mode                     => "SINGLE_PORT",
      width_a                            => 32,
      widthad_a                          => 9,
      numwords_a                         => 512,
      lpm_type                           => "altsyncram",
      width_byteena_a                    => 1,
      outdata_reg_a                      => "UNREGISTERED",
      outdata_aclr_a                     => "NONE",
      indata_aclr_a                      => "NONE",
      wrcontrol_aclr_a                   => "NONE",
      address_aclr_a                     => "NONE",
      read_during_write_mode_mixed_ports => "DONT_CARE",
      lpm_hint                           => "ENABLE_RUNTIME_MOD=NO",
      intended_device_family             => "Stratix"
      )
    PORT MAP (
      wren_a    => s_im_we,
      clock0    => clock,
      address_a => s_im_address,
      data_a    => s_im_din,
      q_a       => s_im_dout
      );

  main : PROCESS (clock, arstn)
    VARIABLE address_counter : std_logic_vector (8 DOWNTO 0);
    VARIABLE word_counter    : std_logic_vector (19 DOWNTO 0);
    VARIABLE block_end       : std_logic;
    VARIABLE write_present   : write_state;
    VARIABLE write_next      : write_state;
    VARIABLE read_present    : read_state;
    VARIABLE read_next       : read_state;
    VARIABLE write_enable    : std_logic;
    VARIABLE read_enable     : std_logic;
  BEGIN
    IF (arstn = '0') THEN
      s_im_address <= (OTHERS => '0');
      datao_valid  <= '0';
      datao        <= (OTHERS => '0');

      address_counter := (OTHERS => '0');
      word_counter    := (OTHERS => '0');
      block_end       := '0';
      write_present   := WRSTOP;
      write_next      := WRSTOP;
      read_present    := RDSTOP;
      read_next       := RDSTOP;
      write_enable    := '0';
      read_enable     := '0';
    ELSIF (clock'event AND clock = '1') THEN
      write_enable := datai_valid;
      IF (write_present = WRINIT) OR (read_present = RDINIT) THEN
        address_counter := (OTHERS => '0');
      ELSIF (write_enable = '1') OR
        ((read_enable = '1') AND (suspend = '0')) THEN
        address_counter := inc(address_counter);
      END IF;
      s_im_address <= address_counter;

      CASE write_present IS
        WHEN WRSTOP =>
          IF (block_write = '1') THEN
            write_next := WRINIT;
          ELSE
            write_next := WRSTOP;
          END IF;
        WHEN WRINIT =>
          write_next := WRDATA;
        WHEN WRDATA =>
          IF (block_write = '0') THEN
            write_next := WRSTOP;
          ELSE
            write_next := WRDATA;
          END IF;
      END CASE;
      write_present := write_next;

      IF (read_present = RDCLOSE) THEN
        datao <= "10" & LENGTH512 & tid & "01100100";
      ELSE
        datao <= '0' & s_im_dout;
      END IF;

      block_end := word_counter(19);
      CASE read_present IS
        WHEN RDSTOP =>
          word_counter := '0' & LENGTH512;
          datao_valid  <= '0';
          read_enable  := '0';
          IF (block_read = '1') THEN
            read_next := RDINIT;
          ELSE
            read_next := RDSTOP;
          END IF;
        WHEN RDINIT =>
          word_counter := dec(word_counter);
          datao_valid  <= '0';
          read_enable  := '1';
          read_next    := RDFETCH;
        WHEN RDFETCH =>
          word_counter := dec(word_counter);
          datao_valid  <= '0';
          read_enable  := '1';
          IF (suspend = '0') THEN
            read_next := RDDATA;
          ELSE
            read_next := RDIDLE;
          END IF;
        WHEN RDIDLE =>
          datao_valid <= '0';
          read_enable := '1';
          IF (suspend = '0') THEN
            read_next := RDDATA;
          ELSE
            read_next := RDIDLE;
          END IF;
        WHEN RDDATA =>
          word_counter := dec(word_counter);
          datao_valid  <= '1';
          read_enable  := '1';
          IF (block_end = '1') THEN
            read_next := RDCLOSE;
          ELSIF (suspend = '1') THEN
            read_next := RDIDLE;
          ELSE
            read_next := RDDATA;
          END IF;
        WHEN RDCLOSE =>
          datao_valid <= '1';
          read_enable := '1';
          read_next   := RDEND;
        WHEN RDEND =>
          datao_valid <= '0';
          read_enable := '0';
          IF block_read = '0' THEN
            read_next := RDSTOP;
          ELSE
            read_next := RDEND;
          END IF;
      END CASE;
      read_present := read_next;

    END IF;
  END PROCESS;

END SYN;

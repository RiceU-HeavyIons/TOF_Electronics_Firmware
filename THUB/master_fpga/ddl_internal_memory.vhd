--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: ddl_internal_memory.vhd,v 1.4 2011-03-02 17:59:47 jschamba Exp $
--******************************************************************************
--*  DDL_INTERNAL_MEMORY.VHD
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
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

ENTITY ddl_internal_memory IS
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
END ddl_internal_memory;


ARCHITECTURE SYN OF ddl_internal_memory IS

  -- CONSTANT LENGTH512 : std_logic_vector := "0000000001000000000";

  TYPE write_state IS (
    WRSTOP,
    WRINIT,
    WRDATA);

  TYPE read_state IS (
    RDSTOP,
    RDINIT,
    RDFETCH,
    RDIDLE,
    RDCLOSE,
    RDEND);

BEGIN

  main : PROCESS (clock, arstn)
    VARIABLE write_present : write_state;
    VARIABLE write_next    : write_state;
    VARIABLE read_present  : read_state;
    VARIABLE read_next     : read_state;
  BEGIN
    IF (arstn = '0') THEN
      datao_valid <= '0';
      datao       <= (OTHERS => '0');

      write_present := WRSTOP;
      write_next    := WRSTOP;
      read_present  := RDSTOP;
      read_next     := RDSTOP;
    ELSIF rising_edge(clock) THEN

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
        datao <= "100000000000000000000" & tid & "01100100";
      ELSE
        datao <= (OTHERS => '0');
      END IF;

      CASE read_present IS
        WHEN RDSTOP =>
          datao_valid <= '0';
          IF (block_read = '1') THEN
            read_next := RDINIT;
          ELSE
            read_next := RDSTOP;
          END IF;
        WHEN RDINIT =>
          datao_valid <= '0';
          read_next   := RDFETCH;
        WHEN RDFETCH =>
          datao_valid <= '0';
          IF (suspend = '0') THEN
            read_next := RDCLOSE;
          ELSE
            read_next := RDIDLE;
          END IF;
        WHEN RDIDLE =>
          datao_valid <= '0';
          IF (suspend = '0') THEN
            read_next := RDCLOSE;
          ELSE
            read_next := RDIDLE;
          END IF;
        WHEN RDCLOSE =>
          datao_valid <= '1';
          read_next   := RDEND;
        WHEN RDEND =>
          datao_valid <= '0';
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

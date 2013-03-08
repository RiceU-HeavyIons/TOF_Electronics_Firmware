-- $Id: pattern_generator.vhd,v 1.3 2004-12-08 22:52:28 tofp Exp $
--*************************************************************************
--*  PATTERN_GENERATOR.VHD : Pattern generator module.
--*
--*
--*  REVISION HISTORY:
--*    26-Apr-2001 CS  Original coding
--*    24-Oct-2001 CS  Length input was replaced with bl_reg
--*                    Pattern input was replaced with ps_reg
--*    22-Mar-2002 CS  Pattern codes are changed to match with pRORC params
--*    24-Apr-2002 CS  Event ID counter is implemented
--*     2-May-2002 CS  Counter control has been changed
--*     3-May-2002 CS  Random length generation
--*
--*************************************************************************


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY pattern_generator IS
  PORT (
    clock       : IN  std_logic;
    arstn       : IN  std_logic;
    ps_reg      : IN  std_logic_vector ( 7 DOWNTO 0);
    bl_reg      : IN  std_logic_vector ( 7 DOWNTO 0);
    xx_reg      : IN  std_logic_vector ( 7 DOWNTO 0);
    tid         : IN  std_logic_vector ( 3 DOWNTO 0);
    enable      : IN  std_logic;
    suspend     : IN  std_logic;
    reset_evid  : IN  std_logic;
    fifo_q      : IN  std_logic_vector (31 DOWNTO 0);
    fifo_empty  : IN  std_logic;
    fifo_rdreq  : OUT std_logic;
    datao       : OUT std_logic_vector (32 DOWNTO 0);
    datao_valid : OUT std_logic);
END pattern_generator;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

ARCHITECTURE SYN OF pattern_generator IS

  CONSTANT FIFO_OUT  : std_logic_vector := "001";
  CONSTANT ALTER_0F  : std_logic_vector := "010";
  CONSTANT FLYING_0  : std_logic_vector := "011";
  CONSTANT FLYING_1  : std_logic_vector := "100";
  CONSTANT INCREMENT : std_logic_vector := "101";
  CONSTANT DECREMENT : std_logic_vector := "110";

  CONSTANT FESTWEOB : std_logic_vector := "01100100";

  TYPE pg_state IS (
    IDLE,
    INITPG1,
    TXEVID,
    TXDATA,
    TXIDLE,
    TXDTSW,
    WAITGAP
    );

  SIGNAL s_suspend : std_logic;

BEGIN

  s_suspend <= (suspend OR fifo_empty) WHEN (ps_reg(2 DOWNTO 0) = FIFO_OUT) ELSE suspend;

  main : PROCESS (clock, arstn)
    VARIABLE pg_present : pg_state;
    VARIABLE pg_next    : pg_state;

    VARIABLE pgdata         : std_logic_vector (31 DOWNTO 0);
    VARIABLE dtstw          : std_logic_vector (31 DOWNTO 0);
    VARIABLE shift_reg      : std_logic_vector (31 DOWNTO 0);
    VARIABLE shiftrg_init   : boolean;
    VARIABLE shiftrg_enable : boolean;
    VARIABLE counter_reg    : std_logic_vector (31 DOWNTO 0);
    VARIABLE counter_init   : boolean;
    VARIABLE counter_enable : boolean;
    VARIABLE alternate_reg  : std_logic_vector (31 DOWNTO 0);
    VARIABLE alterrg_init   : boolean;
    VARIABLE alterrg_enable : boolean;
    VARIABLE actual_length  : std_logic_vector (18 DOWNTO 0);
    VARIABLE fixed_length   : std_logic_vector (18 DOWNTO 0);
    VARIABLE rand_length    : std_logic_vector (18 DOWNTO 0);
    VARIABLE rand_mask      : std_logic_vector (18 DOWNTO 0);
    VARIABLE rand_msb       : std_logic;
    VARIABLE random_data    : std_logic_vector (31 DOWNTO 0);
    VARIABLE event_id       : std_logic_vector (31 DOWNTO 0);
    VARIABLE word_counter   : std_logic_vector (19 DOWNTO 0);
    VARIABLE block_counter  : std_logic_vector (18 DOWNTO 0);
    VARIABLE block_end      : std_logic;

  BEGIN

    IF (arstn = '0') THEN

      datao       <= (OTHERS => '0');
      datao_valid <= '0';
      fifo_rdreq  <= '0';

      pg_present     := IDLE;
      pg_next        := IDLE;
      pgdata         := (OTHERS => '0');
      shift_reg      := (OTHERS => '0');
      shiftrg_init   := false;
      shiftrg_enable := false;
      counter_reg    := (OTHERS => '0');
      counter_init   := false;
      counter_enable := false;
      alternate_reg  := (OTHERS => '0');
      alterrg_init   := false;
      alterrg_enable := false;
      actual_length  := (6      => '1', OTHERS => '0');
      fixed_length   := (6      => '1', OTHERS => '0');
      rand_length    := (OTHERS => '1');
      rand_mask      := int2slv(63, 19);
      rand_msb       := '1';
      random_data    := (OTHERS => '0');
      event_id       := (0      => '1', OTHERS => '0');
      word_counter   := (OTHERS => '0');
      block_counter  := (0      => '1', OTHERS => '0');
      block_end      := '0';

    ELSIF (clock'event AND clock = '1') THEN


      IF (ps_reg(2 DOWNTO 0) = FIFO_OUT) THEN
        block_end := bool2sl( fifo_q(31 DOWNTO 24) = X"EA");
      ELSE
        block_end := word_counter(19);
      END IF;

      IF (pg_present = IDLE OR pg_present = TXDTSW) THEN
        word_counter := ('0' & actual_length);
      ELSIF (pg_present = TXIDLE) THEN
        word_counter := word_counter;
      ELSE
        word_counter := dec(word_counter);
      END IF;

      IF (bl_reg(4) = '0') THEN
        actual_length := fixed_length;
      ELSE
        actual_length := rand_length AND rand_mask;
      END IF;

      IF (reset_evid = '1') THEN
        rand_length := "10000000000" & xx_reg;
      ELSIF (pg_present = INITPG1) THEN
        rand_msb        := rand_length(18);
        rand_length(18) := rand_length(17);
        rand_length(17) := rand_length(16);
        rand_length(16) := rand_length(15);
        rand_length(15) := rand_length(14);
        rand_length(14) := rand_length(13);
        rand_length(13) := rand_length(12);
        rand_length(12) := rand_length(11);
        rand_length(11) := rand_length(10);
        rand_length(10) := rand_length(9);
        rand_length(9)  := rand_length(8);
        rand_length(8)  := rand_length(7);
        rand_length(7)  := rand_length(6);
        rand_length(6)  := rand_length(5);
        rand_length(5)  := rand_length(4) XOR rand_msb;
        rand_length(4)  := rand_length(3);
        rand_length(3)  := rand_length(2);
        rand_length(2)  := rand_length(1) XOR rand_msb;
        rand_length(1)  := rand_length(0) XOR rand_msb;
        rand_length(0)  := rand_msb;
      END IF;

      CASE bl_reg(3 DOWNTO 0) IS
        WHEN "0001" =>
          fixed_length := int2slv(15, 19);
          rand_mask    := int2slv(15, 19);
        WHEN "0010" =>
          fixed_length := int2slv(31, 19);
          rand_mask    := int2slv(31, 19);
        WHEN "0011" =>
          fixed_length := int2slv(63, 19);
          rand_mask    := int2slv(63, 19);
        WHEN "0100" =>
          fixed_length := int2slv(127, 19);
          rand_mask    := int2slv(127, 19);
        WHEN "0101" =>
          fixed_length := int2slv(255, 19);
          rand_mask    := int2slv(255, 19);
        WHEN "0110" =>
          fixed_length := int2slv(511, 19);
          rand_mask    := int2slv(511, 19);
        WHEN "0111" =>
          fixed_length := int2slv(1023, 19);
          rand_mask    := int2slv(1023, 19);
        WHEN "1000" =>
          fixed_length := int2slv(2047, 19);
          rand_mask    := int2slv(2047, 19);
        WHEN "1001" =>
          fixed_length := int2slv(4095, 19);
          rand_mask    := int2slv(4095, 19);
        WHEN "1010" =>
          fixed_length := int2slv(8191, 19);
          rand_mask    := int2slv(8191, 19);
        WHEN "1011" =>
          fixed_length := int2slv(16383, 19);
          rand_mask    := int2slv(16383, 19);
        WHEN "1100" =>
          fixed_length := int2slv(32767, 19);
          rand_mask    := int2slv(32767, 19);
        WHEN "1101" =>
          fixed_length := int2slv(65535, 19);
          rand_mask    := int2slv(65535, 19);
        WHEN "1110" =>
          fixed_length := int2slv(131071, 19);
          rand_mask    := int2slv(131071, 19);
        WHEN "1111" =>
          fixed_length := int2slv(262143, 19);
          rand_mask    := int2slv(262143, 19);
        WHEN OTHERS =>
          fixed_length := int2slv(15, 19);
          rand_mask    := int2slv(15, 19);
      END CASE;

      CASE ps_reg(2 DOWNTO 0) IS
        WHEN FIFO_OUT =>
          pgdata := fifo_q;
        WHEN ALTER_0F =>
          pgdata := alternate_reg;
        WHEN FLYING_0 =>
          pgdata := shift_reg;
        WHEN FLYING_1 =>
          pgdata := shift_reg;
        WHEN INCREMENT =>
          pgdata := counter_reg;
        WHEN DECREMENT =>
          pgdata := counter_reg;
        WHEN OTHERS =>
          pgdata := counter_reg;
      END CASE;

      IF (counter_init) THEN
        counter_reg := (OTHERS => '0');
      ELSIF (counter_enable) THEN
        IF (ps_reg(2 DOWNTO 0) = DECREMENT) THEN
          counter_reg := dec(counter_reg);
        ELSE
          counter_reg := inc(counter_reg);
        END IF;
      END IF;

      IF (shiftrg_init) THEN
        IF (ps_reg(2 DOWNTO 0) = FLYING_1) THEN
          shift_reg := ( 0 => '1', OTHERS => '0' );
        ELSE
          shift_reg := ( 0 => '0', OTHERS => '1' );
        END IF;
      ELSIF (shiftrg_enable) THEN
        shift_reg := (shift_reg(30 DOWNTO 0) & shift_reg(31));
      END IF;

      IF (alterrg_init) THEN
        alternate_reg := (OTHERS => '0');
      ELSIF (alterrg_enable) THEN
        alternate_reg := NOT alternate_reg;
      END IF;

      CASE pg_present IS
        WHEN IDLE =>
          datao       <= ('0' & pgdata);
          datao_valid <= '0';
        WHEN INITPG1 =>
          datao       <= ('0' & pgdata);
          datao_valid <= '0';
        WHEN TXEVID =>
          datao       <= ('0' & event_id);
          datao_valid <= '1';
        WHEN TXDATA =>
          datao <= ('0' & pgdata);
          IF (ps_reg(2 DOWNTO 0) = FIFO_OUT) THEN
            datao_valid <= NOT fifo_empty;
          ELSE
            datao_valid <= '1';
          END IF;
        WHEN TXIDLE =>
          datao       <= ('0' & pgdata);
          datao_valid <= '0';
        WHEN TXDTSW =>
          datao       <= ('1' & dtstw);
          datao_valid <= '1';
        WHEN WAITGAP =>
          datao       <= ('0' & pgdata);
          datao_valid <= '0';
      END CASE;
      dtstw := ('0' & block_counter & tid & FESTWEOB);

      IF (counter_init) THEN
        block_counter := (0 => '1', OTHERS => '0');
      ELSIF (counter_enable) THEN
        block_counter := inc(block_counter);
      END IF;

      IF (reset_evid = '1') THEN
        event_id := (0 => '1', OTHERS => '0');
      ELSIF (pg_present = TXEVID) THEN
        event_id := inc(event_id);
      END IF;

      CASE pg_present IS
        WHEN IDLE =>
          IF (enable = '1' AND s_suspend = '0') THEN
            pg_next := INITPG1;
          ELSE
            pg_next := IDLE;
          END IF;
        WHEN INITPG1 =>
          IF (ps_reg(2 DOWNTO 0) = FIFO_OUT) THEN
            pg_next := TXDATA;
          ELSE
            pg_next := TXEVID;
          END IF;
        WHEN TXEVID =>                  -- 24.04.2002
          IF (block_end = '1') THEN
            pg_next := TXDTSW;
          ELSE
            pg_next := TXDATA;
          END IF;
        WHEN TXDATA =>
          IF (block_end = '1') THEN
            pg_next := TXDTSW;
          ELSIF (s_suspend = '1') THEN
            pg_next := TXIDLE;
          ELSE
            pg_next := TXDATA;
          END IF;
        WHEN TXIDLE =>
          IF (s_suspend = '0') THEN
            pg_next := TXDATA;
          ELSIF (enable = '0') THEN     -- 22.03.2002
            pg_next := IDLE;            -- 22.03.2002
          ELSE
            pg_next := TXIDLE;
          END IF;
        WHEN TXDTSW =>
          pg_next := WAITGAP;
        WHEN WAITGAP =>
          IF (enable = '0') THEN
            pg_next := IDLE;
          ELSE
            pg_next := WAITGAP;
          END IF;
      END CASE;
      pg_present := pg_next;

      fifo_rdreq <= bool2sl(pg_next = TXDATA);

      counter_init   := (pg_next = INITPG1 OR pg_next = TXDTSW);
      counter_enable := (pg_next = TXDATA);
      shiftrg_init   := (pg_next = INITPG1 OR pg_next = TXDTSW);
      shiftrg_enable := (pg_next = TXDATA);
      alterrg_init   := (pg_next = INITPG1 OR pg_next = TXDTSW);
      alterrg_enable := (pg_next = TXDATA);

    END IF;
  END PROCESS main;

END SYN;

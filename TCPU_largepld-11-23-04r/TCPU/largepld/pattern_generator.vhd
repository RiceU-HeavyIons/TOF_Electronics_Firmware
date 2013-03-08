-- $Id: pattern_generator.vhd,v 1.1.1.1 2004-12-03 19:29:46 tofp Exp $
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


library ieee;
use ieee.std_logic_1164.all;

entity pattern_generator is
  port (
    clock       : in  std_logic;
    arstn       : in  std_logic;
    ps_reg      : in  std_logic_vector ( 7 downto 0);
    bl_reg      : in  std_logic_vector ( 7 downto 0);
    xx_reg      : in  std_logic_vector ( 7 downto 0);
    tid         : in  std_logic_vector ( 3 downto 0);
    enable      : in  std_logic;
    suspend     : in  std_logic;
    reset_evid  : in  std_logic;
	fifo_q		: IN  std_logic_vector (31 DOWNTO 0);
	fifo_empty  : IN  std_logic;
	fifo_rdreq	: OUT std_logic;
    datao       : out std_logic_vector (32 downto 0);
    datao_valid : out std_logic);
end pattern_generator;

library ieee;
use ieee.std_logic_1164.all;
use work.my_conversions.all;
use work.my_utilities.all;

architecture SYN of pattern_generator is

  constant FIFO_OUT	 : std_logic_vector := "001";
  constant ALTER_0F  : std_logic_vector := "010";
  constant FLYING_0  : std_logic_vector := "011";
  constant FLYING_1  : std_logic_vector := "100";
  constant INCREMENT : std_logic_vector := "101";
  constant DECREMENT : std_logic_vector := "110";

  constant FESTWEOB  : std_logic_vector := "01100100";

  type pg_state is (
    IDLE,
    INITPG1,
    TXEVID,
    TXDATA,
    TXIDLE,
    TXDTSW,
    WAITGAP
  );

	SIGNAL s_suspend : std_logic;

begin

	s_suspend <= suspend OR fifo_empty;

  main : process (clock, arstn)
    variable pg_present     : pg_state;
    variable pg_next        : pg_state;

    variable pgdata         : std_logic_vector (31 downto 0);
    variable dtstw          : std_logic_vector (31 downto 0);
    variable shift_reg      : std_logic_vector (31 downto 0);
    variable shiftrg_init   : boolean;
    variable shiftrg_enable : boolean;
    variable counter_reg    : std_logic_vector (31 downto 0);
    variable counter_init   : boolean;
    variable counter_enable : boolean;
    variable alternate_reg  : std_logic_vector (31 downto 0);
    variable alterrg_init   : boolean;
    variable alterrg_enable : boolean;
    variable actual_length  : std_logic_vector (18 downto 0);
    variable fixed_length   : std_logic_vector (18 downto 0);
    variable rand_length    : std_logic_vector (18 downto 0);
    variable rand_mask      : std_logic_vector (18 downto 0);
    variable rand_msb       : std_logic;
    variable random_data    : std_logic_vector (31 downto 0);
    variable event_id       : std_logic_vector (31 downto 0);
    variable word_counter   : std_logic_vector (19 downto 0);
    variable block_counter  : std_logic_vector (18 downto 0);
    variable block_end      : std_logic;

  begin

    if (arstn = '0') then

      datao       	<= (others => '0');
      datao_valid 	<= '0';
	  fifo_rdreq 	<= '0';
	
      pg_present     := IDLE;
      pg_next        := IDLE;
      pgdata         := (others => '0');
      shift_reg      := (others => '0');
      shiftrg_init   := false;
      shiftrg_enable := false;
      counter_reg    := (others => '0');
      counter_init   := false;
      counter_enable := false;
      alternate_reg  := (others => '0');
      alterrg_init   := false;
      alterrg_enable := false;
      actual_length  := (6 => '1', others => '0');
      fixed_length   := (6 => '1', others => '0');
      rand_length    := (others => '1');
      rand_mask      := int2slv(63, 19);
      rand_msb       := '1';
      random_data    := (others => '0');
      event_id       := (0 => '1', others => '0');
      word_counter   := (others => '0');
      block_counter  := (0 => '1', others => '0');
      block_end      := '0';

    elsif (clock'event and clock = '1') then


      IF  (ps_reg(2 downto 0) = FIFO_OUT) THEN
		block_end := bool2sl( fifo_q(31 DOWNTO 24) = X"EA"); --"11100111" );
	  ELSE
     	block_end := word_counter(19);
	  END IF;
	
      if (pg_present = IDLE or pg_present = TXDTSW) then
        word_counter := ('0' & actual_length);
      elsif (pg_present = TXIDLE) then
        word_counter := word_counter;
      else
        word_counter := dec(word_counter);
      end if;

      if (bl_reg(4) = '0') then
        actual_length := fixed_length;
      else
        actual_length := rand_length and rand_mask;
      end if;

      if (reset_evid = '1') then
        rand_length := "10000000000" & xx_reg;
      elsif (pg_present = INITPG1) then
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
        rand_length(5)  := rand_length(4) xor rand_msb;
        rand_length(4)  := rand_length(3);
        rand_length(3)  := rand_length(2);
        rand_length(2)  := rand_length(1) xor rand_msb;
        rand_length(1)  := rand_length(0) xor rand_msb;
        rand_length(0)  := rand_msb;
      end if;

      case bl_reg(3 downto 0) is 
        when "0001" =>
          fixed_length := int2slv(15, 19);
          rand_mask    := int2slv(15, 19);
        when "0010" =>
          fixed_length := int2slv(31, 19);
          rand_mask    := int2slv(31, 19);
        when "0011" =>
          fixed_length := int2slv(63, 19);
          rand_mask    := int2slv(63, 19);
        when "0100" =>
          fixed_length := int2slv(127, 19);
          rand_mask    := int2slv(127, 19);
        when "0101" =>
          fixed_length := int2slv(255, 19);
          rand_mask    := int2slv(255, 19);
        when "0110" =>
          fixed_length := int2slv(511, 19);
          rand_mask    := int2slv(511, 19);
        when "0111" =>
          fixed_length := int2slv(1023, 19);
          rand_mask    := int2slv(1023, 19);
        when "1000" =>
          fixed_length := int2slv(2047, 19);
          rand_mask    := int2slv(2047, 19);
        when "1001" =>
          fixed_length := int2slv(4095, 19);
          rand_mask    := int2slv(4095, 19);
        when "1010" =>
          fixed_length := int2slv(8191, 19);
          rand_mask    := int2slv(8191, 19);
        when "1011" =>
          fixed_length := int2slv(16383, 19);
          rand_mask    := int2slv(16383, 19);
        when "1100" =>
          fixed_length := int2slv(32767, 19);
          rand_mask    := int2slv(32767, 19);
        when "1101" =>
          fixed_length := int2slv(65535, 19);
          rand_mask    := int2slv(65535, 19);
        when "1110" =>
          fixed_length := int2slv(131071, 19);
          rand_mask    := int2slv(131071, 19);
        when "1111" =>
          fixed_length := int2slv(262143, 19);
          rand_mask    := int2slv(262143, 19);
        when others =>
          fixed_length := int2slv(15, 19);
          rand_mask    := int2slv(15, 19);
      end case;

      case ps_reg(2 downto 0) is
 		WHEN FIFO_OUT =>
		  pgdata := fifo_q;
       	when ALTER_0F =>
          pgdata := alternate_reg;
        when FLYING_0  =>
          pgdata := shift_reg;
        when FLYING_1  =>
          pgdata := shift_reg;
        when INCREMENT =>
          pgdata := counter_reg;
        when DECREMENT =>
          pgdata := counter_reg;
        when others =>
          pgdata := counter_reg;
      end case;

      if (counter_init) then
        counter_reg := (others => '0');
      elsif (counter_enable) then
        if (ps_reg(2 downto 0) = DECREMENT) then
          counter_reg := dec(counter_reg);
        else
          counter_reg := inc(counter_reg);
        end if;
      end if;

      if (shiftrg_init) then
        if (ps_reg(2 downto 0) = FLYING_1) then
          shift_reg := ( 0 => '1', others => '0' );
        else
          shift_reg := ( 0 => '0', others => '1' );
        end if;
      elsif (shiftrg_enable) then
        shift_reg := (shift_reg(30 downto 0) & shift_reg(31));
      end if;

      if (alterrg_init) then
        alternate_reg := (others => '0');
      elsif (alterrg_enable) then
        alternate_reg := not alternate_reg;
      end if;

      case pg_present is
        when IDLE   =>
          datao       <= ('0' & pgdata);
          datao_valid <= '0';
        when INITPG1 =>
          datao       <= ('0' & pgdata);
          datao_valid <= '0';
        when TXEVID =>
          datao       <= ('0' & event_id);
          datao_valid <= '1';
        when TXDATA =>
          datao       <= ('0' & pgdata);
          datao_valid <= '1';
        when TXIDLE =>
          datao       <= ('0' & pgdata);
          datao_valid <= '0';
        when TXDTSW =>
          datao       <= ('1' & dtstw);
          datao_valid <= '1';
        when WAITGAP =>
          datao       <= ('0' & pgdata);
          datao_valid <= '0';
      end case;
      dtstw := ('0' & block_counter & tid & FESTWEOB);

      if (counter_init) then
        block_counter := (0 => '1', others => '0');
      elsif (counter_enable) then
        block_counter := inc(block_counter);
      end if;

      if (reset_evid = '1') then
        event_id := (0 => '1', others => '0');
      elsif (pg_present = TXEVID) then
        event_id := inc(event_id);
      end if;

      case pg_present is
        when IDLE =>
          if (enable = '1' and s_suspend = '0') then
            pg_next := INITPG1;
          else
            pg_next := IDLE;
          end if;
        when INITPG1 =>
     		IF  (ps_reg(2 downto 0) = FIFO_OUT) THEN
				pg_next := TXDATA;
			ELSE
          		pg_next := TXEVID;
			END IF;
        when TXEVID =>               -- 24.04.2002
          if (block_end = '1') then
            pg_next := TXDTSW;
          else
            pg_next := TXDATA;
          end if;
        when TXDATA =>
          if (block_end = '1') then
            pg_next := TXDTSW;
          elsif (s_suspend = '1') then
            pg_next := TXIDLE;
          else
            pg_next := TXDATA;
          end if;
        when TXIDLE =>
          if (s_suspend = '0') then
            pg_next := TXDATA;
          elsif (enable = '0') then  -- 22.03.2002
            pg_next := IDLE;         -- 22.03.2002
          else
            pg_next := TXIDLE;
          end if;
        when TXDTSW =>
          pg_next := WAITGAP;
        when WAITGAP =>
          if (enable = '0') then
            pg_next := IDLE;
          else
            pg_next := WAITGAP;
          end if;
      end case;
      pg_present := pg_next;

	 fifo_rdreq  <= bool2sl(pg_next = TXDATA);
	
     counter_init   := (pg_next = INITPG1 or pg_next = TXDTSW);
     counter_enable := (pg_next = TXDATA);
     shiftrg_init   := (pg_next = INITPG1 or pg_next = TXDTSW);
     shiftrg_enable := (pg_next = TXDATA);
     alterrg_init   := (pg_next = INITPG1 or pg_next = TXDTSW);
     alterrg_enable := (pg_next = TXDATA);

    end if;
  end process main;

end SYN;

--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: trigger_generator.vhd,v 1.1.1.1 2004-12-03 19:29:46 tofp Exp $
--******************************************************************************
--*  TRIGGER_GENERATOR
--*
--*
--*  REVISION HISTORY:
--*    11-Oct-2001 CS  Original coding
--*
--******************************************************************************

library ieee;
use ieee.std_logic_1164.all;

entity trigger_generator is
  port (
    clock      : in  std_logic;
    arstn      : in  std_logic;
    ext_tr_in  : in  std_logic;
    gap_active : in  std_logic;
    dt_reg     : in  std_logic_vector ( 7 downto 0);
	fifo_empty : IN	 std_logic; -- my trigger
    trigger    : out std_logic);
end trigger_generator;

library ieee;
use ieee.std_logic_1164.all;
use work.my_conversions.all;
use work.my_utilities.all;

architecture SYN of trigger_generator is

  constant FIFOTR : std_logic_vector := "001";	-- Trigger on "FIFO not empty"
  constant EXTTR  : std_logic_vector := "010";
  constant GAP016 : std_logic_vector := "011";
  constant GAP128 : std_logic_vector := "100";
  constant E10MS  : std_logic_vector := "101";
  constant E100MS : std_logic_vector := "110";

begin

  main : process (clock, arstn)

    variable tr_timer     : std_logic_vector (22 downto 0);
    variable tr_timer_in  : std_logic_vector (22 downto 0);
    variable tr_timer_to  : std_logic;
    variable gap_timer    : std_logic_vector (7 downto 0);
    variable gap_timer_in : std_logic_vector (7 downto 0);
    variable gap_timer_to : std_logic;
    variable trg_lock     : std_logic;
    variable ext_tr_reg1  : std_logic;
    variable ext_tr_reg2  : std_logic;
    variable ext_tr_edge  : std_logic;

  begin

    if (arstn = '0') then

      trigger <= '0';
      tr_timer     := (others => '0');
      tr_timer_in  := "01001100010010110100000";
      tr_timer_to  := '0';
      gap_timer    := (others => '0');
      gap_timer_in := "00001001";
      gap_timer_to := '0';
      trg_lock     := '1';
      ext_tr_reg1  := '0';
      ext_tr_reg2  := '0';
      ext_tr_edge  := '0';

    elsif (clock'event and clock = '1') then

      tr_timer_to := tr_timer(22);
      if (tr_timer(22) = '1') then
        tr_timer := tr_timer_in;
      else
        tr_timer := dec(tr_timer);
      end if;
      case dt_reg(2 downto 0) is
        when E10MS  =>
          tr_timer_in := "00000111101000010010000";
        when E100MS =>
          tr_timer_in := "01001100010010110100000";
        when others =>
          tr_timer_in := "01001100010010110100000";
      end case;

      gap_timer_to := gap_timer(7);
      if (gap_active = '0') then
        gap_timer := gap_timer_in;
      else
        gap_timer := dec(gap_timer);
      end if;
      case dt_reg(2 downto 0) is
        when GAP016 =>
          gap_timer_in := "00001001";
        when GAP128 =>
          gap_timer_in := "01111001";
        when others =>
          gap_timer_in := "00001001";
      end case;

      case dt_reg(2 downto 0) is
        when EXTTR  =>
          trigger <= ext_tr_edge;
	    WHEN FIFOTR =>
		  trigger <= (NOT fifo_empty) AND (NOT trg_lock);
        when GAP016 =>
          trigger <= gap_timer_to;
        when GAP128 =>
          trigger <= gap_timer_to;
        when E10MS  =>
          trigger <= tr_timer_to and not trg_lock;
        when E100MS =>
          trigger <= tr_timer_to and not trg_lock;
        when others =>
          trigger <= ext_tr_edge;
      end case;
      if (gap_active = '0') then
        trg_lock := '1';
      elsif (gap_timer_to = '1') then
        trg_lock := '0';
      end if;

      ext_tr_edge := ext_tr_reg1 and not ext_tr_reg2;
      ext_tr_reg2 := ext_tr_reg1;
      ext_tr_reg1 := ext_tr_in;
    end if;
  end process;

end SYN;
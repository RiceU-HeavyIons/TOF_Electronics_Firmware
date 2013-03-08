--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: trigger_generator.vhd,v 1.3 2004-12-09 22:35:10 tofp Exp $
--******************************************************************************
--*  TRIGGER_GENERATOR
--*
--*
--*  REVISION HISTORY:
--*    11-Oct-2001 CS  Original coding
--*
--******************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;


ENTITY trigger_generator IS
  PORT (
    clock      : IN  std_logic;
    arstn      : IN  std_logic;
    ext_tr_in  : IN  std_logic;
    gap_active : IN  std_logic;
    dt_reg     : IN  std_logic_vector ( 7 DOWNTO 0);
    fifo_empty : IN  std_logic;         -- my trigger
    trigger    : OUT std_logic);
END trigger_generator;

ARCHITECTURE SYN OF trigger_generator IS

  CONSTANT FIFOTR : std_logic_vector := "001";  -- Trigger on "FIFO not empty"
  CONSTANT EXTTR  : std_logic_vector := "010";
  CONSTANT GAP016 : std_logic_vector := "011";
  CONSTANT GAP128 : std_logic_vector := "100";
  CONSTANT E10MS  : std_logic_vector := "101";
  CONSTANT E100MS : std_logic_vector := "110";

BEGIN

  main : PROCESS (clock, arstn)

    VARIABLE tr_timer     : std_logic_vector (22 DOWNTO 0);
    VARIABLE tr_timer_in  : std_logic_vector (22 DOWNTO 0);
    VARIABLE tr_timer_to  : std_logic;
    VARIABLE gap_timer    : std_logic_vector (7 DOWNTO 0);
    VARIABLE gap_timer_in : std_logic_vector (7 DOWNTO 0);
    VARIABLE gap_timer_to : std_logic;
    VARIABLE trg_lock     : std_logic;
    VARIABLE ext_tr_reg1  : std_logic;
    VARIABLE ext_tr_reg2  : std_logic;
    VARIABLE ext_tr_edge  : std_logic;

  BEGIN

    IF (arstn = '0') THEN

      trigger      <= '0';
      tr_timer     := (OTHERS => '0');
      tr_timer_in  := "01001100010010110100000";
      tr_timer_to  := '0';
      gap_timer    := (OTHERS => '0');
      gap_timer_in := "00001001";
      gap_timer_to := '0';
      trg_lock     := '1';
      ext_tr_reg1  := '0';
      ext_tr_reg2  := '0';
      ext_tr_edge  := '0';

    ELSIF (clock'event AND clock = '1') THEN

      tr_timer_to := tr_timer(22);
      IF (tr_timer(22) = '1') THEN
        tr_timer := tr_timer_in;
      ELSE
        tr_timer := dec(tr_timer);
      END IF;
      CASE dt_reg(2 DOWNTO 0) IS
        WHEN E10MS =>
          tr_timer_in := "00000111101000010010000";
        WHEN E100MS =>
          tr_timer_in := "01001100010010110100000";
        WHEN OTHERS =>
          tr_timer_in := "01001100010010110100000";
      END CASE;

      gap_timer_to := gap_timer(7);
      IF (gap_active = '0') THEN
        gap_timer := gap_timer_in;
      ELSE
        gap_timer := dec(gap_timer);
      END IF;
      CASE dt_reg(2 DOWNTO 0) IS
        WHEN GAP016 =>
          gap_timer_in := "00001001";
        WHEN GAP128 =>
          gap_timer_in := "01111001";
        WHEN OTHERS =>
          gap_timer_in := "00001001";
      END CASE;

      CASE dt_reg(2 DOWNTO 0) IS
        WHEN EXTTR =>
          trigger <= ext_tr_edge;
        WHEN FIFOTR =>
          trigger <= (NOT fifo_empty) AND (NOT trg_lock);
        WHEN GAP016 =>
          trigger <= gap_timer_to;
        WHEN GAP128 =>
          trigger <= gap_timer_to;
        WHEN E10MS =>
          trigger <= tr_timer_to AND NOT trg_lock;
        WHEN E100MS =>
          trigger <= tr_timer_to AND NOT trg_lock;
        WHEN OTHERS =>
          trigger <= (NOT fifo_empty) AND (NOT trg_lock);  -- default is fifo trigger
      END CASE;
      IF (gap_active = '0') THEN
        trg_lock := '1';
      ELSIF (gap_timer_to = '1') THEN
        trg_lock := '0';
      END IF;

      ext_tr_edge := ext_tr_reg1 AND NOT ext_tr_reg2;
      ext_tr_reg2 := ext_tr_reg1;
      ext_tr_reg1 := ext_tr_in;
    END IF;
  END PROCESS;

END SYN;

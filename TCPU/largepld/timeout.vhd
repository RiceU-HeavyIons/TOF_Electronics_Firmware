LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
USE work.tcpu_package.ALL;


ENTITY timeout IS
  GENERIC (
    nbit : integer := 10);              -- width of counter
  PORT(clk, reset    : IN  std_logic;
       clr_timeout   : IN  std_logic;
       timeout_valid : OUT std_logic
       );
END timeout;

ARCHITECTURE lwb1 OF timeout IS
  
  SIGNAL counter_reset, term_cnt   : std_logic;
  SIGNAL term_cnt_flag, stop_count : std_logic;
  SIGNAL cnt_val                   : std_logic_vector(nbit-1 DOWNTO 0);

BEGIN
  counter_reset <= reset OR clr_timeout;
  stop_count    <= reset OR term_cnt;

  timer : lpm_counter
    GENERIC MAP (
      lpm_width     => nbit,
      lpm_type      => "LPM_COUNTER",
      lpm_direction => "UP")
    PORT MAP (
      sclr  => counter_reset,
      clock => clk,
      cout  => term_cnt,
      q     => cnt_val);

  -- this flag is set when counter reaches terminal cnt
  timeout_flag : DFF_sclr_sset PORT MAP (
    clock => clk,
    sclr  => counter_reset,
    sset  => term_cnt,
    data  => term_cnt_flag,
    q     => term_cnt_flag);

  timeout_valid <= term_cnt_flag;

  -- this ff enables counter after 'clr_timeout' input
--              enable_ff : DFF_sclr_sset PORT MAP (
--                      clock    => clk,
--                      sclr     => stop_count,
--                      sset     => clr_timeout,
--                      data     => count_enable,
--                      q        => count_enable);

END lwb1;





--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: receiver.vhd,v 1.1.1.1 2004-12-03 19:29:46 tofp Exp $
--******************************************************************************
--*  RECEIVER.VHD
--*
--*
--*  REVISION HISTORY:
--*    11-Oct-2001 CS  Original coding
--*    22-Mar-2002 CS  Event ID reset
--*                    FEIC reset
--*
--******************************************************************************


library ieee;
use ieee.std_logic_1164.all;

entity receiver is
  port (
    clock        : in  std_logic;
    arstn        : in  std_logic;
    fc_reg       : in  std_logic_vector ( 7 downto 0);
    block_read   : out std_logic;
    block_write  : out std_logic;
    event_read   : out std_logic;
    reset_evid   : out std_logic;
    im_din       : out std_logic_vector (31 downto 0);
    im_dinval    : out std_logic;
    reg_data     : out std_logic_vector ( 7 downto 0);
    reg_addr     : out std_logic_vector ( 5 downto 0);
    reg_load     : out std_logic;
    reg_read     : out std_logic;
    reg_lock     : out std_logic;
    tid          : out std_logic_vector ( 3 downto 0);
    fiD          : in  std_logic_vector (31 downto 0);
    fiTEN_N      : in  std_logic;
    fiCTRL_N     : in  std_logic;
    fiDIR        : in  std_logic;
    fiBEN_N      : in  std_logic;
    foBSY_N      : out std_logic
  );
end receiver;

library ieee;
use ieee.std_logic_1164.all;
use work.my_conversions.all;
use work.my_utilities.all;

architecture SYN of receiver is

  constant CMD_FECTRL : std_logic_vector := "11000100";
  constant CMD_FESTRD : std_logic_vector := "01000100";
  constant CMD_STBWR  : std_logic_vector := "11010100";
  constant CMD_STBRD  : std_logic_vector := "01010100";
  constant CMD_RDYRX  : std_logic_vector := "00010100";

  constant EACHWORD : std_logic_vector := "01";
  constant EACH128W : std_logic_vector := "10";
  constant EACH16KW : std_logic_vector := "11";

  type input_state is (
    IS_IDLE,
    IS_EVAL,
    IS_FECTRL,
    IS_FESTRD,
    IS_STBWR,
    IS_STBRD,
    IS_EVDATA);

  type flow_state is (
    FS_IDLE,
    FS_COUNT,
    FS_BUSY,
    FS_WAIT);

  type feebus_state is (
    FB_INPUT,
    FB_FLOAT,
    FB_OUTPUT,
    FB_RESET
  );

begin

  main : process (clock, arstn)

    variable flow_present   : flow_state;
    variable flow_next      : flow_state;
    variable input_present  : input_state;
    variable input_next     : input_state;
    variable feebus_present : feebus_state;
    variable feebus_next    : feebus_state;
    variable f_count        : std_logic_vector (14 downto 0);
    variable f_count_init   : std_logic_vector (14 downto 0);
    variable f_count_of     : std_logic;
    variable b_rxany        : boolean;
    variable b_rxdat        : boolean;
    variable b_rxcmd        : boolean;
    variable command_code   : std_logic_vector (7 downto 0);
    variable command_tid    : std_logic_vector (3 downto 0);
    variable command_param  : std_logic_vector (18 downto 0);
    variable download       : std_logic;

  begin

    if (arstn = '0') then
      foBSY_N        <= '1';
      block_read     <= '0';
      block_write    <= '0';
      event_read     <= '0';
      reset_evid     <= '0';
      im_din         <= (others => '0');
      im_dinval      <= '0';
      reg_data       <= (others => '0');
      reg_addr       <= (others => '0');
      reg_load       <= '0';
      reg_read       <= '0';
      reg_lock       <= '0';
      tid            <= (others => '0');
      flow_present   := FS_IDLE;
      flow_next      := FS_IDLE;
      input_present  := IS_IDLE;
      input_next     := IS_IDLE;
      feebus_present := FB_INPUT;
      feebus_next    := FB_INPUT;
      f_count        := (others => '0');
      f_count_init   := (others => '0');
      b_rxany        := false;
      b_rxdat        := false;
      b_rxcmd        := false;
      command_code   := (others => '0');
      command_tid    := (others => '0');
      command_param  := (others => '0');
      download       := '0';
    elsif (clock'event and clock = '1') then

      case fc_reg(1 downto 0) is
        when EACHWORD =>
          f_count_init := "111111111111111";
        when EACH128W =>
          f_count_init := "000000001111110";
        when EACH16KW =>
          f_count_init := "011111111111110";
        when others   =>
          f_count_init := "011111111111110";
      end case;

      b_rxany := (fiDIR = '0') and (fiTEN_N = '0');
      f_count_of := f_count(14);
      if (b_rxany) or (flow_present = FS_IDLE) then
        f_count := f_count_init;
      else
        f_count := dec(f_count);
      end if;

      case flow_present is
        when FS_IDLE  =>
          if (download = '1') then
            flow_next := FS_COUNT;
          else
            flow_next := FS_IDLE;
          end if;
        when FS_COUNT =>
          if (f_count_of = '1') and (b_rxany) then
            flow_next := FS_BUSY;
          else
            flow_next := FS_COUNT;
          end if;
        when FS_BUSY  =>
          flow_next := FS_WAIT;
        when FS_WAIT  =>
          if (download = '0') then
            flow_next := FS_IDLE;
          elsif (not b_rxany) then
            flow_next := FS_COUNT;
          else
            flow_next := FS_WAIT;
          end if;
      end case;
      flow_present := flow_next;
      if (flow_next = FS_BUSY) then
        foBSY_N <= '0';
      else
        foBSY_N <= '1';
      end if;

      b_rxdat := b_rxany and (fiCTRL_N = '1');
      if (input_present = IS_STBWR) then
        im_dinval <= bool2sl(b_rxdat);
        im_din    <= fiD;
      else
        im_dinval <= '0';
        im_din    <= (others => '0');
      end if;

      if (input_present = IS_FECTRL) then
        reg_load <= '1';
      else
        reg_load <= '0';
      end if;
      if (input_present = IS_FESTRD) then
        reg_read <= '1';
      else
        reg_read <= '0';
      end if;
      reg_data <= command_param( 7 downto 0);
      reg_addr <= command_param(13 downto 8);
      reg_lock <= not bool2sl(input_present = IS_IDLE);

      if (input_present = IS_STBRD) then
        block_read <= '1';
      else
        block_read <= '0';
      end if;

      if (input_present = IS_STBWR) then
        block_write <= '1';
      else
        block_write <= '0';
      end if;

      if (input_present = IS_EVDATA) then
        event_read <= '1';
      else
        event_read <= '0';
      end if;

      if (input_present = IS_EVAL and command_code = CMD_RDYRX) then
        reset_evid <= '1';
      else
        reset_evid <= '0';
      end if;

      case input_present is
        when IS_IDLE   =>
          download      := '0';
          if (b_rxcmd) then
            input_next := IS_EVAL;
          else
            input_next := IS_IDLE;
          end if;
        when IS_EVAL   =>
          download      := '0';
          if    (command_code = CMD_FECTRL) then
            input_next := IS_FECTRL;
          elsif (command_code = CMD_FESTRD) then
            input_next := IS_FESTRD;
          elsif (command_code = CMD_STBWR) then
            input_next := IS_STBWR;
          elsif (command_code = CMD_STBRD) then
            input_next := IS_STBRD;
          elsif (command_code = CMD_RDYRX) then
            input_next := IS_EVDATA;
          else
            input_next := IS_IDLE;
          end if;
        when IS_FECTRL =>
          download      := '0';
          input_next := IS_IDLE;
        when IS_FESTRD =>
          download      := '0';
          input_next := IS_IDLE;
        when IS_STBWR  =>
          download      := '1';
          if (b_rxcmd) then
            input_next := IS_IDLE;
          else
            input_next := IS_STBWR;
          end if;
        when IS_STBRD  =>
          download      := '0';
          if (b_rxcmd or feebus_present = FB_RESET) then
            input_next := IS_IDLE;
          else
            input_next := IS_STBRD;
          end if;
        when IS_EVDATA =>
          download      := '0';
          if (b_rxcmd or feebus_present = FB_RESET) then
            input_next := IS_IDLE;
          else
            input_next := IS_EVDATA;
          end if;
      end case;
      input_present := input_next;

      tid      <= command_tid;

      b_rxcmd := b_rxany and (fiCTRL_N = '0');
      if (b_rxcmd) then
        command_code  := fiD( 7 downto  0);
        command_tid   := fiD(11 downto  8);
        command_param := fiD(30 downto 12);
      end if;

      case feebus_present is
        when FB_INPUT =>
          if (fiBEN_N = '1') then
            feebus_next := FB_FLOAT;
          else
            feebus_next := FB_INPUT;
          end if;
        when FB_FLOAT =>
          if (fiBEN_N = '0') then
            if (fiDIR = '0') then
              feebus_next := FB_INPUT;
            else
              feebus_next := FB_OUTPUT;
            end if;
          else
            feebus_next := FB_FLOAT;
          end if;
        when FB_OUTPUT =>
          if (fiBEN_N = '1') then
            feebus_next := FB_FLOAT;
          elsif (fiDIR = '0') then    -- 22.03.2002
            feebus_next := FB_RESET;  -- 22.03.2002
          else
            feebus_next := FB_OUTPUT;
          end if;
        when FB_RESET =>              -- 22.03.2002
          feebus_next := FB_INPUT;    -- 22.03.2002
      end case;
      feebus_present := feebus_next;

    end if;
  end process;

end SYN;

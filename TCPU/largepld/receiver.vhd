--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: receiver.vhd,v 1.2 2004-12-08 22:52:28 tofp Exp $
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


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY receiver IS
  PORT (
    clock       : IN  std_logic;
    arstn       : IN  std_logic;
    fc_reg      : IN  std_logic_vector ( 7 DOWNTO 0);
    block_read  : OUT std_logic;
    block_write : OUT std_logic;
    event_read  : OUT std_logic;
    reset_evid  : OUT std_logic;
    im_din      : OUT std_logic_vector (31 DOWNTO 0);
    im_dinval   : OUT std_logic;
    reg_data    : OUT std_logic_vector ( 7 DOWNTO 0);
    reg_addr    : OUT std_logic_vector ( 5 DOWNTO 0);
    reg_load    : OUT std_logic;
    reg_read    : OUT std_logic;
    reg_lock    : OUT std_logic;
    tid         : OUT std_logic_vector ( 3 DOWNTO 0);
    fiD         : IN  std_logic_vector (31 DOWNTO 0);
    fiTEN_N     : IN  std_logic;
    fiCTRL_N    : IN  std_logic;
    fiDIR       : IN  std_logic;
    fiBEN_N     : IN  std_logic;
    foBSY_N     : OUT std_logic
    );
END receiver;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

ARCHITECTURE SYN OF receiver IS

  CONSTANT CMD_FECTRL : std_logic_vector := "11000100";
  CONSTANT CMD_FESTRD : std_logic_vector := "01000100";
  CONSTANT CMD_STBWR  : std_logic_vector := "11010100";
  CONSTANT CMD_STBRD  : std_logic_vector := "01010100";
  CONSTANT CMD_RDYRX  : std_logic_vector := "00010100";

  CONSTANT EACHWORD : std_logic_vector := "01";
  CONSTANT EACH128W : std_logic_vector := "10";
  CONSTANT EACH16KW : std_logic_vector := "11";

  TYPE input_state IS (
    IS_IDLE,
    IS_EVAL,
    IS_FECTRL,
    IS_FESTRD,
    IS_STBWR,
    IS_STBRD,
    IS_EVDATA);

  TYPE flow_state IS (
    FS_IDLE,
    FS_COUNT,
    FS_BUSY,
    FS_WAIT);

  TYPE feebus_state IS (
    FB_INPUT,
    FB_FLOAT,
    FB_OUTPUT,
    FB_RESET
    );

BEGIN

  main : PROCESS (clock, arstn)

    VARIABLE flow_present   : flow_state;
    VARIABLE flow_next      : flow_state;
    VARIABLE input_present  : input_state;
    VARIABLE input_next     : input_state;
    VARIABLE feebus_present : feebus_state;
    VARIABLE feebus_next    : feebus_state;
    VARIABLE f_count        : std_logic_vector (14 DOWNTO 0);
    VARIABLE f_count_init   : std_logic_vector (14 DOWNTO 0);
    VARIABLE f_count_of     : std_logic;
    VARIABLE b_rxany        : boolean;
    VARIABLE b_rxdat        : boolean;
    VARIABLE b_rxcmd        : boolean;
    VARIABLE command_code   : std_logic_vector (7 DOWNTO 0);
    VARIABLE command_tid    : std_logic_vector (3 DOWNTO 0);
    VARIABLE command_param  : std_logic_vector (18 DOWNTO 0);
    VARIABLE download       : std_logic;

  BEGIN

    IF (arstn = '0') THEN
      foBSY_N        <= '1';
      block_read     <= '0';
      block_write    <= '0';
      event_read     <= '0';
      reset_evid     <= '0';
      im_din         <= (OTHERS => '0');
      im_dinval      <= '0';
      reg_data       <= (OTHERS => '0');
      reg_addr       <= (OTHERS => '0');
      reg_load       <= '0';
      reg_read       <= '0';
      reg_lock       <= '0';
      tid            <= (OTHERS => '0');
      flow_present   := FS_IDLE;
      flow_next      := FS_IDLE;
      input_present  := IS_IDLE;
      input_next     := IS_IDLE;
      feebus_present := FB_INPUT;
      feebus_next    := FB_INPUT;
      f_count        := (OTHERS => '0');
      f_count_init   := (OTHERS => '0');
      b_rxany        := false;
      b_rxdat        := false;
      b_rxcmd        := false;
      command_code   := (OTHERS => '0');
      command_tid    := (OTHERS => '0');
      command_param  := (OTHERS => '0');
      download       := '0';
    ELSIF (clock'event AND clock = '1') THEN

      CASE fc_reg(1 DOWNTO 0) IS
        WHEN EACHWORD =>
          f_count_init := "111111111111111";
        WHEN EACH128W =>
          f_count_init := "000000001111110";
        WHEN EACH16KW =>
          f_count_init := "011111111111110";
        WHEN OTHERS =>
          f_count_init := "011111111111110";
      END CASE;

      b_rxany    := (fiDIR = '0') AND (fiTEN_N = '0');
      f_count_of := f_count(14);
      IF (b_rxany) OR (flow_present = FS_IDLE) THEN
        f_count := f_count_init;
      ELSE
        f_count := dec(f_count);
      END IF;

      CASE flow_present IS
        WHEN FS_IDLE =>
          IF (download = '1') THEN
            flow_next := FS_COUNT;
          ELSE
            flow_next := FS_IDLE;
          END IF;
        WHEN FS_COUNT =>
          IF (f_count_of = '1') AND (b_rxany) THEN
            flow_next := FS_BUSY;
          ELSE
            flow_next := FS_COUNT;
          END IF;
        WHEN FS_BUSY =>
          flow_next := FS_WAIT;
        WHEN FS_WAIT =>
          IF (download = '0') THEN
            flow_next := FS_IDLE;
          ELSIF (NOT b_rxany) THEN
            flow_next := FS_COUNT;
          ELSE
            flow_next := FS_WAIT;
          END IF;
      END CASE;
      flow_present := flow_next;
      IF (flow_next = FS_BUSY) THEN
        foBSY_N <= '0';
      ELSE
        foBSY_N <= '1';
      END IF;

      b_rxdat := b_rxany AND (fiCTRL_N = '1');
      IF (input_present = IS_STBWR) THEN
        im_dinval <= bool2sl(b_rxdat);
        im_din    <= fiD;
      ELSE
        im_dinval <= '0';
        im_din    <= (OTHERS => '0');
      END IF;

      IF (input_present = IS_FECTRL) THEN
        reg_load <= '1';
      ELSE
        reg_load <= '0';
      END IF;
      IF (input_present = IS_FESTRD) THEN
        reg_read <= '1';
      ELSE
        reg_read <= '0';
      END IF;
      reg_data <= command_param( 7 DOWNTO 0);
      reg_addr <= command_param(13 DOWNTO 8);
      reg_lock <= NOT bool2sl(input_present = IS_IDLE);

      IF (input_present = IS_STBRD) THEN
        block_read <= '1';
      ELSE
        block_read <= '0';
      END IF;

      IF (input_present = IS_STBWR) THEN
        block_write <= '1';
      ELSE
        block_write <= '0';
      END IF;

      IF (input_present = IS_EVDATA) THEN
        event_read <= '1';
      ELSE
        event_read <= '0';
      END IF;

      IF (input_present = IS_EVAL AND command_code = CMD_RDYRX) THEN
        reset_evid <= '1';
      ELSE
        reset_evid <= '0';
      END IF;

      CASE input_present IS
        WHEN IS_IDLE =>
          download := '0';
          IF (b_rxcmd) THEN
            input_next := IS_EVAL;
          ELSE
            input_next := IS_IDLE;
          END IF;
        WHEN IS_EVAL =>
          download := '0';
          IF (command_code = CMD_FECTRL) THEN
            input_next := IS_FECTRL;
          ELSIF (command_code = CMD_FESTRD) THEN
            input_next := IS_FESTRD;
          ELSIF (command_code = CMD_STBWR) THEN
            input_next := IS_STBWR;
          ELSIF (command_code = CMD_STBRD) THEN
            input_next := IS_STBRD;
          ELSIF (command_code = CMD_RDYRX) THEN
            input_next := IS_EVDATA;
          ELSE
            input_next := IS_IDLE;
          END IF;
        WHEN IS_FECTRL =>
          download   := '0';
          input_next := IS_IDLE;
        WHEN IS_FESTRD =>
          download   := '0';
          input_next := IS_IDLE;
        WHEN IS_STBWR =>
          download := '1';
          IF (b_rxcmd) THEN
            input_next := IS_IDLE;
          ELSE
            input_next := IS_STBWR;
          END IF;
        WHEN IS_STBRD =>
          download := '0';
          IF (b_rxcmd OR feebus_present = FB_RESET) THEN
            input_next := IS_IDLE;
          ELSE
            input_next := IS_STBRD;
          END IF;
        WHEN IS_EVDATA =>
          download := '0';
          IF (b_rxcmd OR feebus_present = FB_RESET) THEN
            input_next := IS_IDLE;
          ELSE
            input_next := IS_EVDATA;
          END IF;
      END CASE;
      input_present := input_next;

      tid <= command_tid;

      b_rxcmd := b_rxany AND (fiCTRL_N = '0');
      IF (b_rxcmd) THEN
        command_code  := fiD( 7 DOWNTO 0);
        command_tid   := fiD(11 DOWNTO 8);
        command_param := fiD(30 DOWNTO 12);
      END IF;

      CASE feebus_present IS
        WHEN FB_INPUT =>
          IF (fiBEN_N = '1') THEN
            feebus_next := FB_FLOAT;
          ELSE
            feebus_next := FB_INPUT;
          END IF;
        WHEN FB_FLOAT =>
          IF (fiBEN_N = '0') THEN
            IF (fiDIR = '0') THEN
              feebus_next := FB_INPUT;
            ELSE
              feebus_next := FB_OUTPUT;
            END IF;
          ELSE
            feebus_next := FB_FLOAT;
          END IF;
        WHEN FB_OUTPUT =>
          IF (fiBEN_N = '1') THEN
            feebus_next := FB_FLOAT;
          ELSIF (fiDIR = '0') THEN      -- 22.03.2002
            feebus_next := FB_RESET;    -- 22.03.2002
          ELSE
            feebus_next := FB_OUTPUT;
          END IF;
        WHEN FB_RESET =>                -- 22.03.2002
          feebus_next := FB_INPUT;      -- 22.03.2002
      END CASE;
      feebus_present := feebus_next;

    END IF;
  END PROCESS;

END SYN;

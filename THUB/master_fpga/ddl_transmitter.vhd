--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: ddl_transmitter.vhd,v 1.2 2011-03-02 18:02:25 jschamba Exp $
--******************************************************************************
--*  ddl_transmitter.vhd
--*
--*
--*  REVISION HISTORY:
--*    12-Oct-2001 CS  Original coding
--*     2-May-2002 CS  TXINGAP before TXDATA (fix trigger problem)
--*    31-Oct-2002 CS  Internal memory is added to the data path
--*
--******************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

ENTITY ddl_transmitter IS
  PORT (
    clock      : IN  std_logic;
    arstn      : IN  std_logic;
    trigger    : IN  std_logic;
    gap_active : OUT std_logic;
    block_read : IN  std_logic;
    event_read : IN  std_logic;
    reg_read   : IN  std_logic;
    reg_addr   : IN  std_logic_vector ( 5 DOWNTO 0);
    tid        : IN  std_logic_vector ( 3 DOWNTO 0);
    ps_reg     : IN  std_logic_vector ( 7 DOWNTO 0);
    bl_reg     : IN  std_logic_vector ( 7 DOWNTO 0);
    dt_reg     : IN  std_logic_vector ( 7 DOWNTO 0);
    fc_reg     : IN  std_logic_vector ( 7 DOWNTO 0);
    te_reg     : IN  std_logic_vector ( 7 DOWNTO 0);
    xx_reg     : IN  std_logic_vector ( 7 DOWNTO 0);
    pg_dout    : IN  std_logic_vector (32 DOWNTO 0);
    pg_doutval : IN  std_logic;
    pg_enable  : OUT std_logic;
    im_dout    : IN  std_logic_vector (32 DOWNTO 0);
    im_doutval : IN  std_logic;
    im_enable  : OUT std_logic;
    foD        : OUT std_logic_vector (31 DOWNTO 0);
    foTEN_N    : OUT std_logic;
    foCTRL_N   : OUT std_logic;
    fiDIR      : IN  std_logic;
    fiBEN_N    : IN  std_logic;
    fiLF_N     : IN  std_logic
    );
END ddl_transmitter;

ARCHITECTURE SYN OF ddl_transmitter IS

  CONSTANT FESTW : std_logic_vector := "01000100";

  TYPE output_state IS (
    OS_IDLE,
    OS_WAITOUT,
    OS_TXSTATUS,
    OS_TXDATA,
    OS_TXINGAP,
    OS_WAITIN
    );

  TYPE feebus_state IS (
    FB_INPUT,
    FB_FLOAT,
    FB_OUTPUT,
    FB_RESET
    );

BEGIN

  main : PROCESS (clock, arstn)
    VARIABLE datao          : std_logic_vector (32 DOWNTO 0);
    VARIABLE datao_valid    : std_logic;
    VARIABLE st_dout        : std_logic_vector (32 DOWNTO 0);
    VARIABLE b_block_end    : boolean;
    VARIABLE reg_read_req   : std_logic;
    VARIABLE output_present : output_state;
    VARIABLE output_next    : output_state;
    VARIABLE feebus_present : feebus_state;
    VARIABLE feebus_next    : feebus_state;
  BEGIN
    IF (arstn = '0') THEN
      gap_active <= '0';
      pg_enable  <= '0';
      im_enable  <= '0';
      foD        <= (OTHERS => '0');
      foTEN_N    <= '1';
      foCTRL_N   <= '1';

      datao          := (OTHERS => '0');
      datao_valid    := '0';
      st_dout        := (OTHERS => '0');
      b_block_end    := false;
      reg_read_req   := '0';
      output_present := OS_IDLE;
      output_next    := OS_IDLE;
      feebus_present := FB_INPUT;
      feebus_next    := FB_INPUT;

    ELSIF rising_edge(clock) THEN

      IF (output_present = OS_TXSTATUS) THEN
        datao       := st_dout;
        datao_valid := '1';
        b_block_end := false;
      ELSIF (output_present = OS_TXDATA) THEN
        IF block_read = '1' THEN
          datao       := im_dout;
          datao_valid := im_doutval;
          b_block_end := (im_dout(32) = '1' AND im_doutval = '1');
        ELSE
          datao       := pg_dout;
          datao_valid := pg_doutval;
          b_block_end := (pg_dout(32) = '1' AND pg_doutval = '1');
        END IF;
      ELSE
        datao       := (OTHERS => '0');
        datao_valid := '0';
      END IF;

      foD      <= datao(31 DOWNTO 0);
      foCTRL_N <= NOT (datao_valid AND datao(32));
      foTEN_N  <= NOT (datao_valid);

      CASE reg_addr(2 DOWNTO 0) IS
        WHEN "000" =>
          st_dout := "1000000000000" & ps_reg & tid & FESTW;
        WHEN "001" =>
          st_dout := "1000000000000" & bl_reg & tid & FESTW;
        WHEN "010" =>
          st_dout := "1000000000000" & dt_reg & tid & FESTW;
        WHEN "011" =>
          st_dout := "1000000000000" & fc_reg & tid & FESTW;
        WHEN "100" =>
          st_dout := "1000000000000" & te_reg & tid & FESTW;
        WHEN "101" =>
          st_dout := "1000000000000" & xx_reg & tid & FESTW;
        WHEN OTHERS =>
          st_dout := "1000000000000" & "00000000" & tid & FESTW;
      END CASE;

      IF (reg_read = '1') AND (reg_read_req = '0') THEN
        reg_read_req := '1';
      ELSIF (output_present = OS_TXSTATUS) THEN
        reg_read_req := '0';
      END IF;

      CASE output_present IS
        WHEN OS_IDLE =>
          IF (feebus_present = FB_FLOAT) THEN
            output_next := OS_WAITOUT;
          ELSE
            output_next := OS_IDLE;
          END IF;
        WHEN OS_WAITOUT =>
          IF (feebus_present = FB_OUTPUT) THEN
            IF (reg_read_req = '1') THEN
              output_next := OS_TXSTATUS;
            ELSIF (block_read = '1') THEN
              output_next := OS_TXDATA;
            ELSIF (event_read = '1') THEN
              output_next := OS_TXINGAP;
            ELSE
              output_next := OS_WAITIN;
            END IF;
          ELSIF (feebus_present = FB_INPUT) THEN
            output_next := OS_IDLE;
          ELSE
            output_next := OS_WAITOUT;
          END IF;
        WHEN OS_TXSTATUS =>
          output_next := OS_WAITIN;
        WHEN OS_TXDATA =>
          IF (feebus_present = FB_FLOAT OR feebus_present = FB_RESET) THEN
            output_next := OS_WAITIN;
          ELSIF (block_read = '1') AND (b_block_end) THEN
            output_next := OS_WAITIN;
          ELSIF (event_read = '1') AND (b_block_end) THEN
            output_next := OS_TXINGAP;
          ELSE
            output_next := OS_TXDATA;
          END IF;
        WHEN OS_TXINGAP =>
          IF (feebus_present = FB_FLOAT OR feebus_present = FB_RESET) THEN
            output_next := OS_WAITIN;
          ELSIF (trigger = '1') THEN
            output_next := OS_TXDATA;
          ELSE
            output_next := OS_TXINGAP;
          END IF;
        WHEN OS_WAITIN =>
          IF (feebus_present = FB_INPUT) THEN
            output_next := OS_IDLE;
          ELSE
            output_next := OS_WAITIN;
          END IF;
      END CASE;
      output_present := output_next;
      pg_enable      <= bool2sl(output_next = OS_TXDATA) AND event_read;
      im_enable      <= bool2sl(output_next = OS_TXDATA) AND block_read;
      gap_active     <= bool2sl(output_next = OS_TXINGAP);

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

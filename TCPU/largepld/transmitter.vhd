--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: transmitter.vhd,v 1.1.1.1 2004-12-03 19:29:46 tofp Exp $
--******************************************************************************
--*  TRANSMITTER.VHD
--*
--*
--*  REVISION HISTORY:
--*    12-Oct-2001 CS  Original coding
--*     2-May-2002 CS  TXINGAP before TXDATA (fix trigger problem)
--*    31-Oct-2002 CS  Internal memory is added to the data path
--*
--******************************************************************************

library ieee;
use ieee.std_logic_1164.all;

entity transmitter is
  port (
    clock      : in  std_logic;
    arstn      : in  std_logic;
    trigger    : in  std_logic;
    gap_active : out std_logic;
    block_read : in  std_logic;
    event_read : in  std_logic;
    reg_read   : in  std_logic;
    reg_addr   : in  std_logic_vector ( 5 downto 0);
    tid        : in  std_logic_vector ( 3 downto 0);
    ps_reg     : in  std_logic_vector ( 7 downto 0);
    bl_reg     : in  std_logic_vector ( 7 downto 0);
    dt_reg     : in  std_logic_vector ( 7 downto 0);
    fc_reg     : in  std_logic_vector ( 7 downto 0);
    te_reg     : in  std_logic_vector ( 7 downto 0);
    xx_reg     : in  std_logic_vector ( 7 downto 0);
    pg_dout    : in  std_logic_vector (32 downto 0);
    pg_doutval : in  std_logic;
    pg_enable  : out std_logic;
    im_dout    : in  std_logic_vector (32 downto 0);
    im_doutval : in  std_logic;
    im_enable  : out std_logic;
    foD        : out std_logic_vector (31 downto 0);
    foTEN_N    : out std_logic;
    foCTRL_N   : out std_logic;
    fiDIR      : in  std_logic;
    fiBEN_N    : in  std_logic;
    fiLF_N     : in  std_logic
  );
end transmitter;

library ieee;
use ieee.std_logic_1164.all;
use work.my_conversions.all;
use work.my_utilities.all;

architecture SYN of transmitter is

  constant FESTW : std_logic_vector := "01000100";

  type output_state is (
    OS_IDLE,
    OS_WAITOUT,
    OS_TXSTATUS,
    OS_TXDATA,
    OS_TXINGAP,
    OS_WAITIN
  );

  type feebus_state is (
    FB_INPUT,
    FB_FLOAT,
    FB_OUTPUT,
    FB_RESET
  );

begin

  main : process (clock, arstn)

    variable datao          : std_logic_vector (32 downto 0);
    variable datao_valid    : std_logic;
    variable st_dout        : std_logic_vector (32 downto 0);
    variable b_block_end    : boolean;
    variable reg_read_req   : std_logic;
    variable output_present : output_state;
    variable output_next    : output_state;
    variable feebus_present : feebus_state;
    variable feebus_next    : feebus_state;

  begin
    if (arstn = '0') then

      gap_active <= '0';
      pg_enable  <= '0';
      im_enable  <= '0';
      foD        <= (others => '0');
      foTEN_N    <= '1';
      foCTRL_N   <= '1';

      datao          := (others => '0');
      datao_valid    := '0';
      st_dout        := (others => '0');
      b_block_end    := false;
      reg_read_req   := '0';
      output_present := OS_IDLE;
      output_next    := OS_IDLE;
      feebus_present := FB_INPUT;
      feebus_next    := FB_INPUT;

    elsif (clock'event and clock = '1') then

      if (output_present = OS_TXSTATUS) then
        datao       := st_dout;
        datao_valid := '1';
        b_block_end := false;
      elsif (output_present = OS_TXDATA) then
        if block_read = '1' then
          datao       := im_dout;
          datao_valid := im_doutval;
          b_block_end := (im_dout(32) = '1' and im_doutval = '1');
        else
          datao       := pg_dout;
          datao_valid := pg_doutval;
          b_block_end := (pg_dout(32) = '1' and pg_doutval = '1');
        end if;
      else
        datao         := (others => '0');
        datao_valid   := '0';
      end if;

      foD      <= datao(31 downto 0);
      foCTRL_N <= not (datao_valid and datao(32));
      foTEN_N  <= not (datao_valid);

      case reg_addr(2 downto 0) is
        when "000" =>
          st_dout := "1000000000000" & ps_reg & tid & FESTW;
        when "001" =>
          st_dout := "1000000000000" & bl_reg & tid & FESTW;
        when "010" =>
          st_dout := "1000000000000" & dt_reg & tid & FESTW;
        when "011" =>
          st_dout := "1000000000000" & fc_reg & tid & FESTW;
        when "100" =>
          st_dout := "1000000000000" & te_reg & tid & FESTW;
        when "101" =>
          st_dout := "1000000000000" & xx_reg & tid & FESTW;
        when others =>
          st_dout := "1000000000000" & "00000000" & tid & FESTW;
      end case;

      if (reg_read = '1') and (reg_read_req = '0') then
        reg_read_req := '1';
      elsif (output_present = OS_TXSTATUS) then
        reg_read_req := '0';
      end if;

      case output_present is
        when OS_IDLE =>
          if (feebus_present = FB_FLOAT) then
            output_next := OS_WAITOUT;
          else
            output_next := OS_IDLE;
          end if;
        when OS_WAITOUT =>
          if (feebus_present = FB_OUTPUT) then
            if (reg_read_req = '1') then
              output_next := OS_TXSTATUS;
            elsif (block_read = '1') then
              output_next := OS_TXDATA;
            elsif (event_read = '1') then
              output_next := OS_TXINGAP;
            else
              output_next := OS_WAITIN;
            end if;
          elsif (feebus_present = FB_INPUT) then
            output_next := OS_IDLE;
          else
            output_next := OS_WAITOUT;
          end if;
        when OS_TXSTATUS =>
          output_next := OS_WAITIN;
        when OS_TXDATA =>
          if (feebus_present = FB_FLOAT or feebus_present = FB_RESET) then
            output_next := OS_WAITIN;
          elsif (block_read = '1') and (b_block_end) then
            output_next := OS_WAITIN;
          elsif (event_read = '1') and (b_block_end) then
            output_next := OS_TXINGAP;
          else
            output_next := OS_TXDATA;
          end if;
        when OS_TXINGAP =>
          if (feebus_present = FB_FLOAT or feebus_present = FB_RESET) then
            output_next := OS_WAITIN;
          elsif (trigger = '1') then
            output_next := OS_TXDATA;
          else
            output_next := OS_TXINGAP;
          end if;
        when OS_WAITIN =>
          if (feebus_present = FB_INPUT) then
            output_next := OS_IDLE;
          else
            output_next := OS_WAITIN;
          end if;
      end case;
      output_present := output_next;
      pg_enable  <= bool2sl(output_next = OS_TXDATA) and event_read;
      im_enable  <= bool2sl(output_next = OS_TXDATA) and block_read;
      gap_active <= bool2sl(output_next = OS_TXINGAP);

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

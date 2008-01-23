-- $Id: ser_rdo.vhd,v 1.4 2008-01-23 22:58:02 jschamba Exp $

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera;
USE altera.altera_primitives_components.ALL;

--  Entity Declaration
ENTITY ser_rdo IS PORT (
  strb_out       : IN  std_logic;       -- strobe_out from TDC daisy chain
  token_out      : IN  std_logic;       -- token_out from TDC daisy chain
  ser_out        : IN  std_logic;       -- serial_out from TDC daisy chain
  rdout_en       : IN  std_logic;       -- readout rdout_en
  SW             : IN  std_logic;       -- input from switch (now used as half-tray)
  reset          : IN  std_logic;       -- state machine reset (active high)
  token_in       : OUT std_logic;       -- token_in to TDC daisy chain
  rdo_32b_data   : OUT std_logic_vector(31 DOWNTO 0);  -- parallel data from shift register 
  rdo_data_valid : OUT std_logic        -- used as wrreq for FIFO
  );       
END ser_rdo;

-- Architecture body
ARCHITECTURE a OF ser_rdo IS
  
  TYPE   SState_type IS (s1, s2, s3a, s3, s4, s5, s6, s7, s8);
  SIGNAL sState : SState_type;

  SIGNAL token_cap     : std_logic;
  SIGNAL shift_en      : std_logic;
  SIGNAL rdo_shift_q   : std_logic_vector (31 DOWNTO 0);
  SIGNAL rdo_separator : std_logic_vector (31 DOWNTO 0);
  SIGNAL rdreq_sig     : std_logic;
  SIGNAL s_aclr        : std_logic;
  SIGNAL inv_strb_out  : std_logic;

BEGIN

  -- Process Statements

  -- serial readout state machine
  --       state machine to control serial readout of TDC:
  --               - wait for rdout_en to go high (s1)
  --               - issue token to TDC daisy chain (s2)
  --               - reset ser_ctr to 0,
  --                 Clear shift register
  --                 wait for the Serial_Out pin of the 
  --                 TDC to go hi (indicating "start of data"),
  --                 or wait for the token to come back out
  --                 of the TDC (indicating "no data") (s3).
  --                 In case of "no data", just finish by going to s7
  --               - read 32 bits from "Serial_Out" pin into
  --                 shift register (s4)
  --               - clock shift register into FIFO (s5)
  --               - wait one clock tick and go back to s3 for next data item 
  --                 
  --               - when no more data, clock separator word into FIFO
  --                 make sure trigger signal is low again
  --                 go to beginning for next trigger (s7 & s8)
  --                       
  PROCESS (reset, strb_out)
    VARIABLE ser_ctr  : integer RANGE 0 TO 32;
    VARIABLE item_ctr : integer RANGE 0 TO 511;
    VARIABLE rdoutCtr : integer RANGE 0 TO 256;
  BEGIN
    IF (reset = '1') THEN
      sState   <= s1;
      ser_ctr  := 0;
      rdoutCtr := 0;
      
    ELSIF (strb_out'event AND strb_out = '1') THEN
      token_in                   <= '0';
      shift_en                   <= '0';
      rdo_32b_data               <= rdo_shift_q;
      rdo_data_valid             <= '0';
      ser_ctr                    := ser_ctr + 1;
      -- readout separator at end of readout:
      rdo_separator(15 DOWNTO 8) <= CONV_STD_LOGIC_VECTOR(item_ctr, 8);
      rdo_separator(7 DOWNTO 0)  <= CONV_STD_LOGIC_VECTOR(rdoutCtr, 8);

      CASE sState IS
        WHEN s1 =>
          ser_ctr := 0;
          IF (rdout_en = '1') THEN
            sState <= s2;
          END IF;
        WHEN s2 =>
          rdo_32b_data (31 DOWNTO 30) <= "11";
          rdo_32b_data (29 DOWNTO 1)  <= (OTHERS => '0');
          rdo_32b_data (0)            <= SW;

          rdoutCtr := rdoutCtr + 1;
          item_ctr := 0;
          token_in <= '1';
          sState   <= s3a;
        WHEN s3a =>                     -- use this state to strobe geogr. word
          ser_ctr := 0;

          rdo_32b_data (31 DOWNTO 30) <= "11";
          rdo_32b_data (29 DOWNTO 1)  <= (OTHERS => '0');
          rdo_32b_data (0)            <= SW;

          IF (ser_out = '1') THEN
            item_ctr       := item_ctr + 1;
            rdo_data_valid <= '1';      -- strobe Geographical data word
            sState         <= s4;
          ELSIF (token_cap = '1') THEN
            sState <= s7;
          END IF;
        WHEN s3 =>                      -- same state as 3, but w/out geogr. word
          ser_ctr := 0;

          IF (ser_out = '1') THEN
            item_ctr       := item_ctr + 1;
            sState         <= s4;
          ELSIF (token_cap = '1') THEN
            sState <= s7;
          END IF;
        WHEN s4 =>
          shift_en <= '1';
          IF (ser_ctr = 32) THEN
            sState <= s5;
          END IF;
        WHEN s5 =>
          IF (item_ctr < 253) THEN
            rdo_data_valid <= '1';        -- write data to upstream fifos
          ELSE
            item_ctr := 254;
          END IF;
          sState         <= s6;
        WHEN s6 =>
          sState <= s3;
        WHEN s7 =>
          rdo_32b_data <= rdo_separator;
          sState       <= s8;
          
        WHEN s8 =>
          rdo_32b_data   <= rdo_separator;
          rdo_data_valid <= '1';        -- write to upstream fifos

          sState <= s1;
      END CASE;
    END IF;
  END PROCESS;

  -- readout separator at end of readout:
  rdo_separator(31 DOWNTO 28) <= X"E";
  rdo_separator(27 DOWNTO 25) <= (OTHERS => '0');
  rdo_separator(24)           <= SW;
  rdo_separator(23 DOWNTO 16) <= (OTHERS => '0');


  -- latch the token coming back from the TDC
  dff_inst: PROCESS (strb_out, reset) IS
  BEGIN
    IF reset = '1' THEN                 -- asynchronous reset (active high)
      token_cap <= '0';
    ELSIF strb_out'event AND strb_out = '1' THEN  -- rising clock edge
      token_cap <= token_out;
    END IF;
  END PROCESS dff_inst;

  -- shift register to shift in the serial TDC data
  rdo_shift : LPM_SHIFTREG
    GENERIC MAP (
      lpm_type      => "LPM_SHIFTREG",
      lpm_width     => 32,
      lpm_direction => "LEFT")      
    PORT MAP (
      clock   => inv_strb_out,
      shiftin => ser_out,
      q       => rdo_shift_q,
      enable  => shift_en,
      aclr    => s_aclr);

  -- shift register clear when s3
  s_aclr <= '1' WHEN sState = s3 ELSE '0';

  -- shift register clocked by trailing edge of strobe
  inv_strb_out <= NOT strb_out;

END a;


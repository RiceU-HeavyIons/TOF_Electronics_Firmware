-- $Id: serdes_reader.vhd,v 1.12 2008-01-29 17:09:51 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : Serdes Reader
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_reader.vhd
-- Author     : 
-- Company    : 
-- Created    : 2007-11-21
-- Last update: 2008-01-29
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Reads the data from the Serdes FPGA and generates the
--              necessary signals to latch it into a (dual clock) FIFO
-------------------------------------------------------------------------------
-- Copyright (c) 2007 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2007-11-21  1.0      jschamba        Created
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera;
USE altera.altera_primitives_components.ALL;
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

ENTITY serdes_reader IS
  
  PORT (
    clk80mhz            : IN  std_logic;
    areset_n            : IN  std_logic;
    sync_q              : IN  std_logic_vector(16 DOWNTO 0);
    ser_status          : IN  std_logic_vector (3 DOWNTO 0);
    fifo_empty          : IN  std_logic;
    outfifo_almost_full : IN  boolean;
    evt_trg             : IN  std_logic;
    triggerWord         : IN  std_logic_vector (19 DOWNTO 0);
    trgFifo_empty       : IN  std_logic;
    trgFifo_q           : IN  std_logic_vector (19 DOWNTO 0);
    timeout             : IN  std_logic;
    timeout_clr         : OUT std_logic;
    serSel              : OUT std_logic_vector (2 DOWNTO 0);
    trgFifo_rdreq       : OUT std_logic;
    busy                : OUT std_logic;  -- active low
    rdsel_out           : OUT std_logic_vector(1 DOWNTO 0);
    rdreq_out           : OUT std_logic;
    wrreq_out           : OUT std_logic;  -- assuming FIFO clk is clk80mhz
    outdata             : OUT std_logic_vector(31 DOWNTO 0)
    );

END ENTITY serdes_reader;

ARCHITECTURE a OF serdes_reader IS

  COMPONENT ddio_in IS
    PORT (
      datain    : IN  std_logic_vector (7 DOWNTO 0);
      inclock   : IN  std_logic;
      dataout_h : OUT std_logic_vector (7 DOWNTO 0);
      dataout_l : OUT std_logic_vector (7 DOWNTO 0));
  END COMPONENT ddio_in;

  SIGNAL s_outdata   : std_logic_vector (31 DOWNTO 0);
  SIGNAL s_wrreq_out : std_logic;

  SIGNAL block_end      : boolean;
  SIGNAL sl_areset_n    : std_logic;
  SIGNAL s_slatch       : std_logic;
  SIGNAL s_prelatch     : std_logic;
  SIGNAL shift_areset_n : std_logic;
  SIGNAL s_shiftout     : std_logic_vector (31 DOWNTO 0);
  SIGNAL ser_selector   : std_logic_vector (4 DOWNTO 0);

  TYPE TState_type IS (
    SWaitTrig,
    SLatchTrig,
    STagWrd,
    SChkChannel,
    SFifoChk,
    SRdSerA,
    SChgChannel,
    SDelay,
    SRdTrg,
    SEnd
    );
  SIGNAL TState : TState_type;
  
BEGIN  -- ARCHITECTURE a

  wrreq_out <= s_wrreq_out;
  outdata   <= s_outdata;

  rdsel_out <= ser_selector(1 DOWNTO 0);  -- lowest two bits = Serdes Channel
  serSel    <= ser_selector(4 DOWNTO 2);  -- upper 3 bits = Serdes Number
  
  -- create a delayed latch signal
  serdesLatch : PROCESS (clk80mhz, sl_areset_n) IS
  BEGIN
    IF sl_areset_n = '0' THEN           -- asynchronous reset (active low)
      s_slatch   <= '0';
      s_prelatch <= '0';
    ELSIF clk80mhz'event AND clk80mhz = '0' THEN  -- falling clock edge
      s_slatch   <= s_prelatch;
      s_prelatch <= sync_q(16);
    END IF;
  END PROCESS serdesLatch;

  -- use a shift register to make a 32 bit word out of the 16 bit stream
  shifter : PROCESS (clk80mhz, shift_areset_n) IS
  BEGIN
    IF shift_areset_n = '0' THEN        -- asynchronous reset (active low)
      s_shiftout <= (OTHERS => '0');
      
    ELSIF clk80mhz'event AND clk80mhz = '0' THEN  -- falling clock edge
      s_shiftout(31 DOWNTO 16) <= s_shiftout(15 DOWNTO 0);
      s_shiftout(15 DOWNTO 0)  <= sync_q(15 DOWNTO 0);
    END IF;
  END PROCESS shifter;


  -- use a state machine to control the Serdes read process
  rdoutControl : PROCESS (clk80mhz, areset_n) IS
    VARIABLE delayCtr : integer RANGE 0 TO 2047 := 0;
    VARIABLE chCtr    : integer RANGE 0 TO 3    := 0;
    VARIABLE serCtr   : integer RANGE 0 TO 31   := 0;
  BEGIN
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      s_outdata      <= (OTHERS => '0');
      rdreq_out      <= '0';
      block_end      <= false;
      TState         <= SWaitTrig;
      busy           <= '1';            -- default is "not busy"
      trgFifo_rdreq  <= '0';
      sl_areset_n    <= '0';
      shift_areset_n <= '0';
      ser_selector   <= (OTHERS => '0');
      chCtr          := 0;
      serCtr         := 0;
      timeout_clr    <= '1';
      
    ELSIF clk80mhz'event AND clk80mhz = '1' THEN  -- rising clock edge
      s_wrreq_out    <= '0';
      rdreq_out      <= '0';
      busy           <= '0';                      -- default is "busy"
      trgFifo_rdreq  <= '0';
      sl_areset_n    <= '0';
      shift_areset_n <= '1';
      timeout_clr    <= '1';
      
      CASE TState IS

        -- wait for trigger
        WHEN SWaitTrig =>
          ser_selector <= (OTHERS => '0');
          chCtr        := 0;
          serCtr       := 0;
          busy         <= '1';          -- "not busy" until trigger

          IF evt_trg = '1' THEN
            TState <= SLatchTrig;
          END IF;

          -- strobe current trigger word into FIFO
        WHEN SLatchTrig =>
          s_outdata(31 DOWNTO 20) <= X"A00";  -- trigger word
          s_outdata(19 DOWNTO 0)  <= triggerWord;
          s_wrreq_out             <= '1';

          TState <= STagWrd;

          -- strobe tag word into DDL Fifo
        WHEN STagWrd =>
          s_outdata   <= X"DEADFACE";
          s_wrreq_out <= '1';

          TState <= SChkChannel;

          -- check if channel is "locked"
        WHEN SChkChannel =>
          IF ser_status(chCtr) = '0' THEN  -- if NOT locked
            TState <= SChgChannel;
          ELSE
            TState <= SFifoChk;
          END IF;

          -- only continue, if there is enough space in the upstream FIFO
        WHEN SFifoChk =>
          IF (NOT outfifo_almost_full) THEN
            TState <= SRdSerA;
          END IF;

          -- deserialize the 16bit input stream into 32bit output
          -- words with appropriately timed write_request signals TO
          -- strobe the result into a FIFO.
          -- Stop when we see a word starting  with "0xE0" (the
          -- separator word generated by the 2nd cable on TCPU)
        WHEN SRdSerA =>
          rdreq_out   <= '1';           -- start reading
          sl_areset_n <= '1';
          timeout_clr <= s_slatch;      -- clear timeout on latch
          
          -- Condition for last word from that channel:
          IF (s_shiftout(15 DOWNTO 8) = X"E0") AND (s_prelatch = '1') THEN
            block_end <= true;
          END IF;

          s_outdata   <= s_shiftout;
          s_wrreq_out <= s_slatch;

          -- when finished, wait for next latch signal
          IF (block_end AND (s_slatch = '1')) OR (timeout = '1') THEN
            block_end <= false;
            TState    <= SChgChannel;
          END IF;

          -- move on to next channel from same Serdes FPGA
        WHEN SChgChannel =>
          delayCtr := 0;
          chCtr    := chCtr + 1;
          serCtr   := serCtr + 1;

          IF serCtr = 8 THEN            -- last channel: Serdes B, Channel 3
            TState <= SDelay;           -- move on
          ELSE                          -- otherwise repeat from SChkChannel
            ser_selector <= CONV_STD_LOGIC_VECTOR(serCtr, 5);
            TState       <= SChkChannel;
          END IF;

          -- delay for a while (~13 us)
        WHEN SDelay =>
          delayCtr := delayCtr + 1;
          IF delayCtr = 1024 THEN
            TState <= SRdTrg;
          END IF;

          -- emtpy the trigger FIFO into the DDL FIFO 
        WHEN SRdTrg =>
          s_outdata(31 DOWNTO 20) <= X"A00";  -- trigger word
          s_outdata(19 DOWNTO 0)  <= trgFifo_q;

          trgFifo_rdreq <= '1';
          s_wrreq_out   <= NOT trgFifo_empty;

          IF trgFifo_empty = '1' THEN
            TState <= SEnd;
          END IF;

          -- set up the "end" separator and strobe it into the FIFO
        WHEN SEnd =>
          s_outdata(31 DOWNTO 24) <= X"EA";
          s_outdata(23 DOWNTO 0)  <= (OTHERS => '0');
          s_wrreq_out             <= '1';

          TState <= SWaitTrig;          -- return to the beginning

          -- this should never happen:
        WHEN OTHERS =>
          TState <= SWaitTrig;
          
      END CASE;
    END IF;
  END PROCESS rdoutControl;
  
END ARCHITECTURE a;
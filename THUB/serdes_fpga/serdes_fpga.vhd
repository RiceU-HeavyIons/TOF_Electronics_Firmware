-- $Id: serdes_fpga.vhd,v 1.6 2007-04-11 15:28:00 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_fpga.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2005-12-19
-- Last update: 2007-04-10
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top Level Component for the THUB SERDES FPGAs
-------------------------------------------------------------------------------
-- Copyright (c) 2005 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2005-12-19  1.0      jschamba        Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.ALL;
LIBRARY lpm;
USE lpm.lpm_components.ALL;
LIBRARY altera;
USE altera.altera_primitives_components.ALL;
USE work.my_conversions.ALL;
USE work.my_utilities.ALL;

ENTITY serdes_fpga IS
  PORT
    (
      clk                                                : IN    std_logic;  -- Master clock
      -- ***** Mictor outputs *****
      mt                                                 : OUT   std_logic_vector(31 DOWNTO 0);
      mt_clk                                             : OUT   std_logic;
      -- ***** bus to main fpga *****
      ma                                                 : INOUT std_logic_vector(35 DOWNTO 0);
      m_all                                              : IN    std_logic_vector(3 DOWNTO 0);
      -- ***** SRAM *****
      -- ADDR[17] and ADDR[18] on schematic are actually TCK and TDO, so renamed 
      -- ADDR[19] and ADDR[20] to be ADDR[17] and ADDR[18], respectively
      sra_addr, srb_addr                                 : OUT   std_logic_vector(18 DOWNTO 0);
      sra_d                                              : INOUT std_logic_vector(31 DOWNTO 0);
      srb_d                                              : INOUT std_logic_vector(31 DOWNTO 0);
      sra_tck, srb_tck                                   : OUT   std_logic;  -- JTAG
      sra_tdo, srb_tdo                                   : IN    std_logic;  -- JTAG
      sra_rw, srb_rw                                     : OUT   std_logic;
      sra_oe_n, srb_oe_n                                 : OUT   std_logic;
      sra_bw, srb_bw                                     : OUT   std_logic_vector(3 DOWNTO 0);
      sra_adv, srb_adv                                   : OUT   std_logic;
      sra_clk, srb_clk                                   : OUT   std_logic;
      -- ***** SERDES *****
      ch0_rxd, ch1_rxd, ch2_rxd, ch3_rxd                 : IN    std_logic_vector(17 DOWNTO 0);
      ch0_txd, ch1_txd, ch2_txd, ch3_txd                 : OUT   std_logic_vector(17 DOWNTO 0);
      ch0_den, ch1_den, ch2_den, ch3_den                 : OUT   std_logic;
      ch0_ren, ch1_ren, ch2_ren, ch3_ren                 : OUT   std_logic;
      ch0_sync, ch1_sync, ch2_sync, ch3_sync             : OUT   std_logic;
      ch0_tpwdn_n, ch1_tpwdn_n, ch2_tpwdn_n, ch3_tpwdn_n : OUT   std_logic;
      ch0_rpwdn_n, ch1_rpwdn_n, ch2_rpwdn_n, ch3_rpwdn_n : OUT   std_logic;
      ch0_tck, ch1_tck, ch2_tck, ch3_tck                 : OUT   std_logic;
      ch0_lock_n, ch1_lock_n, ch2_lock_n, ch3_lock_n     : IN    std_logic;
      ch0_refclk, ch1_refclk, ch2_refclk, ch3_refclk     : OUT   std_logic;
      ch0_rclk, ch1_rclk, ch2_rclk, ch3_rclk             : IN    std_logic;
      ch0_loc_le, ch1_loc_le, ch2_loc_le, ch3_loc_le     : OUT   std_logic;
      ch0_line_le, ch1_line_le, ch2_line_le, ch3_line_le : OUT   std_logic;
      -- ***** LEDs *****
      led                                                : OUT   std_logic_vector(1 DOWNTO 0);
      -- ***** test points *****
      dummy                                              : IN    std_logic;
      tp                                                 : IN    std_logic_vector(15 DOWNTO 2)

      );
END serdes_fpga;


ARCHITECTURE a OF serdes_fpga IS

  COMPONENT pll
    PORT
      (
        areset : IN  std_logic := '0';
        inclk0 : IN  std_logic := '0';
        c0     : OUT std_logic;
        c1     : OUT std_logic;
        locked : OUT std_logic
        );
  END COMPONENT;

  COMPONENT zbt_ctrl_top
    PORT (
      clk           : IN    std_logic;
      RESET_N       : IN    std_logic;  -- active LOW asynchronous reset
-- local bus interface
      ADDR          : IN    std_logic_vector(18 DOWNTO 0);
      DATA_IN       : IN    std_logic_vector(31 DOWNTO 0);
      DATA_OUT      : OUT   std_logic_vector(31 DOWNTO 0);
      RD_WR_N       : IN    std_logic;  -- active LOW write
      ADDR_ADV_LD_N : IN    std_logic;  -- advance/load address (active LOW load)
      DM            : IN    std_logic_vector(3 DOWNTO 0);  -- data mask bits                   
-- SRAM interface
      SA            : OUT   std_logic_vector(18 DOWNTO 0);  -- address bus to RAM   
      DQ            : INOUT std_logic_vector(31 DOWNTO 0);  -- data to/from RAM
      RW_N          : OUT   std_logic;  -- active LOW write
      ADV_LD_N      : OUT   std_logic;  -- active LOW load
      BW_N          : OUT   std_logic_vector(3 DOWNTO 0)  -- active LOW byte enables
      );
  END COMPONENT;

  COMPONENT LFSR IS
    PORT (
      RESETn : IN  std_logic;
      clock  : IN  std_logic;
      d      : OUT std_logic_vector(16 DOWNTO 0));
  END COMPONENT LFSR;

  SIGNAL globalclk         : std_logic;
  SIGNAL clk_160mhz        : std_logic;  -- PLL 4x output
  SIGNAL clkp_160mhz       : std_logic;  -- PLL 4x output with phase shift
  SIGNAL pll_locked        : std_logic;
  SIGNAL counter_q         : std_logic_vector (16 DOWNTO 0);
  SIGNAL lsfr_d            : std_logic_vector (16 DOWNTO 0);
  SIGNAL serdes_data       : std_logic_vector (16 DOWNTO 0);
  SIGNAL txfifo_rdreq      : std_logic;
  SIGNAL txfifo_q          : std_logic_vector (17 DOWNTO 0);
  SIGNAL txfifo_full       : std_logic;
  SIGNAL txfifo_empty      : std_logic;
  SIGNAL rxfifo_rdreq      : std_logic;
  SIGNAL rxfifo_q          : std_logic_vector (17 DOWNTO 0);
  SIGNAL rxfifo_full       : std_logic;
  SIGNAL rxfifo_empty      : std_logic;
  SIGNAL tx_xor_rx         : std_logic_vector (17 DOWNTO 0);
  SIGNAL counter25b_q      : std_logic_vector (24 DOWNTO 0);
  SIGNAL sync_dip          : std_logic;
  SIGNAL local_aclr        : std_logic;
  SIGNAL err_aclr          : std_logic;
  SIGNAL clk20mhz          : std_logic;
  SIGNAL div2out           : std_logic;
  SIGNAL serdes_clk        : std_logic;
  SIGNAL ctr_enable        : std_logic;
  SIGNAL s_rw_n            : std_logic;
  SIGNAL s_addr_adv_ld_n   : std_logic;
  SIGNAL s_dm              : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_sram_dataout    : std_logic_vector(31 DOWNTO 0);
  SIGNAL areset_n          : std_logic;
  SIGNAL s_shiftout        : std_logic_vector(31 DOWNTO 0);
  SIGNAL s_ch0valid        : std_logic;
  SIGNAL s_ch0_latch       : std_logic;
  SIGNAL s_ch0fifo_rdreq   : std_logic;
  SIGNAL s_ch0fifo_aclr    : std_logic;
  SIGNAL s_ch0fifo_wrreq   : std_logic;
  SIGNAL s_ch0fifo_rdempty : std_logic;
  SIGNAL s_ch0fifo_q       : std_logic_vector(31 DOWNTO 0);
  SIGNAL s_txfifo_q        : std_logic_vector(16 DOWNTO 0);
  SIGNAL s_txfifo_aclr     : std_logic;
  SIGNAL s_txfifo_rdreq    : std_logic;
  SIGNAL s_txfifo_empty    : std_logic;
  SIGNAL s_rxfifo_q        : std_logic_vector(16 DOWNTO 0);
  SIGNAL s_rxfifo_aclr     : std_logic;
  SIGNAL s_rxfifo_rdreq    : std_logic;
  SIGNAL s_rxfifo_wrreq    : std_logic;
  SIGNAL s_rxfifo_empty    : std_logic;
  SIGNAL s_errorctr        : std_logic_vector(31 DOWNTO 0);
  SIGNAL s_error           : std_logic;
  SIGNAL s_ctr_aclr        : std_logic;
  SIGNAL s_ch0_locked      : std_logic;

  TYPE   State_type IS (State0, State1, State1a, State2, State3);
  SIGNAL state : State_type;

  TYPE poweron_state IS (
    PO_INIT,
    PO_WAIT,
    PO_SYNC,
    PO_LOCKED
    );

BEGIN

  areset_n <= '1';  -- asynchronous global reset, active low

  global_clk_buffer : global PORT MAP (a_in => clk, a_out => globalclk);

  ma <= (OTHERS => 'Z');                -- tri-state I/O to master FPGA

  -- create 20 MHz clock with TFF:
  div2 : TFF PORT MAP (
    t    => '1',
    clk  => globalclk,
    clrn => '1',
    prn  => '1',
    q    => div2out);

  global_clk_buffer2 : global PORT MAP (a_in => div2out, a_out => clk20mhz);

  -- PLL
  pll_instance : pll PORT MAP (
    areset => '0',
    inclk0 => clk,
    c0     => clk_160mhz,
    c1     => clkp_160mhz,
    locked => pll_locked);

  serdes_clk <= clk20mhz;
  -- serdes_clk <= '0';
  -- serdes_clk <= globalclk;

  -- LEDs
  -- led <= "10"; -- used below to show lock status

  -- Mictor defaults
  -- mt     <= (OTHERS => '0');
  -- mt(30 DOWNTO 18) <= (OTHERS => '0');
  -- mt_clk <= globalclk;
  -- others are used for SERDES channel-1 display below

  -- SRAM defaults
  sra_addr <= (OTHERS => '0');
  srb_addr <= (OTHERS => '0');
  sra_tck  <= '0';
  srb_tck  <= '0';
  sra_rw   <= '1';
  srb_rw   <= '1';
  sra_oe_n <= '0';
  srb_oe_n <= '0';
  sra_bw   <= (OTHERS => '0');
  srb_bw   <= (OTHERS => '0');
  sra_adv  <= '0';
  srb_adv  <= '0';
  sra_clk  <= clk_160mhz;
  srb_clk  <= clk_160mhz;

  sra_d <= (OTHERS => 'Z');
  srb_d <= (OTHERS => 'Z');

  -- counter to divide clock
--  counter25b : lpm_counter
--    GENERIC MAP (
--      LPM_WIDTH     => 25,
--      LPM_TYPE      => "LPM_COUNTER",
--      LPM_DIRECTION => "UP")
--    PORT MAP (
--      clock => globalclk,
--      q     => counter25b_q);

--  dip_latch : PROCESS (counter25b_q(24)) IS
--  BEGIN  -- PROCESS dip_latch
--    IF (counter25b_q(24)'event AND (counter25b_q(24) = '1')) THEN
--      sync_dip <= m_all(0);
--    END IF;
--  END PROCESS dip_latch;

  -- SERDES utilities

  local_aclr <= (NOT s_ch0_locked) OR s_error;  -- clear when NOT locked or receive error

  -- Counter as data input to channel 0 TX
  counter17b : lpm_counter GENERIC MAP (
    LPM_WIDTH     => 17,
    LPM_TYPE      => "LPM_COUNTER",
    LPM_DIRECTION => "UP")
    PORT MAP (
      clock  => serdes_clk,
      q      => counter_q,
      clk_en => '1',
      aclr   => s_ctr_aclr);

  -- LFSR as data generator (17 bit pseudo random numbers)
  datagen : LFSR
    PORT MAP (
      RESETn => '1',
      clock  => serdes_clk,
      d      => lsfr_d);


  -- SERDES defaults
  serdes_data <= counter_q;
  -- serdes_data <= lsfr_d;

  -- channel 0
  ch0_den              <= m_all(0);     -- tx enabled by dip switch 0
  ch0_ren              <= m_all(0);     -- rx enabled by dip switch 0
  ch0_loc_le           <= '0';
  ch0_line_le          <= '0';
  ch0_txd(16 DOWNTO 0) <= serdes_data;
  ch0_txd(17)          <= s_ch0_locked;
  led(0)               <= ch0_lock_n;

  -- channel 1
  ch1_den              <= m_all(1);     -- tx enabled by dip switch 1
  ch1_ren              <= m_all(1);     -- rx enabled by dip switch 1
  ch1_sync             <= '0';
  ch1_loc_le           <= '0';          -- local loopback disabled
  ch1_line_le          <= '0';          -- line loopback disabled
  ch1_txd(16 DOWNTO 0) <= serdes_data;
  ch1_txd(17)          <= s_ch0_locked;
  led(1)               <= ch1_lock_n;

  -- channel 2
  ch2_den     <= '0';
  ch2_ren     <= '0';
  ch2_sync    <= '0';
  ch2_tpwdn_n <= '0';
  ch2_rpwdn_n <= '0';
  ch2_loc_le  <= '0';
  ch2_line_le <= '0';
  ch2_txd     <= (OTHERS => '0');

  -- channel 3
  ch3_den     <= '0';
  ch3_ren     <= '0';
  ch3_sync    <= '0';
  ch3_tpwdn_n <= '0';
  ch3_rpwdn_n <= '0';
  ch3_loc_le  <= '0';
  ch3_line_le <= '0';
  ch3_txd     <= (OTHERS => '0');


  -- tx clocks and rx refclocks
  -- all of these clocks come directly to the SERDES
  -- daughtercard (differentially), so just put GND ON
  -- those lines if not used.
  -- when resistor is changed to this path, assign proper clock here:
  ch0_tck    <= serdes_clk;
  ch1_tck    <= serdes_clk;
  ch2_tck    <= serdes_clk;
  ch3_tck    <= serdes_clk;
  ch0_refclk <= serdes_clk;
  ch1_refclk <= serdes_clk;
  ch2_refclk <= serdes_clk;
  ch3_refclk <= serdes_clk;


  -- latch tx data into a single clock 17bit fifo for later comparison

  -- s_txfifo_aclr <= local_aclr;
  -- s_rxfifo_aclr <= local_aclr;

  txfifo : scfifo
    GENERIC MAP (
      add_ram_output_register => "ON",
      intended_device_family  => "Cyclone II",
      lpm_numwords            => 256,
      lpm_showahead           => "ON",
      lpm_type                => "scfifo",
      lpm_width               => 17,
      lpm_widthu              => 8,
      overflow_checking       => "ON",
      underflow_checking      => "ON",
      use_eab                 => "ON"
      )
    PORT MAP (
      rdreq => s_txfifo_rdreq,
      aclr  => s_txfifo_aclr,
      clock => ch0_rclk,                -- serdes_clk,
      wrreq => s_ch0_locked,
      data  => serdes_data,
      empty => s_txfifo_empty,
      q     => s_txfifo_q
      );

  rxfifo : scfifo
    GENERIC MAP (
      add_ram_output_register => "ON",
      intended_device_family  => "Cyclone II",
      lpm_numwords            => 256,
      lpm_showahead           => "ON",
      lpm_type                => "scfifo",
      lpm_width               => 17,
      lpm_widthu              => 8,
      overflow_checking       => "ON",
      underflow_checking      => "ON",
      use_eab                 => "ON"
      )
    PORT MAP (
      rdreq => s_rxfifo_rdreq,
      aclr  => s_rxfifo_aclr,
      clock => ch0_rclk,
      wrreq => s_rxfifo_wrreq,
      data  => ch0_rxd(16 DOWNTO 0),
      empty => s_rxfifo_empty,
      q     => s_rxfifo_q
      );

  s_rxfifo_wrreq <= ch0_rxd(17) AND s_ch0_locked;
  
  data_compare : PROCESS (serdes_clk, areset_n) IS
    VARIABLE b_ch0valid : boolean := false;
  BEGIN  -- PROCESS shiftreg1
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      s_errorctr     <= (OTHERS => '0');
      s_txfifo_rdreq <= '0';
      s_rxfifo_rdreq <= '0';
      s_error        <= '0';
      
    ELSIF serdes_clk'event AND serdes_clk = '0' THEN  -- trailing clock edge
      s_txfifo_rdreq <= '0';
      s_rxfifo_rdreq <= '0';
      s_error        <= '0';
      IF ((s_rxfifo_empty = '0') AND (s_txfifo_empty = '0')) THEN
        IF (s_rxfifo_q /= s_txfifo_q) THEN
          s_errorctr <= s_errorctr + 1;
          s_error    <= '1';
        END IF;
        s_txfifo_rdreq <= '1';
        s_rxfifo_rdreq <= '1';
      END IF;
      
    END IF;
  END PROCESS data_compare;

  mt(15 DOWNTO 0)  <= s_rxfifo_q(15 DOWNTO 0);
  mt(23 DOWNTO 16) <= s_txfifo_q(7 DOWNTO 0);
  mt(30 DOWNTO 24) <= s_errorctr(6 DOWNTO 0);
  mt(31)           <= s_ch0_locked;

  -- create a latch signal that has half the frequency of ch0_rclk
  -- reset, when there is nothing being sent (ch0valid = 0)
  ch0_latch : TFF PORT MAP (
    t    => '1',
    clk  => ch0_rclk,
    clrn => s_ch0valid,
    prn  => '1',
    q    => s_ch0_latch);

  -- shift the incoming data 16 bits at a time on each ch0_rclk
  -- reset when nothing is being sent (ch0valid = 0)

  -- purpose: Shift register
  -- type   : sequential
  -- inputs : ch0_rclk, areset_n
  -- outputs: 
  shiftreg1 : PROCESS (ch0_rclk, areset_n) IS
    VARIABLE b_ch0valid : boolean := false;
  BEGIN  -- PROCESS shiftreg1
    IF areset_n = '0' THEN              -- asynchronous reset (active low)
      s_ch0valid <= '0';
      s_shiftout <= (OTHERS => '0');
      b_ch0valid := false;
      
    ELSIF ch0_rclk'event AND ch0_rclk = '1' THEN  -- rising clock edge
      b_ch0valid := (ch0_rxd(17) = '1');
      s_ch0valid <= bool2sl(b_ch0valid);

      IF b_ch0valid THEN                -- use highest bit as shift enable
        s_shiftout(31 DOWNTO 16) <= s_shiftout(15 DOWNTO 0);
        s_shiftout(15 DOWNTO 0)  <= ch0_rxd(15 DOWNTO 0);
      END IF;
      
    END IF;
  END PROCESS shiftreg1;

  mt_clk <= serdes_clk;
  -- mt     <= s_shiftout;                 -- to mictor for display

  -- latch the received data into a dual clock 32bit fifo with the above
  -- generated latch SIGNAL
  -- display output of FIFO to mictor
  ch0_fifo : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_hint               => "MAXIMIZE_SPEED=5",
      lpm_numwords           => 256,
      lpm_showahead          => "OFF",
      lpm_type               => "dcfifo",
      lpm_width              => 32,
      lpm_widthu             => 8,
      overflow_checking      => "ON",
      rdsync_delaypipe       => 4,
      underflow_checking     => "ON",
      wrsync_delaypipe       => 4)
    PORT MAP (
      wrclk   => ch0_rclk,
      rdreq   => s_ch0fifo_rdreq,
      aclr    => s_ch0fifo_aclr,
      rdclk   => globalclk,
      wrreq   => s_ch0fifo_wrreq,
      data    => s_shiftout,
      rdempty => s_ch0fifo_rdempty,
      q       => s_ch0fifo_q);

  s_ch0fifo_aclr  <= local_aclr;
  s_ch0fifo_wrreq <= s_ch0_latch;  -- will be disabled when FIFO is full due to overflow checking
  s_ch0fifo_rdreq <= NOT s_ch0fifo_rdempty;


  -- purpose: power on state machine for channel 0
  -- type   : sequential
  -- inputs : globalclk, areset
  -- outputs: 
  poweron_ch0 : PROCESS (globalclk, areset_n) IS

    VARIABLE poweron0_present : poweron_state;
    VARIABLE poweron0_next    : poweron_state;
    
  BEGIN  -- PROCESS poweron_ch0
    IF areset_n = '0' THEN              -- asynchronous reset (active low)

      poweron0_present := PO_INIT;
      poweron0_next    := PO_INIT;
      ch0_tpwdn_n      <= '0';          -- tx powered down
      ch0_rpwdn_n      <= '0';          -- rx powered down
      ch0_sync         <= '0';          -- sync turned off
      s_ch0_locked     <= '0';
      s_txfifo_aclr    <= '1';
      s_rxfifo_aclr    <= '1';
      
    ELSIF globalclk'event AND globalclk = '1' THEN  -- rising clock edge

      ch0_tpwdn_n   <= '0';             -- tx powered down
      ch0_rpwdn_n   <= '0';             -- rx powered down
      ch0_sync      <= '0';
      s_ch0_locked  <= '0';
      s_txfifo_aclr <= '1';
      s_rxfifo_aclr <= '1';

      CASE poweron0_present IS
        WHEN PO_INIT =>
          s_ctr_aclr <= '1';
          IF pll_locked = '1' THEN
            poweron0_next := PO_WAIT;
          END IF;
        WHEN PO_WAIT =>
          ch0_tpwdn_n <= '1';           -- tx powered on
          ch0_sync    <= '1';           -- sync turned on
          s_ctr_aclr  <= '0';
          IF counter_q(16) = '1' THEN
            poweron0_next := PO_SYNC;
          END IF;
          
        WHEN PO_SYNC =>
          ch0_tpwdn_n <= '1';           -- tx powered on
          ch0_rpwdn_n <= '1';           -- rx powered on
          ch0_sync    <= '1';           -- sync turned on

          IF ch0_lock_n = '0' THEN
            poweron0_next := PO_LOCKED;
          END IF;
        WHEN PO_LOCKED =>
          ch0_tpwdn_n   <= '1';         -- tx powered on
          ch0_rpwdn_n   <= '1';         -- rx powered on
          s_ch0_locked  <= '1';
          s_txfifo_aclr <= '0';
          s_rxfifo_aclr <= '0';

          IF ((ch0_lock_n = '1') OR (ch1_lock_n = '1')) THEN
            poweron0_next := PO_INIT;
          END IF;
        WHEN OTHERS =>
          s_txfifo_aclr <= '0';
          s_rxfifo_aclr <= '0';
          ch0_rpwdn_n <= '1';           -- rx powered on
          ch0_tpwdn_n <= '1';           -- tx powered on

          poweron0_next := PO_LOCKED;
      END CASE;
      poweron0_present := poweron0_next;

    END IF;
  END PROCESS poweron_ch0;

  -- purpose: power on state machine for channel 1 (emulate the TCPU)
  -- type   : sequential
  -- inputs : globalclk, areset
  -- outputs: 
  poweron_ch1 : PROCESS (globalclk, areset_n) IS

    VARIABLE poweron1_present : poweron_state;
    VARIABLE poweron1_next    : poweron_state;
    
  BEGIN  -- PROCESS poweron_ch1
    IF areset_n = '0' THEN              -- asynchronous reset (active low)

      poweron1_present := PO_INIT;
      poweron1_next    := PO_INIT;
      ch1_tpwdn_n      <= '0';          -- tx powered down
      ch1_rpwdn_n      <= '0';          -- rx powered down
      
    ELSIF globalclk'event AND globalclk = '1' THEN  -- rising clock edge

      ch1_tpwdn_n <= '0';               -- tx powered down
      ch1_rpwdn_n <= '0';               -- rx powered down

      CASE poweron1_present IS
        WHEN PO_INIT =>
          IF pll_locked = '1' THEN
            poweron1_next := PO_WAIT;
          END IF;
        WHEN PO_WAIT =>
          ch1_rpwdn_n <= '1';           -- rx powered on
          poweron1_next := PO_SYNC;
        WHEN PO_SYNC =>
          ch1_rpwdn_n <= '1';           -- rx powered on

          IF ch1_lock_n = '0' THEN
            poweron1_next := PO_LOCKED;
          END IF;
        WHEN PO_LOCKED =>
          ch1_tpwdn_n <= '1';           -- tx powered on
          ch1_rpwdn_n <= '1';           -- rx powered on

          IF ch1_lock_n = '1' THEN
            poweron1_next := PO_INIT;
          END IF;
        WHEN OTHERS =>
          ch1_tpwdn_n <= '1';           -- tx powered on
          ch1_rpwdn_n <= '1';           -- rx powered on

          poweron1_next := PO_LOCKED;
      END CASE;
      poweron1_present := poweron1_next;
      
    END IF;
  END PROCESS poweron_ch1;

--  zbt_ctrl_top_inst1 : zbt_ctrl_top
--    PORT MAP (
--      clk                   => clkp_160mhz,
--      RESET_N               => pll_locked,
---- local bus interface
--      ADDR(15 DOWNTO 0)     => ma(15 DOWNTO 0),
--      ADDR(18 DOWNTO 16)    => (OTHERS => '0'),
--      DATA_IN(17 DOWNTO 0)  => ma(33 DOWNTO 16),
--      DATA_IN(31 DOWNTO 18) => (OTHERS => '0'),
--      DATA_OUT              => s_sram_dataout,
--      RD_WR_N               => s_rw_n,
--      ADDR_ADV_LD_N         => s_addr_adv_ld_n,
--      DM                    => s_dm,
---- SRAM interface
--      SA                    => srb_addr,     -- SRAM B
--      DQ                    => srb_d,
--      RW_N                  => srb_rw,
--      ADV_LD_N              => srb_adv,
--      BW_N                  => srb_bw
--      -- SA                    => sra_addr,  -- SRAM A
--      -- DQ                    => sra_d,
--      -- RW_N                  => sra_rw,
--      -- ADV_LD_N              => sra_adv,
--      -- BW_N                  => sra_bw
--      );

--  mt(15 DOWNTO 0) <= s_sram_dataout(15 DOWNTO 0);

--  sram_sm : PROCESS (clkp_160mhz, pll_locked) IS
--  BEGIN  -- PROCESS uc_fpga_sm
--    IF pll_locked = '0' THEN                            -- asynchronous reset (active low)
--      state           <= State0;
--      s_dm            <= (OTHERS => '0');
--      s_rw_n          <= '0';
--      s_addr_adv_ld_n <= '1';
--    ELSIF clkp_160mhz'event AND clkp_160mhz = '1' THEN  -- rising clock edge
--      s_dm            <= (OTHERS => '0');
--      s_rw_n          <= '0';
--      s_addr_adv_ld_n <= '1';
--      CASE state IS
--        WHEN State0 =>
--          IF ma(35) = '1' THEN
--            state <= State1;
--          END IF;
--        WHEN State1 =>
--          s_addr_adv_ld_n <= '0';
--          s_rw_n          <= ma(34);
--          s_dm            <= (OTHERS => '1');
--          state           <= State1a;
--        WHEN State1a =>                                 -- this state is for testing of the waveforms only
--          s_addr_adv_ld_n <= '0';
--          s_rw_n          <= ma(34);
--          s_dm            <= (OTHERS => '1');
--          state           <= State2;
--        WHEN State2 =>
--          s_addr_adv_ld_n <= '0';
--          state           <= State3;
--        WHEN State3 =>
--          IF ma(35) = '0' THEN
--            state <= State0;
--          END IF;
--      END CASE;
--    END IF;
--  END PROCESS sram_sm;

END a;

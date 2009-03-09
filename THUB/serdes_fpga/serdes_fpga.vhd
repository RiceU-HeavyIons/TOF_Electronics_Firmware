-- $Id: serdes_fpga.vhd,v 1.31 2009-03-09 15:29:22 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : SERDES_FPGA
-- Project    : 
-------------------------------------------------------------------------------
-- File       : serdes_fpga.vhd
-- Author     : J. Schambach
-- Company    : 
-- Created    : 2005-12-19
-- Last update: 2009-03-06
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
USE ieee.std_logic_arith.ALL;
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
      maO                                                : OUT   std_logic_vector(16 DOWNTO 0);
      maI                                                : IN    std_logic_vector(35 DOWNTO 17);
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
      tp                                                 : IN    std_logic_vector(15 DOWNTO 2)

      );
END serdes_fpga;


ARCHITECTURE a OF serdes_fpga IS

  COMPONENT serdes_poweron IS
    PORT (
      clk         : IN  std_logic;
      tpwdn_n     : OUT std_logic;
      rpwdn_n     : OUT std_logic;
      sync        : OUT std_logic;
      ch_lock_n   : IN  std_logic;
      ch_ready    : OUT std_logic;
      pll_locked  : IN  std_logic;
      rxd         : IN  std_logic_vector (17 DOWNTO 0);
      serdes_data : IN  std_logic_vector (17 DOWNTO 0);
      txd         : OUT std_logic_vector (17 DOWNTO 0);
      areset_n    : IN  std_logic);
  END COMPONENT serdes_poweron;

  COMPONENT smif IS
    PORT (
      clk40mhz   : IN  std_logic;
      clk20mhz   : IN  std_logic;
      datain     : IN  std_logic_vector(11 DOWNTO 0);
      data_type  : IN  std_logic_vector(3 DOWNTO 0);
      serdes_out : OUT std_logic_vector(17 DOWNTO 0);
      serdes_reg : OUT std_logic_vector(6 DOWNTO 0);
      geo_id0    : OUT std_logic_vector(6 DOWNTO 0);
      geo_id1    : OUT std_logic_vector(6 DOWNTO 0);
      geo_id2    : OUT std_logic_vector(6 DOWNTO 0);
      geo_id3    : OUT std_logic_vector(6 DOWNTO 0);
      trigger    : OUT std_logic;
      areset     : IN  std_logic);
  END COMPONENT smif;

  COMPONENT pll
    PORT
      (
        areset : IN  std_logic := '0';
        inclk0 : IN  std_logic := '0';
        c0     : OUT std_logic;
        c1     : OUT std_logic;
        c2     : OUT std_logic;
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

  COMPONENT mux17x4 IS
    PORT (
      data0x : IN  std_logic_vector (16 DOWNTO 0);
      data1x : IN  std_logic_vector (16 DOWNTO 0);
      data2x : IN  std_logic_vector (16 DOWNTO 0);
      data3x : IN  std_logic_vector (16 DOWNTO 0);
      sel    : IN  std_logic_vector (1 DOWNTO 0);
      result : OUT std_logic_vector (16 DOWNTO 0));
  END COMPONENT mux17x4;

  COMPONENT decoder IS
    PORT (
      input_sig : IN  std_logic;
      adr       : IN  std_logic_vector(1 DOWNTO 0);
      y         : OUT std_logic_vector(3 DOWNTO 0));
  END COMPONENT decoder;

  COMPONENT serdes_rcvr IS
    PORT (
      areset_n   : IN  std_logic;
      clk40mhz   : IN  std_logic;
      rdreq_in   : IN  std_logic;
      fifo_aclr  : IN  std_logic;
      ch_rclk    : IN  std_logic;
      ch_rxd     : IN  std_logic_vector (17 DOWNTO 0);
      geo_id     : IN  std_logic_vector (6 DOWNTO 0);
      dataout    : OUT std_logic_vector (15 DOWNTO 0);
      fifo_empty : OUT std_logic);
  END COMPONENT serdes_rcvr;

  COMPONENT ddio_out IS
    PORT (
      datain_h : IN  std_logic_vector (7 DOWNTO 0);
      datain_l : IN  std_logic_vector (7 DOWNTO 0);
      outclock : IN  std_logic;
      dataout  : OUT std_logic_vector (7 DOWNTO 0));
  END COMPONENT ddio_out;

  SIGNAL areset_n          : std_logic;
  SIGNAL globalclk         : std_logic;
  SIGNAL pll_20mhz         : std_logic;
  SIGNAL pll_80mhz         : std_logic;
  SIGNAL s_pll_80mhz       : std_logic;
  SIGNAL pll_160mhz        : std_logic;  -- PLL 4x output
  SIGNAL pll_160mhz_p      : std_logic;  -- PLL 4x output with phase shift
  SIGNAL clk20mhz          : std_logic;
  SIGNAL div2out           : std_logic := '0';
  SIGNAL serdes_clk        : std_logic;
  SIGNAL pll_locked        : std_logic;
  SIGNAL counter_q         : std_logic_vector (16 DOWNTO 0);
  SIGNAL lsfr_d            : std_logic_vector (16 DOWNTO 0);
  SIGNAL serdes_data       : std_logic_vector (17 DOWNTO 0);
  SIGNAL serdes_tst_data   : std_logic_vector (17 DOWNTO 0);
  SIGNAL txfifo_rdreq      : std_logic;
  SIGNAL txfifo_q          : std_logic_vector (17 DOWNTO 0);
  SIGNAL txfifo_full       : std_logic;
  SIGNAL txfifo_empty      : std_logic;
  SIGNAL rxfifo_rdreq      : std_logic;
  SIGNAL rxfifo_q          : std_logic_vector (17 DOWNTO 0);
  SIGNAL rxfifo_full       : std_logic;
  SIGNAL rxfifo_empty      : std_logic;
  SIGNAL ctr_enable        : std_logic;
  SIGNAL s_rw_n            : std_logic;
  SIGNAL s_addr_adv_ld_n   : std_logic;
  SIGNAL s_dm              : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_sram_dataout    : std_logic_vector(31 DOWNTO 0);
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
  SIGNAL s_ctr_aclr        : std_logic;
  SIGNAL s_ch0_locked      : std_logic;
  SIGNAL s_ch1_locked      : std_logic;
  SIGNAL s_ch2_locked      : std_logic;
  SIGNAL s_ch3_locked      : std_logic;
  SIGNAL s_send_data       : std_logic;
  SIGNAL s_smif_dataout    : std_logic_vector (15 DOWNTO 0);
  SIGNAL s_smif_fifo_empty : std_logic;
  SIGNAL s_smif_select     : std_logic_vector(1 DOWNTO 0);
  SIGNAL s_smif_rdenable   : std_logic;
  SIGNAL s_synced_rdenable : std_logic;
  SIGNAL s_smif_datain     : std_logic_vector(11 DOWNTO 0);
  SIGNAL s_smif_datatype   : std_logic_vector(3 DOWNTO 0);
  SIGNAL s_serdes_out      : std_logic_vector(17 DOWNTO 0);
  SIGNAL s_ch0_txd         : std_logic_vector(17 DOWNTO 0);
  SIGNAL s_ch1_txd         : std_logic_vector(17 DOWNTO 0);
  SIGNAL s_ch2_txd         : std_logic_vector(17 DOWNTO 0);
  SIGNAL s_ch3_txd         : std_logic_vector(17 DOWNTO 0);
  SIGNAL s_serdes_reg      : std_logic_vector(6 DOWNTO 0);
  SIGNAL s_smif_trigger    : std_logic;

  SIGNAL s_ch0fifo_rdreq : std_logic;
  SIGNAL s_ch0fifo_aclr  : std_logic;
  SIGNAL s_ch0fifo_empty : std_logic;
  SIGNAL s_ch0fifo_q     : std_logic_vector(15 DOWNTO 0);
  SIGNAL s_ch1fifo_rdreq : std_logic;
  SIGNAL s_ch1fifo_aclr  : std_logic;
  SIGNAL s_ch1fifo_empty : std_logic;
  SIGNAL s_ch1fifo_q     : std_logic_vector(15 DOWNTO 0);
  SIGNAL s_ch2fifo_rdreq : std_logic;
  SIGNAL s_ch2fifo_aclr  : std_logic;
  SIGNAL s_ch2fifo_empty : std_logic;
  SIGNAL s_ch2fifo_q     : std_logic_vector(15 DOWNTO 0);
  SIGNAL s_ch3fifo_rdreq : std_logic;
  SIGNAL s_ch3fifo_aclr  : std_logic;
  SIGNAL s_ch3fifo_empty : std_logic;
  SIGNAL s_ch3fifo_q     : std_logic_vector(15 DOWNTO 0);
  SIGNAL s_ch0_rclk      : std_logic;
  SIGNAL s_ch1_rclk      : std_logic;
  SIGNAL s_ch2_rclk      : std_logic;
  SIGNAL s_ch3_rclk      : std_logic;

  SIGNAL s_ddr_inh    : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_ddr_inl    : std_logic_vector(7 DOWNTO 0);
  SIGNAL s_rxfifo_out : std_logic_vector(15 DOWNTO 0);

  SIGNAL s_geo_id_ch0 : std_logic_vector(6 DOWNTO 0);
  SIGNAL s_geo_id_ch1 : std_logic_vector(6 DOWNTO 0);
  SIGNAL s_geo_id_ch2 : std_logic_vector(6 DOWNTO 0);
  SIGNAL s_geo_id_ch3 : std_logic_vector(6 DOWNTO 0);

  TYPE State_type IS (State0, State1, State1a, State2, State3);
  SIGNAL state : State_type;

  TYPE Geo_state_type IS (g_data, g_geo);
  SIGNAL geoState0 : Geo_state_type;
  SIGNAL geoState1 : Geo_state_type;
  SIGNAL geoState2 : Geo_state_type;
  SIGNAL geoState3 : Geo_state_type;

BEGIN

  -----------------------------------------------------------------------------
  -- Clocks and resets
  -----------------------------------------------------------------------------

  -- create 20 MHz clock with TFF:
  div2 : PROCESS (globalclk) IS
  BEGIN
    IF rising_edge(globalclk) THEN
      div2out <= NOT div2out;
    END IF;
  END PROCESS div2;

  -- PLL to generate 80MHz, 160MHz, and 160MHz phase shifted clocks
  pll_instance : pll PORT MAP (
    areset => '0',
    inclk0 => clk,
    c0     => pll_160mhz,
    c1     => pll_160mhz_p,
    c2     => s_pll_80mhz,
    locked => pll_locked);

  global_clk_buffer1 : global PORT MAP (a_in => clk, a_out => globalclk);
  global_clk_buffer2 : global PORT MAP (a_in => div2out, a_out => clk20mhz);
  global_clk_buffer3 : global PORT MAP (a_in => s_pll_80mhz, a_out => pll_80mhz);

  ch0_clk_buffer : global PORT MAP (a_in => ch0_rclk, a_out => s_ch0_rclk);
  ch1_clk_buffer : global PORT MAP (a_in => ch1_rclk, a_out => s_ch1_rclk);
  ch2_clk_buffer : global PORT MAP (a_in => ch2_rclk, a_out => s_ch2_rclk);
  ch3_clk_buffer : global PORT MAP (a_in => ch3_rclk, a_out => s_ch3_rclk);

  serdes_clk <= clk20mhz;
  -- serdes_clk <= '0'; -- turned off
  -- serdes_clk <= globalclk; -- 40MHz

  -----------------------------------------------------------------------------
  -- Mictors
  -----------------------------------------------------------------------------
-- mt(17 DOWNTO 0)  <= s_serdes_out;
-- mt(11 DOWNTO 0)  <= s_smif_datain;
-- mt(15 DOWNTO 12) <= s_smif_datatype;
-- mt(23 DOWNTO 18) <= s_txfifo_q(7 DOWNTO 2);
-- mt(31 DOWNTO 24) <= s_serdes_reg;

--  mt(17 DOWNTO 0)  <= ch0_rxd;
--  mt(23 DOWNTO 18) <= s_txfifo_q(7 DOWNTO 2);
--  mt(15 DOWNTO 0)  <= s_rxfifo_q(15 DOWNTO 0);
--  mt(23 DOWNTO 16) <= s_txfifo_q(7 DOWNTO 0);
--  mt(30 DOWNTO 24) <= s_errorctr(6 DOWNTO 0);
--  mt(31)           <= s_ch0_locked;

--  mt_clk <= globalclk;
--  mt_clk <= serdes_clk;
--  mt_clk <= pll_80mhz;

  mt     <= (OTHERS => '0');
  mt_clk <= '0';

  -----------------------------------------------------------------------------
  -- SERDES-MAIN FPGA interface
  -----------------------------------------------------------------------------
  -- Serdes <-> Master Interface is implemented as 36 lines that are assigned
  -- as follows:
  -- maO[7..0]   : 8 bit (Serdes FIFO) data from Serdes DDIO to Master (output)
  -- maO[8]      : latch signal, valid on the last two bytes of each 4 byte transmission
  -- maO[9]      : '0'
  -- ma[10]      : channel 2 "ready" (locked and synch'ed) signal
  -- ma[11]      : channel 3 "ready" (locked and synch'ed) signal
  -- ma[12]      : channel 0 "ready" (locked and synch'ed) signal
  -- ma[13]      : channel 1 "ready" (locked and synch'ed) SIGNAL
  -- (the above four signals are reordered so they correspond to the actual layout)
  -- maO[14]     : '0'
  -- maO[15]     : 80MHz clock for synchronization
  -- maO[16]     : FIFO empty (output)
  -- maI[18..17] : Select one of 4 Serdes FIFOs (input)
  -- maI[19]     : Read Enable to FIFO (input)
  --
  -- maI[31..20] : 12 bit data from Master to Serdes (input)
  -- maI[35..32] : 4 bit data type from Master (input)
  --
  -- Currently, there are 4 "data types" from Master to Serdes defined:
  --    "trigger", "bunch reset", "reset", and "load register"
  -- each action is triggered on leading edge of 40MHz clock and is followed
  -- by one clock of wait state (defined in smif.vhd)

--  ma(35 DOWNTO 17) <= (OTHERS => 'Z');  -- tri-state unused outputs to master FPGA

  -- SERDES (S) to MASTER (M) interface
  maO(15 DOWNTO 0) <= s_smif_dataout;   -- 16bit data from S to M
  maO(16)          <= s_smif_fifo_empty;  -- FIFO empty indicator from S to M
  s_smif_select    <= maI(18 DOWNTO 17);  -- select from M to S to select 1 of 4 FIFOs
  s_smif_rdenable  <= maI(19);          -- read enable from M to S for FIFO

  -- MASTER (M) to SERDES (S) interface
  s_smif_datain   <= maI(31 DOWNTO 20);  -- 12bit data from M to S 
  s_smif_datatype <= maI(35 DOWNTO 32);  -- 4bit data type indicator from M to S

  smif_inst : smif PORT MAP (
    clk40mhz   => globalclk,
    clk20mhz   => clk20mhz,
    datain     => s_smif_datain,
    data_type  => s_smif_datatype,
    serdes_out => s_serdes_out,
    serdes_reg => s_serdes_reg,
    geo_id0    => s_geo_id_ch0,
    geo_id1    => s_geo_id_ch1,
    geo_id2    => s_geo_id_ch2,
    geo_id3    => s_geo_id_ch3,
    trigger    => s_smif_trigger,
    areset     => m_all(1));

  -----------------------------------------------------------------------------
  -- SERDES defaults
  -----------------------------------------------------------------------------

  -- channel 0
  ch0_den     <= s_serdes_reg(2);       -- tx enabled by serdes register bit 0
  ch0_ren     <= s_serdes_reg(2);       -- rx enabled by serdes register bit 0
  ch0_loc_le  <= '0';                   -- local loopback disabled
  ch0_line_le <= '0';                   -- line loopback disabled
  ch0_txd     <= s_ch0_txd;
  led(0)      <= ch0_lock_n;

  -- channel 1
  ch1_den     <= s_serdes_reg(3);       -- tx enabled by serdes register bit 1
  ch1_ren     <= s_serdes_reg(3);       -- rx enabled by serdes_register bit 1
  ch1_loc_le  <= '0';                   -- local loopback disabled
  ch1_line_le <= '0';                   -- line loopback disabled
  ch1_txd     <= s_ch1_txd;
  led(1)      <= ch1_lock_n;

  -- channel 2
  ch2_den     <= s_serdes_reg(0);       -- tx enabled by serdes register bit 2
  ch2_ren     <= s_serdes_reg(0);       -- rx enabled by serdes register bit 2
  ch2_loc_le  <= '0';
  ch2_line_le <= '0';
  ch2_txd     <= s_ch2_txd;

  -- channel 3
  ch3_den     <= s_serdes_reg(1);       -- tx enabled by serdes register bit 3
  ch3_ren     <= s_serdes_reg(1);       -- rx enabled by serdes register bit 3
  ch3_loc_le  <= '0';
  ch3_line_le <= '0';
  ch3_txd     <= s_ch3_txd;


  -- Serdes tx clocks and rx refclocks
  ch0_tck    <= serdes_clk;
  ch1_tck    <= serdes_clk;
  ch2_tck    <= serdes_clk;
  ch3_tck    <= serdes_clk;
  ch0_refclk <= serdes_clk;
  ch1_refclk <= serdes_clk;
  ch2_refclk <= serdes_clk;
  ch3_refclk <= serdes_clk;

  -----------------------------------------------------------------------------
  -- SERDES utilities
  -----------------------------------------------------------------------------

  -- MUX for serdes TX
  WITH s_serdes_reg(4) SELECT
    serdes_data <=  -- goes to poweron sm first to be muxed with poweron data
    serdes_tst_data WHEN '0',           -- test data
    s_serdes_out    WHEN OTHERS;        -- "real" data

  -- test data is currently commented out, so just set it to all 0's
  serdes_tst_data <= (OTHERS => '0');

  -----------------------------------------------------------------------------
  -- Rx FIFOs
  -----------------------------------------------------------------------------

  -- Channel 0 ----------------------------------------------------------------

  ch0rcvr : serdes_rcvr
    PORT MAP (
      areset_n   => s_ch0_locked,
      clk40mhz   => globalclk,
      rdreq_in   => s_ch0fifo_rdreq,
      fifo_aclr  => s_ch0fifo_aclr,
      ch_rclk    => s_ch0_rclk,
      ch_rxd     => ch0_rxd,
      geo_id     => s_geo_id_ch0,
      dataout    => s_ch0fifo_q,
      fifo_empty => s_ch0fifo_empty);

  s_ch0fifo_aclr <= NOT s_ch0_locked OR m_all(0) OR s_smif_trigger;

  -- Channel 1 ----------------------------------------------------------------
  ch1rcvr : serdes_rcvr
    PORT MAP (
      areset_n   => s_ch1_locked,
      clk40mhz   => globalclk,
      rdreq_in   => s_ch1fifo_rdreq,
      fifo_aclr  => s_ch1fifo_aclr,
      ch_rclk    => s_ch1_rclk,
      ch_rxd     => ch1_rxd,
      geo_id     => s_geo_id_ch1,
      dataout    => s_ch1fifo_q,
      fifo_empty => s_ch1fifo_empty);

  s_ch1fifo_aclr <= NOT s_ch1_locked OR m_all(0) OR s_smif_trigger;

  -- Channel 2 ----------------------------------------------------------------
  ch2rcvr : serdes_rcvr
    PORT MAP (
      areset_n   => s_ch2_locked,
      clk40mhz   => globalclk,
      rdreq_in   => s_ch2fifo_rdreq,
      fifo_aclr  => s_ch2fifo_aclr,
      ch_rclk    => s_ch2_rclk,
      ch_rxd     => ch2_rxd,
      geo_id     => s_geo_id_ch2,
      dataout    => s_ch2fifo_q,
      fifo_empty => s_ch2fifo_empty);

  s_ch2fifo_aclr <= NOT s_ch2_locked OR m_all(0) OR s_smif_trigger;

  -- Channel 3 ----------------------------------------------------------------
  ch3rcvr : serdes_rcvr
    PORT MAP (
      areset_n   => s_ch3_locked,
      clk40mhz   => globalclk,
      rdreq_in   => s_ch3fifo_rdreq,
      fifo_aclr  => s_ch3fifo_aclr,
      ch_rclk    => s_ch3_rclk,
      ch_rxd     => ch3_rxd,
      geo_id     => s_geo_id_ch3,
      dataout    => s_ch3fifo_q,
      fifo_empty => s_ch3fifo_empty);

  s_ch3fifo_aclr <= NOT s_ch3_locked OR m_all(0) OR s_smif_trigger;

  -- FIFO output decoded to Master FPGA lines -----------------
  -- select which FIFO to send read enable to
  rdreq_decode : decoder PORT MAP (
    input_sig => s_smif_rdenable,
    adr       => s_smif_select,
    y(0)      => s_ch2fifo_rdreq,
    y(1)      => s_ch3fifo_rdreq,
    y(2)      => s_ch0fifo_rdreq,
    y(3)      => s_ch1fifo_rdreq);

  -- select which FIFO to read
  rxmux_inst : mux17x4 PORT MAP (
    data0x(15 DOWNTO 0) => s_ch2fifo_q,
    data0x(16)          => s_ch2fifo_empty,
    data1x(15 DOWNTO 0) => s_ch3fifo_q,
    data1x(16)          => s_ch3fifo_empty,
    data2x(15 DOWNTO 0) => s_ch0fifo_q,
    data2x(16)          => s_ch0fifo_empty,
    data3x(15 DOWNTO 0) => s_ch1fifo_q,
    data3x(16)          => s_ch1fifo_empty,
    sel                 => s_smif_select,
    result(15 DOWNTO 0) => s_rxfifo_out,
    result(16)          => s_smif_fifo_empty);

  -- output 8bit data on each clock edge of the 80MHz clock
  ddio_out_inst : ddio_out PORT MAP (
    datain_h => s_rxfifo_out(15 DOWNTO 8),
    datain_l => s_rxfifo_out(7 DOWNTO 0),
    outclock => pll_80mhz,
    dataout  => s_smif_dataout(7 DOWNTO 0));

  -- sync rd_enable to 40MHz clock
  PROCESS (globalclk) IS
  BEGIN
    IF falling_edge(globalclk) THEN
      s_synced_rdenable <= s_smif_rdenable;
    END IF;
  END PROCESS;

  -- sync to 80 MHz clock. put out latch signal on last two bytes when valid transmissions
  latcher : PROCESS (pll_80mhz) IS
  BEGIN
    IF rising_edge(pll_80mhz) THEN
      s_smif_dataout(8) <= (globalclk NOR s_smif_fifo_empty) AND s_synced_rdenable;
    END IF;
  END PROCESS latcher;

  s_smif_dataout(9)  <= '0';
  s_smif_dataout(10) <= s_ch2_locked;
  s_smif_dataout(11) <= s_ch3_locked;
  s_smif_dataout(12) <= s_ch0_locked;
  s_smif_dataout(13) <= s_ch1_locked;
  s_smif_dataout(14) <= '0';
  s_smif_dataout(15) <= pll_80mhz;

  -----------------------------------------------------------------------------
  -- SERDES power on procedures
  -----------------------------------------------------------------------------
  
  poweron_ch0 : serdes_poweron PORT MAP (
    clk         => globalclk,
    tpwdn_n     => ch0_tpwdn_n,
    rpwdn_n     => ch0_rpwdn_n,
    sync        => ch0_sync,
    ch_lock_n   => ch0_lock_n,
    ch_ready    => s_ch0_locked,
    pll_locked  => pll_locked,
    rxd         => ch0_rxd,
    serdes_data => serdes_data,
    txd         => s_ch0_txd,
    areset_n    => s_serdes_reg(2));


  poweron_ch1 : serdes_poweron PORT MAP (
    clk         => globalclk,
    tpwdn_n     => ch1_tpwdn_n,
    rpwdn_n     => ch1_rpwdn_n,
    sync        => ch1_sync,
    ch_lock_n   => ch1_lock_n,
    ch_ready    => s_ch1_locked,
    pll_locked  => pll_locked,
    rxd         => ch1_rxd,
    serdes_data => serdes_data,
    txd         => s_ch1_txd,
    areset_n    => s_serdes_reg(3));

  poweron_ch2 : serdes_poweron PORT MAP (
    clk         => globalclk,
    tpwdn_n     => ch2_tpwdn_n,
    rpwdn_n     => ch2_rpwdn_n,
    sync        => ch2_sync,
    ch_lock_n   => ch2_lock_n,
    ch_ready    => s_ch2_locked,
    pll_locked  => pll_locked,
    rxd         => ch2_rxd,
    serdes_data => serdes_data,
    txd         => s_ch2_txd,
    areset_n    => s_serdes_reg(0));

  poweron_ch3 : serdes_poweron PORT MAP (
    clk         => globalclk,
    tpwdn_n     => ch3_tpwdn_n,
    rpwdn_n     => ch3_rpwdn_n,
    sync        => ch3_sync,
    ch_lock_n   => ch3_lock_n,
    ch_ready    => s_ch3_locked,
    pll_locked  => pll_locked,
    rxd         => ch3_rxd,
    serdes_data => serdes_data,
    txd         => s_ch3_txd,
    areset_n    => s_serdes_reg(1));

  -----------------------------------------------------------------------------
  -- SRAM control
  -----------------------------------------------------------------------------

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
  sra_clk  <= pll_160mhz;
  srb_clk  <= pll_160mhz;

  sra_d <= (OTHERS => 'Z');
  srb_d <= (OTHERS => 'Z');

-- THIS CODE NOT USED FOR NOW ----------------
--  zbt_ctrl_top_inst1 : zbt_ctrl_top
--    PORT MAP (
--      clk                   => pll_160mhz_p,
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

--  sram_sm : PROCESS (pll_160mhz_p, pll_locked) IS
--  BEGIN  -- PROCESS uc_fpga_sm
--    IF pll_locked = '0' THEN                            -- asynchronous reset (active low)
--      state           <= State0;
--      s_dm            <= (OTHERS => '0');
--      s_rw_n          <= '0';
--      s_addr_adv_ld_n <= '1';
--    ELSIF rising_edge(pll_160mhz_p) THEN
--      s_dm            <= (OTHERS => '0');
--      s_rw_n          <= '0';
--      s_addr_adv_ld_n <= '1';
--      CASE state IS
-- WHEN State0 =>
--          IF ma(35) = '1' THEN
--            state <= State1;
--          END IF;
-- WHEN State1 =>
--          s_addr_adv_ld_n <= '0';
--          s_rw_n          <= ma(34);
--          s_dm            <= (OTHERS => '1');
--          state           <= State1a;
-- WHEN State1a =>                                 -- this state is for testing of the waveforms only
--          s_addr_adv_ld_n <= '0';
--          s_rw_n          <= ma(34);
--          s_dm            <= (OTHERS => '1');
--          state           <= State2;
-- WHEN State2 =>
--          s_addr_adv_ld_n <= '0';
--          state           <= State3;
-- WHEN State3 =>
--          IF ma(35) = '0' THEN
--            state <= State0;
--          END IF;
--      END CASE;
--    END IF;
--  END PROCESS sram_sm;



  -----------------------------------------------------------------------------
  -- SERDES test utilities
  -----------------------------------------------------------------------------

  -- Counter as data input to channel 0 TX
--  counter17b : lpm_counter GENERIC MAP (
--    LPM_WIDTH     => 17,
--    LPM_TYPE      => "LPM_COUNTER",
--    LPM_DIRECTION => "UP")
--    PORT MAP (
--      clock  => serdes_clk,
--      q      => counter_q,
--      clk_en => '1',
--      aclr   => s_ctr_aclr);

  -- (L)inear (F)eedback (S)hift (R)egister as data generator (17 bit pseudo random numbers)
--  datagen : LFSR
--    PORT MAP (
--      RESETn => '1',
--      clock  => serdes_clk,
--      d      => lsfr_d);

  -- SERDES data:
--  s_send_data <= s_ch0_locked AND s_serdes_reg(6);  -- control sending of data with serdes register bit 6

-- serdes_tst_data(16 DOWNTO 0) <= counter_q;
--  serdes_tst_data(15 DOWNTO 0) <= lsfr_d(15 DOWNTO 0);
--  serdes_tst_data(16)          <= lsfr_d(16) AND s_serdes_reg(6);
--  serdes_tst_data(17)          <= s_send_data;


  -- test feature:
  -- latch tx data into a dual clock 17bit fifo for later comparison
--  txfifo : dcfifo
--    GENERIC MAP (
--      intended_device_family => "Cyclone II",
--      lpm_hint               => "MAXIMIZE_SPEED=5",
--      lpm_numwords           => 16,
--      lpm_showahead          => "ON",
--      lpm_type               => "dcfifo",
--      lpm_width              => 17,
--      lpm_widthu             => 4,
--      overflow_checking      => "ON",
--      rdsync_delaypipe       => 4,
--      underflow_checking     => "ON",
--      wrsync_delaypipe       => 4)
--    PORT MAP (
--      wrclk   => serdes_clk,
--      rdreq   => s_txfifo_rdreq,
--      aclr    => s_txfifo_aclr,
--      rdclk   => s_ch0_rclk,
--      wrreq   => serdes_tst_data(17),
--      data    => serdes_tst_data(16 DOWNTO 0),
--      rdempty => s_txfifo_empty,
--      q       => s_txfifo_q
--      );

  -- latch rx data into a single clock 17bit fifo for later comparison
--  rxfifo : scfifo
--    GENERIC MAP (
--      add_ram_output_register => "ON",
--      intended_device_family  => "Cyclone II",
--      lpm_numwords            => 16,
--      lpm_showahead           => "ON",
--      lpm_type                => "scfifo",
--      lpm_width               => 17,
--      lpm_widthu              => 4,
--      overflow_checking       => "ON",
--      underflow_checking      => "ON",
--      use_eab                 => "ON"
--      )
--    PORT MAP (
--      rdreq => s_rxfifo_rdreq,
--      aclr  => s_rxfifo_aclr,
--      clock => s_ch0_rclk,
--      wrreq => s_rxfifo_wrreq,
--      data  => ch0_rxd(16 DOWNTO 0),
--      empty => s_rxfifo_empty,
--      q     => s_rxfifo_q
--      );

--  s_rxfifo_wrreq <= ch0_rxd(17) AND s_ch0_locked;
--  s_txfifo_aclr  <= NOT s_ch0_locked;
--  s_rxfifo_aclr  <= NOT s_ch0_locked;

--  s_ctr_aclr    <= NOT s_ch0_locked;

  -- now compare
--  areset_n <= '1';  -- asynchronous global reset, active low
--  data_compare : PROCESS (serdes_clk, areset_n) IS
--    VARIABLE b_ch0valid : boolean := false;
--  BEGIN
--    IF areset_n = '0' THEN              -- asynchronous reset (active low)
--      s_errorctr     <= (OTHERS => '0');
--      s_txfifo_rdreq <= '0';
--      s_rxfifo_rdreq <= '0';

--    ELSIF falling_edge(serdes_clk) THEN
--      s_txfifo_rdreq <= '0';
--      s_rxfifo_rdreq <= '0';
--      IF ((s_rxfifo_empty = '0') AND (s_txfifo_empty = '0')) THEN
--        IF (s_rxfifo_q /= s_txfifo_q) THEN
--          s_errorctr <= s_errorctr + 1;
--        END IF;
--        s_txfifo_rdreq <= '1';
--        s_rxfifo_rdreq <= '1';
--      END IF;
--    END IF;
--  END PROCESS data_compare;

END a;

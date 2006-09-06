-- $Id: tcd_interface.vhd,v 1.1 2006-09-06 19:43:28 jschamba Exp $
-------------------------------------------------------------------------------
-- Title      : TCD Interface
-- Project    : THUB
-------------------------------------------------------------------------------
-- File       : tcd_interface.vhd
-- Author     : 
-- Company    : 
-- Created    : 2006-09-01
-- Last update: 2006-09-06
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Interface to TCD signals
-------------------------------------------------------------------------------
-- Copyright (c) 2006 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2006-09-01  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY lpm;
USE lpm.lpm_components.all;
LIBRARY altera_mf; 
USE altera_mf.altera_mf_components.all; 

ENTITY tcd IS
  
  PORT (
    rhic_strobe : IN  std_logic;
    data_strobe : IN  std_logic;
    data        : IN  std_logic_vector (3 DOWNTO 0);
    aclr        : IN  std_logic;
    trgword     : OUT std_logic_vector (19 DOWNTO 0);
    trigger     : OUT std_logic);

END ENTITY tcd;

ARCHITECTURE a OF tcd IS

  SIGNAL s_reg1          : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg2          : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg3          : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg4          : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg5          : std_logic_vector (3 DOWNTO 0);
  SIGNAL s_reg20_1       : std_logic_vector (19 DOWNTO 0);
  SIGNAL s_reg20_2       : std_logic_vector (19 DOWNTO 0);
  SIGNAL inv_data_strobe : std_logic;
  SIGNAL inv_rhic_strobe : std_logic;
  SIGNAL not_zero        : std_logic;
  SIGNAL s_fifo_empty    : std_logic;
  
BEGIN  -- ARCHITECTURE a

  inv_data_strobe <= NOT data_strobe;
  inv_rhic_strobe <= NOT rhic_strobe;

  reg1 : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 4
      )
    PORT MAP (
      clock => inv_data_strobe,
      data  => data,
      q     => s_reg1
      );

  reg2 : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 4
      )
    PORT MAP (
      clock => inv_data_strobe,
      data  => s_reg1,
      q     => s_reg2
      );

  reg3 : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 4
      )
    PORT MAP (
      clock => inv_data_strobe,
      data  => s_reg2,
      q     => s_reg3
      );

  reg4 : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 4
      )
    PORT MAP (
      clock => inv_data_strobe,
      data  => s_reg3,
      q     => s_reg4
      );

  reg5 : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 4
      )
    PORT MAP (
      clock => inv_data_strobe,
      data  => s_reg4,
      q     => s_reg5
      );

  reg20_1 : lpm_ff
    GENERIC MAP (
      lpm_fftype => "DFF",
      lpm_type   => "LPM_FF",
      lpm_width  => 20
      )
    PORT MAP (
      clock              => rhic_strobe,
      data(19 DOWNTO 16) => s_reg5,
      data(15 DOWNTO 12) => s_reg4,
      data(11 DOWNTO 8)  => s_reg3,
      data(7 DOWNTO 4)   => s_reg2,
      data(3 DOWNTO 0)   => s_reg1,
      q                  => s_reg20_1
      );

  not_zero <= '1' WHEN s_reg20_1(19 DOWNTO 16) /= "0000" ELSE '0';

--  reg20_2 : lpm_ff
--    GENERIC MAP (
--      lpm_fftype => "DFF",
--      lpm_type   => "LPM_FF",
--      lpm_width  => 20
--      )
--    PORT MAP (
--      clock  => inv_rhic_strobe,
--      data   => s_reg20_1,
--      enable => not_zero,
--      aclr   => aclr,
--      q      => trgword
--      );


  -- use a FIFO here instead of a register as above

  dcfifo_inst : dcfifo
    GENERIC MAP (
      intended_device_family => "Cyclone II",
      lpm_numwords => 256,
      lpm_showahead => "ON",
      lpm_type => "dcfifo",
      lpm_width => 20,
      lpm_widthu => 8,
      overflow_checking => "ON",
      rdsync_delaypipe => 4,
      underflow_checking => "ON",
      use_eab => "ON",
      wrsync_delaypipe => 4
      )
    PORT MAP (
      wrclk => inv_rhic_strobe,
      rdreq => '1',
      rdclk => aclr,
      wrreq => not_zero,
      data => s_reg20_1,
      rdempty => s_fifo_empty,
      q => s_reg20_2
      );

  trgword <= (OTHERS => '0') WHEN (s_fifo_empty = '1') ELSE s_reg20_2;

  -- not yet implemented:
  trigger <= '0';

END ARCHITECTURE a;

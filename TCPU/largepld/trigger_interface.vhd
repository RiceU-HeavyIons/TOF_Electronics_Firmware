

	-- Filename : trigger_interface.vhd
	--
	-- Date : 9/15/04
	-- Author : L. Bridges / Blue Sky Electronics, LLC
	
	-- Changes History:
	
	-- 11/22/04: Changes "non_zero" signal so that data is written to fifo 
	-- when "TCD command" field (4 msbits) is non-zero. Previously, data was
	-- written to the fifo when ANY of the 20 TCD bits was non-zero.
	--
	-- This module receives tcd trigger commands and tokens as 4bit words, 
	-- and demultiplexes them to a full 20bit word. 
	-- Demultiplex data from 4 bits parallel to 20 bits parallel.


	-- Assumption 1: No actual commands consist of all 0 data. To 
	-- avoid overloading the MCU interface, I pass along TCD words
	--  only when at least on bit is nonzero. 

	-- Assumption 2: The rising edge of RHIC_CLK gives the 
	-- beginning of a new 20 bit sequence. 

	-- DATA PATH:
	--*******************
	
	-- A 4 bit wide by 5 register long shift register loads 
	-- 20 bits of data at 50 Mhz,using the falling edge of 5XRHIC.
	
	-- reg1 => reg2 => ... => reg6 are 4bit registers in series
	
	-- reg7 clocks the 20bits in parallel from reg2 thru reg6 with the
	-- 50 Mhz TCD clock, using a delayed version of the 10Mhz rhic 
	-- strobe as clock enable
	
	-- reg8 clocks the 20 bits with the 25 Mhz local TCPU clock, using
	-- a synchronized version of the RHIC 10Mhz strobe as clock enable
	
	-- reg9 clocks 20 bit words that are non zero, and a further delay 
	-- of its clock enable is output as a data valid strobe
	 
           
    LIBRARY ieee; USE ieee.std_logic_1164.all;
            
    LIBRARY lpm; USE lpm.lpm_components.all;
    use work.tcpu_package.all;
	
	entity trigger_interface is
		port( clk, reset : in std_logic;
			  tcd_4bit_data : in std_logic_vector(3 downto 0);
			  tcd_clk_50mhz : in std_logic;
			  tcd_clk_10mhz : in std_logic;
			  tcd_word : out std_logic_vector(19 downto 0);
			  tcd_strobe : out std_logic
			);		
	end entity trigger_interface;
	
	architecture lwb1 of trigger_interface is

		
	
		-- SIGNALS
		
		signal reg1_out, reg2_out, reg3_out, reg4_out, reg5_out, reg6_out : std_logic_vector(3 downto 0);
		signal reg7_out, reg8_out, reg9_out : std_logic_vector(19 downto 0);
		signal non_zero, inv_tcd_clk_50mhz : std_logic;
		signal clear_register : std_logic;
		signal ser_to_par_enable : std_logic;
		signal reg9_enable : std_logic;
		signal syncff1_out, syncff2_out, syncff3_out, syncff4_out, syncff5_out : std_logic;
		signal delayff1_out : std_logic;
		
	begin
	
	inv_tcd_clk_50mhz <= not tcd_clk_50mhz;
	
	clear_register <= reset or non_zero;
	
	reg1: reg4_en_aclr PORT MAP (
		clock	 => inv_tcd_clk_50mhz,
		aclr 	 => reset,
		enable	 => '1',
		data	 => tcd_4bit_data,
		q	 => reg1_out );
		
	reg2: reg4_en_aclr PORT MAP (
		clock	 => inv_tcd_clk_50mhz,
		aclr 	 => reset,
		enable	 => '1',
		data	 => reg1_out,
		q	 => reg2_out );

	reg3: reg4_en_aclr PORT MAP (
		clock	 => inv_tcd_clk_50mhz,
		aclr 	 => reset,
		enable	 => '1',
		data	 => reg2_out,
		q	 => reg3_out );

	reg4: reg4_en_aclr PORT MAP (
		clock	 => inv_tcd_clk_50mhz,
		aclr 	 => reset,
		enable	 => '1',
		data	 => reg3_out,
		q	 => reg4_out );

	reg5: reg4_en_aclr PORT MAP (
		clock	 => inv_tcd_clk_50mhz,
		aclr 	 => reset,
		enable	 => '1',
		data	 => reg4_out,
		q	 => reg5_out );
		
	reg6: reg4_en_aclr PORT MAP (
		clock	 => inv_tcd_clk_50mhz,
		aclr 	 => reset,
		enable	 => '1',
		data	 => reg5_out,
		q	 => reg6_out );
	
	-- delayff1 delays 10 mhz rhic strobe to use as enable for 1st parallel reg (reg7)
	
	delayff1 : DFF_sclr PORT MAP (
		clock	 => tcd_clk_10mhz,
		sclr	 => '0',
		aclr	 => ser_to_par_enable,
		data	 => '1',
		q	 => delayff1_out );
		
	delayff2 : DFF_sclr PORT MAP (
		clock	 => inv_tcd_clk_50mhz,
		sclr	 => '0',
		aclr	 => reset,
		data	 => delayff1_out,
		q	 => ser_to_par_enable );
				
	reg7 : reg20_en PORT MAP (
			clock	 => tcd_clk_50mhz,
			enable	 => ser_to_par_enable,    -- assumes 10mhz strobe is only 20ns wide
			sclr	 => '0',
			aclr	 => reset,
			data(19 downto 16)	 => reg6_out,  -- trigger cmd
			data(15 downto 12)	 => reg5_out,  -- daq cmd
			data(11 downto  8)	 => reg4_out,  -- token high
			data(7  downto 4)	 => reg3_out,  -- token mid
			data(3  downto 0)	 => reg2_out,  -- token low
			q	           => reg7_out);
	
	reg8 : reg20_en PORT MAP (
			clock	 => clk,
			enable	 => syncff3_out,
			sclr	 => reset,
			aclr	 => '0',
			data	 => reg7_out,
			q	 => reg8_out );
		
	non_zero <= reg8_out(19) or reg8_out(18) or reg8_out(17) or reg8_out(16);
	
		-- or reg8_out(15) 
		--or reg8_out(14) or reg8_out(13) or reg8_out(12) or reg8_out(11) or reg8_out(10) 
		--or reg8_out( 9) or reg8_out( 8) or reg8_out( 7) or reg8_out( 6) or reg8_out( 5) 
		--or reg8_out( 4) or reg8_out( 3) or reg8_out( 2) or reg8_out( 1) or reg8_out( 0);
			
	reg9 : reg20_en PORT MAP (
			clock	 => clk,
			enable	 => reg9_enable,
			sclr	 => reset,
			aclr	 => '0',
			data	 => reg8_out,
			q	 => reg9_out );		
	
	reg9_enable <= non_zero and syncff4_out;
		
	-- 3 DFFs to synchronize 10 mhz rhic strobe to 25mhz system clock
	-- the synced pulse is 1 system clock wide and is used as clock enable for 
	-- reg 8. The same strobe, delayed one more clock, is output to use as clock 
	-- enable for the TCD word fifo
	
	syncff1 : DFF_sclr PORT MAP (
		clock	 => tcd_clk_10mhz,
		sclr	 => '0',
		aclr	 => syncff3_out,
		data	 => '1',
		q	 => syncff1_out );	
	
	syncff2 : DFF_sclr PORT MAP (
		clock	 => clk,
		sclr	 => reset,
		aclr	 => syncff3_out,
		data	 => syncff1_out,
		q	 => syncff2_out );	
		
	syncff3 : DFF_sclr PORT MAP (
		clock	 => clk,
		sclr	 => reset,
		aclr	 => '0',
		data	 => syncff2_out,
		q	 => syncff3_out );	
		
	syncff4 : DFF_sclr PORT MAP (
		clock	 => clk,
		sclr	 => reset,
		aclr	 => '0',
		data	 => syncff3_out,
		q	 => syncff4_out );	

	syncff5 : DFF_sclr PORT MAP (
		clock	 => clk,
		sclr	 => reset,
		aclr	 => '0',
		data	 => reg9_enable,
		q	 => syncff5_out );	
		
	tcd_word <= reg9_out;
	
	tcd_strobe <= syncff5_out;


	end architecture lwb1;

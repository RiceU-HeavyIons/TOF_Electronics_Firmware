
	-- Filename : pushbutton_pulse.vhd
	--
	-- Date : 9/10/04
	-- Author : L. Bridges / Blue Sky Electronics, LLC
	--
	-- This module debounces an active high pulse input from a pushbutton
	-- switch. It outputs a clock-synchronized pulse that is one clock wide. 
	
    LIBRARY ieee; USE ieee.std_logic_1164.all;       
    LIBRARY lpm; USE lpm.lpm_components.all;
    use work.tcpu_package.all;
 	
	entity pushbutton_pulse is
		port( clk, reset : in std_logic;
			  pushbutton : in std_logic;
			  pulseout : out std_logic	
			);		
	end entity pushbutton_pulse;
	
	architecture lwb1 of pushbutton_pulse is
		
		-- SIGNALS
		signal ff1, ff2, ff3, dflop1_clr : std_logic;	
		
	begin
	
		--dflop1 : process (reset, ) is
		--begin
		--	if rising_edge(clk)
	
		dflop1 : DFF_generic PORT MAP (
			clock	 => pushbutton,
			sclr	 => '0',
			sset	 => '0',
			aclr	 => dflop1_clr,
			aset  => '0',
			data	 => '1',
			enable => '1',
			q	 => ff1);
		
		dflop1_clr <= reset or ff3;
			
		dflop2 : DFF_sclr_sset PORT MAP (
			clock => clk,
			sclr	 => reset,
			sset	 => '0',
			data	 => ff1,
			q	 => ff2);
			
		dflop3 : DFF_sclr_sset PORT MAP (
			clock	 => clk,
			sclr	 => reset,
			sset	 => '0',
			data	 => ff2,
			q	 => ff3);
			
		pulseout <= ff3 and ff2;

	end architecture lwb1;
	
	
			
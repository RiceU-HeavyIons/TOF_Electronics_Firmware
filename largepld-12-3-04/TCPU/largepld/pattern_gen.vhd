	
	-- Filename : pattern_gen.vhd
	--
	-- Date : 9/10/04
	-- Author : L. Bridges / Blue Sky Electronics, LLC
	--
	-- This module generates a 32bit test word in response to a pushbutton input
	-- The pushbutton signal is debounced in component pushbutton_pulse.
	--
		
	LIBRARY altera;
    USE altera.maxplus2.ALL;
            
    LIBRARY ieee;
    USE ieee.std_logic_1164.all;
            
    LIBRARY lpm;
    USE lpm.lpm_components.all;

	 
	entity pattern_gen is
		port( clk, reset : in std_logic;
			  pushbutton : in std_logic;
			  test_pattern : out std_logic_vector(31 downto 0);
			  data_cnt_vis : out integer range 0 to 4;
			  button_pulse_vis : out std_logic
			);		
	end entity pattern_gen;
	
	architecture lwb1 of pattern_gen is

		component pushbutton_pulse
			PORT(
			  clk, reset : in std_logic;
			  pushbutton : in std_logic;
			  pulseout : out std_logic	
			);
		end component;
		
		-- SIGNALS
		signal button_pulse : std_logic;	
		signal data_cnt : integer range 0 to 4;
		
	begin
		--dflop1 : process (reset, ) is
		--begin
		--	if rising_edge(clk)
	
		button_sync : pushbutton_pulse PORT MAP (
			clk => clk,
			reset => reset,
			pushbutton => pushbutton,
			pulseout => button_pulse );
		
		test_cnt : process (clk, reset, button_pulse) is
		
			begin
				if reset = '1' then
					 data_cnt <= 0;
					
				elsif rising_edge(clk) then
				
					 	if button_pulse = '1' then
					
								if data_cnt = 4 then
					
									data_cnt <= 0;
								else
									data_cnt <= data_cnt + 1;
									
								end if;							
							
						end if;
				end if;
				
			case data_cnt is
				when 0 =>
					test_pattern <= x"00000000";
				when 1 =>
					test_pattern <= x"0A0A0A0A";
				when 2 =>
					test_pattern <= x"50505050";
				when 3 =>
					test_pattern <= x"A0A0A0A0";	
				when 4 =>
					test_pattern <= x"12345678";
					
			end case;
				
		end process test_cnt;
	
	-- test signals
		
	data_cnt_vis <= data_cnt;
	button_pulse_vis <= button_pulse;
	
	end architecture lwb1;
	
	
			
-- ********************************************************************
-- LIBRARY DEFINITIONS
-- ********************************************************************
            
      LIBRARY ieee; USE ieee.std_logic_1164.all;           
      LIBRARY lpm; USE lpm.lpm_components.all;
	 use work.tdig_package.all;
	 
-- ********************************************************************
-- TOP LEVEL ENTITY
-- ********************************************************************

-- this module will reside in each tdig board
--
--	It takes a 32 bit data word and trasmits it as 8 4bit words. Along
--  with the data, it transmits a clock : 'dclk', and a strobe: 'dout_strobe'.
--  The 'dout_strobe' signal goes high along with the 8 valid 4bit words, and then
--  low.
--
--  To initiate a transfer:
--  0. Verify that 'ready' is high
--  1. Present valid 32bit data at the 'din(31..0)' port
--  2. Pulse 'din_strobe' high for 1 clock cycle. This provides to clock enable
--     for the data and initiates the state machine that sends the data. When the
--	   data transmission is complete, 'ready' will return to high. 
            
	entity par32_to_ser4 is
    	port( 
			clk : in std_logic;
			reset : in std_logic;
			din : in std_logic_vector(31 downto 0);
			din_strobe : in std_logic; -- synchronous with input data: used as clock enable 
								   -- for input register and initiates state machine ctr
			
			dout : out std_logic_vector(3 downto 0);
			dclk : out std_logic;  -- source synchronous clock transmitted with data over cable
			dout_strobe : out std_logic; -- data strobe transmitted with data over cable
										 -- this signal goes low after last of 8 4bit words is xmitted
			ready : out std_logic; -- status that counter is idle
								   -- can write new word even if ready = low
								   -- this will reset counter and start over
								   -- receiver is designed to ignore incomplete 
							       -- transmissions like this
							
			-- test signals
			vis_ctr_val : out std_logic_vector(3 downto 0); -- state machine counter
			vis_count_enable : out 	std_logic -- control flip flop output

		);
	end entity par32_to_ser4;
		
	architecture lwba of par32_to_ser4 is
	
		-- data flow: 32b input register => mux (with 4 bit output reg)
		
		-- control: state machine selects 8 4bit words out of mux with dstrobe = hi. 
		-- 'ready' is held low while data is being transmitted
		
		signal count_enable : std_logic;							
		signal reg32_data : std_logic_vector(31 downto 0);
		signal ctr_val : std_logic_vector(3 downto 0);
		signal ctr_val_is_8 : std_logic;
		signal logic1, xmit_active : std_logic;
		signal logic2 : std_logic;
	
	begin
	

		
		-- set 'dclk' output to be the same as master 40 mhz 'clk'
		-- Note that this circuit is designed so that the 'dclk' can be faster than 40 Mhz
		-- In that case, a PLL multiplier construct would go here
		 
		dclk <= clk;
		
		controller : component ctl32to4 PORT MAP (
			clk 			=> clk,
			reset		=> reset,	
			din_strobe 	=> din_strobe,
			ctr  		=> ctr_val,
			dout_strobe 	=> dout_strobe,
			ready  		=> ready );
			
		input_register : component reg32_en PORT MAP (          
			clock	 => clk,
			enable	 => din_strobe,
			sclr	 	 => reset,
			data	 	 => din,
			q	 	 => reg32_data);

		mux_32_to_4_inst : component mux_32_to_4 PORT MAP (	    -- 8 4bit inputs, 1 4bit output
													        -- contains 4bit output register	
			clock	 => clk,
			aclr	 	 => reset,
			clken	 => '1',
			data8x     => reg32_data(3 downto 0),
			data7x	 => reg32_data(7 downto 4),
			data6x	 => reg32_data(11 downto 8),
			data5x	 => reg32_data(15 downto 12),
			data4x	 => reg32_data(19 downto 16),
			data3x	 => reg32_data(23 downto 20),
			data2x	 => reg32_data(27 downto 24),
			data1x	 => reg32_data(31 downto 28),
			data0x	 => B"0000",	
			sel	      => ctr_val(3 downto 0),
			result	 => dout);
			
			
		-- test signals
		vis_ctr_val <= ctr_val;
		vis_count_enable <= count_enable;
		
	end architecture lwba;
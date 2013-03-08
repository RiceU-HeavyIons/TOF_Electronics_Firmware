	
	LIBRARY altera;
    USE altera.maxplus2.ALL;
            
    LIBRARY ieee;
    USE ieee.std_logic_1164.all;
            
    LIBRARY lpm;
    USE lpm.lpm_components.all;


	entity tdig_tcpu_data_testbench1 is
		port(
				-- signals on tdig side
				-- clock and reset can be separate to model clock skew
				
				tdig_clk, tdig_reset : in std_logic;
				tdig_data_in : in std_logic_vector(31 downto 0);
			    tdig_send_strobe : in std_logic; 	-- synchronous with input data: used as clock enable 
								   			-- for input register and initiates state machine ctr

				tdig_ready : out std_logic; -- status that counter is idle
					   -- It's possible to write a new word even if ready = low.
					   -- This will reset counter and start over.The receiver is designed to ignore 
					   -- incomplete transmissions like this.

				-- test points on 'cable' between boards
				
				cable_data : out std_logic_vector(3 downto 0);
				cable_data_clk, cable_data_strobe : out std_logic;
				
				-- signals on tcpu side
				
				tcpu_clk, tcpu_reset : in std_logic;
				tcpu_dout : out std_logic_vector(31 downto 0)				
		
			);
			
	end entity tdig_tcpu_data_testbench1;
	
	
	
	architecture lwba of tdig_tcpu_data_testbench1 is

		-- tdig side
		
		component par32_to_ser4 is port( 
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
			vis_ctr_val : out std_logic_vector(3 downto 0); -- state machine counter
			vis_count_enable : out 	std_logic -- control flip flop output
		);
		end component par32_to_ser4;
		
		-- tcpu side
		
		component ser_4bit_to_par is
		port( din : in std_logic_vector(3 downto 0); -- data from tdig
			dclk : 	in std_logic;		-- source synchronous clock from TDIG
			dstrobe : in std_logic;		-- strobe from TDIG that marks word boundary
										-- serves as data valid to enable clock to 4bit register
			clk : in std_logic;			-- master tcpu clk
			reset : in std_logic;		-- synchronous reset 
										-- both dclk and clk must be phase aligned
			dout : out std_logic_vector(31 downto 0); -- parallel data word output to TCPU fifo 
			
			rega_en, regb_en : out std_logic -- test pins
			);
		end component ser_4bit_to_par;
		
		signal bus_data : std_logic_vector(3 downto 0);
		signal bus_clk, bus_strobe : std_logic;
		
		begin
		
			tdig_side : component par32_to_ser4
				PORT MAP (clk => tdig_clk,
						  reset => tdig_reset,
						  din => tdig_data_in,
						  din_strobe => tdig_send_strobe,
						  dclk => bus_clk,
						  dout => bus_data,
						  dout_strobe => bus_strobe,
						  ready => tdig_ready
						);				
			
			-- cable signals
			cable_data <= bus_data;
			cable_data_clk <= bus_clk;
			cable_data_strobe <= bus_strobe;
						
		   	tcpu_side : component ser_4bit_to_par
				port map ( clk => tcpu_clk,
						   reset => tcpu_reset,
						   din => bus_data,
						   dclk => bus_clk, 
						   dstrobe => bus_strobe,
						   dout => tcpu_dout
						 );
	end architecture lwba;
	
	
			
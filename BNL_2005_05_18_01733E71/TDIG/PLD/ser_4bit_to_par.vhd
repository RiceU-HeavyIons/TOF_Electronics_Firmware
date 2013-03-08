	
	
	-- Filename : ser_4bit_to_par.vhd
	-- Date : 9/9/04
	
	-- Modified : 11/17/04 
	--	changed register b clock to main clock, not data clock
	--   inverted data clock for all operations, so data nibbles are clock in middle of data period	
	--
	-- Modified : 11/12/04 to eliminate sm_sync_enable and pipeline delay for writing to 2nd register
	

	
	-- Author : L. Bridges / Blue Sky Electronics, LLC
	--
	-- 32bit TDC words are transmitted from TDIG to TCPU over a 4bit cable, along
	-- with a transmit clock and a data strobe. The data strobe is active high while 
	-- the 8 4bit words are presented to TCPU, and then goes low before a new set
	-- of 8 4bit words is transmitted.
	--
	-- This module demultiplexes the 8 4bit words and presents them as a registered 32bit
	-- output, synchronous with the TCPUs internal clock. Once the 32bit output word is valid,
	-- the circuit produces an output strobe that can be used to as a clock enable signal
	-- to clock the data into a register or fifo.
	--	
	-- The first 4bits in become the most significant 4bits in the 32bit output word
	--
	-- The module is designed so that skew between the transmitted clock from TDIG
	-- does not have to have a particular phase relationship with the TDIG clock, as
	-- long as the phase difference is constant. Since the TDIG is the ultimate source
	-- for the TDIG clock, this requirement should be met.
	--
	-- The module is also designed so that the TDIG transmit clock can be an integer
	-- multiple of the TCPU clock, although data rates in the system do not require this.
	-- 
          
    LIBRARY ieee; USE ieee.std_logic_1164.all;          
    LIBRARY lpm; USE lpm.lpm_components.all;
    use work.tdig_package.all;
	
	-- clock ('dclk') and clock enable ('dstrobe') for 4bit registers are sourced 
	-- by TDIG and are independent of clock ('clk') and clock enable 
	-- ('clocken_final') for 32bit register
	 
	entity ser_4bit_to_par is
		port( din 	: in std_logic_vector(3 downto 0); -- data from tdig
			dclk 	: in std_logic;		-- source synchronous clock from TDIG
			dstrobe 	: in std_logic;		-- strobe from TDIG that marks word boundary
										-- serves as data valid to enable clock to 4bit register
			clk 		: in std_logic;		-- master tcpu clk
			reset	: in std_logic;		-- synchronous reset 
										-- both dclk and clk must be phase aligned
			dout 	: out std_logic_vector(31 downto 0); -- parallel data word output to TCPU fifo 
			output_strobe : out std_logic );
			
	end entity ser_4bit_to_par;	
	
	architecture lwb1 of ser_4bit_to_par is

		-- outputs of the eight pipelined registers:
		signal d0, d1, d2, d3, d4, d5, d6, d7 : std_logic_vector(3 downto 0);
		
		signal rega_enable, regb_enable, data_ready : std_logic;
		signal rega_out : std_logic_vector(31 downto 0);
		signal ff1_out, ff2_out, ff3_out, ff4_out, inv_dclk : std_logic;
		
	begin
	
		output_strobe <= data_ready;
		inv_dclk <= not dclk;
		
		-- ******************************************************************
		-- CONTROL PORTION
		
		-- state machine looks for data strobe signal from TDIG : 'dstrobe' (active hi)
		-- this signals the beginning of 8 consecutive 4bit words
		-- the state machine enables the parallel register once the 8 serial registers are loaded.
		
		-- Note that state machine uses data clock, not main clk.
		-- Clock enable for rega appears 1 clock after end of dstrobe.
		
		rega_write_sm : component ctl4to32
			PORT MAP (  reset 	=> reset,
					  dstrobe => dstrobe,
					  clk 	=> inv_dclk,	  
					  rega_en => rega_enable); 
		
		-- reg_a_sm and the 4 to 32 deserializer registers below run from downstream clock, 
		-- which can be up to 15 feet away. So this clock can be skewed more than 50% relative
		-- to the local clock. The 3 flip flops below take the clock enable for the first 32 bit 
		-- register in the data path, and synchronize it to the local clock to produce a clock
		-- enable pulse for the second register.							       
		
		sync_ff1 : DFF_sclr PORT MAP (	-- catch the rising edge of rega clock enable
			clock => rega_enable,
			sclr	 => '0',
			aclr  => ff2_out,
			data	 => '1',
			q	 => ff1_out);
		
		sync_ff2 : DFF_sclr PORT MAP (	-- delay the clock enable to regb by one clock to account
									-- for clock skew due to 15' clock cable
			clock => clk,
			sclr	 => ff2_out,
			aclr  => reset,
			data	 => ff1_out,
			q	 => ff2_out);
			
		sync_ff3 : DFF_sclr PORT MAP (	-- put out a synchronous clock enable for the 2nd 32bit register
			clock => clk,
			sclr	 => '0',
			aclr  => reset,
			data	 => ff2_out,
			q	 => ff3_out);		
			
		regb_enable <= ff3_out;  
		
		sync_ff4 : DFF_sclr PORT MAP (	-- put out data valid pulse for fifo following second register
			clock => clk,
			sclr	 => '0',
			aclr  => reset,
			data	 => ff3_out,
			q	 => ff4_out);
		
		data_ready <= ff4_out;
				
		-- ******************************************************************
		-- DATA PATH PORTION
		
		
		-- reg0 => reg1 => ... => reg7 => reg_outa => reg_outb
		
		-- 8 four bit registers in series, clocked with 'dclk' input data clock from TDIG
		-- followed by a first 32 bit output register, also clocked with 'dclk' input data clock
		-- followed by a second 32 bit output register, clocked with local main clock	
		
		-- 'dclk' can be several times faster than the 40 Mhz TCPU main clock
		
		-- All of these registers are controlled with clock enable signals. 
		-- The 'dstrobe' signal from TDIG serves directly as the clock enable for the 4bit 
		-- registers. Clock enable signals for the two 32bit registers come 
		-- from controllers above.
		
		reg0 : component reg4_en
			PORT MAP (clock	 => inv_dclk,
					enable	 => dstrobe,
					sclr	 	 => reset,
					data	 	 => din,
					q	 	 => d0 );
					
		reg1 : component reg4_en
			PORT MAP ( clock	 => inv_dclk,
					enable	 => dstrobe,
					sclr	 	 => reset,
					data	 	 => d0,
					q	 	 => d1);
					
		reg2 : component reg4_en
			PORT MAP (clock	 => inv_dclk,
					enable	 => dstrobe,
					sclr	 	 => reset,
					data	 	 => d1,
					q	 	 => d2);
					
		reg3 : component reg4_en
			PORT MAP (clock	 => inv_dclk,
					enable	 => dstrobe,
					sclr	 	 => reset,
					data	 	 => d2,
					q	 	 => d3);
					
		reg4 : component reg4_en
			PORT MAP (clock	 => inv_dclk,
					enable	 => dstrobe,
					sclr	 	 => reset,
					data	 	 => d3,
					q	 	 => d4);
					
		reg5 : component reg4_en
			PORT MAP (clock	 => inv_dclk,
					enable	 => dstrobe,
					sclr	 	 => reset,
					data	 	 => d4,
					q	 	 => d5);
					
		reg6 : component reg4_en
			PORT MAP (clock	 => inv_dclk,
					enable	 => dstrobe,
					sclr	 	 => reset,
					data	 	 => d5,
					q	 	 => d6);
					
		reg7 : component reg4_en
			PORT MAP (clock	 => inv_dclk,
					enable	 => dstrobe,
					sclr	 	 => reset,
					data 	 => d6,
					q	 	 => d7);
			
		-- series register outputs feed 32 bit output register in parallel
		-- clock for output register is 'dclk' from TDIG
		
		reg_outa : component reg32_en PORT MAP (
				clock	 => inv_dclk,
				enable	 => rega_enable,
				sclr	 => reset,
				data(31 downto 28)	 => d7,
				data(27 downto 24)	 => d6,
				data(23 downto 20)	 => d5,
				data(19 downto 16)	 => d4,
				data(15 downto 12)	 => d3,
				data(11 downto 8)	 => d2,
				data(7 downto 4)	 => d1,
				data(3 downto 0)	 => d0,
				q	 			 => rega_out);	
				
		reg_outb : component reg32_en PORT MAP (
				clock	 => clk,
				enable	 => regb_enable,
				sclr	 	 => reset,
				data	 	 => rega_out,
				q	 	 => dout);			
	
	end;
	
	
			
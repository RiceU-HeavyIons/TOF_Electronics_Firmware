    -- Filename : data_path_control.vhd
	--
	-- replaces control2.vhd as of 10/26/05
	--
	-- Date : 10/3/2004
	-- Author : L. Bridges / Blue Sky Electronics, LLC
	--
	-- This module is the controller for the core TCPU data path.
	-- That data path consists of 5 input fifos and 2 output fifos. The five input fifos
	-- recieve data automatically from the trigger (TCD) and the four TDIG input cables.
	-- This controller reads each of the 5 input fifos, starting with the trigger fifo, 
	-- and writes their data to one of the two output fifos, according to the trigger command
	-- sequence.
	--
	-- Internally the 5 input fifos are selected by a select counter. The state machine clears
	-- and increments the select counter, and decoder logic routes a 'fifo read' signal to 
	-- appropriate fifo control signal (one of five) according to the value of the counter.
	-- The select values are:
	
		--    trigger fifo = 0
		--    tdig cable 1 = 1
		--    tdig cable 2 = 2
		--    tdig cable 3 = 3
		--    tdig cable 4 = 4
	
	-- The controller sequences through reading the 5 input fifos. During each cycle, it reads once
	-- from the trigger fifo. When reading each tdig cable fifo, the controller reads until either
	-- a separator word appears (indicating the end of an trigger-matched event data set, or until
	-- a timeout counter reaches its limit.
	 
	-- The controller also controls the switching of the two output multiplexers, again based on
	-- the sequence of trigger commands. At any given time, data is written into one of the
	-- multiplexers while the other is read by the DDL interface logic. The switch logic consists
	-- of one toggle flip flop. Decoder logic routes a 'fifo write' signal to the appropriate
	-- fifo control signal (one of two) according to the value flip flop.
	
	   
    	LIBRARY ieee;
    	USE ieee.std_logic_1164.all;
            
    	LIBRARY lpm;
    	USE lpm.lpm_components.all;
    	
	use work.picotof_package.all;
	 
	entity data_path_control is port( 	
				clk, reset 	: in std_logic;
				op_mode 		: in std_logic_vector(7 downto 0);
				current_data 	: in std_logic_vector(31 downto 0);				                     			  
				in_fifo_empty 	: in std_logic_vector(4 downto 0);
				select_input 	: out std_logic_vector(2 downto 0); -- selects among 4 tdc cables and trig	
				read_input_fifo : out std_logic_vector(4 downto 0); -- goes to BOTH fifo_readen AND input register enable				
				write_ddl_fifo : out std_logic_vector(1 downto 0);
				ddl_fifo_sel 	: out std_logic; 				-- select signal for ping-pong output fifos	
				error1 		: out std_logic_vector(7 downto 0);	
				trigger_pulse 	: out std_logic;
				wr_final_fifo 	: out std_logic;
				mcu_mode		: in  std_logic_vector(7 downto 0);
				mcu_config	: in  std_logic_vector(7 downto 0);
				mcu_filter_sel : in  std_logic_vector(7 downto 0);
				wr_mcu_fifo    : out std_logic	 );								
	end entity data_path_control;
	
	architecture lwb1 of data_path_control is
	
		signal main_data_sel, ctr_sel, mcu_sel : std_logic_vector(2 downto 0);
		signal rd_fifo, wr_fifo : std_logic;
		signal switch_output_fifo, toggle, toggle_ff_in : std_logic;		
		signal clr_timeout, timeout_valid : std_logic;		
		signal clr_sel, incr_sel : std_logic;	
		signal current_fifo_empty : std_logic;				
		signal opmode1, opmode5, CMD_L0, CMD_L2, CMD_ABORT, CMD_RESET, CMD_IGNORE : std_logic;
		signal sel_eq_0, separator: std_logic;
		
		signal wr_test_fifo, sel_trig : std_logic;		
		signal dummy1, dummy2,dummy3,dummy4,dummy5,dummy6,dummy7,dummy8,dummy9,dummy10,dummy11,dummy12 : std_logic;
		signal mcu_boss_read_fifo, ctlv1_rd_fifo, enable_test_a, read_fifo_enable  : std_logic;
		signal mcu_boss_wr_mcu_fifo, ctlv1_wr_mcu_fifo : std_logic;
		
		signal infifo_empty, mcu_config_byte, test_mode : std_logic_vector(7 downto 0);

		constant acquire : std_logic_vector(7 downto 0) := X"01";		
		constant cmd_code_0 : std_logic_vector(3 downto 0) := "0000";
		constant cmd_code_1 : std_logic_vector(3 downto 0) := "0001";
		constant cmd_code_RESET : std_logic_vector(3 downto 0) := "0010";
		constant cmd_code_3 : std_logic_vector(3 downto 0) := "0011";
		constant cmd_code_4 : std_logic_vector(3 downto 0) := "0100";
		constant cmd_code_5 : std_logic_vector(3 downto 0) := "0101";
		constant cmd_code_6 : std_logic_vector(3 downto 0) := "0110";
		constant cmd_code_7 : std_logic_vector(3 downto 0) := "0111";
		constant cmd_code_8 : std_logic_vector(3 downto 0) := "1000";
		constant cmd_code_9 : std_logic_vector(3 downto 0) := "1001";
		constant cmd_code_10 : std_logic_vector(3 downto 0) := "1010";
		constant cmd_code_11 : std_logic_vector(3 downto 0) := "1011";
		constant cmd_code_12 : std_logic_vector(3 downto 0) := "1100";		
		constant cmd_code_ABORT : std_logic_vector(3 downto 0) := "1101";
		constant cmd_code_14 : std_logic_vector(3 downto 0) := "1110";		
		constant cmd_code_L2 : std_logic_vector(3 downto 0) := "1111";
		
		constant separator_id : std_logic_vector (3 downto 0) := "1110";

     	-- to change timeout period, modify 'timeout_ctr' with quartus wizard
    		-- timeout period currently set to 20 clocks
 			
	begin	
	
		-- *********************************************************************
		--
		-- Two state machines can control the main data path
		--
		-- 1. MCU_BOSS for noise testing and debugging
		-- 2. CTLV1 for normal operation under trigger control
		--
		-- *********************************************************************
		
		enable_test_a <= mcu_config(7);  
		
		state_machine_for_mcu_control : component MCU_BOSS PORT MAP (
			CLK 				=> clk,
			RESET 			=> reset,
			mcu_config_bit7 	=> enable_test_a,		-- enables this state machine
			mcu_sel_empty 		=> current_fifo_empty,
			rd_fifo 			=> mcu_boss_read_fifo,
			wr_fifo 			=> mcu_boss_wr_mcu_fifo);					
				
		TCD_controlled_state_machine: CTLV1 PORT MAP (

			-- 1. wait for mcu to declare acquire mode
			-- 2. wait for trigger command
			-- 3. read trigger command and write it to output fifo
			-- 4. when trigger command is L0 accept
					-- read each of 4 tdc cable paths (or timeout on each)
					-- write the data to output fifo
			-- 5 toggle output select		

			-- inputs
			CLK	=> clk,
			RESET	=>	reset,
			OPMODE1	=>	'0',
			FIFO_EMPTY	=> current_fifo_empty,
			CMD_L0	=>	CMD_L0,
			CMD_L2	=> 	CMD_L2,
			CMD_ABORT => 	CMD_ABORT,
			CMD_RESET =>   CMD_RESET,
			CMD_IGNORE => 	CMD_IGNORE,
			SEL_EQ_0	=>	sel_eq_0,
			SEPARATOR	=>	separator,
			TIMEOUT	=>	timeout_valid,
			TRIG_EQ_TOKEN => '0',
			
			-- outputs
			CLR_SEL	=>	clr_sel,
			CLR_TIMEOUT	=>	clr_timeout,
			CLR_TDC	=> dummy1,
			CLR_TOGGLE => dummy2,
			CLR_TOKEN => DUMMY3,
			CLR_FIFO_OUT => DUMMY10,
			CLR_INFIFO => DUMMY11,
			CLR_OUTFIFO => DUMMY12,				
			ERROR2 => DUMMY4,
			WR_DDL => DUMMY5,
			WR_L2_REG => DUMMY6,
			WR_MCU => DUMMY7,
			WR_MCU_ERROR => DUMMY8,
			WR_MCU_FIFO => ctlv1_wr_mcu_fifo,
			INCR_SEL	=>	incr_sel,
			RD_FIFO	=>	ctlv1_rd_fifo,
			WR_FIFO	=> 	wr_fifo,
			SW_DDL_FIFO => switch_output_fifo,
			TRIG_TO_TDC => trigger_pulse  );	
					
		-- *********************************************************************
		-- logic common to both state machines:
		-- *********************************************************************
		
		-- enable_test_a is a configuration bit set by the MCU which controls which state machine
		-- will be active
		

			opmode5 <= not enable_test_a; -- CTLV1 is active
			opmode1 <= enable_test_a;  -- MCU_BOSS is active			
	
			-- This mux selects whether mcu_boss or control1 state machine will control the main
			-- data path mux. The main data select controls the main data path mux and also selects 
			-- which fifo_empty signal the current state machine will look at
			
			mcu_sel <= mcu_filter_sel(2 downto 0);			
			
			choose_data_mux_ctl : two_by_3bit_mux PORT MAP (
					data1x	 => mcu_sel,
					data0x	 => ctr_sel,
					sel		 => enable_test_a,			-- mcu config bit controls this mux!
					result	 => main_data_sel );
		
			wr_mcu_fifo <= (enable_test_a and mcu_boss_wr_mcu_fifo) or (not enable_test_a and ctlv1_wr_mcu_fifo);
			
			-- multiplexer to read "fifo_empty" signal from currently selected fifo:			
			empty_signal_mux :  component mux_5_to_1 PORT MAP (
				data4	 => infifo_empty(4),
				data3	 => infifo_empty(3),
				data2	 => infifo_empty(2),
				data1	 => infifo_empty(1),
				data0	 => infifo_empty(0),
				sel	 	 => main_data_sel,
				result	 => current_fifo_empty 	);
			
			-- signal to read currently selected fifo
			-- this signal is decoded to the correct fifo in the core_data_path module
			
			read_fifo_enable <= (enable_test_a and mcu_boss_read_fifo) or (not enable_test_a and ctlv1_rd_fifo);

			decode_3to5_en_inst : decode_3to5_en PORT MAP (
					data	 => main_data_sel,
					enable => read_fifo_enable,
					eq0	 => read_input_fifo(0),
					eq1	 => read_input_fifo(1),
					eq2	 => read_input_fifo(2),
					eq3	 => read_input_fifo(3),
					eq4	 => read_input_fifo(4) );	
									
		-- *********************************************************************
		-- logic specific to CTLV1 state machine
		-- *********************************************************************
			
			-- CTLV1 increments this counter to cycle through the input fifos
			ctr_0_to_4 : component data_sel_ctr PORT MAP (
					clock	 => clk,
					cnt_en	 => incr_sel,
					sclr	 	 => clr_sel,
					aclr     	 => reset,
					q	 	 => ctr_sel );
					
			-- gated writes to ping-pong fifos
		      write_ddl_fifo(0) <= wr_fifo and not toggle;
		      write_ddl_fifo(1) <= wr_fifo and toggle;
			
			-- CTLV1 toggles this flip-flop to control writes to ping-pong fifos
				tff: component DFF_sclr PORT MAP (
					clock => clk,
					sclr	 => reset,
					aclr	 => '0',
					data	 => toggle_ff_in,
					q	 => toggle );	
									    
			-- CTLV1 uses this timeout counter to switch between input fifos if it
			-- does not get a separator from a TDIG link within the timeout period
			timeout_for_tdig : component timeout PORT MAP (
				clk	 => clk,
				reset => reset,
				clr_timeout	 => clr_timeout,
				timeout_valid => timeout_valid );	
		
			toggle_ff_in <= switch_output_fifo xor toggle;
			ddl_fifo_sel   <= toggle;
			
			-- decoder for trigger commands
			command_decode: process (current_data) is
			begin
				if current_data(31 downto 28) = separator_id then
					separator <= '1';
				else separator <= '0';
				end if;
				
				CMD_L0 <= '0';
				CMD_L2 <= '0';
				CMD_ABORT <= '0';
				CMD_RESET <= '0';
				CMD_IGNORE <= '0';
			
				case current_data(19 downto 16) is  -- trigger_command
					when cmd_code_0 => CMD_IGNORE <= '1';
					when cmd_code_1 => CMD_IGNORE <= '1';
					when cmd_code_RESET => CMD_RESET <= '1';
					when cmd_code_3 => CMD_IGNORE <= '1';
					when cmd_code_4 => CMD_L0 <= '1';
					when cmd_code_5 => CMD_L0 <= '1';
					when cmd_code_6 => CMD_L0 <= '1';
					when cmd_code_7 => CMD_L0 <= '1';
					when cmd_code_8 => CMD_L0 <= '1';
					when cmd_code_9 => CMD_L0 <= '1';
					when cmd_code_10 => CMD_L0 <= '1'; 
					when cmd_code_11 => CMD_L0 <= '1'; 
					when cmd_code_12 => CMD_L0 <= '1'; 
					when cmd_code_ABORT => CMD_ABORT <= '1';
					when cmd_code_14 => CMD_IGNORE <= '1';
					when cmd_code_L2 => CMD_L2 <= '1';
					when others => null;
				end case;				
			end process command_decode;
											
	end architecture lwb1;
	
	
			
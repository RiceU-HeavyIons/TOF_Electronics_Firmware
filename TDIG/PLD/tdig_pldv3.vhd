-- $Id: tdig_pldv3.vhd,v 1.1.1.1 2004-12-03 23:23:05 tofp Exp $

-- change log
--
-- filename is TDIG_PLDV3.VHD
--
-- VERSION F: 11/1/04
--	Added 'reset' resgister so that MCU can write individual reset bits
--
-- VERSION G: 11/2/04
--	Recoded TDC JTAG configuration bits to clean up code
--	Added status(0) = TDC error. Bit 0 of mcu read adr 3 is now the OR of error
--		bits from all 4 TDCs.
-- 

LIBRARY ieee; USE ieee.std_logic_1164.all;

LIBRARY lpm; USE lpm.lpm_components.all;

LIBRARY altera_mf; USE altera_mf.altera_mf_components.all; -- gets global clk primitive

USE work.tdig_package.all;

--  Entity Declaration

ENTITY TDIG_pldv3 IS
	PORT
	(
		SW 				: IN 	STD_LOGIC_VECTOR (2 DOWNTO 0);	-- rotary switch

		-- JTAG multiplex signals ---------------------------------		
		TDO_TDC 			: IN 	STD_LOGIC_VECTOR (4 DOWNTO 1);
		TDO_EXT, TDO_MCU 	: OUT 	STD_LOGIC;

		TCK_TDC 			: OUT 	STD_LOGIC_VECTOR (4 DOWNTO 1);
		TCK_EXT, TCK_MCU 	: IN 	STD_LOGIC;

		TMS_TDC 			: OUT 	STD_LOGIC_VECTOR (4 DOWNTO 1);
		TMS_EXT, TMS_MCU 	: IN 	STD_LOGIC;

		TDI_TDC 			: OUT 	STD_LOGIC_VECTOR (4 DOWNTO 1);
		TDI_EXT, TDI_MCU 	: IN 	STD_LOGIC;

		TRST_TDC 			: OUT 	STD_LOGIC_VECTOR (4 DOWNTO 1);
		
		-- PUSHBUTTON INPUT -------------------------------------------
		
		PUSHBUT_IN 		: IN 	STD_LOGIC;					-- DEVICE PIN N1
															-- connected to pushbutton input
															
		-----------------------------------------------------------

		-- clocks
		CLK_40M 			: IN 	STD_LOGIC; --*WHATEVER* 40MHz clock in use!  May be CXO *OR* TCPU generated
		--CLK_10M 			: IN 	STD_LOGIC; --Secondary clock from TCPU.  Originally 10MHz RHIC strobe
		CLK_FROM_MCU 		: IN 	STD_LOGIC; --Secondary clock from 20MHz CXO.  Unused.
		CLK_TO_MCU 		: OUT 	STD_LOGIC;						-- MCU clock source

		TEST 			: OUT 	STD_LOGIC_VECTOR (39 DOWNTO 0);	-- test header

		SMB_in 			: IN 	STD_LOGIC_VECTOR (3  DOWNTO 1);	-- SMB input connectors
		SMB_out 			: OUT 	STD_LOGIC;						-- SMB output connector
		
		PLD_HIT 			: OUT 	STD_LOGIC_VECTOR (1  DOWNTO 0);	-- to TDC Hit[25] & Hit[31]
		PLD_HIT_EN 		: OUT 	STD_LOGIC;						-- level converter enable

		-- TDC signals
		TDC_B_RESET 		: OUT 	STD_LOGIC_VECTOR (4  DOWNTO 1);	-- bunch reset
		TDC_E_RESET 		: OUT 	STD_LOGIC_VECTOR (4  DOWNTO 1);	-- event reset
		TDC_RESET 		: OUT 	STD_LOGIC_VECTOR (4  DOWNTO 1);	-- TDC reset
		TDC_SER_IN 		: OUT 	STD_LOGIC_VECTOR (4  DOWNTO 1);	-- serial_in
		TDC_TOKEN_IN 		: OUT 	STD_LOGIC_VECTOR (4  DOWNTO 1);	-- token_in
		TDC_TRIG 			: OUT 	STD_LOGIC_VECTOR (4  DOWNTO 1);	-- trigger
--		PARA_DATA 		: IN 	STD_LOGIC_VECTOR (7  DOWNTO 0);	-- parallel data "byte" out
--		BYTE_ID 			: IN 	STD_LOGIC_VECTOR (1  DOWNTO 0);
--		BYTE_PARITY 		: IN 	STD_LOGIC;
--		DATA_READY 		: IN 	STD_LOGIC;						-- parallel data "data_ready"
		GET_PARA_DATA 		: OUT 	STD_LOGIC;						-- parallel data "get_data"
		TDC_ERROR 		: IN 	STD_LOGIC_VECTOR (4  DOWNTO 1);	-- error pins
		TDC_SER_OUT 		: IN 	STD_LOGIC_VECTOR (4  DOWNTO 1);	-- serial data out
		TDC_STRB_OUT 		: IN 	STD_LOGIC_VECTOR (4  DOWNTO 1);	-- serial strobe out
		TDC_TEST 			: IN 	STD_LOGIC_VECTOR (4  DOWNTO 1);
		TDC_TOKEN_OUT 		: IN 	STD_LOGIC_VECTOR (4  DOWNTO 1);	-- token_out
		AUX_CLK 			: OUT 	STD_LOGIC_VECTOR (4  DOWNTO 1);

		-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		----------------------------------------------------------------------------------------
		TDC_TRIG_IN 		: IN 	STD_LOGIC;	-- trigger from TCPU
		----------------------------------------------------------------------------------------

		-- upstream connector
		DATA_VALID_US 		: OUT 	STD_LOGIC;
		US_DATA 			: OUT 	STD_LOGIC_VECTOR (3  DOWNTO 0);
		US_D_CLK 			: OUT 	STD_LOGIC;
		US_M24 				: OUT 	STD_LOGIC;
		US_MUL7 			: OUT 	STD_LOGIC_VECTOR (5  DOWNTO 0);
		

		-- downstream connector
		DATA_VALID_DS 		: IN 	STD_LOGIC;
		DS_DATA 			: IN 	STD_LOGIC_VECTOR (3  DOWNTO 0);
		DS_D_CLK 			: IN 	STD_LOGIC;
		DS_M24 			: IN 	STD_LOGIC;
		DS_MUL7 			: IN 	STD_LOGIC_VECTOR (5  DOWNTO 0);
		DS_BUFF_EN 		: OUT 	STD_LOGIC;

		-- 7-segment LED
		LED_A 			: OUT 	STD_LOGIC;
		LED_B 			: OUT 	STD_LOGIC;
		LED_C 			: OUT 	STD_LOGIC;
		LED_D 			: OUT 	STD_LOGIC;
		LED_E 			: OUT 	STD_LOGIC;
		LED_F 			: OUT 	STD_LOGIC;
		LED_G 			: OUT 	STD_LOGIC;
		LED_DP 			: OUT 	STD_LOGIC;


		TAMP_PULSE 		: OUT 	STD_LOGIC; 						-- Output to pulse generator on TAMP
		
		-- CAN controller interface
		CAN_INT 			: IN 	STD_LOGIC; 						-- interrupt from CAN controller.
		nRX0BF 			: IN 	STD_LOGIC; 						-- Interrupt from CAN controller Rx0 buffer
		nRX1BF 			: IN 	STD_LOGIC; 						-- Interrupt from CAN controller Rx1 buffer

		-- Hit inputs for multiplicity calculation.
		-- hit_hi			: IN	STD_LOGIC_VECTOR (23 downto 15);
		-- hit_mid		: IN	STD_LOGIC_VECTOR (12 downto 7);
		-- hit_lo			: IN	STD_LOGIC_VECTOR (1 downto 0);
		
		
	-- OK Hits:
 	-- 23 downto 15, 12 downto 7, 1 downto 0
		
		-- PLD-MCU interface
		MCU_DATA 			: INOUT 	STD_LOGIC_VECTOR (0 TO 7);
		MCU_CTRL4 		: IN 	STD_LOGIC;   -- mcu_adr 2
		MCU_CTRL3 		: IN 	STD_LOGIC;   -- mcu_adr 1
		MCU_CTRL2 		: IN	     STD_LOGIC;   -- mcu_adr 0
		MCU_CTRL1 		: IN 	STD_LOGIC;					-- used as !read / write signal from MCU
															--  low means pld drives 'mcu_data' pins
															--  hi means pld does not drive 'mcu_data' pins
															
		MCU_CTRL0 		: IN 	STD_LOGIC;  					-- used as reset signal
		MCU_INT1			: OUT 	STD_LOGIC;     -- fifo empty
		MCU_INT0			: IN		STD_LOGIC;     -- DATA STROBE ACTIVE HIGH
		
		MUL24_TRIG 		: IN 	STD_LOGIC;					-- M24 (Level-2) data trigger
	
		Si_ID 			: IN 	STD_LOGIC						-- INPUT NOW FOR SAFETY
	);
	
END TDIG_pldv3;

ARCHITECTURE SYN OF TDIG_pldv3 IS

	-- component declarations are in "picotof_package.vhd"

	-- signals
	SIGNAL global_clk_40M 	: STD_LOGIC;	
	SIGNAL global_reset 	: std_logic;

	SIGNAL LED_MCU 		: STD_LOGIC_VECTOR (6 DOWNTO 0);
	SIGNAL LED_EXT 		: STD_LOGIC_VECTOR (6 DOWNTO 0);

	SIGNAL trig_ff_out 		: STD_LOGIC_VECTOR (4 DOWNTO 0);
	SIGNAL bReset_ff_out	: STD_LOGIC_VECTOR (4 DOWNTO 0);
	SIGNAL hit_delay_out 	: STD_LOGIC;

	SIGNAL TDC_token 		: STD_LOGIC;
	SIGNAL state_test 		: STD_LOGIC;
	SIGNAL del_trig		: STD_LOGIC;
	
	signal gate1, gate2		: std_logic;
	
	-- DATA PATH SIGNALS --------------------------------------------------------------------------	
	
	--**************************************************************************************
	signal data_path_reset  : std_logic; -- should come from TCPU. Right now comes from global reset.
	
	--**************************************************************************************
	
	signal serializer_input_strobe  : std_logic;
	signal downstream_32b_data, downstream_fifo_out, serializer_input_data  : std_logic_vector(31 downto 0); 
	signal rdo_32b_data, tdc_fifo_out  : std_logic_vector(31 downto 0); 	
	
	signal serializer_ready, outmux_sel, outmux_clken, downstream_ready  : std_logic;
	
	signal data_enable, fifo_ds_empty, output_busy, pos_dnstrm : std_logic; -- main controller inputs
	
	signal separator : std_logic;  -- valid when data word is a separator word (high nibble = "1110"
	signal tdc_fifo_empty, tdc_fifo_full, trigger_pulse, en_tdc_rdo : std_logic; -- main controller inputs
		 	
	signal rd_ds_fifo, rd_tdc_fifo, sel_ds_fifo : std_logic; -- main controller outputs
	
	signal fifo_ds_full, rdo_dout_strobe : std_logic; -- test signal, not used
	
	signal switch_lsb, pushbutton_debounced_input, mcu_mux_sel : std_logic;
	signal data_to_mcu, data_from_mcu, test_data, mode_data : std_logic_vector (7 downto 0); 
	signal mcu_decode, tdc_mirror_fifo_data, jtag_data, status_data : std_logic_vector (7 downto 0); 
	signal config_data, reset_data : std_logic_vector (7 downto 0); 
	
	signal mcu_adr : std_logic_vector (2 downto 0);
	
	signal mcu_fifo_empty, data_strobe, dummy, readbar_write : std_logic;
	signal mcu_write_to_pld, mcu_read_from_pld, reset_from_mcu, mcu_read_tdc_data_strobe: std_logic;
	
	signal gated_separator, no_trigger, no_separator : std_logic;
	signal test_reg_write, mode_reg_write, config_reg_write : std_logic; -- wr enables mcu writes to registers
	signal jtag_reg_write, reset_reg_write				 : std_logic; -- wr enables mcu writes to registers
	
	signal timeout, clr_timeout, hold : std_logic; -- signals from / to timeout counter for downstream TDIG reads
	signal dummy8 : std_logic_vector(7 downto 0);
		
	signal source_sel : std_logic; --selects source for JTAG TDC configuration: 1 = mcu, 0 = byteblaster
	
	signal tdc_select_from_mcu : std_logic_vector(1 downto 0);    -- TDC selection from MCU 
	signal tdc_select_from_switch : std_logic_vector(1 downto 0); -- TDC selection from rotary switch
	signal tdc_adr : std_logic_vector(1 downto 0);		    -- resultant TDC selection
	signal active_tdo, tck_source, tms_source, tdi_source : std_logic; 
	signal tdc_active : std_logic_vector(4 downto 1);
	
	signal sig_tck_tdc, sig_tms_tdc, sig_tdi_tdc	 : std_logic_vector(4 downto 1);
	signal inv_global_clk : std_logic;
	
BEGIN

	-- hardware reset directly to reset pin on TDCs:
	-- 	ALL TDCs are reset in common if MCU writes a '1' to reset register (address 4), bit 0 
	--	TDC1 is reset individually if MCU writes a '1' to reset register (address 4), bit 1
	--	TDC2 is reset individually if MCU writes a '1' to reset register (address 4), bit 2
	--	TDC3 is reset individually if MCU writes a '1' to reset register (address 4), bit 3
	--	TDC4 is reset individually if MCU writes a '1' to reset register (address 4), bit 4
	
		TDC_RESET(4) <= reset_data(0) or reset_data(4);
		TDC_RESET(3) <= reset_data(0) or reset_data(3);
		TDC_RESET(2) <= reset_data(0) or reset_data(2);
		TDC_RESET(1) <= reset_data(0) or reset_data(1);
		
	-- bunch reset from TCPU
	
		TDC_B_RESET(1) 	<= MUL24_TRIG;
		TDC_B_RESET(2) 	<= MUL24_TRIG;
		TDC_B_RESET(3) 	<= MUL24_TRIG;
		TDC_B_RESET(4) 	<= MUL24_TRIG;
		
		-- TEMPORARILY DISABLED
		
		--TDC_B_RESET(1) 	<= '0';
		--TDC_B_RESET(2) 	<= '0';
		--TDC_B_RESET(3) 	<= '0';
		--TDC_B_RESET(4) 	<= '0';	
	
	-- trigger from TCPU
	
		-- go to 4 outputs : 
	
		tdc_trig(1) <= trig_ff_out(4);
		tdc_trig(2) <= trig_ff_out(4);
		tdc_trig(3) <= trig_ff_out(4);
		tdc_trig(4) <= trig_ff_out(4);
		
		-- TEMPORARILY DISABLED
			
		--tdc_trig(1) <= '0';
		--tdc_trig(2) <= '0';
		--tdc_trig(3) <= '0';
		--tdc_trig(4) <= '0';

	-- INACTIVE HPTDC CONTROLS -------------------------------------------------------------------
	
	AUX_CLK 		<= "0000";
	GET_PARA_DATA 	<= '0';
	PLD_HIT 		<= "00";
	PLD_HIT_EN 	<= '0';
	TDC_E_RESET 	<= "0000";
			
	-- error bits from TDC 1-4 are OR'd together and routed to STATUS buffer (MCU read address = 0
	
	status_data(0) <= TDC_ERROR(4) or TDC_ERROR(3) or TDC_ERROR(2) or TDC_ERROR(1);
	
	-- bidirectional buffer to/from MCU and registers and buffers  -------------------------------
	
	reset_from_mcu 	<= MCU_CTRL0;
	readbar_write 		<= MCU_CTRL1;
	mcu_adr(0)		<= MCU_CTRL2;
	mcu_adr(1) 		<= MCU_CTRL3;
	mcu_adr(2) 		<= MCU_CTRL4;
	
	data_strobe 		<= MCU_INT0;
	MCU_INT1 			<= mcu_fifo_empty; 
	
	mcu_write_to_pld <= data_strobe and readbar_write; 
	mcu_read_from_pld <= data_strobe and (not mcu_write_to_pld);
	
	mcu_bus : bus_tri_8 PORT MAP (
		data	 	 => data_to_mcu,
		enabledt	 => mcu_read_from_pld,
		enabletr	 => mcu_write_to_pld,
		tridata	 => MCU_DATA(0 TO 7),
		result	 => data_from_mcu );
		
	mcu_write_decoder : decoder_3_to_8 PORT MAP (
			data	 => mcu_adr,
			eq0	 => mcu_decode(0),
			eq1	 => mcu_decode(1),
			eq2	 => mcu_decode(2),
			eq3	 => mcu_decode(3),
			eq4	 => mcu_decode(4),
			eq5	 => mcu_decode(5),
			eq6	 => mcu_decode(6),
			eq7	 => mcu_decode(7) );	
	
	-- mcu writes to registers when strobe and adr produce valid register clk enables
	   
	   test_reg_write 	<= mcu_decode(0) and mcu_write_to_pld;
	   mode_reg_write 	<= mcu_decode(1) and mcu_write_to_pld;
	   config_reg_write <= mcu_decode(2) and mcu_write_to_pld;
	   jtag_reg_write 	<= mcu_decode(3) and mcu_write_to_pld;
	   reset_reg_write 	<= mcu_decode(4) and mcu_write_to_pld;
	   
	-- registers that are written to by MCU  -------------------------------
			
	test_register : reg8_en PORT MAP (
		clock	=> global_clk_40M,
		enable	=> test_reg_write,
		sclr	 	=> reset_from_mcu,
		data	 	=> data_from_mcu,
		q	 	=> test_data );
		
	mode_register : reg8_en PORT MAP (
		clock	=> global_clk_40M,
		enable	=> mode_reg_write,
		sclr	 	=> reset_from_mcu,
		data	 	=> data_from_mcu,
		q	 	=> mode_data );

	config_register : reg8_en PORT MAP (
		clock	=> global_clk_40M,
		enable	=> config_reg_write,
		sclr	 	=> reset_from_mcu,
		data	 	=> data_from_mcu,
		q	 	=> config_data );
		
	jtag_register : reg8_en PORT MAP (
		clock	=> global_clk_40M,
		enable	=> jtag_reg_write,
		sclr	 	=> reset_from_mcu,
		data	 	=> data_from_mcu,
		q	 	=> jtag_data );
		
	reset_register : reg8_en PORT MAP (
		clock	=> global_clk_40M,
		enable	=> reset_reg_write,
		sclr	 	=> reset_from_mcu,
		data	 	=> data_from_mcu,
		q	 	=> reset_data );

	-- data mux that is read by MCU  -------------------------------

	mcu_read_mux : mux_8_by_8bit PORT MAP (
			data7x	 => X"07",
			data6x	 => X"06",
			data5x(7 downto 5)	 => sw, -- left justified are 3 bits from position switch
			data5x(4 downto 0)	 => "00000",
			
			data4x	 => tdc_mirror_fifo_data,  -- tdc_data
			data3x	 => status_data,
			data2x	 => config_data,
			data1x	 => mode_data,
			data0x	 => test_data,
			sel	 	 => mcu_adr,
			result	 => data_to_mcu );
	
	mcu_read_tdc_data_strobe	<= mcu_decode(4) and mcu_read_from_pld; -- strobe to Jo's mirror fifo					
				
	----------------------------------------------------------------------------------------------


	-- TRIGGER INPUT FROM TCPU OVER UPSTREAM CONNECTOR = "TDC_TRIG_IN" SIGNAL  -------------------

	-- CLOCK DISTRIBUTION ------------------------------------------------------------------------

		-- make the clock global
		global_clk : component GLOBAL PORT MAP (a_in => CLK_40M, a_out => global_clk_40M);
		
		-- generate 20MHz clock for MCU from 40Mhz global clock 
		
		mcu_clk_gen: component tff_sclr PORT MAP (
				clock => global_clk_40M,	
				sclr	 => '0',	
				q	 => CLK_TO_MCU	);
				
	----------------------------------------------------------------------------------------------
	
	-- RESETS ------------------------------------------------------------------------------------
	
		--reset_fanout : component GLOBAL PORT MAP (a_in => '0', a_out => global_reset); 
		Reset_fanout : component GLOBAL PORT MAP (a_in => mcu_ctrl0, a_out => data_path_reset); 
	
				
		reset_button: component pushbutton_pulse port map ( 
			clk => global_clk_40M,
			reset => MCU_CTRL0,
			pushbutton => PUSHBUT_IN,
			pulseout => pushbutton_debounced_input );		
		
		-- data_path_reset <= global_reset or MCU_CTRL0 or pushbutton_debounced_input; 
	----------------------------------------------------------------------------------------------	
	

	----------------------------------------------------------------------------------------------	
	----------------------------------------------------------------------------------------------
			
	-- DATA FLOW ---------------------------------------------------------------------------------
	
		-- data flow is controlled by data flow state machine: tdig_flow_sm
	
		-- DOWNSTREAM INPUT -> (downstream)FIFO  ->   2:1 MUX  ->  UPSTREAM SERIALIZER
		
		-- TDC READOUT      -> (TDC readout)FIFO ->
		--				    -> MCU FIFO 
																
		-- where: 
			-- 1. Downstream input: 4:32 demux -> fifo (256 x 32b)  not used if board is first in chain		
					-- pin mapping:
					-- dclk
					-- din
					-- dout_strobe
			
			-- 2. 2:1 mux : 2 x 32b input -> 32b output 
			
			-- 3. Upstream serializer : 32:4 multiplexer that sends data, clock, and data output strobe
					-- pin mapping:
						-- dclk => US_D_CLK,			-- upstream output data clock
						-- dout => US_mul7(3 downto 0),  -- upstream output data (4 bits)
						-- dout_strobe => US_mul7(4),  	-- upstream output data strobe
	
			-- 4. TDC readout : readout state machine
					-- reads serial data from 4 HPTDCs and puts data in fifo, 
					-- followed by separator word
			 		-- data goes to 2 fifos:
					 	-- -> hptdc readout fifo
					 	-- -> mcu fifo existing fifo for canbus readout						
	----------------------------------------------------------------------------------------------
	
		-- DATA FLOW CONTROL AND PIN MAPPING  --------------------------------------------------------
			
			no_separator <= config_data(0);
			no_trigger <= config_data(1);
									
			tdig_main_control : component tdigctl2 port map (
				clk 			=> global_clk_40m, -- 
				reset 		=> data_path_reset, --
				data_enable 	=> data_enable, -- 
				pos_dnstrm 	=> pos_dnstrm, -- 			
				trigger_pulse 	=> tdc_trig_in,  -- trigger pulse from upstream connector				
				sel_ds_fifo 	=> sel_ds_fifo, --			
				fifo_ds_empty	=> fifo_ds_empty,--			
				rd_ds_fifo 	=> rd_ds_fifo, --				
				separator 	=> separator, --
				tdc_fifo_empty => tdc_fifo_empty, --				
				en_tdc_rdo 	=> en_tdc_rdo, -- goes to "trigger" input of tdc_rdo state machine
				rd_tdc_fifo 	=> rd_tdc_fifo, --				
				output_busy 	=> output_busy, -- 
				wr_output 	=> serializer_input_strobe,
				timeout		=> '0',
				clr_timeout    => clr_timeout  );	--
				
		
			timeout_ctr_8bit_inst : timeout_ctr_8bit PORT MAP (
					clock	 => global_clk_40m,
					cnt_en	=> hold,
					sclr	 => clr_timeout,
					q	 => dummy8,
					cout	 => timeout );
					
			hold <= not timeout;
			
	
			-- initial test setup:
			
			data_enable <= '1'; -- always turn on data path to respond to trigger inputs
			
			pos_dnstrm <= not sw(0); --switch_lsb; -- even tray position is "downstream" and reads only local fifo
								-- odd tray position is "upstream" and reads local fifo, then
			   					-- downstream fifo
								
			DS_BUFF_EN <= sw(0); --switch_lsb; -- upstream board will enable it's downstream input buffers
												
			output_busy <= not serializer_ready;
			
			-- top nibble = '1110' if separator word
			separator <= 		serializer_input_data(31) and serializer_input_data(30) 
						and  serializer_input_data(29) and not serializer_input_data(28); 
		
					
		-- DOWNSTREAM INPUT  --------------------------------------------------------------------------
		
		   	demux_for_downstream_data_inputs : component ser_4bit_to_par port map ( 
		   			clk => global_clk_40M,
					reset => data_path_reset,
					din => DS_MUL7(3 downto 0),
					dclk => DS_D_CLK, 
					dstrobe => DS_MUL7(4),
					dout => downstream_32b_data,
					output_strobe => downstream_ready );
					
			downstream_fifo : output_fifo_256x32 PORT MAP (
					clock	=> global_clk_40M,
					aclr	 	=> data_path_reset,
					data	 	=> downstream_32b_data,
					wrreq	=> downstream_ready,
					rdreq	=> RD_DS_FIFO,
					q	 	=> downstream_fifo_out,
					full	 	=> fifo_ds_full,
					empty	=> FIFO_DS_EMPTY );	
	
		----------------------------------------------------------------------------------------------	
	
		-- TDC READOUT -------------------------------------------------------------------------------
		
				-- TDC Serial readout state machine instantiation:
				
				tdc_read_sm :  ser_rdo PORT MAP (
				
					-- inputs from last tdc in chain
					
					ser_out 		=> TDC_SER_OUT(1),
					strb_out 		=> TDC_STRB_OUT(1),
					token_out 	=> TDC_TOKEN_OUT(1),  -- final token input from TDC chain
					
					-- using trigger matching? assign trig_ff_out(4)
					-- if not using trigger matching, just assign '1'
					-- REAL CONFIGURATION: use 'en_tdc_rdo' signal from main controller
					-- 11/3 test-- trigger is suspect.  go back to trig_ff_out(4)
					
					trigger		=> trig_ff_out(4),		-- en_tdc_rdo
					trg_reset 	=> data_path_reset,
					token_in 		=> TDC_token,   	-- sends output token to first tdc in chain
					
					clk 			=> global_clk_40M,
			  		reset 		=> data_path_reset,
					mcu_pld_int 	=> mcu_read_tdc_data_strobe,				
					pld_mcu_int 	=> dummy, -- not used - was a flag from pld to mcu
					mcu_byte 		=> tdc_mirror_fifo_data,  -- 8 bit data from fifo within tdc_rdo; 
													 -- this data goes to the local mcu i/f for tdig can xfer
													 
					fifo_empty 	=> mcu_fifo_empty ,  -- MCU_CTRL2
					rdo_32b_data 	=> rdo_32b_data,     -- goes to 256 x 32 fifo for xfer to upstream data path
					rdo_data_valid => rdo_dout_strobe,
					sw 			=> sw			-- position switch input for separator word
					);		
				
				TDC_TOKEN_IN(4) <= TDC_token;  -- sends output token to first tdc in chain
				-- MCU_CTRL2 	<= state_test;
				
				-- daisy-chain TDCs together:
				
				TDC_SER_IN(4) 		<= '0';
				TDC_SER_IN(3) 		<= TDC_SER_OUT(4);
				TDC_SER_IN(2) 		<= TDC_SER_OUT(3);
				TDC_SER_IN(1) 		<= TDC_SER_OUT(2);
				
				TDC_TOKEN_IN(3) 	<= TDC_TOKEN_OUT(4);
				TDC_TOKEN_IN(2) 	<= TDC_TOKEN_OUT(3);				
				TDC_TOKEN_IN(1) 	<= TDC_TOKEN_OUT(2);
				
				-- This fifo is written in parallel with a fifo that outputs to MCU.
				-- That second fifo is inside the serial rdo component.
				-- NOTE THAT the local MCU will only see data from the local TDCs
						
				local_tdc_fifo : output_fifo_256x32 PORT MAP (
					clock	=> global_clk_40M,
					aclr	 	=> data_path_reset,
					data	 	=> rdo_32b_data,
					wrreq	=> rdo_dout_strobe,
					rdreq	=> rd_tdc_fifo,
					q	 	=> tdc_fifo_out,
					full	 	=> tdc_fifo_full,
					empty	=> tdc_fifo_empty );		
					
		----------------------------------------------------------------------------------------------
		
		-- MUX AND UPSTREAM SERIALIZER ---------------------------------------------------------------
		
			outmux : mux_2x32_registered PORT MAP (
					clock	 => global_clk_40M,
					aclr		 => data_path_reset,
					clken	 => outmux_clken,
					data1x	 => downstream_fifo_out,  -- data from downstream fifo 
					data0x	 => tdc_fifo_out, -- data from local TDCs
					sel	 	 => SEL_DS_FIFO,
					result	 => serializer_input_data );
			
			outmux_clken <= rd_ds_fifo or rd_tdc_fifo;
			
					
			upstream_output_serializer : component par32_to_ser4 PORT MAP (
					clk => global_clk_40M,
					reset => data_path_reset,
					din => serializer_input_data,
					din_strobe => serializer_input_strobe,
					
					dclk => US_D_CLK,			-- upstream output data clock
					dout => US_mul7(3 downto 0),  -- upstream output data (4 bits)
					dout_strobe => US_mul7(4),  	-- upstream output data strobe
					
					ready => serializer_ready );	-- serializer ready for new input data
											-- serializer takes 8+ clocks to serialize data
												
	----------------------------------------------------------------------------------------------	
	----------------------------------------------------------------------------------------------

	-- TEST HEADER SIGNAL ROUTING ----------------------------------------------------------------
		
	-- test header
	
	TEST(39 DOWNTO 15) <= (OTHERS => '0');
	
	-- these are signals for logic-analyzer probing
	TEST(0) 	<= TDC_SER_OUT(1);
	TEST(2) 	<= TDC_STRB_OUT(1);
	TEST(4) 	<= TDC_TOKEN_OUT(1);
	TEST(6) 	<= TDC_token;
	TEST(8) 	<= en_tdc_rdo;
	TEST(10) 	<= data_path_reset;	
	TEST(12)	<= TDC_TRIG_IN;
	TEST(14)	<= trig_ff_out(4);

	----------------------------------------------------------------------------------------------
	-- LED CONTROLS
	------------------------------------------------------------------------
		
	-- For a 0-7 counter based on the external switch:
		LED_EXT(0) <= SW(1) OR (NOT SW(1) AND NOT(SW(0) XOR SW(2)));
		LED_EXT(1) <= NOT SW(2) OR (SW(2) AND NOT(SW(1) XOR SW(0)));
		LED_EXT(2) <= SW(2) OR NOT SW(1) OR SW(0);
		LED_EXT(3) <= (NOT SW(2) AND (NOT SW(0) OR SW(1))) OR (SW(1) AND NOT SW(0)) OR (SW(2) AND NOT SW(1) AND SW(0));
		LED_EXT(4) <= NOT SW(0) AND (SW(1) OR NOT SW(2));
		LED_EXT(5) <= (NOT SW(1) AND (NOT SW(0))) OR (SW(2) AND (SW(1) XOR SW(0)));
		LED_EXT(6) <= (SW(1) AND NOT SW(0)) OR (SW(2) AND NOT SW(1)) OR (NOT SW(2) AND SW(1) AND SW(0));
		
	-- For a 1-4 counter based on the external switch:	
	--	LED_EXT(0) <= (SW(0) XOR SW(1));
	--	LED_EXT(1) <= '1';
	--	LED_EXT(2) <= NOT(SW(0) AND NOT SW(1));
	--	LED_EXT(3) <= (SW(0) XOR SW(1));
	--	LED_EXT(4) <= (SW(0) AND NOT SW(1));
	--	LED_EXT(5) <= (SW(0) AND SW(1));
	--	LED_EXT(6) <= NOT(NOT SW(0) AND NOT SW(1));
		
		-- Which TDC does MUX point at (uses SW(1:0) and displays [4:1])
		LED_A <= LED_EXT(0);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(0);
		LED_B <= LED_EXT(1);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(1);
		LED_C <= LED_EXT(2);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(2);
		LED_D <= LED_EXT(3);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(3);
		LED_E <= LED_EXT(4);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(4);
		LED_F <= LED_EXT(5);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(5);
		LED_G <= LED_EXT(6);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(6);
		
		LED_DP <= NOT MCU_CTRL1;
		
	----------------------------------------------------------------------------------------------
	-- mcuctrl 1  goes to jtag_data(2)
	-- mcuint 1 goes to jtag_data(1)
	-- mcuint 0 goes to jtag_data(0)

	-- JTAG SIGNALS TO HPTDCs --------------------------------------------------------------------
	
		--tck_tdc(1) <= tck_ext;
		--tck_tdc(4 downto 2) <= "000";
		
		--tms_tdc(1) <= tms_ext;
		--tms_tdc(4 downto 2) <= "111";
		
		--tdi_tdc(1) <= tdi_ext;
		--tdi_tdc(4 downto 2) <= "000";
 		
		-- ************************************************************************
		-- 2:1 select for TDC configuration from one of 2 sources:
		--		1: MCU
		--		0: Byteblaster port
		
		trst_tdc(4 DOWNTO 1) <= "1111";  -- default inactive TRST to all 4 TDCs !!!!!
								   -- Byteblaster does not source TRST
		
		source_sel <= jtag_data(2); -- 1 selects mcu jtag, 0 selects byteblaster jtag
							   -- jtag_data is a register written by mcu at adr = 3
							   
		
		source_select_mux : mux_2_to_1_3bit PORT MAP (
		
				data1x(2)	 => tck_mcu,
				data1x(1)	 => tms_mcu,
				data1x(0)	 => tdi_mcu,				
				
				data0x(2)	 => tck_ext,
				data0x(1)	 => tms_ext,						
				data0x(0)	 => tdi_ext,
					
				result(2)	 => tck_source, 
				result(1)	 => tms_source, 
				result(0)	 => tdi_source,
				
				sel	 	 => source_sel );
		
		-- Four muxes route the jtag signals to the 4 TDCs
		-- If the TDC in not currently selected, inactive default signals are
		-- selected for the JTAG inputs.					

		TDC4_jtag_input : mux_2_to_1_3bit PORT MAP (
		
				data1x(2)	 => tck_source,
				data1x(1)	 => tms_source,
				data1x(0)	 => tdi_source,
				
				data0x(2)	 => '0',
				data0x(1)	 => '1',
				data0x(0)	 => '0',
				
				result(2)	 => sig_tck_tdc(4),
				result(1)	 => sig_tms_tdc(4),
				result(0)  => sig_tdi_tdc(4),
				
				sel	 	 => TDC_active(4) );					

		TDC3_jtag_input : mux_2_to_1_3bit PORT MAP (
		
				data1x(2)	 => tck_source,
				data1x(1)	 => tms_source,
				data1x(0)	 => tdi_source,
				
				data0x(2)	 => '0',
				data0x(1)	 => '1',
				data0x(0)	 => '0',
				
				result(2)	 => sig_tck_tdc(3),
				result(1)	 => sig_tms_tdc(3),
				result(0)  => sig_tdi_tdc(3),
				
				sel	 	 => TDC_active(3) );

		TDC2_jtag_input : mux_2_to_1_3bit PORT MAP (
		
				data1x(2)	 => tck_source,
				data1x(1)	 => tms_source,
				data1x(0)	 => tdi_source,
				
				data0x(2)	 => '0',
				data0x(1)	 => '1',
				data0x(0)	 => '0',
				
				result(2)	 => sig_tck_tdc(2),
				result(1)	 => sig_tms_tdc(2),
				result(0)  => sig_tdi_tdc(2),
				
				sel	 	 => TDC_active(2) );

		TDC1_jtag_input : mux_2_to_1_3bit PORT MAP (
		
				data1x(2)	 => tck_source,
				data1x(1)	 => tms_source,
				data1x(0)	 => tdi_source,
				
				data0x(2)	 => '0',
				data0x(1)	 => '1',
				data0x(0)	 => '0',
				
				result(2)	 => sig_tck_tdc(1),
				result(1)	 => sig_tms_tdc(1),
				result(0)  => sig_tdi_tdc(1),
				
				sel	 	 => TDC_active(1) );
				
		-- MAP OUTPUT JTAG SIGNALS TO PLD PINS
		
				tck_tdc <= sig_tck_tdc;
				tms_tdc <= sig_tms_tdc;
				tdi_tdc <= sig_tdi_tdc;	
																			
		-- ************************************************************************
		-- select control source for TDC selection:
		--	if configuration source is MCU (source_sel = 1) then mcu selects active
		--		TDC with jtag_data(1..0)
		--	if configuration source is Byteblaster, then the rotary switch (2 lsbs of 
		--		3 bits) selects the active TDC
		
		tdc_select_from_mcu <= jtag_data(1 downto 0);
		tdc_select_from_switch <= sw(1 downto 0);
		
		select_tdc_destination : mux_2_to_1_2bit PORT MAP (
		
			data1x	 => tdc_select_from_mcu,
			data0x	 => tdc_select_from_switch,
			sel	 	 => source_sel,
			result	 => tdc_adr );  -- serves as select for TDC select mux		
		
		-- selected TDC address selects the active TDC
		
		select_tdc : decode_1_to_4 PORT MAP (  

			data	 => tdc_adr,
			eq0	 => TDC_active(1),
			eq1	 => TDC_active(2),
			eq2	 => TDC_active(3),
			eq3	 => TDC_active(4)	);
		
		-- TDC address also selects TDO return from TDC to MCU
		
		mux_4_to_1_1bit_inst : mux_4_to_1_1bit PORT MAP (
		
			data3	 => TDO_TDC(4),
			data2	 => TDO_TDC(3),
			data1	 => TDO_TDC(2),
			data0	 => TDO_TDC(1),
			sel	 	 => tdc_adr,
			result	 => active_tdo );

		-- route TDO return from active TDC to both MCU and byteblaster ports
		
		tdo_ext <= active_tdo;
		tdo_mcu <= active_tdo;

		
--*************************************************************************************************
-- UNUSED CODE TO CONTROL JTAG SIGNALS TO TDC
--*************************************************************************************************

		--tck_tdc(1) <= tck_ext WHEN (SW(1)='0' AND SW(0)='0' AND jtag_data(2)='0') ELSE
		--			  tck_mcu WHEN (jtag_data(1)='0' AND jtag_data(0)='0' AND jtag_data(2)='1') ELSE 'Z';
		--tck_tdc(2) <= tck_ext WHEN (SW(1)='0' AND SW(0)='1' AND jtag_data(2)='0') ELSE
		--			  tck_mcu WHEN (jtag_data(1)='0' AND jtag_data(0)='1' AND jtag_data(2)='1') ELSE 'Z';
		--tck_tdc(3) <= tck_ext WHEN (SW(1)='1' AND SW(0)='0' AND jtag_data(2)='0') ELSE
		--			  tck_mcu WHEN (jtag_data(1)='1' AND jtag_data(0)='0' AND jtag_data(2)='1') ELSE 'Z';
		--tck_tdc(4) <= tck_ext WHEN (SW(1)='1' AND SW(0)='1' AND jtag_data(2)='0') ELSE
		--			  tck_mcu WHEN (jtag_data(1)='1' AND jtag_data(0)='1' AND jtag_data(2)='1') ELSE 'Z';
	
		--tms_tdc(1) <= tms_ext WHEN (SW(1)='0' AND SW(0)='0' AND jtag_data(2)='0')ELSE
		--			  tms_mcu WHEN (jtag_data(1)='0' AND jtag_data(0)='0' AND jtag_data(2)='1') ELSE 'Z';
		--tms_tdc(2) <= tms_ext WHEN (SW(1)='0' AND SW(0)='1' AND jtag_data(2)='0')ELSE
		--			  tms_mcu WHEN (jtag_data(1)='0' AND jtag_data(0)='1' AND jtag_data(2)='1') ELSE 'Z';
		--tms_tdc(3) <= tms_ext WHEN (SW(1)='1' AND SW(0)='0' AND jtag_data(2)='0')ELSE
		--			  tms_mcu WHEN (jtag_data(1)='1' AND jtag_data(0)='0' AND jtag_data(2)='1') ELSE 'Z';
		--tms_tdc(4) <= tms_ext WHEN (SW(1)='1' AND SW(0)='1' AND jtag_data(2)='0')ELSE
		--			  tms_mcu WHEN (jtag_data(1)='1' AND jtag_data(0)='1' AND jtag_data(2)='1') ELSE 'Z';
	
		--tdi_tdc(1) <= tdi_ext WHEN (SW(1)='0' AND SW(0)='0' AND jtag_data(2)='0')ELSE
		--			  tdi_mcu WHEN (jtag_data(1)='0' AND jtag_data(0)='0' AND jtag_data(2)='1') ELSE 'Z';
		--tdi_tdc(2) <= tdi_ext WHEN (SW(1)='0' AND SW(0)='1' AND jtag_data(2)='0')ELSE
		--			  tdi_mcu WHEN (jtag_data(1)='0' AND jtag_data(0)='1' AND jtag_data(2)='1') ELSE 'Z';
		--tdi_tdc(3) <= tdi_ext WHEN (SW(1)='1' AND SW(0)='0' AND jtag_data(2)='0')ELSE
		--			  tdi_mcu WHEN (jtag_data(1)='1' AND jtag_data(0)='0' AND jtag_data(2)='1') ELSE 'Z';
		--tdi_tdc(4) <= tdi_ext WHEN (SW(1)='1' AND SW(0)='1' AND jtag_data(2)='0')ELSE
		--			  tdi_mcu WHEN (jtag_data(1)='1' AND jtag_data(0)='1' AND jtag_data(2)='1') ELSE 'Z';
	
		--tdo_mcu <=	tdo_tdc(1) WHEN (jtag_data(1)='0' AND jtag_data(0)='0' AND jtag_data(2)='1') ELSE
		--			tdo_tdc(2) WHEN (jtag_data(1)='0' AND jtag_data(0)='1' AND jtag_data(2)='1') ELSE
		--			tdo_tdc(3) WHEN (jtag_data(1)='1' AND jtag_data(0)='0' AND jtag_data(2)='1') ELSE
		--			tdo_tdc(4);
	
		--tdo_ext <=	tdo_tdc(1) WHEN (SW(1)='0' AND SW(0)='0' AND jtag_data(2)='0') ELSE
		--			tdo_tdc(2) WHEN (SW(1)='0' AND SW(0)='1' AND jtag_data(2)='0') ELSE
		--			tdo_tdc(3) WHEN (SW(1)='1' AND SW(0)='0' AND jtag_data(2)='0') ELSE
		--			tdo_tdc(4);

--*************************************************************************************************
-- END OF UNUSED CODE TO CONTROL JTAG SIGNALS TO TDC
--*************************************************************************************************


--*************************************************************************************************
-- UNUSED CODE TO DO SYNCHRONOUS DATA ACQUISITION
--*************************************************************************************************

	
	-- TEST SIGNAL PROCESSING FOR SYNCHRONOUS ACQUISITION TEST, ETC ------------------------------
		
	-- trigger pulse from SMB IN[1]
	-- sync SMB IN[1] to 40MHz and shorten to one clock
	trig_ff0 : dff_sclr_sset 
	  PORT MAP (
		data 		=> TDC_TRIG_IN, --SMB_in(1), 
		q 		=> trig_ff_out(0), 
		clock 	=> global_clk_40M, 
		sclr 	=> '0', 
		sset 	=> '0' );

	G1: FOR i IN 1 TO 3 GENERATE
		trig_ffs : dff_sclr_sset
		  PORT MAP (
			data		=> trig_ff_out(i-1), 
			q 		=> trig_ff_out(i), 
			clock 	=> global_clk_40M, 
			sclr 	=> '0', 
			sset 	=> '0'  );			
	END GENERATE;

	trig_ff4 : dff_sclr_sset 
	  PORT MAP (
		data 		=> gate1, 
		q 		=> trig_ff_out(4), 
		clock 	=> global_clk_40M, 
		sclr 	=> '0', 
		sset 	=> '0' );

	gate1 <= trig_ff_out(2) AND (NOT trig_ff_out(3));
	
	inv_global_clk <= NOT global_clk_40M;
	
	 --delay trigger
	trig_delay : LPM_SHIFTREG 
	  GENERIC MAP (
		lpm_type 		=> "LPM_SHIFTREG",
		lpm_width 		=> 38,
		lpm_direction 	=> "RIGHT"
	 )
	  PORT MAP (
		clock 		=> inv_global_clk, 
		shiftin 	=> trig_ff_out(4),
		shiftout 	=> del_trig 
	 );
	 
		 --use trig_ff_out(4) to trigger TDCs:
	--	TDC_TRIG(1) <= TDC_TRIG_IN; --trig_ff_out(4)
	--	TDC_TRIG(2) <= TDC_TRIG_IN; --trig_ff_out(4);
	--	TDC_TRIG(3) <= TDC_TRIG_IN; --trig_ff_out(4);
	--	TDC_TRIG(4) <= TDC_TRIG_IN; --trig_ff_out(4);
	

	
	 --TDC Bunch reset from SMB IN[2]
	 --sync SMB IN[2] to 40MHz and shorten to one clock
	bReset_ff0 : dff_sclr_sset 
	  PORT MAP (
		data 		=> SMB_in(2), 
		q 		=> bReset_ff_out(0), 
		clock 	=> global_clk_40M, 
		sclr 	=> '0', 
		sset 	=> '0'  );

	G2: FOR i IN 1 TO 3 GENERATE
		bReset_ffs : dff_sclr_sset
		  PORT MAP (
			data 		=> bReset_ff_out(i-1), 
			q 		=> bReset_ff_out(i), 
			clock 	=> global_clk_40M, 
			sclr 	=> '0', 
			sset 	=> '0' );			
	END GENERATE;

	bReset_ff4 : dff_sclr_sset 
	  PORT MAP (
		data 		=> gate2, 
		q 		=> bReset_ff_out(4), 
		clock 	=> global_clk_40M, 
		sclr 	=> '0', 
		sset 	=> '0' );
	  
	gate2 <= bReset_ff_out(2) AND (NOT bReset_ff_out(3));


	-- delay sync'd pulse and use on SMB connector "OUT".
	-- this is for use in "synchronous acquisition
	hit_delay : LPM_SHIFTREG 
	  GENERIC MAP (
		lpm_type 		=> "LPM_SHIFTREG",
		lpm_width 		=> 8,
		lpm_direction 	=> "RIGHT"
	  )
	  PORT MAP (
		clock 		=> global_clk_40M, 
		shiftin 	=> bReset_ff_out(4),
		shiftout 	=> hit_delay_out 
	  );
	  
	SMB_OUT 		<= hit_delay_out;
	--------------------------------------------------------------------------------------------------
--*************************************************************************************************
-- END UNUSED CODE TO DO SYNCHRONOUS DATA ACQUISITION
--*************************************************************************************************
			
END SYN;
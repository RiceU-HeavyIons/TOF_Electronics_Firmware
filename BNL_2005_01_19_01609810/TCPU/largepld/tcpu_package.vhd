LIBRARY ieee; USE ieee.std_logic_1164.all;       
LIBRARY lpm; USE lpm.lpm_components.all;

package tcpu_package is

	-- components from primitives
	
		-- to use the global primitive in modelsim: add the following lines
		-- to the source file:
		
			-- LIBRARY altera_mf;
			-- USE altera_mf.altera_mf_components.all;
			
			
			--COMPONENT GLOBAL
		   		--PORT (a_in : IN STD_LOGIC;
		      		--a_out: OUT STD_LOGIC);
			--END COMPONENT;
			
	-- tri-state and bidirectional buffers *****************************	
	
	component bus_tri_8 PORT (
		data			: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		enabledt		: IN STD_LOGIC ;
		enabletr		: IN STD_LOGIC ;
		tridata		: INOUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0) );
	end component;

	-- ********************************************************************************
	-- DDL COMPONENT definition (JS)
	-- ********************************************************************************
			COMPONENT ddl
			  PORT
				(
					reset		: IN	std_logic;
					fiCLK 		: IN 	std_logic;
					fiTEN_N 		: IN	std_logic;
					fiDIR 		: IN 	std_logic;
					fiBEN_N 		: IN 	std_logic;
					fiLF_N 		: IN 	std_logic;
					fiCTRL_N		: IN	std_logic;
					fiD 			: IN	std_logic_vector(31 DOWNTO 0);
					fifo_q		: IN	std_logic_vector(31 DOWNTO 0);	-- interface fifo data output port
					fifo_empty	: IN	std_logic;						-- interface fifo "emtpy" signal
		    			ext_trg   	: IN    std_logic;						-- external trigger (for testing purposes only)
					foD 			: OUT	std_logic_vector(31 DOWNTO 0);
					foBSY_N 		: OUT 	std_logic;
					foCTRL_N		: OUT	std_logic;
					foTEN_N 		: OUT	std_logic;
					fifo_rdreq	: OUT	std_logic						-- interface fifo read request
																		-- (fifo should be clocked by same clock that 
																		--  drives fiCLK)
				);
			END COMPONENT;
		
			-- test module to fill the interface FIFO
			COMPONENT fifo_filler
		  	  PORT (
				clock       : IN  std_logic;
		    		arstn       : IN  std_logic;
				trigger		: IN  std_logic;
				rdreq		: IN  std_logic;
				q			: OUT std_logic_vector (31 DOWNTO 0);
		    	fifo_empty 	: out std_logic
			  );
			END COMPONENT;
		
			COMPONENT timer IS
			  GENERIC (CTR_WIDTH : positive);
			  PORT (
						clk 	: IN 	std_logic;
						trigger	: OUT	std_logic
			  );
			END COMPONENT;
				
	-- controllers and state machines *****************************
	
  	component CTL_ONE IS PORT (
  	  CLK,CMD_L0,FIFO_EMPTY,RESET,SEL_EQ_0,SEPARATOR,TIMEOUT: IN std_logic;
  		CLR_SEL,CLR_TIMEOUT,INCR_SEL,RD_FIFO,TRIG_TO_TDC,WR_FIFO,CTL_ONE_STUFF, stuff0, stuff1 : OUT std_logic);
    END component;
  	
		component ALWREAD IS PORT (
			CLK,empty,RESET: IN std_logic;
			incr_cnt,rd_fifo,wr_fifo : OUT std_logic);
		END component;
		
		component SHORTEN IS PORT (
			CLK,read_strobe,RESET: IN std_logic;
			rd_fifo : OUT std_logic);
		END component;

		component CTL32TO4 IS PORT (
			CTR : OUT std_logic_vector (3 DOWNTO 0);
			CLK,DIN_STROBE,RESET: IN std_logic;
			DOUT_STROBE,READY : OUT std_logic);
		END component;

		component MCU_BOSS IS PORT (
			CLK,mcu_boss_enable,read_strobe,RESET: IN std_logic;
			rd_fifo,wr_fifo : OUT std_logic);
		END component;
		
		component pushbutton_pulse
			PORT( clk, reset : in std_logic;
			  pushbutton : in std_logic;
			  pulseout : out std_logic );
		end component;
			
		component TDIGCTL is PORT (
				CLK,DATA_ENABLE,FIFO_DS_EMPTY,OUTPUT_BUSY,POS_DNSTRM,RESET,SEPARATOR,
				TDC_FIFO_EMPTY,TRIGGER_PULSE: IN std_logic;
				EN_TDC_RDO,RD_DS_FIFO,RD_TDC_FIFO,SEL_DS_FIFO,WR_OUTPUT : OUT std_logic);
		END component;
		
		COMPONENT ser_rdo PORT (
			ser_out		: IN	STD_LOGIC;
			strb_out		: IN	STD_LOGIC;
			token_out		: IN	STD_LOGIC;
			trigger		: IN	STD_LOGIC;
			trg_reset		: IN 	STD_LOGIC;
			token_in		: OUT	STD_LOGIC;
	
			clk, reset	: IN 	STD_LOGIC;
			mcu_pld_int	: IN 	STD_LOGIC;
			pld_mcu_int 	: OUT 	STD_LOGIC;
			mcu_byte		: OUT 	STD_LOGIC_VECTOR (7 DOWNTO 0);
			fifo_empty	: OUT 	STD_LOGIC;	
			rdo_32b_data	: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);		
			rdo_data_valid : OUT STD_LOGIC;
			sw 			: IN std_logic_vector(2 downto 0); -- position switch input for separator word );	
			no_separator   : IN std_logic; -- TDIG config bit for noise testing
			no_trigger	: IN	std_logic ); -- TDIG config bit for noise testing
		END COMPONENT;		
	
		component ctl4to32 IS
			PORT (CLK,DSTROBE,RESET: IN std_logic;
					REGA_EN : OUT std_logic);
		end component;

		component sm_sync_enable is
			port( rega_enable : in std_logic;										
				clk,reset : in std_logic;	-- reset is async		
				regb_enable : out std_logic; -- clock enable for register b
				output_valid : out std_logic
				); 
		end component;
		
		component data_path_control is port ( 	
					clk, reset 	: in std_logic;
					op_mode 		: in std_logic_vector(7 downto 0);
					current_data 	: in std_logic_vector(31 downto 0);				                     			  
					in_fifo_empty 	: in std_logic_vector(4 downto 0);			
					select_input 	: out std_logic_vector(2 downto 0); 				
					read_input_fifo : out std_logic_vector(4 downto 0); 				
					write_ddl_fifo : out std_logic_vector(1 downto 0);
					ddl_fifo_sel 	: out std_logic; -- select signal for ping-pong output fifos	
					error1 		: out std_logic_vector(7 downto 0);	
					trigger_pulse 	: out std_logic;
					wr_final_fifo 	: out std_logic;
					mcu_mode		: in  std_logic_vector(7 downto 0);
					mcu_config	: in  std_logic_vector(7 downto 0);
					mcu_filter_sel : in  std_logic_vector(7 downto 0);
					wr_mcu_fifo    : out std_logic;
					rd_mcu_fifo		: in std_logic	);							
		end component;
	
		component CTLV1 IS
			PORT (CLK,CMD_ABORT,CMD_IGNORE,CMD_L0,CMD_L2,CMD_RESET,FIFO_EMPTY,OPMODE1,
				RESET,SEL_EQ_0,SEPARATOR,TIMEOUT,TRIG_EQ_TOKEN: IN std_logic;
				
				CLR_FIFO_OUT,CLR_INFIFO,CLR_OUTFIFO,CLR_SEL,CLR_TDC,CLR_TIMEOUT,CLR_TOGGLE,
				CLR_TOKEN,ERROR2,INCR_SEL,RD_FIFO,SW_DDL_FIFO,TRIG_TO_TDC,WR_DDL,WR_FIFO,
				WR_L2_REG,WR_MCU,WR_MCU_ERROR,WR_MCU_FIFO : OUT std_logic);
		END component;
		
	-- data path elements *****************************
		
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
		
		component ser_4bit_to_par is
		port( din : in std_logic_vector(3 downto 0); -- data from xmit board
			dclk : 	in std_logic;		-- source synchronous clock from xmit board
			dstrobe : in std_logic;		-- strobe from xmit board that marks word boundary
										-- serves as data valid to enable clock to 4bit register
			clk : in std_logic;			-- master receive clk
			reset : in std_logic;		-- synchronous reset 
									-- dclk and clk must have constant phase difference
			dout : out std_logic_vector(31 downto 0); -- parallel data word output to TCPU fifo 
			output_strobe : out std_logic			
			--rega_en, regb_en : out std_logic -- test pins
			);
			
		end component ser_4bit_to_par;		
		
		component trigger_interface is
			port( clk, reset : in std_logic;
				  tcd_4bit_data : in std_logic_vector(3 downto 0);
				  tcd_clk_50mhz : in std_logic;
				  tcd_clk_10mhz : in std_logic;
				  tcd_word : out std_logic_vector(19 downto 0);
				  tcd_strobe : out std_logic );		
		end component;
		
		component core_data_path_verb is
			port( clk, reset : in std_logic;
				  trigger_input_strobe : in std_logic;
				  tdig_input_strobe : in std_logic_vector(4 downto 1);
				  tcd_data : in std_logic_vector(19 downto 0);
				  tdig1_data : in std_logic_vector(31 downto 0);
				  tdig2_data : in std_logic_vector(31 downto 0); 
				  tdig3_data : in std_logic_vector(31 downto 0);  
				  tdig4_data : in std_logic_vector(31 downto 0);
				  final_data : out std_logic_vector(31 downto 0);
				  mcu_fifo_out : out std_logic_vector(31 downto 0);
				  mcu_fifo_empty : out std_logic;
				  ddl_read_fifo : in std_logic;
				  error 	 : out std_logic_vector(7 downto 0);
				  op_mode    : in std_logic_vector(7 downto 0);
			  	  tdc_strobe : out std_logic;
			  	  mcu_filter_sel	: in std_logic_vector(7 downto 0);
			  	  mcu_config		: in std_logic_vector(7 downto 0);
			  	  mcu_mode		: in std_logic_vector(7 downto 0);
			  	  mcu_strobes_fifo  : in std_logic );
		end component;	
		
	-- registers **********************************
	
		component reg8_en PORT (
				clock	: IN STD_LOGIC ;
				enable	: IN STD_LOGIC ;
				sclr		: IN STD_LOGIC ;
				data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0) );
		end component;
		
		component reg4_en_aclr is 
			PORT ( clock		: IN STD_LOGIC ;
				enable		: IN STD_LOGIC ;
				aclr		: IN STD_LOGIC ;
				data		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				q		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0) );
		end component;
		
		component reg4_en is
			PORT(clock		: IN STD_LOGIC ;
				enable		: IN STD_LOGIC ;
				sclr		: IN STD_LOGIC ;
				data		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				q		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0));
		end component;


		component reg20_en
			PORT ( clock		: IN STD_LOGIC ;
				enable		: IN STD_LOGIC ;
				sclr		: IN STD_LOGIC ;
				aclr		: IN STD_LOGIC ;
				data		: IN STD_LOGIC_VECTOR (19 DOWNTO 0);
				q		: OUT STD_LOGIC_VECTOR (19 DOWNTO 0) );
		end component;
		
		component reg32_en   -- 32 bit D register with clock enable
			PORT
			(
				clock		: IN STD_LOGIC ;
				enable		: IN STD_LOGIC ;
				sclr		: IN STD_LOGIC ;
				data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
			);
		end component;
	
	-- flip flops ***********************************
	
		component DFF_generic PORT (
				clock	: IN STD_LOGIC ;
				enable	: IN STD_LOGIC ;
				sclr		: IN STD_LOGIC ;
				sset		: IN STD_LOGIC ;
				aclr		: IN STD_LOGIC ;
				aset		: IN STD_LOGIC ;
				data		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC );
		end component;

		component DFF_sclr
			PORT (  clock	: IN STD_LOGIC ;
				sclr		: IN STD_LOGIC ;
				aclr		: IN STD_LOGIC ;
				data		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC );
		end component;

		component DFF_sclr_sset
			PORT(clock		: IN STD_LOGIC ;
				sclr		: IN STD_LOGIC ;
				sset		: IN STD_LOGIC ;
				data		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC );
		end component;	

		COMPONENT tff_sclr PORT (
				clock	: IN STD_LOGIC ;
				sclr		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC );
		END COMPONENT;	
		
	-- decoders  ***************************************************
		
		component decoder_3_to_8 PORT (
				data		: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
				eq0		: OUT STD_LOGIC ;
				eq1		: OUT STD_LOGIC ;
				eq2		: OUT STD_LOGIC ;
				eq3		: OUT STD_LOGIC ;
				eq4		: OUT STD_LOGIC ;
				eq5		: OUT STD_LOGIC ;
				eq6		: OUT STD_LOGIC ;
				eq7		: OUT STD_LOGIC );
		end component;

	-- multiplexers ***************************************************

		component mux_2x32 PORT (
				data1x	: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data0x	: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				sel		: IN STD_LOGIC ;
				result	: OUT STD_LOGIC_VECTOR (31 DOWNTO 0) );
		end component;

		component mux_2to1_1bit PORT (
				data1	: IN STD_LOGIC ;
				data0	: IN STD_LOGIC ;
				sel		: IN STD_LOGIC ;
				result	: OUT STD_LOGIC );
		end component;

		component mux_5_to_1 PORT (
				data4		: IN STD_LOGIC ;
				data3		: IN STD_LOGIC ;
				data2		: IN STD_LOGIC ;
				data1		: IN STD_LOGIC ;
				data0		: IN STD_LOGIC ;
				sel		: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
				result		: OUT STD_LOGIC );
		end component;
		
		component mux_3_by_32 PORT (
				data2x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data1x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data0x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				sel			: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
				result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0) );
		end component;

		component mux_8_by_8bit PORT (
				data7x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				data6x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				data5x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				data4x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				data3x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				data2x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				data1x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				data0x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				sel			: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
				result		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0) );
		end component;

		component two_by_3bit_mux PORT (
				data1x		: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
				data0x		: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
				sel		: IN STD_LOGIC ;
				result		: OUT STD_LOGIC_VECTOR (2 DOWNTO 0) );
		end component;
		
		component two_by_8bit_mux
			PORT ( data1x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				data0x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				sel		: IN STD_LOGIC ;
				result		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
		end component;
		
		component mux_2x32_registered
			PORT ( clock	: IN STD_LOGIC ;
				aclr		: IN STD_LOGIC  := '0';
				clken	: IN STD_LOGIC  := '1';
				data1x	: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data0x	: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				sel		: IN STD_LOGIC ;
				result	: OUT STD_LOGIC_VECTOR (31 DOWNTO 0) );
		end component;

		component mux_32_to_4
			PORT ( clock		: IN STD_LOGIC ;
				aclr			: IN STD_LOGIC  := '0';
				clken		: IN STD_LOGIC  := '1';
				data8x		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				data7x		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				data6x		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				data5x		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				data4x		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				data3x		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				data2x		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				data1x		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				data0x		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				sel			: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
				result		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0) );
		end component;

		-- 4 input by 32bit mux with registered output to select data
		-- from TDIG input fifos
		component mux_4x32_registered
			PORT ( clock		: IN STD_LOGIC ;
				aclr			: IN STD_LOGIC  := '0';
				clken		: IN STD_LOGIC  := '1';
				data3x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data2x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data1x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data0x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				sel		     : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
				result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0) );
		end component;
		
		component mux_5x32_unreg PORT (
				data4x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data3x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data2x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data1x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data0x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				sel		     : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
				result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0) );
		end component;
			
		component mux_5x32_registered
			PORT (clock		: IN STD_LOGIC ;
				aclr			: IN STD_LOGIC  := '0';
				clken		: IN STD_LOGIC  := '1';
				data4x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data3x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data2x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data1x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				data0x		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				sel			: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
				result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0) );
		end component;	
		
		component mux_4x8_reg
			PORT ( clock		: IN STD_LOGIC ;
				aclr		: IN STD_LOGIC  := '0';
				clken		: IN STD_LOGIC  := '1';
				data3x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				data2x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				data1x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				data0x		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				sel		: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
				result		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
		end component;
		
	-- counters ***************************************************

		component count127 PORT (
				clock	: IN STD_LOGIC ;
				cnt_en	: IN STD_LOGIC ;
				aclr		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
				cout		: OUT STD_LOGIC );
		end component;

		component trigger_counter_15bit PORT (
				clock	: IN STD_LOGIC ;
				cnt_en	: IN STD_LOGIC ;
				aclr		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC_VECTOR (14 DOWNTO 0);
				cout		: OUT STD_LOGIC );
		end component;

		component trigger_counter_12bit PORT (
				clock	: IN STD_LOGIC ;
				cnt_en	: IN STD_LOGIC ;
				aclr		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
				cout		: OUT STD_LOGIC );
		end component;
	
        	component timeout_ctr
			PORT(clock		: IN STD_LOGIC ;
				cnt_en  : IN STD_LOGIC;
				sclr		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC_VECTOR (9 DOWNTO 0);
				cout		: OUT STD_LOGIC );
		end component;
		
		component data_sel_ctr
			PORT( 	clock		: IN STD_LOGIC ;
				cnt_en		: IN STD_LOGIC ;
				sclr		: IN STD_LOGIC ;
				aclr		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC_VECTOR (2 DOWNTO 0) );
		end component;	
			
		component timeout
  			PORT(	clk, reset : in std_logic;
    				clr_timeout : in std_logic;
    				timeout_valid : out std_logic );
    		end component timeout;
    		
 		component ctr_9state
			PORT
			( 	clock		: IN STD_LOGIC ;
			  	clk_en		: IN STD_LOGIC ;
				aclr		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC_VECTOR (3 DOWNTO 0) );
		end component;	
		
 	-- decoders  ***************************************************  
 	
	 	component decode_3to5_en PORT (
			data		: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
			enable		: IN STD_LOGIC ;
			eq0		: OUT STD_LOGIC ;
			eq1		: OUT STD_LOGIC ;
			eq2		: OUT STD_LOGIC ;
			eq3		: OUT STD_LOGIC ;
			eq4		: OUT STD_LOGIC	);
		end component;
		
	-- fifos  ***************************************************
    				
    		-- tdig data input fifo
		component input_fifo_64x32
			PORT (data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				wrreq		: IN STD_LOGIC ;
				rdreq		: IN STD_LOGIC ;
				clock		: IN STD_LOGIC ;
				aclr			: IN STD_LOGIC ;
				q		     : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
				full			: OUT STD_LOGIC ;
				empty		: OUT STD_LOGIC );
		end component;
		
		component input_fifo64dx20w
			PORT ( data		: IN STD_LOGIC_VECTOR (19 DOWNTO 0);
				wrreq		: IN STD_LOGIC ;
				rdreq		: IN STD_LOGIC ;
				clock		: IN STD_LOGIC ;
				aclr			: IN STD_LOGIC ;
				q			: OUT STD_LOGIC_VECTOR (19 DOWNTO 0);
				full			: OUT STD_LOGIC ;
				empty		: OUT STD_LOGIC );
		end component;	
	
		component output_fifo_256x32
			PORT ( data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				wrreq		: IN STD_LOGIC ;
				rdreq		: IN STD_LOGIC ;
				clock		: IN STD_LOGIC ;
				aclr			: IN STD_LOGIC ;
				q			: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
				full			: OUT STD_LOGIC ;
				empty		: OUT STD_LOGIC );
		end component;	
						
		component mcu_fifo_256x24
			PORT ( data		: IN STD_LOGIC_VECTOR (23 DOWNTO 0);
				wrreq		: IN STD_LOGIC ;
				rdreq		: IN STD_LOGIC ;
				clock		: IN STD_LOGIC ;
				aclr			: IN STD_LOGIC ;
				q			: OUT STD_LOGIC_VECTOR (23 DOWNTO 0);
				full			: OUT STD_LOGIC ;
				empty		: OUT STD_LOGIC );
		end component;
		
    component output_fifo_1024x32
    	PORT
    	( data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
    		wrreq		: IN STD_LOGIC ;
    		rdreq		: IN STD_LOGIC ;
    		clock		: IN STD_LOGIC ;
    		aclr		: IN STD_LOGIC ;
    		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
    		full		: OUT STD_LOGIC ;
    		empty		: OUT STD_LOGIC );
    end component;
				

end package tcpu_package;	
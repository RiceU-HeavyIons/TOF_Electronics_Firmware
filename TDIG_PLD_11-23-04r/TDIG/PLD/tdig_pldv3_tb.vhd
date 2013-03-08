-- $Id: tdig_pldv3_tb.vhd,v 1.1.1.1 2004-12-03 23:23:05 tofp Exp $

LIBRARY ieee; USE ieee.std_logic_1164.all;

LIBRARY lpm; USE lpm.lpm_components.all;

LIBRARY altera_mf; USE altera_mf.altera_mf_components.all; -- gets global clk primitive

USE work.picotof_package.all;

--  Entity Declaration

entity TDIG_pldv3_tb is port (

	clock, reset, trigger : in std_logic;
	
	data_out: out std_logic_vector(3 downto 0);
	data_clock_out, data_valid_out : out std_logic
	
	 );
	
	
end TDIG_pldv3_tb;

ARCHITECTURE behavior OF TDIG_pldv3_tb IS

			component TDIG_pldv3 PORT (

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
					CLK_10M 			: IN 	STD_LOGIC; --Secondary clock from TCPU.  Originally 10MHz RHIC strobe
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
					US_M24 			: OUT 	STD_LOGIC;
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
					hit_hi			: IN	STD_LOGIC_VECTOR (23 downto 15);
					hit_mid			: IN	STD_LOGIC_VECTOR (12 downto 7);
					hit_lo			: IN	STD_LOGIC_VECTOR (1 downto 0);
					
					
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
				
					Si_ID 			: IN 	STD_LOGIC	 );					-- INPUT NOW FOR SAFETY					
		
			END component;

		signal 	tdc_ser_in, tdc_token_in_sig, tdc_trig, tdc_token_out_sig : std_logic_vector(4 downto 1);	
		
				
	BEGIN

		tdig_pld_chip : component TDIG_pldv3 port map (
	
							SW 		=> "001",		 	-- rotary switch
					
							-- JTAG multiplex signals ---------------------------------		
							TDO_TDC 			=> "0000", 
							--TDO_EXT, TDO_MCU 	=>      ,
					
							--TCK_TDC 			=>      ,
							TCK_EXT   =>  '0' ,
							TCK_MCU 	=>  '0' ,
					
							--TMS_TDC 			=>      ,
							TMS_EXT   =>  '0' ,
							TMS_MCU 	=>  '0' ,
					
							--TDI_TDC 			=>      ,
							TDI_EXT   =>  '0' ,
							TDI_MCU 	=>  '0' ,
					
							TRST_TDC 	=>  "0000" ,	
							-- TRST_MCU 			=> '0'  ,
							
							PUSHBUT_IN => '0',
							-----------------------------------------------------------
					
							-- clocks
							CLK_40M 			=>   clock , --*WHATEVER* 40MHz clock in use!  May be CXO *OR* TCPU generated
							CLK_10M 			=>  '0'    , --Secondary clock from TCPU.  Originally 10MHz RHIC strobe
							CLK_FROM_MCU 		=>  '0'    , --Secondary clock from 20MHz CXO.  Unused.
							--CLK_TO_MCU 		=>         , -- MCU clock source
					
							-- TEST 			=>         ,	-- test header
					
							SMB_in 			=>  "000"    ,	-- SMB input connectors
							-- SMB_out 			=>    ,	-- SMB output connector
							
							--PLD_HIT 			-- to TDC Hit[25] & Hit[31]
							--PLD_HIT_EN 		=>         ,	-- level converter enable
					
							-- TDC signals
							
							--TDC_B_RESET 		=>      ,	-- bunch reset
							--TDC_E_RESET 		=>      ,	-- event reset
							--TDC_RESET 		=>      ,	-- TDC reset
							TDC_SER_IN 		=>  tdc_ser_in,	-- serial_in
							TDC_TOKEN_IN 		=>  tdc_token_in_sig,	
							TDC_TRIG 			=>  tdc_trig,	-- trigger
					--		PARA_DATA 		: IN 	STD_LOGIC_VECTOR (7  DOWNTO 0),	-- parallel data "byte" out
					--		BYTE_ID 			: IN 	STD_LOGIC_VECTOR (1  DOWNTO 0),
					--		BYTE_PARITY 		=>      ,
					--		DATA_READY 		=>      ,				-- parallel data "data_ready"
							--GET_PARA_DATA 		=>      ,				-- parallel data "get_data"
							TDC_ERROR 		=> "0000" ,	-- error pins
							TDC_SER_OUT 		=> "0000" ,	-- serial data out
							
							TDC_STRB_OUT(1) 	=> clock,	-- serial strobe out
							TDC_STRB_OUT(4 downto 2) => "000" ,	-- serial strobe out
							TDC_TEST 			=> "0000" ,
							TDC_TOKEN_OUT 		=> tdc_token_out_sig,	
							--AUX_CLK 			=> ,
					
							
					-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					--------------------------------------------------------------------------------------------------------------
							TDC_TRIG_IN 		=>  TRIGGER ,			-- trigger from TCPU
					--------------------------------------------------------------------------------------------------------------
					
					
					
							-- upstream connector
							DATA_VALID_US 		=>   data_valid_out,
							--US_DATA 			=>      ,
							US_D_CLK 			=>   data_clock_out,
							--US_M24 			=>      ,
							US_MUL7(5 downto 4) => "00",
							US_MUL7(3 downto 0) => data_out, 			
					
							-- downstream connector
							DATA_VALID_DS 		=> '0'      ,
							DS_DATA 			=> "0000"   ,
							DS_D_CLK 			=> '0'      ,
							DS_M24 			=> '0'      ,
							DS_MUL7 			=> "000000" ,
							-- DS_BUFF_EN 		=>      ,
					
							-- 7-segment LED
							--LED_A 			=>      ,
							--LED_B 			=>      ,
							--LED_C 			=>      ,
							--LED_D 			=>      ,
							--LED_E 			=>      ,
							--LED_F 			=>      ,
							--LED_G 			=>      ,
							--LED_DP 			=>      ,					
							--TAMP_PULSE 		=>      , 	-- Output to pulse generator on TAMP
							
							-- CAN controller interface
							CAN_INT 			=> '0' , -- interrupt from CAN controller.
							nRX0BF 			=> '0' , 	-- Interrupt from CAN controller Rx0 buffer
							nRX1BF 			=> '0' , 	-- Interrupt from CAN controller Rx1 buffer
					
							-- Hit inputs for multiplicity calculation.
							hit_hi			=> "000000000" ,
							hit_mid			=> "000000"    ,
							hit_lo			=> "00"        ,
							
							-- PLD-MCU interface
							-- MCU_DATA 			=> mcu_data,
							MCU_CTRL4 		=> '0',
							MCU_CTRL3 		=> '0',
							MCU_CTRL2 		=> '0',
							MCU_CTRL1 		=> '0',
							MCU_CTRL0 		=> '0',
							-- MCU_INT1 			=> mcu_fifo_empty, 
							MCU_INT0			=> '0',
							MUL24_TRIG 		=> '0'  ,	-- M24 (Level-2) data trigger						
							Si_ID 			=> '0'    	-- INPUT NOW FOR SAFETY
						) ;
	
	-- "token out" signals are INPUTS FROM the TDCs, "token_in" signals are OUTPUTS TO the TDCs	
	-- The connections below model the tokens passing thru each tdc	

			tdc_token_out_sig(4) <= transport tdc_token_in_sig(4) after 50 ns; -- after 50 ns;
			tdc_token_out_sig(3) <= transport tdc_token_in_sig(3) after 50 ns; --after 50 ns;
			tdc_token_out_sig(2) <= transport tdc_token_in_sig(2) after 50 ns; --after 50 ns;
			tdc_token_out_sig(1) <= transport tdc_token_in_sig(1) after 50 ns;
		
END behavior;
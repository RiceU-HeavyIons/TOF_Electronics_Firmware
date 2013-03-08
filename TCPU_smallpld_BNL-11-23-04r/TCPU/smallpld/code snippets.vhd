	component ser_rdo
		PORT(
			ser_out		:	IN	STD_LOGIC;
			strb_out	: 	IN	STD_LOGIC;
			token_out	:	IN	STD_LOGIC;
			trigger		:	IN	STD_LOGIC;
			trg_rstn	:	IN 	STD_LOGIC;
			token_in	:	OUT	STD_LOGIC;

			us_byte			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			us_data_v		: OUT STD_LOGIC;
			us_data_clk		: IN STD_LOGIC;

			clk, reset		: IN STD_LOGIC;
--			mcu_pld_int		: IN STD_LOGIC;
--			pld_mcu_int 	: OUT STD_LOGIC;
--			mcu_byte	 	: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			fifo_empty		: OUT STD_LOGIC	
		);
	end component; 


BEGIN
-- TDC Serial readout state machine instantiation:
	tdc_read_sm	: ser_rdo PORT MAP(
		ser_out => TDC_SER_OUT(1),
		strb_out => TDC_STRB_OUT(1),
		token_out => TDC_TOKEN_OUT(1),
		trigger	=> trig_ff_out(4),
		trg_rstn => '1',
		token_in => TDC_token,     --TDC_TOKEN_IN(4),
		
--		us_byte(7 DOWNTO 4) => US_MUL7(3 DOWNTO 0),
--		us_byte(3 DOWNTO 0) => US_DATA(3 DOWNTO 0),
		us_byte => upstream_byte,
		us_data_v => DV_US,
		us_data_clk => global_clk_40M,
		
		clk => global_clk_40M,
		reset => MCU_CTRL0,
--		mcu_pld_int => MCU_CTRL4,
--		pld_mcu_int => MCU_CTRL(3),
--		mcu_byte => MCU_DATA,
		fifo_empty => state_test   --MCU_CTRL(2)
	);

	DATA_VALID_US <= DV_US;
	
	TDC_TOKEN_IN(4) <= TDC_token;
	MCU_CTRL(2) <= state_test;
	
	TDC_SER_IN(4) <= '0';
	TDC_SER_IN(3) <= TDC_SER_OUT(4);
	TDC_TOKEN_IN(3) <= TDC_TOKEN_OUT(4);
	TDC_SER_IN(2) <= TDC_SER_OUT(3);
	TDC_TOKEN_IN(2) <= TDC_TOKEN_OUT(3);
	TDC_SER_IN(1) <= TDC_SER_OUT(2);
	TDC_TOKEN_IN(1) <= TDC_TOKEN_OUT(2);
	
	TEST(1) <= upstream_byte(0);
	TEST(3) <= upstream_byte(1);
	TEST(5) <= upstream_byte(2);
	TEST(7) <= upstream_byte(3);
	TEST(9) <= upstream_byte(4);     
	TEST(11) <= upstream_byte(5);	
	TEST(13) <= upstream_byte(6);
	TEST(15) <= upstream_byte(7);
	TEST(17) <= DV_US;
	TEST(19) <= global_clk_40M;


-- Try to make the clock global
	global_clk : GLOBAL PORT MAP (a_in => CLK_40M, a_out => global_clk_40M);

	trig_ff0 : DFF PORT MAP (d => SMB_in(1), q => trig_ff_out(0), 
							clk => global_clk_40M, clrn => '1', prn => '1');
	trig_ff1 : DFF PORT MAP (d => trig_ff_out(0), q => trig_ff_out(1), 
							clk => global_clk_40M, clrn => '1', prn => '1');
	trig_ff2 : DFF PORT MAP (d => trig_ff_out(1), q => trig_ff_out(2), 
							clk => global_clk_40M, clrn => '1', prn => '1');
	trig_ff3 : DFF PORT MAP (d => trig_ff_out(2), q => trig_ff_out(3), 
							clk => global_clk_40M, clrn => '1', prn => '1');
	trig_ff4 : DFF PORT MAP (d => (trig_ff_out(2) AND (NOT trig_ff_out(3))), q => trig_ff_out(4), 
							clk => global_clk_40M, clrn => '1', prn => '1');
							
	hit_delay : LPM_SHIFTREG 
	GENERIC MAP (
		lpm_type => "LPM_SHIFTREG",
		lpm_width => 8,
		lpm_direction => "RIGHT"
	)
	PORT MAP(
		clock => global_clk_40M, 
		shiftin => trig_ff_out(4),
		shiftout => hit_delay_out 
	);
	
	MCU_CLK_GEN : LPM_COUNTER
	GENERIC MAP (
		lpm_width => 3,
		lpm_type => "LPM_COUNTER",
		lpm_direction => "UP"
	)
	PORT MAP (
		clock => global_clk_40M,
		q => counter_out
	);

	CLK_TO_MCU <= counter_out(2);	
	
	SMB_OUT <= hit_delay_out;
	TDC_B_RESET(1) <= trig_ff_out(4);
	TDC_B_RESET(2) <= trig_ff_out(4);
	TDC_B_RESET(3) <= trig_ff_out(4);
	TDC_B_RESET(4) <= trig_ff_out(4);

-- CRAP TO PULL HIGH/LOW --
	TEST(39 DOWNTO 20) <= "00000000000000000000";
	TEST(18) <= '0';
	TEST(16) <= '0';
	TEST(14) <= '0';
	TEST(12) <= '0';
	TEST(10) <= '0';
	TEST(8) <= '0';
	TEST(6) <= '0';
	TEST(4) <= '0';
	TEST(2) <= '0';
	TEST(0) <= '0';
			
	LED_MCU(0) <= (MCU_INT(0) XOR MCU_INT(1));
	LED_MCU(1) <= '1';
	LED_MCU(2) <= NOT(MCU_INT(0) AND NOT MCU_INT(1));
	LED_MCU(3) <= (MCU_INT(0) XOR MCU_INT(1));
	LED_MCU(4) <= (MCU_INT(0) AND NOT MCU_INT(1));
	LED_MCU(5) <= (MCU_INT(0) AND MCU_INT(1));
	LED_MCU(6) <= NOT(NOT MCU_INT(0) AND NOT MCU_INT(1));
	
	LED_EXT(0) <= (SW(0) XOR SW(1));
	LED_EXT(1) <= '1';
	LED_EXT(2) <= NOT(SW(0) AND NOT SW(1));
	LED_EXT(3) <= (SW(0) XOR SW(1));
	LED_EXT(4) <= (SW(0) AND NOT SW(1));
	LED_EXT(5) <= (SW(0) AND SW(1));
	LED_EXT(6) <= NOT(NOT SW(0) AND NOT SW(1));
	
	-- Which TDC does MUX point at (uses SW(1:0) and displays [4:1])
	LED_A <= LED_MCU(0);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(0);
	LED_B <= LED_MCU(1);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(1);
	LED_C <= LED_MCU(2);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(2);
	LED_D <= LED_MCU(3);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(3);
	LED_E <= LED_MCU(4);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(4);
	LED_F <= LED_MCU(5);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(5);
	LED_G <= LED_MCU(6);-- WHEN MCU_INT(2) = '1' ELSE LED_EXT(6);
	
	LED_DP <= MCU_INT(2);
	
	AUX_CLK <= "0000";
	DS_BUFF_EN <= '0';
	GET_PARA_DATA <= '0';
	PLD_HIT <= "00";
	PLD_HIT_EN <= '0';
	TDC_E_RESET <= "0000";
	TDC_RESET <= "0000";
	TDC_TRIG <= "0000";

-- END CRAP TO PULL HIGH/LOW --
	trst_tdc(4 DOWNTO 1) <= "1111";

	tck_tdc(1) <= tck_ext WHEN (SW(1)='0' AND SW(0)='0' AND MCU_INT(2)='0') ELSE
				  tck_mcu WHEN (MCU_INT(1)='0' AND MCU_INT(0)='0' AND MCU_INT(2)='1') ELSE 'Z';
	tck_tdc(2) <= tck_ext WHEN (SW(1)='0' AND SW(0)='1' AND MCU_INT(2)='0') ELSE
				  tck_mcu WHEN (MCU_INT(1)='0' AND MCU_INT(0)='1' AND MCU_INT(2)='1') ELSE 'Z';
	tck_tdc(3) <= tck_ext WHEN (SW(1)='1' AND SW(0)='0' AND MCU_INT(2)='0') ELSE
				  tck_mcu WHEN (MCU_INT(1)='1' AND MCU_INT(0)='0' AND MCU_INT(2)='1') ELSE 'Z';
	tck_tdc(4) <= tck_ext WHEN (SW(1)='1' AND SW(0)='1' AND MCU_INT(2)='0') ELSE
				  tck_mcu WHEN (MCU_INT(1)='1' AND MCU_INT(0)='1' AND MCU_INT(2)='1') ELSE 'Z';

	tms_tdc(1) <= tms_ext WHEN (SW(1)='0' AND SW(0)='0' AND MCU_INT(2)='0')ELSE
				  tms_mcu WHEN (MCU_INT(1)='0' AND MCU_INT(0)='0' AND MCU_INT(2)='1') ELSE 'Z';
	tms_tdc(2) <= tms_ext WHEN (SW(1)='0' AND SW(0)='1' AND MCU_INT(2)='0')ELSE
				  tms_mcu WHEN (MCU_INT(1)='0' AND MCU_INT(0)='1' AND MCU_INT(2)='1') ELSE 'Z';
	tms_tdc(3) <= tms_ext WHEN (SW(1)='1' AND SW(0)='0' AND MCU_INT(2)='0')ELSE
				  tms_mcu WHEN (MCU_INT(1)='1' AND MCU_INT(0)='0' AND MCU_INT(2)='1') ELSE 'Z';
	tms_tdc(4) <= tms_ext WHEN (SW(1)='1' AND SW(0)='1' AND MCU_INT(2)='0')ELSE
				  tms_mcu WHEN (MCU_INT(1)='1' AND MCU_INT(0)='1' AND MCU_INT(2)='1') ELSE 'Z';

	tdi_tdc(1) <= tdi_ext WHEN (SW(1)='0' AND SW(0)='0' AND MCU_INT(2)='0')ELSE
				  tdi_mcu WHEN (MCU_INT(1)='0' AND MCU_INT(0)='0' AND MCU_INT(2)='1') ELSE 'Z';
	tdi_tdc(2) <= tdi_ext WHEN (SW(1)='0' AND SW(0)='1' AND MCU_INT(2)='0')ELSE
				  tdi_mcu WHEN (MCU_INT(1)='0' AND MCU_INT(0)='1' AND MCU_INT(2)='1') ELSE 'Z';
	tdi_tdc(3) <= tdi_ext WHEN (SW(1)='1' AND SW(0)='0' AND MCU_INT(2)='0')ELSE
				  tdi_mcu WHEN (MCU_INT(1)='1' AND MCU_INT(0)='0' AND MCU_INT(2)='1') ELSE 'Z';
	tdi_tdc(4) <= tdi_ext WHEN (SW(1)='1' AND SW(0)='1' AND MCU_INT(2)='0')ELSE
				  tdi_mcu WHEN (MCU_INT(1)='1' AND MCU_INT(0)='1' AND MCU_INT(2)='1') ELSE 'Z';

	tdo_mcu <=	tdo_tdc(1) WHEN (MCU_INT(1)='0' AND MCU_INT(0)='0' AND MCU_INT(2)='1') ELSE
				tdo_tdc(2) WHEN (MCU_INT(1)='0' AND MCU_INT(0)='1' AND MCU_INT(2)='1') ELSE
				tdo_tdc(3) WHEN (MCU_INT(1)='1' AND MCU_INT(0)='0' AND MCU_INT(2)='1') ELSE
				tdo_tdc(4);

	tdo_ext <=	tdo_tdc(1) WHEN (SW(1)='0' AND SW(0)='0' AND MCU_INT(2)='0') ELSE
				tdo_tdc(2) WHEN (SW(1)='0' AND SW(0)='1' AND MCU_INT(2)='0') ELSE
				tdo_tdc(3) WHEN (SW(1)='1' AND SW(0)='0' AND MCU_INT(2)='0') ELSE
				tdo_tdc(4);

LIBRARY altera;
USE altera.maxplus2.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY lpm;
USE lpm.lpm_components.all;

--  Entity Declaration
ENTITY ser_rdo IS
	PORT
	(
		-- TDC PLD Interface signals
		strb_out	: IN	STD_LOGIC;	-- strobe_out from TDC daisy chain
		trigger		: IN	STD_LOGIC;	-- readout trigger
		trg_reset	: IN	STD_LOGIC;	-- reset of trigger counter
		token_out	: IN	STD_LOGIC;	-- token_out from TDC daisy chain
		ser_out		: IN	STD_LOGIC;	-- serial_out from TDC daisy chain	
		token_in	: OUT	STD_LOGIC;	-- token_in to TDC daisy chain

		-- MCU PLD Interface signals
		clk, reset	: IN	STD_LOGIC;						-- FIFO clock and reset
		mcu_pld_int	: IN	STD_LOGIC;						-- MCU-to-PLD control
		pld_mcu_int	: OUT	STD_LOGIC;						-- PLD-to-MCU control
		mcu_byte	: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);	-- PLD-to-MCU data byte
		fifo_empty	: OUT	STD_LOGIC						-- FIFO empty indicator
	);
END ser_rdo;

-- Architecture body
ARCHITECTURE a OF ser_rdo IS
	TYPE SState_type IS (s1,s2,s3,s4,s5,s6,s7,s8);
	SIGNAL sState 		: SState_type;

	TYPE MState_type IS (m1,m2,m3,m4);
	SIGNAL mState 		: MState_type;
	
	SIGNAL token_cap 	: STD_LOGIC; 
	SIGNAL trg_ctr 		: STD_LOGIC_VECTOR (7 DOWNTO 0);
 	SIGNAL shift_en		: STD_LOGIC;
	SIGNAL rdo_shift_q	: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL rdo_fifo_d	: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL rdo_fifo_q	: STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL rdreq_sig	: STD_LOGIC;
	SIGNAL wrreq_sig	: STD_LOGIC;
	SIGNAL s_aclr		: STD_LOGIC;
	SIGNAL gd_ctr 		: INTEGER RANGE 0 TO 3;

BEGIN

	-- Process Statements

	-- serial readout state machine
	--	state machine to control serial readout of TDC:
	--		- wait for trigger to go high (s1)
	--		- issue token to TDC daisy chain (s2)
	--		- reset ser_ctr to 0,
	--		  Clear shift register
	--		  wait for the Serial_Out pin of the 
	--		  TDC to go hi (indicating "start of data"),
	--		  or wait for the token to come back out
	--		  of the TDC (indicating "no data") (s3).
	--		  In case of "no data", just finish by going to s7
	--		- read 32 bits from "Serial_Out" pin into
	--		  shift register (s4)
	--		- clock shift register into FIFO (s5)
	--		- wait one clock tick and go back to s3 for next data item 
	--		  
	--		- when no more data, clock separator word into FIFO
	--		  make sure trigger signal is low again
	--		  go to beginning for next trigger (s7 & s8)
	--			
	PROCESS (reset, strb_out)
		VARIABLE ser_ctr : INTEGER RANGE 0 TO 31;
	BEGIN
		IF (reset = '1') THEN
			sState <= s1;
			ser_ctr := 0;
		ELSIF (strb_out'EVENT AND strb_out = '1') THEN
			token_in <= '0';
			shift_en <= '0';
			rdo_fifo_d <= rdo_shift_q;
			wrreq_sig <= '0';
			ser_ctr := ser_ctr + 1;
			
			CASE sState IS
				WHEN s1 =>
--					IF (trigger = '1') THEN
						sState <= s2;
--					END IF;
				WHEN s2 =>
					token_in <= '1';
					sState <= s3;
				WHEN s3 =>
					ser_ctr := 0;
					IF (ser_out = '1') THEN
						sState <= s4;
					ELSIF (token_cap = '1') THEN
						sState <= s7;
					END IF;
				WHEN s4 =>
					shift_en <= '1';
					IF (ser_ctr = 31) THEN
						sState <= s5;
					END IF;
				WHEN s5 =>
					wrreq_sig <= '1';
					sState <= s6;
				WHEN s6 =>
					sState <= s3;
				WHEN s7 =>
					rdo_fifo_d(31 DOWNTO 8) <= X"E00000";
					rdo_fifo_d( 7 DOWNTO 0) <= trg_ctr;
					IF (trigger = '0') THEN
						sState <= s8;
					END IF;
				WHEN s8 =>
					rdo_fifo_d(31 DOWNTO 8) <= X"E00000";
					rdo_fifo_d( 7 DOWNTO 0) <= trg_ctr;
					wrreq_sig <= '1';
					sState <= s1;
			END CASE;
		END IF;
	END PROCESS;	

	-- micro readout state machine
	--	to transfer the rdo_fifo content to the micro:
	--    - wait for "mcu_pld_int" to go high (m1)
	--	- raise "pld_micro_int" and wait for 
	--	  "mcu_pld_int" to go low again, indicating
	--	  that MCU has read data byte (m2)
	--	- if 4th byte has been read (gd_ctr = 3), advance to 
	--	  next FIFO word (m3)
	--	- advance by one byte (m4)
	--	- return to m1
	--	
	--	"mcu_byte" is the output to the micro (8bit wide).
	--	every cycle through the micro_sm, another byte is
	--	selected through gd_ctr (which is advanced by m4)
	--
	PROCESS (reset, clk)
		VARIABLE gd_ctrv : INTEGER RANGE 0 TO 3;
	BEGIN
		IF (reset = '1') THEN
			mState <= m1;
			gd_ctrv := 0;
			pld_mcu_int <= '0';
		ELSIF (clk'EVENT AND clk = '1') THEN
			pld_mcu_int <= '0';
			rdreq_sig 	<= '0';
			
			CASE mState IS
				WHEN m1 =>
					IF (mcu_pld_int = '1') THEN
						mState <= m2;
					END IF;
				WHEN m2 =>
					pld_mcu_int <= '1';
					IF (mcu_pld_int = '0') THEN
						mState <= m3;
					END IF;
				WHEN m3 =>
					IF (gd_ctr = 3) THEN
						rdreq_sig <= '1';
					END IF;
					mState <= m4;
				WHEN m4 =>
					gd_ctrv := gd_ctrv + 1;
					mState <= m1;
			END CASE;
		END IF;
		gd_ctr <= gd_ctrv;
						
	END PROCESS;	


	-- Conditional Signal Assignment

	-- shift register clear when s3
	s_aclr <= '1' WHEN sState = s3 ELSE '0';


	-- Selected Signal Assignment
	
	-- output byte according to gd_ctr state
	WITH gd_ctr SELECT
		mcu_byte <= rdo_fifo_q(31 DOWNTO 24) WHEN 0,
					rdo_fifo_q(23 DOWNTO 16) WHEN 1,
					rdo_fifo_q(15 DOWNTO  8) WHEN 2,
					rdo_fifo_q( 7 DOWNTO  0) WHEN OTHERS;

	-- Component Instantiation Statements
	
	-- this counts the number of triggers received. is reset by trg_reset	
	trg_ctr_inst : lpm_counter
	  GENERIC MAP (
		lpm_width => 8,
		lpm_type => "LPM_COUNTER",
		lpm_direction => "UP"
	  )
	  PORT MAP (
		clock	=> trigger,
		aclr 	=> trg_reset,
		q	 	=> trg_ctr
	  );

	-- latch the token coming back from the TDC
	token_ff : DFF 
	  PORT MAP (
		d 		=> token_out, 
		q 		=> token_cap, 
		clk 	=> strb_out, 
		clrn 	=> '1', 
		prn 	=> '1'
	  );

	-- shift register to shift in the serial TDC data
	rdo_shift : LPM_SHIFTREG 
	  GENERIC MAP (
		lpm_type 		=> "LPM_SHIFTREG",
		lpm_width 		=> 32,
		lpm_direction 	=> "LEFT"
	  )
	  PORT MAP (
		clock 	=> NOT strb_out, 
		shiftin => ser_out,
		q 		=> rdo_shift_q,
		enable	=> shift_en,
		aclr	=> s_aclr 
	  );
	
	-- FIFO to store TDC data as well as separators
	rdo_fifo : LPM_FIFO
	  GENERIC MAP (
		lpm_type		=> "LPM_FIFO",
		lpm_width		=> 32,
		lpm_numwords	=> 256,
		lpm_widthu		=> 8,
		lpm_showahead	=> "ON"
	  )
	  PORT MAP (
		clock		=> clk,
		empty		=> fifo_empty,
		aclr		=> reset,
		data		=> rdo_fifo_d,
		q			=> rdo_fifo_q,
		wrreq		=> wrreq_sig,
		rdreq		=> rdreq_sig
	  );

END a;


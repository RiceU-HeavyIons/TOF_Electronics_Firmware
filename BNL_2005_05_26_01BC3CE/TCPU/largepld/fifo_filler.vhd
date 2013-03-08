-- $Id: fifo_filler.vhd,v 1.1.1.1 2004-12-03 19:29:46 tofp Exp $
--*************************************************************************
--*  fifo_filler.VHD : Fifo Filler module.
--*
--*
--*  REVISION HISTORY:
--*
--*************************************************************************


LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY lpm;
USE lpm.lpm_components.all;
USE work.my_conversions.all;
USE work.my_utilities.all;

ENTITY fifo_filler IS
  PORT (
	clock       : IN  std_logic;
    arstn       : IN  std_logic;
	trigger		: IN  std_logic;
	rdreq		: IN  std_logic;
	q			: OUT std_logic_vector (31 DOWNTO 0);
    fifo_empty 	: out std_logic);
END fifo_filler;

ARCHITECTURE SYN OF fifo_filler IS

  	TYPE ff_state IS (
    	IDLE,
    	INIT,
    	FFTRIG,
		FFDEBUG,
		FFTAG,
		FFGEO,
    	FFDATA,
    	FFSEP
  	);

  	SIGNAL s_ff_din		: std_logic_vector (31 DOWNTO 0);
	SIGNAL s_ff_wrreq	: std_logic;

BEGIN

	data_fifo : LPM_FIFO
	  GENERIC MAP (
		lpm_type		=> "LPM_FIFO",
		lpm_width		=> 32,
		lpm_numwords	=> 256,
		lpm_widthu		=> 8,
		lpm_showahead	=> "ON"
	  )
	  PORT MAP (
		clock		=> clock,
		empty		=> fifo_empty,
		aclr		=> NOT arstn,
		data		=> s_ff_din,
		q			=> q,
		wrreq		=> s_ff_wrreq,
		rdreq		=> rdreq
	  );


 main : PROCESS (clock, arstn)

    VARIABLE ff_present     : ff_state;
    VARIABLE ff_next		: ff_state;

    VARIABLE ext_tr_reg1  	: std_logic;
    VARIABLE ext_tr_reg2  	: std_logic;
    VARIABLE ext_tr_edge  	: std_logic;
   	VARIABLE block_end      : std_logic;
	VARIABLE token			: std_logic_vector (11 DOWNTO 0);
	VARIABLE tdc_data		: std_logic_vector (20 DOWNTO 0);
	VARIABLE channel		: std_logic_vector ( 2 DOWNTO 0); 
	VARIABLE geo_data		: std_logic_vector (31 DOWNTO 0);
    VARIABLE counter_init   : boolean;
    VARIABLE counter_enable : boolean;
	-- VARIABLE last_event		: boolean;
	

  BEGIN

    IF (arstn = '0') THEN
      	ext_tr_reg1 	:= '0';
      	ext_tr_reg2 	:= '0';
		ext_tr_edge 	:= '0';
		
      	counter_init   	:= false;
      	counter_enable 	:= false;
		-- last_event		:= true;

		token 			:= (OTHERS => '0');
		tdc_data		:= (OTHERS => '0');
		
		ff_present 		:= IDLE;
		ff_next 		:= IDLE;

    ELSIF (clock'event AND clock = '1') THEN
		
		IF (counter_init) THEN
			tdc_data	:= int2slv(15, 21);		-- 16 TPC data words
			channel		:= (OTHERS => '0');
		ELSIF (counter_enable) THEN
			tdc_data	:= dec(tdc_data);
			channel		:= inc (channel);
		END IF;
		block_end := tdc_data(20);				-- stop on counter wrap
		
		-- for each trigger, fill 2 events into FIFO
		--IF (ff_next = IDLE) THEN
		--	last_event := true;
		--ELSIF (ff_next = INIT) THEN
		--	last_event := NOT last_event;
		--END IF;

		IF (ff_next = FFTRIG) THEN
			s_ff_din <= "10100000000001000000" & token;						-- Header Trigger Word
		ELSIF (ff_next = FFDEBUG) THEN
			s_ff_din <= "10110000000011110000" & token;						-- Header Debug Word
		ELSIF (ff_next = FFTAG) THEN
			s_ff_din <= "11011110101011011111101011001110"; 				-- Tag Word: 0xdeadface
		ELSIF (ff_next = FFGEO) THEN
			s_ff_din <= geo_data;											-- Geographical Data: Half Tray 2
		ELSIF (ff_next = FFDATA) THEN
			s_ff_din <= "01001010" & channel & tdc_data;					-- TDC Data: Leading Edge
		ELSIF (ff_next = FFSEP) THEN
			s_ff_din <= "11100111" & int2slv(15, 16) & token(7 DOWNTO 0);	-- Separator: Board 7
		ELSE
			s_ff_din <= (OTHERS => '0');
		END IF;
		
		IF (ff_next = INIT) THEN					-- initialize data
			channel		:= (OTHERS => '0');
			geo_data 	:= "1100" & int2slv(2, 28);	-- half tray = 2
			token		:= inc(token);
		ELSIF (ff_next = FFGEO) THEN
			geo_data 	:= inc (geo_data);
		END IF;
		
		IF ((ff_next = IDLE) OR (ff_next = INIT)) THEN
			s_ff_wrreq <= '0';
		ELSE
			s_ff_wrreq <= '1';
		END IF;
		

		-- FIFO filler state machine
		CASE ff_present IS
        	WHEN IDLE =>
          		IF (ext_tr_edge = '1') THEN
            		ff_next := INIT;
          		ELSE
            		ff_next := IDLE;
          		END IF;
        	WHEN INIT =>
          		ff_next := FFTRIG;
    		WHEN FFTRIG =>
          		ff_next := FFDEBUG;
			WHEN FFDEBUG =>
          		ff_next := FFTAG;
			WHEN FFTAG =>
          		ff_next := FFGEO;
			WHEN FFGEO =>
          		ff_next := FFDATA;
    		WHEN FFDATA =>
          		IF (block_end = '1') THEN
            		ff_next := FFSEP;
          		ELSE
            		ff_next := FFDATA;
          		END IF;
    		WHEN FFSEP =>
				--IF (last_event) THEN
	          		ff_next := IDLE;
				--ELSE
				--	ff_next := INIT;
				--END IF;
       	END CASE;
      	ff_present := ff_next;

     	counter_init   := (ff_next = INIT);
     	counter_enable := (ff_next = FFDATA);

      	ext_tr_edge := ext_tr_reg1 AND NOT ext_tr_reg2;
      	ext_tr_reg2 := ext_tr_reg1;
      	ext_tr_reg1 := trigger;
    END IF;
  END PROCESS;
	
END SYN;

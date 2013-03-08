    -- ********************************************************************
        -- LIBRARY DEFINITIONS
        -- ********************************************************************
        
        LIBRARY altera; USE altera.maxplus2.ALL;
        LIBRARY ieee; USE ieee.std_logic_1164.all;
        LIBRARY lpm;  USE lpm.lpm_components.all;
      
        -- ********************************************************************
        -- TOP LEVEL ENTITY
        -- ********************************************************************

        -- Note mux is hardwired to come from J23 
        
        entity smalla is port (
               gclk1 : in std_logic;         -- clock from clock muxes
               gclk2 : in std_logic;         -- clock directly from oscillator
               
               -- watchdog timers
               -- watchdog1 (U11) receives a pulse from U8 (pld clock)
               -- watchdog2 (U25) receives a pulse from the MCU
               
               wd1_rsout : in std_logic;     -- power on reset signal from watchdog1
               wd2_rsout : in std_logic;     -- power on reset signal from watchdog2
              
               wd1_out : in std_logic;       -- "no pulse" signal from watchdog1  
               wd2_out : in std_logic;       -- "no pulse" signal from watchdog2
               
      
               mcu_reset : out std_logic;    -- reset output to MCU (based on watchdog)
                                             -- ACTIVE LOW, default is HI
                                             -- goes to U21/pin9 "nMCLR" pin
             
               pll_in_sel : in  std_logic;   -- clock source select signal from mcu pin RC2
                                     -- Nomally this will map straight thru to "EXT TO PLL",
                                            -- and this output will cause 
                                            -- HI = external osc into PLL 
                                            -- LO = local osc into PLL
                                            -- power on = LO
                                            -- default = LO
                                            
               mcu_enable_local : in std_logic;   -- PIN 8
												  -- clock input select from mcu pin RC1
                                                  -- Normally this will map straight thru to 
                                                  -- "DISABLE LOCAL OSC"
                                                  --     HI = disable local clock to U6
                                                  --     LO = enable local clock to U6
                                                  -- power on = LO
                                                  -- default = LO            
               
               ext_to_pll : out std_logic;   --  PIN 24 
											 --   function of mcu_enable_local and ...
                                             --   controls U6 mux
                                             --     HI = ext osc is input to U2 PLL
                                       		 --     LO = int osc in from J33/J34 is input to U2 PLL
                                             
               disable_local_osc : out std_logic; -- PIN 25 controls tristate output from U14 to U6 mux
               
                                      --     HI = disable local clock to U6
                                      --     LO = enable local clock to U6
                                      -- power on = LO
                                      -- default = LO
                                      -- operational = LO for slaves and HI for master
                                      
                                 -- Disabling clock is default operational mode for slave TCPUs
                                      -- to reduce crosstalk to external clock signal inside U6
               
      		sel_local_to_board : out std_logic;	 -- PIN 26 SELECT INPUT FOR U4 MUX
									-- '0' selects PLL for U4 mux
									-- '1' selects local oscillator from U14
                            
               
               pushbut2 : in std_logic;   -- prototyping test input from contact switch SW3
               
               master : in std_logic;     -- signal from large PLD telling whether this board is a master
               
               clk_20_mhz : out std_logic;     -- gclk divided by 2 for MCU clock
                              -- this clock should switch with any switch in the main pld clock
                              -- so that the MCU and the main PLD have synchronous clocks
               
               hdr_tck : in std_logic;   -- large pld jtag signals from header
               hdr_tdo : out std_logic; 
               hdr_tms : in std_logic;
               hdr_tdi : in std_logic;
               
               mcu_tck : in std_logic;    -- large pld jtag signals from mcu
               mcu_tdo : out std_logic;
               mcu_tms : in std_logic;
               mcu_tdi : in std_logic;  

               cfg_tck : out std_logic;   -- output of jtag mux to large pld
               cfg_tdo : in std_logic;  
	   		cfg_tms : out std_logic;  
	  		cfg_tdi : out std_logic    ); 
	  		     	
     end smalla;
     
     -- ********************************************************************
     -- TOP LEVEL ARCHITECTURE
     -- ********************************************************************
     
     architecture version_a of smalla is

	component TFF_LB PORT (
			clock	: IN STD_LOGIC ;
			sclr		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC );
	END component;
	
	component mux_2in_3bit PORT (
			data1x		: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
			data0x		: IN STD_LOGIC_VECTOR (2 DOWNTO 0);
			sel		     : IN STD_LOGIC ;
			result		: OUT STD_LOGIC_VECTOR (2 DOWNTO 0) );
	end component;
	
	component mux_2in_1bit PORT (
			data1		: IN STD_LOGIC ;
			data0		: IN STD_LOGIC ;
			sel			: IN STD_LOGIC ;
			result		: OUT STD_LOGIC );
	end component;    
    
     begin	
          mcu_reset <= wd1_rsout;    	-- ACTIVE LOW, default is HI
						 		-- This statement maps the power on reset output of watchdog1
						 		-- to the reset input of the MCU. The watchdog "RSOUT" signal 
						 		-- is active low.
		
		-- ************** SIGNAL THAT DETERMINES MASTER / SLAVE CONFIGURATION
		-- DEFAULT = '0' TO SELECT INTERNAL CLOCK TO PLL
		                                                                
		ext_to_pll <= not master;

		--     HI = ext osc is input to U2 PLL
		--     LO = int osc in from J33/J34 is input to U2 PLL
          
 		sel_local_to_board <= '0';  	-- selects PLL to go thru U4 mux to 
 		 					    	-- J30, J28, and J27 sysclock cable drivers
                            
          disable_local_osc <= '0';     -- default LO = enable local clock to U6
         
          -- divide 40 Mhz by 2 for 20 Mhz MCU clock

	     div2 : TFF_LB PORT MAP (clock => gclk1, sclr => wd1_rsout, q => clk_20_mhz);		
          
  		-- mux selects between header and MCU as JTAG source for programming large PLD	
		-- 3 signals going to large pld
	
		jtag_mux_out : mux_2in_3bit PORT MAP (
			data1x(0)	 => hdr_tdi,
			data1x(1)	 => hdr_tms,
			data1x(2)	 => hdr_tck,
			
			data0x(0)	 => mcu_tdi,
			data0x(1)	 => mcu_tms,
			data0x(2)	 => mcu_tck,
			
			result(0)    => cfg_tdi,   -- JTAG TDI to large PLD
			result(1)    => cfg_tms,   -- JTAG TMS to large PLD 
			result(2)    => cfg_tck,	   -- JTAG TCK to large PLD;
					
			sel	 => '1' );

	-- tdo coming back from large pld goes to both header and mcu	
	hdr_tdo <= cfg_tdo;
	mcu_tdo <= cfg_tdo;	
	          
    end architecture version_a;
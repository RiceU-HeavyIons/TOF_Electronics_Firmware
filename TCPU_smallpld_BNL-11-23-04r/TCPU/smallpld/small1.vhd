                     
            -- ********************************************************************
            -- LIBRARY DEFINITIONS
            -- ********************************************************************
            
            LIBRARY altera;
            USE altera.maxplus2.ALL;
            
            LIBRARY ieee;
            USE ieee.std_logic_1164.all;
            
            LIBRARY lpm;
            USE lpm.lpm_components.all;
            
            -- ********************************************************************
            -- INCLUDE FILES
            -- ********************************************************************
            
            --include "SHIFTREG.vhd";
            
            -- ********************************************************************
            -- TOP LEVEL ENTITY
            -- ********************************************************************
            
            -- things to do:
            -- 1. change one of the inputs from the MCU to control the JTAG mux
            
            entity small1 is
            	port
            	(
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
                                                   
                     mcu_enable_local : in std_logic;   -- clock input select from mcu pin RC1
                                                        -- Normally this will map straight thru to 
                                                        -- "DISABLE LOCAL OSC"
                                                        --     HI = disable local clock to U6
                                                        --     LO = enable local clock to U6
                                                        -- power on = LO
                                                        -- default = LO            
                     
                     ext_to_pll : out std_logic; -- function of mcu_enable_local and ...
                                                   --   controls U6 mux
                                                   --     HI = ext osc is input to U2 PLL
                                                   --     LO = int osc in from J33/J34 is input to U2 PLL
                                                   
                     disable_local_osc : out std_logic; -- controls tristate output from U14 to U6 mux
                     
                                            --     HI = disable local clock to U6
                                            --     LO = enable local clock to U6
                                            -- power on = LO
                                            -- default = LO
                                            -- operational = LO for slaves and HI for master
                                            
                                            -- Disabling clock is default operational mode for slave TCPUs
                                            -- to reduce crosstalk to external clock signal inside U6
                                                   
                     sel_pll_to_board : out std_logic;   -- control for U4 mux 
                     
                                            -- U4 output goes to slave TCPU chassis
                                            --          hi selects local osc (always on)
                                            --          lo selects PLL output
                                            -- PLL output can go away if:
                                            --      external osc goes away
                                            --      internal osc is selected at U6, but disabled at U14
                     
                     pushbut2 : in std_logic;            -- prototyping test input from contact switch SW3
                     
                     clk_status : out std_logic;         -- status signal to MCU telling whether 
                                                         -- external clock is active
                     
                     clk_20_mhz : out std_logic;     -- gclk divided by 2 for MCU clock
                                         -- this clock should switch with any switch in the main pld clock
                                         -- so that the MCU and the main PLD have synchronous clocks
                     
                     hdr_tck : in std_logic;   -- large pld jtag signals from header
                     hdr_tdo : out std_logic; 
                     hdr_tms : in std_logic;
                     hdr_tdi : in std_logic;
                     
                     mcu_tck : in std_logic;   -- large pld jtag signals from mcu
                     mcu_tdo : out std_logic;
                     mcu_tms : in std_logic;
                     mcu_tdi : in std_logic;  
                     
                     cfg_tdi : out std_logic; -- output of jtag mux to large pld
                     cfig_tms : out std_logic;
                     cfg_tck : out std_logic;
                     cfg_tdo : in std_logic;       
      	           );
         	
         end small1;
         
         -- ********************************************************************
         -- TOP LEVEL ARCHITECTURE
         -- ********************************************************************
         
         architecture ver1 of small1 is
         
         -- local signals e.g.
               --SIGNAL LED_MCU : STD_LOGIC_VECTOR (6 DOWNTO 0);
               -- signal clk : std_logic;	
         
         --  default static assignments
         	
              mcu_reset <= '0';    -- ACTIVE LOW, default is HI
                                                                              
              ext_to_pll <= '0';   --  default LO = int osc in from J33/J34 is input to U2 PLL
                                            
              disable_local_osc <= '0';      --     default LO = enable local clock to U6
                                            
              sel_pll_to_board <= '0';   -- default HI selects local osc (always on)            
              
              clk_status <= '0';: out std_logic;         -- status signal to MCU telling whether 
                                                  -- external clock is active
              
              clk_20_mhz <= '0';  -- divide 40 Mhz by 2 for 20 Mhz MCU clock 
              
      -- mux selects between header and MCU as JTAG source for programming large PLD
                           
              hdr_tdo <= '0'; -- return TDO to header for large PLD programming
              
              mcu_tdo <= '0'; -- return TDO to MCU for large PLD programming
              
              cfg_tdi <= '0'; -- JTAG TDI to large PLD
              cfig_tms <= '0'; -- JTAG TMS to large PLD              
              cfg_tck <= '0'; -- JTAG TCK to large PLD;
              
         end architecture ver1;
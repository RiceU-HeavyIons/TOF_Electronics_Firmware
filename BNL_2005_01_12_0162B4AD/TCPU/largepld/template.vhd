	

            
    LIBRARY ieee; USE ieee.std_logic_1164.all;
            
    LIBRARY lpm; USE lpm.lpm_components.all;
 
	entity XXX is port( 
		
		
			);
			
	end XXX;
	
	architecture yyy of XXX is

		
		-- COMPONENTS
		
		-- SIGNALS
		
		
	begin
	
		-- COMPONENT INSTANTIATION
		instance_name : component component_name
			PORT MAP (reset => reset,
					  dstrobe => dstrobe,
					  clk => dclk,				-- note that state machine uses data clock, not main clk
					  rega_en => rega_enable);      -- clock enable for rega appears 1 clock aftere end of dstrobe
					

	
	end architecture yyy;
	
	
			
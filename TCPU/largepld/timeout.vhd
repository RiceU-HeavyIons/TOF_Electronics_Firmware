    LIBRARY ieee; USE ieee.std_logic_1164.all;        
    LIBRARY lpm; USE lpm.lpm_components.all;
    use work.tcpu_package.all;
    
    entity timeout is 
    		port(clk, reset : in std_logic;
    			clr_timeout : in std_logic;
    			timeout_valid : out std_logic  		
    		);
    end timeout;
    
    architecture lwb1 of timeout is
 		
		signal counter_reset, term_cnt, term_cnt_flag, count_enable, stop_count : std_logic;
		signal cnt_val : std_logic_vector(9 downto 0);

    begin
    		counter_reset <= reset or clr_timeout;
    		stop_count <= reset or term_cnt;
    		
    
    		timer : timeout_ctr PORT MAP (
			clock	 => clk,
			cnt_en	 => count_enable,
			sclr	 => counter_reset,
			q	 => cnt_val,
			cout	 => term_cnt);
    
    		-- this flag is set when counter reaches terminal cnt
    		timeout_flag : DFF_sclr_sset PORT MAP (
			clock	 => clk,
			sclr	 => counter_reset,
			sset	 => term_cnt,
			data	 => term_cnt_flag,
			q	 => term_cnt_flag);
		
		timeout_valid <= term_cnt_flag;
 
 		-- this ff enables counter after 'clr_timeout' input
    		enable_ff : DFF_sclr_sset PORT MAP (
			clock	 => clk,
			sclr	 => stop_count,
			sset	 => clr_timeout,
			data	 => count_enable,
			q	 => count_enable);
 
    end lwb1;
    
    
    
    

LIBRARY ieee; USE ieee.std_logic_1164.all;
LIBRARY lpm; USE lpm.lpm_components.all;
LIBRARY altera_mf; USE altera_mf.altera_mf_components.all; 

package tcpu_new_primitives is

	component decoder_4to16_reg
		PORT
		(
			clock		: IN STD_LOGIC ;
			data		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
			enable		: IN STD_LOGIC ;
			eq0		: OUT STD_LOGIC ;
			eq1		: OUT STD_LOGIC ;
			eq10		: OUT STD_LOGIC ;
			eq11		: OUT STD_LOGIC ;
			eq12		: OUT STD_LOGIC ;
			eq13		: OUT STD_LOGIC ;
			eq14		: OUT STD_LOGIC ;
			eq15		: OUT STD_LOGIC ;
			eq2		: OUT STD_LOGIC ;
			eq3		: OUT STD_LOGIC ;
			eq4		: OUT STD_LOGIC ;
			eq5		: OUT STD_LOGIC ;
			eq6		: OUT STD_LOGIC ;
			eq7		: OUT STD_LOGIC ;
			eq8		: OUT STD_LOGIC ;
			eq9		: OUT STD_LOGIC 
		);
	end component;

	component MUX_16TO1
		PORT
		(
			data0		: IN STD_LOGIC ;
			data1		: IN STD_LOGIC ;
			data10		: IN STD_LOGIC ;
			data11		: IN STD_LOGIC ;
			data12		: IN STD_LOGIC ;
			data13		: IN STD_LOGIC ;
			data14		: IN STD_LOGIC ;
			data15		: IN STD_LOGIC ;
			data2		: IN STD_LOGIC ;
			data3		: IN STD_LOGIC ;
			data4		: IN STD_LOGIC ;
			data5		: IN STD_LOGIC ;
			data6		: IN STD_LOGIC ;
			data7		: IN STD_LOGIC ;
			data8		: IN STD_LOGIC ;
			data9		: IN STD_LOGIC ;
			sel		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
			result		: OUT STD_LOGIC 
		);
	end component;

	component SHIFT_REG_16BITS
		PORT
		(
			aclr		: IN STD_LOGIC ;
			clock		: IN STD_LOGIC ;
			shiftin		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	end component;

	component PLL_1x_and_16x
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			c1		: OUT STD_LOGIC 
		);
	end component;

	component PLL_multiplier_4x
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			c1		: OUT STD_LOGIC 
		);
	end component;
			
end package tcpu_new_primitives;

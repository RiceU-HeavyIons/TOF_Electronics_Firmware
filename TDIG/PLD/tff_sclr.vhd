


LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY lpm;
USE lpm.lpm_components.all;

ENTITY tff_sclr IS
	PORT
	(
		clock	: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC 
	);
END tff_sclr;


ARCHITECTURE SYN OF tff_sclr IS

component dff_sclr_sset
	PORT
	(
		clock		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		sset		: IN STD_LOGIC ;
		data		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC 
	);
end component;

	SIGNAL feedback, output	: STD_LOGIC;

BEGIN

	toggle_flop : component dff_sclr_sset
		PORT MAP (
			data => feedback,
			sset => '0',
			sclr => sclr,
			clock => clock,
			q => output );

	feedback <= output xor '1';
	q <= output;
	
END SYN;

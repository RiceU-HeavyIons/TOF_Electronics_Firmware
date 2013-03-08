-- $Id: decoder.vhd,v 1.1 2007-11-12 19:56:28 jschamba Exp $

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY decoder IS
  PORT(input_sig : IN  std_logic;
       adr       : IN  std_logic_vector(1 DOWNTO 0);
       y         : OUT std_logic_vector(3 DOWNTO 0));
END decoder;

ARCHITECTURE decoder_body OF decoder IS
BEGIN
  PROCESS(input_sig, adr)
  BEGIN
    IF(input_sig = '1') THEN
      CASE adr IS
        WHEN "00"   => y <= "0001";
        WHEN "01"   => y <= "0010";
        WHEN "10"   => y <= "0100";
        WHEN OTHERS => y <= "1000";
      END CASE;
    ELSE
      y <= "0000";
    END IF;
  END PROCESS;
END decoder_body;

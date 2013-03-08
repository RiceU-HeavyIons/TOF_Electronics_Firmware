-- $Id: serdesRdDecoder.vhd,v 1.1 2008-01-24 20:50:19 jschamba Exp $

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY serdesRdDecoder IS
  PORT(rdSel  : IN  std_logic_vector(1 DOWNTO 0);
       rdreq  : IN  std_logic;
       adr    : IN  std_logic_vector(2 DOWNTO 0);
       rdSelA : OUT std_logic_vector (1 DOWNTO 0);
       rdreqA : OUT std_logic;
       rdSelB : OUT std_logic_vector (1 DOWNTO 0);
       rdreqB : OUT std_logic;
       rdSelC : OUT std_logic_vector (1 DOWNTO 0);
       rdreqC : OUT std_logic;
       rdSelD : OUT std_logic_vector (1 DOWNTO 0);
       rdreqD : OUT std_logic;
       rdSelE : OUT std_logic_vector (1 DOWNTO 0);
       rdreqE : OUT std_logic;
       rdSelF : OUT std_logic_vector (1 DOWNTO 0);
       rdreqF : OUT std_logic;
       rdSelG : OUT std_logic_vector (1 DOWNTO 0);
       rdreqG : OUT std_logic;
       rdSelH : OUT std_logic_vector (1 DOWNTO 0);
       rdreqH : OUT std_logic
       );
END serdesRdDecoder;

ARCHITECTURE decoder_body OF serdesRdDecoder IS

  SIGNAL y : std_logic_vector (23 DOWNTO 0);

BEGIN
  WITH adr SELECT
    y <=
    "000000000000000000000" & rdreq & rdSel      WHEN "000",
    "000000000000000000" & rdreq & rdSel & "000" WHEN "001",
    "000000000000000" & rdreq & rdSel & "000000" WHEN "010",
    "000000000000" & rdreq & rdSel & "000000000" WHEN "011",
    "000000000" & rdreq & rdSel & "000000000000" WHEN "100",
    "000000" & rdreq & rdSel & "000000000000000" WHEN "101",
    "000" & rdreq & rdSel & "000000000000000000" WHEN "110",
    rdreq & rdSel &      "000000000000000000000" WHEN OTHERS;

  rdSelA <= y(1 DOWNTO 0);
  rdreqA <= y(2);
  rdSelB <= y(4 DOWNTO 3);
  rdreqB <= y(5);
  rdSelC <= y(7 DOWNTO 6);
  rdreqC <= y(8);
  rdSelD <= y(10 DOWNTO 9);
  rdreqD <= y(11);
  rdSelE <= y(13 DOWNTO 12);
  rdreqE <= y(14);
  rdSelF <= y(16 DOWNTO 15);
  rdreqF <= y(17);
  rdSelG <= y(19 DOWNTO 18);
  rdreqG <= y(20);
  rdSelH <= y(22 DOWNTO 21);
  rdreqH <= y(23);

END decoder_body;

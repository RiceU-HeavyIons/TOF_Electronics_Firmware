--345678901234567890123456789012345678901234567890123456789012345678901234567890
-- $Id: ddl_registers.vhd,v 1.1 2006-11-30 15:50:40 jschamba Exp $
--******************************************************************************
--*  ddl_registers.vhd
--*
--*
--*  REVISION HISTORY:
--*    11-Oct-2001 CS  Original coding
--*    17-May-2002 CS  XX registers have been added
--*
--******************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY ddl_registers IS
  PORT (
    clock       : IN  std_logic;
    arstn       : IN  std_logic;
    reg_data    : IN  std_logic_vector ( 7 DOWNTO 0);
    reg_addr    : IN  std_logic_vector ( 5 DOWNTO 0);
    reg_load    : IN  std_logic;
    reg_lock    : IN  std_logic;
    ps_reg      : OUT std_logic_vector ( 7 DOWNTO 0);
    bl_reg      : OUT std_logic_vector ( 7 DOWNTO 0);
    dt_reg      : OUT std_logic_vector ( 7 DOWNTO 0);
    fc_reg      : OUT std_logic_vector ( 7 DOWNTO 0);
    te_reg      : OUT std_logic_vector ( 7 DOWNTO 0);
    xx_reg      : OUT std_logic_vector ( 7 DOWNTO 0)
    );
END ddl_registers;

ARCHITECTURE SYN OF ddl_registers IS

BEGIN

  main : PROCESS (clock, arstn)
    VARIABLE ps_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE bl_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE dt_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE fc_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE te_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE xx_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE psreg_enable    : boolean;
    VARIABLE blreg_enable    : boolean;
    VARIABLE dtreg_enable    : boolean;
    VARIABLE fcreg_enable    : boolean;
    VARIABLE tereg_enable    : boolean;
    VARIABLE xxreg_enable    : boolean;
  BEGIN

    IF (arstn = '0') THEN
      ps_reg_int      := (OTHERS => '0');
      bl_reg_int      := (OTHERS => '0');
      dt_reg_int      := (OTHERS => '0');
      fc_reg_int      := (OTHERS => '0');
      te_reg_int      := (OTHERS => '0');
      xx_reg_int      := (OTHERS => '0');
      psreg_enable    := false;
      blreg_enable    := false;
      dtreg_enable    := false;
      fcreg_enable    := false;
      tereg_enable    := false;
      xxreg_enable    := false;
      ps_reg          <= (OTHERS => '0');
      bl_reg          <= (OTHERS => '0');
      dt_reg          <= (OTHERS => '0');
      fc_reg          <= (OTHERS => '0');
      te_reg          <= (OTHERS => '0');
      xx_reg          <= (OTHERS => '0');
    ELSIF (clock'event AND clock = '1') THEN

      ps_reg_int := reg_data;
      IF ( psreg_enable) THEN
        ps_reg <= ps_reg_int;
      END IF;
      psreg_enable    := ((reg_load = '1') AND (reg_addr = "000000"));

      bl_reg_int := reg_data;
      IF ( blreg_enable) THEN
        bl_reg <= bl_reg_int;
      END IF;
      blreg_enable    := ((reg_load = '1') AND (reg_addr = "000001"));

      dt_reg_int := reg_data;
      IF ( dtreg_enable) THEN
        dt_reg <= dt_reg_int;
      END IF;
      dtreg_enable    := ((reg_load = '1') AND (reg_addr = "000010"));

      fc_reg_int := reg_data;
      IF (fcreg_enable) THEN
        fc_reg <= fc_reg_int;
      END IF;
      fcreg_enable    := ((reg_load = '1') AND (reg_addr = "000011"));

      te_reg_int := reg_data;
      IF (tereg_enable) THEN
        te_reg <= te_reg_int;
      END IF;
      tereg_enable    := ((reg_load = '1') AND (reg_addr = "000100"));

      xx_reg_int := reg_data;
      IF (xxreg_enable) THEN
        xx_reg <= xx_reg_int;
      END IF;
      xxreg_enable    := ((reg_load = '1') AND (reg_addr = "000101"));

    END IF;

  END PROCESS;

END SYN;

--345678901234567890123456789012345678901234567890123456789012345678901234567890
--******************************************************************************
--*  CONTROL_REGISTERS.VHD
--*
--*
--*  REVISION HISTORY:
--*    11-Oct-2001 CS  Original coding
--*    17-May-2002 CS  XX registers have been added
--*
--******************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY control_registers IS
  PORT (
    clock       : IN  std_logic;
    arstn       : IN  std_logic;
    reg_data    : IN  std_logic_vector ( 7 DOWNTO 0);
    reg_addr    : IN  std_logic_vector ( 5 DOWNTO 0);
    reg_load    : IN  std_logic;
    reg_lock    : IN  std_logic;
    ps_switches : IN  std_logic_vector ( 3 DOWNTO 0);
    bl_switches : IN  std_logic_vector ( 3 DOWNTO 0);
    dt_switches : IN  std_logic_vector ( 2 DOWNTO 0);
    fc_switches : IN  std_logic_vector ( 1 DOWNTO 0);
    te_switches : IN  std_logic_vector ( 1 DOWNTO 0);
    xx_switches : IN  std_logic_vector ( 4 DOWNTO 0);
    ps_reg      : OUT std_logic_vector ( 7 DOWNTO 0);
    bl_reg      : OUT std_logic_vector ( 7 DOWNTO 0);
    dt_reg      : OUT std_logic_vector ( 7 DOWNTO 0);
    fc_reg      : OUT std_logic_vector ( 7 DOWNTO 0);
    te_reg      : OUT std_logic_vector ( 7 DOWNTO 0);
    xx_reg      : OUT std_logic_vector ( 7 DOWNTO 0)
    );
END control_registers;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- use work.my_conversions.all;

ARCHITECTURE SYN OF control_registers IS

BEGIN

  main : PROCESS (clock, arstn)
    VARIABLE ps_switches_reg : std_logic_vector (3 DOWNTO 0);
    VARIABLE bl_switches_reg : std_logic_vector (3 DOWNTO 0);
    VARIABLE dt_switches_reg : std_logic_vector (2 DOWNTO 0);
    VARIABLE fc_switches_reg : std_logic_vector (1 DOWNTO 0);
    VARIABLE te_switches_reg : std_logic_vector (1 DOWNTO 0);
    VARIABLE xx_switches_reg : std_logic_vector (4 DOWNTO 0);
    VARIABLE ps_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE bl_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE dt_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE fc_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE te_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE xx_reg_int      : std_logic_vector (7 DOWNTO 0);
    VARIABLE psreg_by_rorc   : boolean;
    VARIABLE blreg_by_rorc   : boolean;
    VARIABLE dtreg_by_rorc   : boolean;
    VARIABLE fcreg_by_rorc   : boolean;
    VARIABLE tereg_by_rorc   : boolean;
    VARIABLE xxreg_by_rorc   : boolean;
    VARIABLE psreg_enable    : boolean;
    VARIABLE blreg_enable    : boolean;
    VARIABLE dtreg_enable    : boolean;
    VARIABLE fcreg_enable    : boolean;
    VARIABLE tereg_enable    : boolean;
    VARIABLE xxreg_enable    : boolean;
  BEGIN

    IF (arstn = '0') THEN
      ps_switches_reg := (OTHERS => '0');
      bl_switches_reg := (OTHERS => '0');
      dt_switches_reg := (OTHERS => '0');
      fc_switches_reg := (OTHERS => '0');
      te_switches_reg := (OTHERS => '0');
      xx_switches_reg := (OTHERS => '0');
      ps_reg_int      := (OTHERS => '0');
      bl_reg_int      := (OTHERS => '0');
      dt_reg_int      := (OTHERS => '0');
      fc_reg_int      := (OTHERS => '0');
      te_reg_int      := (OTHERS => '0');
      xx_reg_int      := (OTHERS => '0');
      psreg_by_rorc   := true;
      blreg_by_rorc   := true;
      dtreg_by_rorc   := true;
      fcreg_by_rorc   := true;
      tereg_by_rorc   := true;
      xxreg_by_rorc   := true;
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

      IF psreg_by_rorc THEN
        ps_reg_int := reg_data;
      ELSE
        ps_reg_int := "0000" & ps_switches_reg;
      END IF;
      IF ( psreg_by_rorc AND psreg_enable) OR
        (NOT psreg_by_rorc AND (reg_lock = '0')) THEN
        ps_reg <= ps_reg_int;
      END IF;
      psreg_enable    := ((reg_load = '1') AND (reg_addr = "000000"));
      psreg_by_rorc   := (ps_switches_reg = "0000");
      ps_switches_reg := ps_switches;

      IF blreg_by_rorc THEN
        bl_reg_int := reg_data;
      ELSE
        bl_reg_int := "0000" & bl_switches_reg;
      END IF;
      IF ( blreg_by_rorc AND blreg_enable) OR
        (NOT blreg_by_rorc AND (reg_lock = '0')) THEN
        bl_reg <= bl_reg_int;
      END IF;
      blreg_enable    := ((reg_load = '1') AND (reg_addr = "000001"));
      blreg_by_rorc   := (bl_switches_reg = "0000");
      bl_switches_reg := bl_switches;

      IF dtreg_by_rorc THEN
        dt_reg_int := reg_data;
      ELSE
        dt_reg_int := "00000" & dt_switches_reg;
      END IF;
      IF ( dtreg_by_rorc AND dtreg_enable) OR
        (NOT dtreg_by_rorc AND (reg_lock = '0')) THEN
        dt_reg <= dt_reg_int;
      END IF;
      dtreg_enable    := ((reg_load = '1') AND (reg_addr = "000010"));
      dtreg_by_rorc   := (dt_switches_reg = "000");
      dt_switches_reg := dt_switches;

      IF fcreg_by_rorc THEN
        fc_reg_int := reg_data;
      ELSE
        fc_reg_int := "000000" & fc_switches_reg;
      END IF;
      IF ( fcreg_by_rorc AND fcreg_enable) OR
        (NOT fcreg_by_rorc AND (reg_lock = '0')) THEN
        fc_reg <= fc_reg_int;
      END IF;
      fcreg_enable    := ((reg_load = '1') AND (reg_addr = "000011"));
      fcreg_by_rorc   := (fc_switches_reg = "00");
      fc_switches_reg := fc_switches;

      IF tereg_by_rorc THEN
        te_reg_int := reg_data;
      ELSE
        te_reg_int := "000000" & te_switches_reg;
      END IF;
      IF ( tereg_by_rorc AND tereg_enable) OR
        (NOT tereg_by_rorc AND (reg_lock = '0')) THEN
        te_reg <= te_reg_int;
      END IF;
      tereg_enable    := ((reg_load = '1') AND (reg_addr = "000100"));
      tereg_by_rorc   := (te_switches_reg = "00");
      te_switches_reg := te_switches;

      IF xxreg_by_rorc THEN
        xx_reg_int := reg_data;
      ELSE
        xx_reg_int := "000" & xx_switches_reg;
      END IF;
      IF ( xxreg_by_rorc AND xxreg_enable) OR
        (NOT xxreg_by_rorc AND (reg_lock = '0')) THEN
        xx_reg <= xx_reg_int;
      END IF;
      xxreg_enable    := ((reg_load = '1') AND (reg_addr = "000101"));
      xxreg_by_rorc   := (xx_switches_reg = "00000");
      xx_switches_reg := xx_switches;

    END IF;

  END PROCESS;

END SYN;

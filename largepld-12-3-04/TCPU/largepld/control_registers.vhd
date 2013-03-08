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

library ieee;
use ieee.std_logic_1164.all;

entity control_registers is
  port (
    clock       : in  std_logic;
    arstn       : in  std_logic;
    reg_data    : in  std_logic_vector ( 7 downto 0);
    reg_addr    : in  std_logic_vector ( 5 downto 0);
    reg_load    : in  std_logic;
    reg_lock    : in  std_logic;
    ps_switches : in  std_logic_vector ( 3 downto 0);
    bl_switches : in  std_logic_vector ( 3 downto 0);
    dt_switches : in  std_logic_vector ( 2 downto 0);
    fc_switches : in  std_logic_vector ( 1 downto 0);
    te_switches : in  std_logic_vector ( 1 downto 0);
    xx_switches : in  std_logic_vector ( 4 downto 0);
    ps_reg      : out std_logic_vector ( 7 downto 0);
    bl_reg      : out std_logic_vector ( 7 downto 0);
    dt_reg      : out std_logic_vector ( 7 downto 0);
    fc_reg      : out std_logic_vector ( 7 downto 0);
    te_reg      : out std_logic_vector ( 7 downto 0);
    xx_reg      : out std_logic_vector ( 7 downto 0)
  );
end control_registers;

library ieee;
use ieee.std_logic_1164.all;

-- use work.my_conversions.all;

architecture SYN of control_registers is

begin

  main : process (clock, arstn)
    variable ps_switches_reg : std_logic_vector (3 downto 0);
    variable bl_switches_reg : std_logic_vector (3 downto 0);
    variable dt_switches_reg : std_logic_vector (2 downto 0);
    variable fc_switches_reg : std_logic_vector (1 downto 0);
    variable te_switches_reg : std_logic_vector (1 downto 0);
    variable xx_switches_reg : std_logic_vector (4 downto 0);
    variable ps_reg_int      : std_logic_vector (7 downto 0);
    variable bl_reg_int      : std_logic_vector (7 downto 0);
    variable dt_reg_int      : std_logic_vector (7 downto 0);
    variable fc_reg_int      : std_logic_vector (7 downto 0);
    variable te_reg_int      : std_logic_vector (7 downto 0);
    variable xx_reg_int      : std_logic_vector (7 downto 0);
    variable psreg_by_rorc   : boolean;
    variable blreg_by_rorc   : boolean;
    variable dtreg_by_rorc   : boolean;
    variable fcreg_by_rorc   : boolean;
    variable tereg_by_rorc   : boolean;
    variable xxreg_by_rorc   : boolean;
    variable psreg_enable    : boolean;
    variable blreg_enable    : boolean;
    variable dtreg_enable    : boolean;
    variable fcreg_enable    : boolean;
    variable tereg_enable    : boolean;
    variable xxreg_enable    : boolean;
  begin

    if (arstn = '0') then
      ps_switches_reg := (others => '0');
      bl_switches_reg := (others => '0');
      dt_switches_reg := (others => '0');
      fc_switches_reg := (others => '0');
      te_switches_reg := (others => '0');
      xx_switches_reg := (others => '0');
      ps_reg_int      := (others => '0');
      bl_reg_int      := (others => '0');
      dt_reg_int      := (others => '0');
      fc_reg_int      := (others => '0');
      te_reg_int      := (others => '0');
      xx_reg_int      := (others => '0');
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
      ps_reg  <= (others => '0');
      bl_reg  <= (others => '0');
      dt_reg  <= (others => '0');
      fc_reg  <= (others => '0');
      te_reg  <= (others => '0');
      xx_reg  <= (others => '0');
    elsif (clock'event and clock = '1') then

      if psreg_by_rorc then
        ps_reg_int := reg_data;
      else
        ps_reg_int := "0000" & ps_switches_reg;
      end if;
      if (    psreg_by_rorc and psreg_enable) or
         (not psreg_by_rorc and (reg_lock = '0')) then
        ps_reg  <=     ps_reg_int;
      end if;
      psreg_enable    := ((reg_load = '1') and (reg_addr = "000000"));
      psreg_by_rorc   := (ps_switches_reg = "0000");
      ps_switches_reg := ps_switches;

      if blreg_by_rorc then
        bl_reg_int := reg_data;
      else
        bl_reg_int := "0000" & bl_switches_reg;
      end if;
      if (    blreg_by_rorc and blreg_enable) or
         (not blreg_by_rorc and (reg_lock = '0')) then
        bl_reg  <=     bl_reg_int;
      end if;
      blreg_enable    := ((reg_load = '1') and (reg_addr = "000001"));
      blreg_by_rorc   := (bl_switches_reg = "0000");
      bl_switches_reg := bl_switches;

      if dtreg_by_rorc then
        dt_reg_int := reg_data;
      else
        dt_reg_int := "00000" & dt_switches_reg;
      end if;
      if (    dtreg_by_rorc and dtreg_enable) or
         (not dtreg_by_rorc and (reg_lock = '0')) then
        dt_reg  <=     dt_reg_int;
      end if;
      dtreg_enable    := ((reg_load = '1') and (reg_addr = "000010"));
      dtreg_by_rorc   := (dt_switches_reg = "000");
      dt_switches_reg := dt_switches;

      if fcreg_by_rorc then
        fc_reg_int := reg_data;
      else
        fc_reg_int := "000000" & fc_switches_reg;
      end if;
      if (    fcreg_by_rorc and fcreg_enable) or
         (not fcreg_by_rorc and (reg_lock = '0')) then
        fc_reg  <=     fc_reg_int;
      end if;
      fcreg_enable    := ((reg_load = '1') and (reg_addr = "000011"));
      fcreg_by_rorc   := (fc_switches_reg = "00");
      fc_switches_reg := fc_switches;

      if tereg_by_rorc then
        te_reg_int := reg_data;
      else
        te_reg_int := "000000" & te_switches_reg;
      end if;
      if (    tereg_by_rorc and tereg_enable) or
         (not tereg_by_rorc and (reg_lock = '0')) then
        te_reg  <=     te_reg_int;
      end if;
      tereg_enable    := ((reg_load = '1') and (reg_addr = "000100"));
      tereg_by_rorc   := (te_switches_reg = "00");
      te_switches_reg := te_switches;

      if xxreg_by_rorc then
        xx_reg_int := reg_data;
      else
        xx_reg_int := "000" & xx_switches_reg;
      end if;
      if (    xxreg_by_rorc and xxreg_enable) or
         (not xxreg_by_rorc and (reg_lock = '0')) then
        xx_reg  <=     xx_reg_int;
      end if;
      xxreg_enable    := ((reg_load = '1') and (reg_addr = "000101"));
      xxreg_by_rorc   := (xx_switches_reg = "00000");
      xx_switches_reg := xx_switches;

    end if;

  end process;

end SYN;

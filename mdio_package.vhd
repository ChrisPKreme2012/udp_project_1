library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mdio_pkg is

    -- 5-bit address type
    subtype reg_addr_t is std_logic_vector(4 downto 0);

    -- 16-bit register value / status type
    subtype reg_status_t is std_logic_vector(15 downto 0);

    -- Struct for each register
    type reg_t is record
        addr    : reg_addr_t;
        status  : reg_status_t;  -- you can initialize to 0
        v_write : reg_status_t;
    end record;

    -- Record
    type reg_map_t is record
        BMCR     : reg_t;
        BMSR     : reg_t;
        PHYIDR1  : reg_t;
        PHYIDR2  : reg_t;
        ANAR     : reg_t;
        ANLPAR   : reg_t;
        --ANLPARNP : reg_t;
        ANER     : reg_t;
        ANNPTR   : reg_t;
        --08h-Fh 8-15 RW RESERVED RESERVED
        PHYSTS   : reg_t;
        --11h 17 RW RESERVED RESERVED
        --12h 18 RO RESERVED RESERVED
        --13h 19 RW RESERVED RESERVED
        FCSCR    : reg_t;
        RECR     : reg_t;
        PCSR     : reg_t;
        RBR      : reg_t;
        LEDCR    : reg_t;
        PHYCR    : reg_t;
        BTSCR    : reg_t;
        CDCTRL1  : reg_t;
        --1Ch 28 RW RESERVED RESERVED
        EDCR     : reg_t;
        --1Eh-1Fh 30-31 RW RESERVED RESERVED
    end record;

    -- Constant instance of the register map
    constant MDIO_REG : reg_map_t := (
        BMCR     => (addr => '0' & x"0", status => (others => '0'), v_write => x"0000"), --00h 0 RW BMCR Basic Mode Control Register
        BMSR     => (addr => '0' & x"1", status => (others => '0'), v_write => x"0000"), --01h 1 RO BMSR Basic Mode Status Register
        PHYIDR1  => (addr => '0' & x"2", status => (others => '0'), v_write => x"0000"), --02h 2 RO PHYIDR1 PHY Identifier Register #1
        PHYIDR2  => (addr => '0' & x"3", status => (others => '0'), v_write => x"0000"), --03h 3 RO PHYIDR2 PHY Identifier Register #2
        ANAR     => (addr => '0' & x"4", status => (others => '0'), v_write => x"0000"), --04h 4 RW ANAR Auto-Negotiation Advertisement Register
        ANLPAR   => (addr => '0' & x"5", status => (others => '0'), v_write => x"0000"), --05h 5 RW ANLPAR Auto-Negotiation Link Partner Ability Register (Base Page)
        --ANLPARNP => (addr => '0' & x"5", status => (others => '0'), v_write => x"0000"), --05h 5 RW ANLPARNP Auto-Negotiation Link Partner Ability Register (Next Page)
        ANER     => (addr => '0' & x"6", status => (others => '0'), v_write => x"0000"), --06h 6 RW ANER Auto-Negotiation Expansion Register
        ANNPTR   => (addr => '0' & x"7", status => (others => '0'), v_write => x"0000"), --07h 7 RW ANNPTR Auto-Negotiation Next Page TX
        --08h-Fh 8-15 RW RESERVED RESERVED
        PHYSTS   => (addr => '1' & x"0", status => (others => '0'), v_write => x"0000"), --10h 16 RO PHYSTS PHY Status Register
        --11h 17 RW RESERVED RESERVED
        --12h 18 RO RESERVED RESERVED
        --13h 19 RW RESERVED RESERVED
        FCSCR    => (addr => '1' & x"4", status => (others => '0'), v_write => x"0000"), --14h 20 RW FCSCR False Carrier Sense Counter Register
        RECR     => (addr => '1' & x"5", status => (others => '0'), v_write => x"0000"), --15h 21 RW RECR Receive Error Counter Register
        PCSR     => (addr => '1' & x"6", status => (others => '0'), v_write => x"0000"), --16h 22 RW PCSR PCS Sub-Layer Configuration and Status Register
        RBR      => (addr => '1' & x"7", status => (others => '0'), v_write => x"0000"), --17h 23 RW RBR RMII and Bypass Register
        LEDCR    => (addr => '1' & x"8", status => (others => '0'), v_write => x"0000"), --18h 24 RW LEDCR LED Direct Control Register
        PHYCR    => (addr => '1' & x"9", status => (others => '0'), v_write => x"0000"), --19h 25 RW PHYCR PHY Control Register
        BTSCR    => (addr => '1' & x"A", status => (others => '0'), v_write => x"0000"), --1Ah 26 RW 10BTSCR 10Base-T Status/Control Register
        CDCTRL1  => (addr => '1' & x"B", status => (others => '0'), v_write => x"0000"), --1Bh 27 RW CDCTRL1 CD Test Control Register and BIST Extensions Register
        --1Ch 28 RW RESERVED RESERVED
        EDCR     => (addr => '1' & x"D", status => (others => '0'), v_write => x"0000") --1Dh 29 RW EDCR Energy Detect Control Register
        --1Eh-1Fh 30-31 RW RESERVED RESERVED
    );

    -- Array of addresses in order
    type reg_array_t is array (natural range <>) of reg_t;

    constant MDIO_REG_ARRAY : reg_array_t := (
        MDIO_REG.BMCR, --00h 0 RW BMCR Basic Mode Control Register
        MDIO_REG.BMSR, --01h 1 RO BMSR Basic Mode Status Register
        MDIO_REG.PHYIDR1, --02h 2 RO PHYIDR1 PHY Identifier Register #1
        MDIO_REG.PHYIDR2, --03h 3 RO PHYIDR2 PHY Identifier Register #2
        MDIO_REG.ANAR, --04h 4 RW ANAR Auto-Negotiation Advertisement Register
        MDIO_REG.ANLPAR, --05h 5 RW ANLPAR Auto-Negotiation Link Partner Ability Register (Base Page)
        --MDIO_REG.ANLPARNP, --05h 5 RW ANLPARNP Auto-Negotiation Link Partner Ability Register (Next Page)
        MDIO_REG.ANER, --06h 6 RW ANER Auto-Negotiation Expansion Register
        MDIO_REG.ANNPTR, --07h 7 RW ANNPTR Auto-Negotiation Next Page TX
        --08h-Fh 8-15 RW RESERVED RESERVED
        MDIO_REG.PHYSTS, --10h 16 RO PHYSTS PHY Status Register
        --11h 17 RW RESERVED RESERVED
        --12h 18 RO RESERVED RESERVED
        --13h 19 RW RESERVED RESERVED
        MDIO_REG.FCSCR, --14h 20 RW FCSCR False Carrier Sense Counter Register
        MDIO_REG.RECR, --15h 21 RW RECR Receive Error Counter Register
        MDIO_REG.PCSR, --16h 22 RW PCSR PCS Sub-Layer Configuration and Status Register
        MDIO_REG.RBR, --17h 23 RW RBR RMII and Bypass Register
        MDIO_REG.LEDCR, --18h 24 RW LEDCR LED Direct Control Register
        MDIO_REG.PHYCR, --19h 25 RW PHYCR PHY Control Register
        MDIO_REG.BTSCR, --1Ah 26 RW 10BTSCR 10Base-T Status/Control Register
        MDIO_REG.CDCTRL1, --1Bh 27 RW CDCTRL1 CD Test Control Register and BIST Extensions Register
        --1Ch 28 RW RESERVED RESERVED
        MDIO_REG.EDCR --1Dh 29 RW EDCR Energy Detect Control Register
        --1Eh-1Fh 30-31 RW RESERVED RESERVED
    );

end package mdio_pkg;

package body mdio_pkg is
end package body mdio_pkg;

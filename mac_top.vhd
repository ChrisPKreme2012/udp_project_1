library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mac_top is
    port (
        -- AXI4-Lite Slave Interface
        ACLK    : in  std_logic;
        ARESETn : in  std_logic;

        AWADDR  : in  std_logic_vector(31 downto 0);
        AWVALID : in  std_logic;
        AWREADY : out std_logic;

        WDATA   : in  std_logic_vector(31 downto 0);
        WSTRB   : in  std_logic_vector(3 downto 0);
        WVALID  : in  std_logic;
        WREADY  : out std_logic;

        BRESP   : out std_logic_vector(1 downto 0);
        BVALID  : out std_logic;
        BREADY  : in  std_logic;

        ARADDR  : in  std_logic_vector(31 downto 0);
        ARVALID : in  std_logic;
        ARREADY : out std_logic;

        RDATA   : out std_logic_vector(31 downto 0);
        RRESP   : out std_logic_vector(1 downto 0);
        RVALID  : out std_logic;
        RREADY  : in  std_logic;

        -- MDIO interface
        mdc        : in  std_logic;
        serial_in  : in  std_logic;
        serial_t   : out std_logic;
        serial_out : out std_logic;

        -- UART
        tx_busy : out std_logic;
        tx_line : out std_logic
    );
end entity;

architecture rtl of mac_top is

    -- APB wires between bridge and slaves
    signal PCLK_sig    : std_logic;
    signal PRESETn_sig : std_logic;

    signal PADDR_sig   : std_logic_vector(31 downto 0);
    signal PWDATA_sig  : std_logic_vector(31 downto 0);
    signal PWRITE_sig  : std_logic;
    signal PENABLE_sig : std_logic;

    signal PSEL0_sig   : std_logic;
    signal PSEL1_sig   : std_logic;

    signal PRDATA0_sig : std_logic_vector(31 downto 0);
    signal PRDATA1_sig : std_logic_vector(31 downto 0);

    signal PREADY0_sig : std_logic;
    signal PREADY1_sig : std_logic;

    signal PSLVERR0_sig : std_logic;
    signal PSLVERR1_sig : std_logic;

begin

    --------------------------------------------------------------------
    -- AXI4-Lite to APB Bridge
    bridge_inst : entity work.axi_slv_apb_bridge
        port map (
            -- AXI4-Lite
            ACLK    => ACLK,
            ARESETn => ARESETn,

            AWADDR  => AWADDR,
            AWVALID => AWVALID,
            AWREADY => AWREADY,

            WDATA   => WDATA,
            WSTRB   => WSTRB,
            WVALID  => WVALID,
            WREADY  => WREADY,

            BRESP   => BRESP,
            BVALID  => BVALID,
            BREADY  => BREADY,

            ARADDR  => ARADDR,
            ARVALID => ARVALID,
            ARREADY => ARREADY,

            RDATA   => RDATA,
            RRESP   => RRESP,
            RVALID  => RVALID,
            RREADY  => RREADY,

            -- APB outputs
            PCLK    => PCLK_sig,
            PRESETn => PRESETn_sig,

            PADDR   => PADDR_sig,
            PWDATA  => PWDATA_sig,
            PWRITE  => PWRITE_sig,
            PENABLE => PENABLE_sig,

            PSEL0   => PSEL0_sig,
            PSEL1   => PSEL1_sig,

            PRDATA0 => PRDATA0_sig,
            PRDATA1 => PRDATA1_sig,

            PREADY0 => PREADY0_sig,
            PREADY1 => PREADY1_sig,

            PSLVERR0 => PSLVERR0_sig,
            PSLVERR1 => PSLVERR1_sig
        );

    --------------------------------------------------------------------
    -- MDIO / APB Slave
    mdio_inst : entity work.md_shift
        port map (
            PCLK    => PCLK_sig,
            PRESETn => PRESETn_sig,
            PSEL    => PSEL0_sig,       -- first APB bus
            PENABLE => PENABLE_sig,
            PWRITE  => PWRITE_sig,
            PADDR   => PADDR_sig,
            PWDATA  => PWDATA_sig,
            PRDATA  => PRDATA0_sig,
            PREADY  => PREADY0_sig,
            PSLVERR => PSLVERR0_sig,

            mdc        => mdc,
            serial_in  => serial_in,
            serial_t   => serial_t,
            serial_out => serial_out
        );

    --------------------------------------------------------------------
    -- UART / APB Slave
    uart_inst : entity work.uart_tx
        generic map (
            CLOCK_FREQ => 100000000,
            BAUD_RATE  => 115200,
            STOP_BITS  => 1
        )
        port map (
            PCLK    => PCLK_sig,
            PRESETn => PRESETn_sig,
            PSEL    => PSEL1_sig,      -- second APB bus
            PENABLE => PENABLE_sig,
            PWRITE  => PWRITE_sig,
            PADDR   => PADDR_sig,
            PWDATA  => PWDATA_sig,
            PRDATA  => PRDATA1_sig,
            PREADY  => PREADY1_sig,
            PSLVERR => PSLVERR1_sig,

            mdc => mdc,
            tx_busy => tx_busy,
            tx_line => tx_line
        );

end architecture;

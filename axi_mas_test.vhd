library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_mas_test is
    port (
        -- Clock and reset
        ACLK    : in  std_logic;
        ARESETn : in  std_logic;

        -- MDIO interface
        mdc        : in  std_logic;
        X1         : out std_logic;
        mdio       : inout  std_logic;
        -- serial_out : out std_logic;
        -- serial_in  : in std_logic;
        -- serial_t   : out std_logic;
        -- UART
        tx_busy : out std_logic;
        tx_line : out std_logic
    );
end entity;

architecture rtl of axi_mas_test is

    -- Internal AXI signals to connect master and slave
    signal AWADDR  : std_logic_vector(31 downto 0);
    signal AWVALID : std_logic;
    signal AWREADY : std_logic;

    signal WDATA   : std_logic_vector(31 downto 0);
    signal WSTRB   : std_logic_vector(3 downto 0) := (others => '1');
    signal WVALID  : std_logic;
    signal WREADY  : std_logic;

    signal BRESP   : std_logic_vector(1 downto 0);
    signal BVALID  : std_logic;
    signal BREADY  : std_logic;

    signal ARADDR  : std_logic_vector(31 downto 0);
    signal ARVALID : std_logic;
    signal ARREADY : std_logic;

    signal RDATA   : std_logic_vector(31 downto 0);
    signal RRESP   : std_logic_vector(1 downto 0);
    signal RVALID  : std_logic;
    signal RREADY  : std_logic;
    signal s_X1, s_ARESETn : std_logic;
    signal serial_out, serial_in, serial_t : std_logic;
    signal mdc_signal : std_logic := '0';

    attribute mark_debug : string;
attribute mark_debug of serial_out : signal is "true";
attribute mark_debug of serial_in : signal is "true";
attribute mark_debug of serial_t : signal is "true";
attribute mark_debug of mdc_signal : signal is "true";
attribute mark_debug of s_ARESETn : signal is "true";

begin

process(mdc)
begin
    if falling_edge(mdc) then
        mdc_signal <= not mdc_signal;
    end if;

end process;

iobuf_inst : IOBUF
  generic map (IOSTANDARD => "LVCMOS33")  -- choose your IO standard
  port map (
      I  => serial_out,  -- signal from logic to pin
      O  => serial_in,   -- signal from pin to logic
      T  => serial_t,    -- tristate control ('1' = high-Z)
      IO => mdio         -- physical pin
  );


    X1 <= s_X1;
    -------------------------------------------------------------------
    -- Instantiate AXI Master
    axi_master_inst : entity work.axi_mas
        port map (
            ACLK    => ACLK,
            ARESETn => s_ARESETn,

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
            RREADY  => RREADY
        );

    -------------------------------------------------------------------
    -- Instantiate MAC Top (AXI slave + MDIO + UART)
    mac_top_inst : entity work.mac_top
        port map (
            ACLK    => ACLK,
            ARESETn => s_ARESETn,

            -- AXI4-Lite slave interface
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

            -- MDIO interface
            mdc        => s_X1,
            serial_in  => serial_in,
            serial_t   => serial_t,
            serial_out => serial_out,

            -- UART
            tx_busy => tx_busy,
            tx_line => tx_line
        );

   -------------------------------------------------------------------
    -- Instantiate Power On Reset Hold
    reset_hold_inst : entity work.reset_hold
        port map (
            ARESETn => s_ARESETn,
            ext_ARESETn => ARESETn,

            -- MDIO interface
            mdc        => mdc,

            X1        => s_X1

        );

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_slv_apb_bridge is
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

        -- APB Interfaces (2 buses)
        PCLK    : out std_logic;
        PRESETn : out std_logic;

        PADDR   : out std_logic_vector(31 downto 0);
        PWDATA  : out std_logic_vector(31 downto 0);
        PWRITE  : out std_logic;
        PENABLE : out std_logic;

        PSEL0   : out std_logic;
        PSEL1   : out std_logic;

        PRDATA0 : in  std_logic_vector(31 downto 0);
        PRDATA1 : in  std_logic_vector(31 downto 0);

        PREADY0 : in  std_logic;
        PREADY1 : in  std_logic;

        PSLVERR0 : in std_logic;
        PSLVERR1 : in std_logic
    );
end entity;

architecture rtl of axi_slv_apb_bridge is

    type state_t is (IDLE, APB_SETUP, APB_DELAY, APB_ACCESS, RESPOND);
    signal state : state_t := IDLE;

    signal axi_addr  : std_logic_vector(31 downto 0);
    signal axi_wdata : std_logic_vector(31 downto 0);
    signal axi_write, s_BVALID, s_RVALID, s_AWREADY : std_logic;
    signal sel       : std_logic;  -- 0 = APB0, 1 = APB1

begin

    -- Clock forwarding
    PCLK    <= ACLK;
    PRESETn <= ARESETn;

    BVALID <= s_BVALID;
    RVALID <= s_RVALID;
    AWREADY <= s_AWREADY;
    
    process(ACLK, ARESETn)
    begin
        if ARESETn = '0' then
            state <= IDLE;

            s_AWREADY <= '0';
            WREADY  <= '0';
            s_BVALID  <= '0';
            BRESP   <= "00";

            ARREADY <= '0';
            s_RVALID  <= '0';
            RRESP   <= "00";
            RDATA   <= (others => '0');

            PSEL0   <= '0';
            PSEL1   <= '0';
            PENABLE <= '0';
            PWRITE  <= '0';
            PADDR   <= (others => '0');
            PWDATA  <= (others => '0');

            axi_addr  <= (others => '0');
            axi_write <= '0';
            axi_wdata <= (others => '0');
            sel <= '0';



        elsif rising_edge(ACLK) then

            case state is

                when IDLE =>
                    s_BVALID <= '0';
                    s_RVALID <= '0';
                    PENABLE <= '1';
                    PSEL0 <= '0';
                    PSEL1 <= '0';

                    if AWVALID = '1' and s_AWREADY = '0' then
                        axi_addr  <= AWADDR;
                        axi_write <= '1';
                        s_AWREADY <= '1';

                    elsif ARVALID = '1' then
                        axi_addr  <= ARADDR;
                        axi_write <= '0';
                        ARREADY <= '1';
                        state <= APB_SETUP;
                    else
                        s_AWREADY <= '0';
                    end if;

                    if WVALID = '1' then
                        axi_wdata <= WDATA;
                        WREADY  <= '1';
                        state <= APB_SETUP;
                    end if;

                when APB_SETUP =>
                    -- Decode address: bit[16] selects APB bus
                    sel <= axi_addr(16);
                    WREADY  <= '0';
                    ARREADY <= '0';

                    PADDR  <= axi_addr;
                    PWDATA <= axi_wdata;
                    PWRITE <= axi_write;
                    PENABLE <= '0';

                    PSEL0 <= not axi_addr(16);
                    PSEL1 <= axi_addr(16);

                    state <= APB_DELAY;

                when APB_DELAY =>
                    -- Decode address: bit[16] selects APB bus
                    PENABLE <= '1';

                    state <= APB_ACCESS;


                when APB_ACCESS =>
                    
                    if (sel = '0' and PREADY0 = '1') or
                       (sel = '1' and PREADY1 = '1') then

                        PSEL0 <= '0';
                        PSEL1 <= '0';

                        -- Capture read data
                        if axi_write = '0' then
                            if sel = '0' then
                                RDATA <= PRDATA0;
                            else
                                RDATA <= PRDATA1;
                            end if;
                        end if;

                        -- Error handling
                        if (sel = '0' and PSLVERR0 = '1') or
                           (sel = '1' and PSLVERR1 = '1') then
                            if axi_write = '1' then
                                BRESP <= "10"; -- SLVERR
                            else
                                RRESP <= "10";
                            end if;
                        else
                            BRESP <= "00"; -- OKAY
                            RRESP <= "00";
                        end if;

                        state <= RESPOND;
                    end if;

                when RESPOND =>
                    if axi_write = '1' and ((sel = '0' and PREADY0 = '1') or
                       (sel = '1' and PREADY1 = '1')) then
                        s_BVALID <= '1';
                        if BREADY = '1' and s_BVALID = '1' then
                            s_BVALID <= '0';
                            state <= IDLE;
                        end if;
                    elsif axi_write = '0' and ((sel = '0' and PREADY0 = '1') or
                       (sel = '1' and PREADY1 ='1')) then 
                        s_RVALID <= '1';
                        if RREADY = '1' and s_RVALID = '1' then
                            s_RVALID <= '0';
                            state <= IDLE;
                        end if;
                    end if;

            end case;
        end if;
    end process;

end architecture;

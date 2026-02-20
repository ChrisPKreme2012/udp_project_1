library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi_mas_pkg.all;

entity axi_mas is
    port (
        ACLK    : in  std_logic;
        ARESETn : in  std_logic;

        -- AXI4-Lite master interface
        AWADDR  : out std_logic_vector(31 downto 0);
        AWVALID : out std_logic;
        AWREADY : in  std_logic;

        WDATA   : out std_logic_vector(31 downto 0);
        WSTRB   : out std_logic_vector(3 downto 0);
        WVALID  : out std_logic;
        WREADY  : in  std_logic;

        BRESP   : in  std_logic_vector(1 downto 0);
        BVALID  : in  std_logic;
        BREADY  : out std_logic;

        ARADDR  : out std_logic_vector(31 downto 0);
        ARVALID : out std_logic;
        ARREADY : in  std_logic;

        RDATA   : in  std_logic_vector(31 downto 0);
        RRESP   : in  std_logic_vector(1 downto 0);
        RVALID  : in  std_logic;
        RREADY  : out std_logic
    );
end entity;

architecture rtl of axi_mas is

    type state_type is (IDLE, WRITE_ADDR, WRITE_DATA, WRITE_RESP, READ_ADDR, READ_DATA, DONE);
    signal state : state_type := IDLE;

    signal s_WVALID, s_ARVALID, s_AWVALID, s_RREADY, s_ARESETn : std_logic := '0';
    signal s_ARADDR, s_AWADDR, s_WDATA : std_logic_vector(31 downto 0) := (others => '0');
    signal LAST_READ : std_logic_vector(31 downto 0)  := x"00000000";

    signal trans_index : integer range 0 to NUM_TRANS-1 := 0;

     attribute mark_debug : string;
     attribute mark_debug of s_WDATA : signal is "true";
     attribute mark_debug of s_AWADDR : signal is "true";
     attribute mark_debug of LAST_READ : signal is "true";
     attribute mark_debug of s_ARESETn : signal is "true";

begin

    AWVALID <= s_AWVALID;
    WVALID  <= s_WVALID;
    ARVALID <= s_ARVALID;
    ARADDR  <= s_ARADDR;
    AWADDR  <= s_AWADDR;
    WDATA   <= s_WDATA;
    RREADY  <= s_RREADY;

    s_ARESETn <= ARESETn;

    process(ACLK)
    begin
        if rising_edge(ACLK) then
            if ARESETn = '0' then
                state       <= IDLE;
                trans_index <= 0;

                s_AWADDR  <= (others => '0');
                s_AWVALID <= '0';
                s_WDATA   <= (others => '0');
                WSTRB   <= (others => '1');
                s_WVALID  <= '0';
                BREADY  <= '0';

                s_ARADDR  <= (others => '0');
                s_ARVALID <= '0';
                s_RREADY  <= '0';
                LAST_READ <= (others => '0');

            else
                case state is
                    when IDLE =>
                        BREADY <= '1';
                        if trans_index < NUM_TRANS then
                            if TRANS_LIST(trans_index).w_rn(1) = '1' then
                                s_AWADDR  <= TRANS_LIST(trans_index).addr;
                                s_AWVALID <= '1';
                                state   <= WRITE_ADDR;
                            else
                                s_ARADDR  <= TRANS_LIST(trans_index).addr;
                                s_ARVALID <= '1';
                                state   <= READ_ADDR;
                            end if;
                        end if;

                    when WRITE_ADDR =>
                        if s_AWVALID = '1' and AWREADY = '1' then
                            s_AWVALID <= '0';
                            if TRANS_LIST(trans_index).w_rn(0) = '1' then
                                s_WDATA   <= TRANS_LIST(trans_index).data;
                            else
                                s_WDATA   <= LAST_READ;
                            end if;
                            s_WVALID  <= '1';
                            state   <= WRITE_DATA;
                        end if;

                    when WRITE_DATA =>
                        if s_WVALID = '1' and WREADY = '1' then
                            s_WVALID <= '0';
                            state  <= WRITE_RESP;
                        end if;

                    when WRITE_RESP =>
                        if BVALID = '1' then
                            BREADY <= '0';
                            if trans_index < NUM_TRANS-1 then
                                trans_index <= trans_index + 1;
                                state <= IDLE;    
                            else
                                state <= DONE;
                            end if;
                        end if;

                    when READ_ADDR =>
                        if s_ARVALID = '1' and ARREADY = '1' then
                            s_ARVALID <= '0';
                            s_RREADY  <= '1';
                            state   <= READ_DATA;
                        end if;

                    when READ_DATA =>
                        if RVALID = '1' then
                            s_RREADY <= '0';
                            LAST_READ <= RDATA;
                            if trans_index < NUM_TRANS-1 then
                                trans_index <= trans_index + 1;
                                state <= IDLE;    
                            else
                                state <= DONE;
                            end if;
                        end if;

                    when DONE =>
                        null;

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

end architecture;

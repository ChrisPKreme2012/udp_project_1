library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        CLOCK_FREQ : integer := 100000000; -- 100 MHz
        BAUD_RATE  : integer := 115200;
        STOP_BITS  : integer := 1            -- 1 or 2
    );
    port (
        PCLK    : in  std_logic;
        PRESETn : in  std_logic;
        PSEL    : in  std_logic;
        PENABLE : in  std_logic;
        PWRITE  : in  std_logic;
        PADDR   : in  std_logic_vector(31 downto 0);
        PWDATA  : in  std_logic_vector(31 downto 0);
        PRDATA  : out std_logic_vector(31 downto 0);
        PREADY  : out std_logic;
        PSLVERR : out std_logic;

        mdc     : in std_logic;
        tx_busy : out std_logic;
        tx_line : out std_logic
    );
end entity;

-- entity uart_tx is
--     generic (
--         CLOCK_FREQ : integer := 100000000; -- 100 MHz
--         BAUD_RATE  : integer := 115200;
--         STOP_BITS  : integer := 1            -- 1 or 2
--     );
--     port (
--         clk      : in  std_logic;
--         reset    : in  std_logic;
--         --tx_start : in  std_logic;
--         --tx_data  : in  std_logic_vector(7 downto 0);
--         tx_busy  : out std_logic;
--         tx_line  : out std_logic
--     );
-- end entity;

architecture rtl of uart_tx is

    constant BAUD_DIV : integer := CLOCK_FREQ / BAUD_RATE;  -- ≈ 10416 for 100MHz/9600

    signal baud_cnt  : integer range 0 to BAUD_DIV-1 := 0;
    signal baud_tick, data_transferred : std_logic := '0';
    
    signal s_apb_8bit  : std_logic_vector(7 downto 0) := x"55";

    type state_type is (UART_IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal uart_state : state_type := UART_IDLE;

    signal bit_index  : integer range 0 to 7 := 0;
    signal stop_count : integer range 0 to 2 := 0;
    signal shift_reg  : std_logic_vector(7 downto 0) := (others => '0');

    -- APB Slave
    type apb_state_t is (APB_IDLE, APB_SETUP, APB_ACCESS);
    signal apb_state : apb_state_t := APB_IDLE;

    signal tx_packet, s_tx_packet, s_tx_packet_sync     : std_logic_vector(63 downto 0);
-- attribute mark_debug : string;
-- attribute mark_debug of tx_line : signal is "true";
-- attribute mark_debug of shift_reg : signal is "true";

    signal byte_index    : integer range 0 to 7 := 0;
    signal sending       : std_logic := '0';
    signal s_tx_line       : std_logic := '1';


begin

    tx_line <= s_tx_line;

    -- Baud rate generator
    process(pclk)
    begin
        if rising_edge(pclk) then
            if presetn = '0' then
                baud_cnt  <= 0;
                baud_tick <= '0';
            else
                if baud_cnt = BAUD_DIV - 1 then
                    baud_cnt  <= 0;
                    baud_tick <= '1';
                else
                    baud_cnt  <= baud_cnt + 1;
                    baud_tick <= '0';
                end if;
            end if;
        end if;
    end process;

    process(mdc)
    begin
       if rising_edge(mdc) then
           s_tx_packet_sync <= tx_packet;
           s_tx_packet <= s_tx_packet_sync;
       end if;
    end process;

    

    -- UART transmit state machine
    process(pclk)
    begin
        if rising_edge(pclk) then
            if presetn = '0' then
                uart_state      <= UART_IDLE;
                s_tx_line    <= '1'; -- idle line is high
                tx_busy    <= '0';
                bit_index  <= 0;
                stop_count <= 0;
                data_transferred <= '0';
                shift_reg <= (others => '0');
            else
                data_transferred <= '0';
                if baud_tick = '1' then
                    case uart_state is

                        when UART_IDLE =>
                            s_tx_line <= '1';
                            tx_busy <= '0';
                            if sending ='1' then
                                shift_reg <= s_apb_8bit;
                                uart_state <= START_BIT;
                                tx_busy <= '1';
                            end if;

                        when START_BIT =>
                            s_tx_line <= '0'; -- start bit
                            bit_index <= 0;
                            uart_state <= DATA_BITS;

                        when DATA_BITS =>
                            s_tx_line <= shift_reg(bit_index);
                            if bit_index = 7 then
                                bit_index <= 0;
                                stop_count <= 0;
                                uart_state <= STOP_BIT;
                            else
                                bit_index <= bit_index + 1;
                            end if;

                        when STOP_BIT =>
                            s_tx_line <= '1';
                            data_transferred <= '1';
                            if stop_count = STOP_BITS - 1 then
                                uart_state <= UART_IDLE;
                            else
                                stop_count <= stop_count + 1;
                            end if;

                        when others =>
                            uart_state <= UART_IDLE;

                    end case;
                end if;
            end if;
        end if;
    end process;

------------------------------------------------------------------------------------------------

    -- APB Slave
    process(pclk)
    begin
        if rising_edge(pclk) then
            if presetn = '0' then
                apb_state      <= APB_IDLE;
                prdata     <= (others => '0');
                pready     <= '1';
                pslverr    <= '0';
                sending <= '0';
                byte_index <= 0;
                tx_packet  <= (others => '0');
                s_apb_8bit  <= (others => '0'); 
            else
                case apb_state is
                    when APB_IDLE =>
                        pready <= '1';
                        byte_index <= 0;
                        if psel = '1' and penable = '0' then
                            apb_state <= APB_SETUP;
                        end if;
                    when APB_SETUP =>
                        pready <= '0';
                        if psel = '1' and penable = '1' then
                            apb_state <= APB_ACCESS;
                        end if;
                    when APB_ACCESS =>
                        pslverr <= '0';
                        if pwrite = '1' then
                            -- WRITE
                            if sending = '0' then
                                -- Capture full 64-bit payload: address + data
                                tx_packet  <= paddr & pwdata;
                                byte_index <= 0;
                                sending    <= '1';
                                s_apb_8bit  <= paddr(31 downto 24); -- first byte (MSB)
                                --s_apb_8bit  <= pwdata(7 downto 0); -- first byte (MSB)
                            else
                                -- Wait for UART to finish sending current byte
                                if data_transferred = '1' then
                                    if byte_index = 7 then
                                        -- All 8 bytes sent
                                        sending <= '0';
                                        pready  <= '1';
                                        apb_state   <= APB_IDLE;
                                    else
                                        -- Send next byte
                                        byte_index <= byte_index + 1;
                                        s_apb_8bit  <= tx_packet(63 - (byte_index+1)*8 downto 56 - (byte_index+1)*8);
                                    end if;
                                end if;
                            end if;
                            
                        -- else
                        --     -- READ
                        --     case paddr(5 downto 2) is
                        --         when "0000" =>  -- Status register
                        --             prdata <= (31 downto 1 => '0') & tx_busy;
                        --         when others =>
                        --             prdata <= (others => '0');
                        --     end case;
                        end if;
                    when others =>
                        apb_state <= APB_IDLE;
                end case;
            end if;
        end if;
    end process;

end architecture;

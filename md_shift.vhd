library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mdio_pkg.all;

entity md_shift is
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

        -- MDIO interface
        mdc        : in  std_logic;
        serial_in  : in  std_logic;
        serial_t   : out std_logic;
        serial_out : out std_logic
    );
end entity;

-- entity md_shift is
--     port (
--         mdc        : in  std_logic;
--         rst        : in  std_logic;
--         serial_in  : in  std_logic;
--         serial_t   : out std_logic;
--         serial_out : out std_logic
--     );
-- end entity;
architecture rtl of md_shift is

-- Writable runtime register bank
signal mdio_regs : reg_array_t(MDIO_REG_ARRAY'range) := MDIO_REG_ARRAY;

-- Shift FSM signals
--signal addr_index : integer range 0 to MDIO_REG_ARRAY'high := 0;
signal addr_index : integer range 0 to 31 := 0;
signal bit_cnt    : integer range 0 to 31 := 31;
signal shift_reg  : std_logic_vector(31 downto 0):= (others => '1');
signal read_done, serial_error  : std_logic := '0';
signal idle_flag  : std_logic := '0';

    -- APB Slave
    type apb_state_t is (APB_IDLE, APB_SETUP, APB_ACCESS);
    signal apb_state : apb_state_t := APB_IDLE;

    -- MD
    type md_state_t is (MD_IDLE, MD_ONES, MD_SEND, MD_DONE);
    signal md_state : md_state_t := MD_IDLE;

    signal tx_packet     : std_logic_vector(63 downto 0);
    signal byte_index    : integer range 0 to 7 := 0;
    signal sending       : std_logic := '0';

begin

serial_out <= shift_reg(31);
process(mdc)
begin
    if PRESETn = '0' then
        addr_index  <= 0;
        bit_cnt     <= 0;
        shift_reg   <= (others => '1');
        serial_t <= '1';
        idle_flag <= '0';
        serial_error <= '0';
        mdio_regs   <= MDIO_REG_ARRAY;  -- reset statuses
        read_done   <= '0';
        md_state <= MD_IDLE;

    elsif falling_edge(mdc) and read_done = '0' then
            case md_state is
                when MD_IDLE =>
                    bit_cnt <= 0;
                    if idle_flag = '0' then
                        serial_t <= '0';
                        idle_flag <= '1';
                        shift_reg <= (others => '1');
                        md_state <= MD_ONES;
                    -- else
                    --     serial_t <= '0';
                    --     idle_flag <= '0';
                    --     --shift_reg <= b"01" & b"10" & b"00001" & mdio_regs(addr_index).addr & b"10" & mdio_regs(addr_index).v_write;
                    --     shift_reg <= b"01" & b"10" & std_logic_vector(to_unsigned(addr_index, 5)) & mdio_regs(1).addr & b"10" & mdio_regs(1).v_write;
                    --     md_state <= MD_SEND;
                    end if;
                when MD_ONES =>
                    if bit_cnt < 31 then
                        serial_t <= '0';
                        bit_cnt <= bit_cnt + 1;
                    elsif bit_cnt = 31 then
                        serial_t <= '0';
                        idle_flag <= '0';
                        bit_cnt <= 0;
                        --shift_reg <= b"01" & b"10" & b"00001" & mdio_regs(addr_index).addr & b"10" & mdio_regs(addr_index).v_write;
                        shift_reg <= b"01" & b"10" & std_logic_vector(to_unsigned(addr_index, 5)) & mdio_regs(1).addr & b"10" & mdio_regs(1).v_write;
                        md_state <= MD_SEND;
                        --serial_t <= '1';
                        --md_state <= MD_IDLE;
                    end if;
                when MD_SEND =>
                    if bit_cnt >= 16 and bit_cnt < 31 then
                        serial_t <= '1';
                        shift_reg(31) <= '0';
                        --mdio_regs(addr_index).v_write(bit_cnt-16) <= serial_in;
                        mdio_regs(1).v_write(bit_cnt-16) <= serial_in;
                        bit_cnt <= bit_cnt + 1;
                    elsif bit_cnt = 14 then
                        serial_t <= '1';
                        bit_cnt <= bit_cnt + 1;
                    elsif bit_cnt = 15 then
                        serial_t <= '1';
                        bit_cnt <= bit_cnt + 1;
                        if serial_in = '0' then
                            serial_error <= '0';
                        else
                            serial_error <= '1';
                        end if;
                    elsif bit_cnt < 14 then
                        serial_t <= '0';
                        shift_reg <= shift_reg(30 downto 0) & '1';
                        bit_cnt <= bit_cnt + 1; 
                    elsif bit_cnt = 31 then
                        --mdio_regs(addr_index).v_write(bit_cnt-16) <= serial_in;
                        mdio_regs(1).v_write(bit_cnt-16) <= serial_in;
                        serial_t <= '1';
                        --if addr_index < MDIO_REG_ARRAY'high then
                        if addr_index < 31 then
                            addr_index <= addr_index + 1;
                            md_state <= MD_IDLE;
                        else
                            md_state <= MD_DONE;
                        end if;
                    else
                        serial_t <= '1';
                        md_state <= MD_IDLE;
                    end if;
                when MD_DONE =>
                        read_done <= '1';
                        serial_t <= '1';
                when others =>
                    md_state <= MD_IDLE;
            end case;
    end if;
end process;

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
            else
                case apb_state is
                    when APB_IDLE =>
                        pready <= '1';
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
                        if pwrite = '0' and read_done = '1' then
                            -- READ
                            case paddr(4 downto 0) is
                                when "00000" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(0).addr & mdio_regs(0).v_write;
                                when "00001" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(1).addr & mdio_regs(1).v_write;
                                when "00010" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(2).addr & mdio_regs(2).v_write;
                                when "00011" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(3).addr & mdio_regs(3).v_write;
                                when "00100" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(4).addr & mdio_regs(4).v_write;
                                when "00101" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(5).addr & mdio_regs(5).v_write;
                                when "00110" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(6).addr & mdio_regs(6).v_write;
                                when "00111" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(7).addr & mdio_regs(7).v_write;
                                when "10000" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(8).addr & mdio_regs(8).v_write;
                                when "10100" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(9).addr & mdio_regs(9).v_write;
                                when "10101" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(10).addr & mdio_regs(10).v_write;
                                when "10110" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(11).addr & mdio_regs(11).v_write;
                                when "10111" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(12).addr & mdio_regs(12).v_write;
                                when "11000" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(13).addr & mdio_regs(13).v_write;
                                when "11001" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(14).addr & mdio_regs(14).v_write;
                                when "11010" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(15).addr & mdio_regs(15).v_write;
                                when "11011" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(16).addr & mdio_regs(16).v_write;
                                when "11101" =>  -- Status register
                                    prdata <= (31 downto 21 => '0') & mdio_regs(17).addr & mdio_regs(17).v_write;
                                when others =>
                                    prdata <= (others => '0');
                            end case;
                            pready <= '1';
                            apb_state <= APB_IDLE;
                        -- else
                        --     -- WRITE
                        end if;
                    when others =>
                        apb_state <= APB_IDLE;
                end case;
            end if;
        end if;
    end process;

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset_hold is
    generic (
        CLOCK_FREQ : integer := 25000000; -- 100 MHz
        TIME_MS  : integer := 167 --167 ms
    );
    port (
        ARESETn : out  std_logic;
        ext_ARESETn : in  std_logic;
        X1      : out  std_logic;
        mdc     : in  std_logic
    );
end entity;

architecture rtl of reset_hold is

    constant CLK_CNT : integer := (CLOCK_FREQ/1000) * TIME_MS;

    signal s_ARESETn    : std_logic := '0';
    signal baud_cnt  : integer range 0 to CLK_CNT-1 := 0;

begin

    ARESETn <= s_ARESETn;

    -- Reset Hold
    process(mdc)
    begin
        if rising_edge(mdc) then
            if ext_ARESETn = '1' then
                if baud_cnt = CLK_CNT - 1 then
                    s_ARESETn <= '1';
                else
                    baud_cnt  <= baud_cnt + 1;
                    s_ARESETn <= '0';
                end if;
            else
                s_ARESETn <= '0';
                baud_cnt <= 0;
            end if;
        end if;
    end process;

    X1 <= mdc when s_ARESETn = '1' else '1';

end architecture;

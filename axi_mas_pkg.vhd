library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package axi_mas_pkg is

    -- Record type for AXI transaction
    type axi_trans_t is record
        w_rn : std_logic_vector(1 downto 0); 
        addr : std_logic_vector(31 downto 0);
        data : std_logic_vector(31 downto 0);
    end record;

    -- Constant array of transactions
    constant NUM_TRANS : integer := 40;
    type trans_array_t is array(0 to NUM_TRANS-1) of axi_trans_t;

    constant TRANS_LIST : trans_array_t := (
        (w_rn => b"11", addr => x"00010000", data => x"AAAA5555"),
        (w_rn => b"11", addr => x"00010004", data => x"12345678"),
        (w_rn => b"11", addr => x"00010008", data => x"DEADBEEF"),
        (w_rn => b"11", addr => x"0001000C", data => x"0F0F0F0F"),
        (w_rn => b"00", addr => x"00000000", data => x"00000000"),
        (w_rn => b"10", addr => x"00010000", data => x"00000000"),
        (w_rn => b"00", addr => x"00000001", data => x"00000000"),
        (w_rn => b"10", addr => x"00010001", data => x"00000000"),
        (w_rn => b"00", addr => x"00000002", data => x"00000000"),
        (w_rn => b"10", addr => x"00010002", data => x"00000000"),
        (w_rn => b"00", addr => x"00000003", data => x"00000000"),
        (w_rn => b"10", addr => x"00010003", data => x"00000000"),
        (w_rn => b"00", addr => x"00000004", data => x"00000000"),
        (w_rn => b"10", addr => x"00010004", data => x"00000000"),
        (w_rn => b"00", addr => x"00000005", data => x"00000000"),
        (w_rn => b"10", addr => x"00010005", data => x"00000000"),
        (w_rn => b"00", addr => x"00000006", data => x"00000000"),
        (w_rn => b"10", addr => x"00010006", data => x"00000000"),
        (w_rn => b"00", addr => x"00000007", data => x"00000000"),
        (w_rn => b"10", addr => x"00010007", data => x"00000000"),
        (w_rn => b"00", addr => x"00000010", data => x"00000000"),
        (w_rn => b"10", addr => x"00010010", data => x"00000000"),
        (w_rn => b"00", addr => x"00000014", data => x"00000000"),
        (w_rn => b"10", addr => x"00010014", data => x"00000000"),
        (w_rn => b"00", addr => x"00000015", data => x"00000000"),
        (w_rn => b"10", addr => x"00010015", data => x"00000000"),
        (w_rn => b"00", addr => x"00000016", data => x"00000000"),
        (w_rn => b"10", addr => x"00010016", data => x"00000000"),
        (w_rn => b"00", addr => x"00000017", data => x"00000000"),
        (w_rn => b"10", addr => x"00010017", data => x"00000000"),
        (w_rn => b"00", addr => x"00000018", data => x"00000000"),
        (w_rn => b"10", addr => x"00010018", data => x"00000000"),
        (w_rn => b"00", addr => x"00000019", data => x"00000000"),
        (w_rn => b"10", addr => x"00010019", data => x"00000000"),
        (w_rn => b"00", addr => x"0000001A", data => x"00000000"),
        (w_rn => b"10", addr => x"0001001A", data => x"00000000"),
        (w_rn => b"00", addr => x"0000001B", data => x"00000000"),
        (w_rn => b"10", addr => x"0001001B", data => x"00000000"),
        (w_rn => b"00", addr => x"0000001D", data => x"00000000"),
        (w_rn => b"10", addr => x"0001001D", data => x"00000000")
    );

end package;

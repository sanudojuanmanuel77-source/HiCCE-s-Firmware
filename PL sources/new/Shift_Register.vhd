

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all; 
--------------------------------------------------------------------
ENTITY Shift_Register IS
    generic(
        N : integer := 18;
        DATA_WIDTH: integer := 18
    );
    
  Port (
    
    en: in std_logic;
    clk: in std_logic;
    sck: in std_logic; --NO como clk real... nos BUFG signal
    rst: in std_logic;
    sdo: in std_logic;
    data_ready: out std_logic;
    data_out: out std_logic_vector(DATA_WIDTH -3 downto 0) -- 16 BITS.
   );
END Shift_Register;
---------------------------------------------------------------------------------------------
architecture RTL of Shift_Register is
    signal shift_reg : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal bit_count : integer range 0 to N;
    signal ready_i   : std_logic := '0';
    signal sck_prev: std_logic;
begin
    process(clk, rst)
    begin
        if rst = '1' then
            shift_reg <= (others => '0');
            bit_count <= 0;
            ready_i   <= '0';
            sck_prev <= '0';

        elsif rising_edge(clk) then
            sck_prev <= sck;
            
            if en = '1' then
            if(sck_prev = '0' and sck = '1') then
            
            
                ------------------------------------------------
                --  Desplazo 1 bit (MSB-first)
                ------------------------------------------------
                shift_reg <=  shift_reg(DATA_WIDTH-2 downto 0) & sdo;
                -- no tiene sentido usar shift_reg(17 down to 0) , rompe modularidad.. solo shift reg...
                ------------------------------------------------
                --  Actualizo contador y ready
                ------------------------------------------------
                if (bit_count = N-1) then   -- acabamos de meter el 18.º bit
                    bit_count <= 0;
                    ready_i   <= '1';     -- pulso de 1 ciclo
                else
                    bit_count <= bit_count + 1;
                    ready_i   <= '0';
                end if;

            else                          -- en = 0
                --bit_count <= 0;
                ready_i   <= '0';
            end if;
          else
                bit_count <= 0;
                ready_i <= '0';
       end if;
     end if;
    end process;

    ----------------------------------------------------------------
    -- Salidas
    ----------------------------------------------------------------
    data_out   <= shift_reg(16 downto 1); --slice from 18 a 16 bits. MSB(sing bit) = 0. LSB = NOISE
    data_ready <= ready_i;
end RTL;


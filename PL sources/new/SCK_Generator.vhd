-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.07.2025 11:19:19
-- Design Name: 
-- Module Name: SCK_Generator - BEHAVIOR
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
------------------------------------------------------------------------------------------------
ENTITY SCK_Generator IS
    GENERIC (
        DIV_VALUE : integer := 3 --- CLK = 100 MHz / (DIV_VALUE) * 2... 16.66 MHz
    );
    PORT (
        en : in  std_logic;
        clk: in  std_logic;
        rst: in  std_logic;
        sck: out std_logic
     );
END SCK_Generator;
------------------------------------------------------------------------------------------------------
ARCHITECTURE BEHAVIOR OF SCK_Generator IS
--Declarative part of the architecture
signal counter: integer range 0 to DIV_VALUE :=0;
signal sck_reg: std_logic := '0';
signal en_reg: std_logic := '0'; 

BEGIN

    sck_geneneration: process(clk,rst)
                      begin
                      if rst='1' then 
                      counter <= 0;
                      sck_reg <= '0'; -- sck reg, evita glithes al estar registrada... 
                      en_reg <= '0';
                      elsif (rising_edge(clk))then
                        if (en = '1') then
                            if (en_reg = '0')then --primer flanco positivo
                                sck_reg <='1';
                                counter <= 0;
                            elsif (counter = DIV_VALUE - 1)then
                                counter <= 0;
                                sck_reg <= not sck_reg;
                            else
                                counter <= counter + 1;
                            end if;
                        else
                            sck_reg <= '0'; -- Se garantiza que el primer flanco sera positvo cuand en=1.
                            counter <= 0; -- se garantiza el mismo tiempo siempre que en=1
                        end if;
                      en_reg <= en;
                      end if;
                     
                     end process;
    sck <= sck_reg;                 
              
end BEHAVIOR;

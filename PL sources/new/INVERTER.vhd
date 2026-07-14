----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.09.2025 21:35:32
-- Design Name: 
-- Module Name: INVERTER - BEHAVIOR
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity INVERTER is
  Port ( 
        
        A: IN STD_LOGIC;
        B: OUT STD_LOGIC
        );
end INVERTER;

architecture BEHAVIOR of INVERTER is
SIGNAL B_int: STD_LOGIC;
begin

    B_int <= not A;
    B <= B_int;

end BEHAVIOR;

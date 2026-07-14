----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.09.2025 10:23:52
-- Design Name: 
-- Module Name: Gate_AND - BEHAVIOR
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

entity Gate_AND is
  Port (
        A: IN  STD_LOGIC;
        B: IN  STD_LOGIC;
        C: OUT STD_LOGIC
         );
end Gate_AND;

architecture BEHAVIOR of Gate_AND is

SIGNAL int_A,int_B: STD_LOGIC;

begin

    int_A <= A;
    int_B <= B;
    
    C <= int_A AND int_B;

end BEHAVIOR;

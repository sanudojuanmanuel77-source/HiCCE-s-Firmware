

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY Reset_Intans IS
  PORT (
  
        clk      : IN  STD_LOGIC;
        rst      : IN  STD_LOGIC;
        Sel0_Reset: OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        
        );
END Reset_Intans;

ARCHITECTURE BEHAVIOR OF Reset_Intans IS



 signal rst_q1, rst_q2 : std_logic := '0';
BEGIN


    PROCESS(clk,rst)
    BEGIN
    
    IF (rising_edge(clk))THEN
      rst_q1 <= rst;
      rst_q2 <= rst_q1;
        
        
        if (rst_q2 = '1' and rst_q1 = '0') then
        Sel0_Reset <= (others => '1');  -- pulso de 1 clk
      else
        Sel0_Reset <= (others => '0');
      end if;
    END IF;
    
    END PROCESS;

END BEHAVIOR;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity Synchonizer is
  Port (
        CLK: IN STD_LOGIC;
        RST: IN STD_LOGIC;
        ASYNC: IN STD_LOGIC;
        SYNC: OUT STD_LOGIC 
        );
end Synchonizer;

architecture BEHAVIOR of Synchonizer is

    SIGNAL Q1,Q2: STD_LOGIC :='0';

begin

    Process(CLK,RST)
            BEGIN
            IF (RST = '1') THEN
                Q1 <= '0';
                Q2 <= '0';
            ELSIF(rising_edge(clk))then
                  Q1 <= ASYNC;
                  Q2 <= Q1;
            END IF;
            END PROCESS;

    SYNC <= Q2;
end BEHAVIOR;

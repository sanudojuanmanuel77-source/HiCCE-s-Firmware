

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY Counter_Final IS
  PORT ( 
        clk:  IN  STD_LOGIC;
        rst:  IN  STD_LOGIC;
        t_va: IN  STD_LOGIC;
        t_re: IN  STD_LOGIC;
        t_la: OUT STD_LOGIC
        );
END Counter_Final;

ARCHITECTURE BEHAVIOR OF Counter_Final IS

SIGNAL pulses: NATURAL := 0;

CONSTANT count: NATURAL := 512;

BEGIN

        PROCESS(clk,rst)
        BEGIN
            
            IF (rst = '1') THEN
                pulses <= 0;
                t_la <= '0';
            
            ELSIF(rising_edge(clk)) THEN
                  t_la <= '0';
                  IF (t_va = '1' AND t_re = '1') THEN
                        
                       IF (pulses = count -1 ) THEN
                          t_la <= '1';
                          pulses <= 0;
                       ELSE
                        pulses <= pulses + 1;
                        t_la <= '0';
                       END IF;
                  END IF;
            END IF;
         END PROCESS;
       

END BEHAVIOR;

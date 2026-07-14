

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY tvalid_tready_counter IS
    
  GENERIC (
           count: NATURAL := 128);  
        
  PORT ( 
       clk:    IN  STD_LOGIC;
       rst:    IN  STD_LOGIC;
       tvalid: IN  STD_LOGIC;
       tready: IN  STD_LOGIC;
       full:   OUT STD_LOGIC 
           
        );
END tvalid_tready_counter;

ARCHITECTURE BEHAVIOR OF tvalid_tready_counter IS

TYPE state IS (idle,sum);

SIGNAL pr_state,nx_state: state;

SIGNAL flag_pulses: STD_LOGIC := '0';
SIGNAL pulses: natural := 0;

BEGIN

    
    State_register: PROCESS(clk,rst)
                    BEGIN
                    
                    IF (rst = '1') THEN
                    pr_state <= idle;
                    pulses <= 0;
                    full <= '0';
                    ELSIF(rising_edge(clk))THEN
                    pr_state <= nx_state;
                   full <= '0';
                    IF(flag_pulses = '1') THEN
                    pulses <= pulses + 1;
                    
                    IF(pulses = count -1) THEN
                    full <= '1';
                    pulses <= 0;
                    ELSE
                    full <= '0';
                    END IF;
                    END IF;
                    END IF;
                    
                    END PROCESS;
   
   
   Combinational_Logic: PROCESS(pr_state,tvalid,tready)
                        BEGIN
                        
                        CASE pr_state IS
                        
                        WHEN idle => 
                                       -- full <= '0';
                                        flag_pulses <= '0';
                                        IF (tvalid='1' AND tready = '1') THEN
                                           flag_pulses <= '1';
                                           nx_state <= sum;
                                        ELSE
                                           nx_state <= idle;
                                        END IF;
                                        
                        WHEN sum =>
                                        
                                        
                                        
                                    --    IF (pulses = count -1) THEN
                                      --  nx_state <= samples;
                                       -- ELSE
                                        nx_state <= idle;
                                       -- END IF;
                                        flag_pulses <= '0';
                                                 
                     --  WHEN samples =>
                           --             full <= '1';  
                           --             flag_pulses <= 0;
                                        
                             --           nx_state <= idle;               
                    
                      WHEN others => 
                                       -- full <= '0';
                                       -- pulses <= 0;
                                        nx_state <= idle;
                                        flag_pulses <= '0';
                      
                      END CASE;
                      
                      END PROCESS;

END BEHAVIOR;

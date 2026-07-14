
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY valve_FSM IS

  GENERIC(
          ports: NATURAL := 4
          );
    
  PORT (
        
        clk   :  IN  STD_LOGIC;
        rst   :  IN  STD_LOGIC;
        last  :  IN  STD_LOGIC;
        pulses:  IN  STD_LOGIC_VECTOR (ports - 1 DOWNTO 0);
        enables: OUT STD_LOGIC_VECTOR (ports - 1 DOWNTO 0)
   );
   
END valve_FSM;

ARCHITECTURE BEHAVIOR OF valve_FSM IS

TYPE state IS (idle,engage,engage2);

SIGNAL pr_state,nx_state: state;

SIGNAL flags: STD_LOGIC_VECTOR (ports -1 DOWNTO 0) := (OTHERS => '0');

SIGNAL clr_flag: STD_LOGIC := '0';

BEGIN


    state_register: PROCESS(clk,rst)
                        BEGIN
                        
                        IF (rst = '1') THEN
                           pr_state <= idle;
                          -- clr_flag <= '0';
                           flags <= (OTHERS => '0');
                           
                        ELSIF(rising_edge(clk)) THEN
                            pr_state <= nx_state;
                            
                            
                            
                            IF (clr_flag = '1') THEN
                                flags <= (OTHERS => '0');
                            ELSE
                            flags <= flags OR pulses;
                            END IF;
                        END IF; 
                          
                     --    IF (pulses(0) = '1') THEN
                       --     flags(0) <= '1';
                       --  END IF
                         
                       --  IF (pulses(1) = '1') THEN
                        --    flags(1) <= '1';
                       --  END IF;
                       --  END IF;
                         END PROCESS;


                combinational_logic: PROCESS(pr_state,flags,last)
                                     BEGIN
                                     
                                     CASE pr_state IS
                                     
                                        WHEN idle =>
                                                        enables <= (OTHERS => '0');
                                                        clr_flag <= '0';
                                                        IF (flags = "1111") THEN
                                                            
                                                            nx_state <= engage;
                                                        ELSE
                                                            nx_state <= idle;
                                                        END IF;    
                    
                                      WHEN engage =>
                                                       enables <= "0001";
                                                       clr_flag <= '0';
                                                       nx_state <= engage2;
                                      
                                      WHEN engage2 => 
                                                        enables <= (OTHERS => '1');
                                                        
                                                        IF (last = '1') THEN
                                                           --flags <= (OTHERS => '0');
                                                           clr_flag <= '1';
                                                           nx_state <= idle;
                                                        ELSE
                                                            clr_flag <= '0';
                                                           nx_state <= engage2;
                                                        END IF;
                                      
                                      WHEN OTHERS =>
                                                       enables <= (OTHERS => '0');
                                                       nx_state <= idle;
                                                        clr_flag <= '0';
                                      END CASE;
                                      END PROCESS;
                                      


END BEHAVIOR;

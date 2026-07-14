library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.numeric_std.all;
--------------------------------------------------------------
entity Step_FSM is
  
  Generic(
        Tone: natural := 10 -- T = 10 ns ; 100 ns de delay...
        );
       
  
  Port(
        CNV: in std_logic;
        rst: in std_logic;
        clk: in std_logic;
        STEP: out std_logic
       );
end Step_FSM;
-----------------------------------------------------------------------------
architecture BEHAVIOR of Step_FSM is
    type state is (idle,delay,state_wait,pulse);
    signal pr_state,nx_state: state;
    --attribute enum_encoding of state: type is "sequential";
    
    constant T1: natural := Tone;
    constant Tmax: natural := Tone - 1;
    signal   t: natural range 0 to Tmax;

    signal reg_step: std_logic := '0';
begin


    --timer
    
    timer: process (clk,rst)
           begin
           if (rst = '1') then -- SISTEMA INICIA CON RST = '1'... si no step valor indefinido
               t <= 0;
           elsif(rising_edge(clk))then
                
                        if (pr_state /= nx_state) then
                        t <= 0; -- se resetea en cada cambio de estado...
                        elsif(t/= tmax) then
                            t <= t + 1;
                        end if;
                end if;
           end process;
    
    --FSM state register
    
    state_register: process(clk,rst)
                    begin
                        if (rst = '1') then
                            pr_state <= idle;
                           -- nx_state <= idle; DEADLOCK... NO TIENE SENTIDO.
                            
                        elsif(rising_edge(clk))then
                            pr_state <= nx_state;
                        end if;
                    end process;
                    
                    
    --FSM combinational logic
     combinational_logic:process(CNV,pr_state,t)
                        begin
                            
                            case pr_state is
                            
                               when idle =>
                                            reg_step <= '0';
                                            --STEP <= '0';
                                            if (CNV = '1')then
                                               nx_state <= delay;
                                            else
                                               nx_state <= idle;
                                            end if;
                               when delay =>
                                            reg_step <= '0';
                                            --STEP <= '0';
                                            if t = Tmax then
                                               nx_state <= pulse;
                                            else
                                               nx_state <= delay;
                                            end if;
                              when pulse =>
                                          --STEP <= '1';
                                        reg_step <= '1';
                                        nx_state <= state_wait;
                                        
                              when state_wait =>
                                         -- STEP <= '0';
                                          reg_step <= '0';
                                          
                                          if (cnv = '0')then
                                            nx_state <= idle;
                                          else
                                            nx_state <= state_wait;
                                          end if;
                              when others => 
                                           nx_state <= idle;
                                           --STEP <= '0';
                                           reg_step <= '0';
                            
                          end case;
                          
                      end process;
            
            registered_output:process(clk,rst)
                              begin
                              
                              if (rst = '1') then
                                 STEP <= '0'; 
                                 --reg_step <= '0';
                              elsif(rising_edge(clk))then
                                   STEP <= reg_step; --registrada... reducir posiblidad de glitch conmutando canal de RHA2132.
                              end if;
                              end process;
            
            
                   
                                    
                                       
                                                     

end BEHAVIOR;

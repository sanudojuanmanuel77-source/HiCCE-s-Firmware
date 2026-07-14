

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
--USE IEEE.numeric_std.ALL;


ENTITY SPI_FSM IS

  GENERIC (
           CONSTANT T1: NATURAL := 500; --  34.000 ciclos para settle 340 microsegundos de settle
           CONSTANT T2: NATURAL := 90; -- 900 ns de CNV - 500 ns min 800 ns máx tiempo de converion
           CONSTANT T3: NATURAL := 6 -- 60 ns wait for MSB in SDO (Datapath), 18 a 40 ns. 
           
         
          );

      PORT (
            clk:        IN STD_LOGIC;
            rst:        IN STD_LOGIC;
            data_ready: IN STD_LOGIC;
            CONN:       IN STD_LOGIC;
            en:         OUT STD_LOGIC;
            cnv:        OUT STD_LOGIC;
            local_rst:  OUT STD_LOGIC;
            settle:     OUT STD_LOGIC
        --out_rst :OUT STD_LOGIC; ... manejo el rst de todos los submodulos?
         );
         
END ENTITY SPI_FSM;

ARCHITECTURE BEHAVIOR OF SPI_FSM IS

TYPE state IS (idle,wait_settle,start,wait_MSB,shift,wr_fifo);-- ultimo estado fifo mmm

SIGNAL pr_state,nx_state: state;

CONSTANT T1_i: NATURAL := T1;
CONSTANT T2_i: NATURAL := T2;
CONSTANT T3_i: NATURAL := T3;
CONSTANT Tmax: NATURAL := T1;
SIGNAL   t   : NATURAL range 0 to Tmax;

SIGNAL cnv_i, settle_i,en_i,local_rst_i: STD_LOGIC := '0';

BEGIN
    
    timer: process(rst,clk)
                  begin
                  if (rst = '1')then
                      t <= 0;
                  elsif(rising_edge(clk))then
                       if (pr_state /= nx_state)then
                           t <= 0;
                       elsif (t /= Tmax) then
                           t <= t+1;
                       end if;
                  end if;
           end process timer;
                  
    




    fsm_register: process(clk,rst) -- perdida de conexion tiene que ir a idle
                  begin
                  if(rst='1') then
                    pr_state <= idle;
                  
                  elsif(rising_edge(clk))then
                    pr_state <= nx_state;
                  end if;
                  end process;
                  
    
    fms_comb_logic:process(pr_state,data_ready,t,conn)
                   begin
               
                  -- if (conn = '0') then  -- si la conexion se pierde en cualquier momento, pum a idle.
                          --NO COMO FILTRO GLOBAL.. SOLO EN LOS ESTADOS FUERA DE IDLE Y WAIT          
                    --  CNV_i <= '0';
                     -- settle_i <= '0';
                     -- en_i <= '0';
                     -- local_rst_i <= '1';  -- por las dudas, reset general
                     -- nx_state <= idle;  
                  -- else
                   
                   case pr_state is
                   
                   when idle =>
                               
                               CNV_i <= '0';
                               settle_i <= '1';
                               en_i <= '0';
                               local_rst_i <= '1'; --resetea sus submodulos.
                               nx_state <= wait_settle;
                  
                  when wait_settle => -- en este estado ademas del setlle del RHA2132...deberia esperar por un inicio de conexion para envio de datos... RST de modulos por esta fms??
                            
                               CNV_i <= '0';
                               settle_i<= '0';
                               en_i <= '0';
                               local_rst_i <= '0';
                               if (t >= T1_i -1 AND CONN='1') then -- señal start que venga del PS ???? Cuando haya conexion en FreeRTOS
                                   nx_state  <= start;
                               else                         -- CONN INDICA QUE EL HAY CONEXIÓN CON EL SERVIDOR
                                   nx_state <= wait_settle;
                               end if;
                  
                  when start =>
                                
                                CNV_i <= '1';
                                en_i <= '0';
                                settle_i <= '0';
                                local_rst_i <= '0';
                                if (conn = '0')then
                                nx_state <= idle;
                                elsif (t >= T2_i -1) then
                                   nx_state <= wait_MSB;
                               else
                                   nx_state <= start;
                               end if;
                 
                 when wait_MSB => 
                               CNV_i <= '0';
                               en_i  <= '0';
                               settle_i <= '0';
                               local_rst_i <= '0';
                               if (conn = '0')then
                                nx_state <= idle;
                               elsif(t >= T3_i -1)then
                                  nx_state <= shift;
                               else
                                  nx_state <= wait_MSB;
                               end if;
                 
                 when shift => 
                               
                               CNV_i <= '0';
                               en_i <= '1';
                               settle_i <= '0';
                               local_rst_i <= '0';
                               if (conn = '0')then
                                nx_state <= idle;
                               elsif (data_ready = '1')then
                                   nx_state <= wr_fifo;
                               else
                                   nx_state <= shift;
                               end if;
                
                when wr_fifo =>     
                                
                                CNV_i <= '0';
                                EN_i <= '0';
                                settle_i <= '0';
                                local_rst_i <= '0';
                                -- if esperando que FIFO a haya guardado el dato?
                                if (conn = '0')then
                                nx_state <= idle;
                                else
                                nx_state <= start;
                                end if;
                   when others =>
                                CNV_i <= '0';
                               settle_i <= '1';
                               en_i <= '0';
                               local_rst_i <= '1'; --resetea sus submodulos.
                               
                                
                                nx_state <= idle;
                   end case;
              --end if;
               end process;
               
               
                  
                               
          registerd_output: process(clk,rst)
                            begin
                            
                        --REGISTRAR SALIDAS, GLITCHES NO PERMITIDOS.                  
                if (rst = '1')then
                CNV <= '0';
                en <='0';
                settle <='0';
                local_rst <= '1';
                elsif(rising_edge(clk))then
                
                CNV <= cnv_i;
                en <= en_i;
                settle <= settle_i;                
                local_rst <= local_rst_i;
                end if;
             end process;              
                               
                    
   


END  BEHAVIOR;

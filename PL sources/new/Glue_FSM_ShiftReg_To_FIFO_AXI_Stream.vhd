

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;



ENTITY Glue_FSM_ShiftReg_To_FIFO_AXI_Stream is
 

 GENERIC(
        CONSTANT DATA_WIDTH: NATURAL := 16
        );
 
 PORT (
        clk       : IN STD_LOGIC;
        rst       : IN STD_LOGIC;
        data_ready: IN STD_LOGIC;
        data_out  : IN STD_LOGIC_VECTOR(DATA_WIDTH -1 DOWNTO 0);
        
        --s_axis_tready: IN STD_LOGIC;
        -- AXI-Stream Master to FIFO. S_AXIS.
        m_axis_tvalid : OUT STD_LOGIC;
        m_axis_tdata  : OUT STD_LOGIC_VECTOR(DATA_WIDTH -1 DOWNTO 0);
        m_axis_tready : IN  STD_LOGIC
         
         );
end Glue_FSM_ShiftReg_To_FIFO_AXI_Stream;

architecture BEHAVIOR of Glue_FSM_ShiftReg_To_FIFO_AXI_Stream is

TYPE state IS (idle,wait_tready);
SIGNAL pr_state,nx_state: state;

--control signals AXI Master.
SIGNAL data_reg       : STD_LOGIC_VECTOR(DATA_WIDTH -1 DOWNTO 0) := (OTHERS => '0');
SIGNAL tvalid_reg     : STD_LOGIC := '0';
SIGNAL data_ready_prev: STD_LOGIC := '0';

SIGNAL ld_data : STD_LOGIC; -- load data
SIGNAL set_valid: STD_LOGIC; -- tvalid to 1
SIGNAL clr_valid: STD_LOGIC; -- t valid to 0

 --DATA_OUT_INT: STD_LOGIC_VECTOR(DATA_WIDTH -1 DOWNTO 0) := (others => '0');


BEGIN


  

        fsm_register:process(clk,rst)
                     begin
                     if(rst = '1')then
                        pr_state <= idle;
                        data_reg <= (others => '0');
                        tvalid_reg <= '0';
                        data_ready_prev <= '0';
                     elsif(rising_edge(clk))then
                        pr_state <= nx_state;
                        data_ready_prev <= data_ready;
                      
                      if (ld_data = '1')then
                         data_reg <= data_out;
                      end if;
                      
                      if(set_valid = '1')then
                         tvalid_reg <= '1'; 
                     end if;
                     
                     if (clr_valid = '1')then
                         tvalid_reg <= '0';
                     end if;
                    end if;
                     end process;
                     
            -- REGISTERED OUTPUTS.         
           m_axis_tdata  <= data_reg;
            m_axis_tvalid <= tvalid_reg;
                     
        com_logic_fsm:process(data_ready,data_ready_prev,pr_state,m_axis_tready,tvalid_reg)
                       
                       begin
                       -- defaults (evita latches)
                    nx_state  <= pr_state;
                    ld_data   <= '0';
                    set_valid <= '0';
                    clr_valid <= '0';
                      CASE pr_state IS
                                
                                WHEN idle =>
                                            
                                             
                                      if (data_ready_prev = '0' AND data_ready = '1')then
                                            
                                                ld_data <= '1';
                                                set_valid <= '1';
                                               
                                              
                                               nx_state <= wait_tready;
                                        else
                                        nx_state <= idle;
                                      end if;
                                   
                                 WHEN wait_tready =>
                                            
                                           
                                            if (tvalid_reg = '1' AND m_axis_tready = '1') then
                                               clr_valid <= '1';
                                               nx_state <= idle;
                                               
                                            else
                                               
                                               nx_state <= wait_tready;
                                            end if;
                                            
                                    WHEN OTHERS =>
                                                    nx_state <= idle;
                                   
                                   END CASE;
                              END PROCESS;
                              
                                           
          
          
          
          
          


end BEHAVIOR;

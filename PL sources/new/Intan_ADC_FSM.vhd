
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
--USE IEEE.NUMERIC.ALL;


ENTITY Intan_ADC_FSM IS
    
    GENERIC(
            DATA: STD_LOGIC_VECTOR := "000000000000010101"
            );

  Port ( 
        clk: IN  STD_LOGIC;
        clr: IN  STD_LOGIC;
        CNV: IN  STD_LOGIC;
        EN : IN  STD_LOGIC;
        SCK: IN  STD_LOGIC;
        SDO: OUT STD_LOGIC
  
        );
END Intan_ADC_FSM;

ARCHITECTURE BEHAVIOR OF Intan_ADC_FSM IS
TYPE state IS (idle,wait_cnv,delay_msb,give_data);
SIGNAL pr_state,nx_state: state;

CONSTANT test_vector_5mv: STD_LOGIC_VECTOR(17 DOWNTO 0) := DATA;


SIGNAL sck_prev,cnv_prev,sdo_r,sdo_next: STD_LOGIC := '0';
SIGNAL count,count_next: INTEGER RANGE 0 TO 17 := 17;

SIGNAL  sck_fall : STD_LOGIC := '0';
 SIGNAL cnv_rise, cnv_fall : STD_LOGIC := '0';
BEGIN


sdo <= sdo_r ;
state_register_fsm:PROCESS(clk,clr)
                   BEGIN
                   
                   IF (clr = '1')THEN
                   pr_state <= idle;
                   sdo_r <= '0';
                   count <= 17;
                   sck_prev <= '0';
                   cnv_prev <= '0';
                    sck_fall <= '0';
                   cnv_rise <= '0'; cnv_fall <= '0';
                   ELSIF (rising_edge(clk))THEN
                   
                  

      IF (sck_prev = '1' AND SCK = '0') THEN
        sck_fall <= '1';
      ELSE
        sck_fall <= '0';
      END IF;

      IF (cnv_prev = '0' AND CNV = '1') THEN
        cnv_rise <= '1';
      ELSE
        cnv_rise <= '0';
      END IF;

      IF (cnv_prev = '1' AND CNV = '0') THEN
        cnv_fall <= '1';
      ELSE
        cnv_fall <= '0';
      END IF;
                   
                   
                   sck_prev <= SCK;
                     cnv_prev <= CNV;
                   
                   pr_state <= nx_state;
                   sdo_r <= sdo_next;
                  count    <= count_next;
                                    
                                  
                   END IF;
                   
                     
                   END PROCESS;
                   
                   
com_logic: PROCESS(pr_state, EN, cnv_rise, cnv_fall, sck_fall, count, sdo_r)
           BEGIN
           -- defaults
    nx_state   <= pr_state;
    sdo_next   <= sdo_r;
    count_next <= count;
    
           CASE pr_state IS
           
           WHEN idle =>
                        
                        --sdo <= '0';
                        sdo_next <= '0';
                        count_next <= 17;
                        
                        IF (cnv_rise = '1') THEN
                            
                            nx_state <= wait_cnv;
                        ELSE
                            nx_state <= idle;
                        END IF;
           
           WHEN wait_cnv =>
                           sdo_next <= '0';
                            
                            IF (cnv_fall = '1') THEN
                            nx_state <= delay_msb;
                            ELSE
                            nx_state <= wait_cnv;
                            END IF;
           WHEN delay_msb =>
                            
                            sdo_next   <= TEST_VECTOR_5MV(count);
                            count_next <=17;
                            IF (en = '1') THEN
                            nx_state <= give_data;
                            ELSE
                            nx_state <= delay_msb;
                            END IF;
          
          WHEN give_data =>
  IF (sck_fall='1') THEN
    IF (count = 0) THEN
      -- ya estábamos mostrando el LSB, se termina
      count_next <= 17;
      nx_state   <= idle;
      -- (sdo_next se mantiene con el último bit hasta que vuelvas a CNV)
    ELSE
      -- bajá el contador y PRE-CARGÁ el próximo bit en el mismo ciclo de clk
      count_next <= count - 1;
      sdo_next   <= TEST_VECTOR_5MV(count - 1);
      nx_state   <= give_data;
    END IF;
  END IF;
          
          WHEN OTHERS => 
                           -- sdo <= '0';
                            nx_State <= idle;
          
          END CASE;
          END PROCESS;            
                                       
                   
                    

END BEHAVIOR;

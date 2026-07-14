
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY MUX_NOT IS
  PORT ( 
        
        IT          : IN  STD_LOGIC;
        sel            : IN  STD_LOGIC;
        OT         : OUT STD_LOGIC
        );
END MUX_NOT;


ARCHITECTURE BEHAVIOR OF MUX_NOT IS

SIGNAL internal: STD_LOGIC;

BEGIN

        internal <= IT;
        
     OT <= (not internal) WHEN sel = '0' ELSE internal;


END BEHAVIOR;

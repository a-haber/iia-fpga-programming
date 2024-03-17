LIBRARY IEEE;
USE ieee.std_logic_1164.all;

ENTITY tlc IS
    PORT(
        clk : IN std_logic;
        request : IN std_logic;
        reset : IN std_logic;
        output : OUT std_logic_vector(4 DOWNTO 0)
    );

END tlc;

ARCHITECTURE tlc_arch OF tlc IS

    -- Build an enumerated type for the state machine
    TYPE state_type IS (G, Y, R);
    -- Register to hold the current state
    SIGNAL state : state_type;

BEGIN

    -- Logic to advance to the next state
    PROCESS (clk, reset)
        VARIABLE count : INTEGER;
    BEGIN
        IF reset = '0' THEN
            state <= G;
        ELSIF rising_edge(clk) THEN
            CASE state IS
                WHEN G=>
                    IF request = '0' THEN
                        state <= Y;
                        count := 0;
                    END IF;
                WHEN Y=>
                    -- Define time constants
                    -- (50MHz clk means 50000000 cycles/s)
                    IF count = 250000000 THEN
                        state <= R;
                        count := 0;
                    ELSE
                        count := count + 1;
                    END IF;
                WHEN R=>
                    IF count = 500000000 THEN
                        state <= G;
                        count := 0;
                    ELSE
                        count := count + 1;
                    END IF;
            END CASE;
        END IF;
    END PROCESS;

    -- Output depends solely on the current state
    PROCESS (state)
    BEGIN
        CASE state IS
            WHEN G =>
                output <= "10001";
            WHEN Y =>
                output <= "10010";
            WHEN R =>
                output <= "01100";
        END CASE;
    END PROCESS;

END tlc_arch;
LIBRARY IEEE;
USE ieee.std_logic_1164.all;

ENTITY tlc IS
    PORT(
        clk : IN std_logic;
        request : IN std_logic;
        reset : IN std_logic;
        hex0, hex1 : OUT std_logic_vector(6 DOWNTO 0);
        output : OUT std_logic_vector(4 DOWNTO 0)
    );

END tlc;

ARCHITECTURE tlc_arch OF tlc IS

    COMPONENT bcd7seg                                                       -- component declaration
    PORT (  bcd: IN std_logic_vector(0 TO 3);
            hex: OUT std_logic_vector(0 to 6));
    END COMPONENT;

    SIGNAL timer : std_logic_vector(7 DOWNTO 0):="11111111";


    -- Build an enumerated type for the state machine
    TYPE state_type IS (G, Y, R, G1);
    -- Register to hold the current state
    SIGNAL state : state_type;

BEGIN


    bcd7seg0 : bcd7seg PORT MAP (timer(7 DOWNTO 4), hex0);                  -- component instantiation
    bcd7seg1 : bcd7seg PORT MAP (timer(3 DOWNTO 0), hex1);

    -- Logic to advance to the next state
    PROCESS (clk, reset)
        VARIABLE count : INTEGER;
    BEGIN
        IF reset = '0' THEN
            state <= G;
            timer <= "11111111";  -- turn off the timer leds
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
                    IF count = 250000000            -- wait 5 seconds
                        state <= R;
                        count := 0;
                    ELSE
                        count := count + 1;
                    END IF;
                WHEN R=>
                    IF count = 0 THEN
                        timer <= "00010000";
                        count := count + 1;
                    ELSIF count = 50000000 THEN
                        timer <= "00001001";
                        count := count + 1;
                    ELSIF count = 100000000 THEN
                        timer <= "00001000";
                        count := count + 1;
                    ELSIF count = 150000000 THEN
                        timer <= "00000111";
                        count := count + 1;
                    ELSIF count = 200000000 THEN
                        timer <= "00000110";
                        count := count + 1;
                    ELSIF count = 250000000 THEN
                        timer <= "00000101";
                        count := count + 1;
                    ELSIF count = 300000000 THEN
                        timer <= "00000100";
                        count := count + 1;
                    ELSIF count = 350000000 THEN
                        timer <= "00000011";
                        count := count + 1;
                    ELSIF count = 400000000 THEN
                        timer <= "00000010";
                        count := count + 1;
                    ELSIF count = 450000000 THEN
                        timer <= "00000001";
                        count := count + 1;
                    ELSIF count = 500000000 THEN
                        timer <= "11111111";
                        count := 0;
                        state <= G1;
                    ELSE
                        count := count + 1;
                    END IF;
                WHEN G1=>
                    IF count = 500000000        -- wait 10 seconds
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
            WHEN G1 =>
                output <= "10001"; -- same output as for normal green state G
        END CASE;
    END PROCESS;
END tlc_arch;

LIBRARY IEEE;
USE ieee.std_logic_1164.all;

ENTITY bcd7seg IS
    PORT (
        bcd : IN STD_LOGIC_VECTOR(0 TO 3);
        hex : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE behaviour OF bcd7seg IS
BEGIN
    hex <= "1000000" WHEN (bcd = "0000") ELSE -- 0
            "1111001" WHEN (bcd = "0001") ELSE -- 1
            "0100100" WHEN (bcd = "0010") ELSE -- 2
            "0110000" WHEN (bcd = "0011") ELSE -- 3
            "0011001" WHEN (bcd = "0100") ELSE -- 4
            "0010010" WHEN (bcd = "0101") ELSE -- 5
            "0000011" WHEN (bcd = "0110") ELSE -- 6
            "1111000" WHEN (bcd = "0111") ELSE -- 7
            "0000000" WHEN (bcd = "1000") ELSE -- 8
            "0011000" WHEN (bcd = "1001") ELSE -- 9
            "1111111";
END behaviour;

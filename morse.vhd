
LIBRARY IEEE;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY morse IS
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;			-- async reset button
		display_request : IN std_logic;	-- button to display selected letter
		sw2, sw1, sw0 : IN std_logic;	-- switches to select letter
		led : OUT std_logic
	);
END morse;

ARCHITECTURE behaviour OF morse IS

	COMPONENT letter_selector
	PORT (
		switches : IN std_logic_vector(2 DOWNTO 0);
		select_button : IN std_logic;
		morse_letter : OUT std_logic_vector(3 DOWNTO 0);
		code_length : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
	);
	END COMPONENT;
	 
	COMPONENT shift_register
	GENERIC (N: INTEGER := 4);
	PORT (
		data: IN std_logic_vector(N-1 DOWNTO 0);
		load, enable: IN std_logic;
		Clock: IN std_logic;
		shifted_data: BUFFER std_logic_vector(N-1 DOWNTO 0)
	);
	END COMPONENT;

	SIGNAL half_sec_count : std_logic_vector(24 DOWNTO 0);
	SIGNAL new_data : std_logic_vector(3 DOWNTO 0);
	SIGNAL new_data_length : std_logic_vector(2 DOWNTO 0);
	SIGNAL data : std_logic_vector(3 DOWNTO 0);
	SIGNAL load : std_logic;
	SIGNAL enable : std_logic;
	
	TYPE state_type IS (OFF, PAUSE, DOT, DASH, SHIFT);
	SIGNAL state : state_type;

BEGIN

	selection : letter_selector PORT MAP (sw2 & sw1 & sw0, display_request, new_data, new_data_length);
	shift_and_count : shift_register PORT MAP (new_data, load, enable, clk, data);

	-- Create a half-second counter to produce a 0.5s enable from the 50MHz clock
	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF half_sec_count = "1011111010111100001000000" THEN -- (25 000 000 in binary)
				half_sec_count <= (others => '0'); -- reset the counter
			ELSE
				half_sec_count <= std_logic_vector(unsigned(half_sec_count) + 1);
			END IF;
		END IF;
	END PROCESS;

	-- Logic for the finite state machine (advance between states)
	PROCESS (clk, reset)
		VARIABLE dash_count : INTEGER := 0; -- to track half-second counter over multiple cycles
		VARIABLE data_length : INTEGER; -- length counter implemented as a variable here
	BEGIN
		IF reset = '0' THEN
			state <= OFF;
		ELSIF rising_edge(clk) THEN
			CASE state IS
				WHEN OFF=>
					enable <= '0';
					IF display_request = '0' THEN
						load <= '1';
						data_length := to_integer(unsigned(new_data_length));
						state <= PAUSE;
					END IF;
				WHEN PAUSE=>
					load <= '0';
					enable <= '0';
					IF half_sec_count = (half_sec_count'range => '0') THEN -- advance to next state after 0.5s, when half_sec_count = 0
						IF data(0) = '0' THEN
							state <= DOT;
						ELSIF data(0) = '1' THEN
							state <= DASH;
						END IF;
					END IF;
				WHEN DOT=>
					IF half_sec_count = (half_sec_count'range => '0') THEN -- advance to next state after 0.5s
						state <= SHIFT;
					END IF;
				WHEN DASH=>
					IF half_sec_count = (half_sec_count'range => '0') THEN
						IF dash_count = 2 THEN -- advance to next state after 1.5s
							dash_count := 0;
							state <= SHIFT;
						ELSE
							dash_count := dash_count + 1;
						END IF;
					END IF;
				WHEN SHIFT=>
					enable <= '1';
					data_length := data_length - 1;
					IF data_length = 0 THEN
						state <= OFF;
					ELSE
						state <= PAUSE;
					END IF;
			END CASE;
		END IF;
	END PROCESS;

	-- Output depends solely on the current state (Moore machine)
	PROCESS (state)
	BEGIN
		CASE state IS
			WHEN OFF | PAUSE | SHIFT =>
				led <= '0';
			WHEN DOT | DASH =>
				led <= '1';
		END CASE;
	END PROCESS;

END behaviour;

LIBRARY IEEE;
USE ieee.std_logic_1164.all;

ENTITY letter_selector IS
	PORT (
		switches : IN std_logic_vector(2 DOWNTO 0);
		select_button : IN std_logic;
		morse_letter : OUT std_logic_vector(3 DOWNTO 0);
		code_length : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)	  -- indicates how long (how many states) the code is
	);
END ENTITY;

ARCHITECTURE behaviour OF letter_selector IS
BEGIN
	PROCESS (select_button)
	BEGIN
		IF (select_button = '0') THEN	-- (low logic level when button pressed)
			CASE switches IS			-- nb we will read the letters from right to left so need to reverse them in morse_letter
				WHEN "000" =>			-- A = .- = 01
					morse_letter <= "0010";
					code_length <= "010";
				WHEN "001" =>			-- B = -... = 1000
					morse_letter <= "0001";
					code_length <= "100";
				WHEN "010" =>			-- C = -.-. = 1010
					morse_letter <= "0101";
					code_length <= "100";
				WHEN "011" =>			-- D = -.. = 100
					morse_letter <= "0001";
					code_length <= "011";
				WHEN "100" =>			-- E = . = 0
					morse_letter <= "0000";
					code_length <= "001";
				WHEN "101" =>			-- F = ..-. = 0010
					morse_letter <= "0100";
					code_length <= "100";
				WHEN "110" =>			-- G = --. = 110
					morse_letter <= "0011";
					code_length <= "011";
				WHEN "111" =>			-- H = .... = 0000
					morse_letter <= "0000";
					code_length <= "100";
			END CASE;
		END IF;
	END PROCESS;
END behaviour;

LIBRARY IEEE;
USE ieee.std_logic_1164.all;

ENTITY shift_register IS
	GENERIC (N: INTEGER := 4);
	PORT (
		data: IN std_logic_vector(N-1 DOWNTO 0);
		load, enable: IN std_logic;
		Clock: IN std_logic;
		shifted_data: BUFFER std_logic_vector(N-1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE behaviour OF shift_register IS
BEGIN
	PROCESS
	BEGIN
		WAIT UNTIL Clock'EVENT AND Clock = '1';
		IF load = '1' THEN
			shifted_data <= data;
		ELSE
			IF enable = '1' THEN
				FOR i IN 0 TO N-2 LOOP
					shifted_data(i) <= shifted_data(i+1);
				END LOOP;
				shifted_data(N-1) <= '0';
			END IF;
		END IF;
	END PROCESS;
END behaviour;
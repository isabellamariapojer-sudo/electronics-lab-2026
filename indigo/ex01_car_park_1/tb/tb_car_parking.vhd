library ieee;
use ieee.std_logic_1164.all;

entity tb_Car_Parking_System is
end entity tb_Car_Parking_System;

architecture test of tb_Car_Parking_System is

    -- Component declaration matching your handout's exact specification
    component Car_Parking_System_VHDL is
        port (
            clk          : in  std_logic;
            reset_n      : in  std_logic;
            front_sensor : in  std_logic;
            back_sensor  : in  std_logic;
            password_1   : in  std_logic_vector(1 downto 0);
            password_2   : in  std_logic_vector(1 downto 0);
            GREEN_LED    : out std_logic;
            RED_LED      : out std_logic;
            HEX_1        : out std_logic_vector(6 downto 0);
            HEX_2        : out std_logic_vector(6 downto 0)
        );
    end component;

    -- Clock period: 10 ns
    constant CLK_PERIOD : time := 10 ns;

    -- Input signals
    signal s_clk          : std_logic := '0';
    signal s_reset_n      : std_logic := '1';
    signal s_front_sensor : std_logic := '0';
    signal s_back_sensor  : std_logic := '0';
    signal s_password_1   : std_logic_vector(1 downto 0) := "00";
    signal s_password_2   : std_logic_vector(1 downto 0) := "00";

    -- Output signals
    signal s_GREEN_LED : std_logic;
    signal s_RED_LED   : std_logic;
    signal s_HEX_1     : std_logic_vector(6 downto 0);
    signal s_HEX_2     : std_logic_vector(6 downto 0);

begin

    -- Unit Under Test (UUT) instantiation
    UUT: Car_Parking_System_VHDL
        port map (
            clk          => s_clk,
            reset_n      => s_reset_n,
            front_sensor => s_front_sensor,
            back_sensor  => s_back_sensor,
            password_1   => s_password_1,
            password_2   => s_password_2,
            GREEN_LED    => s_GREEN_LED,
            RED_LED      => s_RED_LED,
            HEX_1        => s_HEX_1,
            HEX_2        => s_HEX_2
        );

    -- Clock generator process
    Clk_Process: process
    begin
        s_clk <= '0';
        wait for CLK_PERIOD / 2;
        s_clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus process
    Stimulus_Process: process
    begin
        report "=== Start Simulation ===";

        -- Initialize inputs
        s_front_sensor <= '0';
        s_back_sensor  <= '0';
        s_password_1   <= "00";
        s_password_2   <= "00";

        -- Initial Reset
        s_reset_n <= '0';
        wait for CLK_PERIOD * 5;
        s_reset_n <= '1';
        wait for CLK_PERIOD;

       -----------------------------------------------------------------------
        -- Scenario 1: Normal Entry
        -----------------------------------------------------------------------
          -- 1. Car arrives
        s_front_sensor <= '1';
        s_password_1   <= "01";
        s_password_2   <= "10";
        
        -- 2. Wait more than 10 clock cycles (using 12 cycles to give 1-2 extra cycles for state transition)
        wait for CLK_PERIOD * 12;

        -- 4. Verify display shows "GO" ("0000010" and "1000000")
        assert (s_HEX_1 = "0000010" and s_HEX_2 = "1000000")
            report "Scenario 1 Failed: Display did not show GO"
            severity error;

        -- 5. Car passes through gate 
        s_front_sensor <= '0'; -- Car leaves front sensor
        s_back_sensor  <= '1'; -- Car triggers back sensor
        wait for CLK_PERIOD * 2;

        -- 6. Verify: System returns to IDLE (Display OFF = "1111111", LEDs OFF = '0')
        assert (s_HEX_1 = "1111111" and s_HEX_2 = "1111111" and s_GREEN_LED = '0' and s_RED_LED = '0')
            report "Scenario 1 Failed: System did not return to IDLE"
            severity error;

        -- Reset sensors back to 0 
        s_back_sensor <= '0';
        wait for CLK_PERIOD * 2;

        -----------------------------------------------------------------------
        -- Scenario 2: Wrong Password
        -----------------------------------------------------------------------
       -- 1. Car arrives, input wrong password
        s_front_sensor <= '1';
        s_password_1   <= "00";
        s_password_2   <= "00";

 -- 2. Waiting time 
      wait for CLK_PERIOD * 12;

        
        -- 3. Verify display shows "EE" ("0000110" and "0000110")
        assert (s_HEX_1 = "0000110" and s_HEX_2 = "0000110")
            report "Scenario 2 Failed: Display did not show EE"
            severity error;

        -- 4. Input correct password 
        s_password_1   <= "01";
        s_password_2   <= "10";
        wait for CLK_PERIOD * 2;

        -- 5. Verify: System goes to RIGHT_PASSWORD (Display GO --> "0000010" and "1000000" )
        assert (s_HEX_1 = "0000010" and s_HEX_2 = "1000000")
            report "Scenario 2 Failed: System did NOT go to RIGHT_PASSWORD"
            severity error;

        -- Reset sensors back to 0 
        s_front_sensor <= '0' ;
        s_back_sensor <= '1';
        wait for CLK_PERIOD * 2;

        --wait for the car to pass
        s_back_sensor <= '0';
        wait for CLK_PERIOD * 2;

        -----------------------------------------------------------------------
        -- Scenario 3: Multiple Cars
        -----------------------------------------------------------------------
        -- 1. Car 1 passes and verify: System goes to RIGHT_PASSWORD 
        s_front_sensor <= '1';
        s_password_1   <= "01";
        s_password_2   <= "10";
       
       -- Waiting time 
      wait for CLK_PERIOD * 12;
         
        assert (s_HEX_1 = "0000010" and s_HEX_2 = "1000000")
            report "Scenario 3 Failed: System did NOT go to RIGHT_PASSWORD"
            severity error;

        -- 2. Before back_sensor = '1', assert front_sensor = '1' again
        s_front_sensor <= '1';
        s_back_sensor <= '1';
      wait for CLK_PERIOD * 2;

         -- 3. Verify: System goes to STOP (Display SP --> "0100100" and "0001100" )
        assert (s_HEX_1 = "0100100" and s_HEX_2 = "0001100")
            report "Scenario 3 Failed: System did NOT go to STOP"
            severity error;

        -- 4. Correct input for Car 2
         s_password_1   <= "01";
        s_password_2   <= "10";
        s_back_sensor <= '0';
         wait for CLK_PERIOD * 2;
        

        -- 5. Both car pass correctly --> System goes to RIGHT_PASSWORD
        assert (s_HEX_1 = "0000010" and s_HEX_2 = "1000000")
            report "Scenario 3 Failed: System did NOT go to RIGHT_PASSWORD"
            severity error;

        -----------------------------------------------------------------------
        -- Scenario 4: Reset
        -----------------------------------------------------------------------
        -- 1. System start from RIGHT_PASSWORD state (but could have been any state)
       assert (s_HEX_1 = "0000010" and s_HEX_2 = "1000000" and s_RED_LED = '0')
       report "Scenario 4 Failed: System did NOT go to RIGHT_PASSWORD"
            severity error;

        -- 2. assert reset = '0'
           s_reset_n <= '0';
            wait for CLK_PERIOD * 2;

         -- 3. Verify: System returns to IDLE 
        assert (s_HEX_1 = "1111111" and s_HEX_2 = "1111111" and s_GREEN_LED = '0' and s_RED_LED = '0')
            report "Scenario 4 Failed: System did not return to IDLE"
            severity error;


        report "=== Simulation Completed ===";
        wait;
    end process;

    end architecture test;

library IEEE;
use IEEE.std_logic_1164.all;
-- use ieee.std_logic_unsigned.all;
-- use ieee.std_logic_arith.all;

use WORK.modules.all;

entity i2c_tb is
end i2c_tb;

architecture behav of i2c_tb is

   signal clock : std_logic := '0';
   constant clk_in_period : time := 20 ns; -- 50MHz

   signal stop : std_logic := '0';
   signal read_write : std_logic := '0';
   signal start_conversion : std_logic := '0';
   signal scl : std_logic;
   signal sda : std_logic;
   signal error_code : std_logic_vector(2 downto 0);

begin

   x1 : i2c 
   	generic map (
		   device_address => "0101010"
		) 
	port map(
		   double_clock_in => clock,
		   word_address => "01010101",
                   data => "00110011",
		   serial_clock => scl,
		   serial_data => sda,
		   read_write => read_write,
		   start_conversion => start_conversion,
		   error_code => error_code
		);

   stm : process 
   begin
      wait for clk_in_period * 200;
      stop <= '1';
      wait;
   end process;

   -- Clock process definitions
   clk : process
   begin
      clock <= '0';
      wait for clk_in_period/2;
      clock <= '1';
      wait for clk_in_period/2;
      if stop = '1' then
	 wait;
      end if;
   end process;

   process
   begin
      sda <= 'Z';
      wait for 80 ns;
      start_conversion <= '1';
      wait for 30 ns;
      start_conversion <= '0';

      wait for 340 ns;
      sda <= '0';
      wait for 20 ns;
      sda <= 'Z';

      wait for 340 ns;
      sda <= '0';
      wait for 20 ns;
      sda <= 'Z';

      wait for 340 ns;
      sda <= '0';
      wait for 20 ns;
      sda <= 'Z';

      wait;
   end process;

end behav;

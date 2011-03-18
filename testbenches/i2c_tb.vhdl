library IEEE;
use IEEE.std_logic_1164.all;
-- use ieee.std_logic_unsigned.all;
-- use ieee.std_logic_arith.all;

USE ieee.std_logic_unsigned.ALL;

use WORK.modules.all;

entity i2c_tb is
end i2c_tb;

architecture behav of i2c_tb is

   signal clock : std_logic := '0';
   constant clk_in_period : time := 20 ns; -- 50MHz

   signal stop : std_logic := '0';
   signal op : std_logic_vector(1 downto 0);
   signal start_conversion : std_logic := '0';
   signal scl : std_logic;
   signal sda : std_logic := 'Z';
   signal error_code : std_logic_vector(2 downto 0);
   signal data_read : std_logic_vector(7 downto 0);

   signal word_address : std_logic_vector(7 downto 0);
   signal data_write : std_logic_vector(7 downto 0);

   signal dato_chiesto : std_logic_vector(7 downto 0);

   signal toggle_start : std_logic := '0';
   signal toggle_stop : std_logic := '0';

   signal is_running: std_logic;
begin

   x1 : i2c 
   	generic map (
		   device_address => "1100001" -- "0101010"
		) 
	port map(
	           reset => '0',
		   double_clock_in => clock,
		   word_address => word_address,
                   data_write => data_write,
                   data_read => data_read,
		   serial_clock => scl,
		   serial_data => sda,
		   op => op,
		   start_conversion => start_conversion,
                   is_running => is_running,
		   error_code => error_code
		);

   y1 : i2c_slave
	port map(
		   scl => scl,
		   sda => sda
		);

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
      variable dato : std_logic_vector(7 downto 0);
   begin
      start_conversion <= '0';

--      ----------------------------------- FACCIO UNA SCRITTUTA di c6 in 59
--      data_write <= x"C6";
--      word_address <= x"59";
--      op <= "00"; -- write mode
--
--      -- INVIO START_CONVERSION
--      wait for 80 ns;
--      start_conversion <= '1';
--      wait on clock;
--      wait on clock;
--      start_conversion <= '0';
--
--      -- WAIT END OF SERIALIZATION
--      wait until is_running = '0';
--
--      assert false report "errore=" & integer'image(conv_integer(error_code)) severity note;
--
--      wait for 1 us;

      ----------------------------------- FACCIO Current Address Read
      -- Current Address READ: START/DEVICEADDRESS/READ/READDATA/STOP
      op <= "10"; -- current address read mode

      -- INVIO START_CONVERSION
      wait on clock;
      wait on clock;
      wait on clock;
      start_conversion <= '1';
      wait on clock;
      wait on clock;
      wait on clock;
      start_conversion <= '0';

      -- WAIT END OF SERIALIZATION
      wait until is_running = '0';

      -- STAMPO DATO SCRITTO DAME / LETTO DA DRIVER I2C
      assert false report "data read = " & integer'image(conv_integer(data_read))  severity note;
      assert false report "error = " & integer'image(conv_integer(error_code))  severity note;

      --------------------------------------------------------------------
      stop <= '1';
      wait;
   end process;

end behav;

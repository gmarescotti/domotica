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

   signal toggle_start : std_logic := '0';
   signal toggle_stop : std_logic := '0';

   signal is_running: std_logic;

   signal dato_chiesto : std_logic_vector(7 downto 0);
   signal device_address_back : std_logic_vector(7 downto 0);
   signal word_address_back : std_logic_vector(7 downto 0);
   signal data_write_back : std_logic_vector(7 downto 0);

   signal DEVICE_ADDRESS : std_logic_vector(6 downto 0) := "1100001";
begin

   x1 : i2c 
   	generic map (
		   device_address => DEVICE_ADDRESS
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
		   sda => sda,
		   dato_chiesto => dato_chiesto,
                   device_address_back => device_address_back,
                   word_address_back => word_address_back,
                   data_write_back => data_write_back
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

      -------------------------------------------------------------------
      -- BYTE WRITE: START/DEVICEADDRESS/WRITE/WORDADDRESS/DATA/STOP
      mylog("BYTE WRITE: START/DEVICEADDRESS/WRITE/WORDADDRESS/DATA/STOP");

      op <= "00"; -- write mode
      data_write <= x"C6";
      word_address <= x"59";

      -- INVIO START_CONVERSION
      wait for 80 ns;
      start_conversion <= not start_conversion;
      wait until is_running = '0';

      mylog("DEVICE ADDRESS=", DEVICE_ADDRESS);
      mylog("device_address_back=", device_address_back);

      mylog("word_address=", word_address);
      mylog("word_address_back=", word_address_back);

      mylog("data_write=", data_write);
      mylog("data_write_back=", data_write_back);

      mylog("ERRORE=", error_code);

      --------------------------------------------------------------------
      -- CURRENT ADDRESS READ: START/DEVICEADDRESS/READ/READDATA/STOP
      mylog("CURRENT ADDRESS READ: START/DEVICEADDRESS/READ/READDATA/STOP");

      op <= "10"; -- current address read mode
      dato_chiesto <= x"94";

      -- INVIO START_CONVERSION
      wait for 80 ns;
      start_conversion <= not start_conversion;
      wait until is_running = '0';

      mylog("DEVICE ADDRESS=", DEVICE_ADDRESS);
      mylog("device_address_back=", device_address_back);

      mylog("DATO CHIESTO=", dato_chiesto);
      mylog("DATA READ=", data_read);

      mylog("ERROR=", error_code);

      --------------------------------------------------------------------
      -- RANDOM READ: START/DEVICEADDRESS/WRITE/WORDADDRESS/START/DEVICEADDRESS/READ/READDATA/STOP
      --------------------------------------------------------------------
      mylog("RANDOM READ: START/DEVICEADDRESS/WRITE/WORDADDRESS/START/DEVICEADDRESS/READ/READDATA/STOP");

      op <= "01"; -- random read mode
      dato_chiesto <= x"38";
      word_address <= x"59";

      -- INVIO START_CONVERSION
      wait for 80 ns;
      start_conversion <= not start_conversion;
      wait until is_running = '0';

      mylog("DEVICE ADDRESS=", DEVICE_ADDRESS);
      mylog("device_address_back=", device_address_back);

      mylog("word_address=", word_address);
      mylog("word_address_back=", word_address_back);

      mylog("DATO CHIESTO=", dato_chiesto);
      mylog("DATA READ=", data_read);

      mylog("ERROR=", error_code);

      --------------------------------------------------------------------
      stop <= '1';
      wait;
   end process;

end behav;

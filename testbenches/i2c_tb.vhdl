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
   signal read_write : std_logic;
   signal start_conversion : std_logic := '0';
   signal scl : std_logic;
   signal sda : std_logic;
   signal error_code : std_logic_vector(2 downto 0);
   signal data_read : std_logic_vector(7 downto 0);

   signal word_address : std_logic_vector(7 downto 0);
   signal data_write : std_logic_vector(7 downto 0);

   signal toggle_start : std_logic := '0';
   signal toggle_stop : std_logic := '0';
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
		   read_write => read_write,
		   start_conversion => start_conversion,
		   error_code => error_code
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

   -- START CONDITION
   process(scl,sda)
   begin
      if falling_edge(sda) then
	 if scl = '1' then
	    toggle_start <= not toggle_start;
	 end if;
      end if;
   end process;
   -- STOP CONDITION
   process(scl,sda)
   begin
      if rising_edge(sda) then
	 if scl = '1' then
	    toggle_stop <= not toggle_stop;
	 end if;
      end if;
   end process;

   process
      variable dato : std_logic_vector(7 downto 0);
   begin
      sda <= 'Z';

      ----------------------------------- FACCIO UNA SCRITTUTA di c6 in 59
--       data_write <= x"C6";
--       word_address <= x"59";
--       read_write <= '0'; -- write mode
-- 
--       -- INVIO START_CONVERSION
--       wait for 80 ns;
--       start_conversion <= '1';
--       wait until falling_edge(sda);
--       start_conversion <= '0';
-- 
--       for j in 0 to 2 loop -- TRE BYTE: DEVICE, WORDADDRESS, WRITEBYTE
--          -- ASPETTO 8 COLPI DI CLOCK e 1/2
-- 	 for i in 0 to 7 loop
-- 	    wait until rising_edge(scl);
-- 	    wait until falling_edge(scl);
-- 	 end loop;
-- 	 wait until rising_edge(scl);
-- 
--          -- ABBASSO SDA PER 1 CLOCK PER DARE ACK A MASTER
-- 	 sda <= '0';
-- 	 wait until falling_edge(scl);
-- 	 sda <= 'Z';
--       end loop;
-- 
--       wait for 1 us;

      ----------------------------------- FACCIO UNA LETTURA da 72
      -- RANDOM READ: START/DEVICEADDRESS/WRITE/WORDADDRESS/START/DEVICEADDRESS/READ/READDATA/STOP
      word_address <= x"72";
      read_write <= '1'; -- read mode

      -- INVIO START_CONVERSION
      wait for 80 ns;
      start_conversion <= '1';

      -- WAIT START
      wait on toggle_start;
      start_conversion <= '0';

      -- LEGGO DUE BYTE: DEVICE, WORDADDRESS
      for j in 0 to 1 loop
         -- ASPETTO 8 COLPI DI CLOCK e 1/2
	 for i in 7 downto 0 loop
	    wait until rising_edge(scl);
	    dato(i) := sda;
	    wait until falling_edge(scl);
	 end loop;
	 wait until rising_edge(scl);

         -- ABBASSO SDA PER 1 CLOCK PER DARE ACK A MASTER
	 sda <= '0';
	 wait until falling_edge(scl);
	 sda <= 'Z';

	 assert false report "data=" & integer'image(conv_integer(dato)) severity note;
      end loop;

      -- ASPETTO START: FRONTE DISCESA DATO DURANTE HIGH DI CLOCK
      wait on toggle_start;

      -- LEGGO 8 BIT: DEVICE ADDRESS
      for i in 7 downto 0 loop
	 wait until rising_edge(scl);
	 dato(i) := sda;
	 wait until falling_edge(scl);
      end loop;
      assert false report "data=" & integer'image(conv_integer(dato)) severity note;

      -- ASPETTO STOP
      wait on toggle_stop for 1 ms;

      -- STAMPO DATO SCRITTO DAME / LETTO DA DRIVER I2C
      -- assert false report "data read = " & integer'image(conv_integer(data_read))  severity note;

      --------------------------------------------------------------
      stop <= '1';
      wait;
   end process;

end behav;

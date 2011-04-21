library IEEE;
use IEEE.std_logic_1164.all;

USE WORK.modules.all;

--- DEBUG PURPOSES
USE ieee.std_logic_unsigned.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use std.textio.all;

entity mdio_tb is
end mdio_tb;

architecture behav of mdio_tb is

   signal clock : std_logic := '0';
   signal clock_out : std_logic;
   constant clk_in_period : time := 20 ns; -- 50MHz

   signal opcode : std_logic_vector(1 downto 0);
   signal start_conversion : std_logic := '0';
   signal running_conversion : std_logic;
   signal sda : std_logic;
   signal data_read : std_logic_vector(15 downto 0);
   signal data_write : std_logic_vector(15 downto 0);

   signal reset : std_logic := '0';
   signal error_code : std_logic_vector(2 downto 0);

   signal stop : std_logic := '0';

   -- TESTER_MDIO
   signal data_write_back : std_logic_vector(15 downto 0);
   signal data_read_back  : std_logic_vector(15 downto 0);
   signal error_code_slave : std_logic_vector(2 downto 0);
   signal opcode_slave : std_logic_vector(1 downto 0);
   signal addr    : std_logic_vector(4 downto 0);
   signal devaddr : std_logic_vector(4 downto 0);
   signal hexint  : std_logic_vector(3 downto 0);

begin

   x1 : mdio 
        generic map (
		mdio_address   => "11001", -- 0x1F
	        device_address => "11110"  -- 0x1E
     	   )
        port map (
                reset => reset,

		clk_in => clock,

		serial_clock => clock_out,
	        serial_data  => sda,

		opcode  => opcode, -- 00: Address 10: Read-Inc 01: Write

		data_read    => data_read,
		data_write   => data_write,

		start_conversion => start_conversion,
		running_conversion => running_conversion,
		error_code => error_code,
		hexint => hexint
	     );

   t1 : mdio_slave
      port map (
              reset => reset,

	      clk_in => clock,

	      serial_clock => clock_out,
	      serial_data  => sda,

	      data_read_back  => data_read_back,  -- da leggere
	      data_write_back => data_write_back, -- da scrivere

	      error_code => error_code_slave,

	      opcode  => opcode_slave,
              addr    => addr,
              devaddr => devaddr
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

   --------------------------------------------------------------
   invia_dati : process
      variable line_out: Line; -- Line buffers
   begin
      wait for 80 ns;

      ------------------------------------------------------------
      opcode <= "10"; -- READ INC
      data_write_back <= X"DCBA"; -- Quello che mdio_slave risponde a mdio read
      start_conversion <= not start_conversion;
      wait until running_conversion = '0';

      mylog("data_write_back=", data_write_back);
      mylog("data_read=", data_read);
      mylog("error=", error_code);
      mylog("errorslave=", error_code_slave);

      ------------------------------------------------------------
      opcode <= "00"; -- ADDRESS
      data_write <= X"1234";
      start_conversion <= not start_conversion;
      wait until running_conversion = '0';

      mylog("data_write=", data_write);
      mylog("data_read_back=", data_read_back);
      mylog("error=", error_code);
      mylog("errorslave=", error_code_slave);

      ------------------------------------------------------------
      opcode <= "01"; -- WRITE DATA
      data_write <= X"5678";
      start_conversion <= not start_conversion;
      wait until running_conversion = '0';

      mylog("data_write=", data_write);
      mylog("data_read_back=", data_read_back);
      mylog("error=", error_code);
      mylog("errorslave=", error_code_slave);

      --------------------------------------------------------------
      stop <= '1';
      wait;

   end process;

end behav;

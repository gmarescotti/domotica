library IEEE;
use IEEE.std_logic_1164.all;

USE WORK.modules.all;

entity mdio_tb is
end mdio_tb;

architecture behav of mdio_tb is

   signal clock : std_logic := '0';
   constant clk_in_period : time := 20 ns; -- 50MHz

   signal opcode : std_logic_vector(1 downto 0);
   signal start_conversion : std_logic := '0';
   signal running_conversion : std_logic;
   signal sda : std_logic;
   signal data_read : std_logic_vector(15 downto 0);
   signal data_write : std_logic_vector(15 downto 0);

   -- TESTER_MDIO
   signal data_write_back : std_logic_vector(15 downto 0) := X"DCBA";
   signal data_read_back  : std_logic_vector(31 downto 0);
   signal dato_ricevuto : std_logic;

   signal reset : std_logic := '0';

begin

   x1 : mdio 
        generic map (
		mdio_address   => "11001", -- 0x1F
	        device_address => "11110"  -- 0x1E
     	   )
        port map (
                reset => reset,
		serial_clock => clock,
	        serial_data  => sda,
		opcode  => opcode, -- 00: Address 10: Read-Inc 01: Write
		data_read    => data_read,
		data_write   => data_write,
		start_conversion => start_conversion,
		running_conversion => running_conversion
	     );

   t1 : mdio_slave
      port map (
              reset => reset,
	      serial_clock => clock,
	      serial_data  => sda,

	      data_read_back  => data_read_back,
	      data_write_back => data_write_back,

	      dato_ricevuto   => dato_ricevuto
   	);

   -- Clock process definitions
   clk : process
   begin
      clock <= '0';
      wait for clk_in_period/2;
      clock <= '1';
      wait for clk_in_period/2;
   end process;

   invia_dati : process
   begin
      wait for 80 ns;
      opcode <= "10"; -- READ
      -- data <= "0101010101010101";
      -- data <= "ZZZZZZZZZZZZZZZZ";
      start_conversion <= not start_conversion;
      wait for 30 ns;

      wait on running_conversion;

      wait for 180 ns;
      opcode <= "00"; -- ADDRESS
      data_write <= X"1234";
      start_conversion <= not start_conversion;
      wait for 30 ns;

      wait on running_conversion;

      wait for 180 ns;
      opcode <= "01"; -- WRITE DATA
      data_write <= X"5678";
      start_conversion <= not start_conversion;
      wait for 30 ns;

      wait on running_conversion;

      wait;

   end process;

   ricevi_dati : process (dato_ricevuto)
   begin
   end process;

end behav;

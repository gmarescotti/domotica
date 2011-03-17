library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mdio_slave is
   port (
	   reset 	   : in std_logic;
	   serial_clock    : in std_logic; -- deve essere < 2.5 MHz!
	   serial_data     : inout std_logic;

	   data_read_back  : out std_logic_vector(15 downto 0) := (OTHERS => 'Z');
	   data_write_back : in std_logic_vector(15 downto 0);

	   error_code 	   : out std_logic_vector(2 downto 0);

	   opcode : buffer std_logic_vector(1 downto 0);
           addr    : out std_logic_vector(4 downto 0);
           devaddr : out std_logic_vector(4 downto 0)
   );
end mdio_slave;

architecture Behavioral of mdio_slave is

   type tipo_stato is ( aspetta_preamble, aspetta_zero, aspetta_start, aspetta_code, addresses, turn_around_read, turn_around_write, scrivi_dato_back, leggi_dato );
   signal alladdresses : std_logic_vector(9 downto 0);

begin

   addr <= alladdresses(4 downto 0);
   devaddr <= alladdresses(9 downto 5);

   process(serial_clock, reset)

      variable stato   : tipo_stato := aspetta_preamble;
      variable counter : natural := 31;

   begin

      if reset = '1' then
	 stato := aspetta_preamble;
	 counter := 31;
	 serial_data <= 'Z';
	 error_code <= "000";

      elsif rising_edge(serial_clock) then

	 serial_data <= 'Z';

	 case stato is
	    when aspetta_preamble =>

	       if serial_data = '0' then
		  counter := 31;
	       else 

		  if counter > 0 then
		     counter := counter - 1;
		  else
		     stato := aspetta_zero;
		  end if;
	       end if;

	    when aspetta_zero =>
	       if serial_data = '0' then
		  stato := aspetta_start;
		  error_code <= "000";
	       end if;

	    when aspetta_start =>

	       if serial_data = '1' then
		  stato := aspetta_preamble;
		  counter := 31;
		  error_code <= "001";
	       else
		  stato := aspetta_code;
		  counter := 1;
	       end if;

	    when aspetta_code =>

	       opcode(counter) <= serial_data;

	       if counter > 0 then
		  counter := counter - 1;
	       else
		  stato := addresses;
		  counter := 9; -- ADDRS (5) + DEVADDR (5)
	       end if;

	    when addresses =>

	       alladdresses(counter) <= serial_data;

	       if counter > 0 then
		  counter := counter - 1;
	       else
		  if opcode(1) = '1' then -- READ
		     stato := turn_around_write;
		  else
		     stato := turn_around_read;
		  end if;
		  counter := 1;
	       end if;

	    when turn_around_read =>

	       if counter > 0 then
		  counter := counter - 1;
	       else
		  stato := leggi_dato;
		  counter := 15;
	       end if;

	    when turn_around_write =>

	       serial_data <= '0';

	       stato := scrivi_dato_back;
	       counter := 15;

	    when leggi_dato =>

	       data_read_back(counter) <= serial_data;

	       if counter > 0 then
		  counter := counter - 1;
	       else
		  stato := aspetta_preamble;
		  counter := 31;
	       end if;

	    when scrivi_dato_back =>

	       serial_data <= data_write_back (counter);

	       if counter > 0 then
		  counter := counter - 1;
	       else
		  stato := aspetta_preamble;
		  counter := 31;
	       end if;
	 end case;

      end if;
   end process;


end Behavioral;


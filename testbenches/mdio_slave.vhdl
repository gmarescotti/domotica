----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:57:15 11/17/2010 
-- Design Name: 
-- Module Name:    mdio_slave - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use IEEE.STD_LOGIC_ARITH.ALL;
-- use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mdio_slave is
   port (
           reset 	   : in std_logic;
	   serial_clock    : in std_logic; -- deve essere < 2.5 MHz!
	   serial_data     : inout std_logic;

	   data_read_back  : out std_logic_vector(31 downto 0) := "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
	   data_write_back : in std_logic_vector(15 downto 0);

           dato_ricevuto : out std_logic
   );
end mdio_slave;

architecture Behavioral of mdio_slave is

   type tipo_stato is ( aspetta_preamble, aspetta_zero, aspetta_start,
aspetta_code, addresses, turn_around_read, turn_around_write, scrivi_dato_back, leggi_dato );
   signal code : std_logic_vector(1 downto 0);
   signal dato_ricevuto_loc : std_logic := '0';

begin
   dato_ricevuto <= dato_ricevuto_loc;

   process(serial_clock, reset)

      variable stato   : tipo_stato := aspetta_preamble;
      variable counter : natural := 31;
      variable counter_tot: integer range -1 to 31 := -1;

   begin

      if reset = '1' then
	 stato := aspetta_preamble;
	 counter := 31;
	 counter_tot := -1;
	 serial_data <= 'Z';
      else
	 if rising_edge(serial_clock) then

	    serial_data <= 'Z';

	    case stato is
	       when aspetta_preamble =>

		  counter_tot := -1;

		  if serial_data = '0' then
		     counter := 31;
		     dato_ricevuto_loc <= not dato_ricevuto_loc;
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
		     counter_tot := 31;
		  end if;

	       when aspetta_start =>

		  if serial_data = '1' then
		     data_read_back <= X"EEEEEEE2";
		     dato_ricevuto_loc <= not dato_ricevuto_loc;
		     stato := aspetta_preamble;
		  else
		     stato := aspetta_code;
		     counter := 1;
		  end if;

	       when aspetta_code =>

		  code(counter) <= serial_data;

		  if counter > 0 then
		     counter := counter - 1;
		  else
		     stato := addresses;
		     counter := 9; -- ADDRS (5) + DEVADDR (5)
		  end if;

	       when addresses =>

		  if counter > 0 then
		     counter := counter - 1;
		  else
		     if code(1) = '1' then -- READ
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

		  data_read_back(counter_tot) <= '0';
		  counter_tot := counter_tot - 1;

		  stato := scrivi_dato_back;
		  counter := 15;

	       when leggi_dato =>

		  if counter > 0 then
		     counter := counter - 1;
		  else
		     stato := aspetta_preamble;
		     dato_ricevuto_loc <= not dato_ricevuto_loc;
		     counter := 31;
		  end if;

	       when scrivi_dato_back =>

		  serial_data <= data_write_back (counter);

		  if counter > 0 then
		     counter := counter - 1;
		  else
		     stato := aspetta_preamble;
		     dato_ricevuto_loc <= not dato_ricevuto_loc;
		     counter := 31;
		  end if;
	    end case;

	    if counter_tot >= 0 then

	       data_read_back(counter_tot) <= serial_data;

	       counter_tot := counter_tot - 1;
	    end if;

	 end if;
      end if;
   end process;


end Behavioral;


-- Within the bus specifications a regular mode (100 kHz clock rate) and a fast mode (400
-- kHz clock rate) are defined. The DDTC works in both modes.
-- read_write: when set to a 1 a read operation is selected, and when set to a 0 a write operation is selected.

library IEEE;
use IEEE.std_logic_1164.all;

entity i2c is
   generic (
	   device_address  : std_logic_vector(6 downto 0)
	   );
   port (
           reset 	   : in std_logic;
	   double_clock_in : in std_logic;
	   word_address    : in std_logic_vector(7 downto 0);
	   data_read       : out std_logic_vector(7 downto 0);
	   data_write      : in std_logic_vector(7 downto 0);
           read_write      : in std_logic;

	   serial_clock    : out std_logic := '1';
	   serial_data     : inout std_logic := 'Z';

	   start_conversion : in std_logic;
           error_code 	    : out std_logic_vector(2 downto 0)
	);
end entity i2c;

architecture rtl of i2c is

   signal serial_clock_out : std_logic := 'Z';
   signal is_running : std_logic := '0';
begin

   process(double_clock_in, reset)
   begin
      if falling_edge(double_clock_in) then
	 serial_clock <= serial_clock_out or not is_running;
      end if;
   end process;

   process(double_clock_in, reset)

      type tipo_stato is ( wait_start, start, stop, address8, wait_ack, verify_ack, device7, command, data8, read8, wait_only );
      variable stato       : tipo_stato := wait_start;

      variable stato_mem   : tipo_stato := wait_start;
      variable x : std_logic := '0';
      variable bit_counter : natural range 0 to 7 := 0;

   begin
      --
      if reset = '1' then
	 stato := wait_start;
 	 error_code <= "000";
	 
      elsif rising_edge(double_clock_in) then

	 -- assert false report std_logic'image(x) & "," & tipo_stato'image(stato) severity note;

	 if x = '1' then -- LEGGO SERIAL_DATA
	    x := '0';
	    serial_clock_out <= '0';

	    case stato is

	       when start =>

		  if serial_data = '1' then
		     serial_data <= '0';
		     stato := device7;
		     bit_counter := 6;
		     error_code <= "000";
		     is_running <= '1';
		  end if;

	       when stop =>

		  if serial_data = '0' then
		     serial_data <= '1';
		     stato := wait_start;
		     is_running <= '0';
	          end if;

	       when verify_ack =>
		  if serial_data /= '0' then
		     stato := stop;
		     assert false report "NOT ACKNOWLEDGE!" severity note;
		     error_code <= "001";
		     stato := wait_start;
		  else
		     stato := stato_mem;
		  end if;

	       when read8 =>
		  data_read(bit_counter) <= serial_data;

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato_mem := stop; -- ONLY READ 1 BYTE AND STOP (Random Read end)
		     stato := wait_only;

		  end if;

	       when others =>
	          --
	    end case;

	 else -- .. SCRIVO SERIAL_DATA
	    x := '1';
	    serial_clock_out <= '1';

	    case stato is

	       when wait_only =>
		  stato := stato_mem;

	       when wait_start =>

		  if start_conversion = '1' then
		     stato := start;
		     serial_data <= '1';
		  else
		     serial_data <= 'Z';
		     is_running <= '0';
		  end if;

	       when device7 =>

		  serial_data <= device_address(bit_counter);

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato := command;
		  end if;

	       when command =>

		  -- serial_data <= read_write; -- SOLO PER SEQUENTIAL READ!
		  if stato_mem = start then -- STO FACENDO Random Read
		     serial_data <= '1'; -- READ MODE
		     stato_mem := read8;
		  else
		     serial_data <= '0';
		     stato_mem := address8;
		  end if;

		  bit_counter := 7;
		  stato := wait_ack;

	       when wait_ack =>
		  serial_data <= 'Z';
		  stato := verify_ack;

	       when address8 =>
		  --
		  serial_data <= word_address(bit_counter);

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
                     if read_write = '1' then -- Random Read (half)
                        stato_mem := start; -- START A Current Address Read
                     else
		        stato_mem := data8;
                     end if;
		     bit_counter := 7;
		     stato := wait_ack;

		  end if;

	       when data8 =>
		  
		  serial_data <= data_write(bit_counter);

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato_mem := stop;
		     bit_counter := 0;
		     stato := wait_ack;
		  end if;

	       when stop =>
		  serial_data <= '0';

	       when start =>
		  serial_data <= '1';

	       when others =>
	          --

	    end case;
	 end if; -- x=0
      end if; -- if reset = '1'
   end process;

end rtl;

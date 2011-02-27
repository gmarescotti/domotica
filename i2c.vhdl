library IEEE;
use IEEE.std_logic_1164.all;

-- use ieee.std_logic_arith.all; 
-- use ieee.std_logic_unsigned.all; 
-- use ieee.numeric_std.all;

entity i2c is
   generic (
	   device_address  : std_logic_vector(6 downto 0)
	   );
   port (
           reset 	   : in std_logic;
	   double_clock_in : in std_logic;
	   word_address    : in std_logic_vector(7 downto 0);
	   data            : in std_logic_vector(7 downto 0);
           read_write      : in std_logic;

	   serial_clock : out std_logic := '0';
	   serial_data  : inout std_logic := 'Z';

      start_conversion : in std_logic
	);
end entity i2c;

architecture rtl of i2c is

   type tipo_stato is ( wait_start, start, stop, address8, wait_ack, verify_ack, device7, command, data8 );
   signal stato       : tipo_stato := wait_start;

   signal bit_counter 		: natural range 0 to 7 := 0;
   signal serial_clock_loc 	: std_logic;
   signal error_code 		: std_logic_vector(2 downto 0);

begin

   serial_clock <= serial_clock_loc;
	
   process(double_clock_in, reset)
	   variable stato_mem   : tipo_stato := wait_start;

   begin
      --
      if reset = '1' then
         stato <= wait_start;
      else 

	 if double_clock_in = '1' then
	    serial_clock_loc <= not serial_clock_loc;
	 else

	    if serial_clock_loc = '1' then

	       case stato is

	          when start =>
	          --
	     	if serial_data = '1' then
	     	   serial_data <= '0';
	     	   stato <= device7;
	     	   bit_counter <= 6;
	     	   error_code <= "000";
	     	end if;

	          when stop =>
	          --
	     	if serial_data = '0' then
	     	   serial_data <= '1';
	     	   stato <= wait_start;
	     	end if;

	          when verify_ack =>
	     	if serial_data /= '0' then
	     	-- assert (serial_data = 'Z')
	     	-- report "Debug Message"
	     	-- severity note;
	     	-- TEST ERROR
	     	--		     case stato_mem is
	     	--			when stop =>
	     	--			   error_code <= "001";
	     	--			when data8 =>
	     	--			   error_code <= "010";
	     	--			when address8=>
	     	--			   error_code <= "011";
	     	--			when others =>
	     	--			   error_code <= "111";
	     	--		     end case;

	     	   stato <= stop;
	     	else
	     	   stato <= stato_mem;
	     	end if;

	          when others =>
	    --

	       end case;

	    else

	       case stato is

	          when wait_start =>

	     	if start_conversion = '1' then
	     	   stato <= start;
	     	   serial_data <= '1';
	          -- serial_clock_loc <= '0';
	     	else
	     	   serial_data <= 'Z';
	     	end if;

	          when device7 =>
	          --
	     	serial_data <= device_address(bit_counter);

	     	if bit_counter > 0 then
	     	   bit_counter <= bit_counter - 1;
	     	else
	     	   stato <= command;
	     	end if;

	          when command =>
	          --
	     	serial_data <= read_write;

	     	stato_mem := address8;
	     	bit_counter <= 7;
	     	stato <= wait_ack;

	          when wait_ack =>
	     	serial_data <= 'Z';
	     	stato <= verify_ack;

	          when address8 =>
	          --
	     	serial_data <= word_address(bit_counter);

	     	if bit_counter > 0 then
	     	   bit_counter <= bit_counter - 1;
	     	else
	     	   stato_mem := data8;
	     	   bit_counter <= 7;
	     	   stato <= wait_ack;

	     	end if;

	          when data8 =>
	          --
	     	serial_data <= data(bit_counter);

	     	if bit_counter > 0 then
	     	   bit_counter <= bit_counter - 1;
	     	else
	     	   stato_mem := stop;
	     	   bit_counter <= 0;
	     	   stato <= wait_ack;
	     	end if;

	          when stop =>
	     	serial_data <= '0';

	          when start =>
	     	serial_data <= '1';

	          when others =>
	    -- stato <= wait_ack;

	       end case;
	    end if;
	 end if;
      end if;
   end process;

end rtl;

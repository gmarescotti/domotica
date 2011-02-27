-- The MDIO serial control interface allows communication be-
-- tween a station management controller and SCAN25100 de-
-- vices. MDIO and MDC pins are 3.3V LVTTL compliant, not
-- 1.2V compatiable. It is software compatible with the station
-- management bus defined in IEEE 802.3ae-2002. The serial
-- control interface consists of two pins, the data clock MDC and
-- bidirectional data MDIO. MDC has a maximum clock rate of
-- 2.5 MHz and no minimum limit. The MDIO is bidirectional and
-- can be shared by up to 32 physical devices.
-- The MDIO pin requires a pull-up resistor which, during IDLE
-- and turnaround, will pull MDIO high. The parallel equivalence
-- of the MDIO when shared with other devices should not be
-- less than 1.5 kΩ. Note that with many devices in parallel, the
-- internal pull-up resistors add in parallel. Signal quality on the
-- net should provide incident wave switching. It may be desir-
-- able to control the edge rate of MDC and MDIO from the
-- station management controller to optimize signal quality de-
-- pending upon the trace net and any resulting stub lengths.
-- In order to initialize the MDIO interface, the station manage-
-- ment sends a sequence of 32 contiguous logic ones on MDIO
-- with MDC clocking. This preamble may be generated either
-- by driving MDIO high for 32 consecutive MDC clock cycles,
-- or by simply allowing the MDIO pull-up resistor to pull the
-- MDIO high for 32 MDC clock cycles. A preamble is required
-- for every operation (64-bit frames, do not suppress preambles).
-- MDC is an a periodic signal. Its high or low duration is 160 ns
-- minimum and has no maximum limit. Its period is 400 ns min-
-- imum. MDC is not required to maintain a constant phase
-- relationship with TXCLK, SYSCLK, and REFCLK. The follow-
-- ing table shows the management frame structure in according
-- to IEEE 802.3ae.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.modules.all;

entity mdio is
   generic (
   	mdio_address    : std_logic_vector(4 downto 0);
   	device_address  : std_logic_vector(4 downto 0)
   );
   port (
        reset		: in std_logic;
        -- led		: buffer std_logic_vector(3 downto 0) := (OTHERS => '0');

	serial_clock    : in std_logic; -- deve essere < 2.5 MHz!
	serial_data     : inout std_logic;

	opcode  	: in std_logic_vector(1 downto 0);	-- 00: Address 10: Read-Inc 01: Write
	data_read       : out std_logic_vector(15 downto 0);
	data_write      : in std_logic_vector(15 downto 0);
	start_conversion : in std_logic;

	running_conversion  : out std_logic
   );
end entity mdio;

architecture rtl of mdio is

   type tipo_stato is ( WaitStart, Preamble, StartOpcode, MdioAddress, DeviceAddress, TurnAroundDataRead, TurnAroundDataWrite, DataRead, DataWrite );
   signal start_opcode : std_logic_vector(3 downto 0);
   signal start_conversion_loc : std_logic := '0';
   signal running_conversion_loc : std_logic := '0';

   signal stato       	: tipo_stato := WaitStart;

begin
   start_opcode <= "00" & opcode;
   running_conversion <= running_conversion_loc;
   -- led(0) <= running_conversion_loc;

--    with stato select led(3 downto 1) <=
-- 	"000" when WaitStart,
-- 	"001" when Preamble,
-- 	"010" when StartOpcode,
-- 	"011" when MdioAddress,
-- 	"100" when DeviceAddress,
-- 	"110" when DataWrite,
-- 	"111" when DataRead,
-- 	"101" when OTHERS;
	

   process(serial_clock, reset)
      variable bit_counter : natural range 0 to 31 := 0;
   begin
      
      if reset = '1' then
	 stato <= WaitStart;
	 bit_counter := 0;
	 start_conversion_loc <= '0';
	 running_conversion_loc <= '0';
	 data_read <= X"1020";
	 serial_data <= 'Z';
      else 

	 if serial_clock'event and serial_clock = '0' then

	    case stato is

	       when WaitStart =>
		  bit_counter := 31;
		  serial_data <= 'Z';

		  if start_conversion /= start_conversion_loc then
		     start_conversion_loc <= start_conversion;
		     stato <= Preamble;
		     running_conversion_loc <= '1';
		  -- data_read <= "ZZZZZZZZZZZZZZZZ";
		     data_read <= X"BBBB";
		  end if;

	       when Preamble =>
		  data_read <= X"2222";
		  serial_data <= '1';

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato <= StartOpcode;
		     bit_counter := 3;
		  end if;

	       when StartOpcode =>
		  data_read <= X"3333";
		  serial_data <= start_opcode(bit_counter);

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato <= MdioAddress;
		     bit_counter := 4;
		  end if;

	       when MdioAddress =>
		  data_read <= X"4444";
		  serial_data <= mdio_address(bit_counter);

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato <= DeviceAddress;
		     bit_counter := 4;
		  end if;

	       when DeviceAddress =>
		  data_read <= X"5555";
		  serial_data <= device_address(bit_counter);

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     if opcode(1) = '1' then
			stato <= TurnAroundDataRead;
		     else
			stato <= TurnAroundDataWrite;
		     end if;
		  end if;

	       when TurnAroundDataWrite =>
		  data_read <= X"6666";
		  if bit_counter = 0 then
		     serial_data <= '1';
		     bit_counter := 15;
		  else 
		     serial_data <= '0';
		     stato <= DataWrite;
		  end if;

	       when DataWrite =>
		  data_read <= X"7777";
		  serial_data <= data_write(bit_counter);

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato <= WaitStart;
		     running_conversion_loc <= '0';
		  end if;

	       when TurnAroundDataRead =>
		  data_read <= X"8888";
		  serial_data <= 'Z';
		  if bit_counter = 0 then
		     bit_counter := 15;	 
		  else
		     if serial_data = '0' then
			stato <= DataRead;
		     else
			data_read <= X"AAAA";
			stato <= WaitStart; -- ERRORE!

			running_conversion_loc <= '0';
		     end if;
		  end if;

	       when DataRead =>
	          data_read(bit_counter) <= serial_data;

		  if bit_counter > 0 then
		     bit_counter := bit_counter - 1;
		  else
		     stato <= WaitStart;
		     running_conversion_loc <= '0';
		  end if;
	       when others =>
		  data_read <= X"CCCC";
		  stato <= WaitStart;


	    end case;
	 end if;
      end if; -- if reset
   end process;

end rtl;


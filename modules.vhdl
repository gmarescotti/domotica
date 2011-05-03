library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
use ieee.numeric_bit.all;

--- DEBUG PURPOSES
USE ieee.std_logic_unsigned.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use std.textio.all;

package modules is

   constant clk_in_period : time := 20 ns; -- 50MHz   
   constant CR_CODE : std_logic_vector(7 downto 0) := x"0A";
   -- constant CR_CHAR : x"0a";

   type ram_rec is record
      ram_address : std_logic_vector(31 downto 2);
      ram_ce1_n   : std_logic;
      ram_ub1_n   : std_logic;
      ram_lb1_n   : std_logic;
      ram_ce2_n   : std_logic;
      ram_ub2_n   : std_logic;
      ram_lb2_n   : std_logic;
      ram_we_n    : std_logic;
      ram_oe_n    : std_logic;
   end record;

   type hexint_digit is array (3 downto 0) of std_logic_vector(3 downto 0);

   component mdio is
      generic (
      	 mdio_address    : std_logic_vector(4 downto 0);
      	 device_address  : std_logic_vector(4 downto 0)
      );
      port (
         reset		 : in std_logic;
         -- led		 : buffer std_logic_vector(3 downto 0);

 	 clk_in 	 : in std_logic; -- deve essere < 2.5 MHz!

   	 serial_clock    : buffer std_logic; -- deve essere < 2.5 MHz!
   	 serial_data     : inout std_logic;
   
   	 opcode  	 : in std_logic_vector(1 downto 0);	-- 00: Address 10: Read-Inc 01: Write
   	 data_read       : out std_logic_vector(15 downto 0);
   	 data_write      : in std_logic_vector(15 downto 0);
   	 start_conversion: in std_logic;

   	 running_conversion  : out std_logic;
	 error_code          : out std_logic_vector(2 downto 0);
	 hexint	  	     : buffer std_logic_vector(3 downto 0)
      );
   end component;

   component mdio_slave is
      port (
         reset		 : in std_logic;
	 clk_in          : in std_logic;

	 serial_clock    : in std_logic; -- deve essere < 2.5 MHz!
	 serial_data     : inout std_logic;

         data_read_back  : buffer std_logic_vector(15 downto 0); -- out
	 data_write_back : in std_logic_vector(15 downto 0);  -- in

	 error_code 	 : out std_logic_vector(2 downto 0);

	 opcode  : buffer std_logic_vector(1 downto 0);
         addr    : out std_logic_vector(4 downto 0);
         devaddr : out std_logic_vector(4 downto 0)
      );
   end component;

   component i2c is
      generic (
	 device_address  : std_logic_vector(6 downto 0)
	   );
      port (
         reset		 : in std_logic;
	 double_clock_in : in std_logic;
	 word_address    : in std_logic_vector(7 downto 0);
	 data_read       : out std_logic_vector(7 downto 0);
	 data_write      : in std_logic_vector(7 downto 0);
         op      	 : in std_logic_vector(1 downto 0);
         -- 00: Byte Write: Start/Device address/Word Address/Data/Stop
         -- 01: Random Read: Start/Device address/Word Address/Start/Device Address/Read Data
         -- 10: Current Address Read
	 serial_clock    : out std_logic := '0';
	 serial_data     : inout std_logic := 'Z';
         start_conversion: in std_logic;
         is_running      : buffer std_logic;
         error_code 	 : out std_logic_vector(2 downto 0);
         hexint		 : out std_logic_vector(3 downto 0)
	);
   end component;

   component i2c_slave is
      port (
	 scl : in std_logic;
	 sda : inout std_logic;
         dato_chiesto : in std_logic_vector(7 downto 0);
         device_address_back : buffer std_logic_vector(7 downto 0);
         word_address_back : buffer std_logic_vector(7 downto 0); -- era out
         data_write_back : out std_logic_vector(7 downto 0)
      );
   end component;

   -- component plasma_if is
   --    port(clk_in      : in std_logic;
   --       reset       : in std_logic;
   --       uart_read   : in std_logic;
   --       uart_write  : out std_logic;
   -- 
   --       ram	     : out ram_rec;
   --       ram_data    : inout std_logic_vector(31 downto 0);
   --        
   --       gpio0_out   : out std_logic_vector(31 downto 0);
   --       gpioA_in    : in std_logic_vector(31 downto 0)
   --    );
   -- end component;

   component myclocks is
      port(
         reset		 : in std_logic;
	 -- SERDES CLK_REF
	 clkref_serdes_p: out std_logic;
	 clkref_serdes_n: out std_logic;

	 sysclk_serdes_p: in std_logic;
         sysclk_serdes_n: in std_logic;

         serial_clock : out std_logic;
         clkref_serdes: inout std_logic;

         sysclk_serdes: out std_logic;

	 -- PLASMA CPU PINS
	 clk_in      : in std_logic
      );
   end component;

   component uart_menu is
      port(
         reset		 : in std_logic;
         clk_in		 : in std_logic;
         clkref_serdes, rxclk_serdes, sysclk_serdes, serial_clock : in std_logic;

         hexint		 : out std_logic_vector(3 downto 0);

         uart_enable_read     : buffer std_logic;
         uart_enable_write    : buffer std_logic;
         uart_busy_write      : in std_logic;
         uart_data_avail      : in std_logic;

         uart_data_out        : in std_logic_vector(7 downto 0);
         uart_data_in         : out std_logic_vector(7 downto 0);

         mdio_opcode  	 	: out std_logic_vector(1 downto 0);	-- 00: Address 10: Read-Inc 01: Write
         mdio_data_read       	: in std_logic_vector(15 downto 0);
         mdio_data_write      	: out std_logic_vector(15 downto 0);
         mdio_start_conversion	: buffer std_logic;
         mdio_running_conversion   : in std_logic;
         mdio_error_code           : in std_logic_vector(2 downto 0);

         i2c_word_address    : out std_logic_vector(7 downto 0);
         i2c_data_read       : in std_logic_vector(7 downto 0);
         i2c_data_write      : out std_logic_vector(7 downto 0);
         i2c_op      	  : out std_logic_vector(1 downto 0);
         i2c_start_conversion: buffer std_logic;
         i2c_is_running      : in std_logic;
         i2c_error_code 	  : in std_logic_vector(2 downto 0)

      );
   end component;

   component uart is
      generic(log_file : string := "UNUSED");
      port(
         clk          : in std_logic;
         reset        : in std_logic;
         enable_read  : in std_logic;
         enable_write : in std_logic;
         data_in      : in std_logic_vector(7 downto 0);
         data_out     : out std_logic_vector(7 downto 0);
         uart_read    : in std_logic;
         uart_write   : out std_logic;
         busy_write   : out std_logic;
         data_avail   : out std_logic
      );
   end component;

   component pseudo_uart is
      port(
	 clk          : in std_logic;
         reset        : in std_logic;
         uart_read    : out std_logic; -- read per la UART, quindi write
         uart_write   : in std_logic   -- idem...
      );
   end component;

   component display7seg is 
      port (
         clk50        : in std_logic;          -- 50 Mhz XTAL
         reset	      : in std_logic;
         digit        : out std_logic_vector(3 downto 0);  -- digit drivers
         seg          : out std_logic_vector(7 downto 0);  -- segment drivers
         hexint       : in hexint_digit
      );
   end component;

   FUNCTION ALL_ZERO(s1:std_logic_vector) return std_logic; 

   constant ZERO : std_logic_vector(63 downto 0) := (OTHERS => '0');
   constant ONES : std_logic_vector(63 downto 0) := (OTHERS => '1');

   -- procedure mylog(name:string; value:std_logic_vector);
   procedure mylog(name:string; value:std_logic_vector := "0"; tipo: boolean := false);

   function to_string(sv: Std_Logic_Vector) return string;
end;

package body modules is

   FUNCTION ALL_ZERO(s1:std_logic_vector) return std_logic is
      --this function tells if all bits of a vector are '0'
      --return value Z if '1', then vector has all 0 bits
      --VARIABLE V : std_logic_vector(s1'high downto s1'low) ;
      VARIABLE Z : std_logic;
   BEGIN
      Z := '0';
      FOR i IN (s1'low) to s1'high LOOP
         Z := Z OR s1(i);
      END LOOP;
      RETURN not(Z);
   END ALL_ZERO; -- end function 

   procedure mylog(name:string; value:std_logic_vector := "0"; tipo: boolean := false) is
      variable line_out: Line; -- Line buffers
   begin
      if value'length = 1 then
         write(line_out, name);
      else
         write(line_out, name, right, 20);
         -- write(line_out, string'("DATA="));
         if value'length = 8 then
            hwrite(line_out, value);
         else
            write(line_out, value);
         end if;
      end if;
      writeline(OUTPUT, line_out);
   end procedure mylog;

   function to_string(sv: Std_Logic_Vector) return string is
      use Std.TextIO.all;
      variable bv: bit_vector(sv'range) := to_bitvector(sv);
      variable lp: line;
   begin
      write(lp, bv);
      return lp.all;
   end;

end modules;


library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
use ieee.numeric_bit.all;

package modules is

   constant clk_in_period : time := 20 ns; -- 50MHz   
   constant CR_CODE : std_logic_vector(7 downto 0) := x"0a";
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

   type mdio_rec is record
      -- mdio_sda    : std_logic; -- := 'Z';
      -- mdio_scl    : std_logic;
      data_read   : std_logic_vector(15 downto 0);
      data_write  : std_logic_vector(15 downto 0);
      opcode      : std_logic_vector(1 downto 0);
      start_conversion : std_logic; -- := '0';
      running_conversion  : std_logic;
   end record;

   type uart_rec is record
      enable_read  : std_logic;
      enable_write : std_logic;
      data_in      : std_logic_vector(7 downto 0);
      data_out     : std_logic_vector(7 downto 0);
      busy_write   : std_logic;
      data_avail   : std_logic;
   end record;

   component mdio is
      generic (
      	 mdio_address    : std_logic_vector(4 downto 0);
      	 device_address  : std_logic_vector(4 downto 0)
      );
      port (
         reset		 : in std_logic;
         led		 : buffer std_logic_vector(3 downto 0);

   	 serial_clock    : in std_logic; -- deve essere < 2.5 MHz!
   	 serial_data     : inout std_logic;
   
   	 opcode  	 : in std_logic_vector(1 downto 0);	-- 00: Address 10: Read-Inc 01: Write
   	 data_read       : out std_logic_vector(15 downto 0);
   	 data_write      : in std_logic_vector(15 downto 0);
   	 start_conversion: in std_logic;

   	 running_conversion  : out std_logic
      );
   end component;

   component mdio_slave is
      port (
         reset		 : in std_logic;
	 serial_clock    : in std_logic; -- deve essere < 2.5 MHz!
	 serial_data     : inout std_logic;

         data_read_back  : out std_logic_vector(31 downto 0);
	 data_write_back : in std_logic_vector(15 downto 0);

	 dato_ricevuto   : out std_logic
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
	 data            : in std_logic_vector(7 downto 0);
         read_write      : in std_logic;
	 serial_clock    : out std_logic := '0';
	 serial_data     : inout std_logic := 'Z';
         start_conversion: in std_logic
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

         serial_clock : out std_logic;
         clkref_serdes: inout std_logic;

	 -- PLASMA CPU PINS
	 clk_in      : in std_logic
      );
   end component;

   component uart_menu is
      port(
         reset		 : in std_logic;
         clk_in, clkref_serdes, serial_clock : in std_logic;
         led		 : buffer std_logic_vector(7 downto 4);
         hexint		 : out std_logic_vector(15 downto 0);

         uart_enable_read     : out std_logic;
         uart_enable_write    : out std_logic;
         uart_busy_write      : in std_logic;
         uart_data_avail      : in std_logic;

         uart_data_out        : in std_logic_vector(7 downto 0);
         uart_data_in         : out std_logic_vector(7 downto 0);

   	 mdio_opcode  	      : out std_logic_vector(1 downto 0);	-- 00: Address 10: Read-Inc 01: Write
   	 mdio_data_read       : in std_logic_vector(15 downto 0);
   	 mdio_data_write      : out std_logic_vector(15 downto 0);
   	 mdio_start_conversion: out std_logic
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
         hexint       : in std_logic_vector(15 downto 0)   -- what to display
      );
   end component;

   FUNCTION ALL_ZERO(s1:std_logic_vector) return std_logic; 

   constant ZERO : std_logic_vector(63 downto 0) := (OTHERS => '0');
   constant ONES : std_logic_vector(63 downto 0) := (OTHERS => '1');
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

end modules;


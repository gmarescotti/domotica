library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use WORK.modules.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity main is
   generic ( 
	  test_bench : natural := 0; 
          use_cpu    : natural := 0
   );
   port(
	  -- SFP HARDWARE
	  los         : in std_logic;
	  rate_select : out std_logic;
	  t_dis       : out std_logic; -- TELL LASER TO SWITCH-ON (0: ON, 1: OFF)
	  t_fault     : in std_logic;
	  -- Module Definition 2. Data line for Serial ID.
	  -- Module Definition 1. Clock line for Serial ID.
	  -- Module Definition 0. Grounded within the module.
	  mod_def     : inout std_logic_vector(2 downto 0);

	  -- UTILITY
	  led         : buffer std_logic_vector(7 downto 0);
	  tasto       : in std_logic_vector(7 downto 0);
	  digit_out   : out std_logic_vector(3 downto 0);
	  seg_out     : out std_logic_vector(7 downto 0);

	  -- SERDES MDIO SERIAL
	  mdio_sda    : inout std_logic := 'Z';
	  -- mdio_scl    : out std_logic;

	  -- SERDES CLK_REF
	   clkref_serdes_p: out std_logic;
	   clkref_serdes_n: out std_logic;

	  -- PLASMA CPU PINS
	  clk_in      : in std_logic;
	  reset_in    : in std_logic;
	  uart_read   : in std_logic;
	  uart_write  : out std_logic

       );
end main;

architecture Behavioral of main is

   -- signal running_conversion : std_logic;

    signal serial_clock 	: std_logic;
    signal clkref_serdes : std_logic;

   -- signal data_read                 : std_logic_vector(15 downto 0);
   -- signal data_write                : std_logic_vector(15 downto 0);
   -- signal opcode                    : std_logic_vector(1 downto 0);
   -- signal start_conversion          : std_logic := '0';

   -- signal data_write_back : std_logic_vector(15 downto 0);

   -- SIGNAL FOR UART
   -- signal uart_enable_read  : std_logic;
   -- signal uart_enable_write : std_logic;
   -- signal uart_data_in      : std_logic_vector(7 downto 0);
   -- signal uart_data_out     : std_logic_vector(7 downto 0);
   -- signal uart_busy_write   : std_logic;
   -- signal uart_data_avail   : std_logic;

   signal hexint : std_logic_vector(15 downto 0) := x"c1a0";  -- what to display
   signal reset : std_logic := '1';
begin

   -- mdio_scl 	<= serial_clock;

   rate_select 	<= '0';
   t_dis       	<= not tasto(0);
   led(0) 	<= tasto(0);
   led(1) 	<= los;
   led(2)       <= mod_def(0);
   led(4 downto 3) <= "00";

--   digit_out 	<= (OTHERS => '1' );
--   seg_out   	<= (OTHERS => '1' );

   --sync_reset: process(clk_in) is
   --begin
      -- reset <= reset_in;
   --end process;
   IBUFG_inst : IBUFG
   generic map (
      IBUF_DELAY_VALUE => "0", -- Specify the amount of added input delay for buffer, 
                               -- "0"-"12" (Spartan-3E)
                               -- "0"-"16" (Spartan-3A)
      IOSTANDARD => "DEFAULT")
   port map (
      O => reset, -- Clock buffer output
      I => reset_in  -- Clock buffer input (connect directly to top-level port)
   );

   -- SERDES: MDIO serial master interface
   serdes_io : mdio
      generic map ( mdio_address => "11111", device_address => "11110")
      port map ( 
                reset		  => reset,
                -- led		  => led(3 downto 0),
 
                serial_clock       => serial_clock,
                serial_data        => mdio_sda,
 	       
                opcode             => mdio_opcode,
                data_read          => mdio_data_read,
                data_write         => mdio_data_write,
                start_conversion   => mdio_start_conversion,
 	       
                running_conversion => mdio_running_conversion
       );

   -- SFP: Small form-factor pluggable transceiver 
   sfp_io : i2c 
      generic map ( device_address => "1010000" ) -- A0
      port map(
 	    reset		=> reset,
 	    double_clock_in 	=> serial_clock,
 	    word_address 	=> "01010101",
 	    data 		=> "00110011",
 	    serial_clock 	=> mod_def(1),
 	    serial_data 	=> mod_def(2),
 	    read_write 	=> '0', -- 1: READ, 0: WRITE
 	    start_conversion 	=> '0'
 	    );

    -- Genero tutti i clock del progetto
   instanzia_clocks : myclocks
   port map(
           reset,
           clkref_serdes_p, clkref_serdes_n,
           serial_clock, clkref_serdes,
           clk_in
   );

   -- Gestisce un protocollino su seriale
   -- per esportare lo stato attuale del sistema
   -- ad un programma running su PC.
   istanzia_menu : uart_menu
      port map(
         reset => reset,
         clk_in => clk_in, clkref_serdes => clkref_serdes, serial_clock => serial_clock, -- CLOCKS
         led => led(7 downto 5), hexint => hexint,

         uart_enable_read => uart_enable_read,
         uart_enable_write => uart_enable_write,
         uart_busy_write => uart_busy_write,
         uart_data_avail => uart_data_avail,
         uart_data_out => uart_data_out,
         uart_data_in => uart_data_in,

         mdio_opcode => mdio_opcode,
         mdio_data_read => mdio_data_read,
         mdio_data_write => mdio_data_write,
         mdio_start_conversion => mdio_start_conversion,
         mdio_running_conversion => mdio_running_conversion,
         mdio_error_code => mdio_error_code,

         i2c_word_address => i2c_word_address,
         i2c_data_read => i2c_data_read,
         i2c_data_write => i2c_data_write,
         i2c_op => i2c_op,
         i2c_start_conversion => i2c_start_conversion,
         i2c_is_running => i2c_is_running,
         i2c_error_code => i2c_error_code
      );

   -- Istanzia la seriale UART a 57600 baud
   u78 : uart
      port map (
         clk_in,
         reset,
         uart_enable_read,
         uart_enable_write,
         uart_data_in,
         uart_data_out,
         uart_read, uart_write, -- pins from physical serial port
         uart_busy_write,
         uart_data_avail
      );
      -- uart_write <= '1';

   -- istanzia il display a 7 segmenti
   disp1 : display7seg
      port map (
         clk50 => clk_in,           -- in std_logic;          -- 50 Mhz XTAL
         reset => reset,            -- in std_logic;
         digit => digit_out,        -- out std_logic_vector(3 downto 0);   -- digit drivers
         seg   => seg_out,          -- out std_logic_vector(7 downto 0));  -- segment drivers
         hexint=> hexint            -- x"C1A0" -- in std_logic_vector(15 downto 0) ;  -- what to display
      );

end Behavioral;


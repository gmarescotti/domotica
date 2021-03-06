library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use WORK.modules.all;

-- Library UNISIM;
-- use UNISIM.vcomponents.all;

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
	  push_button : in std_logic_vector(3 downto 0);
	  digit_out   : out std_logic_vector(3 downto 0);
	  seg_out     : out std_logic_vector(7 downto 0);

	  -- SERDES MDIO SERIAL
	  mdio_sda    : inout std_logic := 'Z';
	  mdio_scl    : buffer std_logic; -- GGGG era out!!
	  
	  -- TEST SLAVE
	  -- mdio_sda_slave    : inout std_logic := 'Z';
	  -- mdio_scl_slave    : in std_logic;

	  -- SERDES CLK_REF
	  clkref_serdes_p: out std_logic;
	  clkref_serdes_n: out std_logic;

	  sysclk_serdes_p: in std_logic;
	  sysclk_serdes_n: in std_logic;

          rxclk		: in std_logic;
	  rout		: in std_logic_vector(9 downto 0);

          txclk		: out std_logic;
	  din		: out std_logic_vector(9 downto 0);	  

	  -- PLASMA CPU PINS
	  clk_in      : in std_logic;
	  reset       : in std_logic;
	  uart_read   : in std_logic;
	  uart_write  : out std_logic

       );
end main;

architecture Behavioral of main is

   signal serial_clock 	: std_logic;
   signal clkref_serdes : std_logic;
   signal sysclk_serdes : std_logic;

   -- SIGNAL FOR UART
   signal uart_enable_read  : std_logic;
   signal uart_enable_write : std_logic;
   signal uart_data_in      : std_logic_vector(7 downto 0);
   signal uart_data_out     : std_logic_vector(7 downto 0);
   signal uart_busy_write   : std_logic;
   signal uart_data_avail   : std_logic;

   -- DISPLAY 
   signal hexint : hexint_digit; -- std_logic_vector(15 downto 0) := (OTHERS => 'Z');
   -- signal reset : std_logic := '1';

   -- I2C FOR SFP
   signal i2c_word_address    : std_logic_vector(7 downto 0);
   signal i2c_data_read       : std_logic_vector(7 downto 0);
   signal i2c_data_write      : std_logic_vector(7 downto 0);
   signal i2c_op      	       : std_logic_vector(1 downto 0);
   signal i2c_start_conversion: std_logic;
   signal i2c_is_running      : std_logic;
   signal i2c_error_code      : std_logic_vector(2 downto 0);

   -- MDIO FOR SERDES
   signal mdio_opcode  	      : std_logic_vector(1 downto 0);	-- 00: Address 10: Read-Inc 01: Write
   signal mdio_data_read       : std_logic_vector(15 downto 0);
   signal mdio_data_write      : std_logic_vector(15 downto 0);
   signal mdio_start_conversion: std_logic;
   signal mdio_running_conversion  : std_logic;
   signal mdio_error_code          : std_logic_vector(2 downto 0);

begin

   -- mdio_scl 	<= serial_clock;

   rate_select 	<= '0';
   t_dis       	<= '0'; -- not tasto(0);
   -- led(0) 	<= tasto(0);
   -- led(1) 	<= los;
   -- led(2)       <= mod_def(0);
   -- led(7 downto 4) <= (OTHERS => '0');
   -- led(3)       <= mdio_sda;
   

   -- DIN [8] is used as K-code select pin
   -- When DIN [8] is low, DIN [0-7] is mapped to the
   -- corresponding 10-bit D-group. When DIN [8] is high, DIN [0-7] is mapped to the
   -- corresponding 10-bit K-group.
   -- and DIN[9] should be tied Low.
   
   -- ROUT [8] is the K-group indicator. A low at ROUT [8] indicates ROUT [0-7] belongs
   -- to the D-group, while a high indicates it belongs to the K-group. ROUT [9] is the line
   -- code violation (LCV) indicator. ROUT [9] is high for one ROUT cycle when a line code
   -- violation occurs.
   din(9) <= '0';
   din_8_10b: process(clkref_serdes) is
   begin
      if rising_edge(clkref_serdes) then
         if push_button(0) = '0' then
	    din(8) <= '0';
            din(7 downto 0) <= tasto;
	 else
	    din(8) <= '1';
            din(7 downto 0) <= "101" & "11100"; -- "11100" & "101"; -- K28.5
	 end if;
      end if;
   end process;

   led(7 downto 2) <= rout(5 downto 0);
   
   led(0) <= rout(8);
   led(1) <= rout(9);
   
   txclk <= clkref_serdes when push_button(2) = '0' else 'Z';

   -- DEBUG ROUT K-CODES
   hexint(0) <= rout(3 downto 0) when rout(8) ='1' else x"0";
   hexint(1) <= rout(7 downto 4) when rout(8) ='1' else x"0";

   debug_tx: process (rout(9)) is
   begin
      if rising_edge(rout(9)) then
         hexint(2) <= rout(3 downto 0);
         hexint(3) <= rout(7 downto 4);
      end if;
   end process;

--   -- ritardo il fronte di discesa di mdio_scl con monostabile
--   clock_pro: process(clk_in) is
--      variable cnt : integer := 0;
--   begin
--      if rising_edge(clk_in) then
--         if reset = '1' then
--            cnt := 0;
--            mdio_scl <= '0';
--         else
--            if serial_clock = '0' then
--               mdio_scl <= '0';
--               cnt := 0;
--	    else
--               if cnt < 80 then
--                  cnt := cnt + 1;
--                  mdio_scl <= '0';
--               else
--                  mdio_scl <= '1';
--               end if;
--            end if;
--         end if;
--
--      end if;
--   end process;
--
--

--   digit_out 	<= (OTHERS => '1' );
--   seg_out   	<= (OTHERS => '1' );

   --sync_reset: process(clk_in) is
   --begin
      -- reset <= reset_in;
   --end process;
   -- IBUFG_inst : IBUFG
   -- generic map (
   --    IBUF_DELAY_VALUE => "0", -- Specify the amount of added input delay for buffer, 
   --                             -- "0"-"12" (Spartan-3E)
   --                             -- "0"-"16" (Spartan-3A)
   --    IOSTANDARD => "DEFAULT")
   -- port map (
   --    O => reset, -- Clock buffer output
   --    I => reset_in  -- Clock buffer input (connect directly to top-level port)
   -- );

   -- SERDES: MDIO serial master interface
   serdes_io : mdio
      generic map ( mdio_address => "11111", device_address => "11110")
      port map ( 
            reset	       => reset,
 
            clk_in             => serial_clock,

            serial_clock       => mdio_scl,
            serial_data        => mdio_sda,
 	    
            opcode             => mdio_opcode,
            data_read          => mdio_data_read,
            data_write         => mdio_data_write,
            start_conversion   => mdio_start_conversion,
 	    
            running_conversion => mdio_running_conversion,
            error_code         => mdio_error_code,
            hexint 	       => open -- hexint(2)
       );

   -- SERDES SLAVE FOR TEST!!!: MDIO serial test slave interface
   -- serdes_slave_io : mdio_slave
   --    port map ( 
   --          reset	       => reset,
   --          clk_in             => serial_clock,
   --          serial_clock       => mdio_scl_slave,
   --          serial_data        => mdio_sda_slave,
   --          data_write_back    => x"1492"
   --     );


   -- SFP: Small form-factor pluggable transceiver 
   sfp_io : i2c 
      generic map ( device_address => "1010000" ) -- A0
      port map(
 	    reset		=> reset,
 	    double_clock_in 	=> serial_clock,
 	    word_address 	=> i2c_word_address,
 	    data_read 		=> i2c_data_read,
 	    data_write 		=> i2c_data_write,
 	    op 			=> i2c_op,
 	    serial_clock 	=> mod_def(1),
 	    serial_data 	=> mod_def(2),
 	    start_conversion 	=> i2c_start_conversion,
	    is_running		=> i2c_is_running,
	    error_code 		=> i2c_error_code,
            hexint 		=> open -- hexint(1)
 	    );

    -- Genero tutti i clock del progetto
   instanzia_clocks : myclocks
   port map(
           reset => reset,
           clkref_serdes_p => clkref_serdes_p, clkref_serdes_n => clkref_serdes_n,
           sysclk_serdes_p => sysclk_serdes_p, sysclk_serdes_n => sysclk_serdes_n,
           serial_clock => serial_clock, clkref_serdes => clkref_serdes,
	   sysclk_serdes => sysclk_serdes,
           clk_in => clk_in
   );

   -- Gestisce un protocollino su seriale
   -- per esportare lo stato attuale del sistema
   -- ad un programma running su PC.
   istanzia_menu : uart_menu
      port map(
         reset => reset,
         clk_in => clk_in, clkref_serdes => clkref_serdes, 
	 sysclk_serdes => sysclk_serdes, 
	 serial_clock => serial_clock, -- CLOCKS
	 rxclk_serdes => rxclk,
         
	 hexint => open, -- hexint(0),

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


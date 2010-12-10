----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:57:10 11/12/2010 
-- Design Name:    main module
-- Module Name:    main - Behavioral 
-- Project Name:   domus electrica
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
use ieee.std_logic_arith.all;

--  XILINX LIBRARY: use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

use WORK.modules.all;

use IEEE.std_logic_textio.all;
USE ieee.std_logic_unsigned.ALL;
use STD.textio.all;


entity uart_menu is
   port(
      reset		: in std_logic;
      clk_in, clkref_serdes, serial_clock : in std_logic;
      led		: buffer std_logic_vector(7 downto 4);
      hexint		: out std_logic_vector(15 downto 0);

      uart_enable_read  : out std_logic;
      uart_enable_write : out std_logic;
      uart_busy_write   : in std_logic;
      uart_data_avail   : in std_logic;

      uart_data_out    	: in std_logic_vector(7 downto 0);
      uart_data_in     	: out std_logic_vector(7 downto 0);

      mdio_opcode  	 	: out std_logic_vector(1 downto 0);	-- 00: Address 10: Read-Inc 01: Write
      mdio_data_read       	: in std_logic_vector(15 downto 0);
      mdio_data_write      	: out std_logic_vector(15 downto 0);
      mdio_start_conversion	: out std_logic
   );
end uart_menu;

architecture menu1 of uart_menu is

   signal start_clock_test : std_logic := '0';
   signal start_clock_test2 : std_logic := '0';
   signal numof_clkclock : std_logic_vector(15 downto 0) := (OTHERS => '0');
   signal numof_refclock : std_logic_vector(15 downto 0) := (OTHERS => '0'); 
   signal numof_serial_clock : std_logic_vector(15 downto 0) := (OTHERS => '0'); 
   signal mdio_start_conversion_loc : std_logic := '0';

   signal data : std_logic_vector(7 downto 0);

   signal counter_rx : integer := 0;
   signal counter_tx : integer := 0;
   signal flag_rxed_message : std_logic := '0';
   signal flag_tobe_txed_message : std_logic := '0';

   type arr_type is array(0 to 10) of std_logic_vector(7 downto 0);
   signal data_rxed : arr_type := (OTHERS => (OTHERS => '0'));
   signal data_tobe_txed : arr_type := (OTHERS => (OTHERS => '0'));

begin

   mdio_start_conversion <= mdio_start_conversion_loc;
   led(4) <= mdio_start_conversion_loc;

   -----------------------------------------------------------------------------------------
   -- PROCESS CHAR RECEIVED FROM UART:
   -- STORE AND FORWARD MANAGEMENT WHEN CR RECEIVED.
   uart_tester : process (uart_data_avail) is -- , reset)
      variable flag_aspetta_codice: boolean := false;
   begin

      -- wait on uart_data_avail;

      if reset ='1' then
         counter_rx <= 0;
	 -- uart_enable_read <= '0';
      else

         if uart_data_avail = '1' then

            data <= uart_data_out;
            uart_enable_read <= '1';
	    led(6) <= not led(6);
	    hexint(7 downto 0) <= uart_data_out;
	 else
            uart_enable_read <= '0';
-- assert false report "DATA_AVAIL: " & integer'image(conv_integer(data)) severity note;

            if data = CR_CODE then -- Carriage Return
               counter_rx <= 0;
               flag_rxed_message <= not flag_rxed_message;
	    elsif data = x"01" then -- mini protocol character
	       flag_aspetta_codice := true;
            else
	       if flag_aspetta_codice = true then
                  data_rxed(counter_rx) <= not data;
	       else
                  data_rxed(counter_rx) <= data;
	       end if;
	       flag_aspetta_codice := false;

	       if counter_rx < data_rxed'length - 1 then
                  counter_rx <= counter_rx + 1;
	       else
		  assert false report "counter rx out of bound";
	       end if;
            end if;

	 end if;

      end if;
   end process;

   -----------------------------------------------------------------------------------------
   --
   stattx: process (flag_tobe_txed_message, uart_busy_write) is
      type tipo_stato is ( idle, running, invio_codice, invio_CR, fine );
      variable stato_tx : tipo_stato := idle;
      variable counter : integer := 0;

   begin
      if reset = '1' then
         uart_enable_write <= '0';
	 stato_tx := idle;
	 counter := 0;
      else

	 if uart_busy_write = '0' then
	    led(5) <= not led(5);

	    if stato_tx =  idle and counter_tx > 0 then
	       stato_tx := running;
	       counter := counter_tx - 1;
	    end if;

	    case stato_tx is

	       when running =>

	          if data_tobe_txed(counter) = x"01" or data_tobe_txed(counter) = x"00" or data_tobe_txed(counter) = x"0D" or data_tobe_txed(counter) = x"0A" then
	             uart_data_in <= x"01"; -- invio carattere di mini protocollo
	             stato_tx := invio_codice;
	          else
	             uart_data_in <= data_tobe_txed(counter);

	             if counter > 0 then
	                counter := counter - 1;
		     else
	                stato_tx := invio_CR;
	             end if;
	          end if;

	          uart_enable_write <= '1';

	       when invio_codice =>

	          uart_data_in <= not data_tobe_txed(counter);
	          if counter > 0 then
	             counter := counter - 1;
		  else
	             stato_tx := invio_CR;
	          end if;

	       when invio_CR =>

	          uart_data_in <= CR_CODE;  -- at the end send CR
		  stato_tx := fine;

	       when fine =>
                  uart_enable_write <= '0';
		  stato_tx := idle;

	       when others =>
		  assert false report "stato out of value" severity error;

	    end case;
	 end if; -- busy write
      end if;    -- reset
   end process;
            
   -----------------------------------------------------------------------------------------
   -- Processo che gestisce i comandi da UART. Ogni comando è una sequenza di char finiti da CR.
   process (flag_rxed_message) is
      variable counter_loc : integer := 0;
   begin
      if reset = '1' then
         counter_loc := 0;
      else
-- assert false report "RICEVUTO COMANDO " & integer'image(conv_integer(data_rxed(0))) severity note;
         counter_loc := 0;

         case data_rxed(0) is
            when x"00" =>
            when x"01" =>	-- invio dato in MDIO

               mdio_data_write <= data_rxed(2) & data_rxed(3);
               mdio_opcode <= data_rxed(1) (1 downto 0);
	       assert data_rxed(1)(7 downto 2) = "000000" report "mdio-opcode diverso da 00 01 10 11";
               mdio_start_conversion_loc <= not mdio_start_conversion_loc; -- START!

            when x"02" => -- lettura dato da MDIO
               data_tobe_txed(1) <= mdio_data_read(15 downto 8);
               data_tobe_txed(0) <= mdio_data_read(7 downto 0);
               counter_loc := 2;
               
            when x"61" => -- 'a': start/stop calcolo e controllo REFCLK(serdes) e serial_clock
	       case data_rxed(1) is

		  when x"61" =>
		     -- assert false report "start clock!" severity note;
                     start_clock_test <= not start_clock_test;
                     counter_loc := 0;
	          when x"62" =>
                     data_tobe_txed(1) <= numof_refclock(15 downto 8);
                     data_tobe_txed(0) <= numof_refclock(7  downto 0);

                     counter_loc := 2;

	          when x"63" =>
                     data_tobe_txed(1) <= numof_clkclock(15 downto 8);
                     data_tobe_txed(0) <= numof_clkclock(7  downto 0);

                     counter_loc := 2;

	          when x"64" =>
                     data_tobe_txed(1) <= numof_serial_clock(15 downto 8);
                     data_tobe_txed(0) <= numof_serial_clock(7  downto 0);

                     counter_loc := 2;
		  when others =>
                     data_tobe_txed(0) <= x"EE";
                     counter_loc := 1;

	       end case;

	       -- assert false report "clock:" & integer'image(conv_integer(data_tobe_txed(1))) & integer'image(conv_integer(data_tobe_txed(0))) severity note;

            when x"78" => -- 'x': AUTOTEST2
               -- gpioA_in <= gpio0_out;
               data_tobe_txed(4) <= data_rxed(1); -- CONV_STD_LOGIC_VECTOR(character'pos('a'), 8);
               data_tobe_txed(3) <= data_rxed(2); -- CONV_STD_LOGIC_VECTOR(character'pos('a'), 8);
               data_tobe_txed(2) <= data_rxed(3); -- CONV_STD_LOGIC_VECTOR(character'pos('a'), 8);
               data_tobe_txed(1) <= data_rxed(4); -- CONV_STD_LOGIC_VECTOR(character'pos('l'), 8);
               data_tobe_txed(0) <= data_rxed(5); -- CONV_STD_LOGIC_VECTOR(character'pos(CR), 8);
               counter_loc := 5;

            when x"06" =>
               -- gpioA_in <= data_read_back;
               data_tobe_txed(0) <= x"AA";
               counter_loc := 1;

            when others =>
               data_tobe_txed(0) <= x"EE";
               counter_loc := 1;
               led(7) <= not led(7);
         end case;

         data_tobe_txed(counter_loc) <= data_rxed(0);
         counter_loc := counter_loc + 1;

	 assert counter_loc < data_tobe_txed'length and counter_loc > 0 report "counter_loc out of bound:" & integer'image(counter_loc);

         counter_tx <= counter_loc;
         flag_tobe_txed_message <= not flag_tobe_txed_message;
	 hexint(15 downto 8) <= std_logic_vector(to_unsigned(counter_loc, 8));

         -- trasmetto il primo e a catena vengono trasmessi gli altri dal
         -- processo sottostante
      end if;

   end process;

   -- Processo che calcola i clock usati
   clk_calculator: process(clk_in, clkref_serdes, serial_clock)
      variable counter : natural := 0;
      variable counter_ref : natural := 0;
      variable counter_serial : natural := 0;
   begin
      if start_clock_test = '0' or reset ='1' then
         counter := 0;
         counter_ref := 0;
         counter_serial := 0;
      else
         if counter < 50000 then
            if rising_edge(clk_in) then
     	       counter := counter + 1;
            end if;
            if rising_edge(clkref_serdes) then
     	       counter_ref := counter_ref + 1;
            end if;
            if rising_edge(serial_clock) then
     	       counter_serial := counter_serial + 1;
            end if;
         else
            numof_clkclock <= std_logic_vector(to_unsigned(counter,16));
	    numof_refclock <= std_logic_vector(to_unsigned(counter_ref,16));
            numof_serial_clock <= std_logic_vector(to_unsigned(counter_serial,16));
         end if;
      end if;
   end process;
   
end architecture;


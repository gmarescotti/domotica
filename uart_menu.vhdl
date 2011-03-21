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
      clk_in		: in std_logic;
      clkref_serdes, serial_clock : in std_logic;
      led		: buffer std_logic_vector(7 downto 5) := "000";
      hexint		: out std_logic_vector(15 downto 0) := x"c2a0";

      uart_enable_read  : buffer std_logic := '0';
      uart_enable_write : buffer std_logic := '0';
      uart_busy_write   : in std_logic;
      uart_data_avail   : in std_logic;
      uart_data_out    	: in std_logic_vector(7 downto 0);
      uart_data_in     	: out std_logic_vector(7 downto 0);

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
end uart_menu;

architecture menu1 of uart_menu is

   signal start_clock_test : std_logic := '0';
   -- signal start_clock_test2 : std_logic := '0';
   signal numof_clkclock : std_logic_vector(15 downto 0) := (OTHERS => '0');
   signal numof_refclock : std_logic_vector(15 downto 0) := (OTHERS => '0'); 
   signal numof_serial_clock : std_logic_vector(15 downto 0) := (OTHERS => '0'); 
   -- signal mdio_start_conversion_loc : std_logic := '0';

   -- signal data : std_logic_vector(7 downto 0);

   signal flag_rxed_message : std_logic := '0';

   type arr_type is array(0 to 6) of std_logic_vector(7 downto 0);
   signal data_rxed : arr_type := (OTHERS => (OTHERS => '0'));
   signal data_tobe_txed : arr_type := (OTHERS => (OTHERS => '0'));

   signal counter_tx : integer range 0 to arr_type'length - 1 := 0;

      type tipo_stato is ( first, running, invio_codice, invio_CR, fine, errore1, errore2 );
      signal stato_tx : tipo_stato := first;
      -- attribute SIGNAL_ENCODING of stato_tx: signal is "USER";
   signal combi : std_logic;
   signal combi2 : std_logic;

begin

   -- mdio_start_conversion <= mdio_start_conversion_loc;
   -- led(4) <= mdio_start_conversion_loc;

   -----------------------------------------------------------------------------------------
   uart_enable_read <= '1';

   -----------------------------------------------------------------------------------------
   -- PROCESS CHARS RECEIVED FROM UART:
   -- COLLECT AND FORWARD MESSAGE TO MANAGEMENT WHEN CR RECEIVED.

   uart_tester : process (uart_data_avail, reset) is
      variable flag_aspetta_codice: boolean := false;
      -- variable counter_rx : std_logic_vector (5 downto 0);
      variable counter_rx : integer range 0 to arr_type'length; -- integer range 0 to 99;
    begin
 
      if reset ='1' then
         counter_rx := 0;
 	 flag_rxed_message <= '0';
      else
 
 	 if rising_edge(uart_data_avail) then
 
 	    -- hexint(15 downto 8) <= uart_data_out;
	    -- mylog("RX: ", uart_data_out);
 
 	    case uart_data_out is
 	       when CR_CODE => -- CARRIAGE RETURN
 		  counter_rx := 0;
 		  -- led(2) <= not led(2);
 	          flag_rxed_message <= '1';
 	       when x"01" => -- mini protocol character
 		  flag_aspetta_codice := true;
 	       when others =>
 	          flag_rxed_message <= '0';
 
 		  if flag_aspetta_codice = true then
 		     data_rxed(counter_rx) <= not uart_data_out;
 		  else
 		     data_rxed(counter_rx) <= uart_data_out;
 		  end if;
 		  flag_aspetta_codice := false;
 		  if counter_rx < data_rxed'length - 1 then
 		     counter_rx := counter_rx + 1;
 		     -- led(3) <= not led(3);
 		  else
 		     -- led(1) <= not led(1);
 		     -- assert false report "counter rx out of bound";
 		     counter_rx := 0;
 		  end if;
 	    end case;
 
 	    -- hexint(7 downto 0) <= std_logic_vector(to_unsigned(counter_rx, 8));
 	    -- hexint(7 downto 0) <= counter_rx;
 
 	 end if;
 
 
      end if; -- reset
   end process;

   -----------------------------------------------------------------------------------------
   -- Processo che esegue i comandi da UART e risponde l'esito a UART.
   -- Ogni comando e' una sequenza di char finiti da CR.
   -- process_command : process (flag_rxed_message, reset, data_rxed) is

   process_command : process (flag_rxed_message, reset) is
      variable counter_loc : integer range 0 to arr_type'length - 1 := 0;
   begin
      if reset = '1' then
         counter_loc := 0;
 	 counter_tx <= 0;
	 
      elsif rising_edge(flag_rxed_message) then
 
	 -- mylog("data_rxed(0)=", data_rxed(0));
	 -- mylog("data_rxed(1)=", data_rxed(1));
         case data_rxed(0) is

            -------------------- DEBUG CLOCKS ------------------------
            when x"61" => -- 'a': start/stop calcolo e controllo REFCLK(serdes) e serial_clock
 	       case data_rxed(1) is
 
 	          when x"61" =>
 	             -- assert false report "start clock!" severity note;
		     if data_rxed(2) = character'pos('1') then
                        start_clock_test <= '1';
			counter_loc := 0;
		     elsif data_rxed(2) = character'pos('0') then
                        start_clock_test <= '0';
			counter_loc := 0;
		     else
		        data_tobe_txed(0) <= x"EF";
                        counter_loc := 1;
		     end if;
 	          when x"62" =>
                     data_tobe_txed(1) <= numof_refclock(15 downto 8);
                     data_tobe_txed(0) <= numof_refclock(7  downto 0);
		     -- mylog("data_tobe_txed", data_tobe_txed(1));
		     -- mylog("data_tobe_txed", data_tobe_txed(0));
 
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
 
            -------------------- GESTIONE MDIO ------------------------
            when x"62" => -- 'b'
 	       mdio_case: case data_rxed(1) is

                  when x"61" => -- invio dato in MDIO

                     mdio_data_write <= data_rxed(2) & data_rxed(3);
                     mdio_opcode <= data_rxed(1) (1 downto 0);
 	             assert data_rxed(1)(7 downto 2) = "000000" report "mdio-opcode diverso da 00 01 10 11";
                     mdio_start_conversion <= not mdio_start_conversion; -- START!
                     counter_loc := 0;
 
                  when x"62" => -- lettura dato da MDIO
                     counter_loc := 0;
                     -- data_tobe_txed(1) <= mdio_data_read(15 downto 8);
                     -- data_tobe_txed(0) <= mdio_data_read(7 downto 0);
                     -- counter_loc := 2;
                  -- when x"66" => -- lettura error_code
                     -- data_tobetxed(0) <= mdio_error_code;

		  when others =>
		     --
		     counter_loc := 0;
               end case;

            -------------------- GESTIONE I2C ------------------------
            when x"63" => -- 'c'
 	       case data_rxed(1) is
                  when x"61" => 	-- invio dato in MDIO

                     counter_loc := 0;
 
                     -- mdio_data_write <= data_rxed(2) & data_rxed(3);
                     -- mdio_opcode <= data_rxed(1) (1 downto 0);
 	             -- assert data_rxed(1)(7 downto 2) = "000000" report "mdio-opcode diverso da 00 01 10 11";
                     -- mdio_start_conversion_loc <= not mdio_start_conversion_loc; -- START!
 
                  when x"62" => -- lettura dato da MDIO
                     counter_loc := 0;
                     -- data_tobe_txed(1) <= mdio_data_read(15 downto 8);
                     -- data_tobe_txed(0) <= mdio_data_read(7 downto 0);
                     -- counter_loc := 2;
		  when others =>
		     --
                     counter_loc := 0;
               end case;

 	       -- assert false report "clock:" & integer'image(conv_integer(data_tobe_txed(1))) & integer'image(conv_integer(data_tobe_txed(0))) severity note;
 
            --------------------- ECHO AUTOTEST -----------------------
            when x"78" => -- 'x': AUTOTEST2
               -- gpioA_in <= gpio0_out;
               data_tobe_txed(4) <= data_rxed(1); -- CONV_STD_LOGIC_VECTOR(character'pos('a'), 8);
               data_tobe_txed(3) <= data_rxed(2); -- CONV_STD_LOGIC_VECTOR(character'pos('a'), 8);
               data_tobe_txed(2) <= data_rxed(3); -- CONV_STD_LOGIC_VECTOR(character'pos('a'), 8);
               data_tobe_txed(1) <= data_rxed(4); -- CONV_STD_LOGIC_VECTOR(character'pos('l'), 8);
               data_tobe_txed(0) <= data_rxed(5); -- CONV_STD_LOGIC_VECTOR(character'pos(CR), 8);
               counter_loc := 5;
 
            ------------------------------------------------------------
            when others =>
               data_tobe_txed(0) <= x"EE";
               counter_loc := 1;
               -- led(7) <= not led(7);
         end case;
 
         ----------------------------------------------------------------------
         data_tobe_txed(counter_loc) <= data_rxed(0);
 
 	 assert counter_loc < data_tobe_txed'length and counter_loc >= 0 
            report "counter_loc out of bound:" & integer'image(counter_loc)
            severity error;
 
         counter_tx <= counter_loc + 1;
         -- Il messaggio preparato viene inviato dal processo seguente
         -- Il quale processo viene schedulato da flag_rxed_message
         -- ritardato di qualche clock (monostabile)
	 
      end if; -- reset
 
   end process;

   -----------------------------------------------------------------------------------------
   -- creo combi come flag_rxed_message ritardato. In pratica il processo e' un monostabile

   combi_pro: process(clk_in) is
      variable cnt : integer := 0;
   begin
      if rising_edge(clk_in) then
         if flag_rxed_message = '0' then
            cnt := 20;
	    combi <= '0';
         else
	    if cnt > 10 then
	       cnt := cnt - 1;
	       combi <= '0';
	    elsif cnt > 0 then
	       cnt := cnt - 1;
	       combi <= '1';
	    else
	       combi <= '0';
	    end if;
	 end if;

      end if;
   end process;
   
--   led(0) <= combi;
--   led(1) <= uart_enable_write;
--   led(2) <= flag_rxed_message;
   
   combi2 <= combi or uart_busy_write;
   
   -----------------------------------------------------------------------------------------
   -- Processo che trasmette la risposta preparata dal processo process_command
   -- inviando il messaggio in data_tobe_txed seguito da CR via seriale.
   stattx: process (combi2, reset) is
      variable counter : integer range 0 to 15 := 0;
      variable NNN : integer := 0;
   begin
   
      if reset = '1' then
         uart_enable_write <= '0';
	 stato_tx <= first;
	 counter := 0;
   
      elsif rising_edge(combi2) then
	 -- mylog("COMBI!", std_logic_vector(to_unsigned(counter_tx, 8)));

         NNN := NNN + 1;
         hexint(15 downto 8) <= std_logic_vector(to_unsigned(NNN, 8));

 	 case stato_tx is
 
 	    when first =>
 
 	       if counter_tx > 0 then
 		  counter := counter_tx - 1;
 		  uart_data_in <= data_tobe_txed(counter);
	 	  if counter > 0 then
 		     stato_tx <= running;
		     counter := counter - 1;
		  else
		     stato_tx <= invio_CR;
		  end if;
		  
                  uart_enable_write <= '1';
		     
 	       else -- ERRORE1
 	          uart_enable_write <= '0';
		  stato_tx <= errore1;
 	       end if;
 
 	    when running =>
 
 	       if data_tobe_txed(counter) = x"01" or data_tobe_txed(counter) = x"00" or data_tobe_txed(counter) = x"0D" or data_tobe_txed(counter) = x"0A" then
 	          uart_data_in <= x"01"; -- invio carattere di mini protocollo
 	          stato_tx <= invio_codice;
 	       else
 	          uart_data_in <= data_tobe_txed(counter);
 
 	          if counter > 0 then
 	             counter := counter - 1;
 	          else
 	             stato_tx <= invio_CR;
 	          end if;
	       end if;
  
 	     when invio_codice =>
 
 	        uart_data_in <= not data_tobe_txed(counter);
 
 	        if counter > 0 then
 	           counter := counter - 1;
 	           stato_tx <= running;
 	        else
 	           stato_tx <= invio_CR;
 	        end if;
 
 	    when invio_CR =>
 
 	       uart_data_in <= CR_CODE;  -- at the end send CR
 	       stato_tx <= fine;
 
            when fine => -- END TANSMITTING LAST CHAR(CR)
  	       uart_enable_write <= '0'; -- STOP SENDIND DATA THROUGH UART
 	       stato_tx <= first;
 
 	    when others =>
               uart_enable_write <= '0';
	       stato_tx <= errore2;
 	       -- assert false report "stato out of value" severity error;
 
 	 end case;

      end if;    -- reset
   end process;

   with stato_tx select
      led(7 downto 5) <= 
		      "000" when first,
		      "001" when running,
		      "010" when invio_codice,
		      "011" when invio_CR,
		      "100" when fine,
		      "101" when errore1,
		      "110" when errore2,
		      "111" when others;
   
    ----------------------------------------------------------------------------
    -- Processo che calcola i clock usati
    clk_calculator: process(clk_in, clkref_serdes, serial_clock, reset)
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


----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:57:10 11/12/2010 
-- Design Name: 
-- Module Name:    UART BRIDGE
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
use ieee.std_logic_arith.all;
use ieee.numeric_bit.all;

-- use ieee.numeric_std.all;
USE ieee.std_logic_unsigned.ALL;

use STD.textio.all;
use IEEE.std_logic_textio.all;

use WORK.modules.all;

entity pseudo_uart is
   port(
        clk          : in std_logic;
        reset        : in std_logic;
        uart_read    : out std_logic; -- read per la UART, quindi write
        uart_write   : in std_logic   -- idem...
       );
end pseudo_uart;

architecture Behavioral of pseudo_uart is

   signal loc_enable_read  : std_logic; -- in
   signal loc_enable_write : std_logic; -- in
   signal loc_data_in      : std_logic_vector(7 downto 0); -- in
   signal loc_data_out     : std_logic_vector(7 downto 0); -- out
   signal loc_busy_write   : std_logic; -- out
   signal loc_data_avail   : std_logic; -- out

   signal data     : std_logic_vector(7 downto 0); -- out
begin

   -- istanzio una uart per comunicare con la mia uart:
   -- devo connettere uart_read a uart_write e viceversa.
   -- data_in e out li uso per passare i dati da/a stdin/stdout
   -- dove un programma in c gestisce un menu esterno.
   uartback: uart
      port map(clk, reset, loc_enable_read, loc_enable_write,
	 loc_data_in, loc_data_out, uart_write, uart_read,
         loc_busy_write, loc_data_avail);

   --------------------------------------------------------
   read_stdin:
   process
      variable my_input_line : LINE;
      variable myline : LINE;
      variable c : std_ulogic := '1';
      variable ch : character;

      -- file my_input : TEXT open READ_MODE is "giulio-in.txt";
   begin

      loc_enable_write <= '0';
      wait until falling_edge(reset);
      -- wait for 100 us;

      loop
        exit when endfile(input);

-- assert false report "Waiting COMMAND..." severity note;

        readline(input, my_input_line);
	for i in 1 to my_input_line'length loop
           read(my_input_line, ch);

           -----------------------------------------
           -- devo trasmette su uart_rx quello che ho letto da stdin
           -- instanto lo stampo a terminale: funzione echo
           -- write(myline, ch);
           -- writeline(output, myline);

           loc_data_in <= CONV_STD_LOGIC_VECTOR(character'pos(ch), 8);
           loc_enable_write <= '1';
           wait until falling_edge(loc_busy_write);
           loc_enable_write <= '0';
           -- wait for 10 us;

	end loop;

        -- GGG wait for 10 us;
        -- SEND CARRIAGE RETURN/LINE FEED INSIDE UART_MENU THROW UART
        loc_data_in <= CR_CODE; -- CONV_STD_LOGIC_VECTOR(character'pos(CR_CHAR), 8);
        loc_enable_write <= '1';
        wait until falling_edge(loc_busy_write);
        loc_enable_write <= '0';

        -- WAIT ANSWER FROM UART_MENU
        wait until rising_edge(loc_data_avail);
        wait until rising_edge(loc_data_avail);
        -- wait for 700 us;
        wait until loc_data_avail'stable(580 us);

      end loop;
      assert false report "NONE. End of simulation." severity failure;
      wait; -- one shot at time zero,
   end process read_stdin;

   -- PROCESS COMMAND RECEIVED FROM UART
   -- THE ANSWER FROM UART_MENU
   answer_proess:
   process -- (loc_data_avail) -- , reset)
      variable l: line;
      -- file my_output : file of character;
      -- file my_output : TEXT open WRITE_MODE is "giulio-out.txt";
   begin

      wait on loc_data_avail;

      if loc_data_avail = '0' or reset ='1' then
         data <= (OTHERS => 'Z');
      else

         data <= loc_data_out;
         loc_enable_read <= '1';
         wait until loc_data_avail = '0';
         loc_enable_read <= '0';

         if data = CR_CODE then
            writeline(output, l); -- myoutput
         else 
            write(l, character'val(conv_integer(data)));
         end if;

      end if;
   end process;

end Behavioral;


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

use STD.textio.all;
use IEEE.std_logic_textio.all;

-- use WORK.modules.all;

entity pseudo_uart is
   port(
        clk          : in std_logic;
        reset        : in std_logic;
        enable_read  : in std_logic;
        enable_write : in std_logic;
        data_in      : in std_logic_vector(7 downto 0);
        data_out     : out std_logic_vector(7 downto 0);
        busy_write   : out std_logic;
        data_avail   : out std_logic
       );
end pseudo_uart;

architecture Behavioral of pseudo_uart is
begin
   --

   read_stdin:
   process
      variable my_input_line : LINE;
      variable myline : LINE;
      variable c : std_ulogic := '1';
      variable ch : character;
   begin
      loop
        exit when endfile(input);
        readline(input, my_input_line);
	for i in 1 to my_input_line'length loop
           read(my_input_line, ch);
           write(myline, ch);
           writeline(output, myline);
	end loop;
      end loop;
      wait; -- one shot at time zero,
   end process read_stdin;
end Behavioral;


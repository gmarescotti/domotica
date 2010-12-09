---------------------------------------------------------------------
-- TITLE: UART
-- AUTHOR: Giulio Marescotti
-- DATE CREATED: 29/11/2010
-- FILENAME: uart_tb.vhd
-- PROJECT:
-- COPYRIGHT:
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Implements the UART testbench.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use std.textio.all;
use work.modules.all;

entity uart_tb is
end;

architecture tet of uart_tb is

   signal clk          : std_logic; -- in
   signal reset        : std_logic; -- in
   signal enable_read  : std_logic; -- in
   signal enable_write : std_logic; -- in
   signal data_in      : std_logic_vector(7 downto 0); -- in
   signal data_out     : std_logic_vector(7 downto 0); -- out
   signal uart_read    : std_logic; -- in
   signal uart_write   : std_logic; -- out
   signal busy_write   : std_logic; -- out
   signal data_avail   : std_logic; -- out

   constant COUNT_VALUE : std_logic_vector(9 downto 0) :=
      -- "0110110010";  --25MHz/57600Hz = 0x1b2 -- Plasma IF uses div2
      "1101100100";  --50MHz/57600Hz = 0x364 -- Giulio USE 50MHz


   signal tx_clock : std_logic := '0';

begin

   uut: uart
      -- generic map ( log_file => "log.txt") -- UNUSED
      port map (
         clk,reset,enable_read,enable_write,
         data_in,data_out,uart_read,uart_write,
         busy_write,data_avail
      );

   -- Clock process definitions
   clk_in_process : process
   begin
      clk <= '0';
      wait for clk_in_period/2;
      clk <= '1';
      wait for clk_in_period/2;
   end process;

   serclk : process (clk)
      variable counter : integer := 0;
   begin
      -- if rising_edge(clk) then
         if counter = COUNT_VALUE then
            counter := 0;
            tx_clock <= not tx_clock;
         else
            counter := counter + 1;
         end if;
      -- end if;
   end process;

   --------------------------------------------------------

   read_process: process
      constant start_bit : std_logic := '0';
      constant stop_bit : std_logic := '1';
      variable dato : std_logic_vector(9 downto 0);

   begin
      enable_write <= '0';
      data_in <= (OTHERS => '1');

      uart_read <= '1';
      enable_read <= '0';
      reset <= '1';

      wait for 80 us;

      reset <= '0';
      wait for 30 us;
      --------------------------------------------------

      dato := start_bit & "11001010" & stop_bit; -- 53

      for i in (dato'length-1) downto 0 loop
         uart_read <= dato(i);
         wait on tx_clock;
         wait on tx_clock;
      end loop;

      -- wait until data_avail = '0';

      -- wait for 15 us;
      -- enable_read <= '1';
      -- wait for 15 us;
      -- enable_read <= '0';

      -- leggo il dato e ...
      enable_read <= '1';
      wait until data_avail = '0';
      enable_read <= '0';
      wait for 30 us;

      --------------------------------------------------

      dato := start_bit & "01010011" & stop_bit; -- CA

      for i in (dato'length-1) downto 0 loop
         uart_read <= dato(i);
         wait on tx_clock;
         wait on tx_clock;
      end loop;

      -- leggo il dato e ...
      enable_read <= '1';
      wait until data_avail = '0';
      enable_read <= '0';
      wait for 30 us;

      ------------------------------------------------
      data_in <= x"88";
      enable_write <= '1';
      wait on tx_clock;
      wait on tx_clock;
      wait until falling_edge(busy_write);
      data_in <= x"aa";
      wait on tx_clock;
      wait on tx_clock;
      wait until falling_edge(busy_write);
      data_in <= x"bb";
      wait on tx_clock;
      wait on tx_clock;
      wait until falling_edge(busy_write);
      enable_write <= '0';

      wait;
   end process;

end;


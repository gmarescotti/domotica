---------------------------------------------------------------------
-- TITLE: UART
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 5/29/02
-- FILENAME: uart.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Implements the UART.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

-- use ieee.std_logic_misc.all;
use ieee.std_logic_arith.all;
-- use ieee.std_logic_textio.all;
use ieee.std_logic_unsigned.all;

use std.textio.all;
-- use work.mlite_pack.all;
use work.modules.all;

-- use ieee.numeric_std.all;

entity uart is
   generic(log_file : string := "UNUSED");
   port(clk          : in std_logic;
        reset        : in std_logic;
        enable_read  : in std_logic;
        enable_write : in std_logic;
        data_in      : in std_logic_vector(7 downto 0);
        data_out     : out std_logic_vector(7 downto 0);
        uart_read    : in std_logic;
        uart_write   : out std_logic;
        busy_write   : out std_logic;
        data_avail   : out std_logic);
end; --entity uart

architecture logic of uart is
   signal delay_write_reg : std_logic_vector(9 downto 0);
   signal bits_write_reg  : std_logic_vector(3 downto 0) := (OTHERS => '0');
   signal data_write_reg  : std_logic_vector(8 downto 0);
   signal delay_read_reg  : std_logic_vector(9 downto 0);
   signal bits_read_reg   : std_logic_vector(3 downto 0);
   signal data_read_reg   : std_logic_vector(7 downto 0);
   -- signal data_save_reg   : std_logic_vector(17 downto 0);
   signal data_save_reg   : std_logic_vector(8 downto 0);
   signal busy_write_sig  : std_logic := '0';
   signal read_value_reg  : std_logic_vector(6 downto 0);
   signal uart_read2      : std_logic;

begin

uart_proc: process(clk, reset, enable_read, enable_write, data_in,
                   data_write_reg, bits_write_reg, delay_write_reg, 
                   data_read_reg, bits_read_reg, delay_read_reg,
                   data_save_reg, read_value_reg, uart_read2,
                   busy_write_sig, uart_read)
   constant COUNT_VALUE : std_logic_vector(9 downto 0) :=
--      "0100011110";  --33MHz/2/57600Hz = 0x11e
      "1101100100";  --50MHz/57600Hz = 0x364 -- Giulio uses 50MHz
--      "0110110010";  --25MHz/57600Hz = 0x1b2 -- Plasma IF uses div2
--      "0011011001";  --12.5MHz/57600Hz = 0xd9
--      "0000000100";  --for debug (shorten read_value_reg)
begin
   uart_read2 <= read_value_reg(read_value_reg'length - 1);

   if reset = '1' then
      data_write_reg  <= ZERO(8 downto 1) & '1';
      bits_write_reg  <= "0000";
      delay_write_reg <= ZERO(9 downto 0);
      read_value_reg  <= ONES(read_value_reg'length-1 downto 0);
      data_read_reg   <= ZERO(7 downto 0);
      bits_read_reg   <= "0000";
      delay_read_reg  <= ZERO(9 downto 0);
      -- data_save_reg   <= ZERO(17 downto 0);
      data_save_reg   <= ZERO(8 downto 0);
      busy_write_sig <= '0'; -- GGG
   elsif rising_edge(clk) then

      --Write UART
      if bits_write_reg = "0001" then               --nothing left to write?
	 busy_write_sig <= '1'; -- GGG
      else
	 busy_write_sig <= '0'; -- GGG
      end if;
      
      if bits_write_reg = "0000" then               --nothing left to write?
         if enable_write = '1' then

            delay_write_reg <= ZERO(9 downto 0);    --delay before next bit
            -- GGG bits_write_reg <= "1010";               --number of bits to write
            -- GGG data_write_reg <= data_in & '0';        --remember data & start bit
            bits_write_reg <= "1011";               --number of bits to write: AGGIUNGO UN UNO PER RITARDARE
            data_write_reg <= data_in & '0';        --remember data & start bit
-- mylog("TRAS: ", data_in);

         end if;
      else
         if delay_write_reg /= COUNT_VALUE then
            delay_write_reg <= delay_write_reg + 1; --delay before next bit
         else
            delay_write_reg <= ZERO(9 downto 0);    --reset delay
            bits_write_reg <= bits_write_reg - 1;   --bits left to write
            data_write_reg <= '1' & data_write_reg(8 downto 1); -- SHIFT A DESTRA E TRASMETTO BIT0 LSB
         end if;
      end if;

      --Average uart_read signal
      if uart_read = '1' then
         if read_value_reg /= ONES(read_value_reg'length - 1 downto 0) then
            read_value_reg <= read_value_reg + 1;
         end if;
      else
         if read_value_reg /= ZERO(read_value_reg'length - 1 downto 0) then
            read_value_reg <= read_value_reg - 1;
         end if;
      end if;

      --Read UART
      if delay_read_reg = ZERO(9 downto 0) then     --done delay for read?
         if bits_read_reg = "0000" then             --nothing left to read?
            if uart_read2 = '0' then                --wait for start bit
               delay_read_reg <= '0' & COUNT_VALUE(9 downto 1);  --half period
               bits_read_reg <= "1001";             --bits left to read
            end if;
         else
            delay_read_reg <= COUNT_VALUE;          --initialize delay
            bits_read_reg <= bits_read_reg - 1;     --bits left to read
            data_read_reg <= uart_read2 & data_read_reg(7 downto 1);
         end if;
      else
         delay_read_reg <= delay_read_reg - 1;      --delay
      end if;

      --Control character buffer
      if bits_read_reg = "0000" and delay_read_reg = COUNT_VALUE then -- BEGINNING OF STOP BIT
-- GGG          if data_save_reg(8) = '0' or 
-- GGG                (enable_read = '1' and data_save_reg(17) = '0') then
            --Empty buffer
            data_save_reg(7 downto 0) <= data_read_reg;
            data_save_reg(8) <= '1';
            -- data_save_reg(8 downto 0) <= '1' & data_read_reg;
-- GGG          else
-- GGG             --Second character in buffer
-- GGG             data_save_reg(17 downto 9) <= '1' & data_read_reg;
-- GGG             if enable_read = '1' then
-- GGG                data_save_reg(8 downto 0) <= data_save_reg(17 downto 9);
-- GGG             end if;
-- GGG          end if;
      elsif enable_read = '1' then
         -- data_save_reg(17) <= '0';                  --data_available
         -- data_save_reg(8 downto 0) <= data_save_reg(17 downto 9);
	 data_avail <= data_save_reg(8);
	 if data_save_reg(8) = '1' then
-- assert false report "CIAO: " & integer'image(conv_integer(data_save_reg(7 downto 0))) severity note;
	    data_save_reg(8) <= '0';
	 end if;
	 -- GGG
	 -- data_out <= data_save_reg(7 downto 0);
      end if;
   end if;  --rising_edge(clk)

   -- GGG uart_write <= data_write_reg(0);
-- GGG   if bits_write_reg /= "0000" 
-- GGG-- Comment out the following line for full UART simulation (much slower)
-- GGG   and log_file = "UNUSED" 
-- GGG   then
-- GGG      busy_write_sig <= '1';
-- GGG   else
-- GGG      busy_write_sig <= '0';
-- GGG end if;

end process; --uart_proc

   uart_write <= data_write_reg(0);
   busy_write <= busy_write_sig;
   
   -- GGG
   data_out <= data_save_reg(7 downto 0);
 
-- end process; --uart_proc

-- synthesis_off
   uart_logger:
   if log_file /= "UNUSED" generate
      uart_proc: process(clk, enable_write, data_in)
         file store_file : text open write_mode is log_file;
         variable hex_file_line : line;
         variable c : character;
         variable index : natural;
         variable line_length : natural := 0;
      begin
         if rising_edge(clk) and busy_write_sig = '0' then
            if enable_write = '1' then
               index := conv_integer(data_in(6 downto 0));
               if index /= 10 then
                  c := character'val(index);
                  write(hex_file_line, c);
                  line_length := line_length + 1;
               end if;
               if index = 10 or line_length >= 72 then
--The following line may have to be commented out for synthesis
                  writeline(store_file, hex_file_line);
                  line_length := 0;
               end if;
            end if; --uart_sel
         end if; --rising_edge(clk)
      end process; --uart_proc
   end generate; --uart_logger
-- synthesis_on

end; --architecture logic

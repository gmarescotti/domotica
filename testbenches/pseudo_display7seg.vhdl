library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use std.textio.all;
use ieee.numeric_std.all;
use IEEE.std_logic_textio.all;

use work.modules.all;

entity display7seg is port (
   clk50        : in std_logic;          -- 50 Mhz XTAL
   reset	: in std_logic;
   digit        : out std_logic_vector(3 downto 0);   -- digit drivers
   seg          : out std_logic_vector(7 downto 0) := (OTHERS => '1');  -- segment drivers
   hexint       : in hexint_digit); -- std_logic_vector(15 downto 0));  -- what to display
end entity display7seg;

architecture arch_display7seg of display7seg is

begin

displgen: for i in 0 to 3 generate
process(hexint(i))
   variable myline : line;
begin
   if reset = '0' then
      assert false 
         report "DISPLAY " & integer'image(i) & ": " & integer'image(conv_integer(hexint(i)))
         severity note;
   end if;

end process;
end generate displgen;

end arch_display7seg;



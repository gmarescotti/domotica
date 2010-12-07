package boh is
  -- function sin (v : real) return real;
  -- attribute foreign of sin : function is "VHPIDIRECT sin";

   procedure wrapp (y1 : integer );
   attribute foreign of wrapp : procedure is "VHPIDIRECT wrapp";

end boh;

package body boh is
   procedure wrapp (y1 : integer) is
   begin
      assert false severity failure;
   end wrapp;
end boh;

library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;
use work.boh.all;

entity prova_tb is
   port(
         x1   : in std_logic;
	 y1   : out integer := 7;
	 y2   : buffer integer := 6
       );
end prova_tb;


architecture Behavioral of prova_tb is
begin
   --
   wrapp (y2);

   process
      variable l : line;
   begin
      y2 <= 2;

      wrapp (y2);

      write (l, string'("ciao peppe: "));

      write (l, y2);

      writeline (output, l);

      wait;
   end process;

end Behavioral;


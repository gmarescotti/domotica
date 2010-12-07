----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:57:10 11/12/2010 
-- Design Name: 
-- Module Name:    main - Behavioral 
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

-- use IEEE.STD_LOGIC_ARITH.ALL;
-- use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Xilinx primitives in this code.
-- Library UNISIM;
-- use UNISIM.vcomponents.all;

use WORK.modules.all;

entity myclocks is
   generic ( is_xilinx : natural := 1 );
   port(
          reset		 : in std_logic;

	  -- SERDES CLK_REF
	  clkref_serdes_p: out std_logic;
	  clkref_serdes_n: out std_logic;

          serial_clock : out std_logic;
          clkref_serdes: out std_logic;

	  -- PLASMA CPU PINS
	  clk_in      : in std_logic
       );
end myclocks;

architecture Behavioral of myclocks is

   signal clkref_serdes_loc : std_logic;

begin

   clkref_serdes <= clkref_serdes_loc;
   
   process(clkref_serdes_loc) -- converte il clock ref del serdes da 37MHz a ~1MHz buono per le seriali
      variable clk_counter : integer := 0;
      constant CLK_FRACTION : integer := 2; -- ATTENZIONE PER VELOCIZZARE !!!! 32;
   begin
      if reset = '1' then
         clk_counter := 0;
         serial_clock <= '0';
      else 
	 if clkref_serdes_loc = '0' then
	    clk_counter := clk_counter + 1;

	    if clk_counter >= CLK_FRACTION then
	       clk_counter := 0;
	    end if;

	    if clk_counter < CLK_FRACTION/2 then
	       serial_clock <= '1';
	    else
	       serial_clock <= '0';
	    end if;
	 end if;
       end if;
   end process;

   clkref_serdes_loc <= clk_in;

   -- Genero clkef_serdes
   -- clkref_process : process
      -- constant clkref_period : time := 20 ns; -- ATTENZIONE SOLO PER VELOCIZZARE !! 32 ns; -- 30.7MHz -- 20 ns; -- 50MHz   
   -- begin
	-- clkref_serdes_loc <= '0';
	-- wait for clkref_period/2;
	-- clkref_serdes_loc <= '1';
	-- wait for clkref_period/2;
   -- end process;

end Behavioral;


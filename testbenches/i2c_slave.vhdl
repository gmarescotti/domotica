library IEEE;
use IEEE.std_logic_1164.all;
-- use ieee.std_logic_unsigned.all;
-- use ieee.std_logic_arith.all;

USE ieee.std_logic_unsigned.ALL;

use WORK.modules.all;

entity i2c_slave is
   port (
      scl : in std_logic;
      sda : inout std_logic
   );
end entity i2c_slave;

architecture behav of i2c_slave is

   signal data : std_logic_vector(7 downto 0);
   signal dato_chiesto : std_logic_vector(7 downto 0);

   signal toggle_start : std_logic := '0';
   signal toggle_stop : std_logic := '0';

signal gil : std_logic := '0';
begin

   -- START CONDITION
   process(scl,sda)
   begin
      if falling_edge(sda) then
	 if scl = '1' then
	    toggle_start <= not toggle_start;
	 end if;
      end if;
   end process;

   -- STOP CONDITION
   process(scl,sda)
   begin
      if rising_edge(sda) then
	 if scl = '1' then
	    toggle_stop <= not toggle_stop;
	 end if;
      end if;
   end process;

   ----------------------------------------------------------
   process
      variable dato : std_logic_vector(7 downto 0);
   begin
      sda <= 'Z';
      wait on toggle_start;

      -- LEGGO DEVICE ADDRESS+MODE
      for i in 7 downto 0 loop
         wait until rising_edge(scl);
         dato(i) := sda;
         wait until falling_edge(scl);
      end loop;

      wait until rising_edge(scl);
      -- ABBASSO SDA PER 1 CLOCK PER DARE ACK A MASTER
      sda <= '0';
      wait until falling_edge(scl);
      sda <= 'Z';

      assert false report "address+mode=" & integer'image(conv_integer(dato)) severity note;

      if dato(0) = '1' then -- READ MODE

         dato_chiesto <= x"AA";

         -- SCRIVO 8 BIT: DATO CHIESTO
         for i in 7 downto 0 loop
gil <= not gil;
            wait for 10 ns; -- anticipo di  mezzo clock per preparare un dato valido
                           -- durante il fronte alto di serial clock
            sda <= dato_chiesto(i);

            wait until rising_edge(scl);
            wait until falling_edge(scl);
         end loop;
         wait for 10 ns;
         sda <= 'Z';
         wait until rising_edge(scl);
      else
         assert false report "non ancora fatto.." severity  note;
      end if;

   end process;

-- comm: if false generate
-- 
--       ----------------------------------- FACCIO UNA SCRITTUTA di c6 in 59
--       data_write <= x"C6";
--       word_address <= x"59";
--       op <= "00"; -- write mode
-- 
--       -- INVIO START_CONVERSION
--       wait for 80 ns;
--       start_conversion <= '1';
-- 
--       -- WAIT START
--       wait on toggle_start;
--       start_conversion <= '0';
-- 
--       for j in 0 to 2 loop -- TRE BYTE: DEVICE, WORDADDRESS, WRITEBYTE
--          -- ASPETTO 8 COLPI DI CLOCK e 1/2
-- 	 for i in 7 to 0 loop
-- 	    wait until rising_edge(scl);
-- 	    dato(i) := sda;
-- 	    wait until falling_edge(scl);
-- 	 end loop;
-- 	 wait until rising_edge(scl);
-- 
--          -- ABBASSO SDA PER 1 CLOCK PER DARE ACK A MASTER
-- 	 sda <= '0';
-- 	 wait until falling_edge(scl);
-- 	 sda <= 'Z';
-- 
--          assert false report "dato=" & integer'image(conv_integer(dato)) severity note;
--       end loop;
-- 
--       -- ASPETTO STOP
--       wait on toggle_stop for 1 ms;
-- 
--       wait for 1 us;
-- 
--       ----------------------------------- FACCIO Current Address Read
--       -- Current Address READ: START/DEVICEADDRESS/READ/READDATA/STOP
--       word_address <= x"72";
--       op <= "10"; -- current address read mode
-- 
--       -- INVIO START_CONVERSION
--       wait for 80 ns;
--       start_conversion <= '1';
-- 
--       -- WAIT START
--       wait on toggle_start;
--       start_conversion <= '0';
-- 
--       -- LEGGO 8 BIT: DEVICE ADDRESS
--       for i in 7 downto 0 loop
-- 	 wait until rising_edge(scl);
-- 	 dato(i) := sda;
-- 	 wait until falling_edge(scl);
--       end loop;
--       wait until rising_edge(scl);
-- 
--       -- ABBASSO SDA PER 1 CLOCK PER DARE ACK A MASTER
--       sda <= '0';
--       wait until falling_edge(scl);
--       sda <= 'Z';
-- 
--       assert false report "device address=" & integer'image(conv_integer(dato)) severity note;
-- 
--       dato_chiesto <= x"AA";
-- 
--       -- SCRIVO 8 BIT: DATO CHIESTO
--       for i in 7 downto 0 loop
--          wait on clock; -- anticipo di  mezzo clock per preparare un dato valido
--                         -- durante il fronte alto di serial clock
-- 	 sda <= dato_chiesto(i);
-- 	 wait until rising_edge(scl);
-- 	 wait until falling_edge(scl);
--       end loop;
--       wait on clock;
--       sda <= 'Z';
--       wait until rising_edge(scl);
-- 
--       -- ASPETTO STOP
--       wait on toggle_stop for 1 ms;
-- 
--       -- STAMPO DATO SCRITTO DAME / LETTO DA DRIVER I2C
--       assert false report "data read = " & integer'image(conv_integer(data_read))  severity note;
-- 
--       assert false report "error = " & integer'image(conv_integer(error_code))  severity note;
-- 
-- 
-- --      ----------------------------------- FACCIO Random Read in 0x72
-- --      -- RANDOM READ: START/DEVICEADDRESS/WRITE/WORDADDRESS/START/DEVICEADDRESS/READ/READDATA/STOP
-- --      word_address <= x"72";
-- --      op <= "01"; -- random read mode
-- --
-- --      -- INVIO START_CONVERSION
-- --      wait for 80 ns;
-- --      start_conversion <= '1';
-- --
-- --      -- WAIT START
-- --      wait on toggle_start;
-- --      start_conversion <= '0';
-- --
-- --      -- LEGGO DUE BYTE: DEVICE, WORDADDRESS
-- --      for j in 0 to 1 loop
-- --         -- ASPETTO 8 COLPI DI CLOCK e 1/2
-- --	 for i in 7 downto 0 loop
-- --	    wait until rising_edge(scl);
-- --	    dato(i) := sda;
-- --	    wait until falling_edge(scl);
-- --	 end loop;
-- --	 wait until rising_edge(scl);
-- --
-- --         -- ABBASSO SDA PER 1 CLOCK PER DARE ACK A MASTER
-- --	 sda <= '0';
-- --	 wait until falling_edge(scl);
-- --	 sda <= 'Z';
-- --
-- --	 assert false report "data=" & integer'image(conv_integer(dato)) severity note;
-- --      end loop;
-- --
-- --      -- INIZIA UNA CURRENT ADDRESS READ DI UN BYTE
-- --      -- ASPETTO START: FRONTE DISCESA DATO DURANTE HIGH DI CLOCK
-- --      wait on toggle_start;
-- --
-- --      -- LEGGO 8 BIT: DEVICE ADDRESS
-- --      for i in 7 downto 0 loop
-- --	 wait until rising_edge(scl);
-- --	 dato(i) := sda;
-- --	 wait until falling_edge(scl);
-- --      end loop;
-- --      wait until rising_edge(scl);
-- --
-- --      -- ABBASSO SDA PER 1 CLOCK PER DARE ACK A MASTER
-- --      sda <= '0';
-- --      wait until falling_edge(scl);
-- --      sda <= 'Z';
-- --
-- --      assert false report "data=" & integer'image(conv_integer(dato)) severity note;
-- --
-- --      dato_chiesto <= x"AA";
-- --
-- --      -- SCRIVO 8 BIT: DATO CHIESTO
-- --      for i in 7 downto 0 loop
-- --         wait on clock; -- anticipo di  mezzo clock per preparare un dato valido
-- --                        -- durante il fronte alto di serial clock
-- --	 sda <= dato_chiesto(i);
-- --	 wait until rising_edge(scl);
-- --	 wait until falling_edge(scl);
-- --      end loop;
-- --      wait on clock;
-- --      sda <= 'Z';
-- --      wait until rising_edge(scl);
-- --
-- --      -- ASPETTO STOP
-- --      wait on toggle_stop for 1 ms;
-- --
-- --      -- STAMPO DATO SCRITTO DAME / LETTO DA DRIVER I2C
-- --      assert false report "data read = " & integer'image(conv_integer(data_read))  severity note;
-- --
-- --      assert false report "error = " & integer'image(conv_integer(error_code))  severity note;
-- --      --------------------------------------------------------------
-- 
--       stop <= '1';
--       wait;
--    end process;
-- 
-- end generate;

end behav;

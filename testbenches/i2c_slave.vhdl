library IEEE;
use IEEE.std_logic_1164.all;
-- use ieee.std_logic_unsigned.all;
-- use ieee.std_logic_arith.all;

USE ieee.std_logic_unsigned.ALL;

use WORK.modules.all;

entity i2c_slave is
   port (
      scl : in std_logic;
      sda : inout std_logic;

      dato_chiesto : in std_logic_vector(7 downto 0);

      device_address_back : buffer std_logic_vector(7 downto 0);
      word_address_back : out std_logic_vector(7 downto 0);
      data_write_back : out std_logic_vector(7 downto 0)
   );
end entity i2c_slave;

architecture behav of i2c_slave is

   signal data : std_logic_vector(7 downto 0);

   signal toggle_start : std_logic := '0';
   signal toggle_stop : std_logic := '0';

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
         device_address_back(i) <= sda;
         wait until falling_edge(scl);
      end loop;

mylog("DEVICE_ADDRESS=", device_address_back);

      wait until rising_edge(scl);
      -- ABBASSO SDA PER 1 CLOCK PER DARE ACK A MASTER
      sda <= '0';
      wait until falling_edge(scl);
      sda <= 'Z';

      if device_address_back(0) = '1' then -- READ MODE

         -- SCRIVO 8 BIT: DATO CHIESTO
         for i in 7 downto 0 loop
            wait for 10 ns; -- anticipo di  mezzo clock per preparare un dato valido
                            -- durante il fronte alto di serial clock
            sda <= dato_chiesto(i);

            wait until rising_edge(scl);
            wait until falling_edge(scl);
         end loop;
         wait for 10 ns;
         sda <= 'Z';
         wait until rising_edge(scl);

      else -- WRITE MODE

         -------------------------------
         -- LEGGO WORD ADDRESS
         for i in 7 downto 0 loop
            wait until rising_edge(scl);
            word_address_back(i) <= sda;
            wait until falling_edge(scl);
         end loop;
         wait until rising_edge(scl);
         -- ABBASSO SDA PER 1 CLOCK PER DARE ACK A MASTER
         sda <= '0';
         wait until falling_edge(scl);
         sda <= 'Z';

         -------------------------------
	 wait until rising_edge(scl);
         wait on toggle_start for 15 ns; -- aspetto 2/3 clock
         if toggle_start'event then -- HO RICEVUTO UNA START QUI? VUOL DIRE CHE
				    -- INIZIA UNA RANDOM READ
            -- assert false report "EVVIVA RANDOM READ" severity note;

            -- LEGGO DEVICE ADDRESS+MODE
            for i in 7 downto 0 loop
               wait until rising_edge(scl);
               device_address_back(i) <= sda;
               wait until falling_edge(scl);
            end loop;

            wait until rising_edge(scl);
            -- ABBASSO SDA PER 1 CLOCK PER DARE ACK A MASTER
            sda <= '0';
            wait until falling_edge(scl);
            sda <= 'Z';

            assert device_address_back(0) = '1' report "INATTESA WRITE MODE IN MEZZO A RANDOM READ" severity error;

            -- SCRIVO 8 BIT: DATO CHIESTO
            for i in 7 downto 0 loop
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

            -------------------------------
            -- LEGGO DATA
            for i in 7 downto 0 loop
               data_write_back(i) <= sda;
               wait until falling_edge(scl);
	       wait until rising_edge(scl);
            end loop;
            -- ABBASSO SDA PER 1 CLOCK PER DARE ACK A MASTER
            sda <= '0';
            wait until falling_edge(scl);
            sda <= 'Z';
         end if;
         -------------------------------
      end if;

   end process;

end behav;

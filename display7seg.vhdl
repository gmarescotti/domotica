library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

--pragma translate_off
-- library unisim;
-- use unisim.vcomponents.all;
--pragma translate_on

entity display7seg is port (
   clk50        : in std_logic;          -- 50 Mhz XTAL
   reset	: in std_logic;
   digit        : out std_logic_vector(3 downto 0);   -- digit drivers
   seg          : out std_logic_vector(7 downto 0);  -- segment drivers
   hexint       : in std_logic_vector(15 downto 0));  -- what to display
end display7seg;

architecture arch_display7seg of display7seg is

   -- -- CMOS33 input buffer primitive
   -- component ibuf_lvcmos33 port (i : in std_logic; o : out std_logic); end component;
   -- -- CMOS33 clock input buffer primitive
   -- component ibufg_lvcmos33 port(i : in std_logic; o : out std_logic); end component;
   -- -- CMOS33 output buffer primitive
   -- component obuf_lvcmos33 port(i : in std_logic; o : out std_logic); end component;
   -- -- global buffer primitive
   -- component bufg port(i : in std_logic; o : out std_logic); end component;

   signal khertz_en   : std_logic;            --

begin

   -- clk50in_ibuf    : ibufg_lvcmos33   port map(i => clk50in,    o => clk50int );
   -- rxclka_bufg    : bufg          port map(i => clk50int, o => clk50 );
   -- loop0 : for i in 0 to 3 generate
   -- digit_obuf    : obuf_lvcmos33     port map(i => digit(i),   o => digit_out(i));
   -- pb_ibuf    : ibuf_lvcmos33     port map(i => pb_in(i),   o => pb(i));
   -- end generate;
   -- loop1 : for i in 0 to 7 generate
   -- led_obuf    : obuf_lvcmos33     port map(i => led(i),   o => led_out(i));
   -- digit_obuf    : obuf_lvcmos33     port map(i => seg(i),   o => seg_out(i));
   -- sw_ibuf    : ibuf_lvcmos33     port map(i => sw_in(i),   o => sw(i));
   -- end generate;

   -- generates a 1 kHz signal from a 50Mhz signal
   process (clk50, reset)
      variable khertz_count : integer;
   begin
      if reset = '1' then
         khertz_count := 0;
         khertz_en <= '0';
      elsif clk50'event and clk50 = '1' then

            khertz_count := khertz_count + 1;
            if khertz_count = 50000 then -- "1111101000" then
               khertz_en <= '1';
               khertz_count := 0; -- (others => '0');
            else
               khertz_en <= '0';
            end if;

      end if;
   end process;

   -- shows how to multiplex outputs time counter to 7-segment display
   -- display the content of hexint into the 4digit display
   -- alternatively show 1 digit per time, with refresh rate of 1K hertz.
   process (clk50, reset)
      variable cd    : std_logic_vector(1 downto 0);
      variable curr  : std_logic_vector(3 downto 0);
      variable first : std_logic;
      variable dp    : std_logic := '1';
   begin

      if reset = '1' then
         seg <= (others => '1');
         digit <= (others => '1');
         cd := "00";
         first := '0';
         curr := (others => '0');
      elsif clk50'event and clk50 = '1' then

         if khertz_en = '1' then
            cd := cd + 1;
         end if;

         case cd is
            when "00" =>   curr := hexint(3 downto 0);   digit <= "1110";
            when "01" =>   curr := hexint(7 downto 4);   digit <= "1101";
            when "10" =>   curr := hexint(11 downto 8);  digit <= "1011";
            when others => curr := hexint(15 downto 12); digit <= "0111";
         end case;

         if first = '1' then
            case curr is
                              --                   6543210
               when x"0" => seg <= "0000001" & dp;
               when x"1" => seg <= "1001111" & dp;  --        6
               when x"2" => seg <= "0010010" & dp;  --       ---
               when x"3" => seg <= "0000110" & dp;  --    1 |   | 5
               when x"4" => seg <= "1001100" & dp;  --       -0-
               when x"5" => seg <= "0100100" & dp;  --    2 |   | 4
               when x"6" => seg <= "0100000" & dp;  --       ---
               when x"7" => seg <= "0001111" & dp;  --        3
                              --                   6543210
               when x"8" => seg <= "0000000" & dp;  --
               when x"9" => seg <= "0000100" & dp;
               when x"A" => seg <= "0001000" & dp;
               when x"B" => seg <= "1100000" & dp;
               when x"C" => seg <= "0110001" & dp;
               when x"D" => seg <= "1000010" & dp;
               when x"E" => seg <= "0110000" & dp;
               when OTHERS => seg <= "0111000" & dp;
            end case;
         else
            -- PASS HERE ONLY ONCE FOR ANY RESET RELEASE
            seg <= (others => '1'); -- tutto spento
         end if;

         first := '1';

      end if;
   end process;

end arch_display7seg;



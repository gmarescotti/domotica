----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- use IEEE.STD_LOGIC_ARITH.ALL;
-- use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Xilinx primitives in this code.
Library UNISIM;
use UNISIM.vcomponents.all;

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
   
   -- converte il clock ref del serdes da 30.7MHz a ~1MHz buono per le seriali
   -- 30,7692MHz / 32 = 0.961 MHz
   process(clkref_serdes_loc, reset) 
      variable clk_counter : integer := 0;
      constant CLK_FRACTION : integer := 32;
   begin
      if reset = '1' then
         clk_counter := 0;
         serial_clock <= '0';
      else 
	 if rising_edge(clkref_serdes_loc) then
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

   -- DCM: Digital Clock Manager Circuit
   -- Spartan-3
   -- Xilinx HDL Language Template, version 11.1
   -- Genera un clock = clk_in x 8 / 13 => 50MHz x 8 / 13 = 30,7692MHz

   gen1 : if is_xilinx = 1 generate

      DCM_inst : DCM
      generic map (
           	  CLKDV_DIVIDE => 2.0, --  Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
           			       --     7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
           	  CLKFX_DIVIDE => 13,  --  Can be any interger from 1 to 32
           	  CLKFX_MULTIPLY => 8, --  Can be any integer from 1 to 32
           	  CLKIN_DIVIDE_BY_2 => FALSE, --  TRUE/FALSE to enable CLKIN divide by two feature
           	  CLKIN_PERIOD => 20.0,          --  Specify period of input clock
           	  CLKOUT_PHASE_SHIFT => "NONE", --  Specify phase shift of NONE, FIXED or VARIABLE
           	  CLK_FEEDBACK => "NONE", -- "1X",         --  Specify clock feedback of NONE, 1X or 2X
           	  DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", --  SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
           						 --     an integer from 0 to 15
           	  DFS_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for frequency synthesis
           	  DLL_FREQUENCY_MODE => "LOW",     --  HIGH or LOW frequency mode for DLL
           	  DUTY_CYCLE_CORRECTION => TRUE, --  Duty cycle correction, TRUE or FALSE
           	  FACTORY_JF => X"C080",          --  FACTORY JF Values
           	  PHASE_SHIFT => 0,        --  Amount of fixed phase shift from -255 to 255
           	  SIM_MODE => "SAFE", -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation
           			      -- Design Guide" for details
           	  STARTUP_WAIT => FALSE) --  Delay configuration DONE until DCM LOCK, TRUE/FALSE
      port map (
                  -- CLK0 => clk_out,     -- 0 degree DCM CLK ouptput
                  -- CLK180 => CLK180, -- 180 degree DCM CLK output
                  -- CLK270 => CLK270, -- 270 degree DCM CLK output
                  -- CLK2X => CLK2X,   -- 2X DCM CLK output
                  -- CLK2X180 => CLK2X180, -- 2X, 180 degree DCM CLK out
                  -- CLK90 => CLK90,   -- 90 degree DCM CLK output
                  -- CLKDV => CLKDV,   -- Divided DCM CLK out (CLKDV_DIVIDE)
                  CLKFX => clkref_serdes_loc,   -- DCM CLK synthesis out (M/D)
           				 -- CLKFX180 => CLKFX180, -- 180 degree CLK synthesis out
           				 -- LOCKED => LOCKED, -- DCM LOCK status output
           				 -- PSDONE => PSDONE, -- Dynamic phase adjust done output
           				 -- STATUS => STATUS, -- 8-bit DCM status bits output
           				 -- CLKFB => clk_out,   -- DCM clock feedback
                  CLKIN => clk_in,   -- Clock input (from IBUFG, BUFG or DCM)
           			 -- PSCLK => PSCLK,   -- Dynamic phase adjust clock input
           			 -- PSEN => PSEN,     -- Dynamic phase adjust enable input
           			 -- PSINCDEC => PSINCDEC, -- Dynamic phase adjust increment/decrement
           	  RST => reset        -- DCM asynchronous reset input
               );

      -- OBUFDS: Differential Output Buffer
      -- Spartan-3/3E/3A
      -- Xilinx HDL Language Template, version 11.1
      OBUFDS_inst : OBUFDS
      generic map (
           	  IOSTANDARD => "DEFAULT")
      port map (
                  O => clkref_serdes_p,     -- Diff_p output (connect directly to top-level port)
                  OB => clkref_serdes_n,    -- Diff_n output (connect directly to top-level port)
                  I => clkref_serdes_loc        -- Buffer input 
               );
   end generate;

end Behavioral;


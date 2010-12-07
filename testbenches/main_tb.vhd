--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:52:04 11/13/2010
-- Design Name:   
-- Module Name:   main_tb.vhd
-- Project Name: 
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

USE WORK.modules.all;

use IEEE.std_logic_textio.all;
use STD.textio.all;
 
ENTITY main_tb IS
END main_tb;
 
ARCHITECTURE behavior OF main_tb IS 
 
   -- Component Declaration for the Unit Under Test (UUT)
 
   COMPONENT main
   GENERIC ( test_bench : natural := 1 );
   PORT(
	  -- SFP HARDWARE
	  los         : in std_logic;
	  rate_select : out std_logic;
	  t_dis       : out std_logic; -- SWITCH ON LASER WHEN 0
	  t_fault     : in std_logic;
	  mod_def     : inout std_logic_vector(2 downto 0);

	  -- UTILITY
	  led_out     : out std_logic_vector(7 downto 0);
	  tasto       : in std_logic_vector(7 downto 0);
	  digit_out   : out std_logic_vector(3 downto 0);
	  seg_out     : out std_logic_vector(7 downto 0);

	  -- SFP I2C SERIAL
	  i2c_sda	  : inout std_logic;
	  i2c_scl	  : out std_logic;

	  -- SERDES MDIO SERIAL
	  mdio_sda    : inout std_logic := 'Z';
	  mdio_scl    : out std_logic;

	  -- SERDES CLK_REF
	  clkref_serdes_p: out std_logic;
	  clkref_serdes_n: out std_logic;

	  -- PLASMA CPU PINS
	  clk_in      : in std_logic;
	  reset       : in std_logic;
	  uart_read   : in std_logic;
	  uart_write  : out std_logic

        );
   END COMPONENT;
    
   signal clkref_serdes_p : std_logic;
	
   --Inputs
   signal los : std_logic := '0';
   signal t_fault : std_logic := '0';
   signal tasto : std_logic_vector(7 downto 0) := (others => '0');
   signal clk_in : std_logic := '0';
   signal reset : std_logic := '1';
   signal uart_read : std_logic := '0';

	--BiDirs
   signal mod_def : std_logic_vector(2 downto 0);
   signal mdio_sda : std_logic;
   signal mdio_scl : std_logic;
   signal i2c_sda : std_logic;
   signal i2c_scl : std_logic;

 	--Outputs
   signal rate_select : std_logic;
   signal t_dis : std_logic;
   signal led : std_logic_vector(7 downto 0);
   signal uart_write : std_logic;

   -- UART
   signal dato_ricevuto : std_logic;
   signal data_read_back : std_logic_vector(31 downto 0);

   -- clocks
   signal serial_clock 	: std_logic;
   signal clkref_serdes : std_logic;
   
BEGIN

   -- Instantiate the Unit Under Test (UUT)
   uut: main 
	GENERIC MAP (
	  test_bench => 1
	) PORT MAP (
          los => los,
          rate_select => rate_select,
          t_dis => t_dis,
          t_fault => t_fault,
          mod_def => mod_def,

          led_out => led,
          tasto => tasto,

          mdio_sda => mdio_sda,
          mdio_scl => mdio_scl,
          i2c_sda => i2c_sda,
          i2c_scl => i2c_scl,

	  clkref_serdes_p => clkref_serdes_p,

          clk_in => clk_in,
          reset => reset,
          uart_read => uart_read,
          uart_write => uart_write
        );

   -- SERDES-TESTER: MDIO serial slave
   t1 : mdio_slave
   port map(
      reset,
      serial_clock, mdio_sda,
      data_read_back, X"1968", -- data_write_back,
      dato_ricevuto
   );

   -- RI-Genero tutti i clock del progetto all'interno del testbench
   -- cosi' non disturbo quelli dentro main
   clks21: myclocks
   port map(
          reset,
          open, open,
          serial_clock, clkref_serdes,
          clk_in
   );

   urt1: pseudo_uart
   port map ( clk_in, reset, uart_read, uart_write);

   -- Clock process definitions
   clk_in_process : process
   begin
	clk_in <= '0';
	wait for clk_in_period/2;
	clk_in <= '1';
	wait for clk_in_period/2;
   end process;
 
   -- RESET PROCEDURE
   rst1: process
   begin
      reset <= '1';
      wait for 100 us;
      reset <= '0';
assert false report "FINE RESET" severity note;
      wait;
   end process;
END;

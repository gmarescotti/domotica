-- file_io.vhdl   write and read disk files in VHDL
--                typically used to load RAM or ROM, supply test input data, 
--                record test output (possibly for further analysis)

entity file_io is  -- test bench
end file_io;

library IEEE;
use IEEE.std_logic_1164.all;
use STD.textio.all;
use IEEE.std_logic_textio.all;

architecture test of file_io is
  signal done : std_logic := '0';  -- flag set when simulation finished
  signal xx : std_logic_vector(7 downto 0) := "11001010";
  signal y : integer := 123;
begin  -- test of file_io
  done <= '1' after 5 sec;        -- probably set via logic, not time

--   read_file:
--     process    -- read file_io.in (one time at start of simulation)
--       -- file my_input : TEXT open READ_MODE is "file_io.in";
--       variable my_line : LINE;
--       variable my_input_line : LINE;
--       variable c : std_ulogic := '1';
--     begin
--       write(my_line, string'("reading file"));
--       writeline(output, my_line);
--       loop
--         exit when endfile(input);
--         readline(input, my_input_line);
--         read(my_input_line, c);
--         -- process input, possibly set up signals or arrays
--         writeline(output, my_input_line);  -- optional, write to std out
--       end loop;
--       wait; -- one shot at time zero,
--     end process read_file;

  write_file:
    process (done) is    -- write file_io.out (when done goes to '1')
      -- file my_output : TEXT open WRITE_MODE is "file_io.out";
      -- above declaration should be in architecture declarations for multiple
      variable my_line : LINE;
      variable my_output_line : LINE;
    begin
      if done='1' then
        write(my_line, string'("writing file"));
        writeline(output, my_line);
        write(my_output_line, string'("output from file_io.vhdl"));
        writeline(output, my_output_line);
        write(my_output_line, done);    -- or any other stuff
        write(my_output_line, done);    -- or any other stuff
        write(my_output_line, xx);    -- or any other stuff
        write(my_output_line, y);    -- or any other stuff
        writeline(output, my_output_line);
      end if;
    end process write_file;
end architecture test; -- of file_io
-- standard output
  -- reading file
  -- line one of file_io.in
  -- just showing that file
  -- can be read.
  -- writing file
-- file_io.out
  -- output from file_io.vhdl
  -- 1





set fd [ open "| ./a.out" r+ ]

puts "Hello world"

puts $fd "ciao"
flush $fd
 
gets $fd line
puts "ho letto: $line"

after 1000

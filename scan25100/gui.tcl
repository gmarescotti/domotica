#!/usr/bin/wish

global reg

source bitmap.tcl

# parray reg
# 9,bit,D5-D4,name

######################################
toplevel .main

foreach address [ lsort -dictionary [ array names reg -regexp {^[^,]+$} ] ] {
   puts "Address: $address"
   foreach key [ array names reg -regexp "$address,bit,.*,name" ] {
      if { $reg($key) == "Reserved" } continue
      puts $reg($key)
   }
}




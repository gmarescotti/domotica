#!/usr/bin/wish

global reg
source bitmap.tcl

# parray reg
# 9,bit,D5-D4,name

######################################
# toplevel .main

proc print_all_bitreg {} {
   foreach address [ lsort -dictionary [ array names reg -regexp {^[^,]+$} ] ] {
      puts "Address: $address"
      foreach key [ array names reg -regexp "$address,bit,.*,name" ] {
         if { $reg($key) == "Reserved" } continue
         puts $reg($key)
      }
   }
}


# set ::list_addrs [ lsort -dictionary [ array names reg -regexp {^[^,]+$} ] ]

foreach addr [ lsort -dictionary [ array names reg -regexp {^[^,]+$} ] ] {
   lappend ::list_addrs "$addr: $reg($addr)"
}
   

source /home/giulio/sources/vtcl-1.6.0/Projects/uno/main.tcl


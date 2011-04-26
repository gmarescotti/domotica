#!/usr/bin/wish

global reg

# Carico reg con i registri SCAN25100 National
source bitmap.tcl

# parray reg
# 9,bit,D5-D4,name

######################################
# proc print_all_bitreg {} {
#    foreach address [ lsort -dictionary [ array names reg -regexp {^[^,]+$} ] ] {
#       puts "Address: $address"
#       foreach key [ array names reg -regexp "$address,bit,.*,name" ] {
#          if { $reg($key) == "Reserved" } continue
#          puts $reg($key)
#       }
#    }
# }

# source GUI/main.tcl

parray reg
set reg(2,value) 21
set reg(3,bit,D12,value) 999

# vwait ar
# exit


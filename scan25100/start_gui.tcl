#!/usr/bin/tclsh

# LOAD REGISTER MANAGER FOR SCAN25100 National
source bitmap.tcl

# LOAD COMMUNICATION FEATURES WITH SPARTAN3
source com.tcl

#################################################

bitmap::riempi_reg mappa

#################################################
proc reg_changed { address value } {
   puts "WRITE $address ----------> $value"
   com::mdio write_address $address
   com::mdio write_data $value
}

proc reg_needed { address } {
   global mappa
   if { $address == "-1" } {
      set address $mappa(last_address)
      set mappa($address,value) [ com::mdio read_inc ]
      puts "READ-INC $address: 0x[ format %X $mappa($address,value) ]"
      return
   }
   com::mdio write_address $address
   set mappa($address,value) [ com::mdio read ]
   puts "READ $address: 0x[ format %X $mappa($address,value) ]"
}

#################################################

com::init

bitmap::register_write_callback "reg_changed"
bitmap::register_read_callback "reg_needed"

# parray mappa
# set mappa(2,value) 0x21
# set mappa(3,bit,D9-D4,value) 0x3F
# set mappa(9,bit,D15-D11,value) 0x1E

# set mappa(4,value) "toberead"

# set mappa(0,value) "toberead"
# set mappa(1,value) "toberead"
# set mappa(2,value) "toberead"

set mappa(-1,value) "toberead"

# Launch GUI
# source GUI/main.tcl

# vwait ar
# exit


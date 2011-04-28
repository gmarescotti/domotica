#!/usr/bin/tclsh

# LOAD REGISTER MANAGER FOR SCAN25100 National
source bitmap.tcl

# LOAD COMMUNICATION FEATURES WITH SPARTAN3
source com.tcl

#################################################

bitmap::riempi_reg mappa

#################################################
proc leggi_tutti_registri {} {
   global mappa
   com::mdio write_address 0
   for { set i 0 } { $i <= $mappa(last_address) } { incr i } {
      set mappa($i,value) [ com::mdio read_inc ]
   }
}

#################################################
com::init

# parray mappa
set mappa(2,value) 0x21
set mappa(3,bit,D9-D4,value) 0x3F
set mappa(9,bit,D15-D11,value) 0x1E

# Launch GUI
source GUI/main.tcl

# vwait ar
# exit


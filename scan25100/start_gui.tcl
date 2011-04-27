#!/usr/bin/tclsh

# LOAD REGISTER MANAGER FOR SCAN25100 National
source bitmap.tcl

# LOAD COMMUNICATION FEATURES WITH SPARTAN3
lappend argv -nostandalone ;# Skip away menu loop
source com.tcl

#################################################

bitmap::riempi_reg mappa

#################################################
source GUI/main.tcl

parray mappa
set mappa(2,value) 21
set mappa(3,bit,D9-D4,value) 3F
set mappa(9,bit,D15-D11,value) 1E

# vwait ar
# exit


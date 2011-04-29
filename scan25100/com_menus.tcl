#!/usr/bin/tclsh

source com.tcl
#######################################################

proc test_mdio { { code "" } } {

   if { $code == "" } {
      manage_menu "mdio" {
	 {"read inc" "test_mdio readinc"}
	 {"read" "test_mdio read"}
	 {"write address" "test_mdio write_address"}
	 {"write data" "test_mdio write_data"}
	 {"read buffer" "test_mdio readbuffer"}
      }
      return
   }

   switch -exact -- $code {
      readinc {
	 puts -nonewline "Read-Inc($com::mdio_address): "
	 flush stdout
	 puts "[ format %x [ com::mdio read_inc ] ]"
      }
      read {
	 puts -nonewline "Read($com::mdio_address): "
	 flush stdout
	 puts "[ format %x [ com::mdio read ] ]"
      }
      readbuffer {
	 puts -nonewline "quanti: "
	 flush stdout
	 gets stdin quanti
	 for { set i 0 } { $i < $quanti } { incr i } {
	    puts -nonewline "reg($com::mdio_address): "
	    flush stdout
	    puts "[ format %x [ com::mdio read_inc ] ]"
	 }
      }
      write_address {
	 puts -nonewline "new address ($com::mdio_address): "
	 flush stdout
	 set address ""
	 gets stdin address
	 if [ string is integer $address ] {
	    com::mdio write_address $address
	 } else {
	    puts "Wrong address: $address"
	 }
      }
      write_data {
	 puts -nonewline "data ($com::mdio_address): "
	 flush stdout
	 set data ""
	 gets stdin data
	 if [ string is integer $data ] {
	    com::mdio write_data $data
	 } else {
	    puts "Wrong data: $data"
	 }
      }
      default {
	 puts "Unknown code: $code"
      }
   }
}

#######################################################
proc test_i2c {} {
   puts "TEST I2C..."

   set value [ com::i2c current_address_read ]
   puts "CURRENT ADDRESS READ (SB:???): [format %x $value ]"

   # puts "BYTE WRITE 0x19 0x81"
   # i2c byte_write 0x19 0x81
   # after 1000

   # set value [ i2c current_address_read ]
   # puts "CURRENT ADDRESS READ (SB:): [format %x $value ]"

   set value [ com::i2c random_read 0x0 ]
   puts "RANDOM READ IN 0x0 (SB:): [format %x $value ]"
   set value [ com::i2c current_address_read ]
   puts "RANDOM READ IN 0x1 (SB:): [format %x $value ]"
   set value [ com::i2c current_address_read ]
   puts "RANDOM READ IN 0x2 (SB:): [format %x $value ]"
   set value [ com::i2c current_address_read ]
   puts "RANDOM READ IN 0x3 (SB:): [format %x $value ]"
   set value [ com::i2c current_address_read ]
   puts "RANDOM READ IN 0x4 (SB:): [format %x $value ]"
}

#######################################################

set menu_items {
   {"test mdio" test_mdio}
   {"test i2c" test_i2c}
   {"test clocks" com::test_clocks}
   {"test codes" com::test_codes}
}

proc manage_menu { prompt menu_items } {
   lappend menu_items {"back" return}

   while true {
      set i 0
      foreach item $menu_items {
         puts "$i: [ lindex $item 0 ]"
	 incr i
      }
      puts -nonewline "$prompt> "
      flush stdout
      set x ""
      gets stdin x
      # if [ catch {
         eval [ lindex [ lindex $menu_items $x ] 1 ]
      # } err ] {
	    # puts "Unknown menu: $err"
      # }
   }
}

################################################
puts "Running standalone"

com::init

manage_menu "root" $menu_items

puts "END OF FILE"

com::close

#!/usr/bin/tclsh

# 01: invio dato in MDIO
#   TX:
#     1: opcode (bit 1-0) -- 00: Address 10: Read-Inc 01: Write
#     2,3: data write (HI,LO)
#   RX:
# 02: lettura dato da MDIO
#   TX:
#   RX:
#     0,1: data read (HI,LO)
# 03: start/stop calcolo clocks
#   TX:
#     0: (01 -> inizia la procedura di calcolo
#         10 -> legge refclock
#         11 -> legge clkclock
#         12 -> legge serial clock
#   RX:
#     0,1: clock letto (HI,LO)
# 
# 78: Autotest
#   TX:
#     0,1,2,3,4,5: dati che mi devo ritrovare in rx
#   RX:
#     5,4,3,2,1,0: Echo dei dati tx

set list_special_characters {0 1 10 13} ;# EOF SPECIALCHAR LF CR

#######################################################
proc invia { args } {
   global verbose
   global tb
   global list_special_characters

   foreach dato $args {
      # converte in decimale ( se in forma 0x.. e esegue eventuali oper.)
      set num [ expr ($dato) & 0xFF ]

      if { [ lsearch -integer $list_special_characters $num ] != -1 } {
	 puts -nonewline $tb "\x01"
         if $verbose { puts "STO INVIANDO CODE 01" }
	 set num [ expr ~$num & 0xFF ]
      }

      set coded [ binary format c $num ]
      if $verbose { puts "STO INVIANDO [ format %x $num ]" }
      puts -nonewline $tb $coded

      update
   }
   puts -nonewline $tb "\x0a"
   # puts $tb ""
   # flush $tb
}

#######################################################
proc ricevi { command_check { onenumber false } } {
   global verbose
   global tb
   set ret ""

   if $verbose { puts "RICEZIONE:" }
   if { [ gets $tb line ] <= 0 } {
      puts stderr "NO DATA"
      return $ret
   }
   if { [ binary scan $line c* vars ] == 0 } {
      puts stderr "NO SCAN"
      return $ret
   }

   set command [ lindex $vars 0 ]
   set vars [ lrange $vars 1 end ]

   if [ expr $command != $command_check ] {
      puts stderr "Command received is different: $command != $command_check"
   } else {
      if $verbose { puts stderr "Command OK." }
   }

   set flag_special 0
   foreach num $vars {
      set num [ expr $num & 0xFF ]

      if $verbose { puts "RICEVUTO: [ format %x $num ]" }
      if { $flag_special == 1 } {
	 set num [ expr ~$num & 0xFF ]
      } else {
	 if { $num == 1 } {
	    set flag_special 1
	    continue
         }
      }
      set flag_special 0
      if $onenumber {
         append ret [ format %.2x $num ]
      } else {
         lappend ret 0x[ format %.2x $num ]
      }
   }
   if $verbose { puts "FINE RICEZIONE" }
   update

   if $onenumber {
      return [ expr "0x$ret" ]
   }
   return $ret
}

#######################################################
proc init { args } {
   global tb argc argv
   if { [ lsearch "$argv" "-tty" ] >= 0 } {
      set tb [ open "/dev/ttyUSB0" r+] ; # "RDWR NOCTTY NONBLOCK" ] ;#
      # fconfigure $tb -mode 57600,n,8,1 -handshake none -translation binary -blocking 1
      fconfigure $tb -mode 57600,n,8,1 -handshake none -translation binary -buffering none -blocking true
      puts "OPENED ttyUSB0: $tb!"
   } else {
      # set tb [ open "| ./main_tb 2>log.txt" r+ ]
      set tb [ open "| ./main_tb 2> /dev/stderr" r+ ]
      ## set tb [ open "| ./main_tb" r+ ]
      # set tb [ open "| ./prova.sh" r+ ]
      fconfigure $tb -translation binary -buffering line ;#  line none all

      ## set f [ open log.txt r ]
      ## fileevent $f readable "loggami $f"
   }
   after 300
   # flush $tb

}

# proc loggami { f args } {
#    puts -nonewline "\033\[31m" ;# ROSSO
#    puts -nonewline "$f[ gets $f ]"
#    puts "\033\[0m" ;# DEFAULT
# }

#######################################################
proc ascii { args } {
   set ret ""
   foreach ch $args {
      lappend ret [ scan $ch %c ]
   }
   return $ret
}

#######################################################
proc read_callback { args } {
   global tb
   if ![eof $tb] {
      puts "[ gets $tb ]"
   }
}

proc testa_tty {} {
   global tb
   fileevent $tb readable read_callback
   polling


   while ![ eof stdin ] {
      gets stdin line
      puts $tb "$line"
      # flush $tb
      # puts "inviato: $line"
      # puts "READ: [ gets $tb ]"
      update
      update
   }
   exit
}

proc polling {} {
   update
   after 1000 polling
   # puts "POLL.."
}
#######################################################
proc test_clocks { } {
   puts "TESTING CLOCKS...."

   invia 0x61 0x61	0x31;# START CLOCK SUM
   ricevi 0x61

   after 10 ;# msec
   invia 0x61 0x61	0x30;# STOP CLOCK SUM
   ricevi 0x61
  
   # PERDO UN PO' DI TEMPO PER IL SIMULATORE BLOCCATO SULLA GETLINE
   # PIUTTOSTO CHE SUL CALCOLO DEI CLOCKS... 
   # invia 0x78 0x61 0x62 0x63 0x64
   # ricevi 0x78

   invia 0x61 0x63 ;# CLKCLOCK
   puts "CLKCLOCK= [ ricevi 0x61 true ]"

   invia 0x61 0x62 ;# REFCLOCK
   # after 2000
   puts "REFCLOCK= [ ricevi 0x61 true ]"

   invia 0x61 0x64 ;# SERIALCLOCK
   # after 2000
   puts "SERIALCLOCK= [ ricevi 0x61 true ]"

   invia 0x61 0x65 ;# SYSCLK
   # after 2000
   puts "SYSCLK= [ ricevi 0x61 true ]"
}

#######################################################
proc test_codes { } {
   global list_special_characters
   puts "TESTING CODES $list_special_characters USING ECHO..."
   # invia ascii("x") 0x61 0x62 0x63 0x64 0x65
   eval invia [ ascii "x" ] $list_special_characters 0x33
   set ret [ ricevi 0x78 ]
   puts "RET: $ret"
}

#######################################################
proc i2c { op args } {
   switch -exact -- $op {
      "byte_write" {
         eval invia 0x63 0x61 $args
      }
      "random_read" {
         eval invia 0x63 0x62 $args
      }
      "current_address_read" {
         eval invia 0x63 0x63
      }
      default {
         puts "ERROR: WRONG op: $op"
	 return
      }
   }
   after 100
   ricevi 0x63 ;# ACKNOWLEDGE INVIO

   # ASPETTA CONVERSION DONE
   after 1000

   # LEGGI ERROR_CODE
   eval invia 0x63 0x65
   set err [ ricevi 0x63 ]

   if { $err != 0 } {
      puts "\033\[31m######ERROR_CODE: $err#######\033\[0m"
   }

   if [ string match "*read" $op ] {
      # LEGGI DATO
      eval invia 0x63 0x64
      after 1000
      return [ ricevi 0x63 true ] ;# TRUE
   }
}

#######################################################
proc splitta_2x { num } {
   set numx [ format %.4x $num ]
   set ret 0x[ string range $numx 0 1 ]
   return [ concat $ret 0x[ string range $numx 2 3 ] ]
}

proc mdio { op args } {
   # invia false [ ascii "c" ] $opcode "$data4>>8" "$data4&0xFF"
   # invia false 0x62 0x61 :# invio dato in MDIO
   switch -exact -- $op {
      "write_address" {
         eval invia 0x62 0x61 [ splitta_2x $args ]
      }
      "write_data" {
         eval invia 0x62 0x62 [ splitta_2x $args ]
      }
      "read_inc" {
         eval invia 0x62 0x63
      }
      "read" {
         eval invia 0x62 0x64
      }
      default {
         puts "ERROR: WRONG op: $op"
	 return
      }
   }
   ricevi 0x62 ;# ACKNOWLEDGE INVIO

   # ASPETTA CONVERSION DONE
   after 100

   # LEGGI ERROR_CODE
   eval invia 0x62 0x71
   set err [ ricevi 0x62 ]

   if { $err != 0 } {
      puts "\033\[31m######ERROR_CODE: $err#######\033\[0m"
   }

   if [ string match "read*" $op ] {
      # after 300
      # LEGGI DATO
      eval invia 0x62 0x70
      # after 1000
      return [ ricevi 0x62 true ] ;# TRUE
   }
}

#######################################################
set mdio_address 0

proc test_mdio { { code "" } } {
   global mdio_address

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
	 puts -nonewline "Read-Inc($mdio_address): "
	 flush stdout
	 puts "[ format %x [ mdio read_inc ] ]"
	 incr mdio_address
      }
      read {
	 puts -nonewline "Read($mdio_address): "
	 flush stdout
	 puts "[ format %x [ mdio read ] ]"
      }
      readbuffer {
	 puts -nonewline "quanti: "
	 flush stdout
	 gets stdin quanti
	 for { set i 0 } { $i < $quanti } { incr i } {
	    puts -nonewline "reg($mdio_address): "
	    flush stdout
	    puts "[ format %x [ mdio read_inc ] ]"
	    incr mdio_address
	 }
      }
      write_address {
	 puts -nonewline "new address ($mdio_address): "
	 flush stdout
	 set address ""
	 gets stdin address
	 if [ string is integer $address ] {
	    mdio write_address $address
	    set mdio_address $address
	 } else {
	    puts "Wrong address: $address"
	 }
      }
      write_data {
	 puts -nonewline "data ($mdio_address): "
	 flush stdout
	 set data ""
	 gets stdin data
	 if [ string is integer $data ] {
	    mdio write_data $data
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

   set value [ i2c current_address_read ]
   puts "CURRENT ADDRESS READ (SB:???): [format %x $value ]"

   # puts "BYTE WRITE 0x19 0x81"
   # i2c byte_write 0x19 0x81
   # after 1000

   # set value [ i2c current_address_read ]
   # puts "CURRENT ADDRESS READ (SB:): [format %x $value ]"

   set value [ i2c random_read 0x0 ]
   puts "RANDOM READ IN 0x0 (SB:): [format %x $value ]"
   set value [ i2c current_address_read ]
   puts "RANDOM READ IN 0x1 (SB:): [format %x $value ]"
   set value [ i2c current_address_read ]
   puts "RANDOM READ IN 0x2 (SB:): [format %x $value ]"
   set value [ i2c current_address_read ]
   puts "RANDOM READ IN 0x3 (SB:): [format %x $value ]"
   set value [ i2c current_address_read ]
   puts "RANDOM READ IN 0x4 (SB:): [format %x $value ]"
}

#######################################################
set verbose false
# set verbose true

init

#######################################################

set menu_items {
   {"test mdio" test_mdio}
   {"test i2c" test_i2c}
   {"test clocks" test_clocks}
   {"test codes" test_codes}
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

#######################################################
manage_menu "root" $menu_items

puts "END OF FILE"

if [ catch "close $tb" err ] {
   puts "ERROR Closing: $err"
}


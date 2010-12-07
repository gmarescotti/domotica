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

set list_special_characters { 0 1 10 13 } ;# EOF SPECIALCHAR LF CR
#######################################################
proc invia { { verbose true } args } {
   global tb
   global list_special_characters

   foreach dato $args {
      # converte in decimale ( se in forma 0x.. e esegue eventuali oper.)
      set num [ expr ($dato) & 0xFF ]

      if { [ lsearch -integer $list_special_characters $num ] != -1 } {
	 puts -nonewline $tb "\x01"
	 set num [ expr ~$num & 0xFF ]
      }

      set coded [ binary format c $num ]
      if $verbose { puts "STO INVIANDO $num" }
      puts -nonewline $tb $coded
   }
   puts -nonewline $tb "\x0a"
   # puts $tb ""
   # flush $tb
}

proc ricevi { command_check { verbose true } { onenumber false } } {
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
   }

   set flag_special 0
   foreach num $vars {
      set num [ expr $num & 0xFF ]

      if $verbose { puts "RICEVUTO: $num" }
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
         lappend ret [ format %x $num ]
      }
   }
   if $verbose { puts "FINE RICEZIONE" }

   if $onenumber {
      return [ expr "0x$ret" ]
   }

   return $ret
}

#######################################################
proc mdio_send { opcode data4 } {
   invia false 0x01 $opcode "$data4>>8" "$data4&0xFF"
}

proc init { args } {
   global tb argc argv
   if { [ lsearch "$argv" "-tty" ] >= 0 } {
      set tb [ open "/dev/ttyUSB0" r+] ; # "RDWR NOCTTY NONBLOCK" ] ;#
      # fconfigure $tb -mode 57600,n,8,1 -handshake none -translation binary -blocking 1
      fconfigure $tb -mode 57600,n,8,1 -handshake none -translation binary -buffering none -blocking 1
      puts "OPENED ttyUSB0: $tb!"
   } else {
      set tb [ open "| ../main_tb 2>cicci.txt" r+ ]
      # set tb [ open "| ./prova.sh" r+ ]
      fconfigure $tb -translation binary -buffering line ;#  line none all
   }
   after 300
   # flush $tb
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
proc test_clocks {} {
   puts "TESTING CLOCKS...."

   invia false 0x61 0x61	;# START CLOCK SUM
   ricevi 0x61 false
  
   # PERDO UN PO' DI TEMPO PER IL SIMULATORE BLOCCATO SULLA GETLINE
   # PIUTTOSTO CHE SUL CALCOLO DEI CLOCKS... 
   invia false 0x78 8 1 2 3 4 5
   ricevi 0x78 false

   invia false 0x61 0x63 ;# CLKCLOCK
   puts "CLKCLOCK= [ ricevi 0x61 false true ]"

   invia false 0x61 0x62 ;# REFCLOCK
   # after 2000
   puts "REFCLOCK= [ ricevi 0x61 false true ]"

   invia false 0x61 0x64 ;# SERIALCLOCK
   # after 2000
   puts "SERIALCLOCK= [ ricevi 0x61 false true ]"
}

#######################################################

# mdio_send 0 0x1234 ;# Set mdio address 1234

init
# after 3500

test_clocks

# testa_tty
#
# update
# after 4500
# update

puts "END OF FILE"

if [ catch "close $tb" err ] {
   puts "ERROR Closing: $err"
}



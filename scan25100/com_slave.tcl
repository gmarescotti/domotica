#!/usr/bin/tclsh

fconfigure stdin -translation binary -buffering line ;#  line none all

fileevent stdin readable read_callback

set NN 20

proc read_callback { args } {
   global NN
   gets stdin line
   switch -glob -- $line {
      "\x62\x71" {
         puts "\x62\x00"
      }
      "\x62\x70" {
         puts [ binary format c3 "0x62 0x00 $NN" ]
         incr NN
      }
      default {
         puts "$line"
      }
   }
}

vwait forever


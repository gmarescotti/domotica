#!/usr/bin/tclsh

fileevent stdin readable read_callback

proc read_callback { args } {
   gets stdin line
   switch -glob -- $line {
      "\x62\x71*" {
         puts "\x62\x00"
      }
      "\x62\x70*" {
         puts "\x62\x00\x05"
      }
      default {
         puts "$line"
      }
   }
   flush stdout
}

vwait forever


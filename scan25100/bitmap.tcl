set register_description {
Reserved
Address: 00h Value: 0000h
D15-D0 16'd0 Reserved - Reserved for future use. Returns undefined value when read.

Powerdown Control
Address: 01h Value: FFFFh
D15-D9 7'h7F Reserved - Reserved for future use. Returns undefined value when read.
D8 1'b1 RX PWDNB RW Receiver Powerdown: Writing a [0] to this bit places the receiver of the SCAN25100 into a low power mode.
D7-D1 7'h7F Reserved - Reserved for future use. Returns undefined value when read.
D0 1'b1 TX PWDNB RW Transmiter Powerdown: Writing a [0] to this bit places the transmiter of the SCAN25100 into a low power mode.

# 0Eh
OUI
Address: 02h Value: 2000h
D15-D0 16'h2000 OUI RO National Semiconductor identifier assigned by the IEEE.

# 0Fh
OUI +
Address: 03h Value: 5FE4h
D15-D10 6'h17 OUI[19:24] RO National Semiconductor identifier assigned by the IEEE.
D9-D4 6'h3E Part Number RO SCAN25100 device identifier (3Eh).
D3-D0 4'h4 Revision RO SCAN25100 revision number.

Reset
Address: 04h Value: FFFFh
D15-D9 7'h7F Reserved - Reserved for future use. Returns undefined value when read.
D8 1'b1 RX RESETB WC Receiver Reset: Writing [0] to this bit resets Rx control logic. Returns a value 1 after a few REFCLK cycles. If REFCLK is missing, the logic remains reset mode.
D7-D1 7'h7F Reserved - Reserved for future use. Undefined value returned when read.
D0 1'b1 TX PWDNB WC Transmiter Reset: Writing [0] to this bit resets Tx control logic. Returns a value 1 after a few REFCLK cycles. If REFCLK is missing, the logic remains reset mode.

Receive Equalization
Address: 05h Value: 0000h
D15 1'b0 LOF Bypass RW Disables LOF control to allow DCM when using a non-CPRI hyperframe length
D14-D2 13'd0 Reserved RW Reserved for future use. Returns undefined value when read.
D1-D0 2'd0 RX EQ RW Receive Equalization: Sets receive equalization when EQ[1:0] pins are low or floating.

Transmit De-Emphasis
Address: 06h Value: 2000h
D15-D8 8'h20 Hyperframe Size RW Sets non-CPRI hyperframe length.
D7-D2 6'd0 Reserved RW Reserved for future use. Returns undefined value when read.
D1-D0 2'b00 TX DE RW Transmit De-Emphasis: Sets transmit de-emphasis when PE[1:0] pins are low or floating.

Loopback Mode
Address: 07h Value: 0000h
D15-D4 12'h000 Reserved RW Reserved for future use. Returns undefined value when read.
D3-D0 4'b0000 Loopback RW Programs loopback mode
4'b0000 Normal operation (no loopback)
4'bxx10 Line loopback mode
4'bxxx1 Local loopback mode
4'b1000 Special local loopback mode
4'b0100 Special line loopback mode
4'b1100 Digital loopback mode
All other combinations place device in normal operation.

MDIO
Address: 08h Value: 8000h
D15-D14 2'b10 Reserved RO Required MDIO bits. Returns 2'b10 when read.
D13-D0 14'd0 Reserved - Reserved for future use. Returns undefined value when read.

BIST Control
Address: 09h Value: 0000h
D15-D11 5'h0 Reserved - Reserved for future use. Returns undefined value when read.
D10 1'b0 RX Output Enable RW Rx Output Enable: Writing a [1] value enables ROUT pins in BIST mode.
D9-D8 2'b00 BIST Enable RW [9] Rx BIST Verify, [8] Tx BIST Enable: Writing 1's to these bits enables BIST mode. Tx and Rx BIST modes may be operated independently.
D7-D6 2'b00 Reserved - Reserved for future use. Returns undefined value when read.
D5-D4 2'b00 RX BIST RW Rx BIST Pattern Detect
2b'00 CJPAT pattern (lane 0 per XAUI specification)
2b'01 PRWS10 (Pseudo Random Word Sequence) pattern
2b'10 Reserved pattern
2b'11 CJPAT pattern (lane 0 per XAUI specification)
D3-D2 2'b00 Reserved - Reserved for future use. Returns undefined value when read.
D1-D0 2'b00 TX BIST RW Tx BIST Pattern Generation
2b'00 CJPAT pattern (lane 0 per XAUI specification)
2b'01 PRWS10 (Pseudo Random Word Sequence) pattern
2b'10 Reserved pattern
2b'11 CJPAT pattern (lane 0 per XAUI specification)

Speed Mode
Address: 0Ah Value: 0000h
D15-D2 14'd0 Reserved - Reserved for future use. Returns undefined value when read.
D1-D0 2'd0 SPMODE RW Sets CPRI speed mode when SPMODE[1:0] pins are low or floating.

# CAmbiato 0100h in 1000h

BIST Status
Address: 0Bh Value: 1000h
D15-D13 3'd0 Reserved - Reserved for future use. Returns undefined value when read.
D12 1'b1 BIST Stopped RC BIST Stopped: A value [1] will occur when Rx BIST verifier has been stopped during a comparision.
D11 1'b0 BIST Error RC BIST Error: Returns a [1] value when the receive BIST verifier has been stopped or the BIST error count is greater than 10d'0. Returns a [0] value if no BIST errors.
D10 1'b0 BIST Detect RC Rx BIST verifier starts comparing the input data sequence after 3 cycles of properly aligned header sequences have been detected. A value of [1] implies that BIST verifier is checking the pattern. A read operation will NOT clear this bit nor will it reset the alignment of the pattern.
D9-D0 10'd0 Error Count RC This register displays the cumulative number of receive bit errors. The error count starts once a BIST pattern has been detected and the receive BIST verifier is enabled. This register counts a maximum of 10'h3FF errors and remains static as soon as BIST is stopped on the Rx verifier side. A read operation during the BIST enabled mode will clear the error count.

Reserved
Address: 0Ch Value: 0249h
D15-D0 16'h0249 Reserved RO Reserved for future use. Returns undefined value when read.

Run DCM
Address: 0Dh Value: 0000h
D15-D2 14'd0 Reserved WC Reserved for future use. Returns undefined value when read.
D1 1'b0 Reserved WC Reserved for future use. Returns undefined value when read.
D0 1'b0 Run DCM WC Writing a [1] runs DCM.

Loss of Frame (LOF)
Address: 10h Value: 0000h
D15-D9 7'd0 Reserved - Reserved for future use. Returns undefined value when read.
D8 1'd0 LOF Status RC CPRI loss of Frame (LOF) status. A [1] value indicates loss of CPRI frame. A [0] value indicates frame acquired.
D7-D0 8'h00 LOF Count RC Loss of frame count. The maximum count which can be accumulated in this register is 8'hFF.

Loss of Signal (LOS)
Address: 11h Value: 0000h
D15-D9 7'd0 Reserved - Reserved for future use. Returns undefined value when read.
D8 1'b0 LOS Status RC CPRI loss of signal (LOS) status. A value [1] indicates loss of frame.
D7-D0 8'd0 LOS Count RC Loss of signal count. The maximum count which can be accumulated in this register is 8'hFF.

Deserializer Loss of Lock
Address: 12h Value: 0000h
D15-D8 8'd0 Reserved - Reserved for future use. Returns undefined value when read.
D7-D0 8'd0 Loss of Rx Count RC Deserializer PLL loss of lock count since the last read operation of this register. The maximum count which can be accumulated in this register is 8'hFF. Note: During normal operation, receive PLL can go through multiple locking cycles before finally declaring lock. This is normal behavior.

Pin and Loss of Clock Status Registers
Address: 13h Value: 3015h
D15-D14 2'b00 SPMODE[1:0] RO SPMODE[1:0] pin status
D13 1'b1 TXPWDNB RO TXPWDNB pin status
D12 1'b1 RXPWDNB RO RXPWDNB pin status
D11 1'b0 Local Loopback RO A value [1] indicates local loopback is enabled
D10 1'b0 Line Loopback RO A value [1] indicates line loopback is enabled
D9 1'b0 Special Local Loopback RO A value [1] indicates special local loopback is enabled
D8 1'b0 Special Line Loopback RO A value [1] indicates special line loopback is enabled
D7 1'b0 Digital Loopback RO A value [1] indicates digital loopback is enabled
D6 1'b0 TX 10B mode RO
D5 1'b0 RX 10B mode RO
D4 1'b1 RXCLKMODEB RO Inverted value of RXCLKMODE pin.
D3-D2 2'b01 Reserved RO Reserved for future use. Returns undefined value when read.
D1 1'b0 Loss of Tx Clock RO This register bit indicates a loss of TXCLK. A value of 1 indicates the TXCLK is not present or not running in the currently programmed speed mode.
D0 1'b1 Loss of Rx Clock RO This register bit indicates a loss of TXCLK. A value of 1 indicates the RXCLK is not present or not running in the currently programmed speed mode. The RXCLK feature is only supported in SCAN25100 READ mode operation.

# cambiato default D6-D2 da "" a 5'b00000
# cambiato default D1 e D0 da "" a 1'b0
# cambiato default D7 da "" a 1'b0
Misc Status 2
Address: 14h Value: 0000h
D15-D8 8'd0 Reserved - Reserved for future use. Returns undefined value when read.
D7 1'b0 RXCDR Lock - Ready RO A value [0] indicates the deserializer PLL is locked
D6-D2 5'b00000 Reserved - Reserved for future use. Returns undefined value when read.
D1 1'b0 TXPLL Lock - Ready RO A value [1] indicates the serializer PLL is locked
D0 1'b0 TXPLL Counter RO For internal use.

Start of Hyperframe Character
Address: 15h Value: 01BCh
D15-D10 6'd0 Reserved RW Reserved for future use. Returns undefined value when read.
D9-D0 10'h1BC 8b Start of HF Character RW 8b-bit mode start of hyperframe character

Start of Hyperframe Character
Address: 16h Value: 017Ch
D15-D10 6'd0 Reserved RW Reserved for future use. Returns undefined value when read.
D9-D0 10'h17C 10b Start of HF Character+ RW 10b-bit mode start of hyperframe positive character

Start of Hyperframe Character
Address: 17h Value: 0283h
D15-D10 6'd0 Reserved RW Reserved for future use. Returns undefined value when read.
D9-D0 10'h283 10b Start of HF Character- RW 8b-bit mode start of hyperframe negative character

Reserved
Address: 18h Value: 0EF5h
D15-D0 16'h0EF5 Reserved - Reserved for future use. Returns undefined value when read.

DCM
Address: 19h Value: 0000h
D15-D12 4'h0 Reserved RW Reserved for future use. Returns undefined value when read.
D11 1'b0 Hyperframe Length Enable RW Enables non-standard hyperframe length to be used with DCM
D10-D9 2'b00 Initial Power up wait cycle RW These bits program the power up wait cycle for CPRI delay bias circuitry
2'b00 66us
2'b01 33us
2'b10 66us
2'b11 128us
D8-D1 8'd0 Reserved RW Reserved for future use. Returns undefined value when read.
D0 1'b0 Enable DCM RW A value [1] enables DCM control circuitry.

# Reserved
# Address: 1Ah 1Bh 1Ch 1Dh Value: 0000h
# D15-D0 16'd0 Reserved RO Reserved for future use. Returns undefined value when read.

T14 Lower
Address:1Eh Value: 0000h
D15-D0 16'd0 T14 Lower RO Lower 16 T14 DCM bits. T14 is defined as Tx serial to Rx serial delay.  This is the round trip delay of the cable + remote side.

T14 Upper
Address:1Fh Value: 0000h
D15-D6 10'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D5 1'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D4-D0 5'd0 T14 Upper RO Upper 5 T14 DCM bits. T14 is defined as Tx serial to Rx serial delay.  This is the round trip delay of the cable + remote side.

Toffset Lower
Address:20h Value: 0000h
D15-D0 16'd0 Toffset Lower RO Lower 16 Toffset DCM bits. Toffset is defined as the Rx serial to Tx serial delay.

Toffset Upper
Address:21h Value: 0000h
D15-D6 10'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D5 1'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D4-D0 5'd0 Toffset Upper RO Upper 5 Toffset DCM bits. Toffset is defined as the Rx serial to Tx serial delay.

Tser Lower
Address:22h Value: 0000h
D15-D0 16'd0 Tser Lower RO Lower 16 Tser DCM bits. Tser is defined as the serializer delay.

Tser Upper
Address:23h Value: 0000h
D15-D6 10'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D5 1'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D4-D0 5'd0 Tser Upper RO Upper 5 Tser DCM bits. Tser is defined as the serializer delay.

Tdes Lower
Address:24h Value: 0000h
D15-D0 16'd0 Tdes Lower RO Lower 16 Tdes DCM bits. Tdes is defined as the deserializer delay.

Tdes Upper
Address:25h Value: 0000h
D15-D6 10'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D5 1'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D4-D0 5'd0 Tdes Upper RO Upper 5 Tdes DCM bits. Tdes is defined as the deserializer delay.

Tin-out Lower
Address:26h Value: 0000h
D15-D0 16'd0 Tin-out Lower RO Lower 16 Tin-out DCM bits. Tin-out is defined as the delay between the Tx parallel inputs and the Rx parallel outputs.

Tin-out Upper
Address:27h Value: 0000h
D15-D6 10'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D5 1'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D4-D0 5'd0 Tin-out Upper RO Upper 5 Tin-out DCM bits. Tin-out is defined as the delay between the Tx parallel inputs and the Rx parallel outputs.

Tout-in Lower
Address:28h Value: 0000h
D15-D0 16'd0 Tout-in Lower RO Lower 16 Tout-in DCM bits. Tout-in is defined as the delay between the Rx parallel outputs and the Tx parallel inputs.

Tout-in Upper
Address:29h Value: 0000h
D15-D8 8'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D7 1'd0 DCM Error RO This bit is set to [1] if LOF is detected during DCM measurement
D6 1'd0 DCM Ready RO DCM results ready when this bit is [1]
D5 1'd0 Reserved RO Reserved for future use. Returns undefined value when read.
D4-D0 5'd0 Tout-in Upper RO Upper 5 Tout-in DCM bits. Tout-in is defined as the delay between the Rx parallel outputs and the Tx parallel inputs.
}

############################################
set all [ split $register_description \n ]
proc get_next { { remove 1 } } {
   global all
   if { [ llength $all ] == 0 } {
      return ""
   }
   set ret [ lindex $all 0 ]

   if { [ string index $ret 0 ] == "#" } { set ret "" }

   if { $remove } { set all [ lrange $all 1 end ] }

   return $ret
}
proc go_next_reg {} {
   global all
   while { [ get_next ] != "" } {}

   while { [ llength $all ] > 0 } {
      if { [ get_next 0 ] != "" } { return 1 }
      set all [ lrange $all 1 end ]
   }
   return 0
}
############################################

proc riempi_reg {} {
   global reg
   while { [ go_next_reg ] } {
      set title [get_next]
      if { [ scan [ get_next ] "Address: %2xh Value: %4xh" address vdefault ] != 2 } {
         error "$str"
      }
   
      set reg($address) $title
      set reg($address,vdefault) $vdefault
      set reg($address,value) "????"
   
      # D15-D0 16'd0 Tser Lower RO Lower 16 Tser DCM bits. Tser is defined as the serializer delay.
      # D6-D2 Reserved - Reserved for future use. Returns undefined value when read.
      set str [ get_next 0 ]
      while { $str != "" } {
	 get_next

         if { [ string index $str 0 ] == "D" } {

            if { [ regexp {(\S*) (\S*) (.*) (RO|RW|RC|WC|-)( (.*)|)} $str {} range def name access {} descr ] != "1" } {
               error $str
            }

	    set reg($address,bit,$range) $str
	    set reg($address,bit,$range,range) $range
	    set reg($address,bit,$range,def) [ get_bit_default $def ]
	    set reg($address,bit,$range,defx) [ get_hex_default $def ]

	    set reg($address,bit,$range,name) $name
	    set reg($address,bit,$range,access) $access
	    set reg($address,bit,$range,description) $descr

	    set reg($address,bit,$range,value) "?"
	 }

         set str [ get_next 0 ]
      }
   }
}

########################################################################
proc get_bit_range { str D1_ref D0_ref } {
   upvar $D1_ref D1 $D0_ref D0
   if { [ regexp {D(\w*)(-D(\w*)|)} $str {} D1 {} D0 ] != "1" } {
      error ,,,$str,,,
   }
   return [ list $D1 $D0 ]
}

########################################################################
proc int2bin { i } {
   binary scan [binary format S1 $i] B* x
   return $x
}

proc hex2bin { i } {
   binary scan [binary format H4 [ format %.4x 0x$i ] ] B* x
   return $x
}

proc bin2int { i } {
   if { [ binary scan [binary format B* $i] S1 x ] != "1" } { 
      error "bin2int $i: ,,[binary format B* $i],,"
   }
   return [ expr $x & 0xFFFF ]
}

proc get_bit_default { str_def } {
   # 7'd0 1'b0 16'd0 2'b11 10'h283
   if { [ regexp {(\w*)'(d|b|h)(\w*)} $str_def {} numero_bits base valore ] != "1" } {
      error $str_def
   }
   # set bitdef [ string repeat "0" $numero_bits ]
   set numof_bits_1 [ expr $numero_bits - 1 ]
   switch $base {
      d {
         set bitdef [ int2bin $valore ]
         set bitdef [ string range $bitdef end-$numof_bits_1 end ]
      }
      b {
	 set bitdef $valore
      }
      h {
         set bitdef [ hex2bin $valore ]
         set bitdef [ string range $bitdef end-$numof_bits_1 end ]
      }
   }

   if { [ string length $bitdef ] != $numero_bits } {
      error "$bitdef base $base non di $numero_bits bits"
   }
   return $bitdef
}

proc get_hex_default { str_def } {
   set bitdef [ get_bit_default $str_def ]
   set bitdef [ scan $bitdef %d ] ;# CANCELLA GLI 0 DAVANTI
   set bitdef [ format %.16d $bitdef ] ;# AGGIUNGE ZERO DAVANTI
   return [ format %x [ bin2int $bitdef ] ]
}

########################################################################
proc check_reg_defaults { address } {
   global reg
   
   # puts "ADDRESS: $address"
   set address_default "----------------"
   foreach keyrange [ array names reg -regexp "^$address,bit,\[^,\]*$" ] {
      get_bit_range $reg($keyrange,range) D1 D0
      if { $D0 == "" } { set D0 $D1 }

      set numofbits [ expr $D1 - $D0 + 1 ]
      ## get_bit_default $reg($keyrange,def) $numofbits bitdef

      if { $numofbits != [ string length $reg($keyrange,def) ] } {
         error "$str_def,,, $numero_bits != $numero_bits"
      }

      set address_default [ string replace $address_default end-$D1 end-$D0 $reg($keyrange,def) ]
   }
   if [ expr [ bin2int $address_default ] != $reg($address,vdefault) ] {
      error "$address: $address_default != [ format %x $reg($address,vdefault) ]"
   }
}

########################################################################
riempi_reg

###############################
foreach address [ array names reg -regexp {^[^,]+$} ] {
   check_reg_defaults $address
}
 
###############################
lappend argv -nostandalone
source com.tcl

###############################
trace add variable reg { write } reg_callback

proc reg_callback { ar_ref index op } {
   upvar $ar_ref ar
   puts "$ar_ref ($index) -> $ar($index)"

   if { [ regexp {(\w*),} $index {} address ] != "1" } {
      puts "WRONG $index!"
      return -1
   }

   switch -regexp -- $index {
      "^$address,value$" {
         # set reg($address,value) 
	 puts "ADDRESS AND VALUE with address $address"
      }
      "^$address,bit,[^,]*,value$" {
	 puts "BITRANGE MNODIFIED with address $address"
      }
      default {
	 puts "WRONG index $index with address $address"
      }
   }
}

###############################


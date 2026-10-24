# Helpers of the hierarchical PnR (on top of the procedures in pnr_legacy/tcl)

# Make a pin of the special wires of a net on a layer that reach the given die
# edges (any of bottom, top, left, right). The whole wire becomes the pin, so
# the top level can continue it by abutment.
proc saradc_pins_from_swires {net layer edges} {
  set netobj [$::block findNet $net]
  set bterm [$::block findBTerm $net]
  if {$bterm == "NULL"} {
    utl::error ORD 501 "No port for net $net"
  }
  set die [$::block getDieArea]
  set n 0
  foreach swire [$netobj getSWires] {
    foreach sbox [$swire getWires] {
      if {[$sbox isVia] || [[$sbox getTechLayer] getName] != $layer} {
        continue
      }
      set touch 0
      foreach edge $edges {
        switch $edge {
          bottom { set touch [expr $touch || [$sbox yMin] <= [$die yMin]] }
          top    { set touch [expr $touch || [$sbox yMax] >= [$die yMax]] }
          left   { set touch [expr $touch || [$sbox xMin] <= [$die xMin]] }
          right  { set touch [expr $touch || [$sbox xMax] >= [$die xMax]] }
        }
      }
      if {!$touch} {
        continue
      }
      # One pin with all the shapes (the router takes one pin per port)
      if {$n == 0} {
        set bpins [$bterm getBPins]
        if {[llength $bpins] > 0} {
          set bpin [lindex $bpins 0]
        } else {
          set bpin [odb::dbBPin_create $bterm]
        }
      }
      odb::dbBox_create $bpin [$sbox getTechLayer] [$sbox xMin] [$sbox yMin] [$sbox xMax] [$sbox yMax]
      $bpin setPlacementStatus FIRM
      incr n
    }
  }
  puts "\[saradc_pins_from_swires\] $net: $n pins on $layer"
  return $n
}

# add_stripe_over_area marks every net it draws as POWER. Put back the signal
# type of all nets except the supplies, so the LEF pins and DEF are right.
proc saradc_signal_nets {supplies} {
  foreach netobj [$::block getNets] {
    if {[lsearch -exact $supplies [$netobj getName]] >= 0} {
      continue
    }
    set sigTyp [$netobj getSigType]
    if {$sigTyp == "GROUND" || $sigTyp == "POWER"} {
      $netobj setSigType "SIGNAL"
    }
  }
}

# Connect the supply pins of the fillers and taps (ADC and standard cells)
proc saradc_global_fill {vdd vss} {
  global FILLERCells TAPCells
  set masters [concat SARADC_FILLTIE2 SARADC_FILL1 $TAPCells $FILLERCells]
  foreach inst [$::block getInsts] {
    if {[lsearch -exact $masters [[$inst getMaster] getName]] < 0} {
      continue
    }
    set name [reEscape [$inst getName]]
    add_global_connection -net $vdd -inst_pattern $name -pin_pattern {^vdd$} -power
    add_global_connection -net $vss -inst_pattern $name -pin_pattern {^vss$} -ground
  }
}

# The vertical Metal2 supply stripes over the taps of the CDAC columns, as
# create_stripes_vdd_vss, but only between y1 and y2
proc saradc_vdd_vss_stripes {x sizex nx y1 y2 tapcap netvdd netvss w} {
  global metal1 metal2 dbu
  set tap_lib [[::ord::get_db] findLib $tapcap]
  set tap_master [$tap_lib findMaster $tapcap]
  set sizetap [expr 1.0*[$tap_master getWidth] / $dbu]
  set area [list [expr $x - $sizetap] $y1 [expr $x + $sizex*$nx + $sizetap] $y2]
  setAddStripeMode -ignore_nondefault_domains true
  setAddStripeMode -orthogonal_only true -stacked_via_top_layer TopMetal1 -stacked_via_bottom_layer $metal1
  add_stripe_over_area [list $netvdd] $metal2 vertical $w 0.0 $sizex [expr $sizetap/2.0 - $w/2.0 + $sizetap] $area
  add_stripe_over_area [list $netvss] $metal2 vertical $w 0.0 $sizex [expr $sizetap/2.0 - $w/2.0] $area
  setAddStripeMode -reset
}

# Round up to a multiple of a grid
proc saradc_ceil_grid {v grid} {
  return [expr ceil($v/$grid - 1e-9)*$grid]
}

# Remove the sites of the rows inside a region (um), keeping the parts of each
# row left and right of it. Used where cells may not be placed next to the
# ADC cells (the switch rails carry signals).
proc saradc_cut_rows {x1 y1 x2 y2} {
  set rx1 [ord::microns_to_dbu $x1]
  set ry1 [ord::microns_to_dbu $y1]
  set rx2 [ord::microns_to_dbu $x2]
  set ry2 [ord::microns_to_dbu $y2]
  foreach rowobj [$::block getRows] {
    set bb [$rowobj getBBox]
    if {[$bb yMax] <= $ry1 || [$bb yMin] >= $ry2 || [$bb xMax] <= $rx1 || [$bb xMin] >= $rx2} {
      continue
    }
    set site [$rowobj getSite]
    set sw [$site getWidth]
    set name [$rowobj getName]
    set orient [$rowobj getOrient]
    set y [lindex [$rowobj getOrigin] 1]
    set x0 [$bb xMin]
    set x3 [$bb xMax]
    odb::dbRow_destroy $rowobj
    # Left part, up to the region; right part, from the first site after it
    set nl [expr ($rx1 - $x0) / $sw]
    if {$nl > 0} {
      odb::dbRow_create $::block ${name}_L $site $x0 $y $orient HORIZONTAL $nl $sw
    }
    set xr [expr $x0 + (($rx2 - $x0 + $sw - 1) / $sw) * $sw]
    set nr [expr ($x3 - $xr) / $sw]
    if {$nr > 0} {
      odb::dbRow_create $::block ${name}_R $site $xr $y $orient HORIZONTAL $nr $sw
    }
  }
}

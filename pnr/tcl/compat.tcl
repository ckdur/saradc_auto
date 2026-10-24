# Helpers that keep the custom ADC placement independent of the OpenROAD version

# Same as place_inst, but -name is taken literally.
# place_inst did "lindex $keys(-name) 0" until mid-2025 (so names had to be
# wrapped with [list ...]), and later versions take -name as is. The escaped
# names of the ADC instances (e.g. "cap\[0\]") break with either one, so this
# goes directly to odb, doing what place_inst does.
proc saradc_place_inst { args } {
  sta::parse_key_args "saradc_place_inst" args \
    keys {-cell -location -name -orientation -status} flags {}

  set inst_name $keys(-name)
  set orient R0
  if { [info exists keys(-orientation)] } {
    set orient $keys(-orientation)
  }
  set status PLACED
  if { [info exists keys(-status)] } {
    set status $keys(-status)
  }
  set x [ord::microns_to_dbu [lindex $keys(-location) 0]]
  set y [ord::microns_to_dbu [lindex $keys(-location) 1]]

  set inst [$::block findInst $inst_name]
  if { $inst == "NULL" } {
    if { ![info exists keys(-cell)] } {
      utl::error ORD 63 "Instance $inst_name not in the design, -cell must be specified to create a new instance."
    }
    set master [[ord::get_db] findMaster $keys(-cell)]
    if { $master == "NULL" } {
      utl::error ORD 56 "Cell $keys(-cell) not loaded into design."
    }
    set inst [odb::dbInst_create $::block $master $inst_name]
  }
  $inst setOrient $orient
  $inst setLocation $x $y
  $inst setPlacementStatus $status
}

# Set the core area to the bounding box of the (non-pad) rows.
# Until mid-2025 dbBlock::getCoreArea() returned this bounding box, so with
# voltage domains the core covered both the digital and the analog rows.
# Newer versions keep the -core_area given to initialize_floorplan (digital
# only here), and global_placement crashes on the analog region outside it.
proc saradc_core_from_rows {} {
  set first 1
  foreach row [$::block getRows] {
    if {[[$row getSite] getClass] == "PAD"} {
      continue
    }
    set bbox [$row getBBox]
    if {$first} {
      lassign [list [$bbox xMin] [$bbox yMin] [$bbox xMax] [$bbox yMax]] x0 y0 x1 y1
      set first 0
    } else {
      set x0 [expr min($x0, [$bbox xMin])]
      set y0 [expr min($y0, [$bbox yMin])]
      set x1 [expr max($x1, [$bbox xMax])]
      set y1 [expr max($y1, [$bbox yMax])]
    }
  }
  if {!$first} {
    $::block setCoreArea [odb::new_Rect $x0 $y0 $x1 $y1]
  }
}

# Extra arguments for detailed_placement.
# Since mid-2026 detailed_placement uses a negotiation legalizer, which cannot
# move the CDAC tie cells from inside the capacitor arrays (no rows there) to
# the analog rows, and leaves them unplaced over the array wiring. The diamond
# search legalizer, used at tapeout and default before, is selected if needed.
proc saradc_dpl_args {} {
  if {[string first "-use_diamond_legalizer" [info body detailed_placement]] >= 0} {
    return [list -use_diamond_legalizer]
  }
  return {}
}

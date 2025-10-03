#!/usr/bin/tcl
crashbackups stop
#gds flatglob *__example_*
#gds flatten true
gds read $env(GDS)
#set base [file rootname $env(GDS)]
set base "[pwd]/[file rootname [file tail $env(GDS)]]"
set ports {}
set dirs {}
set uses {}


set f [open $env(CSV)]
while {[gets $f line]>=0} {
  set fields [split $line ","]
  lappend ports [lindex $fields 0]
  set dir [lindex $fields 1]
  set use [lindex $fields 2]
  if {$dir == "inputOutput"} {
    set dir "inout"
  }
  if {$use == "supply"} {
    set use "power"
  }
  lappend dirs $dir
  lappend uses $use
}
close $f

# Get all the cells
set cells [cellname list allcells]
foreach cell $cells {
  if {$cell != "(UNNAMED)"} {
    load $cell
    select top cell
    set minp [port first]
    set maxp [port last]
    for {set i $minp} {$i <= $maxp} {incr i} {
      set name [port $i name]
      set find [lsearch $ports $name]
      if {$find >= 0} {
        set class [lindex $dirs $find]
        set use [lindex $uses $find]
        puts "Setting port $name to $class, $use"
        port $i class $class
        port $i use $use
        #if {$use == "power" || $use == "ground"} {
        #  port $i shape abutment
        #}
      }
    }
    property LEFclass BLOCK
    # TODO: Maybe this site name shall be configurable
    # property LEFsite obssite
    property LEFsymmetry "X Y R90"
    lef write $base.$cell.lef
  }
} 

quit


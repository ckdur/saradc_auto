##############################################################################
## SARADC_CDAC: one half of the CDAC as a macro
## The array of CDAC units (MSB, LSB and dummies, in the circle arrangement),
## their switches and wiring, the Metal4 stripes of VOUTH/VOUTL/VREF/VIP/VIN
## over every column, and the bridges of bits 1 and 3. Built as the H half of
## the flat flow (MSB in the middle of the top rows); the top places L mirrored.
## Over the array, from bottom to top: a bus of Metal3 stripes that joins the
## columns of each of VOUTH/VOUTL/VREF/VIP/VIN (in the flat flow the band of
## the channel did it), a row with the tie cells, and the control pins.
##
## Pins: VOUTH VOUTL VREF VIP VIN on Metal4 (the column stripes, at the top
## edge), VDD/VSS on Metal2 (the tap stripes, at the top and bottom edges),
## the switch controls on Metal3 at the top edge.
##############################################################################
source $env(PNR_DIR)/tcl/setup.tcl

# Empty margin around the array (cell rails go 0.15 um over the cell edges).
# The origin of the array is then off the macro grid by the same amount.
set mgn [expr $macro_grid - 1.8]
set strip {VOUTH VOUTL VREF VIP VIN}
# The bus that joins the columns: Metal3 stripes of this width and spacing
set busw 0.4
set buss 0.4
set bush [expr [llength $strip]*($busw+$buss) + $buss]

####################################
## Placement of the array
####################################
# Temporary floorplan, the final one is made after placing the array
initialize_floorplan -site obssite -die_area "0 0 1000 1000" -core_area "10 10 990 990"

set posx_cdac [expr $mgn + $sizetap]
set posy_cdac $mgn
set ret [pos_cdac_circle $posx_cdac $posy_cdac lsb_cdac msb_cdac dummy $nbits $pw $ph $saradc_tap 1 1]
set cdacx [lindex [lindex $ret 0] 0]
set cdacy [lindex [lindex $ret 0] 1]
set nx [lindex [lindex $ret 1] 0]
set ny [lindex [lindex $ret 1] 1]
set posa [concat [lindex $ret 2] [lindex $ret 3]]
set lsta [concat [lindex $ret 4] [lindex $ret 5]]
set nrow [expr int(ceil($cdacy*$ny / $row))]

# The bus and the row of the tie cells, over the array
set busy [expr $posy_cdac + $row*$nrow]
set rowy [expr $busy + $bush]
set W [expr $posx_cdac + $cdacx*$nx + $sizetap + $mgn]
set H [saradc_ceil_grid [expr $rowy + $row + $mgn] $macro_grid]
# create_stripes_vdd_vss spans the stripes over 0 .. Y
set X $W
set Y $H
puts "\[cdac\] macro $W x $H, array $nx x $ny units of $cdacx x $cdacy at ($posx_cdac, $posy_cdac)"

initialize_floorplan -site obssite -die_area "0 0 $W $H" -core_area "0 0 $W $H"
# initialize_floorplan snaps the rows to the site grid from the die origin.
# The only row is the one of the ties, at the top of the array
foreach rowobj [$::block getRows] {
  odb::dbRow_destroy $rowobj
}
odb::dbRow_create $::block ROW_TIE $siteobj [ord::microns_to_dbu $mgn] [ord::microns_to_dbu $rowy] \
  R0 HORIZONTAL [expr int(round(($W - 2*$mgn)/$track))] [ord::microns_to_dbu $track]
saradc_core_from_rows
saradc_make_tracks

####################################
## Supplies
####################################
add_global_connection -net VDD -pin_pattern {nothinghere} -power
add_global_connection -net VSS -pin_pattern {nothinghere} -ground
add_global_connection -net VDD -inst_pattern {.*\.tie[hl]\.impl} -pin_pattern {^vdd$} -power
add_global_connection -net VSS -inst_pattern {.*\.tie[hl]\.impl} -pin_pattern {^vss$} -ground
add_global_connection -net VDD -inst_pattern .* -pin_pattern {^vnw$} -power
add_global_connection -net VSS -inst_pattern .* -pin_pattern {^vpw$} -ground
saradc_global_fill VDD VSS
global_connect
set_voltage_domain -power VDD -ground VSS

# Taps of the tie row first, so the followpins and the stripes see them.
# tapcell cannot be used: it cuts the row with every ADC cell (they are
# blocks). Taps at both ends, at every column edge and at every column middle
for {set i 0} {$i <= $nx} {incr i} {
  set xt [expr $posx_cdac + $i*$cdacx - $sizetap]
  saradc_place_inst -name TAP_TIE_${i}_0 -cell [lindex $TAPCells 0] -location "$xt $rowy" -orientation R0 -status LOCKED
  if {$i < $nx} {
    set xt [expr $posx_cdac + $i*$cdacx + round(($cdacx/2 - $sizetap/2)/$track)*$track]
    saradc_place_inst -name TAP_TIE_${i}_1 -cell [lindex $TAPCells 0] -location "$xt $rowy" -orientation R0 -status LOCKED
  }
}
saradc_global_fill VDD VSS
global_connect

define_pdn_grid -name cdac_grid -starts_with POWER
add_pdn_stripe -grid cdac_grid -layer Metal1 -width 0.3 -followpins
pdngen

####################################
## Routing of the array
####################################
puts "\[Routing\] Creating vdd and vss for ties"
create_stripes_vdd_vss $posx_cdac $posy_cdac $cdacx $nx $H $saradc_tap VDD VSS [expr 2*$metal2_w]

puts "\[Routing\] Internal connections of the CDAC units"
# Plates kept away from the top plates (docs/dac_wiring.md); ROUTE_FIX=0 gives the tapeout wiring
set route_fix [expr {[info exists env(ROUTE_FIX)] ? $env(ROUTE_FIX) : 1}]
puts "\[Routing\] route_fix $route_fix"
create_sw_cap_conn $posx_cdac $posy_cdac $posa $lsta $pw $ph $cdacx $cdacy $strip $route_fix {VOUTH VOUTL}

puts "\[Routing\] Column stripes, up to the top edge"
create_stripes $posx_cdac $posy_cdac $cdacx $nx $H $strip $wthird $sthird

puts "\[Routing\] Bus joining the columns"
setAddStripeMode -orthogonal_only true -stacked_via_top_layer $metal4 -stacked_via_bottom_layer $metal3
add_stripe_over_area $strip $metal3 horizontal $busw $buss 100 $buss \
  [list [expr $posx_cdac - $sizetap] $busy [expr $posx_cdac + $cdacx*$nx + $sizetap] [expr $busy + $bush]]
setAddStripeMode -reset

puts "\[Routing\] Bridges of bits 1 and 3"
set wforth [expr $metal6_w]
set sforth [expr 2*$metal6_s]
set nx_2 [expr int($nx / 2)]
set offset [expr $cdacy/2 - (2*$wforth+$sforth)/2]
set x1 [expr $posx_cdac + ($nx_2-2)*$cdacx]
set x2 [expr $posx_cdac + ($nx_2+2)*$cdacx]
set y1 [expr $posy_cdac + ($ny-2)*$cdacy]
set y2 [expr $posy_cdac + ($ny-1)*$cdacy]
set area "$x1 $y1 $x2 $y2"
# VSH and FL of bit 1 (LSB_VSH[2], LSB_FL[2])
set capobj [$::block findInst "lsb_cdac.cdac_bit\\\[1\\\].cdac_unit.cap\\\[0\\\].cap/impl"]
set VSH_FL_2 [list [[[$capobj findITerm i] getNet] getName] [[[$capobj findITerm zn] getNet] getName]]
setAddStripeMode -stacked_via_top_layer $metal5 -stacked_via_bottom_layer $metal4
add_stripe_over_area $VSH_FL_2 $metal5 horizontal $wforth $sforth $cdacy $offset $area
if {$nbits >= 5} {
  # VSH and FL of bit 3 (LSB_VSH[4], LSB_FL[4])
  set capobj [$::block findInst "lsb_cdac.cdac_bit\\\[3\\\].cdac_unit.cap\\\[0\\\].cap/impl"]
  set VSH_FL_4 [list [[[$capobj findITerm i] getNet] getName] [[[$capobj findITerm zn] getNet] getName]]
  set x1 [expr $posx_cdac + ($nx_2-3)*$cdacx]
  set x2 [expr $posx_cdac + ($nx_2+3)*$cdacx]
  set y1 [expr $posy_cdac + ($ny-4)*$cdacy]
  set y2 [expr $posy_cdac + ($ny-2)*$cdacy]
  set area "$x1 $y1 $x2 $y2"
  setAddStripeMode -stacked_via_top_layer $metal5 -stacked_via_bottom_layer $metal4
  add_stripe_over_area $VSH_FL_4 $metal5 horizontal $wforth $sforth $cdacy $offset $area
  set x1 [expr $posx_cdac + ($nx_2-1)*$cdacx]
  set x2 [expr $posx_cdac + ($nx_2+1)*$cdacx]
  set offset [expr $cdacx/2 - (2*$wforth+$sforth)/2]
  set area "$x1 $y1 $x2 $y2"
  setAddStripeMode -stacked_via_top_layer TopMetal1 -stacked_via_bottom_layer $metal5
  add_stripe_over_area $VSH_FL_4 TopMetal1 vertical $wforth $sforth $cdacx $offset $area
}
setAddStripeMode -reset

####################################
## Pins
####################################
foreach net $strip {
  saradc_pins_from_swires $net $metal4 top
}
saradc_pins_from_swires VDD $metal2 {bottom top}
saradc_pins_from_swires VSS $metal2 {bottom top}

# Controls on the top edge, away from the supply stripes at the column edges
set excl {}
for {set i 0} {$i <= $nx} {incr i} {
  set xc [expr $posx_cdac + $i*$cdacx]
  lappend excl -exclude top:[expr max(0, $xc - $sizetap - 1)]-[expr min($W, $xc + $sizetap + 1)]
}
place_pins -hor_layers $metal2 -ver_layers $metal3 \
  -exclude left:* -exclude right:* -exclude bottom:* {*}$excl

####################################
## Placement of the tie cells
####################################
pos_stdcell_objs [expr $mgn + 2*$sizetap] $rowy [expr $W - 2*$mgn - 4*$sizetap] \
  [filter_by_regex {\.tie[hl]\.impl$} [$::block getInsts]]
detailed_placement {*}[saradc_dpl_args]
if { [catch {check_placement -verbose} errmsg] } {
  puts stderr $errmsg
  puts "Check placement failed, but is ignored on purpose"
}
filler_placement "$FILLERCells"
saradc_global_fill VDD VSS
global_connect

####################################
## Routing of the controls and ties
####################################
set_global_routing_layer_adjustment Metal1-Metal5 0.05
set_routing_layers -signal Metal1-Metal5 -clock Metal1-Metal5
set_macro_extension 0
pin_access
if { [catch {global_route -allow_congestion -congestion_iterations 50 -verbose -congestion_report_file $PNR_DIR/reports/${TOP}_congestion.rpt} errmsg] } {
  puts stderr $errmsg
  puts "Global routing failed with congestions, but is ignored on purpose"
}
set_thread_count 10
detailed_route -output_drc $PNR_DIR/reports/${TOP}.drc \
  -output_maze $PNR_DIR/reports/${TOP}_maze.log \
  -droute_end_iter 64 -verbose 1 -drc_report_iter_step 5

#################################################
## Write out final files
#################################################
saradc_signal_nets {VDD VSS}
write_db $PNR_DIR/outputs/${TOP}.odb
write_verilog $PNR_DIR/outputs/${TOP}.v
write_verilog -include_pwr_gnd $PNR_DIR/outputs/${TOP}_pg.v
write_def $PNR_DIR/outputs/${TOP}.def
write_abstract_lef $PNR_DIR/outputs/${TOP}.lef
write_cdl -masters ${CDLS} $PNR_DIR/outputs/${TOP}.cdl

# Geometry for the top (top.tcl)
set fo [open $PNR_DIR/outputs/${TOP}.geom.tcl w]
puts $fo "# Written by cdac.tcl"
foreach var {W H mgn posx_cdac posy_cdac cdacx cdacy nx ny nrow busy rowy} {
  puts $fo "set cdac_$var [format %.6g [set $var]]"
}
puts $fo "set cdac_strip [list $strip]"
close $fo

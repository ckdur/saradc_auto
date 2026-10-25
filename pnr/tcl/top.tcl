##############################################################################
## SARADC: top of the hierarchical PnR
## Same floorplan as the flat flow (pnr_legacy/tcl/pnr.tcl), with the CDAC
## halves as the SARADC_CDAC macro: H at the bottom, L mirrored (MX) at the
## top. The channel between them (the bands of VREF/VIN/VIP/VOUTH/VOUTL, the
## switch that joins VOUTH and VOUTL, the comparator and the logic buffers) and
## the digital part are made with the procedures of the flat flow. The column
## stripes and the supply stripes of the macros are continued from their edges.
##############################################################################
source $env(PNR_DIR)/tcl/setup.tcl
source $PNR_DIR/outputs/SARADC_CDAC.geom.tcl
set SYN_DIR $env(SYN_DIR)

puts "SDC reading: ${TOP}.sdc.tcl"
read_sdc $SYN_DIR/tcl/${TOP}.sdc.tcl
unset_propagated_clock [all_clocks]

####################################
## Floorplan
####################################
# Analog / digital boundary and die width: those of the 5-bit layout (macro 429.48 wide), moved by the
# growth of the macro width in whole sites, so that other NBITS keep the same alignment. Never
# narrower than for 5 bits: the channel (switch, comparator, logic buffers) needs that width
# (with 3 bits and the boundary moved in, the buffers cannot be legalized).
set dig_to_ana [expr 451.92 + max(0, ceil(($cdac_W - 429.48)/$track - 1e-9))*$track]
set X [expr $dig_to_ana + 114.52]
set corex [expr $margin]
set corey [expr $margin]

# Rows (from the bottom of the core) over a height
proc saradc_ceil_row {y} {
  global corey row
  return [expr $corey + $row*ceil(($y - $corey)/$row - 1e-9)]
}

# Positions, from the bottom: H macro, H band, switch row, L band, L macro.
# The macros are on the macro grid, the bands and the switch on the rows.
set cdac_x [saradc_ceil_grid $corex $macro_grid]
set cdach_y [saradc_ceil_grid $corey $macro_grid]
set cdach_uy [expr $cdach_y + $cdac_H]
set band_h_y [saradc_ceil_row $cdach_uy]
set posy_sw [expr $band_h_y + $row*$nrow_hl_sw]
# The switch and the comparator are placed for an R0 row (the even rows from
# the bottom of the core; the odd ones are mirrored)
if {int(round(($posy_sw - $corey)/$row)) % 2} {
  set band_h_y [expr $band_h_y + $row]
  set posy_sw [expr $posy_sw + $row]
}
set band_l_y [expr $posy_sw + $row]
set band_l_uy [expr $band_l_y + $row*$nrow_hl_sw]
set cdacl_y [saradc_ceil_grid $band_l_uy $macro_grid]
set cdacl_uy [expr $cdacl_y + $cdac_H]
set Y [expr [saradc_ceil_row $cdacl_uy] + $margin]
# Origin of the first CDAC unit (as posx_cdach in the flat flow)
set posx_cdach [expr $cdac_x + $cdac_posx_cdac]
set cdacx_h $cdac_cdacx
set nx_h $cdac_nx
puts "\[top\] die $X x $Y, CDAC H at ($cdac_x, $cdach_y), L at ($cdac_x, $cdacl_y) MX, switch row at $posy_sw"

set digcorearea "[expr $dig_to_ana] [expr $margin] [expr $X-$margin] [expr $Y-$margin]"
set anacorearea "[expr $margin] [expr $margin] [expr $dig_to_ana] [expr $Y-$margin]"
set coreuy [expr $Y-$margin]
set fPlan_height [expr $Y-2*$margin]

# The switch that joins VOUTH and VOUTL, on the site grid of the analog rows
# (they start at the core), as near as possible to the first column of the
# macros (the macro origin is on the track grid, not on the site grid)
set posx_sw [expr $corex + round(($posx_cdach - $corex)/$track)*$track]
set sw_w $cdacx_h
set cmp_x [expr $posx_sw + $sw_w + 20*$track]
# Region of the middle switch: blocked, and without rows (the switch cells use
# their rails for VOUTH/VOUTL, so no tap or filler can abut them)
set sw_region [list [expr $posx_sw-$sizetap] [expr $posy_sw-1*$row] [expr $cmp_x-$sizetap] [expr $posy_sw+2*$row]]

read_upf -file $LEGACY_TCL/${TOP}.upf.tcl
set_domain_area CORE -area $digcorearea
set_domain_area ANALOG -area $anacorearea
# The whole core (the flat flow gives the digital one): initialize_floorplan
# checks that the macros fit in it. The rows come from the domain areas.
initialize_floorplan -site obssite -die_area "0 0 $X $Y" \
  -core_area "$margin $margin [expr $X-$margin] [expr $Y-$margin]"
saradc_make_tracks
saradc_cut_rows {*}$sw_region
saradc_core_from_rows
create_blockage -region $sw_region

# Only add the global connection to the digitals
add_global_connection -net VDD -inst_pattern digital/.* -pin_pattern {^vdd$} -power
add_global_connection -net VSS -inst_pattern digital/.* -pin_pattern {^vss$} -ground
# Just to declare AVDD as a power net
add_global_connection -net AVDD -pin_pattern {nothinghere} -power

set_voltage_domain -region ANALOG -power AVDD -ground VSS -secondary_power VDD
set_voltage_domain -power VDD -ground VSS -secondary_power AVDD

insert_tiecells "sg13g2f_TIEL/zn" -prefix "TIE_ZERO_"
insert_tiecells "sg13g2f_TIEH/z" -prefix "TIE_ONE_"

set die_width $X
set fo [open FPlanFinal.size w]
puts $fo "Floorplan size: \{X Y\} = \{$X $Y\}"
close $fo

####################################
## ADC Macro placement
####################################
saradc_place_inst -name analog/cdac_h -location "$cdac_x $cdach_y" -orientation R0 -status LOCKED
saradc_place_inst -name analog/cdac_l -location "$cdac_x $cdacl_y" -orientation MX -status LOCKED

# Positioning of the additional switch that joins VOUTH and VOUTL
set ret_sw [pos_sw_wtap $posx_sw $posy_sw analog/sw_vouth2voutl $cdacx_h $saradc_tap $nsw_vouthl]
set nrow_sw 1


# connect the fillers
add_global_connection -net AVDD -inst_pattern analog/buflogic.* -pin_pattern {^vdd$} -power
add_global_connection -net VSS -inst_pattern analog/buflogic.* -pin_pattern {^vss$} -ground
add_global_connection -net AVDD -inst_pattern {analog/cdac_[hl]} -pin_pattern {^VDD$} -power
add_global_connection -net VSS -inst_pattern {analog/cdac_[hl]} -pin_pattern {^VSS$} -ground
add_global_connection -net AVDD -inst_pattern analog/.* -pin_pattern {^vnw$} -power
add_global_connection -net VSS -inst_pattern analog/.* -pin_pattern {^vpw$} -ground
do_global_from_areas
global_connect

####################################
## Power planning
####################################
define_pdn_grid -name stdcell_core_grid -starts_with POWER -voltage_domain CORE -pins "TopMetal1 Metal5"
define_pdn_grid -name stdcell_analog_grid -starts_with POWER -voltage_domain ANALOG -pins "TopMetal1 Metal5"
add_pdn_connect -grid stdcell_core_grid -layers "Metal5 TopMetal1"
add_pdn_connect -grid stdcell_analog_grid -layers "Metal5 TopMetal1"
add_pdn_stripe -grid stdcell_core_grid -layer Metal1 -width 0.3 -followpins -extend_to_core_ring
add_pdn_stripe -grid stdcell_analog_grid -layer Metal1 -width 0.3 -followpins -extend_to_core_ring
# NOTE: The vertical Metal5 straps of the analog grid of the flat flow are not
# drawn: they crossed the arrays (now the macros) without connecting there.
add_pdn_connect -grid stdcell_core_grid -layers "Metal1 Metal5"
add_pdn_connect -grid stdcell_analog_grid -layers "Metal1 Metal5"
add_pdn_connect -grid stdcell_analog_grid -layers "Metal1 TopMetal1"
add_pdn_ring -grid stdcell_core_grid -layers "TopMetal1 Metal5" -widths "3.2 3.0" -spacings "1.64 1.64" \
    -core_offset "$metal5_py $metal5_py" -starts_with GROUND -allow_out_of_die
add_pdn_ring -grid stdcell_analog_grid -layers "TopMetal1 Metal5" -widths "3.2 3.0" -spacings "1.64 1.64" \
    -core_offset "$metal5_py $metal5_py" -starts_with GROUND -allow_out_of_die
pdngen

####################################
## ADC Routing
####################################
puts "\[Routing\] Supply stripes of the CDAC columns, outside the macros"
set w_vdd_vss [expr 2*$metal2_w]
saradc_vdd_vss_stripes $posx_cdach $cdacx_h $nx_h 0 $cdach_y $saradc_tap AVDD VSS $w_vdd_vss
saradc_vdd_vss_stripes $posx_cdach $cdacx_h $nx_h $cdach_uy $cdacl_y $saradc_tap AVDD VSS $w_vdd_vss
saradc_vdd_vss_stripes $posx_cdach $cdacx_h $nx_h $cdacl_uy $Y $saradc_tap AVDD VSS $w_vdd_vss

# Positioning of the comparator
# NOTE: We do it AFTER the vdd and vss to avoid some silly DRC
set ret_poscmp [pos_stdcell_comp $cmp_x $posy_sw analog/cmp]
set compx [lindex $ret_poscmp 0]
set compy [lindex $ret_poscmp 1]

puts "\[Routing\] Trace horizontal stripes for connecting VREFH, VIN, VIP for down, and VREFL, VIN, VIP for up"
set midoff [expr $metal3_s+$metal3_py]
set midspc [expr 6*$midoff]
set midwidth [expr $row - $midspc]
set x1 0
set x2 $die_width
set y1 $band_h_y
set y2 [expr $y1 + $row*$nrow_hl_sw]
setAddStripeMode -orthogonal_only true
add_stripe_over_area {analog/VOUTH analog/VOUTL VREFH VIN VIP} $metal3 horizontal \
  $midwidth $midspc 100 $midoff "$x1 $y1 $x2 $y2"
place_pin -pin_name VREFH -layer $metal3 -location [list [expr $midwidth/2] [expr $y1+$midwidth/2+$midoff+2*($midwidth+$midspc)]] -pin_size [list $midwidth $midwidth]
place_pin -pin_name VIN -layer $metal3 -location [list [expr $midwidth/2] [expr $y1+$midwidth/2+$midoff+3*($midwidth+$midspc)]] -pin_size [list $midwidth $midwidth]
place_pin -pin_name VIP -layer $metal3 -location [list [expr $midwidth/2] [expr $y1+$midwidth/2+$midoff+4*($midwidth+$midspc)]] -pin_size [list $midwidth $midwidth]

set y1 $band_l_y
set y2 $band_l_uy
add_stripe_over_area {VIP VIN VREFL analog/VOUTL analog/VOUTH} $metal3 horizontal \
  $midwidth $midspc 100 $midoff "$x1 $y1 $x2 $y2"
place_pin -pin_name VIP -layer $metal3 -location [list [expr $midwidth/2] [expr $y1+$midwidth/2+$midoff+0*($midwidth+$midspc)]] -pin_size [list $midwidth $midwidth]
place_pin -pin_name VIN -layer $metal3 -location [list [expr $midwidth/2] [expr $y1+$midwidth/2+$midoff+1*($midwidth+$midspc)]] -pin_size [list $midwidth $midwidth]
place_pin -pin_name VREFL -layer $metal3 -location [list [expr $midwidth/2] [expr $y1+$midwidth/2+$midoff+2*($midwidth+$midspc)]] -pin_size [list $midwidth $midwidth]

puts "\[Routing\] Column stripes from the macros into the bands"
# The nets of the column stripes of each macro (cdac_strip: VOUTH VOUTL VREF
# VIP VIN), as connected in saradc_analog_hier.v. L has them inverted.
set strip_h {analog/VOUTH analog/VOUTL VREFH VIP VIN}
set strip_l {analog/VOUTL analog/VOUTH VREFL VIN VIP}
# create_stripes starts half a rail below the given y
create_stripes $posx_cdach [expr $cdach_uy + $abutsizey/2] $cdacx_h $nx_h \
  [expr $band_h_y + $row*$nrow_hl_sw - $midoff] $strip_h $wthird $sthird
create_stripes $posx_cdach [expr $band_l_y + $midoff + $abutsizey/2] $cdacx_h $nx_h \
  $cdacl_y $strip_l $wthird $sthird

puts "\[Routing\] Switch and comparator"
create_sw_conn $posx_sw $posy_sw analog/sw_vouth2voutl $cdacx_h $wthird $sthird $nsw_vouthl
route_vouts_comp [expr $posy_sw-5*$row] [expr $posy_sw+5.5*$row] analog/cmp

# A third one just for the switch. Only VOUTH and VOUTL
set x1 [expr $posx_sw]
set x2 [expr $x1 + 4*$wthird + 3*$sthird]
set y1 [expr $band_h_y + $midoff]
set y2 [expr $band_l_uy - $midoff]
setAddStripeMode -orthogonal_only true
add_stripe_over_area {analog/VOUTH analog/VOUTL VIN VIP} $metal4 vertical \
  $wthird $sthird 100 0 "$x1 $y1 $x2 $y2"

# Trace a long-ass AVDD, VDD, and VSS stripe to connect the two domains
setAddStripeMode -stacked_via_top_layer TopMetal1 -stacked_via_bottom_layer $metal5
add_stripe_over_area {AVDD VDD VSS} TopMetal1 horizontal \
  3.2 1.64 100 0 "0 $posy_sw $X [expr $posy_sw + 4*3.2 + 3*1.64]"
setAddStripeMode -reset

# Put the main clock buffer near the digital domain
saradc_place_inst -name "analog/buflogic.conv.smpcs.clkbuf.impl" -location "[expr $dig_to_ana-$sizetap-21.76] $posy_sw" -orientation R0 -status LOCKED

## Tapcell insertion
tapcell -distance 40 -endcap_master "$TAPCells" -tapcell_master "$TAPCells"

add_global_connection -net AVDD -inst_pattern analog/buflogic.* -pin_pattern {^vdd$} -power
add_global_connection -net VSS -inst_pattern analog/buflogic.* -pin_pattern {^vss$} -ground
add_global_connection -net AVDD -inst_pattern analog/.* -pin_pattern {^vnw$} -power
add_global_connection -net VSS -inst_pattern analog/.* -pin_pattern {^vpw$} -ground
do_global_from_areas
global_connect

# Dummy positioning of the buffers
pos_stdcell_box [expr $cmp_x+$compx+$row] [expr $posy_sw-2*$row] [expr $dig_to_ana-($cmp_x+$compx+$row)-3*$margin] analog/buflogic
pos_stdcell_box [expr $dig_to_ana+$row+2*$margin] [expr $posy_sw-10*$row] [expr ($X-$dig_to_ana)-3*$margin-$row] digital

write_def $PNR_DIR/outputs/${TOP}.pre.def

###################################
## Placement
####################################
foreach blockage [$::block getBlockages] {
  odb::dbBlockage_destroy $blockage
}

place_pins -hor_layers Metal4 -ver_layers Metal3 \
  -exclude top:* -exclude left:* -exclude bottom:*

# NOTE: It diverges (GPL-0305) in every OpenROAD version tried, and leaves the
# cells wherever it stopped. Go back to the positions above if it fails.
set gpl_saved {}
foreach inst [$::block getInsts] {
  if {[$inst getPlacementStatus] == "PLACED"} {
    lappend gpl_saved [list $inst [$inst getOrient] {*}[$inst getLocation]]
  }
}
if { [catch {global_placement -skip_initial_place -density 0.82} errmsg] } {
  puts stderr $errmsg
  puts "Global placement failed, but is ignored on purpose"
  foreach saved $gpl_saved {
    lassign $saved inst orient x y
    $inst setOrient $orient
    $inst setLocation $x $y
    $inst setPlacementStatus PLACED
  }
}

set_placement_padding -global -right 0 -left 0
set_placement_padding -masters $DIODECells -left 2

detailed_placement -max_displacement [subst { "500" "100" }] {*}[saradc_dpl_args]
optimize_mirroring
if { [catch {check_placement -verbose} errmsg] } {
  puts stderr $errmsg
  puts "Check placement failed, but is ignored on purpose"
}

####################################
# CTS
####################################
set_global_routing_layer_adjustment Metal1-Metal5 0.05
set_routing_layers -signal Metal1-Metal5 -clock Metal1-Metal5

# correlateRC.py gcd,ibex,aes,jpeg,chameleon,riscv32i,chameleon_hier
# cap units pf/um
set_layer_rc -layer Metal1    -capacitance 3.49E-05 -resistance 0.135e-03
set_layer_rc -layer Metal2    -capacitance 1.81E-05 -resistance 0.103e-03
set_layer_rc -layer Metal3    -capacitance 2.14962E-04 -resistance 0.103e-03
set_layer_rc -layer Metal4    -capacitance 1.48128E-04 -resistance 0.103e-03
set_layer_rc -layer Metal5    -capacitance 1.54087E-04 -resistance 0.103e-03
set_layer_rc -layer TopMetal1 -capacitance 1.54087E-04 -resistance 0.021e-03
set_layer_rc -layer TopMetal2 -capacitance 1.54087E-04 -resistance 0.0145e-03
set_layer_rc -via Via1    -resistance 2.0E-3
set_layer_rc -via Via2    -resistance 2.0E-3
set_layer_rc -via Via3    -resistance 2.0E-3
set_layer_rc -via Via4    -resistance 2.0E-3
set_layer_rc -via TopVia1 -resistance 0.4E-3
set_layer_rc -via TopVia2 -resistance 0.22E-3
set_wire_rc -signal -layer Metal2
set_wire_rc -clock  -layer Metal5

estimate_parasitics -placement
repair_clock_inverters
clock_tree_synthesis -buf_list $BUFCells -root_buf [lindex $BUFCells 0] -sink_clustering_size 25 -sink_clustering_max_diameter 50 -sink_clustering_enable
set_propagated_clock [all_clocks]
estimate_parasitics -placement
repair_clock_nets -max_wire_length 0
estimate_parasitics -placement

detailed_placement {*}[saradc_dpl_args]
optimize_mirroring
if { [catch {check_placement -verbose} errmsg] } {
  puts stderr $errmsg
  puts "Check placement failed, but is ignored on purpose"
}
report_cts -out_file $PNR_DIR/reports/cts.rpt

###############################################
# Global routing
###############################################
set_propagated_clock [all_clocks]
set_macro_extension 0
pin_access
if { [catch {global_route -allow_congestion -congestion_iterations 50 -verbose -congestion_report_file $PNR_DIR/reports/congestion.rpt} errmsg] } {
  puts stderr $errmsg
  puts "Global routing failed with congestions, but is ignored on purpose"
}
set_placement_padding -global -left 0 -right 0
estimate_parasitics -global_routing

# NOTE: Fails (RSZ-0074) on the comparator nets that are partially routed with
# special wires. At tapeout this repaired nothing anyway.
if { [catch {repair_design -verbose} errmsg] } {
  puts stderr $errmsg
  puts "Repair design failed, but is ignored on purpose"
}
global_route -start_incremental -allow_congestion
detailed_placement {*}[saradc_dpl_args]
global_route -end_incremental -allow_congestion -congestion_report_file $PNR_DIR/reports/${TOP}_congestion_post_repair_design.rpt

if { [catch {repair_timing -verbose -setup_margin 0 -repair_tns 100} errmsg] } {
  puts stderr $errmsg
  puts "Repair timing failed, but is ignored on purpose"
}
global_route -start_incremental -allow_congestion
detailed_placement {*}[saradc_dpl_args]
global_route -end_incremental -allow_congestion -congestion_report_file $PNR_DIR/reports/${TOP}_congestion_post_repair_timing.rpt
estimate_parasitics -global_routing

###############################################
# Fillers
###############################################
filler_placement "$FILLERCells"
add_global_connection -net VDD -inst_pattern clkbuf.* -pin_pattern {^vdd$} -power
add_global_connection -net VSS -inst_pattern clkbuf.* -pin_pattern {^vss$} -ground
add_global_connection -net VDD -inst_pattern clkload.* -pin_pattern {^vdd$} -power
add_global_connection -net VSS -inst_pattern clkload.* -pin_pattern {^vss$} -ground
add_global_connection -net AVDD -inst_pattern analog/buflogic.* -pin_pattern {^vdd$} -power
add_global_connection -net VSS -inst_pattern analog/buflogic.* -pin_pattern {^vss$} -ground
add_global_connection -net AVDD -inst_pattern analog/.* -pin_pattern {^vnw$} -power
add_global_connection -net VSS -inst_pattern analog/.* -pin_pattern {^vpw$} -ground
do_global_from_areas
global_connect

###############################################
# Detail routing
###############################################
set_thread_count 10
detailed_route -output_drc $PNR_DIR/reports/${TOP}.drc \
  -output_maze $PNR_DIR/reports/${TOP}_maze.log \
  -droute_end_iter 64 -verbose 1 -drc_report_iter_step 5

#################################################
## Write out final files
#################################################
saradc_signal_nets {AVDD VDD VSS}
write_db $PNR_DIR/outputs/${TOP}.odb
write_verilog $PNR_DIR/outputs/${TOP}.v
write_verilog -include_pwr_gnd $PNR_DIR/outputs/${TOP}_pg.v
write_def $PNR_DIR/outputs/${TOP}.def
write_abstract_lef $PNR_DIR/outputs/${TOP}.lef
write_cdl -masters ${CDLS} $PNR_DIR/outputs/${TOP}.cdl

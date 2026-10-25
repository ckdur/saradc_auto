##############################################################################
## Common setup of the hierarchical PnR (cdac.tcl, top.tcl)
## Libraries, netlists, tracks, the ADC configuration, and the placement and
## routing procedures of the flat flow (pnr_legacy/tcl).
##############################################################################
set TOP $env(TOP)
set PNR_DIR $env(PNR_DIR)
set ROOT_DIR $env(ROOT_DIR)
set LEGACY_TCL $ROOT_DIR/pnr_legacy/tcl

###############################################################
## Library setup
###############################################################
source $ROOT_DIR/cells/settings.tcl

# Macros made by this flow (LEF and CDL in outputs/)
set MACROS {}
if {[info exists env(MACROS)]} {
  set MACROS $env(MACROS)
}
foreach macro $MACROS {
  lappend LEFS $PNR_DIR/outputs/$macro.lef
  lappend CDLS $PNR_DIR/outputs/$macro.cdl
}

# We assume the first LIB is the standard cell lib
set LIBMAIN [lindex $LIBS 0]
set LIBBCMAIN [lindex $LIBS_BC 0]
set LIBWCMAIN [lindex $LIBS_WC 0]

define_corners typ
read_liberty -corner typ "$LIBMAIN"
read_liberty -min -corner typ "$LIBBCMAIN"
read_liberty -max -corner typ "$LIBWCMAIN"

# We assume the first LEF is the tech lef
read_lef [lindex $LEFS 0]
foreach LEFFILE [lrange $LEFS 1 end] {
  read_lef "$LEFFILE"
}

foreach netlist $env(NETLISTS) {
  puts "Reading: $netlist"
  read_verilog $netlist
}
link_design ${TOP}

foreach dir {outputs reports} {
  if {![file exists $dir]} {
    file mkdir $dir
  }
}

####################################
## Cells declaration
####################################
set BUFCells [list sg13g2f_BUFFD1]
set INVCells [list sg13g2f_INVD1]
set FILLERCells [list sg13g2f_FILL1 sg13g2f_FILL2 sg13g2f_FILL4 sg13g2f_FILL8]
set TAPCells [list sg13g2f_TAPCELL]
set DCAPCells [list ]
set DIODECells [list sg13g2f_ANTENNA]

####################################
## Technology
####################################
set ::chip [[::ord::get_db] getChip]
set ::tech [[::ord::get_db] getTech]
set ::block [$::chip getBlock]
set dbu [$tech getDbUnitsPerMicron]

set siteobj [[[::ord::get_db] findLib sg13g2f] findSite obssite]
set row   [expr 1.0*[$siteobj getHeight] / $dbu]
set track [expr 1.0*[$siteobj getWidth] / $dbu]
set pitch [expr 32*$row]
set margin [expr 3*$row]
# Common multiple of the track pitches (0.42 and 0.48). The macros are placed
# on this grid, so their tracks are the ones of the top.
set macro_grid 3.36

# Copied from flow/platforms/ihp-sg13g2/make_tracks.tcl inside OpenROAD-flow-scripts
# NOTE: Newer OpenROAD removes the tracks on every initialize_floorplan, so
# this has to be called again after re-initializing the floorplan
proc saradc_make_tracks {} {
  make_tracks Metal1 -x_offset 0.0  -x_pitch 0.48 -y_offset 0.0 -y_pitch  0.48
  make_tracks Metal2 -x_offset 0.0  -x_pitch 0.42 -y_offset 0.0 -y_pitch  0.42
  make_tracks Metal3 -x_offset 0.0  -x_pitch 0.48 -y_offset 0.0 -y_pitch  0.48
  make_tracks Metal4 -x_offset 0.0  -x_pitch 0.42 -y_offset 0.0 -y_pitch  0.42
  make_tracks Metal5 -x_offset 0.0  -x_pitch 3.48 -y_offset 0.0 -y_pitch  0.48
  make_tracks TopMetal1 -x_offset 1.46 -x_pitch 2.28 -y_offset 1.46 -y_pitch 2.28
  make_tracks TopMetal2 -x_offset 2.0  -x_pitch 4.0  -y_offset 2.0 -y_pitch 4.0
}

# Set some globals that are necessary for the SARADC pos utilities
set saradc_fill_nopower SARADC_FILL1_NOPOWER
set saradc_fill SARADC_FILL1
set saradc_tap SARADC_FILLTIE2
foreach {var layer} {1 Metal1 2 Metal2 3 Metal3 4 Metal4 5 Metal5 6 TopMetal1} {
  set layerobj [$tech findLayer $layer]
  set metal$var $layer
  set metal${var}_px [::ord::dbu_to_microns [$layerobj getPitchX]]
  set metal${var}_py [::ord::dbu_to_microns [$layerobj getPitchY]]
  set metal${var}_w [::ord::dbu_to_microns [$layerobj getWidth]]
  set metal${var}_s [::ord::dbu_to_microns [$layerobj getSpacing]]
}
# As in the flat flow
set metal2_px [expr $metal2_px + 0.02]

# Configuration of the ADC
# Capacitor WxH (3x2 in this case)
set pw 3
set ph 2
# Number of bits of the ADC (NBITS of settings.mk)
set nbits [expr {[info exists env(NBITS)] ? $env(NBITS) : 5}]
# Number of rows (in stdcells) for the distance between a CDAC and the switch
set nrow_hl_sw 5
# Number in tracks of the distance between the CAP and the SW in the CDAC unit
set ntrack_capsw 3
# sw number
set nsw_vouthl 3

# Get the abutment VDD (or VSS) size from the filler
set fill_lib [[::ord::get_db] findLib SARADC_FILL1]
set fill_obj [$fill_lib findMaster SARADC_FILL1]
set fill_rail_obj [lindex [$fill_obj getMTerms] 0]
set abutsizey [::ord::dbu_to_microns [[$fill_rail_obj getBBox] dy]]
set fill_sx [::ord::dbu_to_microns [$fill_obj getWidth]]

set tie_lib [[::ord::get_db] findLib $saradc_tap]
set tie_master [$tie_lib findMaster $saradc_tap]
set sizetap [::ord::dbu_to_microns [$tie_master getWidth]]

# Width and spacing of the vertical Metal4 stripes (VOUTH, VOUTL, VREF, VIP,
# VIN over every column of CDAC units)
set wthird [expr 4*$metal4_w]
set sthird [expr 2*$metal4_s]

####################################
## Procedures of the flat flow
####################################
foreach f {compat stripe saradc_pos saradc_conn comp_pos filler_utils} {
  source $LEGACY_TCL/$f.tcl
}
source $PNR_DIR/tcl/hier_utils.tcl

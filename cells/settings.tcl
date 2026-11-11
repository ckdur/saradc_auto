# Cell libraries of the technology TECH (settings.mk), in cells/<TECH> (CELLS_DIR):
#   <TECH>.lib, <TECH>.tech.lef, <TECH>.lef, <TECH>.cdl  the float standard cells (stdcell-gen)
#   SARADC_*.{lef,gds,cdl}                                the ADC cells (cells/Makefile)
# A cells/<TECH>/settings.tcl, when present, is sourced last to override these.
if { [info exists ::env(PDK_ROOT)]} {
  set PDK_ROOT $::env(PDK_ROOT)
} else {
  set PDK_ROOT "/opt/OpenLane/share/pdk"
}

set ROOT_DIR $env(ROOT_DIR)
set TECH [expr {[info exists ::env(TECH)] ? $::env(TECH) : "sg13g2f"}]
set CELLS_DIR [expr {[info exists ::env(CELLS_DIR)] ? $::env(CELLS_DIR) : "$ROOT_DIR/cells/$TECH"}]
set LIB_PATHS "$ROOT_DIR"

set SARADC_CELLS {SARADC_CELL_INVX0_ASSW SARADC_CELL_INVX16_ASCAP SARADC_FILLTIE2 SARADC_FILL1 SARADC_FILL1_NOPOWER}

set LIBS "$CELLS_DIR/$TECH.lib"
set LEFS "$CELLS_DIR/$TECH.tech.lef $CELLS_DIR/$TECH.lef"
set CDLS "$CELLS_DIR/$TECH.cdl"
foreach c $SARADC_CELLS {
  append LEFS " $CELLS_DIR/$c.lef"
  append CDLS " $CELLS_DIR/$c.cdl"
}

# TODO: Do the characterization of the lib
set LIBS_BC $LIBS
set LIBS_WC $LIBS

# TODO: Not defined yet
set RCX_RULES "$CELLS_DIR/$TECH.rules"

if {[file exists $CELLS_DIR/settings.tcl]} {
  source $CELLS_DIR/settings.tcl
}

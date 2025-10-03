if { [info exists ::env(PDK_ROOT)]} {
  # Setting a default
  set PDK_ROOT $::env(PDK_ROOT)
} else {
  # Setting a default
  set PDK_ROOT "/opt/OpenLane/share/pdk"
}

set ROOT_DIR $env(ROOT_DIR)
set LIB_PATHS "$ROOT_DIR"
set LIBS "${ROOT_DIR}/cells/sg13g2f.lib"

set LEFS "${ROOT_DIR}/cells/sg13g2f.tech.lef ${ROOT_DIR}/cells/sg13g2f.lef ${ROOT_DIR}/cells/SARADC_CELL_INVX0_ASSW.lef ${ROOT_DIR}/cells/SARADC_CELL_INVX16_ASCAP.lef ${ROOT_DIR}/cells/SARADC_FILLTIE2.lef ${ROOT_DIR}/cells/SARADC_FILL1.lef ${ROOT_DIR}/cells/SARADC_FILL1_NOPOWER.lef"
#set GDSS "${ROOT_DIR}/lib/sg13g2.gds"
set CDLS "${ROOT_DIR}/cells/sg13g2f.cdl ${ROOT_DIR}/cells/SARADC_CELL_INVX0_ASSW.cdl ${ROOT_DIR}/cells/SARADC_CELL_INVX16_ASCAP.cdl ${ROOT_DIR}/cells/SARADC_FILLTIE2.cdl ${ROOT_DIR}/cells/SARADC_FILL1.cdl ${ROOT_DIR}/cells/SARADC_FILL1_NOPOWER.cdl"

# TODO: Do the characterization of the lib
set LIBS_BC "${ROOT_DIR}/cells/sg13g2f.lib"
set LIBS_WC "${ROOT_DIR}/cells/sg13g2f.lib"

# TODO: Not defined yet
set RCX_RULES "${ROOT_DIR}/cells/sg13g2f.rules"

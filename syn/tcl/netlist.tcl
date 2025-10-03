# Dummy script for tricking openroad to give us a netlist in CDL form

set TOP $env(TOP)
set SYN_DIR $env(SYN_DIR)
set SYN_SRC $env(SYN_SRC)

source $env(ROOT_DIR)/cells/settings.tcl

# We assume the first LIB is the standard cell lib
set LIBMAIN [lindex $LIBS 0]
set LIBBCMAIN [lindex $LIBS_BC 0]
set LIBWCMAIN [lindex $LIBS_WC 0]

# TODO: Figure out what is the actual set of commands work
define_corners typ
read_liberty -corner typ "$LIBMAIN"
read_liberty -min -corner typ "$LIBBCMAIN"
read_liberty -max -corner typ "$LIBWCMAIN"

# We assume the first LEF is the tech lef
set TECHLEF [lindex $LEFS 0]
set OTHERLEF [lrange $LEFS 1 end]

read_lef $TECHLEF
foreach LEFFILE $OTHERLEF {
  read_lef "$LEFFILE"
}

puts "Reading: $env(SYN_ANA_NET)"
read_verilog $env(SYN_ANA_NET)
link_design ${TOP}

if {![file exists outputs]} {
  file mkdir outputs
  puts "Creating directory outputs"
}

write_cdl -masters ${CDLS} $SYN_DIR/outputs/${TOP}.cdl
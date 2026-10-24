# SPICE netlist with parasitic capacitance from the .ext files written by pex.tcl
ext2spice hierarchy off
ext2spice cthresh 0.01
ext2spice rthresh infinite
ext2spice format ngspice
ext2spice subcircuit top on
ext2spice global off
ext2spice -o SARADC.pex.spice SARADC
quit -noprompt

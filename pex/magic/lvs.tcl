# netgen LVS: magic extraction (flat) vs. the signoff schematic netlist
lvs "SARADC.lvs.spice SARADC" "$::env(SARADC_SPICE) SARADC" $::env(PDK_ROOT)/$::env(PDK)/libs.tech/netgen/$::env(PDK)_setup.tcl lvs.report -json
quit

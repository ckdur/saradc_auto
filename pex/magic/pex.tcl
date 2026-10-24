# Parasitic extraction of SARADC with magic (devices + parasitic capacitance, no resistance)
gds flatglob *_CDNS_*
gds readonly true
gds read $::env(SARADC_GDS)
load SARADC
select top cell
extract do local
extract no all
extract do capacitance
extract do coupling
extract do adjust
extract all
source ext2spice.tcl

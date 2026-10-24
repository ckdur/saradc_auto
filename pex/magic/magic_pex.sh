#!/usr/bin/env bash
# Magic extraction of the whole SARADC (devices + parasitic C), netgen LVS against the signoff
# schematic, and the post-layout netlist for the simulator.
#
# Usage (from the repo root, after `source ~/init_openlane.sh`):
#   pex/magic/magic_pex.sh [layout dir]   (default signoff/outputs_legacy; the 2026-10-22 run used the
#                                          taped-out layout, now in signoff/outputs.tapeout)
# Needs <layout dir>/SARADC.gds and SARADC.spice, and sim/outputs/SARADC.xyce.ckt (for the ports).
# Writes pex/outputs/magic/ (SARADC.pex.spice, SARADC.lvs.spice, lvs.report, logs,
# SARADC.pex.xyce.ckt).
#
# Known result: device counts match (12093 nMOS, 12105 pMOS) but the capacitances are ~100x too large,
# and netgen fails on the sg13_lv_nmos/pmos subcircuit naming (see pex/README.md).
set -e
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
R=$ROOT/pex/magic
O=$ROOT/pex/outputs/magic
L=$(cd "${1:-$ROOT/signoff/outputs_legacy}" && pwd)
RC=$PDK_ROOT/$PDK/libs.tech/magic/$PDK.magicrc
export SARADC_GDS=$L/SARADC.gds SARADC_SPICE=$L/SARADC.spice

mkdir -p "$O"
cp "$R"/*.tcl "$O/"
cd "$O"
# pex.tcl reads $SARADC_GDS, extracts, then sources ext2spice.tcl (-> SARADC.pex.spice)
magic -dnull -noconsole -rcfile "$RC" pex.tcl > pex.log 2>&1
magic -dnull -noconsole -rcfile "$RC" ext2spice_lvs.tcl > ext2spice_lvs.log 2>&1
netgen -batch source lvs.tcl > lvs.log 2>&1 || echo "netgen failed (expected, see lvs.log)"

python3 "$R/pex2xyce.py" SARADC.pex.spice "$ROOT/sim/outputs/SARADC.xyce.ckt" SARADC.pex.xyce.ckt

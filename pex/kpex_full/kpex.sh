#!/usr/bin/env bash
# KLayout-PEX (2.5D, CC) runs on the whole flat SARADC, as attempted on 2026-10-22..24 on the
# taped-out layout. None finished; they are kept so the attempt can be repeated (e.g. with a newer
# kpex). The extraction that works is the split one, pex/split.py (see pex/README.md).
#
# Usage (from the repo root, after `source ~/init_openlane.sh`):
#   pex/kpex_full/kpex.sh [lvs|run1|run2|run3|run4] [layout dir]   (default signoff/outputs_legacy)
# Writes pex/outputs/kpex_full/. Each run is single-threaded in the 2.5D engine and takes > 10 h.
set -e
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
L=$(cd "${2:-$ROOT/signoff/outputs_legacy}" && pwd)
K=$ROOT/pex/outputs/kpex_full
mkdir -p "$K"
cd "$K"
KPEX_PKG=$(python3 -c "import klayout_pex, os; print(os.path.dirname(klayout_pex.__file__))")

lvs() {
    # Schematic with the standard cells flattened, then the PDK LVS deck shipped with kpex
    klayout -b -r "$ROOT/signoff/tcl/flatstd.py" -rd src="$L/SARADC.spice" -rd dst="$K/SARADC.flatstd.spice"
    mkdir -p lvs
    klayout -b -r "$KPEX_PKG/pdk/ihp-sg13g2/libs.tech/kpex/sg13g2.lvs" \
        -rd input="$L/SARADC.gds" -rd report="$K/lvs/SARADC.lvsdb" \
        -rd schematic="$K/SARADC.flatstd.spice" -rd thr=22 -rd run_mode=deep \
        -rd spice_net_names=true -rd spice_comments=false -rd scale=false -rd verbose=false \
        -rd schematic_simplify=false -rd net_only=false -rd top_lvl_pins=true -rd combine=false \
        -rd combine_devices=false -rd purge=false -rd purge_nets=false -rd no_simplify=true \
        -rd topcell=SARADC > lvs/lvs.log 2>&1
}

case "${1:-run4}" in
lvs) lvs ;;
run1)  # kpex's own LVS against the unflattened schematic, 4 h limit
    timeout 14400 kpex --pdk ihp-sg13g2 --gds "$L/SARADC.gds" --schematic "$L/SARADC.spice" \
        --cell SARADC --2.5D --mode CC --threads 8 --out_dir run25d -o SARADC.kpex.spice > kpex.log 2>&1 ;;
run2)  # 12 h limit
    [ -f lvs/SARADC.lvsdb ] || lvs
    timeout 43200 kpex --pdk ihp-sg13g2 --lvsdb lvs/SARADC.lvsdb --gds "$L/SARADC.gds" \
        --cell SARADC --2.5D --mode CC --threads 8 --log_level debug --out_dir run25d \
        -o SARADC.kpex.spice > kpex.log 2>&1 ;;
run3)  # halo 1 um, 10 h limit
    [ -f lvs/SARADC.lvsdb ] || lvs
    timeout 36000 kpex --pdk ihp-sg13g2 --lvsdb lvs/SARADC.lvsdb --gds "$L/SARADC.gds" \
        --cell SARADC --2.5D --mode CC --halo 1 --log_level info --out_dir run25d_h1 \
        -o SARADC.kpex.spice > kpex_h1.log 2>&1 ;;
run4)  # fillers removed, halo 1 um, no limit (stopped by hand after 16 h)
    python3 "$ROOT/pex/kpex_full/strip_fill.py" "$L/SARADC.gds" SARADC.nofill.gds
    nice -n 5 kpex --pdk ihp-sg13g2 --gds SARADC.nofill.gds --cell SARADC --2.5D --mode CC --halo 1 \
        --log_level info --out_dir run25d_nofill -o SARADC.kpex.spice > kpex_nofill.log 2>&1 ;;
*) echo "usage: $0 [lvs|run1|run2|run3|run4] [layout dir]"; exit 1 ;;
esac

#!/bin/bash
# Post-layout netlist of the hierarchical layout (pnr/ + signoff/outputs) in one go:
# split extraction of the SARADC_CDAC macro and of the top without the macros, stitching,
# check against the schematic, and the plate parasitics per bit.
#   pex/hier_pex.sh <tag>     -> pex/outputs/cdac_<tag>/, pex/outputs/top_<tag>/,
#                                sim/outputs/pex/SARADC_<tag>.pex.ckt, ..._<tag>.plate_par.json
# Run from the root of saradc_auto after source ~/init_openlane.sh (~6 min with 28 jobs).
# The grids are those of pex/README.md; they assume the macro and die sizes of today.
set -e
T=${1:?tag}
O=sim/outputs/pex
mkdir -p pex/outputs/top_$T $O
python3 pex/split.py pex/outputs/cdac_$T --gds signoff/outputs/SARADC_CDAC.gds --def pnr/outputs/SARADC_CDAC.def \
  --xs 0 87.52 171.84 256.16 340.48 429.48 --ys 0 22.8 44.04 65.28 86.52 107.76 144.48
klayout -b -r pex/nomacro.py -rd gds=signoff/outputs/SARADC.gds -rd out=pex/outputs/top_$T/SARADC_nomacro.gds
python3 pex/split.py pex/outputs/top_$T/split --gds pex/outputs/top_$T/SARADC_nomacro.gds --def pnr/outputs/SARADC.def -j 14 \
  --xs 0 109.18 233.54 320.32 452.0 566.44 \
  --ys 0 48.96 79.56 110.16 140.76 171.36 189.72 214.2 232.56 263.16 293.76 324.36 410.04
# Flat schematic of the same PnR, for the check (and as the schematic netlist of this variant)
python3 - $O/SARADC_$T.flat.ckt <<'PY'
import os, sys
sys.path.insert(0, 'src')
import adc_char as A
cells = [os.path.join(A.CELLS, c) for c in ("sg13g2f.ckt", "SARADC_CELL_INVX0_ASSW.ckt",
         "SARADC_CELL_INVX16_ASCAP.ckt", "SARADC_FILL1_NOPOWER.cdl", "SARADC_FILL1.cdl", "SARADC_FILLTIE2.cdl")]
A.flatten(cells + ['pnr/outputs/SARADC_CDAC.cdl', 'pnr/outputs/SARADC.cdl'], 'SARADC', sys.argv[1])
PY
python3 sim/pex/stitch.py $O/SARADC_$T.pex.ckt --cdl pnr/outputs/SARADC.cdl --top pex/outputs/top_$T/split/pieces.txt \
  --macro SARADC_CDAC=pex/outputs/cdac_$T/pieces.txt:pnr/outputs/SARADC_CDAC.cdl --check $O/SARADC_$T.flat.ckt
python3 sim/pex/dacpar.py $O/SARADC_$T.pex.ckt --style hier --json $O/SARADC_$T.plate_par.json

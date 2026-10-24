#!/usr/bin/env python3
"""Copy of the layout without the SARADC_FILL1_NOPOWER filler instances (6530 in SARADC), to
reduce the geometry for the kpex 2.5D engine.

  strip_fill.py <in.gds> <out.gds>
"""
import sys

import klayout.db as db

src, dst = sys.argv[1:3]
ly = db.Layout()
ly.read(src)
fill = ly.cell("SARADC_FILL1_NOPOWER").cell_index()
n = 0
for inst in list(ly.top_cell().each_inst()):
    if inst.cell_index == fill:
        inst.delete()
        n += 1
ly.write(dst)
print("removed %d fillers, wrote %s" % (n, dst))

# Run it with: klayout -z -r change_layers.py -rd infile=sg13g2f.gds -rd outfile=sg13g2f_changed.gds

import pya
import os, sys, importlib

app = pya.Application.instance()
mw = app.main_window()

# Create a view, then get the reference
lvi = mw.create_view()
lv = mw.view(lvi)

lv.load_layout(infile, 0)

for i in range(0, lv.cellviews()):
    layout = lv.cellview(i).layout()

    for cell in layout.each_cell():
        source_layer = layout.layer(8, 2)
        target_layer = layout.layer(8, 25)
        source_shapes = cell.shapes(source_layer)
        target_shapes = cell.shapes(target_layer)

        # copy shapes together
        target_shapes.insert(source_shapes)
        source_shapes.insert(target_shapes)

    layout.write(outfile)

# Run it with: klayout -z -r saradc_auto/scripts/change_names.py -rd infile=saradc_auto/cells/sg13g2f.gds -rd outfile=saradc_auto/cells/sg13g2f_changed.gds -rd prefix=sg13g2f
# Run it with: klayout -z -r saradc_auto/scripts/change_names.py -rd infile=lib/sg13g2.gds -rd outfile=lib/sg13g2_changed.gds -rd prefix=sg13g2

import pya
import os, sys, importlib

app = pya.Application.instance()
mw = app.main_window()

# Create a view, then get the reference
lvi = mw.create_view()
lv = mw.view(lvi)

print("Reading: {}".format(infile))
lv.load_layout(infile, 0)

for i in range(0, lv.cellviews()):
    layout = lv.cellview(i).layout()

    for cell in layout.each_cell():
        cell_name = layout.cell_name(cell.cell_index())
        new_name = prefix + "_" + cell_name
        layout.rename_cell(cell.cell_index(), new_name)
        print("Renaming {} -> {}".format(cell_name, new_name))

    layout.write(outfile)

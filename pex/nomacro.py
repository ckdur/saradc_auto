"""Writes the top level of the hierarchical layout without the SARADC_CDAC macros, for the
split extraction of the top (sim/pex/stitch.py puts the macro extraction in their place).
prune_cell, never delete_cell_rec: that also deletes the vias and the cells shared with the top.
Usage: klayout -b -r pex/nomacro.py -rd gds=signoff/outputs/SARADC.gds -rd out=<out.gds>"""
import pya

ly = pya.Layout()
ly.read(gds)
top = ly.cell('SARADC')
for inst in list(top.each_inst()):
    if inst.cell.name == 'SARADC_CDAC':
        inst.delete()
ly.prune_cell(ly.cell('SARADC_CDAC').cell_index(), -1)
ly.write(out)
print('wrote', out, 'CDAC cells left:', [c.name for c in ly.each_cell() if 'CDAC' in c.name])

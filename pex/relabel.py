# Copies the texts on the metal pin layers (L/2) to the metal text layers (L/25)
# The sg13g2f and SARADC cells have their labels on the pin datatype, but the
# IHP LVS (and kpex) only take net names from the text datatype.
# Usage: klayout -b -r relabel.py -rd in_gds=<in.gds> -rd out_gds=<out.gds>
import pya

# Metal1..Metal5, TopMetal1, TopMetal2
METALS = [8, 10, 30, 50, 67, 126, 134]

layout = pya.Layout()
layout.read(in_gds)
copied = 0
for metal in METALS:
    pin = layout.find_layer(metal, 2)
    if pin is None:
        continue
    text = layout.layer(metal, 25)
    for cell in layout.each_cell():
        for shape in cell.shapes(pin).each(pya.Shapes.STexts):
            cell.shapes(text).insert(shape.text)
            copied += 1
layout.write(out_gds)
print(f"relabel: copied {copied} texts into {out_gds}")

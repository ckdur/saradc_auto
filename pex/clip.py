# Clips a window of the SARADC layout and labels the nets inside it.
# Every DEF net (special or regular) with wiring inside the window gets a text
# with its name on the text datatype (L/25) of that metal, so LVS/PEX of the
# clipped layout keeps the DEF net names.
# Usage:
#   klayout -b -r clip.py -rd gds=<SARADC.gds> -rd def=<SARADC.def> \
#     -rd box="x0 y0 x1 y1" (um) -rd out=<clip.gds> [-rd name=<cell>] [-rd nofill=1]
import re
import pya

LAYERS = {'Metal1': 8, 'Metal2': 10, 'Metal3': 30, 'Metal4': 50, 'Metal5': 67,
          'TopMetal1': 126, 'TopMetal2': 134}
# Default wire widths (um, from the tech LEF) for the regular nets
WIDTHS = {'Metal1': 0.16, 'Metal2': 0.2, 'Metal3': 0.2, 'Metal4': 0.2, 'Metal5': 0.2,
          'TopMetal1': 1.64, 'TopMetal2': 2.0}
cellname = globals().get('name', 'CLIP')
x0, y0, x1, y1 = [float(v) for v in box.split()]


def def_wires(path):
    """Yields (net, layer, xa, ya, xb, yb, half_width) in DEF units for every wire segment."""
    txt = open(path).read()
    dbu = int(re.search(r'UNITS DISTANCE MICRONS (\d+)', txt).group(1))
    for sec in ('SPECIALNETS', 'NETS'):
        body = re.search(r'^%s \d+ ;(.*?)^END %s' % (sec, sec), txt, re.S | re.M).group(1)
        for st in re.split(r';\s*\n', body):
            m = re.match(r'\s*- (\S+)', st)
            if not m:
                continue
            net = m.group(1).replace('\\', '')
            for seg in re.split(r'\+ (?:ROUTED|FIXED|COVER)|\bNEW\b', st)[1:]:
                t = seg.split()
                if not t or t[0] not in LAYERS:
                    continue
                if sec == 'SPECIALNETS' and t[1].isdigit():
                    width = int(t[1])
                else:
                    width = WIDTHS[t[0]] * dbu
                pts = re.findall(r'\( (\S+) (\S+)(?: \S+)? \)', seg)
                if len(pts) == 1 and pts[0][0] != '*' and re.search(r'\)\s+\w', seg):
                    # A via alone (e.g. onto a cell pin): a 0.1 um square on the layer
                    x, y = int(pts[0][0]), int(pts[0][1])
                    d = dbu // 20
                    pts = [(x - d, y), (x + d, y)]
                    width = 2 * d
                if len(pts) < 2:
                    continue
                (xa, ya), (xb, yb) = pts[0], pts[1]
                xa, ya = int(xa), int(ya)
                xb = xa if xb == '*' else int(xb)
                yb = ya if yb == '*' else int(yb)
                yield net, t[0], xa / dbu, ya / dbu, xb / dbu, yb / dbu, width / dbu / 2


# Label points on the centerline of the wires inside the window
labels = []
cut = set()
area = {}
for net, layer, xa, ya, xb, yb, hw in def_wires(globals()['def']):
    # The wire as a rectangle: the width goes across the segment (special
    # wires may be written as short segments with a huge width)
    lo_x, hi_x = sorted((xa, xb))
    lo_y, hi_y = sorted((ya, yb))
    if ya == yb:
        lo_y, hi_y = ya - hw, ya + hw
    else:
        lo_x, hi_x = xa - hw, xa + hw
    ix0, ix1 = max(lo_x, x0), min(hi_x, x1)
    iy0, iy1 = max(lo_y, y0), min(hi_y, y1)
    # Only wires that really overlap the window (not just touching its edge)
    if ix0 >= ix1 or iy0 >= iy1:
        continue
    if lo_x < x0 or hi_x > x1 or lo_y < y0 or hi_y > y1:
        cut.add(net)
    # Every segment gets a label: pieces of a net that only connect outside
    # the window would be anonymous otherwise
    labels.append((net, layer, (ix0 + ix1) / 2, (iy0 + iy1) / 2))
    area[net] = area.get(net, 0.0) + (ix1 - ix0) * (iy1 - iy0)

layout = pya.Layout()
layout.read(gds)
top = layout.top_cell()
dbu = layout.dbu
if globals().get('nofill'):
    for c in [c for c in layout.each_cell() if c.name == 'SARADC_FILL1_NOPOWER']:
        for inst in list(c.each_parent_inst()):
            inst.inst().delete()

clip_index = layout.clip(top.cell_index(), pya.DBox(x0, y0, x1, y1))
clip = layout.cell(clip_index)
clip.name = cellname
for net, layer, x, y in labels:
    li = layout.layer(LAYERS[layer], 25)
    clip.shapes(li).insert(pya.DText(net, pya.DTrans(x, y)))

# Anchors: a 0.1x0.1um square of the same metal in a subcell, on every label.
# The netlist extraction drops nets without devices (e.g. a stripe crossing a
# piece); a net connected to a subcell pin is always kept. The square is inside
# the wire, so it adds no geometry.
if globals().get('anchors', '1') != '0':
    anchor = {}
    for layer, num in LAYERS.items():
        cell = layout.create_cell(f'PEX_ANCHOR_{layer}')
        cell.shapes(layout.layer(num, 0)).insert(pya.DBox(-0.05, -0.05, 0.05, 0.05))
        anchor[layer] = cell.cell_index()
    for net, layer, x, y in labels:
        clip.insert(pya.DCellInstArray(anchor[layer], pya.DTrans(x, y)))

# Write only the clipped cell and what it instantiates
out_layout = pya.Layout()
out_layout.dbu = dbu
out_top = out_layout.create_cell(cellname)
out_top.copy_tree(clip)
out_layout.write(out)
nets = sorted(set(n for n, _, _, _ in labels))
print(f'clip: {len(nets)} nets labeled, {len(cut)} cut by the window, written to {out}')
# Net, whether the window cuts it, and its wire area inside the window (um2)
open(out + '.nets', 'w').write('\n'.join(f'{n} {"CUT" if n in cut else "IN"} {area[n]:.3f}' for n in nets) + '\n')

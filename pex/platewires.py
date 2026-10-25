"""Geometric attribution of the DAC plate couplings to the comparator inputs, from the DEF.
For the switched (VSH) and floating (FL) plate of every bit of both halves, it reports, per unit
capacitor, where the routed plate wires (special nets of the DEF, no cell-internal metal) come close
to VOUTH and VOUTL:
  - lateral: facing length (um) on the same layer within --dist (default 1 um), per gap;
  - overlap: area (um2) where the plate crosses VOUTH/VOUTL on the layer above or below.
This tells which layer and which wires make the couplings that sim/pex/dacpar.py measures.
Usage: python3 pex/platewires.py <SARADC.def> [--style legacy|macro] [--dist 1.0] [--prefix analog/]
         [--json out.json]
  legacy: pnr_legacy/outputs*/SARADC.def (flat flow, both halves); macro: pnr/outputs/SARADC_CDAC.def
(run in the venv: it needs klayout.db)."""
import os
import json
import re
import sys
from collections import defaultdict

import klayout.db as db

NBITS = int(os.environ.get("NBITS", 5))  # settings.mk
LAYERS = ['Metal1', 'Metal2', 'Metal3', 'Metal4', 'Metal5', 'TopMetal1', 'TopMetal2']


def special_wires(path):
    """{net: {layer: Region}} of the wire segments of SPECIALNETS (vias left out)."""
    nets = defaultdict(lambda: defaultdict(db.Region))
    txt = open(path).read()
    sec = txt[txt.index('\nSPECIALNETS'):txt.index('\nEND SPECIALNETS')]
    for blk in re.split(r'\n\s*- ', sec)[1:]:
        net = blk.split()[0].replace('\\', '')
        for m in re.finditer(r'(?:ROUTED|NEW)\s+(\S+)\s+(\d+)([^\n]*)', blk):
            layer, w, rest = m.group(1), int(m.group(2)), m.group(3)
            pts = re.findall(r'\(\s*(\S+)\s+(\S+)(?:\s+\S+)?\s*\)', rest)
            if w == 0 or len(pts) < 2:
                continue
            x, y = int(pts[0][0]), int(pts[0][1])
            for px, py in pts[1:]:
                x2 = x if px == '*' else int(px)
                y2 = y if py == '*' else int(py)
                h = w // 2
                if y2 == y:
                    nets[net][layer].insert(db.Box(min(x, x2), y - h, max(x, x2), y + h))
                else:
                    nets[net][layer].insert(db.Box(x - h, min(y, y2), x + h, max(y, y2)))
                x, y = x2, y2
    for n in nets:
        for l in nets[n]:
            nets[n][l].merge()
    return nets


def plates(prefix, style):
    """(half, bit, VSH net, FL net); LSB_*[1..4] are bits 0..3 ([0] is the termination unit).
    legacy: both halves of the flat flow (LSB_H_VSH[1], ...); macro: the SARADC_CDAC macro of
    pnr/ (LSB_VSH[1], ..., one half, its MSB on VOUTH), reported as half M."""
    halves = [('M', '')] if style == 'macro' else [('H', 'H_'), ('L', 'L_')]
    for half, h in halves:
        for b in range(NBITS - 1):
            yield half, b, f'{prefix}LSB_{h}VSH[{b + 1}]', f'{prefix}LSB_{h}FL[{b + 1}]'
        yield half, NBITS - 1, f'{prefix}MSB_{h}VSH', f'{prefix}MSB_{h}FL'


def main():
    path = sys.argv[1]
    arg = lambda k, d: sys.argv[sys.argv.index(k) + 1] if k in sys.argv else d
    dist = float(arg('--dist', '1.0'))
    style = arg('--style', 'legacy')
    prefix = arg('--prefix', '' if style == 'macro' else 'analog/')
    nets = special_wires(path)
    dbu = 1000
    d = int(dist * dbu)
    res = {}
    print(f'per unit capacitor; lateral: facing length (um) within {dist} um, overlap: area (um2) one layer up/down')
    for half, b, vsh, fl in plates(prefix, style):
        n = 2 ** b
        for kind, net in (('VSH', vsh), ('FL', fl)):
            row = {}
            for top in ('VOUTH', 'VOUTL'):
                tn = prefix + top
                for li, layer in enumerate(LAYERS):
                    a = nets[net].get(layer)
                    if a is None or a.is_empty():
                        continue
                    t = nets[tn].get(layer)
                    if t is not None and not t.is_empty():
                        # Facing length per gap: sum of length / gap (a parallel-plate measure, um/um)
                        for e in a.separation_check(t, d):
                            g = max(e.distance(), 1) / dbu
                            key = f'{top} lat {layer} gap {g:.2f}'
                            row[key] = row.get(key, 0) + e.first.length() / dbu / n
                    for lj in (li - 1, li + 1):
                        if 0 <= lj < len(LAYERS):
                            t = nets[tn].get(LAYERS[lj])
                            if t is not None and not t.is_empty():
                                ov = (a & t).area() / dbu ** 2
                                if ov > 0:
                                    row[f'{top} ovl {layer}/{LAYERS[lj]}'] = ov / n
            res[f'{half}{b}_{kind}'] = row
            print(f'{half} bit {b} {kind:3s}: ' + ', '.join(f'{k} {v:.2f}' for k, v in sorted(row.items())))
    if '--json' in sys.argv:
        with open(arg('--json', ''), 'w') as f:
            json.dump(res, f, indent=1)


if __name__ == '__main__':
    main()

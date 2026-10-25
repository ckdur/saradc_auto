"""Parasitic capacitance of the CDAC plates per bit, from a stitched post-layout netlist.
For the switched plate (VSH) and the floating plate (FL) of every bit of both halves, the total
wiring C and its split by the other net, per unit capacitor (bit b has 2**b units).
Usage: python3 dacpar.py <stitched.ckt> [--style legacy|hier] [--json out.json]"""
import os
import json
import re
import sys
from collections import defaultdict

import capsum

NBITS = int(os.environ.get("NBITS", 5))  # settings.mk


def plates(half, style):
    """[(bit, VSH net, FL net)] of one half (H or L)."""
    if style == 'legacy':
        out = [(b, f'analog/LSB_{half}_VSH[{b + 1}]', f'analog/LSB_{half}_FL[{b + 1}]') for b in range(NBITS - 1)]
        return out + [(NBITS - 1, f'analog/MSB_{half}_VSH', f'analog/MSB_{half}_FL')]
    inst = f'analog/cdac_{half.lower()}/'
    out = [(b, f'{inst}LSB_VSH[{b + 1}]', f'{inst}LSB_FL[{b + 1}]') for b in range(NBITS - 1)]
    return out + [(NBITS - 1, f'{inst}MSB_VSH', f'{inst}MSB_FL')]


def group(net, own):
    if net in own:
        return 'own'
    if re.search(r'VOUT[HL]$', net):
        return net.split('/')[-1]
    if net in ('VSS', 'AVDD', 'VDD'):
        return 'supply'
    if re.search(r'VREF|VI[PN]$', net):
        return 'vref/vin'
    if re.search(r'CR[HL]B?\b|CRH|CRL|CPRE|CHOLD', net):
        return 'controls'
    if re.search(r'VSH|FL', net):
        return 'other plates'
    return 'other'


def main():
    path = sys.argv[1]
    style = sys.argv[sys.argv.index('--style') + 1] if '--style' in sys.argv else 'legacy'
    pair, total = capsum.read([path])
    cols = ['VOUTH', 'VOUTL', 'supply', 'vref/vin', 'controls', 'other plates', 'own', 'other']
    res = {}
    for half in ('H', 'L'):
        print(f'== {half} half: wiring C per unit (fF); bit b has 2**b units')
        print(f'{"plate":10s} {"total":>7s} ' + ' '.join(f'{c:>8s}' for c in cols))
        for b, vsh, fl in plates(half, style):
            for kind, net in (('VSH', vsh), ('FL', fl)):
                split = defaultdict(float)
                for (x, y), c in pair.items():
                    if net in (x, y):
                        split[group(y if x == net else x, (vsh, fl))] += c
                n = 2 ** b
                res[f'{half}{b}_{kind}'] = {'units': n, 'total_f': total.get(net, 0)} | {c: split[c] for c in cols}
                print(f'b{b} {kind:6s} {total.get(net, 0) / n * 1e15:7.2f} ' +
                      ' '.join(f'{split[c] / n * 1e15:8.2f}' for c in cols))

    if '--json' in sys.argv:
        with open(sys.argv[sys.argv.index('--json') + 1], 'w') as f:
            json.dump(res, f, indent=1)


if __name__ == '__main__':
    main()

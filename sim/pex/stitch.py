"""Stitches the pieces of split extractions (pex/split.py) into one flat netlist.
The top level comes from one or more split runs of the top layout (macros removed);
each macro instance of the top CDL gets the pieces of its own split run, with its
ports mapped to the top nets and its internal nets prefixed with the instance name.
In every piece: a net split by a cut (name$N) is the net name, anonymous nets
($N, inside a cell) stay local to the piece, VSUBS (substrate) is the ground net.
The MOS become instances of the PDK subcircuits (X...), as in the flat schematic.
Usage: python3 stitch.py <out.ckt> --cdl pnr/outputs/SARADC.cdl --top <pieces.txt>...
         [--macro SARADC_CDAC=<pieces.txt>:<macro.cdl>]... [--cell SARADC] [--gnd VSS]
         [--check <flat schematic>]
--check compares, per named net, the MOS width on gates, source/drain and bulk
with a flat schematic (adc_char.flatten), whose instance paths (Xinst.net) are
mapped to the stitched ones (inst/net)."""
import argparse
import os
import re
from collections import defaultdict

MOS_MODELS = ('sg13_lv_nmos', 'sg13_lv_pmos', 'sg13_hv_nmos', 'sg13_hv_pmos')


def lines_of(path):
    """Lines of a SPICE file with the continuations joined, comments dropped."""
    lines = []
    for line in open(path):
        if line.startswith('+') and lines:
            lines[-1] += ' ' + line[1:].strip()
        elif line.strip() and not line.startswith('*'):
            lines.append(line.strip())
    return lines


def subckts(path):
    """{name: (ports, [element tokens])} of a CDL/SPICE file (backslashes removed)."""
    subs, cur = {}, None
    for line in lines_of(path):
        tok = line.replace('\\', '').split()
        k = tok[0].lower()
        if k == '.subckt':
            cur = tok[1]
            subs[cur] = ([t for t in tok[2:] if '=' not in t], [])
        elif k == '.ends':
            cur = None
        elif cur is not None:
            subs[cur][1].append(tok)
    return subs


def pieces(path):
    """(name, netlist) of the pieces listed in a pieces.txt of split.py."""
    return [(l.split()[0], l.split()[5]) for l in open(path) if l.strip()]


def emit_piece(path, tag, netmap, out, gnd):
    """Appends the elements of one piece netlist to out, the nets renamed by netmap
    (net name -> stitched name). Returns the number of MOS and C."""
    def net(n):
        n = n.replace('\\', '')
        if n == 'VSUBS':
            return netmap(gnd)
        if n.startswith('$'):
            return f'{tag}{n}'
        return netmap(re.sub(r'\$\d+$', '', n))
    nm = nc = 0
    for line in lines_of(path):
        tok = line.split()
        k = tok[0][0].upper()
        if tok[0].startswith('.'):
            continue
        if k == 'M':
            nm += 1
            par = ' '.join(t.lower() for t in tok[6:])
            out.append(f'X{tag}{tok[0][1:].replace("$", "")} {" ".join(net(n) for n in tok[1:5])} {tok[5]} {par}')
        elif k == 'C':
            a, b = net(tok[1]), net(tok[2])
            if a == b:
                continue
            nc += 1
            out.append(f'C{tag}{nc} {a} {b} {tok[3]}')
        else:
            raise ValueError(f'{path}: unsupported element {tok[0]}')
    return nm, nc


def mos_signature(lines):
    """{net: {(model, role): W}} of the MOS lines (X d g s b model w=.. [m=..])."""
    sig = defaultdict(lambda: defaultdict(float))
    for line in lines:
        tok = line.split()
        if not tok or tok[0][0] not in 'Xx' or len(tok) < 6 or tok[5].lower() not in MOS_MODELS:
            continue
        par = {t.split('=')[0].lower(): t.split('=')[1] for t in tok[6:] if '=' in t}
        w = spice_num(par.get('w', '0')) * spice_num(par.get('m', '1'))
        model = tok[5].lower()
        for n, role in zip(tok[1:5], ('sd', 'g', 'sd', 'b')):
            sig[n][(model, role)] += w
    return sig


def spice_num(s):
    m = re.match(r'([-+\d.eE]+)([a-zA-Z]*)', s)
    mult = {'f': 1e-15, 'p': 1e-12, 'n': 1e-9, 'u': 1e-6, 'm': 1e-3, 'k': 1e3, 'meg': 1e6}
    return float(m.group(1)) * mult.get(m.group(2).lower(), 1.0)


def check(stitched, schematic):
    """Compares the MOS signature per net. Nets of the schematic inside cells (names
    with an instance path of a cell) have no layout name and are skipped."""
    lay = mos_signature(stitched)
    sch = defaultdict(lambda: defaultdict(float))
    for n, s in mos_signature(l.replace('\\', '') for l in lines_of(schematic)).items():
        # Xanalog/cdac_h.net -> analog/cdac_h/net (macro nets); leaves others
        m = re.match(r'X([^.]*cdac_[hl])\.(.*)', n)
        sch[f'{m.group(1)}/{m.group(2)}' if m else n] = s
    bad = 0
    named = [n for n in sch if n in lay]
    for n in named:
        for k in set(sch[n]) | set(lay[n]):
            a, b = lay[n].get(k, 0.0), sch[n].get(k, 0.0)
            if abs(a - b) > 1e-9 + 1e-3 * max(a, b):
                bad += 1
                if bad <= 20:
                    print(f'  {n} {k}: layout {a * 1e6:.3f} um, schematic {b * 1e6:.3f} um')
    sw = lambda s: sum(sum(v.values()) for v in s.values())
    print(f'check: {len(named)} nets in both, {bad} mismatches; '
          f'schematic nets not in layout: {len(set(sch) - set(lay))}, layout nets not in schematic: '
          f'{len(set(lay) - set(sch))}; total W layout {sw(lay) * 1e6:.1f} um, schematic {sw(sch) * 1e6:.1f} um')
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--cdl', required=True, help='top CDL: ports and macro instances')
    ap.add_argument('--cell', default='SARADC')
    ap.add_argument('--top', nargs='+', required=True, help='pieces.txt of the top level')
    ap.add_argument('--macro', action='append', default=[], help='MASTER=<pieces.txt>:<macro.cdl>')
    ap.add_argument('--gnd', default='VSS', help='net of the substrate (VSUBS)')
    ap.add_argument('--check', help='flat schematic to compare with')
    a = ap.parse_args()

    top = subckts(a.cdl)[a.cell]
    out = []
    stats = defaultdict(lambda: [0, 0])
    for pt in a.top:
        run = os.path.basename(os.path.dirname(os.path.abspath(pt)))
        for name, path in pieces(pt):
            r = emit_piece(path, f'top_{run}_{name}_', lambda n: n, out, a.gnd)
            stats['top'][0] += r[0]
            stats['top'][1] += r[1]
    for spec in a.macro:
        master, rest = spec.split('=', 1)
        pt, mcdl = rest.split(':', 1)
        mports = subckts(mcdl)[master][0]
        insts = [t for t in top[1] if t[-1] == master]
        if not insts:
            raise ValueError(f'no instance of {master} in {a.cdl}')
        for t in insts:
            inst = t[0][1:]
            pmap = dict(zip(mports, t[1:-1]))
            netmap = lambda n, pmap=pmap, inst=inst: pmap.get(n, f'{inst}/{n}')
            for name, path in pieces(pt):
                r = emit_piece(path, f'{inst.replace("/", "_")}_{name}_', netmap, out, a.gnd)
                stats[inst][0] += r[0]
                stats[inst][1] += r[1]
    with open(a.out, 'w') as f:
        f.write(f'* {a.cell} stitched from split extractions by sim/pex/stitch.py\n')
        f.write(f'.subckt {a.cell} {" ".join(top[0])}\n')
        f.write('\n'.join(out) + '\n.ends\n')
    for k, (m, c) in stats.items():
        print(f'{k}: {m} MOS, {c} C')
    print(f'wrote {a.out}')
    if a.check:
        check(out, a.check)


if __name__ == '__main__':
    main()

"""Summarizes the parasitic capacitances of kpex netlists.
Several netlists (pieces of a split extraction) are summed. Pieces of a net split
by a clip (name$N) are merged into the net.
Usage: python3 capsum.py <pex.spice>... [--show <regex>] [--vs <pex.spice>...]
  --vs: compares the per-net totals against another (set of) netlist(s)."""
import argparse
import re
from collections import defaultdict

UNITS = {'f': 1e-15, 'a': 1e-18, 'p': 1e-12, 'n': 1e-9}


def value(s):
    m = re.match(r'([\d.eE+-]+)([afpn]?)', s)
    return float(m.group(1)) * UNITS.get(m.group(2), 1.0)


def base(net):
    return re.sub(r'(?<=.)\$\d+$', '', net.replace('\\', ''))


def read(paths):
    """Returns ({(net_a, net_b): C}, {net: total C}) summed over the netlists."""
    pair = defaultdict(float)
    total = defaultdict(float)
    for path in paths:
        lines = []
        for line in open(path):
            if line.startswith('+') and lines:
                lines[-1] += ' ' + line[1:]
            else:
                lines.append(line)
        for line in lines:
            t = line.split()
            if not t or not t[0].upper().startswith('C'):
                continue
            a, b, c = base(t[1]), base(t[2]), value(t[3])
            # Anonymous nets ($N) of different pieces are different nets
            if a.startswith('$'):
                a = f'{path}:{a}'
            if b.startswith('$'):
                b = f'{path}:{b}'
            if a == b:
                continue
            pair[tuple(sorted((a, b)))] += c
            total[a] += c
            total[b] += c
    return pair, total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('netlists', nargs='+')
    ap.add_argument('--show', default='^[^$/]|^analog')
    ap.add_argument('--vs', nargs='+')
    a = ap.parse_args()
    show = re.compile(a.show)
    pair, total = read(a.netlists)
    if a.vs:
        _, ref = read(a.vs)
        print(f'{"net":45s} {"fF":>9s} {"vs fF":>9s} {"diff":>7s}')
        for net in sorted(ref, key=lambda n: -ref[n]):
            if show.search(net):
                d = (total.get(net, 0) - ref[net]) / ref[net] * 100
                print(f'{net:45s} {total.get(net, 0) * 1e15:9.2f} {ref[net] * 1e15:9.2f} {d:+6.1f}%')
        return
    print(f'{"net":45s} {"total fF":>9s}   largest couplings (fF)')
    for net in sorted(total, key=lambda n: -total[n]):
        if not show.search(net):
            continue
        cpl = sorted(((c, b if a == net else a) for (a, b), c in pair.items() if net in (a, b)), reverse=True)
        top = ', '.join(f'{o.replace("analog/", "")} {c * 1e15:.2f}' for c, o in cpl[:4])
        print(f'{net:45s} {total[net] * 1e15:9.2f}   {top}')


if __name__ == '__main__':
    main()

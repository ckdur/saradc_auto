"""Split extraction: clips a region of the layout into pieces, extracts each one
with kpex 2.5D (CC) in parallel, and checks that the labeled nets became ports.
Usage: python3 split.py <out_dir> --xs x0 x1 ... --ys y0 y1 ... [-j 28] [--gds G --def D]
The pieces are the cells of the grid xs x ys (um). The layout defaults to the
flat legacy PnR re-run (signoff/outputs_legacy/SARADC.gds, pnr_legacy/outputs/SARADC.def)."""
import argparse
import glob
import os
import re
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..'))
GDS = os.path.join(ROOT, 'signoff', 'outputs_legacy', 'SARADC.gds')
DEF = os.path.join(ROOT, 'pnr_legacy', 'outputs', 'SARADC.def')


def make_deck(out):
    """Copy of the kpex IHP LVS deck that does not purge the floating nets.
    The deck purges the layout netlist after mapping the RF MOS models, which
    drops every net without devices (e.g. a stripe crossing a piece), and kpex
    only extracts the nets of the netlist."""
    import klayout_pex
    src = os.path.join(os.path.dirname(klayout_pex.__file__), 'pdk', 'ihp-sg13g2', 'libs.tech', 'kpex')
    deck = os.path.join(out, 'lvs_deck')
    shutil.rmtree(deck, ignore_errors=True)
    shutil.copytree(src, deck)
    rf = os.path.join(deck, 'rule_decks', 'rfmos_model_mapping.lvs')
    txt = open(rf).read()
    old = '  target_netlist.purge_devices\n  target_netlist.purge\n'
    assert old in txt, 'unexpected rfmos_model_mapping.lvs, check the purge patch'
    open(rf, 'w').write(txt.replace(old, '  target_netlist.purge_devices if PURGE\n  target_netlist.purge if PURGE\n'))
    return os.path.join(deck, 'sg13g2.lvs')


def run_piece(out, deck, name, box, gds_in, def_in):
    gds = os.path.join(out, name + '.gds')
    lvsdb = os.path.join(out, name + '.lvsdb')
    subprocess.run(['klayout', '-b', '-r', os.path.join(HERE, 'clip.py'), '-rd', f'gds={gds_in}',
                    '-rd', f'def={def_in}', '-rd', f'box={box}', '-rd', f'out={gds}', '-rd', f'name={name}',
                    '-rd', 'anchors=0'],
                   check=True, capture_output=True)
    # The LVSDB is only written after a comparison: compare against an empty
    # schematic, as kpex does
    schematic = os.path.join(out, name + '_dummy_schematic.spice')
    open(schematic, 'w').write(f'.subckt {name} VDD VSS\n.ends\n.end\n')
    with open(os.path.join(out, name + '.log'), 'w') as log:
        # Same options kpex uses for its own LVS run
        subprocess.run(['klayout', '-b', '-r', deck, '-rd', f'input={gds}', '-rd', f'report={lvsdb}',
                        '-rd', f'schematic={schematic}',
                        '-rd', f'topcell={name}', '-rd', 'thr=1', '-rd', 'run_mode=deep',
                        '-rd', 'spice_net_names=true', '-rd', 'spice_comments=false', '-rd', 'scale=false',
                        '-rd', 'net_only=false', '-rd', 'top_lvl_pins=true', '-rd', 'combine=false',
                        '-rd', 'combine_devices=false', '-rd', 'purge=false', '-rd', 'purge_nets=false',
                        '-rd', 'no_simplify=true', '-rd', f'target_netlist={os.path.join(out, name + ".cir")}'],
                       cwd=out, stdout=log, stderr=subprocess.STDOUT, check=True)
        if not os.path.isfile(lvsdb):
            raise RuntimeError(f'{name}: the LVS did not write {lvsdb}')
        subprocess.run(['kpex', '--pdk', 'ihp-sg13g2', '--lvsdb', name + '.lvsdb', '--cell', name,
                        '--2.5D', '--mode', 'CC', '--out_dir', name], cwd=out, stdout=log,
                       stderr=subprocess.STDOUT, check=True)


def netlist(out, name):
    return glob.glob(os.path.join(out, name, '**', f'{name}_k25d_pex_netlist.spice'), recursive=True)[0]


def ports(path):
    txt = open(path).read()
    hdr = re.search(r'^\.SUBCKT (.*?)\n(?!\+)', txt, re.S | re.M).group(1).replace('\n+', ' ').split()
    return hdr[0], hdr[1:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--xs', nargs='+', type=float, required=True)
    ap.add_argument('--ys', nargs='+', type=float, required=True)
    ap.add_argument('-j', type=int, default=28)
    ap.add_argument('--gds', default=GDS)
    ap.add_argument('--def', dest='def_', default=DEF)
    ap.add_argument('--min_area', type=float, default=1.0,
                    help='report dropped nets with more wire area than this (um2)')
    ap.add_argument('--check', action='store_true', help='only re-check existing pieces')
    a = ap.parse_args()
    a.out = os.path.abspath(a.out)
    global args_min
    args_min = a.min_area
    os.makedirs(a.out, exist_ok=True)
    pieces = []
    for i in range(len(a.xs) - 1):
        for j in range(len(a.ys) - 1):
            pieces.append((f'P{i}_{j}', f'{a.xs[i]} {a.ys[j]} {a.xs[i + 1]} {a.ys[j + 1]}'))
    if not a.check:
        deck = make_deck(a.out)
        with ThreadPoolExecutor(a.j) as ex:
            list(ex.map(lambda p: run_piece(a.out, deck, *p, os.path.abspath(a.gds), os.path.abspath(a.def_)), pieces))
    missing = 0
    with open(os.path.join(a.out, 'pieces.txt'), 'w') as f:
        for name, box in pieces:
            # Nets present in the extracted netlist (ports or internal)
            base = set(re.sub(r'\$\d+$', '', n.replace('\\', ''))
                       for n in re.findall(r'\S+', open(netlist(a.out, name)).read()))
            labeled = {}
            for line in open(os.path.join(a.out, name + '.gds.nets')):
                if not line.strip():
                    continue
                net, _, area = line.split()
                labeled[net] = float(area)
            miss = sorted(n for n in labeled if n not in base)
            # Wire area of the nets missing in the extracted netlist
            dropped = sum(labeled[n] for n in miss)
            missing += dropped
            f.write(f'{name} {box} {netlist(a.out, name)}\n')
            big = [f'{n}({labeled[n]:.1f})' for n in miss if labeled[n] > args_min]
            if big:
                print(f'{name}: missing nets with wire area > {args_min} um2: {" ".join(big)}')
    print(f'{len(pieces)} pieces extracted in {a.out}; {missing:.1f} um2 of wire missing in total')


if __name__ == '__main__':
    main()

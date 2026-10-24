"""Copies a stitched netlist keeping only some of its parasitic capacitors, to find out which
parasitics matter. A capacitor is selected when one of its two nets matches the regex.
Usage: python3 cfilter.py <in.ckt> <out.ckt> (--keep REGEX | --drop REGEX)"""
import argparse
import re


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('dst')
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--keep')
    g.add_argument('--drop')
    a = ap.parse_args()
    rx = re.compile(a.keep or a.drop)
    n = kept = 0
    with open(a.src) as fi, open(a.dst, 'w') as fo:
        for line in fi:
            if line[0] in 'Cc':
                t = line.split()
                n += 1
                hit = bool(rx.search(t[1]) or rx.search(t[2]))
                if hit != bool(a.keep):
                    continue
                kept += 1
            fo.write(line)
    print(f'{kept} of {n} capacitors kept')


if __name__ == '__main__':
    main()

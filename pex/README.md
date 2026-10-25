# Layout extraction of the SARADC

Everything that produces an extracted (post-layout) netlist. The tools that use those netlists in
simulation are in `sim/pex/`. All commands run from the root of `saradc_auto` after
`source ~/init_openlane.sh`. Results go to `pex/outputs/` (git-ignored).

| Path | What it does | Output |
|---|---|---|
| `split.py` | split extraction: clips the layout into a grid of pieces and extracts each with kpex 2.5D (CC) in parallel. **This is the method that works.** | `pex/outputs/<run>/` |
| `clip.py` | (used by `split.py`) clips one window of the GDS and labels every DEF net segment inside it | `<piece>.gds`, `<piece>.gds.nets` |
| `platewires.py` | geometric attribution of the DAC plate couplings to VOUTH/VOUTL from the DEF (layer, facing length per gap, overlaps); see `docs/dac_wiring.md` | stdout, `--json` |
| `nomacro.py`, `hier_pex.sh` | the top without the macros; the whole hierarchical extraction of one layout variant | `pex/outputs/{cdac,top}_<tag>/` |
| `relabel.py` | copies the cell pin texts (L/2) to the text datatype (L/25) that the IHP LVS reads | |
| `magic/` | `magic_pex.sh`: magic extraction of the whole layout, netgen LVS, `pex2xyce.py` | `pex/outputs/magic/` |
| `kpex_full/` | `kpex.sh`: the kpex 2.5D runs on the whole flat layout (never finished), `strip_fill.py` | `pex/outputs/kpex_full/` |

## Split extraction (`split.py`)

```bash
X="0 104.32 188.64 272.96 357.28 451.92"
python3 pex/split.py pex/outputs/arrH --xs $X --ys 0 39.6 60.84 82.08 103.32 124.56 153          # lower (H) array
python3 pex/split.py pex/outputs/arrL --xs $X --ys 208.08 235.44 256.68 277.92 299.16 320.40 361.08  # upper (L) array
```

The pieces are the cells of the grid `xs x ys` (um). With 28 jobs, each array (30 pieces) takes
about 2.5 min. The layout defaults to the re-run of the flat PnR (`signoff/outputs_legacy/SARADC.gds`,
`pnr_legacy/outputs/SARADC.def`); `--gds`/`--def` select another one, e.g. the taped-out one in
`signoff/outputs.tapeout/` and `pnr_legacy/outputs.tapeout/`, or a macro of the hierarchical PnR:

```bash
python3 pex/split.py pex/outputs/cdac --gds signoff/outputs/SARADC_CDAC.gds --def pnr/outputs/SARADC_CDAC.def \
  --xs 0 87.52 171.84 256.16 340.48 429.48 --ys 0 22.8 44.04 65.28 86.52 107.76 144.48
```

The taped-out layout (what was fabricated and measured) is split in two runs, the analog part
(arrays and channel; the cut at y 177.48 is a row boundary, 180.54 would cut cells) and the digital
column on the right, on its own row boundaries (81 pieces, 6.6 min with 16 jobs):

```bash
G="--gds signoff/outputs.tapeout/SARADC.gds --def pnr_legacy/outputs.tapeout/SARADC.def"
python3 pex/split.py pex/outputs/tapeout/ana $G -j 16 --xs 0 104.32 188.64 272.96 357.28 451.92 \
  --ys 0 39.6 60.84 82.08 103.32 124.56 153 177.48 208.08 235.44 256.68 277.92 299.16 320.40 361.08
python3 pex/split.py pex/outputs/tapeout/dig $G -j 11 --xs 451.92 566.44 \
  --ys 0 48.96 79.56 110.16 140.76 171.36 201.96 232.56 263.16 293.76 324.36 361.08
```

The top level of the hierarchical layout is extracted without the macros (the stitcher puts the
macro extraction in their place, `sim/pex/stitch.py`):

```bash
klayout -b -r pex/nomacro.py -rd gds=signoff/outputs/SARADC.gds -rd out=pex/outputs/top/SARADC_nomacro.gds
python3 pex/split.py pex/outputs/top/split --gds pex/outputs/top/SARADC_nomacro.gds --def pnr/outputs/SARADC.def -j 14 \
  --xs 0 109.18 233.54 320.32 452.0 566.44 \
  --ys 0 48.96 79.56 110.16 140.76 171.36 189.72 214.2 232.56 263.16 293.76 324.36 410.04
```

The grids above (and those in `hier_pex.sh`) are for the 5-bit layout: for another `NBITS` the
macro and the die change size, and the cut lines must be chosen again (between tiles and on row
boundaries). `platewires.py` and `sim/pex/dacpar.py` take the number of bits from `NBITS`.

`pex/hier_pex.sh <tag>` does all of it for the current `pnr/` + `signoff/outputs` (macro split, top
split, stitch with the check against the flat schematic, `dacpar.py`; ~6 min) into
`pex/outputs/{cdac,top}_<tag>/` and `sim/outputs/pex/SARADC_<tag>.{pex.ckt,flat.ckt,plate_par.json}`.

`nomacro.py` must remove the macro with `prune_cell`: `delete_cell_rec` also deletes the vias and
the cells shared with the top level. The cut lines may only cross fillers and taps (the ys are row
boundaries; y = 164.64 or 241.92 would cut digital cells on the right).

For each piece:
1. `clip.py` clips the GDS and adds a text with the DEF net name on every wire segment inside the
   window (special and regular nets; one label per segment, so a piece of a net that only
   connects outside the window still gets its name). It writes `<piece>.gds.nets`: the labeled
   nets, whether the window cuts them, and their wire area inside it.
2. KLayout LVS with a copy of the kpex IHP deck (`<run>/lvs_deck`) that does not purge the
   netlist: the deck's `rfmos_model_mapping.lvs` purges unconditionally, which drops every net
   without devices (a stripe crossing a piece), and kpex only extracts the nets of the netlist.
   The comparison is against a dummy schematic, only to get the LVSDB written.
3. `kpex --lvsdb <piece>.lvsdb --2.5D --mode CC`.

At the end it lists, per piece, the labeled nets missing from the extracted netlist (with their
wire area) and writes `pieces.txt` (`name x0 y0 x1 y1 netlist`). `--check` only re-does that
check on existing pieces. Both arrays extract with 0 um2 of wire missing. A net split by a cut
appears as `name$N` in the netlists; `sim/pex/capsum.py` merges them.

Single pieces scale badly (`pex/outputs/hier/b*`, one job each): 895 um2 25 s / 1.2 GB, 3582 um2
141 s / 4.4 GB, 10746 um2 742 s / 13 GB, 30919 um2 3691 s / 30 GB (time ~ area^1.5).
kpex on the whole macro (62051 um2, its own LVS, `--threads 4`) was stopped by the 4 h timeout
inside the 2.5D engine, single-threaded.

Grid choice (legacy arrays): the cuts run between tiles (pitch 42.16 um x 21.24 um, H tile rows from y = 18.36,
L cap rows from 214.2) so that no unit capacitor is cut. The channel (comparator, switches,
VREF/VIN/VIP stripes, y 153 ... 208) is not extracted yet.

## Whole-layout extraction (did not give a usable netlist)

Run on 2026-10-22..24 on the taped-out layout (then in `signoff/outputs`, now
`signoff/outputs.tapeout`); both scripts take the layout directory as an argument.

```bash
pex/magic/magic_pex.sh signoff/outputs.tapeout          # ~minutes
pex/kpex_full/kpex.sh lvs signoff/outputs.tapeout       # KLayout LVS with the std cells flattened: matches
pex/kpex_full/kpex.sh run4 signoff/outputs.tapeout      # or run1 .. run4, each > 10 h
```

- magic 8.3.623: the device counts match the schematic (12093 nMOS, 12105 pMOS), but the
  capacitances are about 100x too large (4.27 nF on AVDD, ~415 pF on one switch output, the whole
  DAC is ~10 pF), and netgen 1.5.287 cannot compare the netlists (transistors written as calls to
  undefined `sg13_lv_nmos`/`pmos`). `SARADC.pex.xyce.ckt` is the netlist wrapped with the schematic
  port order.
- kpex 0.3.12 / KLayout 0.30.10: LVS needs the schematic with the standard cells flattened
  (`signoff/tcl/flatstd.py`) because the `sg13g2f` cell layouts have no pin labels. The 2.5D
  engine is single-threaded on the flat layout: run1 (kpex's own LVS, 4 h limit), run2 (from the
  clean LVS database, 12 h), run3 (`--halo 1`, 10 h) and run4 (fillers removed by
  `strip_fill.py`, halo 1, stopped by hand after 16 h) all ended inside the engine.
  `pex/outputs/kpex_full/SARADC_extracted.cir` is the KLayout LVS extraction (devices only)
  written by run4.

## `pex/outputs/`

| Directory | Content |
|---|---|
| `arrH/`, `arrL/` | split extraction of the two capacitor arrays (flat PnR re-run) |
| `cdac/` | split extraction of the `SARADC_CDAC` macro (hierarchical PnR) |
| `top/` | the top level of the hierarchical PnR without the macros (`split/`, 60 pieces) |
| `tapeout/` | the taped-out layout: `ana/` (70 pieces), `dig/` (11 pieces) |
| `hier/` | tests on the hierarchical layout: `channel/` (first channel split, its right column cuts digital rows), `b1_1tile` .. `b4_half` (single-piece scaling), `cdac_full/` (kpex on the whole macro) |
| `tests/` | first single-piece tests: `t1_cap` (one cap cell), `t2` (2 tiles), `t3*` (2x2), `t4` (4x3) |
| `magic/`, `kpex_full/` | the whole-layout attempts (taped-out layout) |
| `stray/` | `*_extracted.cir` files the LVS deck left in the working directory of early tests |

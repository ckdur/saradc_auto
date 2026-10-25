# saradc_auto: notes for Claude

Differential SAR ADC generator for IHP sg13g2, 2 to 8 bits; the chip has 5 (the default).
`NBITS` (settings.mk, `make ... NBITS=8` or the environment) reaches every stage: the `` `define NBITS``
of the RTL through Yosys (`verilog_defines`), `nbits` of both PnR flows, and the Python tools (`src/`,
`sim/`, `pex/`, `os.environ`). The stamp `.nbits` (git-ignored) makes a change of it re-run the synthesis.
`pnr/` derives the die width from the macro (5 bits: 566.44, as before; never narrower, the channel
needs it); `pnr_legacy/` keeps X/Y of settings.mk (the 5-bit die).
Tried 2026-10-25 (logs in sim/outputs/nb{3,5,8}/):
- 5 bits: the full flow reproduces fix2 (same die, identical plate geometry), DRC 0, LVS match.
- 8 bits: circle, macro 1104.04 x 315.84 (20 min), die 1241.0 x 752.76; top DRC 0 (antenna included),
  LVS match. The macro alone fails the antenna rules (Ant.b, switch gates of bits 4 and 6: the long
  control nets get their drivers only at the top); the top is clean.
- 3 bits: nested, macro 260.84 x 100.8 DRC 0 / LVS match; top 566.44 x 312.12: one Metal1 short left by
  the detailed router at `analog/cmp.buf_n0.impl` / net `analog/cmp.OUTNp` (same placement as in 5 bits;
  64 or 120 iterations), so top LVS fails. Open. The ADC is assembled from custom cells (`cells/`): unit capacitors are MOS
gates (`SARADC_CELL_INVX16_ASCAP`, 720 instances), switches `SARADC_CELL_INVX0_ASSW` (1452), plus the
`sg13g2f` standard cells for the SAR logic and comparator. It is a macro of the ASICONE chip
(parent repo `asicone_sg13g2`, which has this repo as a submodule). The chip is fabricated and measured.

## Environment
- Always `source ~/init_openlane.sh` first (OpenLane tools in /opt/ext/OpenLane, the venv
  `~/Documents/SymbioticEDA/venv` with kpex, `PDK_ROOT=/opt/ext/OpenPDKs`, `PDK=ihp-sg13g2`).
- PDK: IHP-Open-PDK, branch dev, commit cb743f75 (2026-10-23; models built at 7c783c7c, 2026-10-21). The ngspice OSDI models and the Xyce
  plugins under the PDK were rebuilt locally from that commit (git-ignored there).
- Simulators: ngspice-47 (preferred; PSP103 via OSDI, KLU) and Xyce (about 3x slower with KLU,
  about 10x with its default iterative solver; same results). The machine has 32 cores and 60 GB.
- Flow: `make -C syn all hier`, `make -C pnr all`, `make -C signoff all` (see README.md).
  `settings.mk` holds the die size (X, Y; Y is the legacy one) and the source lists.

## Two PnR flows
- `pnr/` (hierarchical, the current one): `pnr/tcl/cdac.tcl` builds one CDAC half as the macro
  `SARADC_CDAC` (429.48 x 144.48: array, switches, column stripes, bit 1/3 bridges, plus a Metal3 bus
  that joins the columns and a row of tie cells over the array); `pnr/tcl/top.tcl` places it twice
  (H R0 at y 20.16, L MX at 241.92, so L is a true mirror of H), with the channel (switches, comparator,
  bands), the digital part and the PDN. Die 566.44 x 410.04 (taller than the legacy 361.08).
  RTL: `rtl/hier/` (`cdac_half.v`, `saradc_analog_hier.v`, `saradc_hier.v`); netlists from
  `make -C syn hier` (`syn/outputs/hier/`). Helpers in `pnr/tcl/hier_utils.tcl`; the other procedures
  are sourced from `pnr_legacy/tcl`. `make -C pnr cdac top`: about 45 s + a few min, DRT 0 violations.
- `pnr_legacy/` (the flat flow of the tapeout): `make -C pnr_legacy all`, signoff with
  `make -C signoff PNR_DIR=../pnr_legacy OUT_DIR=outputs_legacy REP_DIR=reports_legacy`.
- Signoff: `make -C signoff TOP=SARADC_CDAC gds drc lvs` (macro), `make -C signoff all` (top, with
  the macro GDS/CDL merged in). Both DRC clean, LVS match.
- The parent chip (`asicone_sg13g2`) uses `saradc_auto/pnr/outputs/SARADC.{lef,cdl}` and
  `signoff/outputs/SARADC.gds`: these now hold the hierarchical layout (taller), not the tapeout.

## Taped-out layout (moved to `*.tapeout`)
The taped-out results (2025-10-17, OpenROAD v2.0-23297-g59ef9a9457) were moved (2026-10-24) to
`syn/outputs.tapeout`, `pnr_legacy/outputs.tapeout`, `pnr_legacy/DesignLib.tapeout`,
`signoff/outputs.tapeout`, plus `*.tapeout.log` and `reports.tapeout`. All git-ignored; never delete
them. `pnr_legacy/outputs` and `signoff/outputs_legacy` hold a re-run of the flat flow with OpenROAD
26Q4-1108-g6f3f28cc85 / Yosys 0.69+75.
- `pnr_legacy/tcl/compat.tcl` holds the fixes for newer OpenROAD (`place_inst -name` quoting, core area =
  rows bbox, diamond legalizer); `pnr.tcl` also re-creates tracks after re-init, disables the empty
  digital Metal5 strap (PDN-0185), catches `repair_design/timing` (RSZ-0074), seeds the CDAC tie cells in
  the analog rows and restores positions when `global_placement` diverges (it always does).
- Re-run vs tapeout: all special nets (cap/switch/top-plate/reference routing) and all cap, switch and
  comparator placements are identical; XOR of Activ/GatPoly/Cont is zero inside both arrays. Different:
  ring corners (0.2 um), std-cell placement in the channel/digital part, CTS, and the regular nets
  routed by the detailed router, which include the switch control nets (CRH/CRL/CRHB/CRLB, CPRE,
  CHOLD; ~45 mm inside the arrays). So for post-layout of the *fabricated* chip, extract `signoff/outputs.tapeout/SARADC.gds`
  (`pex/split.py --gds ... --def pnr_legacy/outputs.tapeout/SARADC.def`), not a new PnR.
- LVS: `make -C signoff lvs` runs `sg13g2.lvs` flat with std cells flattened in the schematic
  (`signoff/tcl/flatstd.py`) and `ignore_top_ports_mismatch` (the flattened std-cell pin labels show up
  as ~256 extra top ports in strict mode). Matches for both the re-run and the tapeout GDS.

## Simulation (schematic level, done)
- `src/adc_char.py` (`sim/char.sh`, or the Makefile targets `char_static`, `char_sine`, `char_report` in `sim/`): static
  transfer (staircase + bisection) and coherent sine records, run as many short ngspice jobs in parallel.
  It flattens `pnr_legacy/outputs/SARADC.cdl` and merges parallel MOS (24198 -> 2902 devices). ngspice needs
  `--trtol 7` (default for ngspice). `--netlist` accepts another netlist, which is how a post-layout
  netlist is fed in (`--netlist sim/outputs/pex/SARADC_hier.pex.ckt`).
- Board conditions used for the measurement comparison: `--vdd 1.2 --vrefl 0.4 --vrefh 0.8 --vcm 0.6`,
  fclk 10 MHz (7 clocks per conversion), `--frontend <GBW>` for the board front-end model.
  Results: `sim/outputs/char/ngspice_SARADC.flat_mos_tt_10MHz_vdd1.2_ref0.4-0.8_cm0.6/` (git-ignored).
- Report: `sim/report/make_sim_report.py <char dir> --ref <char dir 1.8 V>/static.json`, writes
  `<char dir>/report/report.pdf`. It also writes `sim_summary.json`, which the measurement report in
  `RISCVConsole/software/mso/report/make_report.py` consumes (copy it to
  `RISCVConsole/software/mso/results/sweep_20261022/`).
- Schematic result: ideal (weights 1.000/1.998/3.999/8.001/15.992, DNL/INL within 0.01 LSB, ENOB 4.8).
  The chip measures bit weights -8 % to +7 % off binary, INL about 0.5 LSB rms, ENOB 3.8 at low
  frequency. The post-layout simulation (below) explains most of it.

## Repository layout for simulation and extraction
- `sim/`: simulations only (`sim/README.md`): `char.sh` (characterization steps), `report/`,
  `tools/` (PDK model rebuild, Trilinos/Xyce cmake configs), and `sim/pex/` for helpers that use
  extracted netlists in simulation (`capsum.py` per-net C totals, `unitcap.py` unit-cap AC C,
  `stitch.py` the stitcher).
- `pex/`: everything that produces an extracted netlist (`pex/README.md`): `split.py` + `clip.py`,
  `platewires.py` (DEF geometry of the plate couplings)
  (split kpex extraction, the method that works), `relabel.py`, `magic/` and `kpex_full/` (the
  whole-layout attempts). All results in `pex/outputs/` (git-ignored): `arrH/`, `arrL/` (legacy
  arrays), `cdac/` (the macro), `top/` (the hierarchical top without the macros), `hier/` (tests on
  the hierarchical layout), `tests/`, `magic/`, `kpex_full/` (formerly `signoff/pex`, `signoff/kpex`).

## Layout extraction: what failed (whole layout, details in pex/README.md)
- Magic 8.3.623: device counts match, capacitances about 100x too large, netgen cannot compare
  (transistors as calls to undefined `sg13_lv_nmos`/`pmos`).
- kpex 2.5D on the whole flat layout: single-threaded, never finished (4 h, 12 h, 10 h, 16 h runs).
  Its LVS only matches with the std cells flattened in the schematic.

## Split extraction (works, `pex/split.py`)
- Clips the GDS into a grid of pieces between tiles, labels every DEF wire segment (`clip.py`), runs
  the kpex IHP LVS deck with the unconditional `purge` in `rfmos_model_mapping.lvs` patched out
  (it drops device-less nets, which kpex then never extracts), then `kpex --lvsdb ... --2.5D --mode CC`.
  28 jobs: ~2.5 min per array (30 pieces), 0 um2 of wire missing. Done on the current flow (new PnR;
  the VSH/FL plate wiring is identical to the tapeout).
- VSH totals per bit (bit0..bit4; 1, 2, 4, 8, 16 units): H 99.3/218.6/399.9/864.4/1583.8 fF,
  L 100.9/219.7/399.6/874.0/1580.6 fF. Bits 1 and 3 (the ones with the extra M5/TopMetal1 "ring"
  bridges in pnr.tcl) have ~9 % more wiring C per unit. Unit device C (6 cap cells): 67.8 fF with FL
  floating, 158.5 fF with FL AC-grounded.
- First-order weight estimate (N*67.8 fF + wiring) gives -2/+4/-1/+4/-2 %, while the chip measures
  -7.8/-5.7/+6.7/-8.4/+3.5 %: wiring C alone does not explain the measurement.

## Post-layout netlist of the hierarchical layout (done)
- Macro: `split.py pex/outputs/cdac` (30 pieces, 2.3 min). VSH per bit within ~1 % of the legacy
  arrH; VOUTL/VREF/VIP/VIN get ~+100 fF from the bus.
- Top: `pex/outputs/top/SARADC_nomacro.gds` (written by `pex/outputs/top/nomacro.py`: the macro
  instances deleted with `prune_cell`, never `delete_cell_rec`, which also deletes the vias and cells
  shared with the top), split on xs 0 109.18 233.54 320.32 452.0 566.44 and ys at row boundaries
  (0 48.96 79.56 110.16 140.76 171.36 189.72 214.2 232.56 263.16 293.76 324.36 410.04): 60 pieces,
  2.4 min. The cuts may only cross fillers and taps (y 164.64/241.92 cut digital rows on the right).
  Couplings between top-level wires and the macro content are not extracted (only the pin stubs and
  one M1 followpin rail at y 244.8 overlap the L macro).
- `sim/pex/stitch.py sim/outputs/pex/SARADC_hier.pex.ckt --cdl pnr/outputs/SARADC.cdl --top
  pex/outputs/top/split/pieces.txt --macro SARADC_CDAC=pex/outputs/cdac/pieces.txt:pnr/outputs/SARADC_CDAC.cdl
  --check sim/outputs/pex/SARADC_hier.flat.ckt`: 24208 MOS, ~58k C; MOS W per role on all 569 named
  nets equal to the flattened schematic.
- Single-piece kpex scaling on the macro (`pex/outputs/hier/b*`): 895 um2 25 s / 1.2 GB, 3582 um2
  141 s / 4.4 GB, 10746 um2 742 s / 13 GB, 30919 um2 (half macro) 3691 s / 30 GB: time ~ area^1.5,
  so small pieces in parallel are the only practical way. kpex on the whole macro hit its 4 h
  timeout (single-threaded in the 2.5D engine despite `--threads 4`).

## Post-layout static results (board conditions, done)
Char dirs `sim/outputs/char/ngspice_SARADC_<name>.pex_mos_tt_10MHz_vdd1.2_ref0.4-0.8_cm0.6/` (static.json +
plate_par.json from `sim/pex/dacpar.py`). The staircase now extends itself until codes 0 and 31 are
reached (`adc_char.py cmd_static`), so the attenuated post-layout DAC gets all 31 transitions.
- Tapeout netlist: `pex/outputs/tapeout/{ana,dig}` (81 pieces, grids in pex/README.md; the cut at
  y 177.48, not 180.54, which cuts cells), stitched with only `--top` into
  `sim/outputs/pex/SARADC_tapeout.pex.ckt` (24198 MOS, 68519 C, check 572 nets 0 mismatches).
  Static 7.2 h with 26 workers.
- Bit weight errors (%, bit0..4), LSB, INL rms, ENOB of a quantized sine (static_enob):
  schematic 0/0/0/0/0, 25.14 mV, 0.01, 4.81; tapeout -12.5/-6.8/+3.3/-5.2/+2.3, 26.78 mV, 0.33, 4.26;
  hier -13.5/-4.7/+0.4/-2.5/+1.0, 27.88 mV, 0.17, 4.60; tapeout with only the plate C (cfilter.py
  `--keep '(VSH|FL)(\[\d+\])?$'`) -6.2/-3.7/+2.6/-3.9/+1.6, 26.88 mV, 0.25; without them -10.6/-7.3/+1.7/-2.6/+1.6, 24.88 mV,
  0.20 (each part has the pattern, not additive; the attenuation is all from the plates).
  Chip: -7.8/-5.7/+6.7/-8.4/+3.5, INL 0.51, ENOB 3.81. Tapeout vs chip: same sign on all bits, INL
  correlation 0.98, about half of the lost ENOB. Main cause: plate wiring C to VOUTH/VOUTL that differs
  per bit (bit 1/3 bridges, MSB VSH 11.3 fF/unit to its own top plate, LSB FL 7-10 fF/unit to the
  other one) and between halves in the tapeout (hier L is an exact mirror, tapeout L is not).
- Reports: `make_sim_report.py <schematic dir> --ref <1.8 V dir>/static.json --pex tapeout=<dir>
  --pex hier=<dir> --pex plates=<dir> --pex noplates=<dir>` (sim/report/pex.tex), then copy
  sim_summary.json to RISCVConsole/software/mso/results/sweep_20261022/ and `make -C
  RISCVConsole/software/mso/report` (comparison.tex, Section "Post-layout simulation").

## Next task: a better DAC wiring (see `docs/dac_wiring.md`)
The bad linearity of the chip is the DAC wiring. `docs/dac_wiring.md` traces each coupling to the code;
`pex/platewires.py <def> [--style legacy|macro]` measures them geometrically from the DEF (`--style macro`
on `pnr/outputs/SARADC_CDAC.def`: today identical to the H half of the tapeout, the baseline).
Causes (taped-out layout, per unit):
- switch-row Metal3 rails of every tile (`create_sw_cap_conn`, `pnr_legacy/tcl/saradc_conn.tcl:459-481`):
  FL rail at minimum spacing (0.28 um, 41 um long) next to the opposite top plate rail -> 7.2 fF; in
  the MSB tiles (no VOUTL switch) VSH sits next to its own VOUT -> 11.3 fF;
- per-tile Metal4 VSH/FL stripes in the slots next to the VOUTH column stripe (`saradc_conn.tcl:563-580`)
  -> FL to VOUTH 3 fF at 0.42 um;
- flat flow: `strip_h`/`strip_l` use the same global order, the L switches are inverted, so the
  halves are not mirrors (L FL to VOUTH ~10 fF); the hierarchical flow (`pnr/`) fixes that;
- bit 1/3 bridges (Metal5/TopMetal1 VSH+FL pairs) add ~9 fF per unit, 3.5 fF of it VSH-FL.
Branch `dac-routing-fix` (2026-10-25), step 1 done: `create_sw_cap_conn ... $fix $tops` (fix 0 = tapeout,
the legacy flow is unchanged; `pnr/tcl/cdac.tcl` uses fix 1, `ROUTE_FIX=0` for the old wiring). Switch-row
Metal3 rails by role [VOUTH-port VI VSH VI VOUTL-port] (MSB: [VI VIP VSH VIN VI], VI = VOUT), no FL rail in
the switch row (FL Metal2 rails stop at the caps), VSH/FL Metal4 tile stripes in the last two slots.
Macro and top: DRT 0, DRC 0, LVS match; `pex/hier_pex.sh fix1` (stitch check 0 mismatches).
Per unit, baseline -> fix1: FL to VOUTH/VOUTL 3.0/7.2 -> 0.6/0.4 fF (bits 1/3: 1.6/1.0, the bridges);
MSB VSH to its VOUT 11.3 -> 5.2 (= the other bits per side); VSH to VREF/VIN 12 -> 21-22 (MSB 25.5, the
shield rails, static nets). Left: the bit 1/3 bridges (+9 fF per unit on each plate, VSH-FL +3 fF).
Pattern by NBITS (`pnr/tcl/cdac.tcl`): 2..5 bits the nested pattern (generic `saradc_nested_pattern`,
bands around the lower bits; 5 bits = fix2) with fix 2; above 5 the circle with its bridges and fix 1
(`CDAC_PATTERN` overrides). 8 bits (circle): macro 1104.04 x 315.84, 20 min, DRT 0, LVS match, but DRC
fails on antenna rules (Ant.b on Metal4..TopMetal2 at switch gates of bits 4 and 6: long control nets
whose drivers are outside the macro); `repair_antennas` is not in the flows (commented out in
pnr_legacy/tcl/pnr.tcl).
Step 2 done (fix2, the default now for 5 bits): `saradc_nested_pattern` (`pnr/tcl/hier_utils.tcl`, nested U shapes,
every bit connected, no bridges; `CDAC_PATTERN=circle` for the old one) + `fix 2` (Metal4 VSH/FL stripes only
where the unit above/below is the same bit). DRC 0, LVS match, `pex/hier_pex.sh fix2` 0 mismatches.
Per unit (H): VSH total 97.7-101.0 fF for all bits (baseline 97.9-109.0), FL 46.0-48.0 (64-76), VSH to
VOUTH/VOUTL 4.7-5.1/0.4-4.8, FL to them <= 0.5, VSH-FL 19.1-20.7 (24-28); details in docs/dac_wiring.md s7.
Next: post-layout static of `sim/outputs/pex/SARADC_fix2.pex.ckt` (~7 h, 26 workers), compare the weights.
`pnr/outputs` and `signoff/outputs` now hold the fix2 layout (the parent chip reads them).
The original plan, in `pnr/` (hierarchical flow; `pnr/tcl/cdac.tcl`, procedures in `pnr_legacy/tcl/saradc_conn.tcl`):
1. (done, fix1) Reorder/shield the Metal3 switch rails and the Metal4 tile slots so that VSH/FL never run next to
   VOUTH/VOUTL (VSS or VI in between, or VOUT only as vias from the column stripes).
2. (done, fix1) The same rail list in the MSB tiles as in the LSB tiles; equal coupling per unit for every bit.
3. (done, fix2) Remove the bit 1/3 bridges (placement without them) or give every bit identical dummy bridges.
4. (tools done: `pex/hier_pex.sh <tag>`) Check each change with `platewires.py --style macro` (seconds), then split extraction + stitch +
   `dacpar.py --style hier` +
   `platewires.py` (target: plate-to-VOUT C per unit equal for all bits and halves within a few
   0.1 fF), then the post-layout static (~7 h, 26 workers).
5. Localize the rest of bit 0 (-10.6 % even without the plate C): decompose with `cfilter.py`
   (control nets CRH/CRL/CRI only; VOUTH/VOUTL only).
Still open: the remaining difference to the chip (bit 0 less reduced, bit 2 larger, bit 3 smaller):
unit-cap mismatch, wiring resistance (not extracted), undecoupled board references.

## Conventions
- Commit only when the user asks; end commit messages with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

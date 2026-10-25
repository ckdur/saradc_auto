# DAC wiring: why the taped-out SARADC is not binary

Report of 2026-10-25. The measured chip has bit-weight errors of −8 % to +7 %, INL 0.51 LSB rms and
ENOB 3.8 bits at low frequency. The schematic simulation is ideal (ENOB 4.8). The post-layout
simulation of the taped-out layout (split extraction, `pex/README.md`; simulation, `sim/README.md`
section 4) reproduces most of the gap. This report traces the parasitics that cause it back to the
wiring code in `pnr_legacy/tcl` (the flat flow of the tapeout), and lists what a better wiring
has to do.

## 1. Result in short

| Bit-weight error (%) | bit 0 | bit 1 | bit 2 | bit 3 | bit 4 | INL (LSB rms) | ENOB (bits) |
|---|---|---|---|---|---|---|---|
| Schematic | 0.0 | −0.1 | 0.0 | 0.0 | 0.0 | 0.01 | 4.81 |
| Post-layout, taped-out layout | −12.5 | −6.8 | +3.3 | −5.2 | +2.3 | 0.33 | 4.26 |
| Post-layout, hierarchical re-layout (`pnr/`) | −13.5 | −4.7 | +0.4 | −2.5 | +1.0 | 0.17 | 4.60 |
| Taped-out, only the plate wiring C | −6.2 | −3.7 | +2.6 | −3.9 | +1.6 | 0.25 | 4.46 |
| Taped-out, without the plate wiring C | −10.6 | −7.3 | +1.7 | −2.6 | +1.6 | 0.20 | 4.53 |
| **Measured chip** | −7.8 | −5.7 | +6.7 | −8.4 | +3.5 | 0.51 | 3.81 |

ENOB here is static: a sine quantized with the transition levels.

- The post-layout errors have the measured sign on all five bits. The post-layout INL curve
  correlates with the measured one at 0.98. The parasitics account for about half of the lost bit.
- Both parts of the parasitics already show the pattern on their own:
  - the wiring of the bit plates (VSH, FL);
  - everything else: top plates, switches, control nets.

  The two parts do not simply add up.
- The remaining difference to the chip (bit 0 less reduced, bit 2 larger, bit 3 smaller) is not
  explained. Candidates: unit-capacitor mismatch, wiring resistance (not extracted), and the
  board references.

## 2. How a bit couples to the comparator

Each bit `b` has 2^b units. A unit is six MOS gate capacitors (`SARADC_CELL_INVX16_ASCAP`)
between:
- the switched plate **VSH**, connected through switches to the input, to VOUTH or to VOUTL;
- the floating plate **FL**, the channel/diffusion side, which is left floating.

VOUTH and VOUTL are the comparator inputs (the "top plates"). The unit capacitance is 67.8 fF with FL
floating (158.5 fF with FL AC-grounded), so the floating plate's own parasitics are part of the unit.

The weight of a bit is the charge it moves onto VOUTH/VOUTL when its VSH switches. So wiring
capacitance between a bit's plates and VOUTH/VOUTL changes that charge directly. The split matters:
- Wiring capacitance that is the same per unit for every bit only scales the DAC (a gain error).
- Wiring capacitance that differs from bit to bit breaks the binary ratios.
- Wiring capacitance that differs between the two halves breaks the differential symmetry.

The taped-out layout has all three.

## 3. Measured parasitics per unit

The table below comes from `sim/pex/dacpar.py` on the taped-out post-layout netlist. Values are
per unit capacitor, in fF.

| Half | Plate | Bits 0, 2 | Bits 1, 3 | Bit 4 (MSB) |
|---|---|---|---|---|
| H | VSH → VOUTH / VOUTL | 4.7 / 4.7 | 5.2 / 5.2 | **11.3 / 0.4** |
| H | FL → VOUTH / VOUTL | 3.0 / **7.2** | 3.6 / **7.7** | 3.0 / 0.2 |
| L | VSH → VOUTH / VOUTL | 4.7 / 4.7 | 5.2 / 5.1 | 0.3 / **11.3** |
| L | FL → VOUTH / VOUTL | **9.6** / 0.5 | **10.1** / 1.0 | 2.7 / 0.6 |
| both | total VSH / FL | 99–101 / 65–66 | 108–110 / 75–76 | 99 / 65 |
| both | VSH–FL (parallel to the unit) | 24.1 | 27.6 | 24.3 |

The H half's MSB connects to VOUTH; the L half's MSB connects to VOUTL, and its other bits have
VOUTH and VOUTL exchanged (`rtl/saradc_analog.v`).

`pex/platewires.py` locates these couplings in the DEF. It measures, per unit, the facing length
between plate wires and VOUTH/VOUTL on the same layer, and the overlaps with the layer above and
below:

```bash
python3 pex/platewires.py pnr_legacy/outputs.tapeout/SARADC.def   # in the venv (klayout.db)
```

| Coupling | Where (taped-out DEF, per unit) | Code |
|---|---|---|
| FL → the opposite top plate (7.2 fF, H) | Metal3, **41 µm at 0.28 µm** (minimum spacing): in the switch row of every tile the Metal3 rails are VSH, VI, VOUTH, VOUTL, FL at the Metal3 pitch (order inferred from the gaps), so the FL rail sits right next to the VOUTL rail across the whole tile width | `create_sw_cap_conn`, `pnr_legacy/tcl/saradc_conn.tcl:459-481` (FL is appended to `all_zsnnets` after the switch nets) |
| FL → VOUTH (3.0 fF, H) | Metal4, **20 µm at 0.42 µm**: the per-tile Metal4 stripes of VSH and FL take the first two of nine slots; the column stripes VOUTH VOUTL VREF VIP VIN take slots 2–6, so FL always sits next to VOUTH | `saradc_conn.tcl:563-580` (`nnets = 2 + strip + 2`), `create_stripes` `:622` |
| VSH → VOUTH/VOUTL (4.7/4.7 fF, LSB bits) | Metal2, 29 µm at 0.44 µm to both (the switch rails); Metal3, 41 µm at 0.76 µm to VOUTH (VI between them) | `create_sw_cap_conn` switch rails `saradc_conn.tcl:334-360`, Metal3 rails `:459-481` |
| MSB VSH → its own top plate (11.3 fF) | Metal3, **41.8 µm at 0.28 µm**: the MSB unit has no VOUTL switch, so its rail list is shorter and VSH ends up right next to VOUT | same code; the MSB units differ only in their switch list |
| Taped-out halves not mirrored (L: FL 9.6 fF to VOUTH, 0.5 fF to VOUTL) | Both halves use the same *global* column order `{analog/VOUTH analog/VOUTL ...}`, while the switch rails follow the *local* (inverted) nets of the L half. In L, the Metal4 FL stripe (next to global VOUTH) and the Metal3 FL rail (next to local VOUTL = global VOUTH) both face VOUTH | `pnr_legacy/tcl/pnr.tcl:472-473` (`strip_h`, `strip_l`) |
| Bits 1 and 3: about +9 fF total and +3.5 fF VSH–FL per unit | The Metal5/TopMetal1 bridges run VSH and FL of bits 1 and 3 as a pair at 2×TopMetal1 spacing over the array. They cross the Metal4 VOUTH/VOUTL column stripes (2.6 and 2.0 µm² per unit), but most of their capacitance goes to the supply stripes and between the two plates | `pnr_legacy/tcl/pnr.tcl:498-578` ("rings for fixing bits 1 and 3"), `pnr/tcl/cdac.tcl:113-145` |

The geometry agrees with the extraction. A 41 µm Metal3 run at minimum spacing gives about 6–7 fF,
which is the 7.2 fF of FL to VOUTL in H. In L the Metal3 rail and the Metal4 stripe both face VOUTH,
which gives the 9.6–10.1 fF.

The hierarchical re-layout (`pnr/`) builds one half as a macro with local net names and mirrors it.
That removes the asymmetry between the halves (its L half is the exact mirror of H) and halves the
INL (0.17 instead of 0.33 LSB rms). It does not remove the bit-to-bit differences: the tile wiring
is the same code.

## 4. What is not yet localized

- **Bit 0.** Without any plate capacitors the error is still −10.6 % (−12.5 % with all
  parasitics). So bit 0's error comes mostly from the other parasitics. One candidate is the per-bit
  wiring that does not scale with 2^b: the control nets CRH/CRL/CRI of each bit, routed by the
  detailed router and about 45 mm inside the arrays, and their coupling to VOUTH/VOUTL. Another is
  the termination unit `LSB_*_VSH[0]`, which has the same size as bit 0. The next step is a
  decomposition by net class with `sim/pex/cfilter.py`: only the control-net capacitors, and only
  the VOUTH/VOUTL capacitors.
- **Wiring resistance** is not extracted (kpex `--mode CC`).
- The remaining difference to the chip (section 1).

## 5. Requirements for a better wiring

1. **No plate wire next to a comparator input at minimum spacing.**
   - Reorder the switch-row Metal3 rails so that FL and VSH are never adjacent to VOUTH/VOUTL: for
     example VOUTH, VI, VOUTL with VSS or VI between them and the plates.
   - Or keep VOUTH/VOUTL out of the tile and only drop vias from the column stripes to the
     switches.
   - In the Metal4 column, put a shield (VSS) or the input stripes between the VSH/FL slots and
     VOUTH/VOUTL.
2. **The same wiring per unit for every bit, including the MSB.**
   - Use the same rail list in the MSB tiles as in the LSB tiles (a dummy VOUTL rail or the same
     order).
   - Then whatever coupling remains scales with 2^b and only shows up as a gain error.
   - Bits 1 and 3 need their bridges replaced, either by a placement whose bits do not need bridges
     or by identical dummy bridges on every bit.
   - Their VSH/FL pair should not run side by side over long distances: the VSH–FL coupling adds to
     the unit.
3. **Mirrored halves with local names.** This is already the case in the hierarchical flow (`pnr/`).
   For the flat flow, the column order of `strip_l` must follow the inverted connection of the L
   half.
4. **Check before simulating.**
   - After each change: `pex/platewires.py pnr/outputs/SARADC_CDAC.def --style macro` (seconds),
     then split extraction (cdac macro ~2.5 min, top ~2.5 min), stitching,
     `sim/pex/dacpar.py` and `pex/platewires.py`.
   - Target: plate → VOUTH/VOUTL coupling per unit equal for all bits and both halves within a few
     tenths of a fF.
   - Only then run the post-layout static, about 7 h with 26 workers.
5. Outside the layout: the weights could be calibrated digitally (the measured weights are stable),
   or a redundant bit could be added.

## 6. Files

- `pex/platewires.py`: geometric attribution from the DEF. `--style legacy` (default) for the flat
  flow (both halves); `--style macro` for `pnr/outputs/SARADC_CDAC.def`, one half, reported as M. The
  current macro gives the same numbers as the H half of the tapeout: that is the baseline for the
  routing corrections.
- `sim/pex/dacpar.py`: plate parasitics per bit from a stitched netlist (`--style legacy|hier`).
- `sim/pex/cfilter.py`: decompositions by net.
- Reports:
  - `sim/report/pex.tex`: the post-layout section of the simulation report;
  - `RISCVConsole/software/mso/report/comparison.tex`: the measurement report.

## 7. Corrections (branch `dac-routing-fix`)

**Step 1 (fix1, 2026-10-25): switch rails and tile stripes.**

`create_sw_cap_conn` (`pnr_legacy/tcl/saradc_conn.tcl`) has a new `fix` argument. The legacy flow
calls it without one, so it keeps the tapeout wiring. `pnr/tcl/cdac.tcl` uses `fix 1`; `ROUTE_FIX=0`
builds the old wiring for comparison. With `fix 1`:

- **Switch-row Metal3 rails** are ordered by role:
  - lower bits: VOUTH-port, VI, VSH, VI, VOUTL-port;
  - MSB, whose VI is VOUT: VI, VIP, VSH, VIN, VI.

  VSH is shielded on both sides by a net that is not a comparator input.
- **FL** has no rail in the switch row. Its Metal2 rails stop at the capacitors, and the rails of
  the capacitor rows connect it.
- **Metal4 tile stripes** of VSH and FL take the last two column slots, next to VIN.

Macro and top: routing 0 violations, DRC 0, LVS match. `pex/hier_pex.sh fix1` stitches with
0 mismatches.

| Per unit (fF), baseline → fix1 | Bits 0, 2 | Bits 1, 3 | Bit 4 (MSB) |
|---|---|---|---|
| FL → own / opposite comparator input | 3.0 / 7.2 → 0.5 / 0.4 | 3.5 / 7.7 → 1.4 / 0.9 | 3.0 / 0.2 → 0.5 / 0.1 |
| VSH → VOUTH / VOUTL (H half) | 4.7 / 4.7 → 4.9 / 4.8 | 5.1 / 5.2 → 5.4 / 5.2 | 11.3 / 0.4 → 5.2 / 0.4 |
| VSH → VREF/VIN/VIP (the shields) | 12.0 → 21.2 | 13.3 → 22.3 | 9.8 → 25.5 |
| total VSH / FL | 99–101 / 65–66 → 105–107 / 51–52 | 108–109 / 75 → 114–115 / 60–62 | 98 / 64 → 104 / 50 |

The halves stay exact mirrors.

What is left of the bit-to-bit differences is the bridges of bits 1 and 3: about +9 fF per unit on
each plate, VSH–FL +3 fF, and FL 1 fF closer to the comparator inputs. That is step 2.

The post-layout static of fix1 has not been run yet (about 7 h).

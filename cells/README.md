# Cell libraries

One directory per technology, selected by `TECH` (settings.mk, `make ... TECH=sky130f`); the flow
gets it as `CELLS_DIR` (cells/settings.tcl lists the files). Every technology has the same files:

| File | What |
|---|---|
| `<TECH>.gds`, `.lef`, `.cdl`, `.ckt`, `.port.csv` | the float standard cells (no bulk taps inside the cells), named `<TECH>_<CELL>`; the LEF starts with the site `obssite` |
| `<TECH>.tech.lef` | the tech LEF of the PDK |
| `<TECH>.lib`, `<TECH>.v` | liberty (tt, nominal voltage) and verilog models of the logic cells |
| `<TECH>_blackboxes.v` | blackboxes of the ADC cells and of the standard cells the RTL instantiates |
| `SARADC_CELL_INVX0_ASSW.*` | the switch: an INVD0 with its bodies on the pins `vnw`/`vpw` |
| `SARADC_CELL_INVX16_ASCAP.*` | the unit capacitor: an INVD12, the gates (`i`) are the top plate (VSH), drains, sources and rails the bottom plate (FL); bodies on `vnw`/`vpw` |
| `SARADC_FILLTIE2.*` | the body tie of the arrays: `vss`/`vdd` are substrate/N-well taps |
| `SARADC_FILL1.*`, `SARADC_FILL1_NOPOWER.*` | one-site fillers, with and without rails |

| TECH | PDK | Devices | Site (um) | Switch / unit cap (um) | DRC / LVS of the ADC cells |
|---|---|---|---|---|---|
| `sg13g2f` | IHP sg13g2 | `sg13_lv_nmos/pmos`, L 0.13 | 0.34 x 6.12 | 1.70 / 12.24 x 6.12 | taped out |
| `sky130f` | sky130A | `sky130_fd_pr__nfet/pfet_01v8`, L 0.15 | 0.36 x 6.12 | 1.80 / 13.68 x 6.12 | clean / match |
| `gf180mcuf` | gf180mcuD | `nfet_03v3/pfet_03v3` (3.3 V), L 0.28 | 0.56 x 7.84 | 2.24 / 15.68 x 7.84 | clean / match |
| `ics55f` | ICsprout 55 | `nm1p2/pm1p2_svt_lp` (1.2 V SVT), L 0.06 | 0.2 x 3.2 | 1.00 / 6.60 x 3.2 | clean (translated deck) / no deck |

`sg13g2f` holds the cells of the taped-out chip: they are kept as they are, with their own
Makefile (`cells/sg13g2f/Makefile`, LVS with `lvs/sg13g2_custom.lvs`).

## Building a technology

The standard cells come from stdcell-gen (`STDCELL_GEN`, ~/Documents/IIZUKA_LAB/stdcell-gen),
`docs/float.md` there:

```
make -C $STDCELL_GEN -f Makefile.sky130f -j12 layouts   # the float cells, DRC/LVS: test/verify_float.sh
make -C $STDCELL_GEN -f Makefile.sky130f -j8 PYTHON3=$STDCELL_GEN/.venv/bin/python char_lib  # liberty
make -C cells TECH=sky130f                              # cells/sky130f
make -C cells TECH=sky130f check                        # DRC/LVS of the ADC cells, cells/sky130f/reports
```

- `tools/build_cells.py` (KLayout): copies the cells, renames them, derives the ADC cells, and writes
  the netlists, the blackboxes and the LEFs. The LEF is written from the layout, not with magic
  (whose sky130 boundary scale and pin purposes did not work for these cells): SIZE from the
  boundary, the pins from the nets of the pin texts on the layers the tech LEF has, OBS from the
  other nets, ANTENNAGATEAREA/ANTENNADIFFAREA from the gate and diffusion of each pin net.
- `tech/<TECH>.json`: GDS layers, text layers and tech LEF names of the conductors, the device
  models, the layers kept in `SARADC_FILL1_NOPOWER`, and the tech LEF of the PDK.
- `tools/merge_lib.py`: merges the per-cell liberty files of lctime (`char_lib` in stdcell-gen,
  `docs/float.md` there) into `<TECH>.lib`, with the cells renamed, the table templates of all
  files, the areas from the LEF (lctime's template has a placeholder), and the constant
  `clear`/`preset` that lctime writes for DFQD1 dropped. It also writes `<TECH>.v` from the liberty
  functions and `ff` groups (for `sim/`, the gate-level simulation). Corners: tt only, at 1.8 V
  (sky130f), 3.3 V (gf180mcuf), 1.2 V (ics55f).
- `tools/check_cells.sh`: the per-cell checks of stdcell-gen (`test/float/check_cell.sh`). The
  switch and the capacitor are compared with `vnw`/`vpw` on `vdd`/`vss`, which is how the deck ties
  the floating wells. gf180mcuD runs in the asic-all docker image.
- On a single cell some rules cannot pass by construction and are waived: the distance to a tap
  (gf180 DF.13/DF.14, ics55 LU_S_*), floating N-well (ics55 NW1_R_1), density. An isolated
  `SARADC_FILL1` of ics55f has its rail stubs below the M1 minimum area (MET1_A_1) until they abut.

The libraries load in OpenSTA and yosys; the SAR logic (`rtl/sar_logic_wreset.v`) maps onto each
of them, and its gate-level simulation with `<TECH>.v` gives the same testbench waveforms as the
RTL (after the reset). Not done yet for the new technologies: the flow itself (the RTL cell prefix,
PnR layers, tracks and the CDAC wiring are still sg13g2).

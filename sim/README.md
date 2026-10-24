# Simulation of the SARADC

Transistor-level characterization of the SARADC (schematic level, October 2026), its PDF report,
and the helpers for post-layout netlists. Producing the extracted netlists is in `pex/`
(`pex/README.md`). The results were compared with the chip measurement in
`RISCVConsole/software/mso` (branch `adc-sim-comparison`, see its `README.md`).

All commands run from the root of `saradc_auto` after `source ~/init_openlane.sh`. Everything
below `sim/outputs/` is git-ignored: the scripts here regenerate it.

| Path | What it does | Output (git-ignored) |
|---|---|---|
| `char.sh` | static and sine characterization with ngspice, Xyce cross-check, report | `sim/outputs/char/`, `sim/outputs/SARADC.flat.ckt` |
| `report/` | `make_sim_report.py`: the PDF report and `sim_summary.json` | `<char dir>/report/` |
| `pex/` | helpers for simulations with extracted netlists: `capsum.py` (per-net capacitance totals of a set of kpex netlists, merges the `name$N` pieces), `unitcap.py` (device capacitance of one CDAC unit, ngspice AC) | `sim/pex/unitcap/` |
| `tools/build_models.sh` | rebuilds the PSP103/r3_cmc models of the PDK (OSDI for ngspice, plugins for Xyce) | `$PDK_ROOT/$PDK/libs.tech/{ngspice/osdi,xyce/plugins}` |
| `tools/*-reconfigure.sh` | cmake configurations of Trilinos 14 and Xyce as built for these runs | |

## 1. Inputs

The schematic-level results of October 2026 were made from the taped-out netlists (2025-10-17):
`SARADC.cdl` (schematic netlist) and `SARADC.spice` (LVS schematic) of the flat PnR. The flat PnR
is now `pnr_legacy/`; `pnr_legacy/outputs/` and `signoff/outputs_legacy/` hold its re-run with the
current tools (new Yosys, so the SAR logic netlist can differ), and the taped-out copies are in
`pnr_legacy/outputs.tapeout/` and `signoff/outputs.tapeout/` (git-ignored, never delete them).
`src/adc_char.py` flattens `pnr_legacy/outputs/SARADC.cdl`, so to repeat the October results
exactly, run it with the taped-out CDL in that place.

`sim/outputs/SARADC.xyce.ckt` and the per-cell `.ckt` files come from the existing `sim/Makefile`
(Xyce netlists of the cells); `pex/magic/magic_pex.sh` only uses it for the port order.

## 2. Tools

Versions used (installed in `/opt/ext/OpenLane`, venv `~/Documents/SymbioticEDA/venv`):

| Tool | Version | Notes |
|---|---|---|
| IHP-Open-PDK | branch `dev`, `7c783c7c` (2026-10-21) | `/opt/ext/OpenPDKs/IHP-Open-PDK`; later commits up to `cb743f75` do not touch the models |
| ngspice | 47 | built from the `ngspice-47` tag, see below |
| OpenVAF | `openvaf-r` | used by the PDK's `openvaf-compile-va.sh` |
| Xyce | 7.10.0-59-gcac8ebf9, MPI, plugin support | on Trilinos 14.0.0 (`sim/tools/`) |
| magic | 8.3.623 | |
| netgen | 1.5.287 | |
| KLayout | 0.30.10 | |
| KLayout-PEX (kpex) | 0.3.12 | `pip install klayout-pex` in the venv |

ngspice-47 (KLU and OSDI are on by default):

```bash
cd ~/Documents/SymbioticEDA/ngspice-ngspice && git checkout ngspice-47 && ./autogen.sh
mkdir -p release-47 && cd release-47
../configure --prefix=/opt/ext/OpenLane --with-x --enable-cider --disable-debug CFLAGS="-O2 -march=native"
make -j24 && make install
```

Xyce (only for the cross-check): Trilinos 14 with `sim/tools/trilinos-14-reconfigure.sh` (GCC 15 needs the
`-include cstdint -Wno-template-body` flags in it), then Xyce with `sim/tools/xyce-reconfigure.sh`, both
from a `build-mpi5/` directory inside the source tree, `make -j && make install`.

Then rebuild the device models of the PDK checkout (the shipped binaries are outdated):

```bash
sim/tools/build_models.sh
```

## 3. Characterization and report

```bash
sim/char.sh                 # all steps: ref static sine sinefe xyce report
sim/char.sh static report   # or only some steps
```

| Step | Conditions | Result directory under `sim/outputs/char/` |
|---|---|---|
| `ref` | design testbench, VDD 1.8 V, static only | `ngspice_SARADC.flat_mos_tt_10MHz/` |
| `static` | board: VDD 1.2 V, VREF 0.4/0.8 V, VCM 0.6 V | `ngspice_SARADC.flat_mos_tt_10MHz_vdd1.2_ref0.4-0.8_cm0.6/` |
| `sine` | board, ideal differential input, 27 LSB pk-pk, 256 samples, 17 kHz ... 650 kHz | same directory, `sine_*.json` |
| `sinefe` | board, inputs through the linear front-end model (GBW 1.4 MHz) | same directory, `sinefe_*.json` |
| `xyce` | 3 conversions of the same flat netlist in ngspice and Xyce | `ngspice_SARADC.flat_*`, `xyce_SARADC.flat_*` (`bench_k3*`) |

What `src/adc_char.py` does: flattens `pnr_legacy/outputs/SARADC.cdl` with the cell netlists into
`sim/outputs/SARADC.flat.ckt`, merges parallel MOS (24198 -> 2902), and runs many short ngspice jobs
in parallel (PSP103 via OSDI, KLU, gear, reltol 1e-4, trtol 7). Each result directory gets a
`pdk.json` with the git state of the PDK at simulation time. On 32 cores the static runs take
hours and each sine frequency many CPU-hours; lower `--workers` in `char.sh` on smaller machines.

The `report` step builds `<board dir>/report/report.pdf` and `sim_summary.json`. For the measurement
report, copy that JSON to `RISCVConsole/software/mso/results/sweep_20261022/` and rebuild there
(`make -C software/mso/report`).

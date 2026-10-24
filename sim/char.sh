#!/usr/bin/env bash
# Transistor-level characterization of the schematic netlist and its report, as used for the
# comparison with the chip measurement (RISCVConsole/software/mso).
#
# Usage (from the repo root, after `source ~/init_openlane.sh`): sim/char.sh [step...]
#   steps: ref static sine sinefe xyce report   (default: all, in this order)
# Results in sim/outputs/char/<netlist>_<corner>_<fclk>[_conditions]/. 32 cores: the static runs
# take a few hours, each sine record about a day of CPU; adjust --workers to the machine.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
CHAR=sim/outputs/char
BOARD="--vdd 1.2 --vrefh 0.8 --vrefl 0.4 --vcm 0.6"   # adapter board conditions
mkdir -p $CHAR

for step in ${@:-ref static sine sinefe xyce report}; do
    case $step in
    ref)     # design testbench conditions (1.8 V), static only: reference for the report
        python3 src/adc_char.py static --k 4 --workers 8 > $CHAR/static_ng.txt 2>&1 ;;
    static)  # board conditions
        python3 src/adc_char.py static --k 4 --workers 8 $BOARD > $CHAR/static_v12.txt 2>&1 ;;
    sine)    # ideal differential input, 27 LSB pk-pk, 256 samples, default frequency list
        python3 src/adc_char.py sine --k 8 --workers 12 $BOARD > $CHAR/sine_v12.txt 2>&1 ;;
    sinefe)  # inputs through the linear model of the board front end (LMV358, GBW 1.4 MHz)
        python3 src/adc_char.py sine --k 8 --workers 10 $BOARD --frontend 1.4e6 \
            --freq 17e3 300e3 500e3 650e3 > $CHAR/sinefe_v12.txt 2>&1 ;;
    xyce)    # simulator cross-check: the same flat netlist (made by the ref/static steps) in both
        python3 src/adc_char.py bench --k 3 > $CHAR/bench_ng.txt 2>&1
        python3 src/adc_char.py bench --k 3 --sim xyce --netlist sim/outputs/SARADC.flat.ckt \
            --tag SARADC.flat > $CHAR/bench_xyce_flat.txt 2>&1 ;;
    report)
        D=$CHAR/ngspice_SARADC.flat_mos_tt_10MHz_vdd1.2_ref0.4-0.8_cm0.6
        python3 sim/report/make_sim_report.py $D --ref $CHAR/ngspice_SARADC.flat_mos_tt_10MHz/static.json
        echo "report: $D/report/report.pdf, summary for RISCVConsole: $D/report/sim_summary.json" ;;
    *) echo "unknown step $step"; exit 1 ;;
    esac
done

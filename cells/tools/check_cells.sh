#!/bin/bash
# DRC and LVS of the ADC cells of cells/<TECH>, with the checks of stdcell-gen
# (test/float/check_cell.sh: the PDK decks, the floating bulk tied to vss/vdd).
#
#   check_cells.sh <tech> <cells dir> <report dir> <cell> ...
#
# The switch and the capacitor have their bodies on the pins vnw/vpw. The layout has no taps, so
# for LVS their netlist gets vnw = vdd and vpw = vss, which is how the deck ties the N-well and
# the substrate. gf180mcuD is only in the asic-all docker image: the checks run there.
T=$1; D=$(realpath "$2"); O=$(mkdir -p "$3" && realpath "$3"); shift 3
STDCELL_GEN=${STDCELL_GEN:-$HOME/Documents/IIZUKA_LAB/stdcell-gen}
CHECK=$STDCELL_GEN/test/float/check_cell.sh
run() {
  for c in "$@"; do
    n=-
    if [ -f "$D/$c.cdl" ] && grep -q "^[MX]" "$D/$c.cdl"; then
      n=$O/$c.lvs.cdl
      sed -e '/^\.SUBCKT/s/ vnw vpw$//' -e '/^[MX]/s/ vnw / vdd /; /^[MX]/s/ vpw / vss /' "$D/$c.cdl" > "$n"
    fi
    bash "$CHECK" "$T" "$D/$c.gds" "$c" "$n" "$O/$c" &
  done
  wait
}
if [ "$T" = gf180mcuf ] && [ -z "$IN_DOCKER" ]; then
  docker run --rm -u $(id -u):$(id -g) -e HOME=/tmp -e IN_DOCKER=1 -e STDCELL_GEN=$STDCELL_GEN \
    -v $STDCELL_GEN:$STDCELL_GEN -v $D:$D -v $O:$O -v $(dirname $(realpath $0)):$(dirname $(realpath $0)) \
    ${DOCKER_IMAGE:-factory.symbioticeda.com/asic-all:dev} \
    bash -lc "bash $(realpath $0) $T $D $O $*" 2>&1 | grep -v tini
  exit ${PIPESTATUS[0]}
fi
run "$@" | sort | tee "$O/check.txt"
! grep -v "drc=\[0[] ]" "$O/check.txt" | grep -q . && ! grep "lvs=" "$O/check.txt" | grep -v "Congratulations\|no devices\|no deck" | grep -q .

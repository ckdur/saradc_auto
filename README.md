# SAR ADC Generator 

This is an ADC generator. Will create an ADC of N bits using open-source tools.
The generator works by assembling several existing standard cells. The current
project contains only cells for IHP-sg13g2, but should be able to work in any
technology node. The repository contains scripts for the assembly of the ADC
using Yosys and OpenROAD mainly.

This ADC is not designed for industrial purposes.

# How to run

Run the following in order to generate the GDS:

```bash
make -C syn all
make -C pnr all
make -C signoff all
```

Once the GDS is ran, you can perform several tests from the `sim` folder.

## Number of bits

The ADC has 5 bits by default (`NBITS` in `settings.mk`); 2 to 8 bits are supported. Give the number
to every stage, e.g. for 8 bits:

```bash
make -C syn all hier NBITS=8
make -C pnr all NBITS=8
make -C signoff all NBITS=8
```

or `export NBITS=8` once (the simulation tools in `src/` and `sim/` read it from the environment as
well). `NBITS` sets the `` `define NBITS`` of the RTL (through Yosys) and `nbits` of the PnR, and a
change of it re-runs the synthesis. Up to 5 bits the CDAC macro of `pnr/` uses the bridgeless
nested pattern (`saradc_nested_pattern`, `docs/dac_wiring.md`); above 5 bits it uses the circle
pattern of the tapeout, with its bridges. The die of `pnr/` follows the size of the macro; the flat
flow (`pnr_legacy/`) keeps the die of `settings.mk` (`X`, `Y`), which is that of 5 bits.
Status: 5 and 8 bits pass DRC and LVS; at 3 bits the detailed router leaves one short at the
comparator (see `CLAUDE.md`).

# Acknoledge

- SARADC paper: [Read it here.](https://ieeexplore.ieee.org/document/11002493)
- Symbiotic EDA used the design of this ADC to evaluate the OpenSource tools.
- The University of Tokyo, which uses the ADC for research purposes.
- IHP for the tapeout.

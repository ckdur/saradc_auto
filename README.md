# SAR ADC Generator 

This is an ADC generator. Will create an ADC of N bits using open-source tools.
The generator works by assembling several existing standard cells. The current
project contains only cells for IHP-sg13g2, but should be able to work in any
technology node. The repository contains scripts for the assembly of the ADC
using Yosys and OpenROAD mainly.

# How to run

Run the following in order to generate the GDS:

```bash
make -C syn all
make -C pnr all
make -C signoff all
```

Once the GDS is ran, you can perform several tests from the `sim` folder.

# Acknoledge

- SARADC paper: [Read it here.](https://ieeexplore.ieee.org/document/11002493)
- Symbiotic EDA sponsored the design of this ADC Generator.
- IHP for the tapeout.

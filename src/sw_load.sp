* Load done for switch.
* Resistance in series with a voltage source, and a capacitance in parallel

.subckt sw_load L VSS vdc=0 Rin=1k
    R0 L net1 {Rin}
    V0 net1 VSS DC {vdc}
.ends sw_classic

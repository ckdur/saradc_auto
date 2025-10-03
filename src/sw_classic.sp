* A classic switch made with regular transistors
* Please change the technology transistor accordingly

* NOTE: The size of the transistors are the following
*       Dummy transistors = same as the inverter
*       Passgate transistors = double of the dummy

.subckt pg_classic S SB VDD VSS Z1 Z2
    * Pass gate
    XMPGP_0 Z1 S Z2 VSS nch_lvt_mac l=1.300e-07 w=360.0n
    XMPGP_1 Z1 S Z2 VSS nch_lvt_mac l=1.300e-07 w=360.0n
    XMPGN_0 Z1 SB Z2 VDD pch_lvt_mac l=1.300e-07 w=600.0n
    XMPGN_1 Z1 SB Z2 VDD pch_lvt_mac l=1.300e-07 w=600.0n
.ends sw_classic

.subckt sw_classic S SB VDD VSS Z1 Z2
    * Balancing dummy transistors
    XMBZ1N Z1 SB Z1 VSS nch_lvt_mac l=1.300e-07 w=360.0n
    XMBZ2N Z2 SB Z2 VSS nch_lvt_mac l=1.300e-07 w=360.0n
    XMBZ1P Z1 S Z1 VDD pch_lvt_mac l=1.300e-07 w=600.00n
    XMBZZP Z2 S Z2 VDD pch_lvt_mac l=1.300e-07 w=600.00n
    * Pass gate
    XPG S SB VDD VSS Z1 Z2 pg_classic
.ends sw_classic



# Flattens the sg13g2f standard cells of a SPICE netlist, keeping the ADC cells.
# The standard cell layouts cannot be matched as subcircuits by the LVS, so the
# schematic needs them flattened into transistors.
# Usage: klayout -b -r flatstd.py -rd src=<in.spice> -rd dst=<out.spice>
import pya

netlist = pya.Netlist()
netlist.read(src, pya.NetlistSpiceReader())
for circuit in [c for c in netlist.each_circuit() if c.name.upper().startswith('SG13G2F_')]:
    netlist.flatten_circuit(circuit)
writer = pya.NetlistSpiceWriter()
writer.use_net_names = True
netlist.write(dst, writer)

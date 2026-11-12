# Builds cells/<TECH> from the float standard cells of stdcell-gen: the standard cell library and
# the ADC cells (SARADC_*) derived from it. Run with KLayout (see cells/Makefile):
#
#   klayout -b -r build_cells.py -rd tech=<tech json> -rd src=<stdcell-gen tmp dir> -rd out=<dir>
#           -rd cells="INVD0 INVD1 ..." -rd blackbox="INVD1 ..."
#
# Inputs, from stdcell-gen (make -f Makefile.<tech> layouts): <tech>_<CELL>.gds (top cell <CELL>),
# <tech>_<CELL>_schematic.cdl/.ckt, <tech>_<CELL>_port.csv, and <tech>.site.lef.
#
# Outputs in <out>:
#   <tech>.gds, .cdl, .ckt, .lef, .port.csv  the standard cells, named <tech>_<CELL>
#   <tech>_blackboxes.v                     blackboxes of the ADC cells and of the cells in `blackbox`
#                                           (the standard cells the RTL instantiates directly)
#   SARADC_<...>.gds, .cdl, .ckt, .lef, .port.csv   the ADC cells:
#     SARADC_CELL_INVX0_ASSW    the switch: INVD0 with its bodies on the pins vpw/vnw
#     SARADC_CELL_INVX16_ASCAP  the unit capacitor: INVD12 (its gates are the plate i), bodies vpw/vnw
#     SARADC_FILLTIE2           the body tie: TAPCELL (vss/vdd are the substrate/N-well taps)
#     SARADC_FILL1              FILL1
#     SARADC_FILL1_NOPOWER      FILL1 without its rails (only wells, implants and the boundary)
#
# The LEF is written here from the layout (not with magic): the boundary gives SIZE, the net of
# each pin label gives the pin shapes on the layers of the tech LEF, the other nets are OBS, and the
# gate/diffusion areas of each pin net give ANTENNAGATEAREA/ANTENNADIFFAREA.
import csv
import json
import os
import re
import pya

T = json.load(open(tech))  # noqa: F821 (set by klayout -rd)
TECH = T["tech"]
SRC, OUT = src, out  # noqa: F821
CELLS = cells.split()  # noqa: F821
BLACKBOX = blackbox.split()  # noqa: F821
os.makedirs(OUT, exist_ok=True)

# The ADC cells: name -> (source cell, ports csv rows, body pins)
ADC = {
    "SARADC_CELL_INVX0_ASSW": ("INVD0", [("vdd", "inputOutput", "supply"), ("vss", "inputOutput", "ground"),
                                         ("i", "input", "signal"), ("zn", "inputOutput", "supply")], True),
    "SARADC_CELL_INVX16_ASCAP": ("INVD12", [("vdd", "inputOutput", "supply"), ("vss", "inputOutput", "ground"),
                                            ("i", "inputOutput", "supply"), ("zn", "inputOutput", "supply")], True),
    "SARADC_FILLTIE2": ("TAPCELL", [("vdd", "inputOutput", "supply"), ("vss", "inputOutput", "ground")], False),
    "SARADC_FILL1": ("FILL1", [("vdd", "inputOutput", "supply"), ("vss", "inputOutput", "ground")], False),
    "SARADC_FILL1_NOPOWER": ("FILL1", [], False),
}


# Ports of the ADC cell blackboxes for the synthesis (as in cells/sg13g2f: i is an input and zn an
# output of the switch and of the capacitor, even if they are routed as special nets)
BB_ADC = {
    "SARADC_CELL_INVX0_ASSW": [("vdd", "inout", ""), ("vss", "inout", ""), ("i", "input", ""), ("zn", "output", "")],
    "SARADC_CELL_INVX16_ASCAP": [("vdd", "inout", ""), ("vss", "inout", ""), ("i", "input", ""), ("zn", "output", "")],
    "SARADC_FILLTIE2": [("vdd", "inout", ""), ("vss", "inout", "")],
}


def srcfile(cell, suffix):
    return os.path.join(SRC, "{}_{}{}".format(TECH, cell, suffix))


def read_ports(cell):
    with open(srcfile(cell, "_port.csv")) as f:
        return [tuple(r[:3]) for r in csv.reader(f) if r]


def read_subckt(path):
    """(name, ports, device lines) of the first subcircuit of a netlist."""
    name, ports, devs = None, [], []
    for line in open(path).read().replace("\r", "").splitlines():
        w = line.split()
        if not w or line.startswith("*"):
            continue
        if w[0].upper() == ".SUBCKT":
            name, ports = w[1], w[2:]
        elif w[0].upper() == ".ENDS":
            break
        elif name:
            devs.append(line)
    return name, ports, devs


def write_subckt(f, name, ports, devs, pininfo=None):
    f.write(".SUBCKT {} {}\n".format(name, " ".join(ports)))
    if pininfo:
        f.write("*.PININFO {}\n".format(pininfo))
    for d in devs:
        f.write(d + "\n")
    f.write(".ENDS\n\n")


def with_bodies(devs):
    """Device lines with the bulk (4th node) of the NMOS on vpw and of the PMOS on vnw."""
    out = []
    for d in devs:
        w = d.split()
        if len(w) > 5 and w[0][0].upper() in "MX":
            if w[5] in T["nmos"]:
                w[4] = "vpw"
            elif w[5] in T["pmos"]:
                w[4] = "vnw"
            d = " ".join(w)
        out.append(d)
    return out


# ---------------------------------------------------------------------------- Layout helpers

def L(ly, ld):
    return ly.layer(ld[0], ld[1])


def read_cell(cell):
    ly = pya.Layout()
    ly.read(srcfile(cell, ".gds"))
    return ly


def copy_into(dst, src_ly, src_name, new_name, keep=None):
    """Copies the cell src_name of src_ly (flattened) into dst as new_name (only the layers in keep,
    if given)."""
    sc = src_ly.cell(src_name)
    c = dst.create_cell(new_name)
    for li in src_ly.layer_indexes():
        info = src_ly.get_info(li)
        if keep is not None and [info.layer, info.datatype] not in keep:
            continue
        dl = dst.layer(info.layer, info.datatype)
        it = sc.begin_shapes_rec(li)
        while not it.at_end():
            c.shapes(dl).insert(it.shape(), it.trans())
            it.next()
    return c


# ---------------------------------------------------------------------------- LEF writer

def nets_of(ly, cell):
    """Extracts the nets of a cell. Returns (l2n, layers dict, gate region, sd region)."""
    l2n = pya.LayoutToNetlist(pya.RecursiveShapeIterator(ly, cell, []))
    l2n.threads = 1
    lay = {}
    for k, c in T["conductors"].items():
        lay[k] = l2n.make_layer(L(ly, c["gds"]), k)
    diff = l2n.make_layer(L(ly, T["diff"]), "diff")
    gate = lay["poly"] & diff
    sd = diff - lay["poly"]
    lay["sd"] = sd
    l2n.register(sd, "sd")
    for k, c in T["conductors"].items():
        for i, tl in enumerate(c.get("texts", [])):
            t = l2n.make_text_layer(L(ly, tl), "{}_t{}".format(k, i))
            l2n.connect(lay[k], t)
    for a, b in T["connect"]:
        l2n.connect(lay[a], lay[b])
    for k in lay:
        l2n.connect(lay[k])
    l2n.extract_netlist()
    return l2n, lay, gate, sd


def rects(region):
    out = []
    for p in region.merged().decompose_trapezoids_to_region().each():
        b = p.bbox()
        out.append(b)
    return sorted(out, key=lambda b: (b.bottom, b.left))


def lef_macro(ly, cell, name, ports, cls, site, bodies=False):
    dbu = ly.dbu
    bnd = pya.Region(cell.begin_shapes_rec(L(ly, T["boundary"])))
    bb = bnd.bbox()
    l2n, lay, gate, sd = nets_of(ly, cell)
    circ = next(l2n.netlist().each_circuit_top_down(), None)  # None: no conductors
    allnets = list(circ.each_net()) if circ else []
    byname = {}
    for net in allnets:
        for n in net.name.split(",") if net.name else []:
            byname.setdefault(n, []).append(net)
    pin_nets = set()
    s = []
    s.append("MACRO {}\n  CLASS {} ;\n  FOREIGN {} ;\n  ORIGIN 0.000 0.000 ;\n".format(name, cls, name))
    s.append("  SIZE {:.3f} BY {:.3f} ;\n  SYMMETRY X Y R90 ;\n".format(bb.width() * dbu, bb.height() * dbu))
    if site:
        s.append("  SITE {} ;\n".format(site))
    if bodies:
        s.append("  PIN vnw\n  END vnw\n  PIN vpw\n  END vpw\n")
    a2 = dbu * dbu
    for pname, direction, use in ports:
        nets = byname.get(pname, [])
        d = {"input": "INPUT", "output": "OUTPUT"}.get(direction, "INOUT")
        u = {"supply": "POWER", "ground": "GROUND"}.get(use, "SIGNAL")
        s.append("  PIN {}\n    DIRECTION {} ;\n    USE {} ;\n".format(pname, d, u))
        if u != "SIGNAL" and site:
            s.append("    SHAPE ABUTMENT ;\n")
        geo = {}
        ga = da = 0
        for net in nets:
            pin_nets.add(net.cluster_id)
            for k, c in T["conductors"].items():
                if c.get("cut") or not c.get("lef"):
                    continue
                geo.setdefault(c["lef"], pya.Region())
                geo[c["lef"]] += l2n.shapes_of_net(net, lay[k], True)
            poly = l2n.shapes_of_net(net, lay["poly"], True)
            ga += (gate & poly).area()
            da += l2n.shapes_of_net(net, lay["sd"], True).area()
        if u == "SIGNAL" and d == "INPUT" and ga:
            s.append("    ANTENNAGATEAREA {:.6f} ;\n".format(ga * a2))
        if u == "SIGNAL" and d != "INPUT" and da:
            s.append("    ANTENNADIFFAREA {:.6f} ;\n".format(da * a2))
        if any(not r.is_empty() for r in geo.values()):
            s.append("    PORT\n")
            for lname, r in geo.items():
                if r.is_empty():
                    continue
                s.append("      LAYER {} ;\n".format(lname))
                for b in rects(r):
                    s.append("        RECT {:.3f} {:.3f} {:.3f} {:.3f} ;\n".format(
                        b.left * dbu, b.bottom * dbu, b.right * dbu, b.top * dbu))
            s.append("    END\n")
        s.append("  END {}\n".format(pname))
    obs = {}
    for net in allnets:
        if net.cluster_id in pin_nets:
            continue
        for k, c in T["conductors"].items():
            if c.get("cut") or not c.get("lef") or k == "poly":
                continue
            obs.setdefault(c["lef"], pya.Region())
            obs[c["lef"]] += l2n.shapes_of_net(net, lay[k], True)
    if any(not r.is_empty() for r in obs.values()):
        s.append("  OBS\n")
        for lname, r in obs.items():
            if r.is_empty():
                continue
            s.append("    LAYER {} ;\n".format(lname))
            for b in rects(r):
                s.append("      RECT {:.3f} {:.3f} {:.3f} {:.3f} ;\n".format(
                    b.left * dbu, b.bottom * dbu, b.right * dbu, b.top * dbu))
        s.append("  END\n")
    s.append("END {}\n\n".format(name))
    return "".join(s)


LEF_HEAD = 'VERSION 5.7 ;\nDIVIDERCHAR "/" ;\nBUSBITCHARS "[]" ;\n\n'


def classof(cell):
    if cell.startswith("FILL"):
        return "CORE SPACER"
    if cell == "TAPCELL":
        return "CORE WELLTAP"
    if cell == "ANTENNA":
        return "CORE ANTENNACELL"
    if cell.startswith("TIE"):
        return "CORE TIEHIGH" if cell == "TIEH" else "CORE TIELOW"
    return "CORE"


def blackbox_module(name, ports, bodies=False):
    names = [p[0] for p in ports]
    ins = [p[0] for p in ports if p[1] == "input"]
    outs = [p[0] for p in ports if p[1] == "output"]
    ios = [p[0] for p in ports if p[1] not in ("input", "output")]
    if bodies:
        names = ["vnw", "vpw"] + names
        ios = ["vnw", "vpw"] + ios
    s = "(* blackbox *)\nmodule {}({});\n".format(name, ", ".join(names))
    if ins:
        s += "    input {};\n".format(", ".join(ins))
    if outs:
        s += "    output {};\n".format(", ".join(outs))
    if ios:
        s += "    inout {};\n".format(", ".join(ios))
    return s + "endmodule\n\n"


# ---------------------------------------------------------------------------- Standard cells

lib = pya.Layout()
lib.dbu = 0.001
lef = [LEF_HEAD, open(os.path.join(SRC, TECH + ".site.lef")).read().split("END LIBRARY")[0], "\n"]
cdl, ckt, portrows, bb = [], [], [], []
for cell in CELLS:
    ly = read_cell(cell)
    name = "{}_{}".format(TECH, cell)
    c = copy_into(lib, ly, cell, name)
    ports = read_ports(cell)
    portrows += [p for p in ports if p not in portrows]
    lef.append(lef_macro(lib, c, name, ports, classof(cell), T["site"]))
    for dst, suf in ((cdl, "_schematic.cdl"), (ckt, "_schematic.ckt")):
        n, p, d = read_subckt(srcfile(cell, suf))
        dst.append((name, p, d))
    if cell in BLACKBOX:
        bb.append(blackbox_module(name, ports))
lib.write(os.path.join(OUT, TECH + ".gds"))
open(os.path.join(OUT, TECH + ".lef"), "w").write("".join(lef) + "END LIBRARY\n")
for path, items in ((TECH + ".cdl", cdl), (TECH + ".ckt", ckt)):
    with open(os.path.join(OUT, path), "w") as f:
        f.write("* {} float standard cells (stdcell-gen), cells/tools/build_cells.py\n\n".format(TECH))
        for n, p, d in items:
            write_subckt(f, n, p, d)
with open(os.path.join(OUT, TECH + ".port.csv"), "w") as f:
    csv.writer(f).writerows(portrows)

# ---------------------------------------------------------------------------- ADC cells

for name, (base, ports, bodies) in ADC.items():
    ly = read_cell(base)
    out_ly = pya.Layout()
    out_ly.dbu = 0.001
    keep = T["nopower_keep"] if name.endswith("_NOPOWER") else None
    c = copy_into(out_ly, ly, base, name, keep)
    out_ly.write(os.path.join(OUT, name + ".gds"))
    open(os.path.join(OUT, name + ".lef"), "w").write(
        LEF_HEAD + lef_macro(out_ly, c, name, ports, "BLOCK", None, bodies) + "END LIBRARY\n")
    with open(os.path.join(OUT, name + ".port.csv"), "w") as f:
        csv.writer(f).writerows(ports)
    for suf, ext in (("_schematic.cdl", ".cdl"), ("_schematic.ckt", ".ckt")):
        n, p, d = read_subckt(srcfile(base, suf))
        if name.endswith("_NOPOWER"):
            p, d = [], []
        if bodies:
            p, d = p + ["vnw", "vpw"], with_bodies(d)
        with open(os.path.join(OUT, name + ext), "w") as f:
            f.write("* {} ({} of {}), cells/tools/build_cells.py\n".format(name, base, TECH))
            write_subckt(f, name, p, d)
    if name in BB_ADC:
        bb.insert(0, blackbox_module(name, BB_ADC[name], bodies))

with open(os.path.join(OUT, TECH + "_blackboxes.v"), "w") as f:
    f.write("// Blackboxes of the ADC cells and of the {} cells the RTL instantiates (build_cells.py)\n\n".format(TECH))
    f.write("".join(bb))
print("Built {} ({} standard cells, {} ADC cells) in {}".format(TECH, len(CELLS), len(ADC), OUT))

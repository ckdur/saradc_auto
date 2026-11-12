#!/usr/bin/env python3
"""Merges the per-cell liberty files of stdcell-gen (lctime) into one library, with the cells
renamed <tech>_<CELL>, and writes verilog models from their functions.

usage: merge_lib.py <tech> <stdcell-gen tmp dir> <out dir> <lef> <cell> [<cell> ...]

Reads <tmp>/<tech>_<CELL>.lib (cells without one, such as fillers and taps, are skipped) and
writes <out>/<tech>.lib and <out>/<tech>.v. The library header is the one of the first file,
with the library named <tech>, plus the table templates (lu_table_template etc.) of the other files
(each lctime file only has the ones of its own cell: the flip-flops add setup/hold/recovery/removal). The template of lctime has a placeholder area: the area of each cell
is its SIZE in <lef> (the LEF of cells/<tech>). lctime writes `clear : "0"` and `preset : "0"` in the
ff group of the flip-flops without them; these lines are dropped.

The verilog models (for gate-level simulation) come from the liberty: `function` of the
combinational outputs, and the `ff` group (clocked_on, next_state, clear, preset) of the
flip-flops. Tie cells get constant outputs.
"""
import os
import re
import sys


def groups(text, start=0):
    """Yields (head, body, end) of the top-level groups `head { body }` from start."""
    i, n = start, len(text)
    while i < n:
        m = re.compile(r"([A-Za-z_][\w]*\s*\([^)]*\))\s*\{").search(text, i)
        if not m:
            return
        depth, j = 1, m.end()
        while depth and j < n:
            c = text[j]
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
            elif c == '"':
                j = text.index('"', j + 1)
            j += 1
        yield m.group(1), text[m.end():j - 1], j
        i = j


def strip_comments(s):
    return re.sub(r"/\*.*?\*/", "", s, flags=re.S)


def attr(body, name):
    m = re.search(r"\b" + name + r"\s*:\s*\"?([^;\"]*)\"?\s*;", body)
    return m.group(1).strip() if m else None


def verilog_expr(f):
    """Liberty boolean function to verilog."""
    f = f.replace("!", "~").replace("+", "|").replace("*", "&")
    # Implicit AND (juxtaposition): "a b" or ")(" -> "a & b"
    f = re.sub(r"([\w)])\s+(?=[\w(~])", r"\1 & ", f)
    f = re.sub(r"\)\s*\(", ") & (", f)
    return f


def verilog_module(name, body):
    pins = []
    for head, pbody, _ in groups(body):
        m = re.match(r"pin\s*\(\s*([^)\s]+)\s*\)", head)
        if m:
            pins.append((m.group(1), attr(pbody, "direction"), attr(pbody, "function")))
    ins = [p for p, d, _ in pins if d == "input"]
    outs = [(p, f) for p, d, f in pins if d == "output"]
    s = "module {}({});\n".format(name, ", ".join(ins + [p for p, _ in outs]))
    if ins:
        s += "  input {};\n".format(", ".join(ins))
    s += "  output {};\n".format(", ".join(p for p, _ in outs))
    ff = None
    for head, fbody, _ in groups(body):
        m = re.match(r"ff\s*\(\s*([^,\s]+)\s*,\s*([^)\s]+)\s*\)", head)
        if m:
            ff = (m.group(1), m.group(2), fbody)
    if ff:
        iq, iqn, fbody = ff
        clk, nxt = attr(fbody, "clocked_on"), attr(fbody, "next_state")
        clr, pre = attr(fbody, "clear"), attr(fbody, "preset")
        clr, pre = (None if v in (None, "0") else v for v in (clr, pre))
        s += "  reg {} = 1'b0;\n  wire {} = ~{};\n".format(iq, iqn, iq)
        ev = ["posedge ({})".format(verilog_expr(clk))]
        if clr:
            ev.append("posedge ({})".format(verilog_expr(clr)))
        if pre:
            ev.append("posedge ({})".format(verilog_expr(pre)))
        s += "  always @({}) begin\n    ".format(" or ".join(ev))
        if clr:
            s += "if ({}) {} <= 1'b0;\n    else ".format(verilog_expr(clr), iq)
        if pre:
            s += "if ({}) {} <= 1'b1;\n    else ".format(verilog_expr(pre), iq)
        s += "{} <= {};\n  end\n".format(iq, verilog_expr(nxt))
    for p, f in outs:
        if f is None:
            f = "1" if re.search(r"TIEH$", name) else "0" if re.search(r"TIEL$", name) else None
        if f is not None:
            f = {"1": "1'b1", "0": "1'b0"}.get(f.strip(), f)
            s += "  assign {} = {};\n".format(p, verilog_expr(f))
    return s + "endmodule\n\n"


def lef_areas(path):
    areas, name = {}, None
    for line in open(path):
        m = re.match(r"\s*MACRO\s+(\S+)", line)
        if m:
            name = m.group(1)
        m = re.match(r"\s*SIZE\s+([\d.]+)\s+BY\s+([\d.]+)", line)
        if m and name:
            areas[name] = float(m.group(1)) * float(m.group(2))
            name = None
    return areas


def main():
    tech, src, out, lef = sys.argv[1:5]
    cells = sys.argv[5:]
    areas = lef_areas(lef)
    header, blocks, vmods, templates = None, [], [], {}
    for cell in cells:
        path = os.path.join(src, "{}_{}.lib".format(tech, cell))
        if not os.path.exists(path):
            continue
        text = strip_comments(open(path).read())
        (lhead, lbody, _), = list(groups(text))
        name = "{}_{}".format(tech, cell)
        for head, body, end in groups(lbody):
            if re.match(r"cell\s*\(", head):
                if header is None:
                    header = lbody[:lbody.index(head)]
                for thead, tbody, _ in groups(lbody[:lbody.index(head)]):
                    if re.match(r"\w*_template\s*\(", thead):
                        templates.setdefault(re.sub(r"\s+", "", thead), (thead, tbody))
                body = re.sub(r"\n\s*(clear|preset)\s*:\s*\"0\"\s*;", "", body)
                if name not in areas:
                    sys.exit("{} is not in {}".format(name, lef))
                body = re.sub(r"(\barea\s*:\s*)[\d.]+", r"\g<1>{:.4f}".format(areas[name]), body, count=1)
                blocks.append("  cell ({}) {{{}}}\n".format(name, body))
                vmods.append(verilog_module(name, body))
    if header is None:
        sys.exit("No liberty files for {} in {}".format(tech, src))
    have = {re.sub(r"\s+", "", h) for h, _, _ in groups(header)}
    header = header.rstrip() + "\n" + "".join("  {} {{{}}}\n".format(h, b)
                                             for k, (h, b) in templates.items() if k not in have)
    with open(os.path.join(out, tech + ".lib"), "w") as f:
        f.write("/* {} float standard cells, characterized with lctime (stdcell-gen), merged by"
                " cells/tools/merge_lib.py */\n".format(tech))
        f.write("library ({}) {{{}".format(tech, header.rstrip() + "\n\n"))
        f.write("\n".join(blocks))
        f.write("}\n")
    with open(os.path.join(out, tech + ".v"), "w") as f:
        f.write("// {} cell models from the liberty functions (cells/tools/merge_lib.py)\n\n".format(tech))
        f.write("".join(vmods))
    print("{}: {} cells in {}.lib/.v".format(tech, len(blocks), tech))


if __name__ == "__main__":
    main()

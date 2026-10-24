#!/usr/bin/env python3
"""Build the simulation characterization report of the SARADC from the results of src/adc_char.py.

  make_sim_report.py <char_dir> [build_dir]

<char_dir> is a directory made by adc_char.py (static.json and sine_*.json). Writes the figures
(vector PDF), results.tex (LaTeX macros and tables) and sim_summary.json into build_dir (default:
<char_dir>/report), then compiles report.tex there with latexmk. sim_summary.json is the file the
measurement report of the chip (RISCVConsole software/mso/report) compares against.
"""
import glob
import json
import os
import shutil
import subprocess
import sys

import matplotlib
matplotlib.use("pdf")
import matplotlib.pyplot as plt
import matplotlib.ticker
import numpy as np

REPORT_DIR = os.path.dirname(os.path.abspath(__file__))
SIMOUT = os.path.join(REPORT_DIR, "..", "outputs")


def pdk_version():
    """Git state of the PDK in $PDK_ROOT/$PDK (environment of init_openlane.sh)."""
    pdk = os.path.join(os.environ.get("PDK_ROOT", "/opt/ext/OpenPDKs"), os.environ.get("PDK", "ihp-sg13g2"))
    git = lambda *a: subprocess.run(["git", "-C", pdk] + list(a), capture_output=True, text=True).stdout.strip()
    commit = git("log", "-1", "--format=%h")
    if not commit:
        return None
    return {"name": os.environ.get("PDK", "ihp-sg13g2"), "commit": commit, "describe": git("describe", "--tags", "--always"),
            "branch": git("rev-parse", "--abbrev-ref", "HEAD"), "date": git("log", "-1", "--format=%cd", "--date=short"),
            "remote": git("remote", "get-url", "origin")}

NBITS = 5
NCODES = 1 << NBITS
NHARM = 7

# Reference palette (light mode, categorical slots in fixed order) and text inks
SERIES = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100"]
INK = "#0b0b0b"
INK2 = "#52514e"
GRID = "#e4e3df"

plt.rcParams.update({
    "font.family": "serif", "font.size": 8, "axes.titlesize": 9, "axes.labelsize": 8,
    "axes.edgecolor": INK2, "axes.labelcolor": INK, "axes.linewidth": 0.6,
    "xtick.color": INK2, "ytick.color": INK2, "xtick.labelsize": 7, "ytick.labelsize": 7,
    "axes.grid": True, "grid.color": GRID, "grid.linewidth": 0.5,
    "axes.spines.top": False, "axes.spines.right": False,
    "legend.frameon": False, "legend.fontsize": 7, "lines.linewidth": 1.2,
    "pdf.fonttype": 42, "figure.dpi": 150,
})
FIG_W = 5.6  # inches, \textwidth of the report


def save(fig, build, name):
    fig.tight_layout()
    fig.savefig(os.path.join(build, "fig", name + ".pdf"))
    plt.close(fig)


def sine_fit(x, fs, freq):
    """3 parameter sine fit at a known (coherent) frequency. Returns (amplitude, offset, phase, fitted)."""
    tt = np.arange(len(x)) / fs
    a = np.column_stack([np.cos(2 * np.pi * freq * tt), np.sin(2 * np.pi * freq * tt), np.ones(len(x))])
    p, *_ = np.linalg.lstsq(a, x, rcond=None)
    return np.hypot(p[0], p[1]), p[2], np.arctan2(-p[1], p[0]), a @ p


def alias_bin(k, n):
    k %= n
    return n - k if k > n // 2 else k


# ---------------------------------------------------------------------------------------------
# Analysis


def analyze_static(st):
    """Transition levels from the bisection (differential volts) -> LSB, DNL, INL (end point)."""
    t = np.array([st["transitions"][str(k)] for k in range(1, NCODES)])
    lsb = (t[-1] - t[0]) / (NCODES - 2)
    dnl = np.diff(t) / lsb - 1
    inl = (t - (t[0] + lsb * np.arange(NCODES - 1))) / lsb
    ideal = st["lsb_ideal"]
    # Ideal converter: T_k = (k - NCODES/2) * LSB (code = floor(v / LSB) + NCODES/2)
    return {"t": t, "lsb": lsb, "dnl": dnl, "inl": inl, "lsb_ideal": ideal,
            "gain_err": lsb / ideal - 1, "offset_lsb": (t[0] + t[-1]) / 2 / ideal,
            "resolution": st["resolution"], "coarse_levels": np.array(st["coarse_levels"]),
            "coarse_codes": np.array(st["coarse_codes"]),
            "missing": [k for k in range(1, NCODES - 1) if t[k] - t[k - 1] <= 0]}


DBC_FLOOR = -100  # Harmonics below this are numerical zeros (exact cancellation of even orders)


def dbc_tex(v):
    return "{$<%d$}" % DBC_FLOOR if v <= DBC_FLOOR else "%.1f" % v


def analyze_sine(sn, r=None):
    x = np.array(sn["codes"], float)
    n, fs, f, j = len(x), sn["fs"], sn["freq"], sn["cycles"]
    amp, off, ph, y = sine_fit(x, fs, f)
    err = np.sqrt(np.mean((x - y) ** 2))
    sinad = 20 * np.log10(amp / np.sqrt(2) / err)
    # Coherent record: rectangular window, every tone in a single bin
    spec = np.abs(np.fft.rfft(x - x.mean())) ** 2 / (n / 2) ** 2 / 2  # A^2/2 for a sine of amplitude A
    p_fund = spec[j]
    harm = {}
    used = {0, j}
    for hk in range(2, NHARM + 1):
        b = alias_bin(hk * j, n)
        harm[hk] = {"freq": b * fs / n, "dbc": max(10 * np.log10(max(spec[b], 1e-30) / p_fund), DBC_FLOOR)}
        used.add(b)
    p_harm = sum(spec[alias_bin(hk * j, n)] for hk in range(2, NHARM + 1))
    rest = np.array([spec[b] for b in range(len(spec)) if b not in used])
    spur = spec.copy()
    spur[[0, j]] = 0
    out = {"freq": f, "fs": fs, "cycles": j, "n": n, "codes": x, "amp": amp, "offset": off, "fitted": y,
           "sinad": sinad, "enob": (sinad - 1.76) / 6.02, "harm": harm,
           "thd": 10 * np.log10(max(p_harm, 1e-30) / p_fund),
           "snr": 10 * np.log10(p_fund / max(rest.sum(), 1e-30)),
           "sfdr": 10 * np.log10(p_fund / spur.max()),
           "spec_dbfs": 10 * np.log10(np.maximum(spec, 1e-30) / ((NCODES / 2) ** 2 / 2)),
           "spec_freqs": np.arange(len(spec)) * fs / n,
           "clip": float(np.mean((x == 0) | (x == NCODES - 1))),
           "amp_in_lsb": sn["amp_vpp"] / 2 / (r["lsb"] if r else sn["amp_vpp"])}
    if r is not None:
        # What the static transfer alone predicts: the same ideal sine quantized with T_k
        vin = np.array(sn["vin_sampled"])
        xs = np.searchsorted(r["t"], vin).astype(float)
        a2, _, _, y2 = sine_fit(xs, fs, f)
        out["sinad_static"] = 20 * np.log10(a2 / np.sqrt(2) / np.sqrt(np.mean((xs - y2) ** 2)))
        out["enob_static"] = (out["sinad_static"] - 1.76) / 6.02
    return out


def unit_cap_cv():
    """C(V) of SARADC_CELL_INVX16_ASCAP from the cap_linearity AC runs (sim/Makefile test_cap_linearity)."""
    vs, cs = [], []
    for f in sorted(glob.glob(os.path.join(SIMOUT, "cap_linearity.xyce.*.csv"))):
        d = np.genfromtxt(f, delimiter=",", names=True)
        z = (d["ReVVPLUS"] + 1j * d["ImVVPLUS"]) / (d["ReIVPORT"] + 1j * d["ImIVPORT"])
        i = np.searchsorted(d["FREQ"], 100e6)
        vs.append(float(os.path.basename(f).split("xyce.")[1][:4]))
        cs.append(-1 / (2 * np.pi * d["FREQ"][i] * np.imag(z[i])))
    return np.array(vs), np.abs(np.array(cs))


# ---------------------------------------------------------------------------------------------
# Figures


def fig_cap(v, c, build):
    fig, ax = plt.subplots(figsize=(FIG_W, 2.2))
    ax.plot(v, c * 1e15, color=SERIES[0], marker="o", ms=3.5)
    ax.set_xlabel("Bias of the gate terminal (V)")
    ax.set_ylabel("Unit capacitance (fF)")
    save(fig, build, "cap_cv")


def fig_transfer(r, build):
    t, lsb = r["t"] * 1e3, r["lsb"] * 1e3
    fig, ax = plt.subplots(figsize=(FIG_W, 2.6))
    v = np.concatenate([[t[0] - 2 * lsb], np.repeat(t, 2), [t[-1] + 2 * lsb]])
    c = np.concatenate([[0, 0], np.repeat(np.arange(1, NCODES), 2)])[:len(v)]
    ax.plot(v, c, color=SERIES[0], label="Simulated")
    li = r["lsb_ideal"] * 1e3
    ideal = li * (np.arange(-1, NCODES + 1) - NCODES / 2)
    ax.plot(ideal, np.arange(-1, NCODES + 1) - 0.5, color=INK2, lw=0.8, ls="--", label="Ideal")
    ax.set_xlabel("Differential input $V_{IP}-V_{IN}$ (mV)")
    ax.set_ylabel("Output code")
    ax.set_ylim(-0.5, NCODES - 0.5)
    ax.legend(loc="upper left")
    save(fig, build, "transfer")


def fig_dnl_inl(r, build):
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(FIG_W, 3.4), sharex=True)
    a1.bar(np.arange(1, NCODES - 1), r["dnl"], width=0.7, color=SERIES[0])
    a1.axhline(0, color=INK2, lw=0.6)
    a1.set_ylabel("DNL (LSB)")
    a1.set_title("Differential nonlinearity", loc="left", color=INK)
    a2.plot(np.arange(1, NCODES), r["inl"], color=SERIES[0], marker="o", ms=3)
    a2.axhline(0, color=INK2, lw=0.6)
    a2.set_ylabel("INL (LSB)")
    a2.set_xlabel("Code (transition k-1 to k for INL)")
    a2.set_title("Integral nonlinearity (end point)", loc="left", color=INK)
    a2.set_xticks(range(0, NCODES, 4))
    save(fig, build, "dnl_inl")


def fig_spectrum(s, build, name):
    fig, ax = plt.subplots(figsize=(FIG_W, 2.4))
    ax.plot(s["spec_freqs"] / 1e3, s["spec_dbfs"], color=SERIES[0], lw=0.8, drawstyle="steps-mid")
    for k, h in s["harm"].items():
        if h["dbc"] > -60:
            y = s["spec_dbfs"][int(round(h["freq"] / s["fs"] * s["n"]))]
            ax.annotate("H%d" % k, (h["freq"] / 1e3, y), xytext=(0, 3), textcoords="offset points",
                        ha="center", fontsize=6, color=INK2)
    ax.set_xlabel("Frequency (kHz)")
    ax.set_ylabel("Power (dBFS)")
    ax.set_xlim(0, s["fs"] / 2e3)
    ax.set_ylim(-90, 5)
    save(fig, build, name)


def fig_sine_time(s, build, name):
    n = min(len(s["codes"]), max(int(round(3 * s["fs"] / s["freq"])), 60))
    t = np.arange(n) / s["fs"] * 1e6
    fig, ax = plt.subplots(figsize=(FIG_W, 2.2))
    ax.plot(t, s["fitted"][:n], color=INK2, lw=0.8, ls="--", label="Sine fit")
    ax.plot(t, s["codes"][:n], color=SERIES[0], drawstyle="steps-post", label="ADC output")
    ax.set_xlabel("Time (µs)")
    ax.set_ylabel("Code")
    ax.set_ylim(-0.5, NCODES - 0.5)
    ax.legend(loc="lower left", bbox_to_anchor=(0, 1.0), ncol=2)
    save(fig, build, name)


def khz_axis(ax):
    ax.xaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(lambda v, _: "%g" % v))


def fig_sweep(sines, build):
    f = np.array([s["freq"] for s in sines]) / 1e3
    fig, ax = plt.subplots(figsize=(FIG_W, 2.4))
    ax.semilogx(f, [s["enob"] for s in sines], color=SERIES[0], marker="o", ms=4, label="Transient simulation")
    ax.semilogx(f, [s["enob_static"] for s in sines], color=SERIES[1], marker="o", ms=3.5,
                label="Predicted from the simulated static transfer")
    ax.legend(loc="lower left", bbox_to_anchor=(0, 1.0), ncol=2)
    ax.set_xlabel("Input frequency (kHz)")
    khz_axis(ax)
    ax.set_ylabel("ENOB (bits)")
    ax.axhline(NBITS, color=INK2, lw=0.6, ls="--")
    ax.set_ylim(0, NBITS + 0.5)
    save(fig, build, "sweep_enob")

    fig, ax = plt.subplots(figsize=(FIG_W, 2.6))
    series = [("THD", [s["thd"] for s in sines])] + \
             [("H%d" % k, [s["harm"][k]["dbc"] for s in sines]) for k in (2, 3, 5)]
    for i, (lbl, y) in enumerate(series):
        y = np.where(np.array(y) <= DBC_FLOOR, np.nan, y)  # Numerical zeros are left out
        ax.semilogx(f, y, color=SERIES[i], marker="o", ms=3.5, label=lbl)
    ax.set_xlabel("Input frequency (kHz)")
    khz_axis(ax)
    ax.set_ylabel("Level (dBc)")
    ax.set_ylim(DBC_FLOOR - 5, 0)
    ax.legend(loc="lower left", bbox_to_anchor=(0, 1.0), ncol=4)
    save(fig, build, "sweep_harmonics")


# ---------------------------------------------------------------------------------------------
# LaTeX


def bit_weights(r):
    """Binary weights (end-point LSB) that best fit the transition levels."""
    k = np.arange(1, NCODES)
    X = np.column_stack([[(kk >> b) & 1 for kk in k] for b in range(NBITS)] + [np.ones(len(k))])
    return np.linalg.lstsq(X, k + r["inl"], rcond=None)[0][:NBITS]


def write_fe(build, sines, fes):
    """Ideal differential input against the input through the linear front-end model."""
    by = {round(s["freq"]): s for s in sines}
    with open(os.path.join(build, "table_fe.tex"), "w") as fo:
        fo.write("\\begin{tabular}{S[table-format=3.1] S[table-format=2.2] S[table-format=2.2] S[table-format=1.2] "
                 "S[table-format=1.2] S[table-format=-3.1] S[table-format=-3.1] S[table-format=-2.1] S[table-format=-2.1]}\n"
                 "\\toprule\n{$f_{in}$} & \\multicolumn{2}{c}{$A$ (LSB)} & \\multicolumn{2}{c}{ENOB (bits)} & "
                 "\\multicolumn{2}{c}{H2 (\\si{dBc})} & \\multicolumn{2}{c}{H3 (\\si{dBc})} \\\\\n"
                 "{(\\si{kHz})} & {ideal} & {board} & {ideal} & {board} & {ideal} & {board} & {ideal} & {board} \\\\\n"
                 "\\midrule\n")
        for f in fes:
            i = by.get(round(f["freq"]))
            g = lambda s, fmt, key: (fmt % key(s)) if s else "{--}"
            h = lambda s, k: dbc_tex(s["harm"][k]["dbc"]) if s else "{--}"
            fo.write("%.1f & %s & %.2f & %s & %.2f & %s & %s & %s & %s \\\\\n" % (
                f["freq"] / 1e3, g(i, "%.2f", lambda s: s["amp"]), f["amp"], g(i, "%.2f", lambda s: s["enob"]),
                f["enob"], h(i, 2), h(f, 2), h(i, 3), h(f, 3)))
        fo.write("\\bottomrule\n\\end{tabular}\n")
    hi = fes[-1]
    L = ["\\newcommand{\\%s}{%s}" % kv for kv in [
        ("FeFreqHigh", "%.1f" % (hi["freq"] / 1e3)), ("FeEnobHigh", "%.2f" % hi["enob"]),
        ("FeAmpHigh", "%.2f" % hi["amp"]), ("FeAmpLow", "%.2f" % fes[0]["amp"]),
        ("FeHtwoMax", "%.0f" % max(f["harm"][2]["dbc"] for f in fes)),
        ("FeHtwoMaxFreq", "%.0f" % (max(fes, key=lambda f: f["harm"][2]["dbc"])["freq"] / 1e3))]]
    with open(os.path.join(build, "results_fe.tex"), "w") as fo:
        fo.write("\n".join(L) + "\n")


def write_tex(build, meta, r, sines, cap):
    L = []
    m = lambda k, v: L.append("\\newcommand{\\%s}{%s}" % (k, v))
    m("CharDir", meta["dir"].replace("_", r"\_"))
    m("Fclk", "%g" % (meta["fclk"] / 1e6))
    m("Fs", "%.4f" % (meta["fclk"] / 7 / 1e6))
    m("LsbIdeal", "%.2f" % (r["lsb_ideal"] * 1e3))
    m("Lsb", "%.2f" % (r["lsb"] * 1e3))
    m("GainErr", "%.1f" % (r["gain_err"] * 100))
    m("OffsetLsb", "%.2f" % r["offset_lsb"])
    m("TFirst", "%.1f" % (r["t"][0] * 1e3))
    m("TLast", "%.1f" % (r["t"][-1] * 1e3))
    m("DnlMin", "%.2f" % r["dnl"].min())
    m("DnlMax", "%.2f" % r["dnl"].max())
    m("InlMin", "%.2f" % r["inl"].min())
    m("InlMax", "%.2f" % r["inl"].max())
    m("Resolution", "%.2f" % (r["resolution"] * 1e3))
    m("MissingCodes", ", ".join(map(str, r["missing"])) if r["missing"] else "none")
    if sines:
        m("NSine", sines[0]["n"])
        m("SineAmpLsb", "%.1f" % (sines[0]["amp_in_lsb"]))
        m("SineLowFreq", "%.1f" % (sines[0]["freq"] / 1e3))
        m("SineLowEnob", "%.2f" % sines[0]["enob"])
        m("SineLowSinad", "%.2f" % sines[0]["sinad"])
        m("SineHighFreq", "%.1f" % (sines[-1]["freq"] / 1e3))
        m("SineHighEnob", "%.2f" % sines[-1]["enob"])
    m("CapMin", "%.2f" % (cap[1].min() * 1e15))
    m("CapMax", "%.2f" % (cap[1].max() * 1e15))
    m("CapVmin", "%.1f" % cap[0][np.argmin(cap[1])])
    m("Simulator", meta["sim"])
    if sines:
        m("SineLowSinadSt", "%.2f" % sines[0]["sinad_static"])
        m("SineHighSinad", "%.2f" % sines[-1]["sinad"])
        m("SineHtreeHigh", "%.0f" % sines[-1]["harm"][3]["dbc"])
        m("SineHtreeLow", "%.0f" % sines[0]["harm"][3]["dbc"])
    st = meta["static"]
    m("Vdd", "%g" % st.get("vdd", 1.8))
    m("Vrefh", "%g" % st.get("vrefh", 1.35))
    m("Vrefl", "%g" % st.get("vrefl", 0.45))
    m("Vcm", "%g" % st.get("vcm", 0.9))
    w = bit_weights(r)
    for b in range(NBITS):
        m("BitW" + "ABCDEFGH"[b], "%.3f" % w[b])
    if meta.get("ref"):
        q = meta["ref"]
        m("RefVdd", "%g" % q["vdd"])
        m("RefLsb", "%.2f" % (q["lsb"] * 1e3))
        m("RefLsbIdeal", "%.2f" % (q["lsb_ideal"] * 1e3))
        m("RefGainErr", "%.1f" % (q["gain_err"] * 100))
        m("RefDnlMax", "%.2f" % np.abs(q["dnl"]).max())
        m("RefInlMax", "%.2f" % np.abs(q["inl"]).max())
        m("RefResolution", "%.2f" % (q["resolution"] / q["lsb"]))
        wq = bit_weights(q)
        for b in range(NBITS):
            m("RefBitW" + "ABCDEFGH"[b], "%.3f" % wq[b])
    m("Corner", meta["corner"].replace("_", r"\_"))
    pv = meta.get("pdk") or {}
    m("PdkName", pv.get("name", "ihp-sg13g2"))
    m("PdkCommit", pv.get("commit", "unknown"))
    m("PdkDescribe", pv.get("describe", "unknown"))
    m("PdkBranch", pv.get("branch", "unknown"))
    m("PdkDate", pv.get("date", "unknown"))
    with open(os.path.join(build, "results.tex"), "w") as fo:
        fo.write("\n".join(L) + "\n")

    with open(os.path.join(build, "table_codes.tex"), "w") as fo:
        fo.write("\\begin{tabular}{S[table-format=2.0] S[table-format=-3.2] S[table-format=-1.2] "
                 "S[table-format=-1.2]}\n\\toprule\n"
                 "{Code} & {$T_k$ (\\si{mV})} & {DNL (LSB)} & {INL (LSB)} \\\\\n\\midrule\n")
        for k in range(1, NCODES):
            d = "%.2f" % r["dnl"][k - 1] if k <= NCODES - 2 else "{--}"
            fo.write("%d & %.2f & %s & %.2f \\\\\n" % (k, r["t"][k - 1] * 1e3, d, r["inl"][k - 1]))
        fo.write("\\bottomrule\n\\end{tabular}\n")

    if not sines:
        return
    with open(os.path.join(build, "table_sweep.tex"), "w") as fo:
        fo.write("\\begin{tabular}{S[table-format=3.1] S[table-format=3.0] S[table-format=2.2] S[table-format=2.2] "
                 "S[table-format=2.2] S[table-format=1.2] S[table-format=1.2] S[table-format=-2.1] S[table-format=2.1] "
                 "S[table-format=-2.1] S[table-format=-2.1] S[table-format=-2.1]}\n\\toprule\n"
                 "{$f_{in}$ (\\si{kHz})} & {Cycles} & {$A$ (LSB)} & {SINAD} & {SINAD$_{st}$} & {ENOB} & {ENOB$_{st}$} & "
                 "{THD} & {SFDR} & {H2} & {H3} & {H5} \\\\\n"
                 " & & & {(\\si{dB})} & {(\\si{dB})} & {(bits)} & {(bits)} & {(\\si{dB})} & {(\\si{dB})} & "
                 "{(\\si{dBc})} & {(\\si{dBc})} & {(\\si{dBc})} \\\\\n\\midrule\n")
        for s in sines:
            fo.write("%.1f & %d & %.2f & %.2f & %.2f & %.2f & %.2f & %.1f & %.1f & %s & %s & %s \\\\\n" % (
                s["freq"] / 1e3, s["cycles"], s["amp"], s["sinad"], s["sinad_static"], s["enob"], s["enob_static"],
                s["thd"], s["sfdr"], dbc_tex(s["harm"][2]["dbc"]), dbc_tex(s["harm"][3]["dbc"]),
                dbc_tex(s["harm"][5]["dbc"])))
        fo.write("\\bottomrule\n\\end{tabular}\n")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    args = sys.argv[1:]
    ref = None
    if "--ref" in args:  # static.json of another operating point, quoted in the report
        i = args.index("--ref")
        ref = os.path.abspath(args[i + 1])
        del args[i:i + 2]
    char = os.path.abspath(args[0])
    build = os.path.abspath(args[1]) if len(args) > 1 else os.path.join(char, "report")
    os.makedirs(os.path.join(build, "fig"), exist_ok=True)

    with open(os.path.join(char, "static.json")) as f:
        st = json.load(f)
    r = analyze_static(st)
    sines = []
    for p in glob.glob(os.path.join(char, "sine_*.json")):
        with open(p) as f:
            sines.append(analyze_sine(json.load(f), r))
    sines.sort(key=lambda s: s["freq"])
    fes = []
    for p in glob.glob(os.path.join(char, "sinefe_*.json")):
        with open(p) as f:
            fes.append(analyze_sine(json.load(f), r))
    fes.sort(key=lambda s: s["freq"])
    if not sines:  # Static only (the sine records are still running): the report leaves out the dynamic part
        print("No sine_*.json in", char, "- static report only")
    name = os.path.basename(char)
    meta = {"dir": name, "fclk": st["fclk"], "sim": name.split("_")[0],
            "corner": "mos_" + name.split("_mos_")[1].split("_")[0] if "_mos_" in name else "?", "static": st}
    if ref:
        with open(ref) as f:
            q = json.load(f)
        meta["ref"] = analyze_static(q) | {"vdd": q.get("vdd", 1.8)}
    meta["pdk"] = pdk_version()
    cap = unit_cap_cv()

    fig_cap(*cap, build)
    fig_transfer(r, build)
    fig_dnl_inl(r, build)
    for f in ("table_sweep.tex", "table_fe.tex", "results_fe.tex"):
        if os.path.exists(os.path.join(build, f)):
            os.remove(os.path.join(build, f))
    if sines:
        fig_sine_time(sines[0], build, "sine_time")
        fig_spectrum(sines[0], build, "spectrum_low")
        fig_spectrum(sines[-1], build, "spectrum_high")
        fig_sweep(sines, build)
    write_tex(build, meta, r, sines, cap)
    if fes:
        write_fe(build, sines, fes)

    summary = {
        "source": name, "fclk": st["fclk"], "pdk": meta["pdk"],
        "conditions": {k: st.get(k) for k in ("vdd", "vrefh", "vrefl", "vcm")},
        "static": {"weights": bit_weights(r).tolist(), "lsb_v": r["lsb"], "lsb_ideal_v": r["lsb_ideal"], "gain_err": r["gain_err"],
                   "offset_lsb": r["offset_lsb"], "t": r["t"].tolist(), "dnl": r["dnl"].tolist(),
                   "inl": r["inl"].tolist(), "resolution_v": r["resolution"]},
        "sines": [{k: s[k] for k in ("freq", "cycles", "n", "amp", "offset", "sinad", "sinad_static", "enob",
                                     "enob_static", "snr", "thd", "sfdr", "clip")} |
                  {"harm": {str(k): v for k, v in s["harm"].items()}, "codes": s["codes"].astype(int).tolist()}
                  for s in sines],
        "sines_frontend": [{k: s[k] for k in ("freq", "amp", "sinad", "enob", "thd")} |
                           {"harm": {str(k): v for k, v in s["harm"].items()}} for s in fes],
        "unit_cap": {"v": cap[0].tolist(), "c_f": cap[1].tolist()},
    }
    with open(os.path.join(build, "sim_summary.json"), "w") as fo:
        json.dump(summary, fo, indent=1, default=float)

    for f in ("report.tex", "discussion.tex", "references.tex"):
        shutil.copy(os.path.join(REPORT_DIR, f), build)
    subprocess.run(["latexmk", "-pdf", "-interaction=nonstopmode", "-halt-on-error", "report.tex"],
                   cwd=build, check=True, stdout=subprocess.DEVNULL)
    print(os.path.join(build, "report.pdf"))


if __name__ == "__main__":
    main()

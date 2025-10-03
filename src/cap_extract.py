import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import sys, os

if __name__ == "__main__":
    voltages = np.linspace(0.0, 1.8, 10)
    voltages_str = ["{:.2f}".format(v) for v in voltages]
    caps = None
    cap_avg = None
    cap_std = None

    if len(sys.argv) <= 3:
        print("USAGE: {} run_dir template spice_cmd")
        sys.exit(0)
    
    run_dir = sys.argv[1]
    template = sys.argv[2]
    sim_cmd = sys.argv[3]

    # Read original content
    with open(template, "r") as f:
        content = f.read()

    for i in range(len(voltages)):
        volt = voltages_str[i]
        volt_str = voltages_str[i]

        # Modify the content
        new_content = content.replace("{vi}", volt_str)
        new_content = new_content.replace("cap_linearity.xyce", "cap_linearity.xyce."+volt_str)
        new_content = new_content.replace("mos_tt", "mos_tt")
        new_content = new_content.replace("{PDK_ROOT}", os.environ['PDK_ROOT'])
        new_content = new_content.replace("{PDK}", os.environ['PDK'])

        netlist_path = "{}/cap_linearity.xyce.{}.sp".format(run_dir, volt_str)

        # Overwrite with modified content
        with open(netlist_path, "w") as f:
            f.write(new_content)

        # Do the simulation
        cmd = "cd {} && {} {}".format(run_dir, sim_cmd, netlist_path)
        print("Running: ", cmd)
        os.system(cmd)

        # Load simulation data
        #data = np.loadtxt("outputs/cap_linearity.xyce.csv", skiprows=1)
        df = pd.read_csv("{}/cap_linearity.xyce.{}.csv".format(run_dir, volt_str))

        freq = df["FREQ"].to_numpy()
        V = df["Re(V(VPLUS))"].to_numpy() + 1j*df["Im(V(VPLUS))"].to_numpy()
        I = df["Re(I(VPORT))"].to_numpy() + 1j*df["Im(I(VPORT))"].to_numpy()

        if caps is None:
            caps = np.zeros((len(freq),len(voltages)))
            cap_avg = np.zeros((len(freq),))

        Z = V / I
        Zi = np.imag(Z)
        C = 1/(2*np.pi*freq*Zi)

        caps[:, i] = C[:]
    
    cap_avg = np.mean(caps, axis=1)
    cap_std = np.sqrt(np.var(caps, axis=1))
    
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(6, 5), sharex=True)

    ax1.plot(freq, cap_avg, color="blue")
    ax1.set_ylabel("Avg Capacitance (F)")
    ax1.set_xlabel("Freq (Hz)")
    ax1.set_xscale('log')
    ax1.grid(True)

    ax2.plot(freq, cap_std, color="blue")
    ax2.set_ylabel("Dev Capacitance (F)")
    ax2.set_xlabel("Freq (Hz)")
    ax2.set_xscale('log')
    ax2.grid(True)
    
    fig2, (ax3) = plt.subplots(1, 1, figsize=(6, 5), sharex=True)

    ax3.errorbar(freq,
             cap_avg,
             yerr=cap_std,
             fmt='o-',           # marker and line style
             ecolor='gray',      # error bar color
             elinewidth=1,       # error bar line width
             capsize=3,          # cap length
             label="Average ± 1σ")
    ax3.set_xscale('log')
    ax3.set_ylabel("Dev Capacitance (F)")
    ax3.set_xlabel("Freq (Hz)")

    target = 100e6

    idx_candidates = np.where(freq >= target)[0]
    if len(idx_candidates) > 0:
        idx = idx_candidates[0]
        fig3, (ax4) = plt.subplots(1, 1, figsize=(6, 5), sharex=True)

        ax4.plot(voltages, caps[idx, :], color="blue")
        ax4.set_ylabel("Capacitance (F)")
        ax4.set_xlabel("Bias Voltage (V)")
        ax4.set_title('With Freq={}'.format(freq[idx]))
        ax4.grid(True)

    #print("FREQ:", freq)
    #print("C_f:", cap_avg)
    #print("C_af:", cap_std)

    plt.show()

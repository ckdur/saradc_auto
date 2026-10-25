import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import sys, os

if __name__ == "__main__":
    freqs = np.array([50000000, 200000000])
    freqs_str = ["{}".format(v) for v in freqs]
    N=128
    nbits = int(os.environ.get("NBITS", 5))  # settings.mk
    k=((N/2)-1)
    

    if len(sys.argv) <= 3:
        print("USAGE: {} run_dir template spice_cmd")
        sys.exit(0)
    
    run_dir = sys.argv[1]
    template = sys.argv[2]
    sim_cmd = sys.argv[3]

    # Read original content
    with open(template, "r") as f:
        content = f.read()

    for i in range(len(freqs)):
        fclk = freqs[i]
        freq_str = freqs_str[i]

        tclk = (1/fclk)
        tstart = tclk * 5.5         # The start time, when the go signal is high
        tcv = (tclk*(nbits+1))      # The sampling time
        fin = (fclk / 100 * k / N)  # The frequency of the input signal

        # Modify the content
        new_content = content.replace("{vi}", freq_str)
        new_content = new_content.replace("{DEF_FCLK}", freq_str)
        new_content = new_content.replace("saradc_tb.xyce", "saradc_tb.xyce."+freq_str)
        new_content = new_content.replace("mos_tt", "mos_tt")
        new_content = new_content.replace("{PDK_ROOT}", os.environ['PDK_ROOT'])
        new_content = new_content.replace("{PDK}", os.environ['PDK'])

        netlist_path = "{}/saradc_tb.xyce.{}.sp".format(run_dir, freq_str)
        data_path = "{}/saradc_tb.xyce.{}.csv".format(run_dir, freq_str)

        # Overwrite with modified content
        with open(netlist_path, "w") as f:
            f.write(new_content)

        # Do the simulation
        if not os.path.isfile(data_path):
            cmd = "cd {} && {} {}".format(run_dir, sim_cmd, netlist_path)
            print("Running: ", cmd)
            os.system(cmd)

        # Load simulation data
        df = pd.read_csv("{}/saradc_tb.xyce.{}.csv".format(run_dir, freq_str))

        t = df["TIME"].to_numpy()
        Vi = df["V(VIP)"].to_numpy() - df["V(VIN)"].to_numpy()
        Vo = df["V(VOUT)"].to_numpy()

        # Convert the simulation time into a constant time for fft
        fs = 1/tcv
        print(f"fs = {fs}, ts = {tcv}")
        t_unif = np.linspace(t[0], t[-1], int(fs * (t[-1]-t[0])))
        Vi_unif = np.interp(t_unif, t, Vi)
        Vo_unif = np.interp(t_unif, t, Vo)
        print(Vi_unif.shape)

        nsamples = len(Vi_unif)

        Vi_x = np.fft.fft(Vi_unif)
        Vo_x = np.fft.fft(Vo_unif)

        disp_freqs = np.fft.fftfreq(nsamples, 1/fs)
        idx = np.arange(nsamples//2)

        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(6, 5), sharex=True)

        ax1.plot(disp_freqs[idx], 2.0/nsamples * np.abs(Vo_x[idx]))
        ax2.plot(disp_freqs[idx], 2.0/nsamples * np.angle(Vo_x[idx]))
        ax1.set_title("Spectrum")
        ax2.set_xlabel("Frequency [Hz]")
        ax1.set_ylabel("Magnitude")
        ax2.set_ylabel("Phase")

    plt.show()

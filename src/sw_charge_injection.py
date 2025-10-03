import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import sys, os
import itertools

if __name__ == "__main__":
    voltages = np.linspace(0.0, 1.8, 10)
    voltages_str = ["{:.2f}".format(v) for v in voltages]
    delays = np.linspace(10, 20, 6)
    delays_str = ["{:.2f}p".format(v) for v in delays]
    freq = 100000000
    tperiod = 1/freq
    t1 = 0.25*tperiod
    t2 = 0.75*tperiod

    nvoltages = len(voltages)
    ndelays = len(delays)

    SARADC_SW_ideal = np.zeros((nvoltages, ndelays))
    SARADC_SW_iter = np.zeros((nvoltages, ndelays))

    SARADC_SWDUM_ideal = np.zeros((nvoltages, ndelays))
    SARADC_SWDUM_iter = np.zeros((nvoltages, ndelays))

    sw_classic_ideal = np.zeros((nvoltages, ndelays))
    sw_classic_iter = np.zeros((nvoltages, ndelays))

    pg_classic_ideal = np.zeros((nvoltages, ndelays))
    pg_classic_iter1 = np.zeros((nvoltages, ndelays))
    pg_classic_iter2 = np.zeros((nvoltages, ndelays))

    name_gen = lambda v, d: "{}_{}".format(v, d)

    if len(sys.argv) <= 3:
        print("USAGE: {} run_dir template spice_cmd")
        sys.exit(1)
    
    run_dir = sys.argv[1]
    template = sys.argv[2]
    sim_cmd = sys.argv[3]

    # Read original content
    with open(template, "r") as f:
        content = f.read()

    for idx_volt, idx_delay in itertools.product(range(nvoltages), range(ndelays)):
        volt = voltages_str[idx_volt]
        volt_str = voltages_str[idx_volt]
        delay = delays_str[idx_delay]
        delay_str = delays_str[idx_delay]
        name = name_gen(volt_str, delay_str)

        # Modify the content
        new_content = content.replace("{vdc}", volt_str)
        new_content = new_content.replace("{delay}", delay_str)
        new_content = new_content.replace("sw_charge_injection.xyce", "sw_charge_injection.xyce."+name)
        new_content = new_content.replace("mos_tt", "mos_tt")
        new_content = new_content.replace("{PDK_ROOT}", os.environ['PDK_ROOT'])
        new_content = new_content.replace("{PDK}", os.environ['PDK'])

        netlist_path = "{}/sw_charge_injection.xyce.{}.sp".format(run_dir, name)
        data_path = "{}/sw_charge_injection.xyce.{}.csv".format(run_dir, name)

        # Overwrite with modified content
        with open(netlist_path, "w") as f:
            f.write(new_content)

        # Do the simulation
        if not os.path.isfile(data_path):
            cmd = "cd {} && {} {}".format(run_dir, sim_cmd, netlist_path)
            print("Running: ", cmd)
            os.system(cmd)

        # Load simulation data
        df = pd.read_csv(data_path)

        t = df["TIME"].to_numpy() * 1e-9
        CS = df["V(CS)"].to_numpy()
        NCS = df["V(NCS)"].to_numpy()
        VOv4 = df["V(VOV4)"].to_numpy()
        VOv5 = df["V(VOV5)"].to_numpy()
        VOnd = df["V(VOND)"].to_numpy()
        VOnd2 = df["V(VOND2)"].to_numpy()
        VOnd3 = df["V(VOND3)"].to_numpy()
        VOclassicideal = df["V(VOCLASSICIDEAL)"].to_numpy()
        VOclassic2 = df["V(VOCLASSIC2)"].to_numpy()
        VO1videal = df["V(VO1VIDEAL)"].to_numpy()
        VO2videal = df["V(VO2VIDEAL)"].to_numpy()

        # If fails here, is because the time is not right
        ti1 = np.where(t >= t1)[0][0]
        ti2 = np.where(t >= t2)[0][0]

        # Get the difference
        SARADC_SW_ideal[idx_volt, idx_delay] = np.abs(VO2videal[ti2] - VO2videal[ti1])
        SARADC_SW_iter[idx_volt, idx_delay] = np.abs(VOv4[ti2] - VOv4[ti1])

        SARADC_SWDUM_ideal[idx_volt, idx_delay] = np.abs(VO1videal[ti2] - VO1videal[ti1])
        SARADC_SWDUM_iter[idx_volt, idx_delay] = np.abs(VOv5[ti2] - VOv5[ti1])

        sw_classic_ideal[idx_volt, idx_delay] = np.abs(VOclassicideal[ti2] - VOclassicideal[ti1])
        sw_classic_iter[idx_volt, idx_delay] = np.abs(VOclassic2[ti2] - VOclassic2[ti1])

        pg_classic_ideal[idx_volt, idx_delay] = np.abs(VOnd3[ti2] - VOnd3[ti1])
        pg_classic_iter1[idx_volt, idx_delay] = np.abs(VOnd2[ti2] - VOnd2[ti1])
        pg_classic_iter2[idx_volt, idx_delay] = np.abs(VOnd[ti2] - VOnd[ti1])

        if 0:
            plt.figure()
            plt.plot(t, VO2videal)
            plt.show()
            print(ti1, t[ti1], t1)
            print(ti2, t[ti2], t2)

    fig, (ax1, ax2, ax3, ax4) = plt.subplots(4, 1, figsize=(10, 8), sharex=True)
    fig2, (ax5, ax6, ax7, ax8) = plt.subplots(4, 1, figsize=(10, 8), sharex=True)
    for idx_delay in range(ndelays):
        delay = delays_str[idx_delay]
        ax1.plot(voltages, SARADC_SW_iter[:, idx_delay], label="$delay$={:.2} ps".format(delay))
        ax2.plot(voltages, SARADC_SWDUM_iter[:, idx_delay], label="$delay$={:.2} ps".format(delay))
        ax3.plot(voltages, sw_classic_iter[:, idx_delay], label="$delay$={:.2} ps".format(delay))
        ax4.plot(voltages, pg_classic_iter1[:, idx_delay], label="$delay$={:.2} ps".format(delay))
        ax5.plot(voltages, SARADC_SW_ideal[:, idx_delay], label="$delay$={:.2} ps".format(delay))
        ax6.plot(voltages, SARADC_SWDUM_ideal[:, idx_delay], label="$delay$={:.2} ps".format(delay))
        ax7.plot(voltages, sw_classic_ideal[:, idx_delay], label="$delay$={:.2} ps".format(delay))
        ax8.plot(voltages, pg_classic_ideal[:, idx_delay], label="$delay$={:.2} ps".format(delay))

    ax1.set_ylabel("Delta ON-OFF (V)")
    ax1.set_xlabel("Voltage (V)")
    ax1.set_title("SARADC 4T switch (Non-ideal)")
    ax1.legend(fontsize=8)

    ax2.set_ylabel("Delta ON-OFF (V)")
    ax2.set_xlabel("Voltage (V)")
    ax2.set_title("SARADC 2T switch (Non-ideal)")
    ax2.legend(fontsize=8)

    ax3.set_ylabel("Delta ON-OFF (V)")
    ax3.set_xlabel("Voltage (V)")
    ax3.set_title("Ideal switch (Non-ideal)")
    ax3.legend(fontsize=8)

    ax4.set_ylabel("Delta ON-OFF (V)")
    ax4.set_xlabel("Voltage (V)")
    ax4.set_title("Passgate switch (Non-ideal)")
    ax4.legend(fontsize=8)

    ax5.set_ylabel("Delta ON-OFF (V)")
    ax5.set_xlabel("Voltage (V)")
    ax5.set_title("SARADC 4T switch (Non-ideal)")
    ax5.legend(fontsize=8)

    ax6.set_ylabel("Delta ON-OFF (V)")
    ax6.set_xlabel("Voltage (V)")
    ax6.set_title("SARADC 2T switch (Non-ideal)")
    ax6.legend(fontsize=8)

    ax7.set_ylabel("Delta ON-OFF (V)")
    ax7.set_xlabel("Voltage (V)")
    ax7.set_title("Ideal switch (Non-ideal)")
    ax7.legend(fontsize=8)

    ax8.set_ylabel("Delta ON-OFF (V)")
    ax8.set_xlabel("Voltage (V)")
    ax8.set_title("Passgate switch (Non-ideal)")
    ax8.legend(fontsize=8)

    plt.show()

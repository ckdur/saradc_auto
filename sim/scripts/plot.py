# Remember to install the following:
# python3 -m pip install numpy scipy pandas matplotlib

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy import interpolate
import os, sys

if __name__=="__main__":
  if len(sys.argv) < 2:
    print("USAGE: {} file.csv".format(sys.argv[0]))
    sys.exit(1)
  
  filename = sys.argv[1]
  basename = os.path.basename(filename)

  colnames_single = ["vin", "vip", "result[0]", "result[1]", "result[2]", "result[3]", "result[4]", "go", "sample", "valid", "vout"]

  colnames = []
  for sig in colnames_single:
    colnames.append("t" + sig)  # time column
    colnames.append(sig)        # value column

  df = pd.read_csv(filename, delim_whitespace=True, names=colnames)

  print(df.head())  # sanity check

  # Plot
  fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(6, 8), sharex=True)

  ax1.plot(df["tvin"], df["vin"], label="vin", color="blue")
  ax1.set_ylabel("Vin (V)")
  ax1.legend()
  ax1.grid(True)

  ax2.plot(df["tvout"], df["vout"], label="vout", color="red")
  ax2.set_xlabel("Time (s)")
  ax2.set_ylabel("Vout (V)")
  ax2.legend()
  ax2.grid(True)

  fig.savefig('{}.vin_vout.pdf'.format(basename),bbox_inches='tight')


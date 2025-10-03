# Usage: gnuplot -c plot.vin_vout.gnu input.csv output.pdf "My Title"

# Get command-line arguments
csvfile = ARG1      # first argument: input CSV
pdffile = ARG2      # second argument: output PDF
plottitle = ARG3    # third argument: figure title

set terminal pdfcairo size 8,6 enhanced font 'Helvetica,10'
set output pdffile

set multiplot layout 3,1 title "Vin and Vout" font ",12"

set datafile separator ","

# --- First subplot: Vin ---
set xlabel "time (s)"
set ylabel "Vin (V)"
plot csvfile skip 50 using 1:2 with lines lw 2 title 'Vin'

# --- First subplot: Vin ---
set xlabel "time (s)"
set ylabel "Vip (V)"
plot csvfile skip 50 using 1:3 with lines lw 2 title 'Vip'

# --- Second subplot: Vout ---
set xlabel "time (s)"
set ylabel "Vout (V)"
plot csvfile skip 50 using 1:12 with lines lw 2 title 'Vout'

unset multiplot

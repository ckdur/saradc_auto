# Usage: gnuplot -c plot.vin_vout.gnu input.csv output.pdf "My Title"

# Get command-line arguments
csvfile = ARG1      # first argument: input CSV
pdffile = ARG2      # second argument: output PDF
plottitle = ARG3    # third argument: figure title

set terminal pdfcairo size 8,8 enhanced font 'Helvetica,10'
set output pdffile

set multiplot layout 8,1 title "Results" font ",12"

set xlabel "time (s)"
set ylabel "Result 0 (V)"
plot csvfile using 5:6 with lines lw 2 title 'result[0]'

set xlabel "time (s)"
set ylabel "Result 1 (V)"
plot csvfile using 7:8 with lines lw 2 title 'result[1]'

set xlabel "time (s)"
set ylabel "Result 2 (V)"
plot csvfile using 9:10 with lines lw 2 title 'result[2]'

set xlabel "time (s)"
set ylabel "Result 3 (V)"
plot csvfile using 11:12 with lines lw 2 title 'result[3]'

set xlabel "time (s)"
set ylabel "Result 4 (V)"
plot csvfile using 13:14 with lines lw 2 title 'result[4]'

set xlabel "time (s)"
set ylabel "Go (V)"
plot csvfile using 15:16 with lines lw 2 title 'go'

set xlabel "time (s)"
set ylabel "Sample (V)"
plot csvfile using 17:18 with lines lw 2 title 'sample'

set xlabel "time (s)"
set ylabel "Valid (V)"
plot csvfile using 19:20 with lines lw 2 title 'valid'

set xlabel "time (s)"
set ylabel "Clock (V)"
plot csvfile using 23:24 with lines lw 2 title 'clk'

unset multiplot

"""Device capacitance of one CDAC unit (6 SARADC_CELL_INVX16_ASCAP) seen from VSH.
FL floating (as in the ADC, DC path only through 1 Tohm) or FL AC-grounded.
Usage: python3 unitcap.py [subckt file] [subckt name]"""
import os
import re
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
PDK = os.path.join(os.environ.get('PDK_ROOT', '/opt/ext/OpenPDKs'), 'ihp-sg13g2')
CELL = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'cells', 'SARADC_CELL_INVX16_ASCAP.ckt')
NAME = sys.argv[2] if len(sys.argv) > 2 else 'SARADC_CELL_INVX16_ASCAP'
F = 1e6
VDD = 1.2
WORK = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'unitcap')
os.makedirs(WORK, exist_ok=True)

deck = f"""* unit cap
.options tnom=25 temp=27
.lib {PDK}/libs.tech/ngspice/models/cornerMOSlv.lib mos_tt
.inc {CELL}
.param vsh=0.6
vavdd avdd 0 {VDD}
vvss vss 0 0
vsh vsh 0 dc {{vsh}} ac 1
* floating FL
rfl1 fl1 vsh 1e12
xc1 vsh fl1 fl1 fl1 avdd vss {NAME}
xc2 vsh fl1 fl1 fl1 avdd vss {NAME}
xc3 vsh fl1 fl1 fl1 avdd vss {NAME}
xc4 vsh fl1 fl1 fl1 avdd vss {NAME}
xc5 vsh fl1 fl1 fl1 avdd vss {NAME}
xc6 vsh fl1 fl1 fl1 avdd vss {NAME}
.control
set wr_singlescale
foreach v 0.4 0.5 0.6 0.7 0.8
  alterparam vsh=$v
  reset
  ac lin 1 {F} {F}
  let c = -imag(i(vsh))/(2*3.14159265*{F})
  echo "FLOAT $v" $&c
end
.endc
.end
"""
# Same with FL AC grounded at a DC level (0.6 V)
deck_gnd = deck.replace('rfl1 fl1 vsh 1e12', 'vfl fl1 0 0.6').replace('FLOAT', 'FLGND')

# The PDK .spiceinit loads the OSDI models from the working directory
with open(os.path.join(PDK, 'libs.tech', 'ngspice', '.spiceinit')) as fi:
    open(os.path.join(WORK, '.spiceinit'), 'w').write(fi.read())
for tag, d in (('float', deck), ('gnd', deck_gnd)):
    path = os.path.join(WORK, f'unitcap_{tag}.sp')
    open(path, 'w').write(d)
    out = subprocess.run(['ngspice', '-b', path], cwd=WORK, capture_output=True, text=True).stdout
    for m in re.finditer(r'(FLOAT|FLGND) (\S+)\s+(\S+)', out):
        print(f'{m.group(1)} VSH={m.group(2)} V: C = {float(m.group(3)) * 1e15:.2f} fF')

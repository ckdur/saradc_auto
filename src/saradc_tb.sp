* SARADC testbench

.options tnom=25 temp=25 gminsteps=0 warn=1 klu=1 acct=1 method=gear trtol=1

* Include the models
* TODO: make it depending on PDK_ROOT

.lib {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/cornerMOSlv.lib mos_tt
.lib {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/cornerMOShv.lib mos_tt
.lib {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/cornerCAP.lib cap_typ
.lib {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/cornerRES.lib res_typ
.lib {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/cornerHBT.lib hbt_typ
.inc {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/diodes.lib

* SARADC cells
.inc ../cells/sg13g2f.ckt
.inc ../cells/SARADC_CELL_INVX0_ASSW.ckt
.inc ../cells/SARADC_CELL_INVX16_ASCAP.ckt
.inc ../cells/SARADC_FILL1_NOPOWER.cdl
.inc ../cells/SARADC_FILL1.cdl
.inc ../cells/SARADC_FILLTIE2.cdl

* Include the actual netlist
* NOTE: Relative to this file
.inc ../pnr/outputs/SARADC.cdl

.inc saradc_tb_body.sp

* The actual implementation
xtest vdd clk go result_0 result_1 result_2 result_3
+ result_4 rst sample valid dvdd vin vip vrefh vrefl gnd SARADC

Rresult_5 result_5 gnd 1k
Rresult_6 result_6 gnd 1k
Rresult_7 result_7 gnd 1k

.PROBE
+    V(xtest.analog/VOUTL)
+    V(xtest.analog/VOUTH)
+    V(xtest.analog/CCMP)
+    V(xtest.analog/CCMPB)
+    V(xtest.analog/_unconnected_0)
+    V(xtest.CMPO)

.control
  run
  plot V(vin) V(vip) V(vout)
  plot V(go) V(clk) V(valid) V(sample)
  plot V(xtest.analog/VOUTL) V(xtest.analog/VOUTH) V(xtest.analog/CCMP) V(xtest.analog/CCMPB) V(xtest.CMPO)
  *write SARADC.raw
  wrdata saradc_tb.csv V(vin) V(vip) V(result_0) V(result_1) V(result_2) V(result_3) V(result_4) V(go) V(sample) V(valid) V(vout) V(clk)
  wrdata saradc_tb.debug.csv V(xtest.analog/VOUTL) V(xtest.analog/VOUTH) V(xtest.analog/CCMP) V(xtest.analog/CCMPB) V(xtest.CMPO)
  quit
.endc

.end

* SARADC testbench

.options tnom=25 temp=25 gminsteps=0 warn=1 klu=1 acct=1 method=gear trtol=1

* Include the models
* TODO: These variables doesnt work (obviously), but seriously, the simulators should have a way
*.param PDK="ihp-sg13g2"
*.param PDK_ROOT="/opt/ext/OpenPDKs"

.lib {PDK_ROOT}/{PDK}/libs.tech/xyce/models/cornerMOSlv.lib mos_tt
.lib {PDK_ROOT}/{PDK}/libs.tech/xyce/models/cornerMOShv.lib mos_tt
.lib {PDK_ROOT}/{PDK}/libs.tech/xyce/models/cornerCAP.lib cap_typ
.lib {PDK_ROOT}/{PDK}/libs.tech/xyce/models/cornerRES.lib res_typ
.lib {PDK_ROOT}/{PDK}/libs.tech/xyce/models/cornerHBT.lib hbt_typ
.inc {PDK_ROOT}/{PDK}/libs.tech/xyce/models/diodes.lib

* SARADC cells
.inc sg13g2f.ckt
.inc SARADC_CELL_INVX0_ASSW.ckt
.inc SARADC_CELL_INVX16_ASCAP.ckt
.inc SARADC_FILL1_NOPOWER.xyce.ckt
.inc SARADC_FILL1.cdl
.inc SARADC_FILLTIE2.cdl

* Include the actual netlist
* NOTE: Relative to this file
.inc SARADC.xyce.ckt

.PARAM DEF_CLK=10000000
.PARAM fclk={DEF_FCLK}
.inc saradc_tb_body.sp

* The actual implementation
xtest vdd clk go result_0 result_1 result_2 result_3
+ result_4 rst sample valid dvdd vin vip vrefh vrefl gnd SARADC

Rresult_5 result_5 gnd 1k
Rresult_6 result_6 gnd 1k
Rresult_7 result_7 gnd 1k

vgnd gnd 0 DC 0

.PROBE
+    V(xtest.analog/VOUTL)
+    V(xtest.analog/VOUTH)
+    V(xtest.analog/CCMP)
+    V(xtest.analog/CCMPB)
+    V(xtest.analog/_unconnected_0)
+    V(xtest.CMPO)

.print tran format=csv file=saradc_tb.xyce.csv V(vin) V(vip) V(result_0) V(result_1) V(result_2) V(result_3) V(result_4) V(go) V(sample) V(valid) V(vout) V(clk) V(result_5) V(result_6) V(result_7)

.print tran format=csv file=saradc_tb.xyce.debug.csv V(xtest:analog/VOUTL) V(xtest:analog/VOUTH) V(xtest:analog/CCMP) V(xtest:analog/CCMPB) V(xtest:CMPO)

.end

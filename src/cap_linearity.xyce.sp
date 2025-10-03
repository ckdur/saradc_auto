* CAP linearity test

.options tnom=25 temp=25 gminsteps=0 warn=1 klu=1 acct=1 method=gear trtol=1

* Include the models
* TODO: make it depending on PDK_ROOT

.lib {PDK_ROOT}/{PDK}/libs.tech/xyce/models/cornerMOSlv.lib mos_tt
.lib {PDK_ROOT}/{PDK}/libs.tech/xyce/models/cornerMOShv.lib mos_tt
.lib {PDK_ROOT}/{PDK}/libs.tech/xyce/models/cornerCAP.lib cap_typ
.lib {PDK_ROOT}/{PDK}/libs.tech/xyce/models/cornerRES.lib res_typ
.lib {PDK_ROOT}/{PDK}/libs.tech/xyce/models/cornerHBT.lib hbt_typ
.inc {PDK_ROOT}/{PDK}/libs.tech/xyce/models/diodes.lib

.inc SARADC_CELL_INVX16_ASCAP.ckt

.PARAM supply=1.8
.PARAM vi=1.2
.PARAM f=100M


* Supply
Vsupply vdd vss DC {supply}
Vgnd vss 0 DC 0

* DUT
*.SUBCKT SARADC_CELL_INVX16_ASCAP i vdd vss zn vnw vpw
xdut vplus vminus vminus vminus vdd vss SARADC_CELL_INVX16_ASCAP
*Cdut vplus vss 15f

* PORT definition
Rport vplus vplusp 50
Vport vplusp vpluspp AC 1
Vbias vpluspp vss DC {vi}

.AC dec 10 1e6 1e9

.print ac format=csv file=cap_linearity.xyce.csv V(vplus) I(Vport)

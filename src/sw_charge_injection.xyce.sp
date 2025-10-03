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
.inc SARADC_CELL_INVX0_ASSW.ckt
.inc SARADC_SW.cdl
*.SUBCKT SARADC_SW S SB VDD VSS Z1 Z2
.inc SARADC_SWDUM.cdl
*.SUBCKT SARADC_SWDUM S SB VDD VSS Z1 Z2
.inc sw_classic.sp
*.SUBCKT sw_classic S SB VDD VSS Z1 Z2
*.SUBCKT pg_classic S SB VDD VSS Z1 Z2
.inc sg13g2f.ckt
*.SUBCKT sg13g2f_INVD0 i vdd vss zn
*.SUBCKT sg13g2f_INVD1 i z vss vdd
.inc sw_load.sp

.PARAM supply=1.8
.PARAM Csh=10f
.PARAM Rin=0
.PARAM fclk=100M
.PARAM tclk=1/fclk
.PARAM vdc=0
.PARAM stopsim=2*tclk
.PARAM trise=4e-10
.PARAM tfall=4e-10

* Supply
Vsupply VDD VSS DC {supply}
Vgnd VSS 0 DC 0
VCS3 CS3 VSS PULSE 0 {supply} 0 {trise} {tfall} {1/(2*fclk)} {1/fclk}
VNCS3 NCS3 VSS PULSE {supply} 0 {delay} {trise} {tfall} {1/(2*fclk)} {1/fclk}

* DUT
XLATCH1_0 NCS VDD VSS CS sg13g2f_INVD0
XLATCH1_1 CS VDD VSS NCS sg13g2f_INVD0
XLATCH2_0 CS2 VDD VSS NCS2 sg13g2f_INVD0
XLATCH2_1 NCS2 VDD VSS CS2 sg13g2f_INVD0

XBUF3_N NCS3 VDD VSS NCS sg13g2f_BUFFD1
XBUF3_P CS3 VDD VSS CS2 sg13g2f_BUFFD1

XDUT3 CS3 NCS3 VDD VSS VI2videal VO2videal SARADC_SW
XDUT2 CS2 NCS2 VDD VSS VIv4 VOv4 SARADC_SW
XDUT CS NCS VDD VSS VIv2 VOv2 SARADC_SW

XDUM3_0 CS3 NCS3 VDD VSS VI1videal VO1videal SARADC_SWDUM
XDUM3_1 CS3 NCS3 VDD VSS VI1videal VO1videal SARADC_SWDUM
XDUM2_0 CS2 NCS2 VDD VSS VIv5 VOv5 SARADC_SWDUM
XDUM2_1 CS2 NCS2 VDD VSS VIv5 VOv5 SARADC_SWDUM
XDUM_0 CS NCS VDD VSS VIv1 VOv1 SARADC_SWDUM
XDUM_1 CS NCS VDD VSS VIv1 VOv1 SARADC_SWDUM

XIDL3 CS3 NCS3 VDD VSS VIclassicideal VOclassicideal sw_classic
XIDL2 CS2 NCS2 VDD VSS VIclassic2 VOclassic2 sw_classic
XIDL CS NCS VDD VSS VIclassic VOclassic sw_classic

XPG3 CS3 NCS3 VDD VSS VInd3 VOnd3 pg_classic
XPG2 CS2 NCS2 VDD VSS VInd2 VOnd2 pg_classic
XPG CS NCS VDD VSS VInd VOnd pg_classic

CLOAD_VOv1 VOv1 VSS {Csh}
CLOAD_VOv2 VOv2 VSS {Csh}
CLOAD_VOv4 VOv4 VSS {Csh}
CLOAD_VOv5 VOv5 VSS {Csh}
CLOAD_VOnd3 VOnd3 VSS {Csh}
CLOAD_VOnd2 VOnd2 VSS {Csh}
CLOAD_VOnd VOnd VSS {Csh}
CLOAD_VO2videal VO2videal VSS {Csh}
CLOAD_VO1videal VO1videal VSS {Csh}
CLOAD_VOclassicideal VOclassicideal VSS {Csh}
CLOAD_VOclassic2 VOclassic2 VSS {Csh}
CLOAD_VOclassic VOclassic VSS {Csh}

CLOAD_VIv1 VIv1 VSS {Csh}
CLOAD_VIv2 VIv2 VSS {Csh}
CLOAD_VIv4 VIv4 VSS {Csh}
CLOAD_VIv5 VIv5 VSS {Csh}
CLOAD_VInd3 VInd3 VSS {Csh}
CLOAD_VInd2 VInd2 VSS {Csh}
CLOAD_VInd VInd VSS {Csh}
CLOAD_VI2videal VI2videal VSS {Csh}
CLOAD_VI1videal VI1videal VSS {Csh}
CLOAD_VIclassicideal VIclassicideal VSS {Csh}
CLOAD_VIclassic2 VIclassic2 VSS {Csh}
CLOAD_VIclassic VIclassic VSS {Csh}

XLOAD_VIv1 VIv1 VSS sw_load vdc={vdc} Rin={Rin}
XLOAD_VIv2 VIv2 VSS sw_load vdc={vdc} Rin={Rin}
XLOAD_VIv4 VIv4 VSS sw_load vdc={vdc} Rin={Rin}
XLOAD_VIv5 VIv5 VSS sw_load vdc={vdc} Rin={Rin}
XLOAD_VInd3 VInd3 VSS sw_load vdc={vdc} Rin={Rin}
XLOAD_VInd2 VInd2 VSS sw_load vdc={vdc} Rin={Rin}
XLOAD_VInd VInd VSS sw_load vdc={vdc} Rin={Rin}
XLOAD_VI2videal VI2videal VSS sw_load vdc={vdc} Rin={Rin}
XLOAD_VI1videal VI1videal VSS sw_load vdc={vdc} Rin={Rin}
XLOAD_VIclassicideal VIclassicideal VSS sw_load vdc={vdc} Rin={Rin}
XLOAD_VIclassic2 VIclassic2 VSS sw_load vdc={vdc} Rin={Rin}
XLOAD_VIclassic VIclassic VSS sw_load vdc={vdc} Rin={Rin}

.TRAN 1u {stopsim} uic

.print tran format=csv file=sw_charge_injection.xyce.csv V(CS) V(NCS) V(CS2) V(NCS2) V(CS3) V(NCS3) V(VOv4) V(VOv5) V(VOnd) V(VOnd2) V(VOnd3) V(VOclassicideal) V(VOclassic2) V(VO1videal) V(VO2videal)

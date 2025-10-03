* SARADC testbench

.TEMP 25
.OPTION
+    ARTIST=2
+    INGOLD=2
+    PARHIER=LOCAL
+    PSF=2
+    PROBE

* Include the models
* TODO: make it depending on PDK_ROOT
.lib {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/cornerMOSlv.lib mos_tt
.lib {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/cornerMOShv.lib mos_tt
.lib {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/cornerCAP.lib cap_typ
.lib {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/cornerRES.lib res_typ
.lib {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/cornerHBT.lib hbt_typ
.include {PDK_ROOT}/{PDK}/libs.tech/ngspice/models/diodes.lib

* Include the actual netlist
* NOTE: The design needs to pass LVS for this to work
.inc ../pnr/outputs/saradc.cdl

.inc saradc_tb_body.sp

* The actual implementation
* NOTE: It changes A LOT if the layout changes. Be careful
* last version was:
* .SUBCKT SARADC i|z z zn z$1 AVDD|vdd i|z$1 z$2 VSS|vss z$3 i|z$2 z$4 VDD|vdd
* + d|zn a2|zn a1|z zn$1 z$5 a1|z$1 a1|z$2 a1|z$3 a1|b|i|q d|z b|zn a2|a3|zn
* + a1|b|i|q$1 a2|z a1|a2|a3|z GO|a2 a2|zn$1 d|zn$1 a1|z$4 a2 VIP VIN z$6 d|z$1
* + cp|z result_0|i|q d|zn$2 VREFH a2$1 z$7 z$8 z$9 d|zn$3 a2|z$1 a2|z$2 b|zn$1
* + RST|a1|b|i a2|zn$2 d|z$2 a1|z$5 b|zn$2 a1|z$6 a1|z$7 a1|b|i|q$2 z$10 d|zn$4
* + d|zn$5 z$11 a1|z$8 a2|d|zn a1|z$9 result_1|i|q z$12 z$13 b|q cp|z$1 i|z$3
* + a2|i|q z$14 z$15 z$16 z$17 d|z$3 z$18 zn$2 z$19 d|zn$6 b|zn$3 i|z$4
* + a1|b|i|q$3 a2|zn$3 a2|a3|z a2|zn$4 a1|z$10 z$20 a2|z$3 i|zn a2|zn$5 CLK|i
* + a1|i|q i|z$5 i|z|zn i|z$6 z$21 i|z$7 i|z$8 cp|z$2 d|zn$7 i|z$9 i|z$10 i|z$11
* + i|z|zn$1 i|z$12 i|zn$1 i|z$13 i|z$14 d|zn$8 i|zn$2 i|z$15 i|z|zn$2 i|z$16
* + i|z$17 i|z|zn$3 i|z$18 i|z$19 i|z$20 i|z$21 i|z$22 i|z$23 result_4|i|q
* + i|z|zn$4 i|z$24 a1|i|z|zn i|zn$3 i|z|zn$5 result_2|i|q i|z$25 i|z$26 i|z$27
* + i|z|zn$6 i|zn$4 i|z$28 i|z$29 i|z$30 i|zn$5 i|z$31 i|z$32 i|z$33 i|z$34
* + a2|z$4 i|z|zn$7 i|z$35 i|z$36 i|z$37 i|z$38 i|z$39 a1|z$11 VALID|a3|z a2|i|z
* + i|z$40 i|zn$6 i|zn$7 i|z$41 i|z$42 i|z|zn$8 a2|z$5 i|z$43 i|z$44 i|z$45
* + i|z$46 i|z$47 i|z$48 result_3|i|q a1|i|q$1 i|z$49 i|z$50 i|z$51 i|z$52
* + i|z$53 a1|c|i|zn i|z$54 z$22 i|z$55 z$23 i|z$56 i|zn$8 i|z$57 i|z$58 i|zn$9
* + SAMPLE|a1|i|z i|zn$10 i|z$59 i|z$60 i|z$61 a2|b|z i|z$62 i|z$63 a1|c|i|zn$1
* + i|z$64 i|z$65 z$24 z$25 i|z$66 i|z$67 i|zn$11 i|z$68 i|z$69 i|z$70 i|z|zn$9
* + i|z$71 i|z$72 i|z$73 i|z$74 i|z$75 b|i|q i|z$76 i|z$77 b|i|q$1 i|z$78 i|z$79
* + i|z$80 i|z$81 i|z$82 i|z$83 i|z$84 i|z$85 i|z$86 a1|z$12 i|z$87 i|z$88
* + i|zn$12 i|z$89 i|z$90 i|z$91 i|z$92 i|z$93 b|i|q$2 i|z$94 i|zn$13 i|z$95
* + i|z$96 b|zn$4 cp|i|z zn$3 i|z$97 i|z$98 i|z$99 z$26 i|z$100 i|z$101 b|i|q$3
* + VREFL i|z$102 i|z$103 i|z$104 i|z$105 i|z$106 i|z$107 i|z$108 i|z$109 a2|zn$6
* + i|z$110 a1|z$13 zn$4 i|z$111 i|z$112 i|z$113 i|z$114 d|zn$9 cp|z$3 d|zn$10
* + a2|z$6 b|zn$5 d|z$4 a2|z$7 b|zn$6 z$27 zn$5

xtest i|z z zn z$1 vdd i|z$1 z$2 gnd z$3 i|z$2 z$4 dvdd
+ d|zn a2|zn a1|z zn$1 z$5 a1|z$1 a1|z$2 a1|z$3 a1|b|i|q d|z b|zn a2|a3|zn
+ a1|b|i|q$1 a2|z a1|a2|a3|z go a2|zn$1 d|zn$1 a1|z$4 a2 vip vin z$6 d|z$1
+ cp|z result_0 d|zn$2 vrefh a2$1 z$7 z$8 z$9 d|zn$3 a2|z$1 a2|z$2 b|zn$1
+ rst a2|zn$2 d|z$2 a1|z$5 b|zn$2 a1|z$6 a1|z$7 a1|b|i|q$2 z$10 d|zn$4
+ d|zn$5 z$11 a1|z$8 a2|d|zn a1|z$9 result_1 z$12 z$13 b|q cp|z$1 i|z$3
+ a2|i|q z$14 z$15 z$16 z$17 d|z$3 z$18 zn$2 z$19 d|zn$6 b|zn$3 i|z$4
+ a1|b|i|q$3 a2|zn$3 a2|a3|z a2|zn$4 a1|z$10 z$20 a2|z$3 i|zn a2|zn$5 clk
+ a1|i|q i|z$5 i|z|zn i|z$6 z$21 i|z$7 i|z$8 cp|z$2 d|zn$7 i|z$9 i|z$10 i|z$11
+ i|z|zn$1 i|z$12 i|zn$1 i|z$13 i|z$14 d|zn$8 i|zn$2 i|z$15 i|z|zn$2 i|z$16
+ i|z$17 i|z|zn$3 i|z$18 i|z$19 i|z$20 i|z$21 i|z$22 i|z$23 result_4
+ i|z|zn$4 i|z$24 a1|i|z|zn i|zn$3 i|z|zn$5 result_2 i|z$25 i|z$26 i|z$27
+ i|z|zn$6 i|zn$4 i|z$28 i|z$29 i|z$30 i|zn$5 i|z$31 i|z$32 i|z$33 i|z$34
+ a2|z$4 i|z|zn$7 i|z$35 i|z$36 i|z$37 i|z$38 i|z$39 a1|z$11 valid a2|i|z
+ i|z$40 i|zn$6 i|zn$7 i|z$41 i|z$42 i|z|zn$8 a2|z$5 i|z$43 i|z$44 i|z$45
+ i|z$46 i|z$47 i|z$48 result_3 a1|i|q$1 i|z$49 i|z$50 i|z$51 i|z$52
+ i|z$53 a1|c|i|zn i|z$54 z$22 i|z$55 z$23 i|z$56 i|zn$8 i|z$57 i|z$58 i|zn$9
+ sample i|zn$10 i|z$59 i|z$60 i|z$61 a2|b|z i|z$62 i|z$63 a1|c|i|zn$1
+ i|z$64 i|z$65 z$24 z$25 i|z$66 i|z$67 i|zn$11 i|z$68 i|z$69 i|z$70 i|z|zn$9
+ i|z$71 i|z$72 i|z$73 i|z$74 i|z$75 b|i|q i|z$76 i|z$77 b|i|q$1 i|z$78 i|z$79
+ i|z$80 i|z$81 i|z$82 i|z$83 i|z$84 i|z$85 i|z$86 a1|z$12 i|z$87 i|z$88
+ i|zn$12 i|z$89 i|z$90 i|z$91 i|z$92 i|z$93 b|i|q$2 i|z$94 i|zn$13 i|z$95
+ i|z$96 b|zn$4 cp|i|z zn$3 i|z$97 i|z$98 i|z$99 z$26 i|z$100 i|z$101 b|i|q$3
+ vrefl i|z$102 i|z$103 i|z$104 i|z$105 i|z$106 i|z$107 i|z$108 i|z$109 a2|zn$6
+ i|z$110 a1|z$13 zn$4 i|z$111 i|z$112 i|z$113 i|z$114 d|zn$9 cp|z$3 d|zn$10
+ a2|z$6 b|zn$5 d|z$4 a2|z$7 b|zn$6 z$27 zn$5 SARADC

.control
  run
  plot V(vin) V(vip) V(vout)
  plot V(go) V(clk) V(valid) V(sample)
  write SARADC.raw
  wrdata saradc_tb_rcx.csv V(vin) V(vip) V(result_0) V(result_1) V(result_2) V(result_3) V(result_4) V(go) V(sample) V(valid) V(vout) V(clk)
  quit
.endc

.end

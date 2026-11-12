// Blackboxes of the ADC cells and of the ics55f cells the RTL instantiates (build_cells.py)

(* blackbox *)
module SARADC_FILLTIE2(vdd, vss);
    inout vdd, vss;
endmodule

(* blackbox *)
module SARADC_CELL_INVX16_ASCAP(vnw, vpw, vdd, vss, i, zn);
    input i;
    output zn;
    inout vnw, vpw, vdd, vss;
endmodule

(* blackbox *)
module SARADC_CELL_INVX0_ASSW(vnw, vpw, vdd, vss, i, zn);
    input i;
    output zn;
    inout vnw, vpw, vdd, vss;
endmodule

(* blackbox *)
module ics55f_INVD1(z, vdd, vss, i);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_INVD6(i, vdd, vss, zn);
    input i;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_INVD8(i, vdd, vss, zn);
    input i;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_BUFFD0(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_BUFFD2(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_BUFFD4(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_BUFFD8(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_BUFFD16(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_DEL4(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_ND2D2(a1, a2, vdd, vss, zn);
    input a1, a2;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_NR3D4(a1, a2, a3, vdd, vss, zn);
    input a1, a2, a3;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_AN2D4(a1, a2, vdd, vss, z);
    input a1, a2;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_OAI211D4(a1, a2, b, c, vdd, vss, zn);
    input a1, a2, b, c;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_TIEH(vdd, vss, z);
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module ics55f_TIEL(vdd, vss, zn);
    output zn;
    inout vdd, vss;
endmodule


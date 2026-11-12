// Blackboxes of the ADC cells and of the gf180mcuf cells the RTL instantiates (build_cells.py)

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
module gf180mcuf_INVD1(z, vdd, vss, i);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_INVD6(i, vdd, vss, zn);
    input i;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_INVD8(i, vdd, vss, zn);
    input i;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_BUFFD0(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_BUFFD2(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_BUFFD4(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_BUFFD8(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_BUFFD16(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_DEL4(i, vdd, vss, z);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_ND2D2(a1, a2, vdd, vss, zn);
    input a1, a2;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_NR3D4(a1, a2, a3, vdd, vss, zn);
    input a1, a2, a3;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_AN2D4(a1, a2, vdd, vss, z);
    input a1, a2;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_OAI211D4(a1, a2, b, c, vdd, vss, zn);
    input a1, a2, b, c;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_TIEH(vdd, vss, z);
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module gf180mcuf_TIEL(vdd, vss, zn);
    output zn;
    inout vdd, vss;
endmodule


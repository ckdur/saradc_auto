(* blackbox *)
module SARADC_CELL_INVX0_ASSW(
//`ifdef WITH_BODY
    vnw, vpw, 
//`endif
    vdd, vss, i, zn);
    input i;
    output zn;
    inout 
//`ifdef WITH_BODY
        vnw, vpw, 
//`endif
        vdd, vss;
endmodule

(* blackbox *)
module SARADC_CELL_INVX16_ASCAP(
//`ifdef WITH_BODY
    vnw, vpw, 
//`endif
    vdd, vss, i, zn);
    input i;
    output zn;
    inout 
//`ifdef WITH_BODY
        vnw, vpw, 
//`endif
        vdd, vss;
endmodule

(* blackbox *)
module SARADC_FILLTIE2(vdd, vss);
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_TIEH(z, vdd, vss);
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_TIEL(zn, vdd, vss);
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_TIEL(zn, vdd, vss);
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_INVD1(i, zn, vdd, vss);
    input i;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_INVD6(i, zn, vdd, vss);
    input i;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_INVD8(i, zn, vdd, vss);
    input i;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_OAI211D4(a1, a2, b, c, zn, vdd, vss);
    input a1, a2, b, c;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_ND2D2(a1, a2, zn, vdd, vss);
    input a1, a2;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_AN2D4(a1, a2, z, vdd, vss);
    input a1, a2;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_NR3D4(a1, a2, a3, zn, vdd, vss);
    input a1, a2, a3;
    output zn;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_BUFFD0(i, z, vdd, vss);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_BUFFD2(i, z, vdd, vss);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_BUFFD4(i, z, vdd, vss);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_BUFFD8(i, z, vdd, vss);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_BUFFD16(i, z, vdd, vss);
    input i;
    output z;
    inout vdd, vss;
endmodule

(* blackbox *)
module sg13g2f_DEL4(i, z, vdd, vss);
    input i;
    output z;
    inout vdd, vss;
endmodule

// Cell definition
// The definitions come from the standard cell generator (stdcell-gen) for sky130f
// Float cells (no body connection), cells/sky130f

`define WITH_POWER
//`define WITH_BODY

module SARADC_CELL_INVX1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input I,
  output ZN
);
  // INVX1 -> INVD1
  sky130f_INVD1 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(I), .z(ZN)
  );

endmodule

module SARADC_CELL_INVX6(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input I,
  output ZN
);
  // INVX6 -> INVD6 (TODO)
  sky130f_INVD6 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(I), .zn(ZN)
  );

endmodule

module SARADC_CELL_INVX8(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input I,
  output ZN
);
  // INVX8 -> INVD8
  sky130f_INVD8 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(I), .zn(ZN)
  );

endmodule

module SARADC_CELL_OAI211X16(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input A0, A1, B0, C0,
  output ZN
);
  // OAI211X16 -> OAI211D4 x4
  sky130f_OAI211D4 impl_0(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .a1(A0), .a2(A1), .b(B0), .c(C0), .zn(ZN)
  );
  sky130f_OAI211D4 impl_1(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .a1(A0), .a2(A1), .b(B0), .c(C0), .zn(ZN)
  );
  sky130f_OAI211D4 impl_2(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .a1(A0), .a2(A1), .b(B0), .c(C0), .zn(ZN)
  );
  sky130f_OAI211D4 impl_3(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .a1(A0), .a2(A1), .b(B0), .c(C0), .zn(ZN)
  );

endmodule

module SARADC_CELL_OAI211X4(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input A0, A1, B0, C0,
  output ZN
);
  // OAI211X4 -> OAI211D4
  sky130f_OAI211D4 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .a1(A0), .a2(A1), .b(B0), .c(C0), .zn(ZN)
  );

endmodule

module SARADC_CELL_NAND2X2(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input A0, A1,
  output ZN
);
  // NAND2X2 -> ND2D2
  sky130f_ND2D2 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .a1(A0), .a2(A1), .zn(ZN)
  );

endmodule

module SARADC_CELL_AND2X4(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input A0, A1,
  output Z
);
  // AND2X4 -> AN2D4
  sky130f_AN2D4 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .a1(A0), .a2(A1), .z(Z)
  );

endmodule

module SARADC_CELL_NOR3X4(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input A0, A1, A2,
  output ZN
);
  // NOR3X4 -> NR3D4
  sky130f_NR3D4 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .a1(A0), .a2(A1), .a3(A2), .zn(ZN)
  );

endmodule

module SARADC_CELL_AND2X16(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input A0, A1,
  output Z
);
  // AND2X16 -> AN2D4
  sky130f_AN2D4 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .a1(A0), .a2(A1), .z(Z)
  );

endmodule

module SARADC_CELL_BUFFX0(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input I,
  output Z
);
  // BUFFX0 -> BUFFD0
  sky130f_BUFFD0 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(I), .z(Z)
  );

endmodule

module SARADC_CELL_BUFFX2(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input I,
  output Z
);
  // BUFFX2 -> BUFFD2
  sky130f_BUFFD2 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(I), .z(Z)
  );

endmodule

module SARADC_CELL_BUFFX4(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input I,
  output Z
);
  // BUFFX4 -> BUFFD4
  sky130f_BUFFD4 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(I), .z(Z)
  );

endmodule

module SARADC_CELL_BUFFX8(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input I,
  output Z
);
  // BUFFX8 -> BUFFD8
  sky130f_BUFFD8 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(I), .z(Z)
  );

endmodule

module SARADC_CELL_BUFFX16(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input I,
  output Z
);
  // BUFFX16 -> BUFFD16
  sky130f_BUFFD16 impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(I), .z(Z)
  );

endmodule

module SARADC_CELL_DEL4X4(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input I,
  output Z
);

  // DEL4X4 -> DEL4 + BUFFD4
  wire Z1;
  sky130f_DEL4 impl1(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(I), .z(Z1)
  );
  sky130f_BUFFD4 impl2(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(Z1), .z(Z)
  );

endmodule

module SARADC_CELL_DEL4X2(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  input I,
  output Z
);
  // DEL4X2 -> DEL4 + BUFFD2
  wire Z1;
  sky130f_DEL4 impl1(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(I), .z(Z1)
  );
  sky130f_BUFFD2 impl2(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .i(Z1), .z(Z)
  );

endmodule

module SARADC_CELL_TIEH(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  output Z
);
  // TIEH -> TIEH
  sky130f_TIEH impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .z(Z)
  );

endmodule

module SARADC_CELL_TIEL(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
`ifdef WITH_BODY
  inout VNW, VPW,
`endif
  output ZN
);
  // TIEL -> TIEL
  sky130f_TIEL impl(
`ifdef WITH_POWER
    .vdd(VDD), .vss(VSS), 
`endif
`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
`endif
    .zn(ZN)
  );

endmodule


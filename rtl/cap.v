// Capacitor definition
// Use the biggest inverter as a capacitor
// Maybe... is better to use a regular capacitor?

(* keep_hierarchy = "yes" *)
module SARADC_CAP (
  inout VNW, VPW,
  inout VSH, FL // TODO: Ask Li why those names
);

  SARADC_CELL_INVX16_ASCAP impl (
//`ifdef WITH_BODY
    .vnw(VNW), .vpw(VPW),
//`endif
    .vdd(FL), .vss(FL),
    .i(VSH), .zn(FL)
  );

endmodule


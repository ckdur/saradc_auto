// Switch definition
// Uses the smallest inverter to create two pass-gates
// The passgates created between VDD-ZN of one INV, and the ZN-VSS of other INV

(* keep_hierarchy = "yes" *)
module SARADC_SW (
  inout VDD, VSS,
  input SB, S, // Negated and non-negated
  inout Z1, Z2 // Inouts of the switch
);
  
  // We use VDD and VSS in unintended ways
  // TODO: Crimes against the logic (lol)
  
  SARADC_CELL_INVX0_ASSW pgp_lz1 (
//`ifdef WITH_BODY
    .vnw(VDD), .vpw(VSS),
//`endif
  // | passg in p |  load Z1 |
    .vdd(Z2), .zn(Z1), .vss(Z1), .i(SB)
  );
  SARADC_CELL_INVX0_ASSW pgn_lz1 (
//`ifdef WITH_BODY
    .vnw(VDD), .vpw(VSS),
//`endif
  // | load Z1  | passg in n |
    .vdd(Z1), .zn(Z1), .vss(Z2), .i(S)
  );
  
  SARADC_CELL_INVX0_ASSW pgp_lz2 (
//`ifdef WITH_BODY
    .vnw(VDD), .vpw(VSS),
//`endif
  // | passg in p |  load Z2 |
    .vdd(Z1), .zn(Z2), .vss(Z2), .i(SB)
  );
  SARADC_CELL_INVX0_ASSW pgn_lz2 (
//`ifdef WITH_BODY
    .vnw(VDD), .vpw(VSS),
//`endif
  // | load Z2  | passg in n |
    .vdd(Z2), .zn(Z2), .vss(Z1), .i(S)
  );

  // TODO: We might need to put a pair of antennas

endmodule

// Switch for testing purposes
(* keep_hierarchy = "yes" *)
module SARADC_SWDUM (
  inout VDD, VSS,
  input SB, S, // Negated and non-negated
  inout Z1, Z2 // Inouts of the switch
);
  
  wire Z3;
  
  SARADC_CELL_INVX0_ASSW sw1 (
//`ifdef WITH_BODY
    .vnw(VDD), .vpw(VSS),
//`endif
    .vdd(Z2), .zn(Z1), .vss(Z3), .i(SB)
  );
  SARADC_CELL_INVX0_ASSW sw2 (
//`ifdef WITH_BODY
    .vnw(VDD), .vpw(VSS),
//`endif
    .vdd(Z3), .zn(Z1), .vss(Z2), .i(S)
  );

endmodule

module SARADC_SW_MULT # (
  parameter N = 3
) (
  inout VDD, VSS,
  input SB, S, // Negated and non-negated
  inout Z1, Z2 // Inouts of the switch
);
  genvar i;
  
  generate
    for(i = 0; i < N; i = i + 1) begin : impl
      SARADC_SW impl (
        .VDD(VDD), .VSS(VSS), 
        .SB(SB), .S(S),
        .Z1(Z1), .Z2(Z2)
      );
    end
  endgenerate
endmodule

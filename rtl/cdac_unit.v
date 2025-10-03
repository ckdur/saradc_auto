// CDAC unit definition
// Three switches, and a capacitor
// The capacitor uses the biggest possible inverter in the std cell library

module SARADC_CDAC_UNIT # (
  parameter integer NSW_VI = 1,
  parameter integer NSW_VOUTH = 1,
  parameter integer NSW_VOUTL = 1,
  parameter integer NSW_CAP = 1
) (
  inout VDD, VSS,
  input CRI, CRIB, CRH, CRHB, CRL, CRLB, // Negated and non-negated
  inout VI, VOUTH, VOUTL, // Inouts of the switches
  inout VSH, FL // Debug signals (Capacitor terminals)
);
  
  genvar i;
  
  generate
    for(i = 0; i < NSW_VI; i = i + 1) begin : vi2cap
      SARADC_SW sw_vi2cap (
        .VDD(VDD), .VSS(VSS), 
        .SB(CRIB), .S(CRI),
        .Z1(VI), .Z2(VSH)
      );
    end
  endgenerate
  
  
  generate
    for(i = 0; i < NSW_VOUTH; i = i + 1) begin : cap2vouth
      SARADC_SW sw_cap2vouth (
        .VDD(VDD), .VSS(VSS), 
        .SB(CRHB), .S(CRH),
        .Z1(VSH), .Z2(VOUTH) // NOTE: Maybe the order of the pins matter.
      );
    end
  endgenerate
  
  
  generate
    for(i = 0; i < NSW_VOUTL; i = i + 1) begin : cap2voutl
      SARADC_SW sw_cap2voutl (
        .VDD(VDD), .VSS(VSS), 
        .SB(CRLB), .S(CRL),
        .Z1(VSH), .Z2(VOUTL)
      );
    end
  endgenerate
  
  
  generate
    for(i = 0; i < NSW_CAP; i = i + 1) begin : cap
      SARADC_CAP cap (
        .VNW(VDD), .VPW(VSS),
        .VSH(VSH), .FL(FL)
      );
    end
  endgenerate

endmodule


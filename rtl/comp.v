// Latched comparator definition
// Uses two OAI211X16 for the latch
// We do not have X16, so we use 4x the X4
// Also, we use NAND2 for reinforcing the output?
// Also also, what the hell is clkbuf for?

module SARADC_COMP (
  inout VDD, VSS,
  input CMP, CMPB, CK, // Negated and non-negated of compare start
  inout VP, VN, // Differential inputs
  output OUTN, OUTP // Differential output
);
  
  wire OUTNp, OUTPp; // Pre-signals
  wire OUTNpb, OUTPpb; // Pre-signals buffered 1 time
  
  // Compare stage
  SARADC_CELL_OAI211X16 vp_cmp (
    .VDD(VDD), .VSS(VSS), 
    .A0(CMPB), .A1(VP), .B0(CMP), .C0(OUTPp), .ZN(OUTNp));
  SARADC_CELL_OAI211X16 vn_cmp (
    .VDD(VDD), .VSS(VSS), 
    .A0(CMPB), .A1(VN), .B0(CMP), .C0(OUTNp), .ZN(OUTPp));
    
  // Differential stage
  SARADC_CELL_NAND2X2 n2p (
    .VDD(VDD), .VSS(VSS), 
    .A0(OUTNp), .A1(CMP), .ZN(OUTPp));
  SARADC_CELL_NAND2X2 p2n (
    .VDD(VDD), .VSS(VSS), 
    .A0(OUTPp), .A1(CMP), .ZN(OUTNp));
  
  // Buffering stage
  SARADC_CELL_BUFFX0 buf_n0 (
    .VDD(VDD), .VSS(VSS), 
    .I(OUTNp), .Z(OUTNpb));
  SARADC_CELL_BUFFX2 buf_n1 (
    .VDD(VDD), .VSS(VSS), 
    .I(OUTNpb), .Z(OUTN));
  SARADC_CELL_BUFFX0 buf_p0 (
    .VDD(VDD), .VSS(VSS), 
    .I(OUTPp), .Z(OUTPpb));
  SARADC_CELL_BUFFX2 buf_p1 (
    .VDD(VDD), .VSS(VSS), 
    .I(OUTPpb), .Z(OUTP));
  
endmodule


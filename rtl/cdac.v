// LSB CDAC definition
// This is the Capacitor DAC, doing the least significant bits (LSB)

module SARADC_LSB_CDAC # (
  parameter integer NBITS = 7,
  parameter integer NPW = 3, // Number of caps in X for each CDAC unit
  parameter integer NPH = 2 // Number of caps in Y for each CDAC unit
) (
  inout VDD, VSS,
  input CPRE, CPREB, 
  input [NBITS-1:0] CRH, CRHB, CRL, CRLB, // Negated and non-negated
  inout VREF, VOUTH, VOUTL, // Inouts of the switches
  inout [NBITS:0] VSH, FL // Debug signals (Capacitor terminals, there is one more for the dummy)
);
  
  genvar i;
  generate
    for(i = 0; i < NBITS; i = i + 1) begin : cdac_bit
      SARADC_CDAC_UNIT #(
        .NSW_VI(1 << i), // 1, 2, 4, 8...
        .NSW_VOUTH(1 << i), // 1, 2, 4, 8...
        .NSW_VOUTL(1 << i), // 1, 2, 4, 8...
        .NSW_CAP((1 << i)*NPW*NPH) // 1, 2, 4, 8... and multiplied by NPW*NPH
      ) cdac_unit (
        .VDD(VDD), .VSS(VSS), 
        .CRI(CPRE), .CRIB(CPREB),
        .CRH(CRH[i]), .CRHB(CRHB[i]),
        .CRL(CRL[i]), .CRLB(CRLB[i]),
        .VI(VREF), .VOUTH(VOUTH), .VOUTL(VOUTL),
        .VSH(VSH[i+1]), .FL(FL[i+1]) // Note: These are 1 bit off
      );
    end
  endgenerate
  
  wire zero, one;
  SARADC_CELL_TIEH tieh(.VDD(VDD), .VSS(VSS), .Z(one));
  SARADC_CELL_TIEL tiel(.VDD(VDD), .VSS(VSS), .ZN(zero));
  
  // The dummy CDAC
  SARADC_CDAC_UNIT #(
    .NSW_VI(1),
    .NSW_VOUTH(1),
    .NSW_VOUTL(1),
    .NSW_CAP(6)
  ) cdac_unit (
    .VDD(VDD), .VSS(VSS), 
    .CRI(CPRE), .CRIB(CPREB),
    .CRH(zero), .CRHB(one), // Disabled
    .CRL(zero), .CRLB(one), // Disabled
    .VI(VREF), .VOUTH(VOUTH), .VOUTL(VOUTL),
    .VSH(VSH[0]), .FL(FL[0]) // NOTE: The dummy VSH/FL is put in 0
  );

endmodule

// MSB CDAC definition
// This is the Capacitor DAC, doing the most significant bit (MSB), singular

module SARADC_MSB_CDAC # (
  parameter integer NBITS = 7,
  parameter integer NPW = 3, // Number of caps in X for each CDAC unit
  parameter integer NPH = 2 // Number of caps in Y for each CDAC unit
) (
  inout VDD, VSS,
  input CPRE, CPREB, CHOLD, CHOLDB,
  inout VIP, VIN, VOUT, // Inouts of the switches
  inout VSH, FL // Debug signals (Capacitor terminals)
);
  
  wire zero, one;
  SARADC_CELL_TIEH tieh(.VDD(VDD), .VSS(VSS), .Z(one));
  SARADC_CELL_TIEL tiel(.VDD(VDD), .VSS(VSS), .ZN(zero));
  
  // This CDAC unit is connected backwards
  SARADC_CDAC_UNIT #(
    .NSW_VI(1 << NBITS),
    .NSW_VOUTH(1 << NBITS),
    .NSW_VOUTL(1 << NBITS),
    .NSW_CAP((1 << NBITS)*NPW*NPH)
  ) cdac_unit (
    .VDD(VDD), .VSS(VSS), 
    .CRI(CHOLD), .CRIB(CHOLDB),
    .CRH(CPRE), .CRHB(CPREB),
    .CRL(zero), .CRLB(one), // Disabled (NOTE: It was conected to power, but this is illegal)
    .VI(VOUT), .VOUTH(VIP), .VOUTL(VIN),
    .VSH(VSH), .FL(FL)
  );

endmodule


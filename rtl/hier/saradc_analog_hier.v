// Definition of the SARADC from the analog perspective, with the CDAC halves
// as macros (hierarchical PnR, pnr/). Same circuit as SARADC_ANALOG.

(* keep_hierarchy = "yes" *)
module SARADC_ANALOG_HIER #(
  parameter integer NBITS = 8,
  parameter integer NPW = 3, // Number of caps in X for each CDAC unit
  parameter integer NPH = 2 // Number of caps in Y for each CDAC unit
) (
  inout VDD, VSS,
  // Analog signals
  inout VREFH, VREFL, VIN, VIP,
  // Digital to Analog control signals
  input CLK,
  input VALID,                      // VALID=1 when conversion finished
  input SAMPLE,                     // to S&H circuit
  input [NBITS-1:0] RESULTP,        // 8 bit RESULT output
  input [NBITS-1:0] RESULTN,
  output CMPO,                      // from comparitor
  output CLKBUF
);
  wire CPRE, CPREB, CHOLD, CHOLDB, CCMP, CCMPB;
  wire [NBITS-2:0] CRH, CRHB, CRL, CRLB;

  (* dont_touch = "yes" *)
  wire VOUTH, VOUTL;

  // The two halves of the CDAC (macros). L is the same macro mirrored,
  // with the inputs and outputs inverted
  SARADC_CDAC cdac_h (
    .VDD(VDD), .VSS(VSS),
    .CPRE(CPRE), .CPREB(CPREB), .CHOLD(CHOLD), .CHOLDB(CHOLDB),
    .CRH(CRH), .CRHB(CRHB), .CRL(CRL), .CRLB(CRLB),
    .VREF(VREFH), .VIP(VIP), .VIN(VIN), .VOUTH(VOUTH), .VOUTL(VOUTL) // FORWARD
  );
  SARADC_CDAC cdac_l (
    .VDD(VDD), .VSS(VSS),
    .CPRE(CPRE), .CPREB(CPREB), .CHOLD(CHOLD), .CHOLDB(CHOLDB),
    .CRH(CRH), .CRHB(CRHB), .CRL(CRL), .CRLB(CRLB),
    .VREF(VREFL), .VIP(VIN), .VIN(VIP), .VOUTH(VOUTL), .VOUTL(VOUTH) // INVERTED
  );

  // Switch for joining the VOUTH and VOUTL
  SARADC_SW_MULT #(.N(3)) sw_vouth2voutl (
    .VDD(VDD), .VSS(VSS), 
    .SB(CPREB), .S(CPRE),
    .Z1(VOUTH), .Z2(VOUTL) // NOTE: Again, the order maybe is important.
  );
  
  // The comparator
  SARADC_COMP cmp (
    .VDD(VDD), .VSS(VSS), 
    .CMP(CCMP), .CMPB(CCMPB), .CK(CLK),
    .VP(VOUTH), .VN(VOUTL),
    .OUTN(), .OUTP(CMPO) // TODO: OUTN is not used
  );
  
  // Logic buffers
  saradc_logic_buf #(.NBITS(NBITS)) buflogic (
    .VDD(VDD), .VSS(VSS),
    .CLK(CLK),
    .RESULTP(RESULTP[NBITS-1:1]), .RESULTN(RESULTN[NBITS-1:1]),
    .SAMPLE(SAMPLE),
    .VALID(VALID),
    
    .CPRE(CPRE), .CPREB(CPREB), .CHOLD(CHOLD), .CHOLDB(CHOLDB), .CCMP(CCMP), .CCMPB(CCMPB),
    .CRH(CRH), .CRHB(CRHB), .CRL(CRL), .CRLB(CRLB),
    .CLKBUF(CLKBUF)
  );
  
endmodule


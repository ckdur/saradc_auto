// Definition of the SARADC
// Combining the analog and the digital

`ifndef NBITS
`define NBITS 5
`endif

(* blackbox *)
module sar_logic_wreset 
(
  input CLK,                        // clock input
  input RST,                        // reset input
  input GO,                         // GO=1 to perform conversion
  output VALID,                     // VALID=1 when conversion finished
  output reg [`NBITS-1:0] RESULTP,   // 8 bit RESULT output
  output reg [`NBITS-1:0] RESULTN,
  output SAMPLE,                    // to S&H circuit
  input CMP                         // from comparitor
);
endmodule

(* keep_hierarchy = "yes" *)
module SARADC #(
  parameter integer NBITS = `NBITS,
  parameter integer NPW = 3, // Number of caps in X for each CDAC unit
  parameter integer NPH = 2 // Number of caps in Y for each CDAC unit
) (
  inout AVDD, VDD, VSS, // NOTE: VDD is the digital VDD
  // Analog signals
  inout VREFH, VREFL, VIN, VIP,
  // Digital signals
  input CLK, RST,
  input GO, 
  output VALID, SAMPLE,
  output [NBITS-1:0] RESULT
);

  // TODO: Is buffering the CLK through the analog the RIGHT WAY?
  wire [NBITS-1:0] RESULTN;
  wire CMPO, CLKBUF;

  SARADC_ANALOG #(
    .NBITS(NBITS),
    .NPW(NPW),
    .NPH(NPH)
  ) analog (
    .VDD(AVDD), .VSS(VSS), 
    .VREFH(VREFH), .VREFL(VREFL), .VIN(VIN), .VIP(VIP),
    .CLK(CLK),
    .VALID(VALID), .SAMPLE(SAMPLE),
    .RESULTP(RESULT), .RESULTN(RESULTN),
    .CMPO(CMPO), .CLKBUF(CLKBUF)
  );

`ifndef DIGTOP
`define DIGTOP sar_logic_wreset
`endif
  `DIGTOP digital ( 
    .CLK(CLK), .RST(RST),
    .GO(GO),
    .VALID(VALID), .SAMPLE(SAMPLE),
    .RESULTP(RESULT), .RESULTN(RESULTN),
    .CMP(CMPO)
  );
  
endmodule


// One half of the differential CDAC as a macro (hierarchical PnR, pnr/)
// MSB + LSB CDACs with their switches, and the dummy units around them.
// The SARADC uses two: H as is, and L mirrored with VIP/VIN, VOUTH/VOUTL
// swapped and VREF = VREFL (see saradc_analog_hier.v).

`ifndef NBITS
`define NBITS 5
`endif

module SARADC_CDAC #(
  parameter integer NBITS = `NBITS,
  parameter integer NPW = 3, // Number of caps in X for each CDAC unit
  parameter integer NPH = 2 // Number of caps in Y for each CDAC unit
) (
  inout VDD, VSS,
  input CPRE, CPREB, CHOLD, CHOLDB,
  input [NBITS-2:0] CRH, CRHB, CRL, CRLB,
  inout VREF, VIP, VIN, VOUTH, VOUTL
);

  // Circle function number of
  function integer ncircle;
    input [31:0] nelem;
    integer ntotal;
  begin
    ntotal = 2;
    for (ncircle=1; ntotal<nelem; ncircle=ncircle+1) begin
      ntotal = ncircle * ncircle * 2;
    end
    ncircle = ncircle - 1;
  end
  endfunction

  // Calculate the number of dummies from NBITS
  localparam nu = 1<<NBITS;
  localparam nc = ncircle(nu);
  localparam nall = nc * nc * 2 + nc * 6 + 4; // Area + perimeter (w being nc*2, h being nc)
  localparam ndummy = nall - nu;

  // CDAC dummy phase
  SARADC_CDAC_DUMMY #(.N(ndummy), .NPW(NPW), .NPH(NPH)) dummy (.VDD(VDD), .VSS(VSS));

  // CDAC MSB phase
  (* dont_touch = "yes" *)
  wire MSB_VSH, MSB_FL;
  SARADC_MSB_CDAC #(
    .NBITS(NBITS-1), .NPW(NPW), .NPH(NPH)
  ) msb_cdac (
    .VDD(VDD), .VSS(VSS),
    .CPRE(CPRE), .CPREB(CPREB), .CHOLD(CHOLD), .CHOLDB(CHOLDB),
    .VIP(VIP), .VIN(VIN), .VOUT(VOUTH),
    .VSH(MSB_VSH), .FL(MSB_FL)
  );

  // CDAC LSB phase
  (* dont_touch = "yes" *)
  wire [NBITS-1:0] LSB_VSH, LSB_FL;
  SARADC_LSB_CDAC #(
    .NBITS(NBITS-1), .NPW(NPW), .NPH(NPH)
  ) lsb_cdac (
    .VDD(VDD), .VSS(VSS),
    .CPRE(CPRE), .CPREB(CPREB),
    .CRH(CRH), .CRHB(CRHB), .CRL(CRL), .CRLB(CRLB),
    .VREF(VREF), .VOUTH(VOUTH), .VOUTL(VOUTL),
    .VSH(LSB_VSH), .FL(LSB_FL)
  );

endmodule

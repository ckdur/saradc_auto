// Definition of the SARADC buffer
// Pseudo-digital circuit

module saradc_logic_buf #(
  parameter NBITS = 8
)
(
  inout VDD, VSS,
  input CLK,
  input [NBITS-1:1] RESULTP,
  input [NBITS-1:1] RESULTN,
  input SAMPLE,
  input VALID,
  
  output CPRE, CPREB, CHOLD, CHOLDB, CCMP, CCMPB,
  output [NBITS-2:0] CRH, CRHB, CRL, CRLB,
  output CLKBUF
);
  wire PRE, HOLD, CMP;
  
  // The logic
  saradc_logic_conv #(.NBITS(NBITS)) conv
  (
    .VDD(VDD), .VSS(VSS),
    .CLK(CLK),
    .RESULTP(RESULTP),
    .RESULTN(RESULTN),
    .SAMPLE(SAMPLE),
    .VALID(VALID),
    .CLKBUF(CLKBUF),
    .PRE(PRE), .HOLD(HOLD), .CMP(CMP),
    .CRH(CRH), .CRHB(CRHB), .CRL(CRL), .CRLB(CRLB)
  );
  
  // Latch buffers
  saradc_sh2sbuf lnbuf_cpre(.VDD(VDD), .VSS(VSS), .I(PRE), .Z(CPRE), .ZN(CPREB));
  saradc_sh2sbuf lnbuf_chold(.VDD(VDD), .VSS(VSS), .I(HOLD), .Z(CHOLD), .ZN(CHOLDB));
  saradc_cmpcs2cmp lnbuf_ccmp(.VDD(VDD), .VSS(VSS), .I(CMP), .Z(CCMP), .ZN(CCMPB));
  
  // Regular buffers
  // TODO: The VALID and SAMPLE shall be buffered by the digital flow
  /*wire VALIDB;
  SARADC_CELL_BUFFX4 validbuf4(.VDD(VDD), .VSS(VSS), .I(VALID), .Z(VALIDB));
  SARADC_CELL_BUFFX16 validbuf16(.VDD(VDD), .VSS(VSS), .I(VALIDB), .Z(VALIDBUF));
  
  wire SAMPLEB;
  SARADC_CELL_BUFFX4 samplebuf4(.VDD(VDD), .VSS(VSS), .I(SAMPLE), .Z(SAMPLEB));
  SARADC_CELL_BUFFX16 samplebuf16(.VDD(VDD), .VSS(VSS), .I(SAMPLEB), .Z(SAMPLEBUF));*/
  
  // TODO: This is not used in the schematic
  /*wire CMPB;
  SARADC_CELL_BUFFX4 samplebuf4(.VDD(VDD), .VSS(VSS), .I(CMP), .Z(CMPB));
  SARADC_CELL_BUFFX16 samplebuf16(.VDD(VDD), .VSS(VSS), .I(CMPB1), .Z(CMPBUF));*/
endmodule

// Definition of the SH2SBUF (TODO: What is this?)
module saradc_sh2sbuf (
  inout VDD, VSS,
  input I,
  output Z, ZN
);
  wire N1, N2, N3;
  
  // Input buffer
  SARADC_CELL_BUFFX16 ibuf16(.VDD(VDD), .VSS(VSS), .I(I), .Z(N3));
  
  // Latch
  SARADC_CELL_INVX8 ln1(.VDD(VDD), .VSS(VSS), .I(N3), .ZN(N2));
  SARADC_CELL_INVX8 ln2(.VDD(VDD), .VSS(VSS), .I(N2), .ZN(N3));
  
  // Output Buffers
  SARADC_CELL_BUFFX8 zbuf8(.VDD(VDD), .VSS(VSS), .I(N3), .Z(N1));
  SARADC_CELL_BUFFX16 zbuf16_1(.VDD(VDD), .VSS(VSS), .I(N1), .Z(Z));
  SARADC_CELL_BUFFX16 zbuf16_2(.VDD(VDD), .VSS(VSS), .I(N1), .Z(Z));
  SARADC_CELL_BUFFX16 znbuf16_1(.VDD(VDD), .VSS(VSS), .I(N2), .Z(ZN));
  SARADC_CELL_BUFFX16 znbuf16_2(.VDD(VDD), .VSS(VSS), .I(N2), .Z(ZN));
  
endmodule

// Definition of the CMPCS2CMP (TODO: What is this?)
module saradc_cmpcs2cmp (
  inout VDD, VSS,
  input I,
  output Z, ZN
);
  wire IL, ID, IP, ILBUF;
  
  // Latch
  SARADC_CELL_INVX6 ln1(.VDD(VDD), .VSS(VSS), .I(I), .ZN(IL));
  SARADC_CELL_INVX6 ln2(.VDD(VDD), .VSS(VSS), .I(IL), .ZN(I));
  
  // Pulse generation
  SARADC_CELL_DEL4X4 del4(.VDD(VDD), .VSS(VSS), .I(I), .Z(ID));
  SARADC_CELL_AND2X4 deland(.VDD(VDD), .VSS(VSS), .A0(I), .A1(ID), .Z(IP));
  
  // Output Buffers
  SARADC_CELL_BUFFX4 lnbbuf4(.VDD(VDD), .VSS(VSS), .I(IL), .Z(ILBUF));
  SARADC_CELL_BUFFX16 lnbbuf16(.VDD(VDD), .VSS(VSS), .I(ILBUF), .Z(ZN));
  SARADC_CELL_BUFFX16 delbuf16(.VDD(VDD), .VSS(VSS), .I(IP), .Z(Z));
  
endmodule

// Definition of the logic converter
module saradc_logic_conv #(
  parameter NBITS = 8
)
(
  inout VDD, VSS,
  input CLK,
  input [NBITS-1:1] RESULTP,
  input [NBITS-1:1] RESULTN,
  input SAMPLE,
  input VALID,
  
  output CLKBUF,
  
  output PRE, HOLD, CMP,
  output [NBITS-2:0] CRH, CRHB, CRL, CRLB
);
  genvar i;
  generate
    for(i = 1; i < NBITS; i=i+1) begin : re2cr
      saradc_re2cr ren2crh(
        .VDD(VDD), .VSS(VSS), 
        .I(RESULTN[i]), .Z(CRH[i-1]), .ZN(CRHB[i-1])
      );
      saradc_re2cr rep2crl(
        .VDD(VDD), .VSS(VSS), 
        .I(RESULTP[i]), .Z(CRL[i-1]), .ZN(CRLB[i-1])
      );
    end
  endgenerate
  
  saradc_smpcs smpcs(
    .VDD(VDD), .VSS(VSS), 
    .CLK(CLK), .SAMPLE(SAMPLE),
    .CPRE(PRE), .CHOLD(HOLD), .CLKBUF(CLKBUF)
  );
  
  saradc_cmpbegin cmpbegin(
    .VDD(VDD), .VSS(VSS), 
    .CLKBUF(CLKBUF), .SAMPLE(SAMPLE), .VALID(VALID),
    .CCMP(CMP)
  );
endmodule 

// Definition of a RE2CR
module saradc_re2cr(
  inout VDD, VSS,
  input I,
  output Z, ZN
);
  wire ZL, ZNL;
  wire ZLD1, ZLD2, ZLD3;
  wire ZNLD1, ZNLD2, ZNLD3;
  
  // Input buffer
  SARADC_CELL_BUFFX16 ibuf16(.VDD(VDD), .VSS(VSS), .I(I), .Z(ZL));
  
  // Latch
  SARADC_CELL_INVX8 ln1(.VDD(VDD), .VSS(VSS), .I(ZL), .ZN(ZNL));
  SARADC_CELL_INVX8 ln2(.VDD(VDD), .VSS(VSS), .I(ZNL), .ZN(ZL));
  
  // Delays
  SARADC_CELL_DEL4X2 zdel_1(.VDD(VDD), .VSS(VSS), .I(ZL), .Z(ZLD1));
  SARADC_CELL_DEL4X2 zdel_2(.VDD(VDD), .VSS(VSS), .I(ZLD1), .Z(ZLD2));
  SARADC_CELL_DEL4X2 zdel_3(.VDD(VDD), .VSS(VSS), .I(ZLD2), .Z(ZLD3));
  SARADC_CELL_DEL4X2 zndel_1(.VDD(VDD), .VSS(VSS), .I(ZNL), .Z(ZNLD1));
  SARADC_CELL_DEL4X2 zndel_2(.VDD(VDD), .VSS(VSS), .I(ZNLD1), .Z(ZNLD2));
  SARADC_CELL_DEL4X2 zndel_3(.VDD(VDD), .VSS(VSS), .I(ZNLD2), .Z(ZNLD3));
  
  // Output Buffers
  SARADC_CELL_BUFFX16 zbuf(.VDD(VDD), .VSS(VSS), .I(ZLD3), .Z(Z));
  SARADC_CELL_BUFFX16 znbuf(.VDD(VDD), .VSS(VSS), .I(ZNLD3), .Z(ZN));
  
endmodule

// Definition of a SMPCS
// WARNING: Heavily timing section!
module saradc_smpcs(
  inout VDD, VSS,
  input CLK, SAMPLE,
  output CPRE, CHOLD, CLKBUF
);
  
  // Input clock buffer
  SARADC_CELL_BUFFX16 clkbuf(.VDD(VDD), .VSS(VSS), .I(CLK), .Z(CLKBUF));
  
  // Sample to hold
  SARADC_CELL_INVX8 invsmp(.VDD(VDD), .VSS(VSS), .I(SAMPLE), .ZN(CHOLD));
  
  // CPRE construction
  wire CHOLDB, CHOLDB1;
  wire CLKBUFD1, CLKBUFD2, CLKBUFD3;
  SARADC_CELL_INVX8 choldb(.VDD(VDD), .VSS(VSS), .I(CHOLD), .ZN(CHOLDB));
  SARADC_CELL_BUFFX8 choldb1(.VDD(VDD), .VSS(VSS), .I(CHOLDB), .Z(CHOLDB1));
  SARADC_CELL_DEL4X4 clkbufd1(.VDD(VDD), .VSS(VSS), .I(CLKBUF), .Z(CLKBUFD1));
  SARADC_CELL_DEL4X4 clkbufd2(.VDD(VDD), .VSS(VSS), .I(CLKBUFD1), .Z(CLKBUFD2));
  SARADC_CELL_DEL4X4 clkbufd3(.VDD(VDD), .VSS(VSS), .I(CLKBUFD2), .Z(CLKBUFD3));
  SARADC_CELL_AND2X16 cpreand(.VDD(VDD), .VSS(VSS), .A0(CHOLDB1), .A1(CLKBUFD3), .Z(CPRE));
endmodule

// Definition of CMPBEGIN
module saradc_cmpbegin(
  inout VDD, VSS,
  input CLKBUF, SAMPLE, VALID,
  output CCMP
);
  wire CCMPNR, CCMPNR1;
  // CCMP construction
  SARADC_CELL_NOR3X4 ccmpnor(.VDD(VDD), .VSS(VSS), 
    .A0(SAMPLE), .A1(CLKBUF), .A2(VALID), .ZN(CCMPNR));
  
  // Buffering
  SARADC_CELL_BUFFX8 ccmpbuf1(.VDD(VDD), .VSS(VSS), .I(CCMPNR), .Z(CCMPNR1));
  SARADC_CELL_BUFFX16 ccmpbuf2(.VDD(VDD), .VSS(VSS), .I(CCMPNR1), .Z(CCMP));
endmodule


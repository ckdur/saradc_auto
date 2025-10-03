// SAR logic test
// A simple test to check if the digital part actually is moving
`timescale 1ps/1ps

module sar_logic_tb;
  localparam NBITS = 5;
  localparam freq = 10000000;
  localparam tf_ps = 1000000000/freq * 1000;
  reg CLK = 0;                    // clock input
  reg RST;                         // GO=1 to perform conversion
  reg GO;                         // GO=1 to perform conversion
  wire VALID;                     // VALID=1 when conversion finished
  wire [NBITS-1:0] RESULTP;       // 8 bit RESULT output
  wire [NBITS-1:0] RESULTN;
  wire SAMPLE;                    // to S&H circuit
  reg CMP;                        // from comparitor

`define NBITS8 _NBITS8
`ifndef DIGTOP
`define DIGTOP sar_logic_wreset
`endif
`ifdef SYNTHESIS
  `DIGTOP
`else
  `DIGTOP #(
    .NBITS(NBITS)
  )
`endif
  dut ( 
    .CLK(CLK), .RST(RST),
    .GO(GO),
    .VALID(VALID), .SAMPLE(SAMPLE),
    .RESULTP(RESULTP), .RESULTN(RESULTN),
    .CMP(CMP)
  );
  
  // Clock vibration
  always begin
     #(tf_ps/2) CLK = ~CLK;
  end
  
  // Excitations
  initial begin
`ifdef SYNTHESIS
    $dumpfile("sar_logic_tb_syn.vcd");
`else
    $dumpfile("sar_logic_tb.vcd");
`endif
    $dumpvars;
    // Put the comparator always in a fix val, for now
    CMP = 0;
    // RESET/NOT GO
    GO = 0;
    RST = 1;
    #(tf_ps * 10);
    RST = 0;
    GO = 1;
    #(tf_ps * 100); // TODO: Do some automatic checking
    $finish;
  end
endmodule


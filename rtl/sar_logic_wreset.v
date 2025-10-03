// SAR logic
// Inspired from the SAR_LOGIC_1102
// Credit to: Li Shouwei,  Ckristian Duran

`ifndef NBITS
`define NBITS 5
`endif

module sar_logic_wreset #(
  parameter NBITS = `NBITS
)
(
  input CLK,                        // clock input
  input RST,                        // reset input
  input GO,                         // GO=1 to perform conversion
  output VALID,                     // VALID=1 when conversion finished
  output reg [NBITS-1:0] RESULTP,   // 8 bit RESULT output
  output reg [NBITS-1:0] RESULTN,
  output SAMPLE,                    // to S&H circuit
  input CMP                         // from comparitor
);

  wire [NBITS-1:0] VALUE;  
  reg [1:0] state; // current state in state machine
  reg [NBITS-1:0] mask; // bit to test in binary search
  
  // state assignment
  localparam sWait=0, sSAMPLE=1, sConv=2, sDone=3;
  
  // synchronous design
  always @(posedge CLK) begin
    if (RST)
      state <= sWait; // stop and reset if RST=1
    else case (state) // choose next state in state machine
      sWait : begin
        if(GO) state <= sSAMPLE;
        RESULTP <= 'd0; // clear RESULT
        RESULTN <= 'd0; // clear RESULT
      end
      sSAMPLE : begin // start new conversion so
        state <= sConv; // enter convert state next
        mask <= 1 << (NBITS-1); // reset mask to MSB only (8'b10000000)
        RESULTP <= 'd0; // clear RESULT
        RESULTN <= 'd0; // clear RESULT
      end
      sConv : begin
        // set bit if comparitor indicates input larger than
        // VALUE currently under consideration, else leave bit clear
        if (CMP)
          RESULTP <= RESULTP | mask;
        else
          RESULTN <= RESULTN | mask;

        // shift mask to try next bit next time
        mask <= mask>>1;
        // finished once LSB has been done
        if (mask[0]) 
          state <= sDone;
      end
      sDone : begin
        RESULTP <= 'd0; // clear RESULT
        RESULTN <= 'd0; // clear RESULT
        if(GO) state <= sSAMPLE;
        else state <= sWait;
      end
    endcase
  end
  
  assign SAMPLE = state==sSAMPLE; // drive SAMPLE and hold
  assign VALUE = RESULTP | mask; // (RESULT so far) OR (bit to try)
  assign VALID = state==sDone; // indicate when finished
endmodule


// This only defines the cells, but the function is bogus
// It seems lctime does not give me a verilog.

module sg13g2f_AN2D1(a1, a2, z);
  input a1, a2;
  output z;
  assign z = (a1 && a2);
endmodule

module sg13g2f_AO21D1(a1, a2, b, z);
  input a1, a2, b;
  output z;
  assign z = (a1&a2) | (b);
endmodule

module sg13g2f_AOI21D1(a1, a2, b, zn);
  input a1, a2, b;
  output zn;
  assign zn = (!a1&!b) | (!a2&!b);
endmodule

module sg13g2f_BUFFD1(i, z);
  input i;
  output z;
  assign z = i;
endmodule

module sg13g2f_DFCNQD1(d, cp, cdn, q);
  input d, cp, cdn;
  output q;
  reg q = 1'b0;
  always @(posedge cp or negedge cdn) begin 
    if(!cdn) q <= 1'b0; 
    else q <= d;
  end
endmodule

module sg13g2f_DFQD1(d, cp, q);
  input d, cp;
  output q;
  reg q = 1'b0;
  always @(posedge cp) q <= d;
endmodule

module sg13g2f_INVD1(i, z);
  input i;
  output z;
  assign z = !i;
endmodule

module sg13g2f_MUX2D1(i0, i1, s, z);
  input i0, i1, s;
  output z;
  assign z = (i0&!s) | (i1&s);
endmodule

module sg13g2f_ND2D1(a1, a2, zn);
  input a1, a2;
  output zn;
  assign zn = !(a1 && a2);
endmodule

module sg13g2f_ND3D1(a1, a2, a3, zn);
  input a1, a2, a3;
  output zn;
  assign zn = !(a1 && a2 && a3);
endmodule

module sg13g2f_NR2D1(a1, a2, zn);
  input a1, a2;
  output zn;
  assign zn = !(a1 || a2);
endmodule

module sg13g2f_OA21D1(a1, a2, b, z);
  input a1, a2, b;
  output z;
  assign z = (a1&b) | (a2&b);
endmodule

module sg13g2f_OAI21D1(a1, a2, b, zn);
  input a1, a2, b;
  output zn;
  assign zn = (!a1&!a2) | (!b);
endmodule

module sg13g2f_OR2D1(a1, a2, z);
  input a1, a2;
  output z;
  assign z = (a1 || a2);
endmodule

module sg13g2f_TIEH(z);
  output z;
  assign z = 1'b1;
endmodule

module sg13g2f_TIEL(zn);
  output zn;
  assign zn = 1'b0;
endmodule

module sg13g2f_XNR2D1(a1, a2, zn);
  input a1, a2;
  output zn;
  assign zn = (a1 && a2) || (!a1 && !a2);
endmodule

module sg13g2f_XOR2D1(a1, a2, z);
  input a1, a2;
  output z;
  assign z = (a1 && !a2) || (!a1 && a2);
endmodule


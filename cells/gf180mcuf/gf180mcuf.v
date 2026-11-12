// gf180mcuf cell models from the liberty functions (cells/tools/merge_lib.py)

module gf180mcuf_INVD1(i, z);
  input i;
  output z;
  assign z = (~i);
endmodule

module gf180mcuf_INVD6(i, zn);
  input i;
  output zn;
  assign zn = (~i);
endmodule

module gf180mcuf_INVD8(i, zn);
  input i;
  output zn;
  assign zn = (~i);
endmodule

module gf180mcuf_BUFFD0(i, z);
  input i;
  output z;
  assign z = (i);
endmodule

module gf180mcuf_BUFFD1(i, z);
  input i;
  output z;
  assign z = (i);
endmodule

module gf180mcuf_BUFFD2(i, z);
  input i;
  output z;
  assign z = (i);
endmodule

module gf180mcuf_BUFFD4(i, z);
  input i;
  output z;
  assign z = (i);
endmodule

module gf180mcuf_BUFFD8(i, z);
  input i;
  output z;
  assign z = (i);
endmodule

module gf180mcuf_BUFFD16(i, z);
  input i;
  output z;
  assign z = (i);
endmodule

module gf180mcuf_DEL4(i, z);
  input i;
  output z;
  assign z = (i);
endmodule

module gf180mcuf_ND2D1(a1, a2, zn);
  input a1, a2;
  output zn;
  assign zn = (~a1)|(~a2);
endmodule

module gf180mcuf_ND2D2(a1, a2, zn);
  input a1, a2;
  output zn;
  assign zn = (~a1)|(~a2);
endmodule

module gf180mcuf_ND3D1(a1, a2, a3, zn);
  input a1, a2, a3;
  output zn;
  assign zn = (~a1)|(~a2)|(~a3);
endmodule

module gf180mcuf_NR2D1(a1, a2, zn);
  input a1, a2;
  output zn;
  assign zn = (~a1&~a2);
endmodule

module gf180mcuf_NR3D4(a1, a2, a3, zn);
  input a1, a2, a3;
  output zn;
  assign zn = (~a1&~a2&~a3);
endmodule

module gf180mcuf_AN2D1(a1, a2, z);
  input a1, a2;
  output z;
  assign z = (a1&a2);
endmodule

module gf180mcuf_AN2D4(a1, a2, z);
  input a1, a2;
  output z;
  assign z = (a1&a2);
endmodule

module gf180mcuf_OR2D1(a1, a2, z);
  input a1, a2;
  output z;
  assign z = (a1|a2);
endmodule

module gf180mcuf_AO21D1(a1, a2, b, z);
  input a1, a2, b;
  output z;
  assign z = (a1&a2) | (b);
endmodule

module gf180mcuf_OA21D1(a1, a2, b, z);
  input a1, a2, b;
  output z;
  assign z = (a1&b) | (a2&b);
endmodule

module gf180mcuf_AOI21D1(a1, a2, b, zn);
  input a1, a2, b;
  output zn;
  assign zn = (~a1&~b) | (~a2&~b);
endmodule

module gf180mcuf_OAI21D1(a1, a2, b, zn);
  input a1, a2, b;
  output zn;
  assign zn = (~a1&~a2) | (~b);
endmodule

module gf180mcuf_OAI211D4(a1, a2, b, c, zn);
  input a1, a2, b, c;
  output zn;
  assign zn = (~a1&~a2) | (~b) | (~c);
endmodule

module gf180mcuf_XOR2D1(a1, a2, z);
  input a1, a2;
  output z;
  assign z = (a1&~a2) | (~a1&a2);
endmodule

module gf180mcuf_XNR2D1(a1, a2, zn);
  input a1, a2;
  output zn;
  assign zn = (a1&a2) | (~a1&~a2);
endmodule

module gf180mcuf_MUX2D1(i0, i1, s, z);
  input i0, i1, s;
  output z;
  assign z = (i0&~s) | (i1&s);
endmodule

module gf180mcuf_DFQD1(d, cp, q);
  input d, cp;
  output q;
  reg ds = 1'b0;
  wire ds_INV = ~ds;
  always @(posedge (cp)) begin
    ds <= d;
  end
  assign q = ds;
endmodule

module gf180mcuf_DFCNQD1(d, cp, cdn, q);
  input d, cp, cdn;
  output q;
  reg ds = 1'b0;
  wire ds_INV = ~ds;
  always @(posedge (cp) or posedge ((~cdn))) begin
    if ((~cdn)) ds <= 1'b0;
    else ds <= d;
  end
  assign q = ds;
endmodule

module gf180mcuf_TIEH(z);
  output z;
  assign z = 1'b1;
endmodule

module gf180mcuf_TIEL(zn);
  output zn;
  assign zn = 1'b0;
endmodule


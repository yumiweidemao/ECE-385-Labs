module lookahead_adder (
	input  [15:0] A, B,
	input         cin,
	output [15:0] S,
	output        cout
);
    /* TODO
     *
     * Insert code here to implement a CLA adder.
     * Your code should be completly combinational (don't use always_ff or always_latch).
     * Feel free to create sub-modules or other files. */
	  logic c0, c1, c2;
	  logic c4, c8, c12;
	  logic pg0, pg4, pg8, pg12, gg0, gg4, gg8, gg12;
	  
	  la_adder_4 la1(.A(A[3:0]),.B(B[3:0]),.cin(cin),.S(S[3:0]),.cout(c0),.pg(pg0),.gg(gg0));
	  assign c4 = gg0 | (cin & pg0);
	  la_adder_4 la2(.A(A[7:4]),.B(B[7:4]),.cin(c4), .S(S[7:4]),.cout(c1),.pg(pg4),.gg(gg4));
	  assign c8 = gg4 | (gg0&pg4) | (cin&pg0&pg4);
	  la_adder_4 la3(.A(A[11:8]),.B(B[11:8]),.cin(c8),.S(S[11:8]),.cout(c2),.pg(pg8),.gg(gg8));
	  assign c12 = gg8 | (gg4&pg8) | (gg0&pg8&pg4) | (cin&pg8&pg4&pg0);
	  la_adder_4 la4(.A(A[15:12]),.B(B[15:12]),.cin(c12),.S(S[15:12]),.cout(cout),.pg(pg12),.gg(gg12));

endmodule


module la_adder_4 (
	input		[3:0] A, B,
	input				cin,
	output	[3:0] S,
	output			cout,
	output			pg,
	output			gg
);

	/* This is a 4-bit lookahead adder. */
	logic		c0, c1, c2, c3;
	logic [3:0] p, g;
	
	assign p = A ^ B;
	assign g = A & B;
	
	assign pg = p[0]&p[1]&p[2]&p[3];
	assign gg = g[3] | (g[2]&p[3]) | (g[1]&p[3]&p[2]) | (g[0]&p[3]&p[2]&p[1]);
	
	assign c0 = cin;
	assign c1 = (g[0]) | (cin & p[0]);
	assign c2 = (cin & p[0] & p[1]) | (g[0] & p[1]) | (g[1]);
	assign c3 = (cin&p[0]&p[1]&p[2]) | (g[0]&p[1]&p[2]) | (g[1]&p[2]) | (g[2]);
	
	full_adder fa1(.A(A[0]), .B(B[0]), .cin(c0), .S(S[0]));
	full_adder fa2(.A(A[1]), .B(B[1]), .cin(c1), .S(S[1]));
	full_adder fa3(.A(A[2]), .B(B[2]), .cin(c2), .S(S[2]));
	full_adder fa4(.A(A[3]), .B(B[3]), .cin(c3), .S(S[3]), .cout(cout));

endmodule

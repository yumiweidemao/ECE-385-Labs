module ripple_adder
(
	input  [15:0] A, B,
	input         cin,
	output [15:0] S,
	output        cout
);

    /* TODO
     *
     * Insert code here to implement a ripple adder.
     * Your code should be completly combinational (don't use always_ff or always_latch).
     * Feel free to create sub-modules or other files. */
	  logic c0, c1, c2;
	  
	  ripple_adder_4 fa1(.A(A[3:0]), .B(B[3:0]), .cin(cin), .S(S[3:0]), .cout(c0));
	  ripple_adder_4 fa2(.A(A[7:4]), .B(B[7:4]), .cin(c0),  .S(S[7:4]), .cout(c1));
	  ripple_adder_4 fa3(.A(A[11:8]), .B(B[11:8]), .cin(c1),.S(S[11:8]),.cout(c2));
	  ripple_adder_4 fa4(.A(A[15:12]), .B(B[15:12]), .cin(c2), .S(S[15:12]), .cout(cout));

     
endmodule

module ripple_adder_4
(
	input		[3:0] A, B,
	input				cin,
	output	[3:0]	S,
	output			cout
);

/* This is a 4-bit ripple adder. */
	logic		c0, c1, c2;
	
	full_adder fa1(.A (A[0]), .B (B[0]), .cin(cin), .S (S[0]), .cout(c0));
	full_adder fa2(.A (A[1]), .B (B[1]), .cin(c0),  .S (S[1]), .cout(c1));
	full_adder fa3(.A (A[2]), .B (B[2]), .cin(c1),  .S (S[2]), .cout(c2));
	full_adder fa4(.A (A[3]), .B (B[3]), .cin(c2),  .S (S[3]), .cout(cout));


endmodule

module full_adder
(
	input		A, B,
	input		cin,
	output	S,
	output	cout
);

/* This is a 1-bit full adder. */

	assign S = A^B^cin;
	assign cout = (A&B) | (B&cin) | (A&cin);


endmodule


module select_adder (
	input  [15:0] A, B,
	input         cin,
	output [15:0] S,
	output        cout
);

    /* TODO
     *
     * Insert code here to implement a CSA adder.
     * Your code should be completly combinational (don't use always_ff or always_latch).
     * Feel free to create sub-modules or other files. */
	  logic c4, c8, c12;
	  logic c1, c2, c5, c6, c9, c10;
	  
	  logic [15:0] S1, S2;
	  
	  // c8 = c1 | (c2 & c4)
	  // c12 = c5 | (c6 & c8)
	  // cout = c9 | (c10 & c12)
	  
	  ripple_adder_4 ra1(.A(A[3:0]),.B(B[3:0]),.cin(cin),.S(S[3:0]),.cout(c4));
	  ripple_adder_4 ra2(.A(A[7:4]),.B(B[7:4]),.cin(0), .S(S1[7:4]),.cout(c1));
	  ripple_adder_4 ra3(.A(A[7:4]),.B(B[7:4]),.cin(1), .S(S2[7:4]),.cout(c2));
	  ripple_adder_4 ra4(.A(A[11:8]),.B(B[11:8]),.cin(0),.S(S1[11:8]),.cout(c5));
	  ripple_adder_4 ra5(.A(A[11:8]),.B(B[11:8]),.cin(1),.S(S2[11:8]),.cout(c6));
	  ripple_adder_4 ra6(.A(A[15:12]),.B(B[15:12]),.cin(0),.S(S1[15:12]),.cout(c9));
	  ripple_adder_4 ra7(.A(A[15:12]),.B(B[15:12]),.cin(1),.S(S2[15:12]),.cout(c10));
	  
	  assign c8 = c1 | (c2 & c4);
	  assign c12 = c5 | (c6 & c8);
	  assign cout = c9 | (c10 & c12);
	  
	  always_comb
	  begin
	  
	  // choose S1 if 0, S2 if 1
	  if (c4 == 1'b0)
			S[7:4] = S1[7:4];
	  else
			S[7:4] = S2[7:4];
	
	  if (c8 == 1'b0)
			S[11:8] = S1[11:8];
	  else
			S[11:8] = S2[11:8];
			
	  if (c12 == 1'b0)
			S[15:12] = S1[15:12];
	  else
			S[15:12] = S2[15:12];
	
	  end
	  
	  
endmodule

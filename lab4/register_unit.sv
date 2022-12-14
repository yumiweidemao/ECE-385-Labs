module register_unit (input  logic Clk, Reset, X_In, A_In, B_In, Ld_X, Ld_A, Ld_B, 
                            Shift_En,
                      input  logic [7:0]  DA, DB,
							 input  logic 			DX,
                      output logic A_out, B_out, X_out,
                      output logic [7:0]  A,
                      output logic [7:0]  B,
							 output logic			X);

	 reg_1  reg_X (.*, .D(DX), .Shift_In(X_In), .Load(Ld_X),
						.Shift_Out(X_out), .Data_Out(X));
    reg_8  reg_A (.*, .D(DA), .Shift_In(A_In), .Load(Ld_A),
	               .Shift_Out(A_out), .Data_Out(A));
    reg_8  reg_B (.*, .D(DB), .Shift_In(B_In), .Load(Ld_B),
	               .Shift_Out(B_out), .Data_Out(B));

endmodule

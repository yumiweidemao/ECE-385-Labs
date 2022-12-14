//4-bit logic processor top level module
//for use with ECE 385 Spring 2021
//last modified by Zuofu Cheng


//Always use input/output logic types when possible, prevents issues with tools that have strict type enforcement

module processor (input logic   Clk,     // Internal
                                Reset_Load_Clear,   // Push button 0
										  Run,					 // Push button 1
                  input  logic [7:0]  SW,     // input data
				  //Hint for SignalTap, you want to comment out the following 2 lines to hardwire values for F and R
                  output logic 		  Xval,     // DEBUG
                  output logic [7:0]  Aval,    // DEBUG
                                Bval,    // DEBUG
                  output logic [6:0]  HEX1,
                                HEX0,
                                HEX3,
                                HEX2);

	 //local logic variables go here
	 logic Reset_Load_Clear_SH, Run_SH;
	 logic Ld_A, Ld_B, Ld_X, newA, newB, newX, opA, opB, opX, Shift_En;
	 logic [7:0] A, B, SW_S, Ain, Bin;
	 logic [8:0] F;
	 logic X, Xin;
	 logic Add, Sub, Clr_Ld, Clr_A;
	 
	 
	 //We can use the "assign" statement to do simple combinational logic
	 assign Aval = A;
	 assign Bval = B;
	 assign Xval = X;
	 
	 logic LoadAX;
	 
	 assign LoadAX = (Add | Sub | Clr_Ld | Clr_A);
	 
	 logic [7:0] S_add;
	 logic 		 S_cin;
	 
	 always_comb begin
	 
	 if (Sub == 1'b1) begin
		S_add = SW_S ^ 8'b11111111;
		S_cin = 1'b1;
	 end
	 
	 else begin
		S_add = SW_S;
		S_cin = 1'b0;
	 end
	 
	 if (Clr_Ld == 1'b1 || Clr_A) begin
		Ain = 8'b00000000;
		Xin = 1'b0;
	 end
	 
	 else begin
		Ain = F[7:0];
		Xin = F[8];
	 end
	 
	 
	 end
	 
	 //Note that you can hardwire F and R here with 'assign'. What to assign them to? Check the demo points!
	 //Remember that when you comment out the ports above, you will need to define F and R as variables
	 //uncomment the following lines when you hardwaire F and R (This was the solution to the problem during Q/A)
	 //logic [2:0] F;
	 //logic [1:0] R;
	 //assign F = 3'b010;
	 //assign R = 2'b10;
	 
	 //Instantiation of modules here
	 register_unit    reg_unit (
                        .Clk(Clk),
                        .Reset(1'b0),
                        .Ld_A(LoadAX), //note these are inferred assignments, because of the existence a logic variable of the same name
                        .Ld_B(Clr_Ld),
								.Ld_X(LoadAX),
                        .Shift_En,
								.DA(Ain),
                        .DB(SW_S),
								.DX(Xin),
                        .A_In(opX), // opX
                        .B_In(opA),
								.X_In(opX),
                        .A_out(opA),
                        .B_out(opB),
								.X_out(opX),
                        .A(A),
                        .B(B),
								.X(X));
	 nine_bit_adder	adder (
								.A({A[7], A}),
								.B({S_add[7], S_add}),
								.cin(S_cin),
								.S(F));
	 control          control_unit (
                        .Clk(Clk),
                        .Reset(Reset_Load_Clear_SH),
								.ClearALoadB(Reset_Load_Clear_SH),
                        .Run(Run_SH),
                        .M(opB),
                        .Shift_En(Shift_En),
								.Clr_Ld(Clr_Ld),
								.Clr_A(Clr_A),
                        .Sub(Sub),
                        .Add(Add));
	 HexDriver        H0 (
                        .In0(A[3:0]),
                        .Out0(HEX2) );
	 HexDriver        H2 (
                        .In0(B[3:0]),
                        .Out0(HEX0) );
								
	 //When you extend to 8-bits, you will need more HEX drivers to view upper nibble of registers, for now set to 0
	 HexDriver        H1 (
                        .In0(A[7:4]),
                        .Out0(HEX3) );	
	 HexDriver        H3 (
                       .In0(B[7:4]),
                        .Out0(HEX1) );
								
	  //Input synchronizers required for asynchronous inputs (in this case, from the switches)
	  //These are array module instantiations
	  //Note: S stands for SYNCHRONIZED, H stands for active HIGH
	  //Note: We can invert the levels inside the port assignments
	  sync button_sync[1:0] (Clk, {~Reset_Load_Clear, ~Run}, {Reset_Load_Clear_SH, Run_SH});
	  sync SW_sync[7:0] (Clk, SW, SW_S);
	  
endmodule

module reg_file(
		input logic				 Clk, Reset,
		input logic  [15:0] 	 Data_In,
		input logic  [2:0]	 DR,
		input logic     		 LD_REG,
		input logic	 [2:0]	 SR1,
		input logic  [2:0]	 SR2,
		output logic [15:0]	 SR1_OUT,
		output logic [15:0]   SR2_OUT
	);
	
	logic l0, l1, l2, l3, l4, l5, l6, l7;
	logic [15:0] out0, out1, out2, out3, out4, out5, out6, out7;
	
	reg_16 R0(.Clk(Clk), .Reset(Reset), .Load(l0), .D(Data_In), .Data_Out(out0));
	reg_16 R1(.Clk(Clk), .Reset(Reset), .Load(l1), .D(Data_In), .Data_Out(out1));
	reg_16 R2(.Clk(Clk), .Reset(Reset), .Load(l2), .D(Data_In), .Data_Out(out2));
	reg_16 R3(.Clk(Clk), .Reset(Reset), .Load(l3), .D(Data_In), .Data_Out(out3));
	reg_16 R4(.Clk(Clk), .Reset(Reset), .Load(l4), .D(Data_In), .Data_Out(out4));
	reg_16 R5(.Clk(Clk), .Reset(Reset), .Load(l5), .D(Data_In), .Data_Out(out5));
	reg_16 R6(.Clk(Clk), .Reset(Reset), .Load(l6), .D(Data_In), .Data_Out(out6));
	reg_16 R7(.Clk(Clk), .Reset(Reset), .Load(l7), .D(Data_In), .Data_Out(out7));
	
	// calculate load signals
	always_comb begin
		if (DR == 3'b000 && LD_REG == 1'b1) begin
			l0 = 1'b1;
			l1 = 1'b0;
			l2 = 1'b0;
			l3 = 1'b0;
			l4 = 1'b0;
			l5 = 1'b0;
			l6 = 1'b0;
			l7 = 1'b0;
		end
			
		else if (DR == 3'b001 && LD_REG == 1'b1) begin
			l0 = 1'b0;
			l1 = 1'b1;
			l2 = 1'b0;
			l3 = 1'b0;
			l4 = 1'b0;
			l5 = 1'b0;
			l6 = 1'b0;
			l7 = 1'b0;
		end
		
		else if (DR == 3'b010 && LD_REG == 1'b1) begin
			l0 = 1'b0;
			l1 = 1'b0;
			l2 = 1'b1;
			l3 = 1'b0;
			l4 = 1'b0;
			l5 = 1'b0;
			l6 = 1'b0;
			l7 = 1'b0;
		end
		
		else if (DR == 3'b011 && LD_REG == 1'b1) begin
			l0 = 1'b0;
			l1 = 1'b0;
			l2 = 1'b0;
			l3 = 1'b1;
			l4 = 1'b0;
			l5 = 1'b0;
			l6 = 1'b0;
			l7 = 1'b0;
		end
		
		else if (DR == 3'b100 && LD_REG == 1'b1) begin
			l0 = 1'b0;
			l1 = 1'b0;
			l2 = 1'b0;
			l3 = 1'b0;
			l4 = 1'b1;
			l5 = 1'b0;
			l6 = 1'b0;
			l7 = 1'b0;
		end
		
		else if (DR == 3'b101 && LD_REG == 1'b1) begin
			l0 = 1'b0;
			l1 = 1'b0;
			l2 = 1'b0;
			l3 = 1'b0;
			l4 = 1'b0;
			l5 = 1'b1;
			l6 = 1'b0;
			l7 = 1'b0;
		end
		
		else if (DR == 3'b110 && LD_REG == 1'b1) begin
			l0 = 1'b0;
			l1 = 1'b0;
			l2 = 1'b0;
			l3 = 1'b0;
			l4 = 1'b0;
			l5 = 1'b0;
			l6 = 1'b1;
			l7 = 1'b0;
		end
		
		else if (DR == 3'b111 && LD_REG == 1'b1) begin
			l0 = 1'b0;
			l1 = 1'b0;
			l2 = 1'b0;
			l3 = 1'b0;
			l4 = 1'b0;
			l5 = 1'b0;
			l6 = 1'b0;
			l7 = 1'b1;
		end
		
		else begin
			l0 = 1'b0;
			l1 = 1'b0;
			l2 = 1'b0;
			l3 = 1'b0;
			l4 = 1'b0;
			l5 = 1'b0;
			l6 = 1'b0;
			l7 = 1'b0;
		end
	end
	
	// calculate out signals
	always_comb begin
		if (SR1 == 3'b000)
			SR1_OUT = out0;
		else if (SR1 == 3'b001)
			SR1_OUT = out1;
		else if (SR1 == 3'b010)
			SR1_OUT = out2;
		else if (SR1 == 3'b011)
			SR1_OUT = out3;
		else if (SR1 == 3'b100)
			SR1_OUT = out4;
		else if (SR1 == 3'b101)
			SR1_OUT = out5;
		else if (SR1 == 3'b110)
			SR1_OUT = out6;
		else if (SR1 == 3'b111)
			SR1_OUT = out7;
		else
			SR1_OUT = 16'h0000;
			
		if (SR2 == 3'b000)
			SR2_OUT = out0;
		else if (SR2 == 3'b001)
			SR2_OUT = out1;
		else if (SR2 == 3'b010)
			SR2_OUT = out2;
		else if (SR2 == 3'b011)
			SR2_OUT = out3;
		else if (SR2 == 3'b100)
			SR2_OUT = out4;
		else if (SR2 == 3'b101)
			SR2_OUT = out5;
		else if (SR2 == 3'b110)
			SR2_OUT = out6;
		else if (SR2 == 3'b111)
			SR2_OUT = out7;
		else
			SR2_OUT = 16'h0000;
	end
	

endmodule

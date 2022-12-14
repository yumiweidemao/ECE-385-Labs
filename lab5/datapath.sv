module datapath(
		input logic Clk, Reset,
		input logic LD_MAR, LD_MDR, LD_IR, LD_BEN, LD_CC, LD_REG, LD_PC, LD_LED,
		input logic GatePC, GateMDR, GateALU, GateMARMUX,
		input logic SR2MUX, ADDR1MUX, MARMUX,
		input logic MIO_EN, DRMUX, SR1MUX,
		input logic [1:0] PCMUX, ADDR2MUX, ALUK,
		input logic [15:0] MDR_In,
		output logic BEN,
		output logic [15:0] MAR, MDR, IR, PC
	);
	
	logic [15:0] bus;
	logic	[15:0] PC_out, MDR_out, PC_in, MDR_in;
	logic [15:0] SR1_OUT, SR2_OUT, SR2MUX_OUT, ALU_out;
	logic [15:0] ADDR1MUX_OUT, ADDR2MUX_OUT, ADDR_ADDER_OUT;
	
	logic [2:0]	DR, SR1, SR2;
	
	assign MDR = MDR_out;
	assign PC = PC_out;
	
	reg_16 MAR0(.Clk(Clk), .Reset(Reset), .Load(LD_MAR), .D(bus), .Data_Out(MAR));
	reg_16 MDR0(.Clk(Clk), .Reset(Reset), .Load(LD_MDR), .D(MDR_in), .Data_Out(MDR_out));
	reg_16 IR0(.Clk(Clk), .Reset(Reset), .Load(LD_IR), .D(bus), .Data_Out(IR));
	reg_16 PC0(.Clk(Clk), .Reset(Reset), .Load(LD_PC), .D(PC_in), .Data_Out(PC_out));
	
	
	reg_file reg_file0(.Clk(Clk), .Reset(Reset), .Data_In(bus), .DR(DR), .LD_REG(LD_REG),
							 .SR1(SR1), .SR2(SR2), .SR1_OUT(SR1_OUT), .SR2_OUT(SR2_OUT));
	
	ALU ALU0(.A(SR1_OUT), .B(SR2MUX_OUT), .ALUK(ALUK), .ALU_out(ALU_out));
	
	// calculate bus
	always_comb begin
		if (GatePC == 1'b1)
			bus = PC_out;
		else if (GateMDR == 1'b1)
			bus = MDR_out;
		else if (GateALU == 1'b1)
			bus = ALU_out;
		else if (GateMARMUX == 1'b1)
			bus = ADDR_ADDER_OUT;
		else
			bus = 16'bxxxxxxxxxxxxxxxx;
	end
	
	// calculate MDR_in
	always_comb begin
		if (MIO_EN == 1'b0)
			MDR_in = bus;
		else if (MIO_EN == 1'b1)
			MDR_in = MDR_In; // this is connected to MEM2IO::data_to_CPU
		else
			MDR_in = 16'bxxxxxxxxxxxxxxxx;
	end
	
	// calculate PC_in
	always_comb begin
		if (PCMUX == 2'b00)
			PC_in = PC_out + 16'h0001;
		else if (PCMUX == 2'b01)
			PC_in = bus;
		else if (PCMUX == 2'b10)
			PC_in = ADDR_ADDER_OUT;
		else
			PC_in = 16'bxxxxxxxxxxxxxxxx;
	end
	
	// DRMUX implementation
	always_comb begin
		if (DRMUX == 1'b0)
			DR = IR[11:9];
		else if (DRMUX == 1'b1)
			DR = 3'b111;
		else
			DR = 3'bxxx;
	end
	
	// SR1MUX implementation
	always_comb begin
		if (SR1MUX == 1'b0)
			SR1 = IR[11:9];
		else if (SR1MUX == 1'b1)
			SR1 = IR[8:6];
		else
			SR1 = 3'bxxx;
	end
	
	// SR2 connected to IR[2:0]
	assign SR2 = IR[2:0];
	
	// SR2MUX implementation
	always_comb begin
		if (SR2MUX == 1'b0)
			SR2MUX_OUT = SR2_OUT;
		else if (SR2MUX == 1'b1) begin
			// sign extension of IR[4:0]
			logic [10:0] sign_bits;
			if (IR[4] == 1'b0)
				sign_bits = 11'b00000000000;
			else if (IR[4] == 1'b1)
				sign_bits = 11'b11111111111;
			else
				sign_bits = 11'bxxxxxxxxxxx;
			SR2MUX_OUT = {sign_bits, IR[4:0]};
		end
		else
			SR2MUX_OUT = 16'bxxxxxxxxxxxxxxxx;
	end
	
	// register for NZP
	logic [2:0] nzp;
	logic [2:0] new_nzp;
	
	always_ff @ (posedge Clk) begin
		if (LD_CC == 1'b1)
			nzp <= new_nzp;
	end
	
	always_comb begin
		if (bus == 16'h0000)
			new_nzp = 3'b010;
		else if (bus[15] == 1)
			new_nzp = 3'b100;
		else if (bus[15] == 0)
			new_nzp = 3'b001;
		else
			new_nzp = 3'bxxx;
	end
	
	// register for BEN
	logic		ben;
	logic		new_ben;
	
	always_ff @ (posedge Clk) begin
		if (LD_BEN == 1'b1)
			ben <= new_ben;
	end
	
	always_comb begin
		logic [2:0]	result;
		result = IR[11:9] & nzp;
		if (result == 3'b000)
			new_ben = 1'b0;
		else
			new_ben = 1'b1;
	end
	
	assign BEN = ben;
	
	// ADDR1MUX implementation
	always_comb begin
		if (ADDR1MUX == 1'b0)
			ADDR1MUX_OUT = PC_out;
		else
			ADDR1MUX_OUT = SR1_OUT;
	end
	
	// ADDR2MUX implementation
	always_comb begin
		if (ADDR2MUX == 2'b00)
			ADDR2MUX_OUT = 16'h0000;
		else if (ADDR2MUX == 2'b01)
			ADDR2MUX_OUT = {IR[5],IR[5],IR[5],IR[5],IR[5],IR[5],IR[5],IR[5],IR[5],IR[5], IR[5:0]};
		else if (ADDR2MUX == 2'b10)
			ADDR2MUX_OUT = {IR[8],IR[8],IR[8],IR[8],IR[8],IR[8],IR[8], IR[8:0]};
		else
			ADDR2MUX_OUT = {IR[10],IR[10],IR[10],IR[10],IR[10],IR[10:0]};
	end
	
	// ADDR_ADDER_OUT
	assign ADDR_ADDER_OUT = ADDR1MUX_OUT + ADDR2MUX_OUT;
	
	
endmodule

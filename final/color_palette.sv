module color_palette(
	input logic [3:0] index,
	input logic blank,
	output logic [7:0] Red, Green, Blue
);

	logic [23:0] palette_reg [16];
	
	assign palette_reg[0] = 24'h7E7E7E; // (background) dark grey
	assign palette_reg[1] = 24'hFCA044; // light orange
	assign palette_reg[2] = 24'h6A9455; // green
	assign palette_reg[3] = 24'hD5925E; // orange-red
	assign palette_reg[4] = 24'h1EB21E; // green
	assign palette_reg[5] = 24'hDB0000; // pure red 
	assign palette_reg[6] = 24'h9B3D00; // brown
	assign palette_reg[7] = 24'hFFE303; // yellow
	assign palette_reg[8] = 24'hF0D0B0; // light grey orange
	assign palette_reg[9] = 24'h48FF3B; // light green
	assign palette_reg[10] = 24'h42B8FF;// light blue
	assign palette_reg[11] = 24'hFCFCFC;// white
	assign palette_reg[12] = 24'h422A00;// dark brown
	assign palette_reg[13] = 24'hA40000;// dark red
	assign palette_reg[14] = 24'hD82800;// lighter dark red
	assign palette_reg[15] = 24'hCBD8DE;// light grey
	
	always_comb begin
		if (blank == 1'b0) begin
			Red = 8'h00;
			Green = 8'h00;
			Blue = 8'h00;
		end
		
		else begin
			Red = palette_reg[index][23:16];
			Green = palette_reg[index][15:8];
			Blue = palette_reg[index][7:0];
		end
	end
	
endmodule

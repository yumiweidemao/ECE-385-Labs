/************************************************************************
Avalon-MM Interface VGA Text mode display

Register Map:
0x000-0x0257 : VRAM, 80x30 (2400 byte, 600 word) raster order (first column then row)
0x258        : control register

VRAM Format:
X->
[ 31  30-24][ 23  22-16][ 15  14-8 ][ 7    6-0 ]
[IV3][CODE3][IV2][CODE2][IV1][CODE1][IV0][CODE0]

IVn = Draw inverse glyph
CODEn = Glyph code from IBM codepage 437

Control Register Format:
[[31-25][24-21][20-17][16-13][ 12-9][ 8-5 ][ 4-1 ][   0    ] 
[[RSVD ][FGD_R][FGD_G][FGD_B][BKG_R][BKG_G][BKG_B][RESERVED]

VSYNC signal = bit which flips on every Vsync (time for new frame), used to synchronize software
BKG_R/G/B = Background color, flipped with foreground when IVn bit is set
FGD_R/G/B = Foreground color, flipped with background when Inv bit is set

************************************************************************/

module vga_text_avl_interface (
	// Avalon Clock Input, note this clock is also used for VGA, so this must be 50Mhz
	// We can put a clock divider here in the future to make this IP more generalizable
	input logic CLK,
	
	// Avalon Reset Input
	input logic RESET,
	
	// Avalon-MM Slave Signals
	input  logic AVL_READ,					// Avalon-MM Read
	input  logic AVL_WRITE,					// Avalon-MM Write
	input  logic AVL_CS,					// Avalon-MM Chip Select
	input  logic [3:0] AVL_BYTE_EN,			// Avalon-MM Byte Enable
	input  logic [11:0] AVL_ADDR,			// Avalon-MM Address
	input  logic [31:0] AVL_WRITEDATA,		// Avalon-MM Write Data
	output logic [31:0] AVL_READDATA,		// Avalon-MM Read Data
	
	// Exported Conduit (mapped to VGA port - make sure you export in Platform Designer)
	output logic [3:0]  red, green, blue,	// VGA color channels (mapped to output pins in top-level)
	output logic hs, vs						// VGA HS/VS
);

// Control Register
logic [31:0] CTRL_REG [7:0];


//put other local variables here

// VGA variables
logic VGA_Clk, blank, sync;
logic [9:0] drawX, drawY;
logic [3:0] new_red, new_green, new_blue;
// ROM variables
logic [10:0] rom_addr;
logic [7:0] rom_data;
logic [3:0] BR, BG, BB, FR, FG, FB;

//Declare submodules..e.g. VGA controller, ROMS, etc
vga_controller vga_controller0(.Clk(CLK), .Reset(RESET), .hs(hs), .vs(vs), .pixel_clk(VGA_Clk),
										 .blank(blank), .sync(sync), .DrawX(drawX), .DrawY(drawY));
font_rom font_rom0(.addr(rom_addr), .data(rom_data));
   
// Read and write from AVL interface to register block, note that READ waitstate = 1, so this should be in always_ff
always_ff @(posedge CLK or posedge RESET) begin
	if (RESET) begin
		integer i;
		for (i = 0; i < 8; i=i+1) CTRL_REG[i] <= 32'h00000000;
	end
	
	else begin
		// check if control reg is being written
		if ((AVL_ADDR - 12'h800) >= 0 && AVL_WRITE == 1'b1) begin
			if (AVL_BYTE_EN[3])
				CTRL_REG[AVL_ADDR - 12'h800][31:24] <= AVL_WRITEDATA[31:24];
			if (AVL_BYTE_EN[2])
				CTRL_REG[AVL_ADDR - 12'h800][23:16] <= AVL_WRITEDATA[23:16];
			if (AVL_BYTE_EN[1])
				CTRL_REG[AVL_ADDR - 12'h800][15:8] <= AVL_WRITEDATA[15:8];
			if (AVL_BYTE_EN[0])
				CTRL_REG[AVL_ADDR - 12'h800][7:0] <= AVL_WRITEDATA[7:0];
		end
	end
end



//handle drawing (may either be combinational or sequential - or both).

logic [4:0] row;
logic [6:0] col;
logic [2:0] posX;
logic [3:0] posY;

always_comb begin
	posX = drawX[2:0];
	posY = drawY[3:0];
	col = (drawX >> 3);
	row = (drawY >> 4);
end

logic byteSelect;
logic [10:0] regAddr;
logic [6:0] code;
logic iv;
logic [3:0] fgd_idx, bgd_idx;

always_comb begin
	byteSelect = (row * 80 + col);
	regAddr = ((row * 80 + col) >> 1);
end


always_comb begin
	unique case (byteSelect)
		1'b1: begin
			code = AVL_READDATA[30:24];
			iv = AVL_READDATA[31];
			fgd_idx = AVL_READDATA[23:20];
			bgd_idx = AVL_READDATA[19:16];
		end
		1'b0: begin
			code = AVL_READDATA[14:8];
			iv = AVL_READDATA[15];
			fgd_idx = AVL_READDATA[7:4];
			bgd_idx = AVL_READDATA[3:0];
		end
	endcase
end

logic fs, bs;
logic [2:0] fn, bn;
always_comb begin
	// reg no. = idx // 2
	fs = fgd_idx[0];
	bs = bgd_idx[0];
	
	fn = fgd_idx >> 1;
	bn = bgd_idx >> 1;
	
	if (fs == 1'b0) begin
		FR = CTRL_REG[fn][12:9];
		FG = CTRL_REG[fn][8:5];
		FB = CTRL_REG[fn][4:1];
	end
	else begin
		FR = CTRL_REG[fn][24:21];
		FG = CTRL_REG[fn][20:17];
		FB = CTRL_REG[fn][16:13];
	end
	
	if (bs == 1'b0) begin
		BR = CTRL_REG[bn][12:9];
		BG = CTRL_REG[bn][8:5];
		BB = CTRL_REG[bn][4:1];
	end
	else begin
		BR = CTRL_REG[bn][24:21];
		BG = CTRL_REG[bn][20:17];
		BB = CTRL_REG[bn][16:13];
	end
end

logic pixel;

assign rom_addr = {code, posY};
assign pixel = rom_data[7-posX];


always_comb begin
	if (blank == 1'b0) begin
		new_red = 4'b0000;
		new_green = 4'b0000;
		new_blue = 4'b0000;
	end
	
	else begin
		if (iv ^ pixel) begin
			new_red = FR; // Foreground
			new_green = FG;
			new_blue = FB;
		end
		else begin
			new_red = BR; // Background
			new_green = BG;
			new_blue = BB;
		end
	end
end

always_ff @ (posedge VGA_Clk) begin
	red <= new_red;
	blue <= new_blue;
	green <= new_green;
end

// instantiate ram module
assign wren = AVL_WRITE & AVL_CS; // write only happens when chip is selected

logic [11:0] addr;

always_comb begin
	if (AVL_READ | wren)
		addr = AVL_ADDR;
	else
		addr = regAddr;
end


ram ram0(.address(addr), .byteena(AVL_BYTE_EN), .clock(CLK), 
			.data(AVL_WRITEDATA), .wren(wren), .q(AVL_READDATA));

endmodule

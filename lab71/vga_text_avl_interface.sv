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
`define NUM_REGS 601 //80*30 characters / 4 characters per register
`define CTRL_REG 600 //index of control register

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
	input  logic [9:0] AVL_ADDR,			// Avalon-MM Address
	input  logic [31:0] AVL_WRITEDATA,		// Avalon-MM Write Data
	output logic [31:0] AVL_READDATA,		// Avalon-MM Read Data
	
	// Exported Conduit (mapped to VGA port - make sure you export in Platform Designer)
	output logic [3:0]  red, green, blue,	// VGA color channels (mapped to output pins in top-level)
	output logic hs, vs						// VGA HS/VS
);

logic [31:0] LOCAL_REG       [`NUM_REGS]; // Registers
//put other local variables here
// VGA variables
logic VGA_Clk, blank, sync;
logic [9:0] drawX, drawY;
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
		for (i=0; i<`NUM_REGS; i=i+1) LOCAL_REG[i] <= 32'h00000000;
	end
	
	else begin
	if (AVL_CS == 1'b1) begin
		if (AVL_READ == 1'b1) begin
			AVL_READDATA <= LOCAL_REG[AVL_ADDR];
		end
		else
			AVL_READDATA <= 32'h00000000;
		
		if (AVL_WRITE == 1'b1) begin
			if (AVL_BYTE_EN[0])
				LOCAL_REG[AVL_ADDR][7:0] = AVL_WRITEDATA[7:0];
			if (AVL_BYTE_EN[1])
				LOCAL_REG[AVL_ADDR][15:8] = AVL_WRITEDATA[15:8];
			if (AVL_BYTE_EN[2])
				LOCAL_REG[AVL_ADDR][23:16] = AVL_WRITEDATA[23:16];
			if (AVL_BYTE_EN[3])
				LOCAL_REG[AVL_ADDR][31:24] = AVL_WRITEDATA[31:24];
		end
	end
	end
end



//handle drawing (may either be combinational or sequential - or both).

assign FR = LOCAL_REG[`CTRL_REG][24:21];
assign FG = LOCAL_REG[`CTRL_REG][20:17];
assign FB = LOCAL_REG[`CTRL_REG][16:13];
assign BR = LOCAL_REG[`CTRL_REG][12:9];
assign BG = LOCAL_REG[`CTRL_REG][8:5];
assign BB = LOCAL_REG[`CTRL_REG][4:1];

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

logic [1:0] byteSelect;
logic [9:0] regAddr;
logic [6:0] code;
logic iv;

always_comb begin
	byteSelect = (row * 80 + col);
	regAddr = ((row * 80 + col) >> 2);
	
	unique case (byteSelect)
		2'b11: begin
			code = LOCAL_REG[regAddr][30:24];
			iv = LOCAL_REG[regAddr][31];
		end
		2'b10: begin
			code = LOCAL_REG[regAddr][22:16];
			iv = LOCAL_REG[regAddr][23];
		end
		2'b01: begin
			code = LOCAL_REG[regAddr][14:8];
			iv = LOCAL_REG[regAddr][15];
		end
		2'b00: begin
			code = LOCAL_REG[regAddr][6:0];
			iv = LOCAL_REG[regAddr][7];
		end
	endcase
end

logic pixel;

assign rom_addr = {code, posY};
assign pixel = rom_data[7-posX];


always_comb begin
	if (blank == 1'b0) begin
		red = 4'b0000;
		green = 4'b0000;
		blue = 4'b0000;
	end
	
	else begin
		if (iv ^ pixel) begin
			red = FR; // Foreground
			green = FG;
			blue = FB;
		end
		else begin
			red = BR; // Background
			green = BG;
			blue = BB;
		end
	end
end


endmodule

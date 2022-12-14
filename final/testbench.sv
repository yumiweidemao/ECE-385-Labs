module testbench();

timeunit 10ns;

timeprecision 1ns;

logic frame_clk = 0;

// create game instance
logic [9:0] character_pos_x;
logic [8:0] character_pos_y;
logic [10:0] screen_pos;
logic big, idle, walk1, walk2, walk3, jump, direction, lose, transition;
logic [15:0] keycode;
logic [35:0] coin;
logic [5:0] score;
logic [3:0] game_state;
logic reset;
				
		
// Instantiating the DUT
// Make sure the module and signal names match with those in your design
game game0(.*);

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1 frame_clk = ~frame_clk;
end

initial begin: CLOCK_INITIALIZATION
    frame_clk = 0;
end

// Testing begins here
// The initial block is not synthesizable
// Everything happens sequentially inside an initial block
// as in a software program
initial begin: TEST_VECTOR
reset = 1; // reset all parameters

/* Test jump, dir
#2 reset = 0;

#8 keycode = 16'h07; // D

#20 keycode = {8'h1A, 8'h07}; // D + W
#6 keycode = 0;

#10 keycode = 16'h04; // A
#16 keycode = 0;

#4 keycode = 16'h07;
#30 keycode = 0;
*/

#2 reset = 0;

#2 keycode = 16'h07;
#690 keycode = 0;

#2 keycode = 16'h1A;
#2 keycode = 0;
end

endmodule

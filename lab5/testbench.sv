module testbench();

timeunit 10ns;

timeprecision 1ns;

logic Clk = 0;
logic Run, Continue;
logic [9:0] SW;
logic [9:0] LED;
logic [6:0] HEX0,
		 HEX1,
		 HEX2,
		 HEX3; 

logic [15:0] MDR, MAR, PC, IR;
logic [3:0] current_state; // delete this later

	
		
// Instantiating the DUT
// Make sure the module and signal names match with those in your design
slc3_testtop slc3_testtop0(.*);

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1 Clk = ~Clk;
end

initial begin: CLOCK_INITIALIZATION
    Clk = 0;
end

// Testing begins here
// The initial block is not synthesizable
// Everything happens sequentially inside an initial block
// as in a software program


initial begin: TEST_VECTORS

Continue = 0;
Run = 0;

SW = 10'd26;

#2 Run = 1;
	Continue = 1;

#18	 Run = 0;  // toggle run, load CLR R0
#2		 Run = 1;

#18	 Continue = 0;
#2		 Continue = 1; // toggle continue, read SW value

#18	 Continue = 0;
#2		 Continue = 1; // toggle continue, now IR is JMP

#18	 Continue = 0;
#2		 Continue = 1;	// toggle continue, now IR is the opcode at addr=SW

#4		Run = 1;

#18	Continue = 0;
#2 	Continue = 1;

end

endmodule

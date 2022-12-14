module testbench();

timeunit 10ns;

timeprecision 1ns;

logic Clk = 0;
logic Run, Reset_Load_Clear;
logic [7:0] SW;
logic Xval;
logic [7:0] Aval,
		 Bval;
logic [6:0] HEX0,
		 HEX1,
		 HEX2,
		 HEX3; 

// To store expected results
logic [15:0] ans;
				
		
// Instantiating the DUT
// Make sure the module and signal names match with those in your design
processor processor0(.*);	

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
Reset_Load_Clear = 0;		// Toggle Rest
Run = 1;
SW = 8'hFE;	// Specify Din, F, and R

#2 Reset_Load_Clear = 1;

#2 SW = 8'h8C;
   
#22 Run = 1;

#2 Run = 0;	// Toggle Execute
#2 Run = 1;
end

endmodule

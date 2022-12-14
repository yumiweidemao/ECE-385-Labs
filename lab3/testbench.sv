module testbench();

timeunit 10ns;

timeprecision 1ns;

logic Clk = 0;
logic Run_Accumulate, Reset_Clear;
logic [9:0] SW;
logic [9:0] LED;
logic [6:0] HEX0,
		 HEX1,
		 HEX2,
		 HEX3,
		 HEX4,
		 HEX5; 
logic [16:0] Adder_val, Out_val;

logic [16:0] ans;

assign ans = 10'b0011001101 + 10'b0001010011; // correct answer
				
		
// Instantiating the DUT
// Make sure the module and signal names match with those in your design
adder2 adder2_0(.*);	

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
Reset_Clear = 0;		// Toggle Rest
Run_Accumulate = 1;
SW = 10'b0011001101;	// initial value is 205 (decimal)

#2 Reset_Clear = 1;
   
#10 Run_Accumulate = 1;

#2 Run_Accumulate = 0;	// Load initial value
#2 Run_Accumulate = 1;

#2 SW = 10'b0001010011; // second value is 83 (decimal)

#10 Run_Accumulate = 1;

#2 Run_Accumulate = 0; // perform addition: result should be 288 (9b'100100000)
#2 Run_Accumulate = 1;

end

endmodule

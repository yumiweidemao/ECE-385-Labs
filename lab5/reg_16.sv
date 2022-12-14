module reg_16 (input  logic Clk, Reset, Load,
              input  logic [15:0]  D,
              output logic [15:0]  Data_Out);

    always_ff @ (posedge Clk)
    begin
	 	 if (Reset) //notice, this is a sycnrhonous reset, which is recommended on the FPGA
			  Data_Out <= 16'h0000;
		 //else if (Load && Shift_En)
			//  Data_Out <= { Shift_In, D[7:1] }; // change
		 else if (Load)
			  Data_Out <= D;
    end

endmodule

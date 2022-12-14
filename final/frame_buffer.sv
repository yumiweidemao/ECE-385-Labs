/*
 * ECE385-HelperTools/PNG-To-Txt
 * Author: Rishi Thakkar
 *
 */

module frame_buffer
(
		input [3:0] data_In,
		input [18:0] write_address, read_address,
		input we, Clk,

		output logic [3:0] data_Out
);

logic [3:0] mem [0:307199]; // 640 * 480 words

always_ff @ (posedge Clk) begin
	if (we)
		mem[write_address] <= data_In;
	data_Out<= mem[read_address];
end

endmodule

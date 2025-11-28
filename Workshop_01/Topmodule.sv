module Topmodule #(
	parameter int WIDTH = 4
)(
	input logic clk_i, rst_i, en_reg_a_i, en_reg_b_i,
	input logic [1:0] cntrl_alu_i,
	input logic [WIDTH-1:0] op_A, op_B,
	
	output logic [3:0] result_o,
	output logic carry_o
	);
	
	// Internal Variables
	logic [WIDTH-1:0] reg_a, reg_b, result;
	
	//Sequential Logic
	always_ff @(posedge clk_i) begin
		if (!rst_i) begin
			reg_a <= 0;
			reg_b <= 0;
		end else begin
			if (!en_reg_a_i) reg_a <= op_A;
			if (!en_reg_b_i) reg_b <= op_B;
		end
	end
	
	// Instance
	ALU_DUT #(
		.WIDTH(WIDTH)
	) ALU (
		.cntrl_alu_i(cntrl_alu_i),
		.reg_a_i(reg_a),
		.reg_b_i(reg_b),
		.carry_o(carry_o),
		.result_o(result_o)
	);

	endmodule
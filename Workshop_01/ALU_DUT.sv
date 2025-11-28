module ALU_DUT #(
    parameter int WIDTH = 8
  )(
    input  logic [1:0]        cntrl_alu_i,
    input  logic [WIDTH-1:0]  reg_a_i,
										reg_b_i,

    output logic              carry_o,
    output logic [WIDTH-1:0]             result_o
  );
  
  // Internal variable
  logic		[WIDTH:0]		result;
  logic 							overflow;
  
  // ALU - Combinational logic
  always_comb begin
    case(cntrl_alu_i)
      0: result = reg_a_i + reg_b_i;	//add
      1: result = reg_a_i - reg_b_i;	//sub
      2: result = reg_a_i & reg_b_i;	//and
      3: result = reg_a_i | reg_b_i;	//or
      default:	result = 'b0;
    endcase
  end
        
  // Output logic
  always_comb begin
    result_o = result[WIDTH-1:0];
    carry_o = result[WIDTH];
  end

endmodule
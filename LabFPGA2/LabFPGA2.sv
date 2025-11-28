`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: TEC
// Engineer: Carlos Andrey Morales Zamora
// 
// Create Date: 07.03.2025
// Design Name: 
// Module Name: ALU_DUT
// Project Name: LabFPGA2
// 
//////////////////////////////////////////////////////////////////////////////////

module LabFPGA2 #(
	parameter int WIDTH = 24,
	parameter int DIVIDER = 20e6
)(
	input		logic					clk_i,
										rst_i,
										en_reg_i,
										sw_reg_b_i,
										slct_op_i,
										slct_byte_i,
										slct_sb_i,
	input		logic	[3:0]			cntrl_alu_i,
	input		logic	[3:0]			op_i,		
	output	logic	[3:0]			flag_o,
	output	logic	[41:0]		display_o,
	output	logic	[1:0]			counter_slct_op_o,
										counter_slct_byte_o,
	output 	logic					sb_op_o
						
);
	
	//Internal variables
	logic	[WIDTH-1:0]	reg_a, reg_b, result;
	logic [23:0] display;
	logic [1:0] counter_slct_byte, counter_slct_op;
	logic en_reg, slct_sb, sb_op, slct_byte, slct_op;
	logic en_slct_sb, en_slct_byte;
	
	assign counter_slct_op_o = counter_slct_op;
	assign counter_slct_byte_o = counter_slct_byte;
	assign sb_op_o = sb_op;
	
	//Logic counter select column operand
	always_ff @(posedge clk_i) begin
		if(!rst_i) begin counter_slct_byte <= 0; en_slct_sb <= 0; end
		else begin
			if(en_slct_byte) counter_slct_byte <= 0;
			else begin
				if(slct_byte) begin
					en_slct_sb <= 1;
					if(counter_slct_byte == 2) counter_slct_byte <= 0;
					else counter_slct_byte <= counter_slct_byte + 1;
				end else en_slct_sb <= 0;
			end	
		end
	end
	
	//Logic select operand
	always_ff @(posedge clk_i) begin
		if(!rst_i) begin counter_slct_op <= 0;	en_slct_byte <= 0; end
		else begin
			if(slct_op) begin
				en_slct_byte <=1;
				if(counter_slct_op == 2) counter_slct_op <= 0;
				else counter_slct_op <= counter_slct_op + 1;
			end else en_slct_byte <= 0;
		end
	end
	
	//Logic select sb data
	always_ff @(posedge clk_i) begin
		if(!rst_i) sb_op <= 0;
		else begin
			if(en_slct_sb) sb_op <= 0;
			else if(slct_sb) sb_op <= ~sb_op;
		end
	end
	
	always_comb begin
		case(counter_slct_op) 
			2'b00: display = reg_a;
			2'b01: display = reg_b;
			2'b10: display = result;
			default: display = 0;
		endcase
	end
	
	//Register logic
	always_ff @(posedge clk_i) begin
		if(!rst_i) begin
			reg_a <= 0;
			reg_b <= 0;
		end else begin
			if(en_reg && counter_slct_op[0] == 1'b0) begin
				case(counter_slct_byte)
					2'b00: reg_a <= sb_op ? {reg_a[23:8], op_i, reg_a[3:0]} : {reg_a[23:4], op_i};
					2'b01: reg_a <= sb_op ? {reg_a[23:16], op_i, reg_a[11:0]} : {reg_a[23:12], op_i, reg_a[7:0]};
					2'b10: reg_a <= sb_op ? {op_i, reg_a[19:0]} : {reg_a[23:20], op_i, reg_a[15:0]};
					default: reg_a <= 0;
				endcase
			end	
			if(en_reg && counter_slct_op[0] == 1'b1) begin
				if(!sw_reg_b_i) begin 
					case(counter_slct_byte)
						2'b00: reg_b <= sb_op ? {reg_b[23:8], op_i, reg_b[3:0]} : {reg_b[23:4], op_i};
						2'b01: reg_b <= sb_op ? {reg_b[23:16], op_i, reg_b[11:0]} : {reg_b[23:12], op_i, reg_b[7:0]};
						2'b10: reg_b <= sb_op ? {op_i, reg_b[19:0]} : {reg_b[23:20], op_i, reg_b[15:0]};
						default: reg_b <= 0;
					endcase
				end else reg_b <= result;
			end
		end
	end
	
	ALU_DUT #(
		.WIDTH(WIDTH)
	) ALU (
		.cntrl_alu_i(cntrl_alu_i),
		.reg_a_i(reg_a),
		.reg_b_i(reg_b),
		.flag_o(flag_o),
		.result_o(result)	
	);
	
	seg7_control seg7_crtl (
      .display_i(display),
      .display_o(display_o)
   );
	
	genvar i;
	generate
	  for (i = 0; i < 4; i++) begin : gen_debounce
		 logic btn_in, btn_out;

		 // Asignaciones para cada instancia
		 always_comb begin
			case (i)
			  0: begin btn_in = en_reg_i;      en_reg      = btn_out; end
			  1: begin btn_in = slct_op_i;     slct_op     = btn_out; end
			  2: begin btn_in = slct_byte_i;   slct_byte   = btn_out; end
			  3: begin btn_in = slct_sb_i;     slct_sb     = btn_out; end
			  default: begin btn_in = 1'b0;    /* default case */     end
			endcase
		 end

		 debounce #(.DIVIDER(DIVIDER)) debouncer (
			.clk_i(clk_i),
			.rst_i(rst_i),
			.btn_i(btn_in),
			.btn_o(btn_out)
		 );
		 
	  end
	endgenerate
	
endmodule



module ALU_DUT #(
	parameter int WIDTH = 8
)(
	input		logic	[3:0]			cntrl_alu_i,
	input		logic	[WIDTH-1:0]	reg_a_i,
										reg_b_i,
	output	logic	[3:0]			flag_o,
	output	logic	[WIDTH-1:0]	result_o								
);
	
	//Internal variables
	logic	[WIDTH:0] result;
	
	//ALU logic
	always_comb begin
		case(cntrl_alu_i)
			0:	result = reg_a_i + reg_b_i;				//add
			1: result = reg_a_i - reg_b_i;            //sub
			2: result = reg_a_i + 1;            		//increase
			3: result = reg_a_i - 1;						//decrease
         4: result = reg_a_i & reg_b_i;            //and
         5: result = reg_a_i || reg_b_i;           //or
			6: result = ~(~reg_a_i);						//not a
			7: result = ~(reg_b_i);							//not b
			8:	result = ~(reg_a_i & reg_b_i);			//nand
			9:	result = reg_a_i ^ reg_b_i;				//xor
			10: result = reg_a_i ~^ ~reg_b_i;			//xnor
         11: result = reg_a_i << reg_b_i;     		//sll
         12: result = reg_a_i >> reg_b_i;     		//srl   
         13: begin                              	//slt (less than)
					if(reg_a_i < reg_b_i) result = 1;
               else result = 0;
            end
         14: begin                               //  (greater than or equal to)
               if(reg_b_i <= reg_a_i ) result = 1;
               else result = 0;
               end
         default : result = 'b0;
		endcase
	end
	
	//Flag logic
	always_comb begin
		//flag_o[0] = Z
		flag_o[0] = (result == 0);
		//flag_o[1] = S
		flag_o[1] = result[WIDTH-1];  //1 if negative
		//flag_o[2] = O
		flag_o[2] = result[WIDTH];
		//flag_o[3] = C
		flag_o[3] = result[WIDTH];
	end

	//Output logic
	always_comb begin
		result_o = result[WIDTH-1:0];
	end
	
endmodule

module seg7_control(
    input  logic [23:0] display_i,       
    output logic [41:0] display_o        
);

    logic [6:0] segments [5:0];  // Segments per display

    genvar i;
    generate
        for (i = 0; i < 6; i++) begin : display_gen
            seg7_digit decoder (
                .digit_i    (display_i[i*4 +: 4]),
                .segments_o (segments[i])
            );
        end
    endgenerate

    // Concatenate the 6 groups of 7 bits into a single output vector
    always_comb begin
        display_o = {
            segments[5],
            segments[4],
            segments[3],
            segments[2],
            segments[1],
            segments[0]
        };
    end

endmodule

module seg7_digit(
    input  logic [3:0] digit_i,
    output logic [6:0] segments_o
);

    always_comb begin
        case (digit_i)
			4'h0: segments_o = 7'b100_0000;    //ZERO
			4'h1: segments_o = 7'b111_1001;    //ONE
			4'h2: segments_o = 7'b010_0100;    //TWO
			4'h3: segments_o = 7'b011_0000;    //THREE
			4'h4: segments_o = 7'b001_1001;    //FOUR
			4'h5: segments_o = 7'b001_0010;    //FIVE
			4'h6: segments_o = 7'b000_0010;    //SIX
			4'h7: segments_o = 7'b111_1000;    //SEVEN
			4'h8: segments_o = 7'b000_0000;    //EIGHT
			4'h9: segments_o = 7'b001_1000;    //NINE
			4'ha: segments_o = 7'b000_1000;    //A
			4'hb: segments_o = 7'b000_0011;    //B
			4'hc: segments_o = 7'b100_0110;    //C
			4'hd: segments_o = 7'b010_0001;    //D
			4'he: segments_o = 7'b000_0110;    //E
			4'hf: segments_o = 7'b000_1110;    //F
			default: segments_o = 7'b100_0000;    //ZERO
        endcase
    end

endmodule

module debounce #(
	 parameter int DIVIDER = 20e6
	 )(
    input   logic   clk_i,
                    rst_i,
                    btn_i,
    output  logic   btn_o
 ); 

    logic   [32 : 0]    counter;
    
    logic               start, send;
								
    //Cunter logic
    always_ff @(posedge clk_i) begin
        if(!rst_i) begin
            counter	<= 0;
            start		<= 0;
				send		<= 0;
        end else begin
            if(!btn_i && !start) begin
					start	<= 1;
					send	<= 1;	
				end        
            if(start) begin 
                if(counter  == (DIVIDER - 1)) begin
                    counter <= 0;
                    start   <= 0;           
                end else counter <= counter + 1;
					 send	<= 0;	
            end
        end
	 end
	 
    assign btn_o = send;
    
endmodule


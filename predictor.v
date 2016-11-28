`timescale 1ps/1ps

`define WEIGHT_BITS 8
`define HISTORY_bits 3
`define THRESHOLD 29
`define N_bits 1
`define NUM_PERCEPTRON_ENTRIES 2**`N_bits * (`HISTORY_bits + 1)




module neural_predictor(input clk, input current_pc_valid, input[15:0]current_pc, input result_valid, input [15:0]result_pc, input result,
	output current_should_jump);

	/*integer N_bits = 3; //number of bits to use for indexing into predictor hash table
	parameter HISTORY_bits = 8; //number of bits to use for storing history

	parameter WEIGHT_BITS = 8;

	parameter THRESHOLD = 29; //see paper*/

	wire [3:0]hash_addr = current_pc[`N_bits:0];

	wire [3:0]result_hash_addr = result_pc[`N_bits:0];


	reg [`HISTORY_bits - 1 : 0]history = 0;
	reg [`HISTORY_bits - 1 : 0]history_valid = 0;

	reg signed [`WEIGHT_BITS - 1:0]perceptron_table[`NUM_PERCEPTRON_ENTRIES - 1 : 0];

	wire signed [`WEIGHT_BITS - 1 : 0]current_perceptron_weights[`HISTORY_bits : 0]; //there is an extra bias weight, so no minus 1

	wire signed [`WEIGHT_BITS - 1 : 0]result_perceptron_weights[`HISTORY_bits : 0];


	wire signed [31:0]adder_outs[`HISTORY_bits : 0];
	assign adder_outs[0] = 1 * current_perceptron_weights[0];



	integer init;
	initial begin
		
		for(init = 0; init < `NUM_PERCEPTRON_ENTRIES; init = init + 1) begin
			perceptron_table[init] <= 0;
		end


	end

	wire [`WEIGHT_BITS - 1 : 0]p0 = perceptron_table[0];
	wire [`WEIGHT_BITS - 1 : 0]p1 = perceptron_table[1];
	wire [`WEIGHT_BITS - 1 : 0]p2 = perceptron_table[2];
	wire [`WEIGHT_BITS - 1 : 0]p3 = perceptron_table[3];
	wire [`WEIGHT_BITS - 1 : 0]p4 = perceptron_table[4];
	wire [`WEIGHT_BITS - 1 : 0]p5 = perceptron_table[5];
	wire [`WEIGHT_BITS - 1 : 0]p6 = perceptron_table[6];
	wire [`WEIGHT_BITS - 1 : 0]p7 = perceptron_table[7];

	generate
		genvar i;
		
		for(i = 0; i < `HISTORY_bits + 1; i = i + 1) begin
			assign current_perceptron_weights[i] = perceptron_table[hash_addr * (`HISTORY_bits + 1) + i];
		end

		for(i = 0; i < `HISTORY_bits + 1; i = i + 1) begin
			assign result_perceptron_weights[i] = perceptron_table[result_hash_addr * (`HISTORY_bits + 1) + i];
		end


		for(i = 1; i < `HISTORY_bits + 1; i = i + 1) begin
			wire signed [31:0]mult = ~history_valid[i-1] ? 0 : (history[i-1] == 1 ? current_perceptron_weights[i] * 1 : current_perceptron_weights[i] * -1);

			adder a(adder_outs[i-1], mult, adder_outs[i]);
	
			
		end
	endgenerate


	wire signed [31:0]Y_weight_dot = adder_outs[`HISTORY_bits];


	assign current_should_jump = Y_weight_dot > 0;


	wire buff_valid;
	wire signed [31:0]buff_next;

	buffer wait_for_results(clk, result_valid, current_pc_valid, Y_weight_dot, buff_valid, buff_next);

	wire [31:0]abs_Y_buff = buff_next[31] ? -buff_next : buff_next;
	integer j;
	always @(posedge clk) begin
		if(result_valid & buff_valid) begin
			if((~result ^ buff_next[31]) | (abs_Y_buff < `THRESHOLD)) begin //was a jump and neg Y, or wasn't a jump and pos Y
				for(j = 0; j < `HISTORY_bits + 1; j = j + 1) begin
					if(result) begin
						if(j == 0) begin
							perceptron_table[result_hash_addr * (`HISTORY_bits + 1) + j] <= result_perceptron_weights[j] + 1;
						end
						else if(history_valid[j-1]) begin
							perceptron_table[result_hash_addr * (`HISTORY_bits + 1) + j] <= result_perceptron_weights[j] + history[j-1];
						end

						//$display("starting at addr %d: weight %d updated from %d to %d", )
						
					end

					else begin
						if(j == 0) begin
							perceptron_table[result_hash_addr * (`HISTORY_bits + 1) + j] <= result_perceptron_weights[j] - 1;
						end
						else if(history_valid[j-1]) begin
							perceptron_table[result_hash_addr * (`HISTORY_bits + 1) + j] <= result_perceptron_weights[j] - history[j-1];
						end
					end
					
				end
			end

			history <= (history << 1) | result;
			history_valid <= (history_valid << 1) | 1;
		end
	end



endmodule

module adder(input [31:0]p1, input [31:0]p2, output [31:0]out);
	assign out = p1 + p2;
endmodule


module buffer(input clk, input taken, input v_in, input [31:0]next, output v_out, output [31:0]next_Y);

reg [7:0]next_empty = 0;
reg [7:0]next_pointer = 0;


reg [31:0]data[7:0];
reg valid[7:0];

integer p;
initial begin
	
	for(p = 0; p < 8; p = p+1) begin
		data[p] = 0;
		valid[p] = 0;
	end
end


assign next_Y = data[next_pointer];
assign v_out = valid[next_pointer];

always @(posedge clk) begin
	if(v_in) begin
		data[next_empty] <= next;
		valid[next_empty] <= 1;
		next_empty <= (next_empty + 1) % 8;
	end

	if(taken) begin
		valid[next_pointer] <= 0;
		data[next_pointer] <= 0;
		next_pointer <= (next_pointer + 1) % 8;
	end
end





endmodule
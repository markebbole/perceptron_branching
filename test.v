`timescale 1ps/1ps


module test();
	initial begin
		$dumpfile("test.vcd");
		$dumpvars(1, test);
		$dumpvars(0, prediction);
	end


	// clock
    wire clk;
    clock c0(clk);

    reg current_pc_valid = 0;
    reg [15:0]current_pc = 0;

    reg result_valid;
    reg [15:0]result_pc;
    reg result;
    wire should_jump;

    reg [15:0]counter = 0;



	neural_predictor prediction(clk, current_pc_valid, current_pc, result_valid, result_pc, result, should_jump);

	always @(posedge clk) begin
		case(counter)

			0: begin
				current_pc_valid <= 1;
				current_pc <= 0;
				result_valid <= 0;
				result_pc <= 0;
				result <= 0;

			end


			2: begin
				current_pc_valid <= 0;
				current_pc <= 'hxxxx;
				result_valid <= 1;
				result_pc <= 0;
				result <= 1;
			end

			5: begin
				current_pc_valid <= 1;
				current_pc <= 0;
				result_valid <= 0;
				result_pc <= 'hxxxx;
				result <= 'hxxxx;
			end


			9: begin
				current_pc_valid <= 0;
				current_pc <= 'hxxxx;
				result_valid <= 1;
				result_pc <= 0;
				result <= 1;
			end


			11: begin
				current_pc_valid <= 1;
				current_pc <= 0;
				result_valid <= 0;
				result_pc <= 'hxxxx;
				result <= 'hxxxx;
			end

			default: begin
				current_pc_valid <= 0;
				current_pc <= 'hxxxx;
				result_valid <= 0;
				result_pc <= 'hxxxx;
				result <= 'hxxxx;
			end
		endcase	


		counter <= counter + 1;

		if(counter == 100) begin
			$finish;
		end
	end

endmodule
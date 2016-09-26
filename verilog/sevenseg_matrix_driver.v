
module sevenseg_matrix_driver(
	input clk,

	input [3:0] dig0,
	input [3:0] dig1,
	input [3:0] dig2,
	input [3:0] dig3,

	output reg [3:0] sevenseg_control,
	output reg [0:7] sevenseg_value
);

//values in 7seg are are A, B, C, D, E, F, G, DP 

reg [3:0] dig_num;
reg [3:0] current_digit;
reg [7:0] clk_div_count;

always@(posedge clk) begin
	if(clk_div_count == 8'hFF) begin
		
		clk_div_count <= 8'h0;
	
		if(dig_num == 4'h7) begin
			dig_num <= 4'h0;
		end else begin
			dig_num <= dig_num + 1'b1;
		end
		
		if(dig_num == 4'h0) begin
			sevenseg_control <= 4'b1110;
			current_digit <= dig0;
		end else if(dig_num == 4'h2) begin
			sevenseg_control <= 4'b1101;
			current_digit <= dig1;
		end else if(dig_num == 4'h4) begin
			sevenseg_control <= 4'b1011;
			current_digit <= dig2;
		end else if(dig_num == 4'h6) begin
			sevenseg_control <= 4'b0111;
			current_digit <= dig3;
		end else begin
			sevenseg_control <= 4'b1111; //gives us a nice "off" state before crossing digits, reducing blur
		end
		
	end else begin
		clk_div_count <= clk_div_count + 8'h1;
	end
end

always @* begin
	case(current_digit)
		4'h0: sevenseg_value <= 8'b00000011;
		4'h1: sevenseg_value <= 8'b10011111;
		4'h2: sevenseg_value <= 8'b00100101;
		4'h3: sevenseg_value <= 8'b00001101;
		4'h4: sevenseg_value <= 8'b10011001;
		4'h5: sevenseg_value <= 8'b01001001;
		4'h6: sevenseg_value <= 8'b01000001;
		4'h7: sevenseg_value <= 8'b00011111;
		4'h8: sevenseg_value <= 8'b00000001;
		4'h9: sevenseg_value <= 8'b00001001;
		4'hA: sevenseg_value <= 8'b00010001;
		4'hB: sevenseg_value <= 8'b11000001;
		4'hC: sevenseg_value <= 8'b01100011;
		4'hD: sevenseg_value <= 8'b10000101;
		4'hE: sevenseg_value <= 8'b01100001;
		default: sevenseg_value <= 8'b01110001; //F
	endcase
end

endmodule
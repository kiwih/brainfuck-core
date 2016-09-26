module basic_register#(
	parameter DATA_WIDTH = 8
)(
	input clk,
	input rst,
	input wr_en,
	input [(DATA_WIDTH-1):0] data_in,
	output [(DATA_WIDTH-1):0] data_out
);

reg [(DATA_WIDTH-1):0] data;

initial data <= 0;

always @(posedge clk or posedge rst) begin
	if(rst)
		data <= 0;
	else begin
		if(wr_en)
			data <= data_in;
	end
end

assign data_out = data;

endmodule
		
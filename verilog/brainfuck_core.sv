// `default_nettype none //Uncomment this if you want better error checking
`include "../verilog/brainfuck_constants.sv"

module brainfuck_core#(
	parameter PROG_DATA_WIDTH = 3, //8 different characters can be stored in 3 bits
	parameter PROG_ADDR_WIDTH = 8,
	parameter MEM_DATA_WIDTH = 8,
	parameter MEM_ADDR_WIDTH = 8
)(
	//clock input
	input clk,
	input rst,
	
	//I/O to data memory
	input [(MEM_DATA_WIDTH-1):0] mem_data_rd,
	output wire [(MEM_DATA_WIDTH-1):0] mem_data_wr,
	output wire [(MEM_ADDR_WIDTH-1):0] mem_addr,
	output reg mem_wr_en,
	
	//I/O to instruction memory
	input [(PROG_DATA_WIDTH-1):0] prog_data_rd,
	output wire prog_rd_en,
	output wire [(PROG_ADDR_WIDTH-1):0] prog_addr,
	
	//I/O to STDIN
	input [7:0] rx_data,
	input rx_ready,
	output reg rx_clear,
	
	//I/O to STDOUT
	output [7:0] tx_data,
	input tx_busy,
	output reg tx_wr
);

//program counter
wire [(PROG_ADDR_WIDTH-1):0] pc_out;
reg [(PROG_ADDR_WIDTH-1):0] pc_in;
wire pc_wr_en;
basic_register #(.DATA_WIDTH(PROG_ADDR_WIDTH)) pc (.clk(clk), .rst(rst), .wr_en(pc_wr_en), .data_in(pc_in), .data_out(pc_out));

//mux for pc register
wire pc_sel;
always_comb begin
	case(pc_sel)
		`PC_SEL_INC: pc_in <= pc_out + 1'b1;
		default: pc_in <= pc_out - 1'b1;
	endcase
end

//no mux for program memory address source
assign prog_addr = pc_out;

//memory pointer
wire [(MEM_ADDR_WIDTH-1):0] ptr_out;
reg [(MEM_ADDR_WIDTH-1):0] ptr_in;
wire ptr_wr_en;
basic_register #(.DATA_WIDTH(MEM_ADDR_WIDTH)) ptr (.clk(clk), .rst(rst), .wr_en(ptr_wr_en), .data_in(ptr_in), .data_out(ptr_out));

//mux for ptr register
reg ptr_sel;
always_comb begin
	case(ptr_sel)
		`PTR_SEL_INC: ptr_in <= ptr_out + 1'b1;
		default: ptr_in <= ptr_out - 1'b1;
	endcase
end

//temporary data storage
wire [(MEM_DATA_WIDTH-1):0] data_out;
reg [(MEM_DATA_WIDTH-1):0] data_in;
wire data_wr_en;
basic_register #(.DATA_WIDTH(MEM_DATA_WIDTH)) data (.clk(clk), .rst(rst), .wr_en(data_wr_en), .data_in(data_in), .data_out(data_out));

//mux for data register

reg [1:0] data_sel;
always_comb begin
	case(data_sel)
		`DATA_SEL_MEM: data_in <= mem_data_rd;
		`DATA_SEL_MEM_INC: data_in <= mem_data_rd + 1'b1;
		`DATA_SEL_MEM_DEC: data_in <= mem_data_rd - 1'b1;
		default: data_in <= rx_data[7:0]; //{8'b0, rx_data[7:0]};
	endcase
end

//instr memory address is always ptr
assign mem_addr = ptr_out;

//memory data always
assign mem_data_wr = data_out;

//dir register (for loops)
wire dir_out;
wire dir_in;
wire dir_wr_en;
basic_register #(.DATA_WIDTH(1)) dir (.clk(clk), .rst(rst), .wr_en(dir_wr_en), .data_in(dir_in), .data_out(dir_out));

//no mux for dir_in
wire dir_sel;
assign dir_in = dir_sel;

assign tx_data = data_out[7:0];

//nest_level register (for nested loops)
reg [7:0] nest_level_in;
wire [7:0] nest_level_out;
wire nest_level_wr_en;
wire nest_level_clear;
basic_register #(.DATA_WIDTH(8)) nest_level (.clk(clk), .rst(rst || nest_level_clear), .wr_en(nest_level_wr_en), .data_in(nest_level_in), .data_out(nest_level_out));

reg nest_level_sel;
always_comb begin
	case(nest_level_sel)
		`NEST_LEVEL_SEL_INC: nest_level_in <= nest_level_out + 1'b1;
		default: nest_level_in <= nest_level_out - 1'b1;
	endcase
end

brainfuck_core_fsm #(
	.PROG_DATA_WIDTH(PROG_DATA_WIDTH),
	.MEM_DATA_WIDTH(MEM_DATA_WIDTH)
) fsm (
	.clk(clk),
	.rst(rst),
	
	.prog_instr(prog_data_rd),
	.rx_ready(rx_ready),
	.tx_busy(tx_busy),
	.data(data_out),
	.dir(dir_out),
	.nest_level(nest_level_out),
	
	.prog_rd_en(prog_rd_en),
	.mem_wr_en(mem_wr_en),
	.data_wr_en(data_wr_en),
	.data_sel(data_sel),
	.ptr_wr_en(ptr_wr_en),
	.ptr_sel(ptr_sel),
	.pc_wr_en(pc_wr_en),
	.pc_sel(pc_sel),
	.dir_wr_en(dir_wr_en),
	.dir_sel(dir_sel),
	.nest_level_sel(nest_level_sel),
	.nest_level_clear(nest_level_clear),
	.nest_level_wr_en(nest_level_wr_en),
	.tx_wr(tx_wr),
	.rx_clear(rx_clear)
);

endmodule





// `default_nettype none //Uncomment this if you want better error checking
`include "../verilog/brainfuck_constants.sv"

module top_cyclone_four_de2_115#(
	parameter PROG_ADDR_WIDTH = 11,
	parameter PROG_DATA_WIDTH = 3,
	parameter MEM_ADDR_WIDTH = 16,
	parameter MEM_DATA_WIDTH = 9,

	parameter PROGRAM_NAME = "../prog/beer.txt"
)(
	input CLOCK_50,
	input [3:0] SW,
	output [17:0] LEDR,
	output [8:0] LEDG,
	output UART_TXD,
	input UART_RXD
);

wire clk;
assign clk = CLOCK_50;

wire rst;
assign rst = ~SW[0];

wire [2:0] debug_state;


wire [(PROG_ADDR_WIDTH-1):0] prog_addr;
wire [(PROG_DATA_WIDTH-1):0] prog_data_rd;
wire prog_rd_en;

single_port_rom #(
	.ADDR_WIDTH(PROG_ADDR_WIDTH),
	.DATA_WIDTH(PROG_DATA_WIDTH),
	.PROGRAM_NAME(PROGRAM_NAME)
) program_memory (
	.clk(clk),
	.addr(prog_addr),
	.q(prog_data_rd),
	.rd_en(prog_rd_en)
);

wire [(MEM_ADDR_WIDTH-1):0] mem_addr;
wire [(MEM_DATA_WIDTH-1):0] mem_data_rd;
wire [(MEM_DATA_WIDTH-1):0] mem_data_wr;
wire mem_wr_en;

single_port_ram #(
	.ADDR_WIDTH(MEM_ADDR_WIDTH),
	.DATA_WIDTH(MEM_DATA_WIDTH)
) data_memory (
	.clk(clk),
	.addr(mem_addr),
	.we(mem_wr_en),
	.data(mem_data_wr),
	.q(mem_data_rd)
);

wire [7:0] tx_data;
wire tx_wr; 	//from CORE to UART, write in data to transmit
wire tx_busy;  //from UART to CORE, uart is busy transmitting

wire [7:0] rx_data;
wire rx_clear; //FROM CORE to UART, i have seen the data you received
wire rx_ready; //FROM UART to CORE, i have new data to see
wire rx_busy;

uart #
(
    .DATA_WIDTH(MEM_DATA_WIDTH)
)
uart0
(
    .clk(clk),
    .rst(rst),

    .input_axis_tdata(tx_data),
    .input_axis_tvalid(tx_wr),
    //.input_axis_tready(tx_ready), //don't care about the AXIS api

    .output_axis_tdata(rx_data),
    .output_axis_tvalid(rx_ready),
    .output_axis_tready(rx_clear),

    .rxd(UART_RXD),
    .txd(UART_TXD),

    .tx_busy(tx_busy),
    .rx_busy(rx_busy),
    //output wire rx_overrun_error //rx_overrun and rx_frame errors are not passed on to the bfcore at this stage
    //output wire rx_frame_error

    .prescale(16'd651)	//prescale (fclk/baud*8) (50MHz / 9600 * 8)
);

brainfuck_core #(
	.PROG_DATA_WIDTH(PROG_DATA_WIDTH),
	.PROG_ADDR_WIDTH(PROG_ADDR_WIDTH),
	.MEM_DATA_WIDTH(MEM_DATA_WIDTH),
	.MEM_ADDR_WIDTH(MEM_ADDR_WIDTH)
) core (
	.clk(clk),
	.rst(rst),
	
	.mem_data_rd(mem_data_rd),
	.mem_data_wr(mem_data_wr),
	.mem_addr(mem_addr),
	.mem_wr_en(mem_wr_en),
	
	.prog_data_rd(prog_data_rd),
	.prog_addr(prog_addr),
	.prog_rd_en(prog_rd_en),
	
	.rx_data(rx_data),
	.rx_ready(rx_ready),
	.rx_clear(rx_clear),
	
	.tx_data(tx_data),
	.tx_busy(tx_busy),
	.tx_wr(tx_wr)
	
);

assign LEDG[8:0] = prog_addr[8:0];
assign LEDR[7:0] = mem_data_rd[7:0];
assign LEDR[17] = clk;
endmodule

`default_nettype wire
`default_nettype none
`include "../verilog/brainfuck_constants.sv"

module top_cyclone_one#(
	parameter PROG_ADDR_WIDTH = 8,
	parameter PROG_DATA_WIDTH = 3,
	parameter MEM_ADDR_WIDTH = 8,
	parameter MEM_DATA_WIDTH = 8,

	parameter PROGRAM_NAME = "D:/Dropbox/brainfuck-core/prog/test.txt"
)(
	input CLK_50,
	input [3:0] SW,
	output [0:7] SEVENSEG_7,
	output [3:0] SEVENSEG_4,
	output [7:2] LED,
	output TX,
	input RX
);


reg [32:0] clk_div_count;

wire clk;
assign clk = CLK_50;

wire rst;
assign rst = ~SW[0];

wire [2:0] debug_state;

assign LED[2] = TX;
assign LED[3] = RX;
assign LED[4] = 1;
assign LED[5] = debug_state[0];
assign LED[6] = debug_state[1];
assign LED[7] = debug_state[2];

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

wire [(MEM_DATA_WIDTH-1):0] tx_data;
wire tx_wr; 	//from CORE to UART, write in data to transmit
wire tx_busy;  //from UART to CORE, uart is busy transmitting

wire [(MEM_DATA_WIDTH-1):0] rx_data;
wire rx_clear; //FROM CORE to UART, i have seen the data you received
wire rx_ready; //FROM UART to CORE, i have new data to see
wire rx_busy;

uart #
(
    .DATA_WIDTH(MEM_DATA_WIDTH)
)
uart0
(
    .clk(CLK_50),
    .rst(rst),

    .input_axis_tdata(tx_data),
    .input_axis_tvalid(tx_wr),
    //.input_axis_tready(tx_ready), //don't care

    .output_axis_tdata(rx_data),
    .output_axis_tvalid(rx_ready),
    .output_axis_tready(rx_clear),

    .rxd(RX),
    .txd(TX),

    .tx_busy(tx_busy),
    .rx_busy(rx_busy),
    //output wire                   rx_overrun_error,
    //output wire                   rx_frame_error,

    .prescale(16'd651)//input  wire [15:0]            prescale (fclk/baud*8)
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
	.tx_wr(tx_wr),
	
	.debug_state(debug_state)
	
);

sevenseg_matrix_driver driver (
	.clk(CLK_50),
	.dig0(prog_addr[3:0]),
	.dig1(prog_addr[7:4]),
	.dig2(mem_data_rd[3:0]),
	.dig3(mem_data_rd[7:4]),
	
	.sevenseg_control(SEVENSEG_4),
	.sevenseg_value(SEVENSEG_7)
);

endmodule

`default_nettype wire
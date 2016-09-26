`default_nettype none
`include "../verilog/brainfuck_constants.sv"

`define 	S_POWERUP		3'h0
`define 	S_FETCH			3'h1
`define 	S_DECODE			3'h2
`define 	S_MEMORY			3'h3
`define 	S_LOOP			3'h4
`define 	S_LOOP_FETCH	3'h5

module brainfuck_core_fsm#(
	parameter PROG_DATA_WIDTH = 3,
	parameter MEM_DATA_WIDTH = 8
)(
	input wire clk,
	input wire rst,
	
	input wire [(PROG_DATA_WIDTH-1):0] prog_instr,
	input wire rx_ready,
	input wire tx_busy,
	input wire [(MEM_DATA_WIDTH-1):0] data,
	input wire dir,
	input wire [7:0] nest_level,
	
	output reg prog_rd_en,
	output reg mem_wr_en,
	output reg data_wr_en,
	output reg [1:0] data_sel,
	output reg ptr_wr_en,
	output reg ptr_sel,
	output reg pc_wr_en,
	output reg pc_sel,
	output reg dir_wr_en,
	output reg dir_sel,
	output reg nest_level_sel,
	output reg nest_level_clear,
	output reg nest_level_wr_en,
	output reg tx_wr,
	output reg rx_clear,
	
	output reg [2:0] debug_state
);



//state registers
reg [2:0] state = `S_POWERUP;
reg [2:0] next_state = `S_POWERUP;

//initial begin
//	state <= 3'h0;
//	next_state <= 3'h0;
//end

assign debug_state = state;

//state register logic
always @(posedge clk or posedge rst) begin
	if (rst)
		state <= `S_POWERUP;
  else
		state <= next_state;
end

//assign debug_current_state = state;
//mux for ptr register


//next state/output logic
always_comb begin
	//default values
	prog_rd_en <= 0;
	
	mem_wr_en <= 0;
	
	data_wr_en <= 0;
	data_sel <= `DATA_SEL_MEM;
	
	ptr_wr_en <= 0;
	ptr_sel <= `PTR_SEL_INC;
	
	pc_wr_en <= 0;
	pc_sel <= `PC_SEL_INC;
	
	dir_wr_en <= 0;
	dir_sel <= `DIR_FORWARDS;
	
	nest_level_clear <= 0;
	nest_level_wr_en <= 0;
	nest_level_sel <= `NEST_LEVEL_SEL_INC;
	
	tx_wr <= 0;
	rx_clear <= 0;
	
	//transition options
	case(state)
	
		`S_POWERUP: begin
			//prog_rd_en <= 1;
			next_state <= `S_FETCH;
			
		end
	
		`S_FETCH: begin
			prog_rd_en <= 1;
			next_state <= `S_DECODE;
		end
		
		`S_DECODE: begin
			if(prog_instr == `I_GREATER) begin
				ptr_wr_en <= 1;
				ptr_sel <= `PTR_SEL_INC;
				pc_wr_en <= 1;
				next_state <= `S_FETCH;
			end else if(prog_instr == `I_LESSER) begin
				ptr_wr_en <= 1;
				ptr_sel <= `PTR_SEL_DEC;
				pc_wr_en <= 1;
				next_state <= `S_FETCH;
			end else if(prog_instr == `I_PLUS) begin
				data_wr_en <= 1;
				data_sel <= `DATA_SEL_MEM_INC;
				next_state <= `S_MEMORY;
			end else if(prog_instr == `I_MINUS) begin
				data_wr_en <= 1;
				data_sel <= `DATA_SEL_MEM_DEC;
				next_state <= `S_MEMORY;
			end else if(prog_instr == `I_OPEN) begin
				data_wr_en <= 1;
				data_sel <= `DATA_SEL_MEM;
				dir_sel <= `DIR_FORWARDS;
				dir_wr_en <= 1;
				next_state <= `S_MEMORY;
			end else if(prog_instr == `I_CLOSE) begin
				data_wr_en <= 1;
				data_sel <= `DATA_SEL_MEM;
				dir_sel <= `DIR_BACKWARDS;
				dir_wr_en <= 1;
				next_state <= `S_MEMORY;	
			end else if(prog_instr == `I_COMMA && rx_ready == 1) begin
				data_wr_en <= 1;
				data_sel <= `DATA_SEL_RX;
				next_state <= `S_MEMORY;
				rx_clear <= 1;
			end else if(prog_instr == `I_PERIOD && tx_busy == 0) begin
				data_wr_en <= 1;
				data_sel <= `DATA_SEL_MEM;
				next_state <= `S_MEMORY;
			end else begin 
				//when instruction is comma/period and the respective stdin/stdout isn't ready, wait in this state
				next_state <= `S_DECODE;
			end
		end
		`S_MEMORY: begin
			if(prog_instr == `I_PLUS || prog_instr == `I_MINUS || prog_instr == `I_COMMA) begin
				mem_wr_en <= 1;
				next_state <= `S_FETCH;
				pc_wr_en <= 1;
			end else if (prog_instr == `I_PERIOD) begin
				tx_wr <= 1;
				mem_wr_en <= 1;
				pc_wr_en <= 1;
				next_state <= `S_FETCH;
			end else if((prog_instr == `I_OPEN && data == 0) || (prog_instr == `I_CLOSE && data != 0)) begin
				pc_wr_en <= 1;
				nest_level_clear <= 1;
				next_state <= `S_LOOP_FETCH;
				if (dir == `DIR_FORWARDS) begin
					pc_sel <= `PC_SEL_INC;
				end else begin
					pc_sel <= `PC_SEL_DEC;
				end
			end else begin
				//when instruction is either open or close and no action needs to occur due to data value
				pc_sel <= `PC_SEL_INC;
				pc_wr_en <= 1;
				next_state <= `S_FETCH;
			end
		
		end
		`S_LOOP_FETCH: begin
			prog_rd_en <= 1;
			next_state <= `S_LOOP;
		
		
		
		end
		default: begin //LOOP
			if(((prog_instr == `I_CLOSE && dir == `DIR_FORWARDS) || (prog_instr == `I_OPEN && dir == `DIR_BACKWARDS)) && nest_level == 0) begin
				//correct bracket, nest level 0, exit search
				pc_sel <= `PC_SEL_INC;
				pc_wr_en <= 1;
				next_state <= `S_FETCH;
			end else if(((prog_instr == `I_CLOSE && dir == `DIR_FORWARDS) || (prog_instr == `I_OPEN && dir == `DIR_BACKWARDS)) && !(nest_level == 0)) begin
				//correct bracket, nest level not 0, continue search but lower nest level
				nest_level_sel <= `NEST_LEVEL_SEL_DEC;
				nest_level_wr_en <= 1;
				
				pc_wr_en <= 1;
				if (dir == `DIR_FORWARDS) begin
					pc_sel <= `PC_SEL_INC;
				end else begin
					pc_sel <= `PC_SEL_DEC;
				end
				next_state <= `S_LOOP_FETCH;
			end else if((prog_instr == `I_CLOSE && dir == `DIR_BACKWARDS) || (prog_instr == `I_OPEN && dir == `DIR_FORWARDS)) begin
				//incorrect bracket, increase nest level
				nest_level_sel <= `NEST_LEVEL_SEL_INC;
				nest_level_wr_en <= 1;
				
				pc_wr_en <= 1;
				if (dir == `DIR_FORWARDS) begin
					pc_sel <= `PC_SEL_INC;
				end else begin
					pc_sel <= `PC_SEL_DEC;
				end
				next_state <= `S_LOOP_FETCH;
			end else begin
				//not a bracket
				pc_wr_en <= 1;
				if (dir == `DIR_FORWARDS) begin
					pc_sel <= `PC_SEL_INC;
				end else begin
					pc_sel <= `PC_SEL_DEC;
				end
				next_state <= `S_LOOP_FETCH;
			end
		
		end
		
	
	
	endcase
end

endmodule
`ifndef BF_CONSTANTS_SV_
`define BF_CONSTANTS_SV_

`define DATA_SEL_MEM  		2'h0
`define DATA_SEL_MEM_INC  	2'h1
`define DATA_SEL_MEM_DEC  	2'h2
`define DATA_SEL_RX	  		2'h3

`define PC_SEL_INC 			1'h0
`define PC_SEL_DEC 			1'h1

`define PTR_SEL_INC 			1'h0
`define PTR_SEL_DEC 			1'h1

`define DIR_FORWARDS 		1'h0
`define DIR_BACKWARDS 		1'h1

`define NEST_LEVEL_SEL_INC	1'h0
`define NEST_LEVEL_SEL_DEC	1'h1

//values used as instructions
`define I_GREATER 3'h0	//	>	x increment the data pointer (to point to the next cell to the right).
`define I_LESSER 	3'h1	//	<	x decrement the data pointer (to point to the next cell to the left).
`define I_PLUS		3'h2	//	+	x increment (increase by one) the byte at the data pointer.
`define I_MINUS	3'h3	//	-	x decrement (decrease by one) the byte at the data pointer.
`define I_PERIOD	3'h4	//	.	  output the byte at the data pointer.
`define I_COMMA	3'h5	//	,	  accept one byte of input, storing its value in the byte at the data pointer.
`define I_OPEN		3'h6	// [	  if the byte at the data pointer is zero, then instead of moving the instruction pointer forward to the next command, jump it forward to the command after the matching ] command.
`define I_CLOSE	3'h7	//	]    if the byte at the data pointer is nonzero, then instead of moving the instruction pointer forward to the next command, jump it back to the command after the matching [ command.



`endif
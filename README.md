# brainfuck-core
This is a Verilog/SystemVerilog\* implementation of a microprocessor that executes [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck) code natively.

It is implemented as a multi-cycle Harvard architecture, and the excellent UART from https://github.com/alexforencich/verilog-uart/ was used to implement blocking STDIN and STDOUT. Program/Data memory widths and sizes are completely parameterized throughout the source code.

The FSM at the core of the control unit implements the following diagram:
![Control unit FSM](/doc/bfcore - fsm.png?raw=true "")

\*: While features of SystemVerilog were used, this is primarily a Verilog implementation.

## Instructions for Use

You will need to create a project in the Verilog synthesis tool of your choice. If you use Quartus, provided are two example projects, one for a Cyclone chip on a custom board under Quartus 11, and one for a Cyclone IV DE2-115 board under Quartus 16.

Once a project has been created, add all Verilog and SystemVerilog files under /verilog and /verilog/uart

Either create an appropriate top-level file joining memory to the brainfuck_core module, or adapt/use one of the existing top level files (`top_cyclone_one.v` or `top_cyclone_four_de2_115.v`) and set this as your top level file.

The top level file should provide the program binary file to the program memory for the synthesis tool to find. 
The program binary file needs to be compatible with the `readmemb()` function, and match the program width provided as parameters.

## The ISA

Brainfuck instructions are provided in the memory file as one of 8 values:

 Brainfuck Instruction | Encoding | Explanation                                                                            
 --------------------- | -------- | --------------------------------------------------------------------------------------
           >           |   000    | increment the data pointer                                                             
           <           |   001    | decrement the data pointer                                                             
           +           |   010    | increment the byte at the data pointer                                                 
           -           |   011    | decrement the byte at the data pointer                                                 
           .           |   100    | output the byte at the data pointer                                                    
           ,           |   101    | input a byte and store it at the data pointer                                            
           [           |   110    | if the byte at the data pointer == 0 jump forward to the command after the matching ]  
           ]           |   111    | if the byte at the data pointer == 1 jump backward to the command after the matching [ 

There should be one encoding per line in the binary file loaded to the processor.

Several example programs have been provided (adapted from http://esoteric.sange.fi/brainfuck/bf-source/prog/), such as beer.txt (outputs the 99 bottles song), helloyou.txt (asks for your name then greets you), and fibonacci.txt (outputs fibonacci numbers).

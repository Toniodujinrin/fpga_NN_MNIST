`define SIGMOID_VALUES_FILE "sigmoid_file.mem"
module sigmoid 
#(
parameter
INPUT_WIDTH = 5,
OUTPUT_WIDTH = 16
)
(
  input [INPUT_WIDTH-1:0] data_in,
  output reg [OUTPUT_WIDTH-1:0] data_out
); 
  reg [OUTPUT_WIDTH-1:0] mem [0:(2**INPUT_WIDTH)-1]; 
  initial
  begin 
    $readmemb(`SIGMOID_VALUES_FILE,mem); 
  end 
  
  //combinational read infers DRAM 
  always@(*)
  begin
    if($signed(data_in) >= 0)
      data_out = mem[data_in + (1<<INPUT_WIDTH-1)]; 
    else 
      data_out = mem[data_in - (1<<INPUT_WIDTH-1)]; 
  end 

endmodule 

module weight_mem 
#(
  parameter 
  N_WEIGHTS = 723, 
  WEIGHT_WIDTH = 32,
  WEIGHT_ADDRESS_WIDTH = 10,
  WEIGHT_FILE = "weight_file_0_0"
)
(
  input clk, read_en,
  input [WEIGHT_ADDRESS_WIDTH-1:0] weight_read_addr,
  input write_en,
  input [WEIGHT_ADDRESS_WIDTH-1:0] weight_write_addr,
  input [WEIGHT_WIDTH-1:0] weight_write_data,
  output reg [WEIGHT_WIDTH-1:0] weight_out   
); 

  reg [WEIGHT_WIDTH-1:0] weight_memory [0:N_WEIGHTS-1]; 
  
 initial
 begin 
	$readmemb(WEIGHT_FILE,weight_memory); 
 end 



  //reading data from RAM: 
  //sequential flow infers BRAM for Vivado synthesis. 
  always@(posedge clk)
  begin
    if(write_en)
      weight_memory[weight_write_addr] <= weight_write_data;
    else if(read_en)
      weight_out <= weight_memory[weight_read_addr]; 
  end 

endmodule 

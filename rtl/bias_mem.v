module bias_mem 
#(
  parameter 
  BIAS_WIDTH = 32,
  BIAS_FILE = "bias_1_1.mif"
)
(
  input clk,
  input write_en,
  input [BIAS_WIDTH-1:0] write_data,
  output [BIAS_WIDTH-1:0] bias_out
); 
  //one memory slot
  reg [BIAS_WIDTH-1:0] mem [0:0];
  
  initial
    begin 
      $readmemb(BIAS_FILE, mem); 
    end 
  assign bias_out = mem[0];

  always @(posedge clk)
    if (write_en)
      mem[0] <= write_data;
endmodule 

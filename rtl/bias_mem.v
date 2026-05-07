module bias_mem 
#(
  parameter 
  BIAS_WIDTH = 32,
  BIAS_FILE = "bias_1_1.mif"
)
(
  output reg [BIAS_WIDTH-1:0] bias_out
); 
  //one memory slot
  reg [BIAS_WIDTH-1:0] mem [0:0];
  
  initial
    begin 
      $readmemb(BIAS_FILE, mem); 
    end 
  always@(*)
    begin 
        bias_out = mem[0]; 
    end 
endmodule 

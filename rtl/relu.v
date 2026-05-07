module relu
#(
  parameter 
  INPUT_WIDTH = 32, 
  OUTPUT_WIDTH = 16
)
(
  input [INPUT_WIDTH-1:0] data_in, 
  output reg [OUTPUT_WIDTH-1:0] data_out
); 
  always@(*)
  begin 
    if($signed(data_in) > 0)
      begin 
        data_out = data_in[INPUT_WIDTH-1:0]; 
      end 
    else
      begin 
        data_out = {OUTPUT_WIDTH{1'b0}}; 
		end 
  end 
endmodule 

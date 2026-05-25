module relu #(
  parameter INPUT_WIDTH = 32, OUTPUT_WIDTH = 16
)(
  input  [INPUT_WIDTH-1:0]      data_in, 
  output reg [OUTPUT_WIDTH-1:0] data_out
);
  always @(*) begin 
    if ($signed(data_in) > 0) begin
      // Positive overflow check: if any integer bits above bit 25 are active
      if (|data_in[30:25])
        data_out = 16'h7FFF;
      else
        data_out = data_in[25:10]; // Correctly extract Q5.10
    end else begin 
      data_out = 16'h0000;
    end 
  end 
endmodule

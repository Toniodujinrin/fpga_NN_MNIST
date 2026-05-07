module fpga_NN_MNIST(
  input clk, 
  input reset, 
  input x_valid, 
  input [15:0] x_value,
  output [15:0] neuron_output, 
  output output_valid 
); 
  neuron 
  #(
    .DATA_WIDTH(16),
    .WEIGHT_WIDTH(16),
    .N_WEIGHTS(16),
    .SIGMOID_INPUT_WIDTH(5),
    .ACC_TYPE("reLU"),
    .WEIGHT_FILE("weight_file_mock.mem"),
    .BIAS_FILE("bias_file_mock.mem"),
    .BIAS_WIDTH(32)
  )
  NEURON  
  (
    .clk(clk), 
    .reset(reset), 
    .x_value(x_value),
    .x_valid(x_valid), 
    .neuron_output(neuron_output), 
    .output_valid_flag(output_valid)
  ); 
endmodule



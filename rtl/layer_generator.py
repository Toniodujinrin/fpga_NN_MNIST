LAYER_NUM = input("layer number: ")
N_NEURONS = int(input("number of neurons: "))

with open(f"layer_{LAYER_NUM}.v", 'w') as file:
    generated = ""
    for i in range(N_NEURONS):
        generated += f"""
neuron 
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_FILE("weights/weight_file_layer_{LAYER_NUM}_neuron_{i}.mem"),
    .BIAS_FILE("biases/bias_file_layer_{LAYER_NUM}_neuron_{i}.mem"),
    .BIAS_WIDTH(BIAS_WIDTH)
)
    NEURON_{i}
(
    .clk(clk),
    .reset(reset),
    .x_value(input_value),
    .x_valid(input_valid),
    .neuron_output(output_values[((({i}+1)*DATA_WIDTH)-1)-:DATA_WIDTH]),
    .output_valid_flag(outputs_valid_array[{i}]), 
    .neuron_ready(neuron_ready_array[{i}])
);
"""

    rtl = f"""
module layer_{LAYER_NUM}
#(
  parameter
  DATA_WIDTH            = 16,
  WEIGHT_WIDTH          = 16,
  N_WEIGHTS             = 784,
  N_NEURONS             = {N_NEURONS},
  N_INPUTS              = 784,
  SIGMOID_INPUT_WIDTH   = 5,
  ACC_TYPE              = "reLU",
  BIAS_WIDTH            = 32
)
(
  input                              clk,
  input                              reset,
  input                              input_valid,
  input      [DATA_WIDTH-1:0]        input_value,
  output [(DATA_WIDTH*N_NEURONS)-1:0] output_values,
  output                        outputs_valid, 
  output                        layer_ready
);

wire [N_NEURONS-1:0]               outputs_valid_array;
wire [N_NEURONS-1:0]               neuron_ready_array; 
assign outputs_valid = &outputs_valid_array; 
assign layer_ready  = &neuron_ready_array; 


{generated}

endmodule
"""
    file.write(rtl)

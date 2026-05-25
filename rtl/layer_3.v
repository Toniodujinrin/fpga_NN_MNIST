
module layer_3
#(
  parameter
  DATA_WIDTH            = 16,
  WEIGHT_WIDTH          = 16,
  N_WEIGHTS             = 784, 
  N_NEURONS             = 10,
  N_INPUTS              = 784,
  SIGMOID_INPUT_WIDTH   = 5,
  ACC_TYPE              = "reLU",
  WEIGHT_INT_WIDTH      = 1,
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



neuron 
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH),
    .WEIGHT_FILE("weights/weight_file_layer_3_neuron_0.mem"),
    .BIAS_FILE("biases/bias_file_layer_3_neuron_0.mem"),
    .BIAS_WIDTH(BIAS_WIDTH)
)
    NEURON_0
(
    .clk(clk),
    .reset(reset),
    .x_value(input_value),
    .x_valid(input_valid),
    .neuron_output(output_values[(((0+1)*DATA_WIDTH)-1)-:DATA_WIDTH]),
    .output_valid_flag(outputs_valid_array[0]), 
    .neuron_ready(neuron_ready_array[0])
);

neuron 
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH),
    .WEIGHT_FILE("weights/weight_file_layer_3_neuron_1.mem"),
    .BIAS_FILE("biases/bias_file_layer_3_neuron_1.mem"),
    .BIAS_WIDTH(BIAS_WIDTH)
)
    NEURON_1
(
    .clk(clk),
    .reset(reset),
    .x_value(input_value),
    .x_valid(input_valid),
    .neuron_output(output_values[(((1+1)*DATA_WIDTH)-1)-:DATA_WIDTH]),
    .output_valid_flag(outputs_valid_array[1]), 
    .neuron_ready(neuron_ready_array[1])
);

neuron 
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH),
    .WEIGHT_FILE("weights/weight_file_layer_3_neuron_2.mem"),
    .BIAS_FILE("biases/bias_file_layer_3_neuron_2.mem"),
    .BIAS_WIDTH(BIAS_WIDTH)
)
    NEURON_2
(
    .clk(clk),
    .reset(reset),
    .x_value(input_value),
    .x_valid(input_valid),
    .neuron_output(output_values[(((2+1)*DATA_WIDTH)-1)-:DATA_WIDTH]),
    .output_valid_flag(outputs_valid_array[2]), 
    .neuron_ready(neuron_ready_array[2])
);

neuron 
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH),
    .WEIGHT_FILE("weights/weight_file_layer_3_neuron_3.mem"),
    .BIAS_FILE("biases/bias_file_layer_3_neuron_3.mem"),
    .BIAS_WIDTH(BIAS_WIDTH)
)
    NEURON_3
(
    .clk(clk),
    .reset(reset),
    .x_value(input_value),
    .x_valid(input_valid),
    .neuron_output(output_values[(((3+1)*DATA_WIDTH)-1)-:DATA_WIDTH]),
    .output_valid_flag(outputs_valid_array[3]), 
    .neuron_ready(neuron_ready_array[3])
);

neuron 
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH),
    .WEIGHT_FILE("weights/weight_file_layer_3_neuron_4.mem"),
    .BIAS_FILE("biases/bias_file_layer_3_neuron_4.mem"),
    .BIAS_WIDTH(BIAS_WIDTH)
)
    NEURON_4
(
    .clk(clk),
    .reset(reset),
    .x_value(input_value),
    .x_valid(input_valid),
    .neuron_output(output_values[(((4+1)*DATA_WIDTH)-1)-:DATA_WIDTH]),
    .output_valid_flag(outputs_valid_array[4]), 
    .neuron_ready(neuron_ready_array[4])
);

neuron 
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH),
    .WEIGHT_FILE("weights/weight_file_layer_3_neuron_5.mem"),
    .BIAS_FILE("biases/bias_file_layer_3_neuron_5.mem"),
    .BIAS_WIDTH(BIAS_WIDTH)
)
    NEURON_5
(
    .clk(clk),
    .reset(reset),
    .x_value(input_value),
    .x_valid(input_valid),
    .neuron_output(output_values[(((5+1)*DATA_WIDTH)-1)-:DATA_WIDTH]),
    .output_valid_flag(outputs_valid_array[5]), 
    .neuron_ready(neuron_ready_array[5])
);

neuron 
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH),
    .WEIGHT_FILE("weights/weight_file_layer_3_neuron_6.mem"),
    .BIAS_FILE("biases/bias_file_layer_3_neuron_6.mem"),
    .BIAS_WIDTH(BIAS_WIDTH)
)
    NEURON_6
(
    .clk(clk),
    .reset(reset),
    .x_value(input_value),
    .x_valid(input_valid),
    .neuron_output(output_values[(((6+1)*DATA_WIDTH)-1)-:DATA_WIDTH]),
    .output_valid_flag(outputs_valid_array[6]), 
    .neuron_ready(neuron_ready_array[6])
);

neuron 
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH),
    .WEIGHT_FILE("weights/weight_file_layer_3_neuron_7.mem"),
    .BIAS_FILE("biases/bias_file_layer_3_neuron_7.mem"),
    .BIAS_WIDTH(BIAS_WIDTH)
)
    NEURON_7
(
    .clk(clk),
    .reset(reset),
    .x_value(input_value),
    .x_valid(input_valid),
    .neuron_output(output_values[(((7+1)*DATA_WIDTH)-1)-:DATA_WIDTH]),
    .output_valid_flag(outputs_valid_array[7]), 
    .neuron_ready(neuron_ready_array[7])
);

neuron 
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH),
    .WEIGHT_FILE("weights/weight_file_layer_3_neuron_8.mem"),
    .BIAS_FILE("biases/bias_file_layer_3_neuron_8.mem"),
    .BIAS_WIDTH(BIAS_WIDTH)
)
    NEURON_8
(
    .clk(clk),
    .reset(reset),
    .x_value(input_value),
    .x_valid(input_valid),
    .neuron_output(output_values[(((8+1)*DATA_WIDTH)-1)-:DATA_WIDTH]),
    .output_valid_flag(outputs_valid_array[8]), 
    .neuron_ready(neuron_ready_array[8])
);

neuron 
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH),
    .WEIGHT_FILE("weights/weight_file_layer_3_neuron_9.mem"),
    .BIAS_FILE("biases/bias_file_layer_3_neuron_9.mem"),
    .BIAS_WIDTH(BIAS_WIDTH)
)
    NEURON_9
(
    .clk(clk),
    .reset(reset),
    .x_value(input_value),
    .x_valid(input_valid),
    .neuron_output(output_values[(((9+1)*DATA_WIDTH)-1)-:DATA_WIDTH]),
    .output_valid_flag(outputs_valid_array[9]), 
    .neuron_ready(neuron_ready_array[9])
);


endmodule

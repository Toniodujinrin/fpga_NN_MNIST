import argparse
from pathlib import Path


def generate_layer(layer_num: int, neuron_count: int) -> str:
    instances = []
    for i in range(neuron_count):
        instances.append(f"""
neuron
#(
    .DATA_WIDTH(DATA_WIDTH),
    .WEIGHT_WIDTH(WEIGHT_WIDTH),
    .N_WEIGHTS(N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .ACC_TYPE(ACC_TYPE),
    .WEIGHT_FILE("weights/weight_file_layer_{layer_num}_neuron_{i}.mem"),
    .BIAS_FILE("biases/bias_file_layer_{layer_num}_neuron_{i}.mem"),
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
    .neuron_ready(neuron_ready_array[{i}]),
    .cfg_write_enable(cfg_write_enable && cfg_neuron == 6'd{i}),
    .cfg_is_bias(cfg_is_bias),
    .cfg_weight_addr(cfg_index[WEIGHT_ADDRESS_WIDTH-1:0]),
    .cfg_write_data(cfg_write_data)
);
""")

    return f"""module layer_{layer_num}
#(
  parameter
  DATA_WIDTH            = 16,
  WEIGHT_WIDTH          = 16,
  N_WEIGHTS             = 784,
  N_NEURONS             = {neuron_count},
  N_INPUTS              = 784,
  SIGMOID_INPUT_WIDTH   = 5,
  ACC_TYPE              = "reLU",
  BIAS_WIDTH            = 32
)
(
  input                               clk,
  input                               reset,
  input                               input_valid,
  input      [DATA_WIDTH-1:0]         input_value,
  output     [(DATA_WIDTH*N_NEURONS)-1:0] output_values,
  output                              outputs_valid,
  output                              layer_ready,
  input                               cfg_write_enable,
  input      [5:0]                    cfg_neuron,
  input      [9:0]                    cfg_index,
  input                               cfg_is_bias,
  input      [BIAS_WIDTH-1:0]         cfg_write_data
);

localparam WEIGHT_ADDRESS_WIDTH = $clog2(N_WEIGHTS);
wire [N_NEURONS-1:0] outputs_valid_array;
wire [N_NEURONS-1:0] neuron_ready_array;
assign outputs_valid = &outputs_valid_array;
assign layer_ready = &neuron_ready_array;

{''.join(instances)}
endmodule
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate a neural-network layer")
    parser.add_argument("layer", type=int)
    parser.add_argument("neurons", type=int)
    args = parser.parse_args()

    output = Path(__file__).with_name(f"layer_{args.layer}.v")
    output.write_text(generate_layer(args.layer, args.neurons), encoding="ascii")


if __name__ == "__main__":
    main()

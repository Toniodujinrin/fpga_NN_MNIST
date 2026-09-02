`timescale 1ns/1ps

module neuron_dynamic_tb;
  reg clk = 0;
  reg reset = 1;
  always #5 clk = ~clk;

  reg [15:0] x_value = 0;
  reg x_valid = 0;
  wire [15:0] neuron_output;
  wire output_valid_flag;
  wire neuron_ready;
  reg cfg_write_enable = 0;
  reg cfg_is_bias = 0;
  reg [5:0] cfg_weight_addr = 0;
  reg [31:0] cfg_write_data = 0;
  integer i;

  neuron #(
    .N_WEIGHTS(64),
    .ACC_TYPE("linear"),
    .WEIGHT_FILE("weights/weight_file_layer_2_neuron_0.mem"),
    .BIAS_FILE("biases/bias_file_layer_2_neuron_0.mem")
  ) dut (
    .clk(clk), .reset(reset), .x_value(x_value), .x_valid(x_valid),
    .neuron_output(neuron_output), .output_valid_flag(output_valid_flag),
    .neuron_ready(neuron_ready), .cfg_write_enable(cfg_write_enable),
    .cfg_is_bias(cfg_is_bias), .cfg_weight_addr(cfg_weight_addr),
    .cfg_write_data(cfg_write_data)
  );

  initial begin
    repeat (3) @(posedge clk);
    reset = 0;

    for (i = 0; i < 64; i = i + 1) begin
      @(negedge clk);
      cfg_write_enable = 1;
      cfg_is_bias = 0;
      cfg_weight_addr = i;
      cfg_write_data = 0;
    end
    @(negedge clk);
    cfg_is_bias = 1;
    cfg_write_data = 32'h0001_0000;
    @(negedge clk);
    cfg_write_enable = 0;

    for (i = 0; i < 64; i = i + 1) begin
      x_value = 16'h0100;
      x_valid = 1;
      @(negedge clk);
      x_valid = 0;
      @(negedge clk);
    end

    repeat (2) @(negedge clk);
    if (neuron_ready !== 0) begin
      $display("FAIL: neuron remained ready after 64 inputs");
      $finish(1);
    end

    fork
      begin
        wait (output_valid_flag);
        if (neuron_output !== 16'h0100) begin
          $display("FAIL: expected bias-only output 0100, got %h", neuron_output);
          $finish(1);
        end
        $display("PASS: neuron_dynamic_tb");
        $finish;
      end
      begin
        repeat (30) @(posedge clk);
        $display("FAIL: neuron output timeout");
        $finish(1);
      end
    join
  end
endmodule

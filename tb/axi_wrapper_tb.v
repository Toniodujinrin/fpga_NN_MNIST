`timescale 1ns/1ps

module axi_wrapper_tb;
  reg clk = 0;
  reg reset_n = 0;
  always #5 clk = ~clk;

  reg aw_valid = 0;
  reg [7:0] aw_data = 0;
  wire aw_ready;
  reg [2:0] aw_prot = 0;
  reg w_valid = 0;
  reg [31:0] w_data = 0;
  reg [3:0] w_strobe = 4'hf;
  wire w_ready;
  wire b_valid;
  wire [1:0] b_data;
  reg b_ready = 0;
  reg ar_valid = 0;
  reg [7:0] ar_data = 0;
  wire ar_ready;
  reg [2:0] ar_prot = 0;
  wire r_valid;
  wire [31:0] r_data;
  wire [1:0] r_resp;
  reg r_ready = 0;

  reg network_idle = 1;
  reg network_ready = 0;
  reg [15:0] network_output_data = 0;
  reg network_output_data_valid = 0;
  wire network_start;
  wire [15:0] network_input_data;
  wire network_input_data_valid;
  wire model_write_valid;
  wire [1:0] model_layer;
  wire [5:0] model_neuron;
  wire [9:0] model_index;
  wire model_is_bias;
  wire [31:0] model_write_data;

  integer failures = 0;
  integer model_pulses = 0;
  integer start_pulses = 0;

  axi_slave_wrapper #(
    .N_NETWORK_INPUTS(2),
    .N_NEURONS_LAYER_1(1),
    .N_NEURONS_LAYER_2(1),
    .N_NEURONS_LAYER_3(1)
  ) dut (
    .clk(clk), .reset_n(reset_n),
    .aw_valid(aw_valid), .aw_data(aw_data), .aw_ready(aw_ready), .aw_prot(aw_prot),
    .w_valid(w_valid), .w_data(w_data), .w_strobe(w_strobe), .w_ready(w_ready),
    .b_valid(b_valid), .b_data(b_data), .b_ready(b_ready),
    .ar_valid(ar_valid), .ar_data(ar_data), .ar_ready(ar_ready), .ar_prot(ar_prot),
    .r_valid(r_valid), .r_data(r_data), .r_resp(r_resp), .r_ready(r_ready),
    .network_idle(network_idle), .network_ready(network_ready),
    .network_output_data(network_output_data),
    .network_output_data_valid(network_output_data_valid),
    .network_start(network_start), .network_input_data(network_input_data),
    .network_input_data_valid(network_input_data_valid),
    .model_write_valid(model_write_valid), .model_layer(model_layer),
    .model_neuron(model_neuron), .model_index(model_index),
    .model_is_bias(model_is_bias), .model_write_data(model_write_data)
  );

  task check;
    input condition;
    input [255:0] message;
    begin
      if (!condition) begin
        $display("FAIL: %0s", message);
        failures = failures + 1;
      end
    end
  endtask

  task axi_write;
    input [7:0] address;
    input [31:0] value;
    input data_first;
    output [1:0] response;
    begin
      if (data_first) begin
        @(negedge clk);
        w_data = value;
        w_valid = 1;
        while (!w_ready) @(negedge clk);
        @(negedge clk);
        w_valid = 0;
        aw_data = address;
        aw_valid = 1;
        while (!aw_ready) @(negedge clk);
        @(negedge clk);
        aw_valid = 0;
      end else begin
        @(negedge clk);
        aw_data = address;
        aw_valid = 1;
        while (!aw_ready) @(negedge clk);
        @(negedge clk);
        aw_valid = 0;
        w_data = value;
        w_valid = 1;
        while (!w_ready) @(negedge clk);
        @(negedge clk);
        w_valid = 0;
      end

      while (!b_valid) @(negedge clk);
      response = b_data;
      @(negedge clk);
      check(b_valid && b_data == response, "write response held under backpressure");
      b_ready = 1;
      @(negedge clk);
      b_ready = 0;
    end
  endtask

  task axi_read;
    input [7:0] address;
    output [31:0] value;
    output [1:0] response;
    begin
      @(negedge clk);
      ar_data = address;
      ar_valid = 1;
      while (!ar_ready) @(negedge clk);
      @(negedge clk);
      ar_valid = 0;
      while (!r_valid) @(negedge clk);
      value = r_data;
      response = r_resp;
      @(negedge clk);
      check(r_valid && r_data == value && r_resp == response,
            "read response held under backpressure");
      r_ready = 1;
      @(negedge clk);
      r_ready = 0;
    end
  endtask

  always @(posedge clk)
    if (model_write_valid) begin
      case (model_pulses)
        0: check(!model_is_bias && model_layer == 1 && model_index == 0,
                 "layer 1 weight 0 route");
        1: check(!model_is_bias && model_layer == 1 && model_index == 1,
                 "layer 1 weight 1 route");
        2: check(!model_is_bias && model_layer == 2 && model_index == 0,
                 "layer 2 weight route");
        3: check(!model_is_bias && model_layer == 3 && model_index == 0,
                 "layer 3 weight route");
        4: check(model_is_bias && model_layer == 1, "layer 1 bias route");
        5: check(model_is_bias && model_layer == 2, "layer 2 bias route");
        6: check(model_is_bias && model_layer == 3, "layer 3 bias route");
      endcase
      check(model_write_data == model_pulses, "model write data");
      model_pulses = model_pulses + 1;
    end

  always @(posedge clk)
    if (network_start)
      start_pulses = start_pulses + 1;

  reg [1:0] response;
  reg [31:0] value;
  integer i;

  initial begin
    repeat (3) @(posedge clk);
    reset_n = 1;

    axi_read(8'h04, value, response);
    check(response == 0 && value[5] && value[1], "default model is valid and idle");

    axi_write(8'h00, 32'h2, 1, response);
    check(response == 0, "W-before-AW load begin");
    axi_read(8'h08, value, response);
    check(value == 32'h0001_0000, "model cursor reset");

    axi_write(8'h0c, 0, 0, response);
    axi_write(8'h00, 32'h2, 0, response);
    model_pulses = 0;
    axi_read(8'h10, value, response);
    check(response == 0 && value == 0, "load begin restarts a partial load");
    axi_read(8'h08, value, response);
    check(value == 32'h0001_0000, "restart resets model cursor");

    for (i = 0; i < 7; i = i + 1) begin
      axi_write(8'h0c, i, i[0], response);
      check(response == 0, "model data write response");
    end
    check(model_pulses == 7, "all model writes routed");

    axi_write(8'h0c, 32'hdeadbeef, 0, response);
    check(response == 2'b10, "extra model write rejected");
    axi_write(8'h00, 32'h10, 0, response);
    check(response == 0, "clear error");
    axi_write(8'h00, 32'h4, 0, response);
    check(response == 0, "model commit");

    axi_write(8'h20, 32'h1234, 0, response);
    check(response == 2'b10, "input before start rejected without deadlock");
    axi_write(8'h00, 32'h11, 0, response);
    check(response == 0, "start after rejected input");
    check(start_pulses == 1, "network start pulse");
    @(negedge clk);
    network_idle = 0;

    fork
      begin
        axi_write(8'h20, 32'h00001234, 1, response);
        check(response == 0, "input write completed after ready");
      end
      begin
        repeat (5) @(negedge clk);
        check(!b_valid, "input write stalls while network not ready");
        network_ready = 1;
        @(negedge clk);
        network_ready = 0;
      end
    join
    check(network_input_data == 16'h1234, "input data routed");

    network_output_data = 16'h0007;
    network_output_data_valid = 1;
    @(negedge clk);
    network_output_data_valid = 0;
    network_idle = 1;
    axi_read(8'h24, value, response);
    check(response == 0 && value == 7, "latched nonblocking result read");

    axi_write(8'h00, 32'h2, 0, response);
    axi_write(8'h0c, 7, 0, response);
    @(negedge clk);
    reset_n = 0;
    repeat (2) @(negedge clk);
    reset_n = 1;
    axi_read(8'h04, value, response);
    check(!value[5], "reset during loading preserves invalid model state");

    if (failures == 0)
      $display("PASS: axi_wrapper_tb");
    else
      $display("FAIL: axi_wrapper_tb had %0d failures", failures);
    $finish(failures != 0);
  end
endmodule

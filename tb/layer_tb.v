`timescale 1ns/1ps
// ================================================================
// tb_layer_1.v  –  diagnostic testbench for layer_1
//
// Compile:
//   iverilog -o sim tb_layer_1.v layer_1.v neuron.v \
//            weight_mem.v bias_mem.v signed_adder.v relu.v sigmoid.v
//   vvp sim | tee run.log
// ================================================================
module tb_layer_1;

// ---- parameters ------------------------------------------------
localparam DATA_WIDTH = 16;
localparam N_NEURONS  = 30;
localparam N_WEIGHTS  = 784;
localparam CLK_HALF   = 5;
localparam HARD_STOP  = 200_000;     // absolute cycle limit

// ---- DUT ports -------------------------------------------------
reg                               clk;
reg                               reset;
reg                               input_valid;
reg  [DATA_WIDTH-1:0]             input_value;
wire [(DATA_WIDTH*N_NEURONS)-1:0] output_values;
wire                              outputs_valid;
wire                              layer_ready;

// ---- counters --------------------------------------------------
integer total_cycles;
integer i;

// ---- DUT -------------------------------------------------------
layer_1 #(
    .DATA_WIDTH         (DATA_WIDTH),
    .WEIGHT_WIDTH       (DATA_WIDTH),
    .N_WEIGHTS          (N_WEIGHTS),
    .N_NEURONS          (N_NEURONS),
    .N_INPUTS           (N_WEIGHTS),
    .SIGMOID_INPUT_WIDTH(5),
    .ACC_TYPE           ("reLU"),
    .WEIGHT_INT_WIDTH   (1),
    .BIAS_WIDTH         (2*DATA_WIDTH)
) DUT (
    .clk          (clk),
    .reset        (reset),
    .input_valid  (input_valid),
    .input_value  (input_value),
    .output_values(output_values),
    .outputs_valid(outputs_valid),
    .layer_ready  (layer_ready)
);

// ---- clock -----------------------------------------------------
initial clk = 0;
always  #CLK_HALF clk = ~clk;

// ================================================================
// WATCHDOG – fires at HARD_STOP regardless of any stuck loop.
// Prints full pipeline state of NEURON_0 so you can see exactly
// which pipeline stage is stuck.
// ================================================================
initial begin
    total_cycles = 0;
    forever begin
        @(posedge clk);
        total_cycles = total_cycles + 1;
        if (total_cycles >= HARD_STOP) begin
            $display("");
            $display("[WATCHDOG] %0d cycles – force stopping.", total_cycles);
            $display("[WATCHDOG] layer_ready         = %b", layer_ready);
            $display("[WATCHDOG] outputs_valid       = %b", outputs_valid);
            $display("[WATCHDOG] outputs_valid_array = %b", DUT.outputs_valid_array);
            $display("[WATCHDOG] neuron_ready_array  = %b", DUT.neuron_ready_array);
            $display("[WATCHDOG] Neurons that never fired (flag=0):");
            for (i = 0; i < N_NEURONS; i = i + 1)
                if (!DUT.outputs_valid_array[i])
                    $display("              NEURON_%0d", i);
            $display("[WATCHDOG] NEURON_0 pipeline state:");
            $display("   current_address   = %0d",
                                        DUT.NEURON_0.current_address);
            $display("   last_x_valid_seen = %b",
                                        DUT.NEURON_0.last_x_valid_seen);
            $display("   last_flag_d1      = %b",
                                        DUT.NEURON_0.last_flag_d1);
            $display("   last_flag_d2      = %b",
                                        DUT.NEURON_0.last_flag_d2);
            $display("   x_value_delay     = %b",
                                        DUT.NEURON_0.x_value_delay);
            $display("   weights_valid     = %b",
                                        DUT.NEURON_0.weights_valid);
            $display("   multiply_valid    = %b",
                                        DUT.NEURON_0.multiply_valid);
            $display("   final_MAC_valid   = %b",
                                        DUT.NEURON_0.final_MAC_valid);
            $display("   activation_valid  = %b",
                                        DUT.NEURON_0.activation_valid);
            $display("   output_valid      = %b",
                                        DUT.NEURON_0.output_valid);
            $display("   output_valid_flag = %b",
                                        DUT.NEURON_0.output_valid_flag);
            $display("   accumulated_sum   = %h",
                                        DUT.NEURON_0.accumulated_sum);
            $display("   neuron_ready      = %b",
                                        DUT.NEURON_0.neuron_ready);
            $finish;
        end
    end
end

// ================================================================
// Periodic status print every 1000 cycles once inputs are started.
// ================================================================
reg inputs_started;
initial inputs_started = 0;

always @(posedge clk) begin
    if (inputs_started && (total_cycles % 1000 == 0)) begin
        $display("[cycle %0d] ready=%b valid=%b array=%b",
            total_cycles, layer_ready, outputs_valid,
            DUT.outputs_valid_array);
        $display("           N0: addr=%0d mult=%b fmac=%b act=%b outv=%b flag=%b",
            DUT.NEURON_0.current_address,
            DUT.NEURON_0.multiply_valid,
            DUT.NEURON_0.final_MAC_valid,
            DUT.NEURON_0.activation_valid,
            DUT.NEURON_0.output_valid,
            DUT.NEURON_0.output_valid_flag);
    end
end

// ================================================================
// Catch outputs_valid going high at ANY cycle – this fires even
// during the input-sending phase.
// ================================================================
always @(posedge clk) begin
    if (outputs_valid) begin
        $display("[cycle %0d] *** outputs_valid ASSERTED ***", total_cycles);
        $display("           outputs_valid_array = %b", DUT.outputs_valid_array);
        $display("           --- Neuron outputs ---");
        for (i = 0; i < N_NEURONS; i = i + 1)
            $display("           output[%02d] = 0x%04h  (%0d)",
                i,
                output_values[i*DATA_WIDTH +: DATA_WIDTH],
                $signed(output_values[i*DATA_WIDTH +: DATA_WIDTH]));
        // If this fires early (e.g. due to unresolved chunk_serializer or
        // initialisation bugs) it will be visible here.
    end
end

// ================================================================
// Main stimulus
// ================================================================
initial begin : stimulus
    integer inputs_sent;

    // --- reset ---
    input_valid = 0;
    input_value = 0;
    reset       = 1;
    repeat(4) @(posedge clk);
    reset = 0;
    @(posedge clk);

    $display("==============================================");
    $display("  TB_LAYER_1  N_WEIGHTS=%0d  N_NEURONS=%0d", N_WEIGHTS, N_NEURONS);
    $display("==============================================");

    // --- wait for layer_ready after reset ---
    $display("[%0d] Waiting for layer_ready...", total_cycles);
    while (!layer_ready) @(posedge clk);
    $display("[%0d] layer_ready asserted.", total_cycles);

    // --- print initial neuron state to catch any initialisation issues ---
    $display("[%0d] Initial state check:", total_cycles);
    $display("  neuron_ready_array  = %b  (all 1 = OK)", DUT.neuron_ready_array);
    $display("  outputs_valid_array = %b  (all 0 = OK)", DUT.outputs_valid_array);
    $display("  NEURON_0:");
    $display("    output_valid      = %b  (0 = OK)", DUT.NEURON_0.output_valid);
    $display("    output_valid_flag = %b  (0 = OK)", DUT.NEURON_0.output_valid_flag);
    $display("    final_MAC_valid   = %b  (0 = OK)", DUT.NEURON_0.final_MAC_valid);
    $display("    current_address   = %0d (0 = OK)", DUT.NEURON_0.current_address);

    inputs_started = 1;

    // --- feed N_WEIGHTS inputs ---
    $display("[%0d] Sending %0d inputs...", total_cycles, N_WEIGHTS);
    for (inputs_sent = 0; inputs_sent < N_WEIGHTS; inputs_sent = inputs_sent + 1) begin

        // Handshake: wait for all 30 neurons ready
        while (!layer_ready) @(posedge clk);

        // 1-cycle pulse
        input_value = inputs_sent[DATA_WIDTH-1:0] + 1;
        input_valid = 1;
        @(posedge clk);
        input_valid = 0;

        // Progress every 100 inputs
        if ((inputs_sent % 100) == 0)
            $display("[%0d]   input[%0d] sent  N0.cur_addr=%0d",
                total_cycles, inputs_sent, DUT.NEURON_0.current_address);
    end

    $display("[%0d] *** All %0d inputs sent ***", total_cycles, N_WEIGHTS);
    $display("  NEURON_0.current_address   = %0d  (expect %0d)",
        DUT.NEURON_0.current_address, N_WEIGHTS);
    $display("  NEURON_0.last_x_valid_seen = %b",
        DUT.NEURON_0.last_x_valid_seen);
    $display("  NEURON_0.last_flag_d2      = %b",
        DUT.NEURON_0.last_flag_d2);
    $display("  outputs_valid_array        = %b",
        DUT.outputs_valid_array);
    $display("  (waiting for outputs_valid – watchdog fires at %0d cycles)", HARD_STOP);
    // The always blocks above handle outputs_valid and the watchdog.
end

// ---- waveform dump (depth limited to keep VCD small) -----------
initial begin
    $dumpfile("tb_layer_1.vcd");
    $dumpvars(1, tb_layer_1);
    $dumpvars(0, tb_layer_1.DUT.NEURON_0);  // full NEURON_0 internals
end

endmodule

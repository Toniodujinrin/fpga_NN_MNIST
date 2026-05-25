`timescale 1ns / 1ps
module tb_network;

    // ----------------- Parameters -----------------
    localparam DATA_WIDTH          = 16;
    localparam N_NETWORK_INPUTS    = 784;
    localparam N_NEURONS_LAYER_3   = 10;
    localparam ACC_TYPE            = "reLU";     // matches fpga_NN_MNIST.v
    localparam SIGMOID_INPUT_WIDTH = 5;
    localparam WEIGHT_INT_WIDTH    = 1;

    // ----------------- Signals -----------------
    reg  clk;
    reg  reset;
    reg  [DATA_WIDTH-1:0] network_input_value;
    reg  network_input_valid;
    wire network_inference_sample_ready;
    wire network_inference_ready;
    wire [(DATA_WIDTH*N_NEURONS_LAYER_3)-1:0] network_output;
    wire network_output_valid;
    reg  inference_start;
    //debug 
    // wire layer_1_ready; 
    // wire layer_1_output_valid; 
    // wire [DATA_WIDTH-1:0] layer_2_serializer_out_debug;
    // wire layer_1_serializer_busy_debug;  
    // wire layer_2_serializer_busy_debug; 
    // wire layer_2_fifo_empty_debug;
    // wire layer_1_serializer_out_debug; 
    // wire layer_2_input_value_debug; 
    // wire layer_2_input_valid_debug;
    

    integer i, cycle;

    // ----------------- DUT -----------------
    network #(
        .DATA_WIDTH(DATA_WIDTH),
        .N_NEURONS_LAYER_1(30),
        .N_NEURONS_LAYER_2(30),
        .N_NEURONS_LAYER_3(N_NEURONS_LAYER_3),
        .N_NETWORK_INPUTS(N_NETWORK_INPUTS),
        .ACC_TYPE(ACC_TYPE),
        .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
        .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH)
    ) DUT (
        .clk                        (clk),
        .reset                      (reset),
        .network_input_value        (network_input_value),
        .network_input_valid        (network_input_valid),
        .network_inference_sample_ready (network_inference_sample_ready),
        .network_inference_ready    (network_inference_ready),
        .network_output             (network_output),
        .network_output_valid       (network_output_valid),
        .inference_start            (inference_start),

        //debug
        // .layer_1_ready_out              (layer_1_ready), 
        // .layer_1_output_valid           (layer_1_output_valid), 
        // .layer_2_serializer_out_debug (layer_2_serializer_out_debug),
        // .layer_1_serializer_busy_debug (layer_1_serializer_busy_debug),  
        // .layer_2_serializer_busy_debug (layer_2_serializer_busy_debug), 
        // .layer_2_fifo_empty_debug (layer_2_fifo_empty_debug), 
        // .layer_1_serializer_out_debug (layer_1_serializer_out_debug),  
        // .layer_2_input_value_debug (layer_2_input_value_debug), 
        // .layer_2_input_valid_debug (layer_2_input_valid_debug)


    );

    // ----------------- Clock -----------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100 MHz
    end

    // ----------------- Reset -----------------
    initial begin
        reset = 1;
        #20 reset = 0;
    end

    // ----------------- Stimulus (exact FSM handshake) -----------------
    initial begin
        $display("=== NETWORK ISOLATED TEST START (exact fpga_NN_MNIST handshake) ===");
        inference_start     = 0;
        network_input_value = 0;
        network_input_valid = 0;
        cycle = 0;

        #50;  // wait for reset to settle

        // === STEP 1: Wait for network to be ready, then pulse inference_start ===
        $display("Waiting for network_inference_ready...");
        while (!network_inference_ready) begin
            @(posedge clk);
            cycle = cycle + 1;
        end
        $display("network_inference_ready asserted at cycle %0d → pulsing inference_start", cycle);

        inference_start = 1;
        @(posedge clk);
        inference_start = 0;

        // === STEP 2: Feed 784 inputs whenever sample_ready pulses ===
        $display("Starting input streaming...");
        for (i = 0; i < N_NETWORK_INPUTS; i = i + 1) begin
            // Wait for sample_ready (exactly like the INFERENCE state in fpga_NN_MNIST)
            while (!network_inference_sample_ready) begin
                @(posedge clk);
                cycle = cycle + 1;
            end

            // Drive next input (ramp pattern - easy to replace with real .mif data)
            network_input_value = i + 1;   // 1, 2, 3, ..., 784
            network_input_valid = 1;

            @(posedge clk);
            network_input_valid = 0;
            cycle = cycle + 1;

            // Optional progress print every 100 inputs
            if (i % 100 == 0)
                $display("  Sent input %0d / %0d at cycle %0d", i, N_NETWORK_INPUTS, cycle);
        end

        $display("All %0d inputs sent at cycle %0d", N_NETWORK_INPUTS, cycle);

        // === STEP 3: Wait for final network output ===
        while (!network_output_valid) begin
            @(posedge clk);
            cycle = cycle + 1;
            if (cycle > 200000) begin
                $display("TIMEOUT waiting for network_output_valid");
                $finish;
            end
        end

        // === STEP 4: Print results ===
        $display("=== NETWORK OUTPUT VALID at cycle %0d ===", cycle);
        for (i = 0; i < N_NEURONS_LAYER_3; i = i + 1) begin
            $display("  output[%0d] = %0d (0x%04h)", 
                     i,
                     $signed(network_output[i*DATA_WIDTH +: DATA_WIDTH]),
                     network_output[i*DATA_WIDTH +: DATA_WIDTH]);
        end

        #200 $finish;
    end

    // ----------------- Waveform dump -----------------
    initial begin
        $dumpfile("tb_network.vcd");
        $dumpvars(0, tb_network);
    end

    // === DEBUG: confirm neuron parameter width ===
    initial begin
        #100;  // after reset
        $display("=== NEURON PARAMETER CHECK ===");
        $display("  N_WEIGHTS          = %0d", DUT.LAYER_1.NEURON_0.N_WEIGHTS);
        $display("  WEIGHT_ADDRESS_WIDTH = %0d", DUT.LAYER_1.NEURON_0.WEIGHT_ADDRESS_WIDTH);
    end

endmodule

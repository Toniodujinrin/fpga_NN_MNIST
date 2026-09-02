`timescale 1ns / 1ps
module tb_fpga_NN_MNIST;

    // ----------------- Parameters -----------------

    localparam N_NETWORK_INPUTS = 784;  
    localparam N_NEURONS_LAYER_1 = 64; 
    localparam N_NEURONS_LAYER_2 = 64; 
    localparam N_NEURONS_LAYER_3 = 10; 
    localparam ACC_TYPE = "reLU";
    localparam SIGMOID_INPUT_WIDTH = 5; 
    localparam DATA_WIDTH = 16;
    localparam AXI_ADDR_WIDTH = 8; 
    localparam AXI_WRITE_RESPONSE_WIDTH = 1;

    // ----------------- Signals -----------------
      reg clk;  
      reg reset_n; 

      //AXI Signals
      //write address channel  
      reg aw_valid; 
      reg [AXI_ADDR_WIDTH-1:0]  aw_data;
      wire aw_ready;
      reg aw_prot;

      //write data channel 
      reg w_valid; 
      wire w_ready; 
      reg [DATA_WIDTH-1:0] w_data;
      reg w_strobe; 

      //write response channel 
      wire b_valid; 
      reg b_ready;
      wire b_resp; 
      
      //read addr signals 
      reg [AXI_ADDR_WIDTH-1:0] ar_data;
      wire ar_ready;
      reg ar_valid;
      reg ar_prot;
      //read data signals 
      wire [DATA_WIDTH-1:0] r_data; 
      wire r_valid;
      reg r_ready;
      wire r_resp;
  // ----------------- DUT -----------------

fpga_NN_MNIST
#( 
	.N_NETWORK_INPUTS(N_NETWORK_INPUTS), 
	.N_NEURONS_LAYER_1(N_NEURONS_LAYER_1), 
	.N_NEURONS_LAYER_2(N_NEURONS_LAYER_2), 
	.N_NEURONS_LAYER_3(N_NEURONS_LAYER_3), 
	.ACC_TYPE(ACC_TYPE), 
	.SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH), 
	.DATA_WIDTH(DATA_WIDTH), 
  .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH), 
  .AXI_WRITE_RESPONSE_WIDTH(AXI_WRITE_RESPONSE_WIDTH)
)
DUT
(
    .clk(clk), 
    .reset_n(reset_n),

    //AXI Signals
    //write address channel  
    .aw_valid(aw_valid), 
    .aw_data(aw_data),
    .aw_ready(aw_ready), 
    .aw_prot(aw_prot), 

    //write data channel 
    .w_valid(w_valid), 
    .w_ready(w_ready), 
    .w_data(w_data),
    .w_strobe(w_strobe), 

    //write response channel 
    .b_valid(b_valid), 
    .b_ready(b_ready), 
    .b_resp(b_resp), 
    
    //read addr signals 
    .ar_data(ar_data),
    .ar_ready(ar_ready),
    .ar_valid(ar_valid),
    .ar_prot(ar_prot), 
    //read data signals 
    .r_data(r_data), 
    .r_valid(r_valid),
    .r_ready(r_ready),
    .r_resp(r_resp)
  );     

// ----------------- Clock -----------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100 MHz
    end

    // ----------------- Reset -----------------
    initial begin
        reset_n = 0;
        #20 reset_n = 1;
    end



    // ----------------- Stimulus (exact FSM handshake) -----------------
    integer fd; 
    integer status;
    integer pixel_count; 
    reg [DATA_WIDTH-1:0] data_in; 
   
    initial begin
        aw_valid = 0;
        aw_data  = 0;
        aw_prot  = 0;
        w_valid  = 0;
        w_data   = 0;
        w_strobe = 0;
        b_ready  = 0;
        ar_valid = 0;
        ar_data  = 0;
        ar_prot  = 0;
        r_ready  = 0;
        data_in  = 0;
        pixel_count = 0;
 
        @(posedge reset_n);
        @(posedge clk);
 
        fd = $fopen("input_1.txt", "r");
        if (fd == 0) begin
            $display("ERROR: could not open input_1.txt");
            $finish;
        end
 
        while (!$feof(fd)) begin
            status = $fscanf(fd, "%b\n", data_in);
            if (status != 1) begin
                $display("WARNING: fscanf returned %0d at pixel %0d", status, pixel_count);
            end
            $display("[%0t] Sending pixel %0d : %b (%0d)", $time, pixel_count, data_in, data_in);
 
            aw_valid = 1; 
            aw_data  = 8'h01;   
            while (!aw_ready) begin
                $display("[%0t] waiting for aw_ready", $time);
                @(posedge clk);
            end
            @(posedge clk);
            aw_valid = 0; 
            aw_data  = 0;
            w_data  = data_in; 
            w_valid = 1;
            while (!w_ready) begin
                $display("[%0t] waiting for w_ready", $time);
                @(posedge clk);
            end
            @(posedge clk); 
            w_valid = 0; 
            w_data  = 0;
            b_ready = 1;
            
            while (!b_valid) begin
                $display("[%0t] waiting for b_valid", $time);
                @(posedge clk);
            end
            @(posedge clk);
            b_ready = 0;
            pixel_count = pixel_count + 1;
        end
 
        $fclose(fd);
        $display("[%0t] All %0d pixels sent.", $time, pixel_count);
    end
    
    //------------------Extract Data -------------------
    initial begin 
        ar_valid = 0;  
        ar_data = 0; 
        r_ready = 0; 
        
        @(posedge reset_n); 
        @(posedge clk); 
        ar_valid = 1; 
        ar_data = 8'b01; 

        while(!ar_ready)
          @(posedge clk); 
        @(posedge clk);

        r_ready = 1; 
        while(!r_valid)
          @(posedge clk); 
        @(posedge clk); 
        r_ready = 0; 
        $display("Received output: %h", r_data); 
    end 
    // ----------------- Waveform dump -----------------
    initial begin
        $dumpfile("tb_fpga_NN_MNIST.vcd");
        $dumpvars(0, tb_fpga_NN_MNIST);
    end

endmodule

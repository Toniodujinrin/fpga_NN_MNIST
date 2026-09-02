module
network
#(
  parameter 
  DATA_WIDTH = 16, 
  N_NEURONS_LAYER_1 = 64, 
  N_NEURONS_LAYER_2 = 64,  
  N_NEURONS_LAYER_3 = 10, 
  N_NETWORK_INPUTS = 784,
  ACC_TYPE = "sigmoid", 
  SIGMOID_INPUT_WIDTH = 5,
  WEIGHT_INT_WIDTH = 1
)
(
  input clk, reset,
  input [DATA_WIDTH-1:0] network_input_value,  
  output wire [(DATA_WIDTH*N_NEURONS_LAYER_3)-1:0] network_output, 
  output reg network_inference_sample_ready, //true if the network is ready to recieve the next sample of an inference
  output reg network_inference_ready, //true if the network has just completed an inference, or if no inference has started at all 
  output wire network_output_valid, 
  input wire network_input_valid, 
  input wire inference_start
); 
  localparam WEIGHT_WIDTH = DATA_WIDTH; 
  localparam BIAS_WIDTH = 2*DATA_WIDTH; 
  localparam IDLE = 2'b00; 
  localparam INFERENCE = 2'b01; 
  localparam INFERENCE_SUB_STATE = 2'b10; 
  reg [1:0] current_state;

  //network signals 
  assign network_output_valid = layer_3_output_valid; 
  assign network_output = layer_3_output_values; 
  
  //LAYER 1 SIGNALS
  wire layer_1_ready; 
  wire [(DATA_WIDTH*N_NEURONS_LAYER_1)-1:0] layer_1_output_values; 
  wire [DATA_WIDTH-1:0] layer_1_serializer_out ; 
  wire layer_1_serializer_busy; 
  wire layer_1_fifo_full; 
  wire layer_1_fifo_empty; 
  wire layer_1_output_valid; 

  //LAYER 2 SIGNALS
  wire layer_2_output_valid; 
  wire layer_2_ready; 
  wire layer_2_input_valid; 
  wire [DATA_WIDTH-1:0] layer_2_input_value;
  wire [(DATA_WIDTH*N_NEURONS_LAYER_2)-1:0] layer_2_output_values; 
  wire layer_2_serializer_busy; 
  wire layer_2_fifo_full; 
  wire layer_2_fifo_empty;
  wire [DATA_WIDTH-1:0] layer_2_serializer_out; 
  
  //LAYER 3 SIGNALS
  wire layer_3_ready; 
  wire layer_3_input_valid; 
  wire [DATA_WIDTH-1:0] layer_3_input_value; 
  wire [(DATA_WIDTH*N_NEURONS_LAYER_3)-1:0] layer_3_output_values; 
  wire layer_3_output_valid;

  layer_1 #(
    .DATA_WIDTH(DATA_WIDTH), 
    .WEIGHT_WIDTH(WEIGHT_WIDTH), 
    .N_WEIGHTS(N_NETWORK_INPUTS), 
    .N_NEURONS(N_NEURONS_LAYER_1), 
    .N_INPUTS(N_NETWORK_INPUTS), 
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH), 
    .ACC_TYPE(ACC_TYPE), 
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH), 
    .BIAS_WIDTH(BIAS_WIDTH) 
  ) 
  LAYER_1 (
    .clk(clk), 
    .reset(reset),
    .input_valid(network_input_valid), 
    .input_value(network_input_value), 
    .output_values(layer_1_output_values), 
    .outputs_valid(layer_1_output_valid), 
	 .layer_ready(layer_1_ready)
  ); 
  
  
   chunk_serializer
	#(
		.DATA_WIDTH(DATA_WIDTH*N_NEURONS_LAYER_1), 
		.CHUNK_WIDTH(DATA_WIDTH) 
	)
	LAYER_1_OUTPUT_SERIALIZER
	(
	  .clk(clk),
	  .reset(reset), 
		.in(layer_1_output_values),
		.serializer_start(layer_1_output_valid), 
		.out(layer_1_serializer_out),
		.serializer_busy(layer_1_serializer_busy), 
		.serializer_stall(layer_1_fifo_full)
	);
	
	sync_fifo
	#( 
	  .FIFO_SIZE(2**($clog2(N_NEURONS_LAYER_1))), 
    .DATA_WIDTH(DATA_WIDTH)
	)
	LAYER_1_OUTPUT_FIFO
	(
	  .clk(clk),
	  .n_reset(~reset), 
	  .in(layer_1_serializer_out), 
	  .out(layer_2_input_value),
	  .out_valid(layer_2_input_valid), 
	  .write_en(layer_1_serializer_busy), 
	  .read_en(layer_2_ready), 
	  .fifo_full(layer_1_fifo_full),
	  .fifo_empty(layer_1_fifo_empty)
	); 
	
  
  //LAYER 2 

  layer_2 
  #(
    .DATA_WIDTH(DATA_WIDTH), 
    .WEIGHT_WIDTH(WEIGHT_WIDTH), 
    .N_WEIGHTS(N_NEURONS_LAYER_1), 
    .N_NEURONS(N_NEURONS_LAYER_2), 
    .N_INPUTS(N_NEURONS_LAYER_1), 
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH), 
    .ACC_TYPE(ACC_TYPE), 
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH), 
    .BIAS_WIDTH(BIAS_WIDTH)
  ) 
  LAYER_2 (
    .clk(clk), 
    .reset(reset),
    .input_valid(layer_2_input_valid), 
    .input_value(layer_2_input_value), 
    .output_values(layer_2_output_values), 
    .outputs_valid(layer_2_output_valid), 
	 .layer_ready(layer_2_ready)

  ); 
  
  	chunk_serializer
	#(
		.DATA_WIDTH(DATA_WIDTH*N_NEURONS_LAYER_2), 
		.CHUNK_WIDTH(DATA_WIDTH) 
	)
	LAYER_2_OUTPUT_SERIALIZER
	(
	   .clk(clk),
	   .reset(reset), 
		.in(layer_2_output_values),
		.serializer_start(layer_2_output_valid), 
		.out(layer_2_serializer_out),
		.serializer_stall(layer_2_fifo_full), 
		.serializer_busy(layer_2_serializer_busy)
	);
	
	sync_fifo
	#( 
	  .FIFO_SIZE(2**($clog2(N_NEURONS_LAYER_2))), //EXTRA SPACE IN FIFO 
	  .DATA_WIDTH(DATA_WIDTH)
	)
	LAYER_2_OUTPUT_FIFO
	(
	  .clk(clk),
	  .n_reset(~reset), 
	  .in(layer_2_serializer_out), 
	  .out(layer_3_input_value),
	  .out_valid(layer_3_input_valid), 
	  .write_en(layer_2_serializer_busy), 
	  .read_en(layer_3_ready), 
	  .fifo_full(layer_2_fifo_full),
	  .fifo_empty(layer_2_fifo_empty)
	); 
	

  //LAYER 3 

  layer_3 
  #(
    .DATA_WIDTH(DATA_WIDTH), 
    .WEIGHT_WIDTH(WEIGHT_WIDTH), 
    .N_WEIGHTS(N_NEURONS_LAYER_2), 
    .N_NEURONS(N_NEURONS_LAYER_3), 
    .N_INPUTS(N_NEURONS_LAYER_2), 
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH), 
    .ACC_TYPE("linear"), 
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH), 
    .BIAS_WIDTH(2*DATA_WIDTH)
  ) 
  LAYER_3 (
    .clk(clk), 
    .reset(reset),
    .input_valid(layer_3_input_valid), 
    .input_value(layer_3_input_value), 
    .output_values(layer_3_output_values), 
    .outputs_valid(layer_3_output_valid), 
	 .layer_ready(layer_3_ready)
  ); 

  
  //control FSM
  
  always@(posedge clk or posedge reset)
  begin 
	if(reset)
		begin 
			current_state <= IDLE; 
			network_inference_ready <= 1; 
			network_inference_sample_ready <= 1; 
		end 
	else
		begin 
			case(current_state)
				IDLE: 
					if(inference_start)
						begin 
							network_inference_ready <= 0; 
							network_inference_sample_ready <= 1; 
							current_state <= INFERENCE; 
						end 
					else
						begin 
							current_state <= IDLE; 
							network_inference_ready <= 1; 
							network_inference_sample_ready <= 0; 
						end
        INFERENCE:
          if(layer_3_output_valid)
          begin
              network_inference_sample_ready <= 0;
              network_inference_ready <= 1; 
              current_state <= IDLE;
          end
          else if(layer_1_ready && network_input_valid) // Ensure data is valid before consuming
          begin
              network_inference_sample_ready <= 0;
              network_inference_sample_ready <= 0; 
              current_state <= INFERENCE_SUB_STATE;
          end
          else 
          begin
              network_inference_sample_ready <= 0;
              network_inference_sample_ready <= 0; // Hold ready low while waiting
              current_state <= INFERENCE; 
          end
				INFERENCE_SUB_STATE:
          if(layer_3_output_valid)
          begin 
              network_inference_ready       <= 1;
              network_inference_sample_ready <= 0;
              current_state                 <= IDLE;
          end
					else if(layer_1_ready)
					begin 
						network_inference_sample_ready <= 1; 
						network_inference_ready <= 0; 
						current_state <= INFERENCE; 
					end 
					else 
					begin 
						network_inference_sample_ready <= 0; 
						network_inference_ready <= 0; 
						current_state <= INFERENCE_SUB_STATE; 
					end 
			endcase 
		end 
  end
endmodule 

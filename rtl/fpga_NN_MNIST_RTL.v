module fpga_NN_MNIST_RTL
#(
	parameter 
	N_NETWORK_INPUTS = 784, 
	N_NEURONS_LAYER_1 = 64, 
	N_NEURONS_LAYER_2 = 64, 
	N_NEURONS_LAYER_3 = 10, 
	ACC_TYPE = "reLU", 
	SIGMOID_INPUT_WIDTH = 5, 
	DATA_WIDTH = 16, 
  AXI_ADDR_WIDTH = 8, 
  AXI_WRITE_RESPONSE_WIDTH = 2, 
  AXI_READ_RESPONSE_WIDTH = 2, 
  AXI_WRITE_STROBE_WIDTH = 4, 
  AXI_ADDR_WRITE_PROT_WIDTH = 3, 
  AXI_WRITE_DATA_WIDTH = 32, 
  AXI_READ_DATA_WIDTH = 32, 
  AXI_ADDR_READ_PROT_WIDTH = 3
)
(
  input clk, 
  input reset_n,

  //AXI Signals
  //write address channel  
  input awvalid, 
  input [AXI_ADDR_WIDTH-1:0]  awdata,
  output awready, 
  input [AXI_ADDR_WRITE_PROT_WIDTH-1:0] awprot, 

  //write data channel 
  input wvalid, 
  output wready, 
  input [AXI_WRITE_DATA_WIDTH-1:0] wdata,
  input [AXI_WRITE_STROBE_WIDTH-1:0] wstrobe, 

  //write response channel 
  output bvalid, 
  input bready, 
  output [AXI_WRITE_RESPONSE_WIDTH-1:0] bresp, 
  
  //read addr signals 
  input [AXI_ADDR_WIDTH-1:0] araddr,
  output arready,
  input arvalid,
  input [AXI_ADDR_READ_PROT_WIDTH-1:0] arprot, 
  //read data signals 
  output [AXI_READ_DATA_WIDTH-1:0] rdata, 
  output rvalid,
  input rready,
  output [AXI_READ_RESPONSE_WIDTH-1:0] rresp
); 

  
	localparam IDLE = 1'b0; 
  localparam INFERENCE	= 1'b1;  
		
	reg current_state; 
	
	//network signals 
	wire network_inference_sample_ready; 
	wire network_inference_ready;
	reg inference_start; 
  wire network_start;
  wire network_idle = (current_state == IDLE);
  wire [DATA_WIDTH-1:0] network_input_data; 
  wire network_input_data_valid; 
  wire model_write_valid;
  wire [1:0] model_layer;
  wire [5:0] model_neuron;
  wire [9:0] model_index;
  wire model_is_bias;
  wire [31:0] model_write_data;
  //max finder signals
	wire [(DATA_WIDTH*N_NEURONS_LAYER_3)-1:0] network_output; 
  wire network_output_valid; 
  wire nn_output_valid; 
  wire [DATA_WIDTH-1:0] nn_output; 
      
  
  network
  #(
    .DATA_WIDTH(DATA_WIDTH), 
    .N_NEURONS_LAYER_1(N_NEURONS_LAYER_1), 
    .N_NEURONS_LAYER_2(N_NEURONS_LAYER_2),  
    .N_NEURONS_LAYER_3(N_NEURONS_LAYER_3), 
    .N_NETWORK_INPUTS(N_NETWORK_INPUTS),
    .ACC_TYPE(ACC_TYPE), 
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH)
  )
  NETWORK 
  (
    .clk(clk), 
    .reset(~reset_n), 
    .network_inference_sample_ready(network_inference_sample_ready), 
	  .network_inference_ready(network_inference_ready), 
	  .network_input_value(network_input_data), 
    .network_input_valid(network_input_data_valid), 
    .network_output(network_output),  
    .network_output_valid(network_output_valid), 
	 .inference_start(inference_start),
    .model_write_valid(model_write_valid),
    .model_layer(model_layer),
    .model_neuron(model_neuron),
    .model_index(model_index),
    .model_is_bias(model_is_bias),
    .model_write_data(model_write_data)
  ); 
  
   max_finder
	#( 
	  .DATA_WIDTH(DATA_WIDTH),
	  .LAYER_N(N_NEURONS_LAYER_3)
	)
  MAX_FINDER
	(
	  .clk(clk),
	  .reset(~reset_n), 
	  .start(network_output_valid), 
	  .data(network_output),  
	  .out(nn_output), 
	  .out_valid(nn_output_valid)
	);
  
  axi_slave_wrapper
  #(
    .ADDR_WIDTH(AXI_ADDR_WIDTH),
    .DATA_WIDTH(AXI_WRITE_DATA_WIDTH),
    .N_NETWORK_INPUTS(N_NETWORK_INPUTS),
    .N_NEURONS_LAYER_1(N_NEURONS_LAYER_1),
    .N_NEURONS_LAYER_2(N_NEURONS_LAYER_2),
    .N_NEURONS_LAYER_3(N_NEURONS_LAYER_3)
  )
  AXI
  (
    .clk(clk), 
    .reset_n(reset_n), 
    //write address channel 
    .aw_ready(awready), 
    .aw_valid(awvalid), 
    .aw_data(awdata),
    .aw_prot(awprot), 
    //write data channel
    .w_data(wdata), 
    .w_ready(wready),
    .w_valid(wvalid), 
    .w_strobe(wstrobe), 
    
    //write response 
    .b_ready(bready), 
    .b_valid(bvalid), 
    .b_data(bresp), 
    
    //read address channel 
    .ar_data(araddr), 
    .ar_valid(arvalid),
    .ar_ready(arready), 
    .ar_prot(arprot), 

    //write address channel 
    .r_ready(rready), 
    .r_valid(rvalid), 
    .r_data(rdata), 
    .r_resp(rresp), 

    //network signals 
    .network_idle(network_idle),
    .network_ready(network_inference_sample_ready), 
    .network_output_data(nn_output), 
    .network_output_data_valid(nn_output_valid), 
    .network_start(network_start),
    .network_input_data(network_input_data), 
    .network_input_data_valid(network_input_data_valid),
    .model_write_valid(model_write_valid),
    .model_layer(model_layer),
    .model_neuron(model_neuron),
    .model_index(model_index),
    .model_is_bias(model_is_bias),
    .model_write_data(model_write_data)
  );  


  always@(posedge clk, negedge reset_n)
  begin 
    if(!reset_n)
    begin 
      current_state <= IDLE; 
      inference_start <= 0;
    end
    else
    begin 
      case(current_state)
        IDLE: 
        begin 
          if(network_start)
          begin 
            inference_start <= 1; 
            current_state <= INFERENCE; 
          end
          else 
          begin 
            inference_start <= 0; 
            current_state <= IDLE; 
          end 
        end
        INFERENCE: 
        begin 
          if(nn_output_valid)
          begin 
            current_state <= IDLE; 
            inference_start <= 0; 
          end 
          else 
          begin 
            current_state <= INFERENCE; 
            inference_start <= 0; 
          end 
        end
        default:
        begin
          current_state <= IDLE;
          inference_start <= 0;
        end
      endcase
    end 
  end
  

  endmodule





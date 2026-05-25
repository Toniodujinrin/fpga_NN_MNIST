module fpga_NN_MNIST
#(
	parameter 
	INPUT_ROM_FILE = "inputs/input_1.mif", 
	N_NETWORK_INPUTS = 784, 
	N_NEURONS_LAYER_1 = 30, 
	N_NEURONS_LAYER_2 = 30, 
	N_NEURONS_LAYER_3 = 10, 
	ACC_TYPE = "reLU", 
	WEIGHT_INT_WIDTH = 1, 
	SIGMOID_INPUT_WIDTH = 5, 
	DATA_WIDTH = 16
)
(
  input clk, 
  input reset,
  output nn_output_valid


  //AXI Signals
  //write address channel  
  input aw_valid, 
  input []  aw_addr,
  output reg aw_ready, 
  input aw_prot

  //write data channel 
  input w_valid, 
  output reg w_ready, 
  input [DATA_WIDTH-1:0] w_data,
  input [clog2(clog8(DATA_WIDTH))-1:0] w_strobe, 

  //write response channel 
  output reg b_valid, 
  input b_ready, 
  output reg b_resp 
  
  //read addr signals 
  input ar_addr,
  output reg ar_ready,
  input ar_valid,
  input ar_prot, 
  //read data signals 
  output reg [DATA_WIDTH-1:0] r_data, 
  output reg r_valid,
  input r_ready,
  output r_resp
); 

  
	localparam IDLE = 2'b00; 
  localparam INFERENCE	= 2'b01;  
	localparam MAX_FINDING = 2'b10; 
	
	reg [1:0] current_state; 
	
	//network signals 
	wire network_inference_sample_ready; 
	wire network_inference_ready;
	reg inference_start; 

  //max finder signals
	reg [(DATA_WIDTH*N_NEURONS_LAYER_3)-1:0] max_finder_data_in; 
	wire [(DATA_WIDTH*N_NEURONS_LAYER_3)-1:0] network_output;  
  reg max_finder_start; 
  
  //nn signals 
  wire network_output_valid; 
	reg read_en; 
  
  
  network
  #(
    .DATA_WIDTH(DATA_WIDTH), 
    .N_NEURONS_LAYER_1(N_NEURONS_LAYER_1), 
    .N_NEURONS_LAYER_2(N_NEURONS_LAYER_2),  
    .N_NEURONS_LAYER_3(N_NEURONS_LAYER_3), 
    .N_NETWORK_INPUTS(N_NETWORK_INPUTS),
    .ACC_TYPE(ACC_TYPE), 
    .SIGMOID_INPUT_WIDTH(SIGMOID_INPUT_WIDTH),
    .WEIGHT_INT_WIDTH(WEIGHT_INT_WIDTH)
  )
  NETWORK 
  (
    .clk(clk), 
    .reset(reset), 
    .network_inference_sample_ready(network_inference_sample_ready), 
	  .network_inference_ready(network_inference_ready), 
	  .network_input_value(input_rom_data_value), 
    .network_input_valid(input_rom_data_valid), 
    .network_output(network_output),  
    .network_output_valid(network_output_valid), 
	 .inference_start(inference_start)
  ); 
  
   max_finder
	#( 
	  .DATA_WIDTH(DATA_WIDTH*N_NEURONS_LAYER_3),
	  .LAYER_N(N_NEURONS_LAYER_3)
	)
  MAX_FINDER
	(
	  .clk(clk),
	  .reset(reset), 
	  .start(max_finder_start), 
	  .data(max_finder_data_in),  
	  .out(nn_output), 
	  .out_valid(nn_output_valid)
	);
  
  
  //input load FSM 
  always@(posedge clk or posedge reset)
	begin 
		if(reset)
		begin 
			current_state <= IDLE;
      //axi 
      w_ready <= 0; 
      aw_ready <= 0; 
			inference_start <= 0; 
			max_finder_start <= 0; 	
		end 
		else 
		begin 
			case(current_state)
				IDLE: 
				begin 
					if(network_inference_ready)
					begin 
						inference_start <= 1; 
						input_rom_addr <= 0;
					  max_finder_start <= 0; 
            max_finder_data_in <= 0;
            rom_counter <= 0; 
						current_state <= INFERENCE; 
					end 
					else
					begin 
						inference_start <= 0; 
						input_rom_addr <= 0; 
						max_finder_start <= 0; 	
            max_finder_data_in <= 0;
						current_state <= IDLE; 
					end
				end 
				
				INFERENCE: 
				begin 
					if(network_output_valid)
					begin 
						inference_start <= 0; 
						max_finder_start<= 1; 
						current_state <= MAX_FINDING;
            read_en <= 0; 
            max_finder_data_in <= network_output; 
					end 
					else if(network_inference_sample_ready)
					begin 
						inference_start <= 0; 
						max_finder_start<= 0; 
						input_rom_addr <= rom_counter;
            rom_counter <= rom_counter+1; 
            read_en <= 1; 
						current_state <= INFERENCE; 
					end 
          else if(!network_inference_sample_ready)
          begin 
            inference_start <= 0; 
						max_finder_start<= 0; 
            read_en <= 0; 
						current_state <= INFERENCE;
          end 
				end 
				MAX_FINDING:
				begin 
					if(nn_output_valid)
					begin 
						max_finder_start <= 0; 
						inference_start <= 0; 
						current_state <= IDLE;
          end 
					else 
					begin 
						current_state <= MAX_FINDING; 
						inference_start <= 0;
            max_finder_start <= 0; 
					end
				end 
			endcase
		end 
	end
endmodule



function integer clog8
  input integer value 
  begin 
    clog8 = clog2(value)/clog2(8); 
  end 
endfunction 

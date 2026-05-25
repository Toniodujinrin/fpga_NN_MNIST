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
  output [$clog2(N_NEURONS_LAYER_3)-1:0] nn_output, 
  output nn_output_valid
); 
	localparam ROM_ADDR_WIDTH = $clog2(N_NETWORK_INPUTS);
	localparam IDLE = 2'b00; 
   localparam INFERENCE	= 2'b01;  
	localparam MAX_FINDING = 2'b10; 
	
	reg [1:0] current_state; 
	
	
	wire network_inference_sample_ready; 
	wire network_inference_ready;
	wire [DATA_WIDTH-1:0] input_rom_data_value; 
	wire input_rom_data_valid;
	reg [ROM_ADDR_WIDTH-1:0] input_rom_addr; 
	reg inference_start; 
	reg [(DATA_WIDTH*N_NEURONS_LAYER_3)-1:0] max_finder_data_in; 
	wire [(DATA_WIDTH*N_NEURONS_LAYER_3)-1:0] network_output;  
  wire network_output_valid; 
	reg max_finder_start; 
  reg read_en; 
  reg [ROM_ADDR_WIDTH-1:0] rom_counter;  
  
	input_rom
	#( 
		.DATA_WIDTH(DATA_WIDTH),  
		.N_INPUTS(N_NETWORK_INPUTS), 
		.INPUT_ROM_FILE(INPUT_ROM_FILE), 
		.ADDR_WIDTH(ROM_ADDR_WIDTH) 
	)
  INPUT_ROM
	(
		.clk(clk), 
		.reset(reset), 
		.data_out(input_rom_data_value), 
		.out_valid(input_rom_data_valid),
    .read_en(read_en), 
		.addr_in(input_rom_addr) 
	); 

  
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
			inference_start <= 0; 
			input_rom_addr <= 0;
      rom_counter <= 0; 
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


  // //debug
  // always@(posedge clk) 
  // begin
  //   $display("[%0t] state=%0d | sample_ready=%b | output_valid=%b | addr=%0d", 
  //       $time,
  //       current_state,
  //       network_inference_sample_ready,
  //       network_output_valid,
  //       input_rom_addr
  //   );
  // end
  //
endmodule





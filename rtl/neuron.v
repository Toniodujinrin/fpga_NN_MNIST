module neuron #(
  parameter
  DATA_WIDTH = 16, 
  WEIGHT_WIDTH = 16, 
  N_WEIGHTS = 784, 
  SIGMOID_INPUT_WIDTH = 5, 
  ACC_TYPE = "sigmoid",
  WEIGHT_INT_WIDTH = 14, 
  WEIGHT_FILE = "weights/weight_file_layer_1_neuron_0.mem", //weight file for this particular neuron 
  BIAS_FILE="biases/bias_file_layer_1_neuron_0.mem", //bias file for this particular neuron 
  BIAS_WIDTH = 32
)
(
  input clk,reset, 
  input [DATA_WIDTH-1:0] x_value, 
  input x_valid, 
  output reg [DATA_WIDTH-1:0] neuron_output, 
  output reg output_valid_flag, 
  output reg neuron_ready
); 
  localparam WEIGHT_ADDRESS_WIDTH = $clog2(N_WEIGHTS); 
  reg weight_mem_read_enable; 
  reg [WEIGHT_ADDRESS_WIDTH-1:0] weight_mem_read_addr; 
  reg [WEIGHT_ADDRESS_WIDTH-1:0] current_address; 
  reg [DATA_WIDTH-1:0] x_value_reg; 
  reg [DATA_WIDTH-1:0] x_value_reg_delayed; 
  reg x_value_delay; 
  wire [WEIGHT_WIDTH-1:0] weight_mem_out; 
  wire [BIAS_WIDTH-1:0] bias_mem_out; 
  reg [2*DATA_WIDTH-1:0] accumulated_sum; 
  reg [WEIGHT_WIDTH-1:0] weight_product_operand;
  reg [DATA_WIDTH-1:0] x_value_product_operand; 
  wire [2*DATA_WIDTH-1:0] product; 
  reg [2*DATA_WIDTH-1:0] sum_operand_1; 
  wire  [2*DATA_WIDTH-1:0] adder_result; 
  wire sum_negative;
  wire sum_overflow; 
  wire sum_zero; 
  wire sum_cout;
  wire [DATA_WIDTH-1:0] activation_function_output; 
  reg weights_valid, multiply_valid, activation_valid, final_MAC_valid, output_valid;  
  reg  last_flag_d2, last_flag_d1, last_x_valid_seen; 

  assign product = $signed(x_value_product_operand)*$signed(weight_product_operand);  

  //fetch weights 
  always@(posedge clk, posedge reset)
  begin 
    if(reset)
    begin 
      weight_mem_read_addr <=  {WEIGHT_ADDRESS_WIDTH{1'b0}}; 
      current_address      <= 0; 
      x_value_reg          <= 0; 
      weight_mem_read_enable <= 0; 
      neuron_ready         <= 1; 
    end 
    else if(output_valid)
    begin
      current_address      <= 0;
      neuron_ready         <= 1;
      weight_mem_read_enable <= 0; 
      weight_mem_read_addr <=  {WEIGHT_ADDRESS_WIDTH{1'b0}}; 
      x_value_reg          <= 0; 
    end 
    else if(x_valid && neuron_ready && (current_address < N_WEIGHTS))
    begin 
      weight_mem_read_addr   <= current_address; 
      x_value_reg            <= x_value;
      current_address        <= current_address + 1; 
      weight_mem_read_enable <= 1; 
    end 
    else
    begin 
      weight_mem_read_enable <= 0; 
      //only de-assert ready when all inputs have been processed
      neuron_ready <= (current_address < N_WEIGHTS);
    end 
  end
    
  //delayed input to align with weight
  always@(posedge clk or posedge reset)
  begin 
      if(reset)
        x_value_reg_delayed <= 0; 
      else if(x_value_delay)
        x_value_reg_delayed <= x_value_reg; 
  end 


  //multiply 
  always@(posedge clk or posedge reset)
  begin 
    if(reset)
    begin 
      weight_product_operand <= 0; 
      x_value_product_operand <= 0; 
    end 
    else if(weights_valid)
    begin 
      weight_product_operand <= weight_mem_out; 
      x_value_product_operand <= x_value_reg_delayed; 
    end
   end 
  

  always @(posedge clk or posedge reset)   // ADD reset sensitivity
  begin
      if (reset)
      begin
          last_x_valid_seen <= 0;
          last_flag_d1      <= 0;
          last_flag_d2      <= 0;
      end
      else
      begin
          last_x_valid_seen <= x_valid && (current_address == N_WEIGHTS-1);
          last_flag_d1      <= last_x_valid_seen;
          last_flag_d2      <= last_flag_d1;
      end
  end

  
  always@(posedge clk or posedge reset)
  begin
      if(reset)
        sum_operand_1 <= 0; 
      else if(multiply_valid)
          sum_operand_1 <= product; 
      else if(final_MAC_valid)
          sum_operand_1 <= bias_mem_out;
  end

  always@(posedge clk, posedge reset)
  begin
      if(reset)
          accumulated_sum <= 0;
      else if(output_valid)
          accumulated_sum <= 0;
      else if(multiply_valid | final_MAC_valid)
      begin
          if(sum_overflow & sum_negative)
              accumulated_sum <= {1'b0, {((2*DATA_WIDTH)-1){1'b1}}};
          else if(sum_overflow & !sum_negative)
              accumulated_sum <= {1'b1, {((2*DATA_WIDTH)-1){1'b0}}};
          else
              accumulated_sum <= adder_result;
      end
  end  
  //combinational read bias DRAM
  bias_mem #(.BIAS_WIDTH(BIAS_WIDTH), .BIAS_FILE(BIAS_FILE)) BIAS_MEMORY(
    .bias_out(bias_mem_out)
  ); 
  weight_mem #(.N_WEIGHTS(N_WEIGHTS),.WEIGHT_WIDTH(WEIGHT_WIDTH),.WEIGHT_ADDRESS_WIDTH($clog2(N_WEIGHTS)), .WEIGHT_FILE(WEIGHT_FILE)) WEIGHT_MEMORY(
    .clk(clk), 
    .read_en(weight_mem_read_enable), 
    .weight_read_addr(weight_mem_read_addr), 
    .weight_out(weight_mem_out)
  );



 signed_adder #(.WIDTH(2*DATA_WIDTH)) SIGNED_ADDER (
    .x(sum_operand_1),
    .y(accumulated_sum),
    .s(adder_result),
    .add_sub(0), 
    .overflow(sum_overflow), 
    .negative(sum_negative), 
    .zero(sum_zero), 
    .cout(sum_cout)
 ); 

 generate
  if(ACC_TYPE == "reLU")
  begin:relu
    relu #(.INPUT_WIDTH(DATA_WIDTH*2), .OUTPUT_WIDTH(DATA_WIDTH)) RELU 
    (
      .data_in(accumulated_sum), 
      .data_out(activation_function_output)
    ); 
  end
  else if(ACC_TYPE == "linear")
  begin 
      wire [6:0] overflow_check = accumulated_sum[31:25];
      
      assign activation_function_output =
      (overflow_check != 7'b0000000 && overflow_check != 7'b1111111) ?
          (accumulated_sum[31] ? 16'h8000 : 16'h7FFF) : 
          accumulated_sum[25:10];                       
  end
  else
  begin:sigmoid
    sigmoid #(.INPUT_WIDTH(SIGMOID_INPUT_WIDTH), .OUTPUT_WIDTH(DATA_WIDTH)) SIGMOID 
    (
      .data_in(accumulated_sum[(2*DATA_WIDTH)-1-:SIGMOID_INPUT_WIDTH]), 
      .data_out(activation_function_output)
    ); 
  end 
 endgenerate 
  
always @(posedge clk, posedge reset) 
begin
  if (reset) 
	begin
    x_value_delay     <= 0;
    weights_valid     <= 0;
    multiply_valid    <= 0;
    activation_valid  <= 0;
    output_valid <= 0; 
    output_valid_flag <= 0; 
    neuron_output<= 0; 
    final_MAC_valid <= 0; 
	end 
  else if(output_valid)
  begin 
    x_value_delay     <= 0;
    weights_valid     <= 0;
    multiply_valid    <= 0;
    activation_valid  <= 0;
    output_valid      <= 0;
    neuron_output <= activation_function_output; 
    output_valid_flag <= 1; 
  end 
  else if(output_valid_flag)
  begin 
	 output_valid_flag <= 0; 
  end 
  else 
	begin
    x_value_delay <= x_valid;
    weights_valid <= x_value_delay;
    multiply_valid <= weights_valid;
    final_MAC_valid <= multiply_valid && last_flag_d2;
    activation_valid <= final_MAC_valid; 
    output_valid <= activation_valid;
    output_valid_flag <= output_valid; 
   end
 end
endmodule 


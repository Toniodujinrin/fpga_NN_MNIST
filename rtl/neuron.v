module neuron #(
  parameter
  DATA_WIDTH = 16, 
  WEIGHT_WIDTH = 16, 
  N_WEIGHTS = 784, 
  SIGMOID_INPUT_WIDTH = 5, 
  ACC_TYPE = "reLU", 
  WEIGHT_FILE = "1", //weight file for this particular neuron 
  BIAS_FILE="1", //bias file for this particular neuron 
  BIAS_WIDTH = 32
)
(
  input clk,reset, 
  input [DATA_WIDTH-1:0] x_value, 
  input x_valid, 
  output reg [DATA_WIDTH-1:0] neuron_output, 
  output reg output_valid_flag
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
  wire product_negative; 
  wire product_overflow; 
  wire product_zero; 
  wire product_cout;
  wire sum_negative;
  wire sum_overflow; 
  wire sum_zero; 
  wire sum_cout;
  wire [DATA_WIDTH-1:0] activation_function_output; 
  reg weights_valid, multiply_valid, activation_valid, final_MAC_valid, output_valid;  
  reg  last_flag_d2, last_flag_d1, last_x_valid_seen; 


  //fetch weights 
  always@(posedge clk, posedge reset)
  begin 
    if(reset)
    begin 
      weight_mem_read_addr <=  {WEIGHT_ADDRESS_WIDTH{1'b0}}; 
      
    end 
    else if(output_valid)
    begin
      current_address <= 0; 
    end 
    else if(x_valid)
    begin 
      weight_mem_read_addr <= current_address; 
      x_value_reg <= x_value;
      current_address <= current_address +1 ; 
      weight_mem_read_enable <= 1; 
    end 
    else
      weight_mem_read_enable <= 0; 
   end
    
  //delayed input to align with weight
  always@(posedge clk)
  begin 
      if(x_value_delay)
        x_value_reg_delayed <= x_value_reg; 
  end 


  //multiply 
  always@(posedge clk)
  begin 
    if(weights_valid)
    begin 
      weight_product_operand <= weight_mem_out; 
      x_value_product_operand <= x_value_reg_delayed; 
    end
   end 
  
  //sum
  always@(posedge clk)
  begin 
    if(final_MAC_valid)
      begin
        sum_operand_1 <= bias_mem_out;
      end  
    else if(multiply_valid)
      begin 
        if(product_overflow & !product_negative) //underflow, saturate to 0 
          begin 
            sum_operand_1 <= {(2*DATA_WIDTH){1'b0}}; 
          end
        else if(product_overflow & product_negative) //overflow, saturate to max capacity
          begin 
            sum_operand_1 <= {(2*DATA_WIDTH){1'b1}}; 
          end
        else
          begin 
            sum_operand_1 <= product; 
          end
      end 
  end

  always @(posedge clk) 
  begin
      last_x_valid_seen <= x_valid && (current_address == N_WEIGHTS-1);
      //delay last valid seen by 1 cycle since x_valid delayed by 1 cycle too
      last_flag_d1 <= last_x_valid_seen;
      last_flag_d2 <= last_flag_d1;
  end

  
  //accumulate sum 
  always@(posedge clk, posedge reset)
  begin
      if(reset)
          accumulated_sum <= 0;
      else if(output_valid)
          accumulated_sum <= 0;
      else if(sum_overflow & sum_negative)
          accumulated_sum <= {(2*DATA_WIDTH){1'b1}};
      else if(sum_overflow & !sum_negative)
          accumulated_sum <= {(2*DATA_WIDTH){1'b0}};
      else
          accumulated_sum <= adder_result;
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


  multiplier #(.WIDTH(DATA_WIDTH)) SIGNED_MULTIPLIER (
    .x(weight_product_operand),
    .y(x_value_product_operand), 
    .r(product), 
    .negative(product_negative), 
    .overflow(product_overflow), 
    .zero(product_zero), 
    .cout(product_cout)
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
  else 
	begin
    x_value_delay <= x_valid;
    weights_valid <= x_value_delay;
    multiply_valid <= weights_valid;
    final_MAC_valid <= multiply_valid & last_flag_d2;
    activation_valid <= final_MAC_valid; 
    output_valid <= activation_valid;
    output_valid_flag <= output_valid; 
   end
 end

endmodule 


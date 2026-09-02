module axi_slave_wrapper
#(
  parameter
  DATA_WIDTH = 16, 
  ADDR_WIDTH = 8 , 
  WRITE_STROBE_WIDTH = 1 , 
  WRITE_RESPONSE_WIDTH = 1
)
(
  input clk, 
  input reset_n, 
  //write address channel 
  output reg aw_ready, 
  input aw_valid, 
  input [ADDR_WIDTH-1:0] aw_data,
  input aw_prot, 

  //write data channel
  input [DATA_WIDTH-1:0] w_data, 
  output reg w_ready,
  input  w_valid, 
  input [WRITE_STROBE_WIDTH-1:0] w_strobe, 
  
  //write response 
  input b_ready, 
  output reg b_valid, 
  output reg [WRITE_RESPONSE_WIDTH-1:0] b_data, 
  
  //read address channel 
  input [DATA_WIDTH-1:0] ar_data, 
  input ar_valid,
  output reg ar_ready, 
  input ar_prot, 

  //write address channel 
  input r_ready, 
  output reg r_valid, 
  output reg [DATA_WIDTH-1:0] r_data, 
  output reg r_resp, 

  //network signals 
  input network_ready, 
  input [DATA_WIDTH-1:0] network_output_data, 
  input network_output_data_valid, 
  output reg [DATA_WIDTH-1:0] network_input_data, 
  output reg network_input_data_valid
); 

  //write transaction state machine 
  localparam [1:0] W_IDLE = 2'b00; 
  localparam [1:0] W_ADDR_WAIT = 2'b01; 
  localparam [1:0] W_DATA_WAIT = 2'b10;  
  localparam [1:0] W_RESP_WAIT = 2'b11; 
  reg [1:0] current_write_state; 
  
  //respond codes
  localparam OKAY = 2'b00; 
  localparam EXOXAY = 2'b01; 
  localparam SLVERR = 2'b10; 
  localparam DECERR = 2'b11; 

  reg [ADDR_WIDTH-1:0] write_address;
   

  always@(posedge clk, negedge reset_n)
  begin 
    if(!reset_n)
    begin 
      current_write_state <= W_IDLE;
      aw_ready<= 0; 
      w_ready <= 0; 
      b_valid <= 0; 
      b_data <= 0; 
      network_input_data <= 0; 
      network_input_data_valid <= 0;
      write_address <= 0;
    end 
    else 
    begin 
      case(current_write_state)
        W_IDLE: 
        begin 
          if(network_ready)
          begin
            current_write_state<= W_ADDR_WAIT; 
            aw_ready <= 1; 
            w_ready <= 0; 
            b_valid <= 0; 
            b_data <= 0; 
            write_address <= 0;
            network_input_data <= 0; 
            network_input_data_valid <= 0;
          end
          else
          begin 
            current_write_state <= W_IDLE;
            aw_ready<= 0; 
            w_ready <= 0; 
            b_valid <= 0; 
            b_data <= 0; 
            write_address <= 0; 
            network_input_data <= 0; 
            network_input_data_valid <= 0;
          end 
        end 

        W_ADDR_WAIT:
        begin 
          if(aw_valid)
          begin 
            current_write_state <= W_DATA_WAIT; 
            aw_ready<= 0; 
            w_ready <= 1; 
            b_valid <= 0; 
            b_data <= 0; 
            write_address <= aw_data; 
            network_input_data <= 0; 
            network_input_data_valid <= 0; 
          end 
          else
          begin 
            current_write_state <= W_ADDR_WAIT; 
            aw_ready<= 1; 
            w_ready <= 0; 
            b_valid <= 0; 
            b_data <= 0; 
            write_address <= 0; 
            network_input_data <= 0; 
            network_input_data_valid <= 0; 
          end 
        end 

        W_DATA_WAIT: 
        begin 
          if(w_valid & w_ready)
          begin 
            current_write_state <= W_RESP_WAIT; 
            aw_ready<= 0; 
            w_ready <= 0; 
            network_input_data <= w_data; 
            network_input_data_valid <= 1; 
            b_valid <= 1; 
            b_data <= OKAY; 
          end 
          else
          begin 
            current_write_state <= W_DATA_WAIT; 
            aw_ready<= 0; 
            w_ready <= 1; 
            network_input_data <= 0; 
            network_input_data_valid <= 0; 
            b_valid <= 0; 
            b_data <= 0; 
          end 
        end 

        W_RESP_WAIT: 
        begin 
          if(b_ready & b_valid)
          begin 
            current_write_state <= W_IDLE; 
            aw_ready<= 0; 
            w_ready <= 0; 
            write_address <= 0; 
            network_input_data <= 0; 
            network_input_data_valid <= 0; 
            b_valid <= 0; 
            b_data <= 0; 
          end 
          else
          begin 
            current_write_state <= W_RESP_WAIT; 
            aw_ready<= 0; 
            w_ready <= 0; 
            network_input_data <= 0; 
            network_input_data_valid <= 0; 
            b_valid <= 1; 
            b_data <= b_data;
          end 
          end
      endcase
    end 
  end


  
  //read transaction state machine 
  localparam R_IDLE = 00; 
  localparam R_ADDR_WAIT = 01; 
  localparam R_DATA_WAIT = 10; 
  reg [1:0] current_read_state; 
  reg [ADDR_WIDTH-1:0] read_address; 
  always@(posedge clk, negedge reset_n)
  begin 
    if(!reset_n)
    begin 
      current_read_state <= R_IDLE; 
      ar_ready <= 0; 
      r_data <= 0; 
      r_valid <= 0; 
      read_address <= 0; 
    end 
    else
    begin 
      case(current_read_state)
        R_IDLE: 
        begin 
          if(network_output_data_valid)
          begin
            current_read_state <= R_ADDR_WAIT; 
            ar_ready <= 1; 
            r_data <= network_output_data; 
            r_valid <= 0; 
            read_address <= 0; 
          end 
          else
          begin 
            current_read_state <= R_IDLE; 
            ar_ready <= 0; 
            r_data <= 0; 
            r_valid <= 0; 
            read_address <= 0; 
          end 
        end 
        R_ADDR_WAIT:
        begin 
          if(ar_ready & ar_valid)
          begin 
            current_read_state <= R_DATA_WAIT; 
            ar_ready <= 0; 
            read_address <= ar_data; 
            r_valid <= 1; 
            r_data <= r_data; 
            r_resp <= OKAY; 
          end 
          else
          begin 
            current_read_state <= R_ADDR_WAIT; 
            ar_ready <= 1; 
            read_address <= 0; 
            r_valid <= 0; 
            r_data <= r_data; 
            r_resp <= 0; 
          end 
        end 

        R_DATA_WAIT:
        begin 
          if(r_valid & r_ready)
          begin 
            current_read_state <= R_IDLE; 
            read_address <= 0; 
            r_data <= r_data; 
            r_valid <= 0; 
            ar_ready <= 0; 
            r_resp <= 0; 
          end 
          else 
          begin 
            current_read_state <= R_DATA_WAIT; 
            read_address <= read_address; 
            r_data <= r_data; 
            r_valid <= 1; 
            r_resp <= r_resp; 
            ar_ready <= 0; 
          end 
        end 
      endcase 
    end 
  end 

endmodule 

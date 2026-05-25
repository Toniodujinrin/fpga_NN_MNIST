module axi_slave_wrapper
#(
  DATA_WIDTH = 16, 
  ADDR_WIDTH = 8 , 
  STROBE_WIDTH = 1 , 
  WRITE_RESPONSE_WIDTH = 
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
  input [STROBE_WIDTH-1:0] w_strobe
  
  //write response 
  input b_ready, 
  output b_valid, 
  output [WRITE_RESPONSE_WIDTH-1:0] b_data, 
  
  //read address channel 
  input [DATA_WIDTH-1:0] ar_data, 
  input ar_valid,
  output ar_ready, 
  input ar_prot, 

  //write address channel 
  input r_ready, 
  output reg r_valid, 
  output reg [DATA_WIDTH-1:0] r_data, 
  output reg r_resp

  //network signals 
  input network_ready, 
  input [DATA_WIDTH-1:0] network_output_data, 
  input network_output_data_valid, 
  output reg [DATA_WIDTH-1:0] network_input_data, 
  output reg network_input_data_valid, 
); 

  //write transaction state machine 
  localparam W_IDLE = 00; 
  localparam W_ADDR_WAIT = 01; 
  localparam W_DATA_WAIT = 10;  
  localparam W_RESP_WAIT = 11; 
  reg [1:0] current_write_state; 

  reg [ADDR_WIDTH-1:0] write_address;
   

  always(@posedge clk, negedge reset_n)
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
            current_write_state <= IDLE;
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
          if(aw_valid & w_ready)
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
            b_data <= 1; 
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
            address <= 0; 
            network_input_data <= 0; 
            network_input_data_valid <= 0; 
            b_valid <= 0; 
            b_data <= 0; 
          end 
          else 
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
  localparam R_IDLE = 00,
  localparam R_ADDR_WAIT = 01,
  localparam R_DATA_WAIT = 10, 
  reg current_read_state; 
  reg read_address; 
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
            ar_ready <= 1; 
            r_data <= network_output_data; 
            r_valid <= 1; 
            read_address <= 0; 
          end 
          else
          begin 

          end 
        end 
        R_ADDR_WAIT:
        begin 
          
        end 

        R_DATA_WAIT:
        begin 

        end 
        
      endcase 
    end 
  end 
      

endmodule 

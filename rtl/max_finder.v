module max_finder #(
  parameter DATA_WIDTH = 2,
  LAYER_N = 3
)(
  input clk, reset,
  input start,
  input [(DATA_WIDTH*LAYER_N)-1:0] data,
  output reg [$clog2(LAYER_N)-1:0] out,
  output reg out_valid
);

  reg [DATA_WIDTH-1:0] max_val;
  reg [$clog2(LAYER_N)-1:0] max_pointer;   
  reg [$clog2(LAYER_N)-1:0] current_pointer;
  reg [(DATA_WIDTH*LAYER_N)-1:0] data_reg;
  reg current_state;

  localparam IDLE = 0;
  localparam SEARCH = 1;

  always@(posedge clk, posedge reset)
  begin
    if(reset)
    begin
      current_pointer <= 0;
      max_pointer     <= 0;
      out_valid       <= 0;
      out             <= 0;               
      max_val         <= 0;
      current_state   <= IDLE;
      data_reg        <= 0;
    end
    else
    begin
      case(current_state)
        IDLE:
        begin
          if(!start)
            out_valid <= 0;                 
          else if (start)
          begin
            data_reg        <= data;
            max_val         <= data[DATA_WIDTH-1:0];
            max_pointer     <= 0;
            current_pointer <= 0;
            current_state   <= SEARCH;
            out             <= 0;
          end
        end

        SEARCH:
        begin
          if(current_pointer < LAYER_N)   
          begin
            reg [DATA_WIDTH-1:0] candidate = data_reg[((current_pointer+1)*DATA_WIDTH)-1 -: DATA_WIDTH];
            if($signed(max_val) < $signed(candidate))
            begin
              max_val     <= candidate;
              max_pointer <= current_pointer;
            end
            current_pointer <= current_pointer + 1;
          end
          else
          begin
            current_state <= IDLE;
            out           <= max_pointer;
            out_valid     <= 1;           
          end
        end
      endcase
    end
  end
endmodule

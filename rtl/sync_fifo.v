module sync_fifo
#(
  parameter 
  FIFO_SIZE = 8, 
  ADDR_WIDTH = 3, 
  DATA_WIDTH = 8
)
(
  input clk, n_reset, 
  input [DATA_WIDTH-1:0] in, 
  output reg [DATA_WIDTH-1:0] out,
  output reg out_valid, 
  input write_en, 
  input read_en, 
  output fifo_full, fifo_empty
); 
  reg [ADDR_WIDTH-1:0] read_addr; 
  reg [ADDR_WIDTH-1:0] write_addr; 
  reg [DATA_WIDTH-1:0] mem [0:FIFO_SIZE-1]; 
  assign fifo_full =(write_addr == {~ (read_addr[ADDR_WIDTH-1: ADDR_WIDTH-2]), read_addr[ADDR_WIDTH-3: 0]})? 1'b1: 1'b0;
  assign fifo_empty = read_addr == write_addr; 
  

  always@(posedge clk or negedge n_reset)
  begin 
    if(!n_reset)
      begin 
        read_addr <= 0; 
        write_addr <= 0;
      end 
    else
      begin 
        if (~fifo_empty & read_en)
          read_addr <= read_addr + 1'b1;
        if (~fifo_full & write_en)
          begin 
            mem[write_addr] <= in; 
            write_addr <= write_addr + 1'b1;
          end 
      end 
  end
  
    
  
  //combinational read 
  always@(*)
    begin 
      out = mem[read_addr];
      if(read_en & ~fifo_empty)
        out_valid = 1'b1; 
      else 
        out_valid = 1'b0; 
    end

endmodule 





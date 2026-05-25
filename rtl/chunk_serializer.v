module chunk_serializer
#(
  parameter
	DATA_WIDTH = 32, 
	CHUNK_WIDTH = 8
)
(
  input clk, reset, 
	input [DATA_WIDTH-1:0] in,
	input serializer_start,
	input serializer_stall, 
	output reg [CHUNK_WIDTH-1:0] out,
	output reg serializer_busy
); 
	localparam N_CHUNKS = DATA_WIDTH/CHUNK_WIDTH; 
	reg [$clog2(N_CHUNKS):0] pointer; 
	localparam [1:0] IDLE = 2'b00; 
	localparam [1:0] WRITE = 2'b01;
	localparam [1:0] STALL = 2'b10; 
	reg [1:0] current_state; 
   reg [DATA_WIDTH-1:0] in_reg;  


	always@(posedge clk or posedge reset)
	begin 
		if(reset)
		begin 
			current_state<= IDLE; 
			serializer_busy <= 0; 
			pointer <= 0; 
			in_reg <= 0; 
		end 
		else
		begin 
			case(current_state)
				IDLE: 
          if(serializer_start)
          begin 
              current_state   <= WRITE; 
              pointer         <= 1;               
              serializer_busy <= 1;
              in_reg          <= in;
              out             <= in[CHUNK_WIDTH-1:0]; 
          end
					else
						begin 
							current_state <= IDLE; 
							pointer <= 0; 
							serializer_busy <= 0;
							in_reg <= in; //fill register with external data 
						end 
				WRITE: 
					begin 
						if(pointer != N_CHUNKS && !serializer_stall)
							begin 
								current_state <= WRITE; 
								out <= in_reg[((pointer+1)*CHUNK_WIDTH)-1 -: CHUNK_WIDTH]; 
								pointer <= pointer + 1; 
								serializer_busy <= 1; 
							end 
						else if(pointer != N_CHUNKS && serializer_stall)
							begin 
								current_state <= STALL; 
								pointer <= pointer; 
								serializer_busy <= 1; 
							end 
						else if(pointer == N_CHUNKS)
							begin 
								current_state <= IDLE; 
								serializer_busy<= 0;
							end 	
					end 
STALL: 
    if(!serializer_stall)
        begin 
            current_state   <= WRITE;
            serializer_busy <= 1;
            // immediately output the pending chunk
            out <= in_reg[((pointer+1)*CHUNK_WIDTH)-1 -: CHUNK_WIDTH];
            pointer <= pointer + 1;
        end 
    else 
        begin 
            current_state   <= STALL;
            serializer_busy <= 1;
        end
			endcase 
		end 
	end 

endmodule 

module input_rom
#(
	parameter 
	DATA_WIDTH = 16,  
	N_INPUTS = 784, 
	INPUT_ROM_FILE = "inputs/input_1.mif", 
	ADDR_WIDTH = 10 
)
(
	input clk, reset, 
  input read_en, 
	output reg [DATA_WIDTH-1:0] data_out, 
	output reg out_valid, 
	input [ADDR_WIDTH-1:0] addr_in
); 

	reg [DATA_WIDTH-1:0] mem [0:N_INPUTS-1];
	
	initial
	begin 
		$readmemb(INPUT_ROM_FILE, mem); 
	end 
	
	always@(posedge clk or posedge reset)
	begin 
		if(reset)
			begin
				data_out <= 0; 
				out_valid <= 0;
			end
		else if(read_en)
			begin
				data_out <= mem[addr_in]; 
				out_valid <= 1;
			end
    else
    begin 
        out_valid <= 0; 
    end 
	end 
endmodule

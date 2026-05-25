//reusable modules	
module simplified_signed_adder(x, y, add_sub, cout, s);
	parameter WIDTH = 8; 
	input [WIDTH-1:0] x, y; 
	input add_sub;
	output [WIDTH-1:0] s; 
	output cout; 

	wire [WIDTH-1:0] couts;  
	wire [WIDTH-1:0] _y; 
	
	assign cout = couts[WIDTH-1]; 
	
	genvar i; 
	generate
		for(i = 0; i < WIDTH; i = i+1)
			begin: compliment_y
				assign _y[i] = y[i] ^ add_sub;
			end
	endgenerate

	carry_look_adder #(.WIDTH(WIDTH)) A1(x, _y, add_sub, s, couts);
endmodule 


//carry look ahead adder implementation
module carry_look_adder  (x,y,cin,s,cout);

	parameter WIDTH = 16; 
	input [WIDTH-1:0] x, y; 
	input cin; 
	output [WIDTH-1:0] s, cout; 
	
	
	wire [WIDTH:0] c;
	wire [WIDTH-1:0] g, p;
	
	assign g = x & y;
	assign p = x | y;
	assign c[0] = cin;

	genvar i;
	generate
		for (i = 1; i <= WIDTH; i = i + 1) begin: carry_chain
			assign c[i] = g[i-1] | (p[i-1] & c[i-1]);
		end
	endgenerate

	assign s = x ^ y ^ c[WIDTH-1:0];
	assign cout = c[WIDTH:1];
endmodule

//D type flip flop 
module d_ff(clk, d, q, reset);
	input clk; 
	input d, reset; 
	output reg q; 
	always @(posedge clk, posedge reset)
		begin
			if(reset)
				q <= 0; 
			else
				q <= d; 
		end 
endmodule 

//n bit chained 2 to 1 MUX with shared select line 
module chained_mux(x,y,s,out); 
	parameter WIDTH = 7; 
	input [WIDTH-1:0] x,y; 
	input s; 
	output [WIDTH-1:0] out; 
	
	genvar i; 
	generate 
		for(i=0; i< WIDTH; i = i+1)
		begin : SINGLE_MUX
			mux MUX(.x(x[i]),.y(y[i]),.s(s),.out(out[i])); 
		end 
	endgenerate 
endmodule 


//2 to 1 MUX implementation 
module mux(x,y,s,out);
	input x,y,s; 
	output out; 
	assign out = s?x:y; 
endmodule









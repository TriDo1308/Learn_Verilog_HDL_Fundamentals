module ADD_SUB_Sharing (
	input  wire					ADD_SUB_Select_in,
    input  wire signed [15:0]   a_in,                   // input A (Q8.7)
    input  wire signed [15:0]   b_in,                   // input B (Q8.7)
    output wire  signed [15:0]  c_out
);

    //==================================================//
    //                   	Wire                      	//
    //==================================================//
	
	wire signed [16:0] 			ADD_w, SUB_w, c_w;
	
	
	//==================================================//
    //              Combinational Circuits              //
    //==================================================//
	
	assign ADD_w 				= a_in + b_in;
	assign SUB_w 				= a_in - b_in;
	
	assign c_w					= (ADD_SUB_Select_in) ? SUB_w : ADD_w;
	
	assign c_out 				= (c_w > 32767) ? 17'sd32767 :
								  (c_w < -32768) ? -17'sd32768 : c_w[15:0];					
endmodule

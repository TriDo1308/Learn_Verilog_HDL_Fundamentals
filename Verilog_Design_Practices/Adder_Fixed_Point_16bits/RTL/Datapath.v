module Datapath (
    input  wire                 CLK,
	input  wire					RST,
	input  wire					En_in,
    input  wire signed [15:0]   a_in,        			// Input A (Q8.7)
    input  wire signed [15:0]   b_in,        			// Input B (Q8.7)
    output reg  signed [15:0]   c_out,       			// Output C (Q8.7)
	output reg 					c_valid_out
);

    //==================================================//
    //                   	Wire                      	//
    //==================================================//
    wire signed [16:0] 			sum_w;   

	//==================================================//
    //              Combinational Circuits              //
    //==================================================//
    assign sum_w 				= a_in + b_in;

	//==================================================//
    //              	Sequential Circuits             //
    //==================================================//
    always @(posedge CLK or negedge RST) begin
		if(RST == 0) begin
			c_out				<= 0;
			c_valid_out			<= 0;
		end
        else begin
			if(En_in) begin
				c_valid_out		<= 1;
				if (sum_w > 32767)
					c_out 		<= 17'sd32767;
				else if (sum_w < -32768)
					c_out 		<= -17'sd32768;
				else
					c_out 		<= sum_w[15:0];
			end
			else begin
				c_out			<= c_out;
				c_valid_out		<= 0;
			end
		end
    end

endmodule

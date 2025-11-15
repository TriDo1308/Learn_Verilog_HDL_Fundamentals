module Datapath (
    input  wire                 CLK,
	input  wire					RST,
	input  wire					En_in,
    input  wire signed [7:0]    a_in,        			// input A (Q4.3)
    input  wire signed [7:0]    b_in,        			// input B (Q4.3)
    output reg  signed [7:0]    c_out,       			// output C (Q4.3)
	output reg 					c_valid_out
);

    //==================================================//
    //                   	Wire                      	//
    //==================================================//
    wire signed [8:0] 			sum_w;   

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
				if (sum_w > 127)
					c_out 		<= 8'sd127;
				else if (sum_w < -128)
					c_out 		<= -8'sd128;
				else
					c_out 		<= sum_w[7:0];
			end
			else begin
				c_out			<= c_out;
				c_valid_out		<= 0;
			end
		end
    end

endmodule

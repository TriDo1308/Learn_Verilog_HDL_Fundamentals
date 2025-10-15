module d_latch_rst_n(
    input d,
	input enable,
	input reset_n,
	output q,
    output q_not
    );

	reg dlatch;					// Latch needs to hold its state when enable = 0 (no new assignment → reg retains previous value).

	// The D-Lach is level sensitive
	always @(enable or d or reset_n) begin
	    if (!reset_n)
		    dlatch <= 1'b0;
	    else if(enable)
		    dlatch <= d; 
	end

	assign q = dlatch;
	assign q_not = ~q;
endmodule

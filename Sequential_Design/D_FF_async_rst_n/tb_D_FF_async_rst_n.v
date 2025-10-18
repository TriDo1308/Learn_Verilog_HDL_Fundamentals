`timescale 1us/1ns

module tb_D_FF_rst_n();
	// Testbench variables
    reg d;
	reg clk = 0;
	reg reset_n;
	wire q;
    wire q_not;
	reg [1:0] delay;
    integer i;
	
	// Instantiate the DUT
	D_FF_async_rst_n DFF0
	(
	    .reset_n(reset_n),
	    .clk    (clk    ),
        .d      (d      ),
	    .q      (q      ),
        .q_not  (q_not  )
	);
	
	// Create the clk signal
	always begin
	    #0.5 clk = ~clk;
	end
	
    // Create stimulus	  
    initial begin
        reset_n = 0; d = 0;
		for (i = 0; i < 4; i = i + 1) begin
		   delay = i + 1;
		   #(delay) d = ~d;
		end
		
		reset_n = 1;
	    for (i = 0; i < 4; i = i + 1) begin
		   delay = i + 1;
		   #(delay) d = ~d;                     // toggle the FF at random times
		end	
        #(0.2); reset_n = 0;                    // reset the FF again		
	end
	
    // This will stop the simulator when the time expires
    initial begin
        #40 $finish;
    end  
endmodule

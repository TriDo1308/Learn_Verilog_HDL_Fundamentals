`timescale 1us/1ns

module tb_d_latch_rst_n();
	// Testbench variables
    reg d;
	reg enable;
	reg reset_n;
	wire q;
    wire q_not;
    
	// Instantiate the DUT
	d_latch_rst_n DL0
	(
        .d      (d      ),
	    .enable (enable ),
		.reset_n(reset_n),
	    .q      (q      ),
        .q_not  (q_not  )
	);
	
    // Create stimulus	  
    initial begin
	    $monitor ($time, " enable = %b, d = %b, q = %b, q_not = %b",
		                   enable, d, q, q_not);
        enable = 0; reset_n = 0;
		#2  ; d = 0;
	    #0.5; d = 1;
		#1  ; d = 0;
		#1  ; d = 1;
		#1.5; enable = 1;
		#0.1; d = 1; 
		#0.2; d = 0; reset_n = 1;
		#0.3; d = 1;
		#1  ; enable = 0; d = 0;
		#1  ; d = 1; reset_n = 0;
		#2  ; d = 0;
	end
	
    // This will stop the simulator when the time expires
    initial begin
        #40 $finish;
    end
endmodule

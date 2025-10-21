`timescale 1us/1ns

module tb_lfsr_16();
	// Testbench variables
    reg clk = 0;
    reg reset_n;
	reg enable;
    wire [15:0] lfsr;
	
	// Instantiate the DUT
    lfsr_16 LSFR
	(
		.clk    (clk    ),
		.reset_n(reset_n),
		.enable (enable ),
		.lfsr   (lfsr   )
	);

	// Create the clock signal
	always begin
	    #0.5 clk = ~clk;
	end
	
    // Create stimulus	  
    initial begin	 
	    $monitor($time, " enable = %d, lfsr = 0x%x", enable, lfsr);
	    #1  ; reset_n = 0; enable = 0;          // apply reset
		#1.2; reset_n = 1;                      // release reset
		repeat(2) @(posedge clk); 
		enable = 1;
		
	    repeat(10) @(posedge clk); 
		enable = 0;
	end
	
    // This will stop the simulator when the time expires
    initial begin
        #20 $stop;
    end  
endmodule

/* Output
0  enable = x, lfsr = 0xxxxx
1  enable = 0, lfsr = 0x1001
4  enable = 1, lfsr = 0x2003
5  enable = 1, lfsr = 0x4007
6  enable = 1, lfsr = 0x800e
7  enable = 1, lfsr = 0x001d
8  enable = 1, lfsr = 0x003a
9  enable = 1, lfsr = 0x0074
10 enable = 1, lfsr = 0x00e8
11 enable = 1, lfsr = 0x01d0
12 enable = 1, lfsr = 0x03a0
13 enable = 1, lfsr = 0x0740
14 enable = 0, lfsr = 0x0740
*/
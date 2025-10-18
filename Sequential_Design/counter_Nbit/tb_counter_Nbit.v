`timescale 1us/1ns

module tb_counter_nbit();
	// Testbench variables
	parameter CNT_WIDTH = 3;
    reg clk = 0;
    reg reset_n;
    wire [CNT_WIDTH-1:0] counter;
	
	// Instantiate the DUT
    counter_nbit 
    // Parameters section
    #(.CNT_WIDTH(CNT_WIDTH)) 
    CNT_NBIT0
    (
        .clk(clk),
        .reset_n(reset_n),
        .counter(counter)
    );
	
	// Create the clock signal
	always begin
	    #0.5 clk = ~clk;
	end
	
    // Create stimulus	  
    initial begin	 
        $monitor($time, " counter = %d", counter);	
	    #1  ; reset_n = 0; 	        // apply reset
		#1.2; reset_n = 1;          // release reset
	end
	
    // This will stop the simulator when the time expires
    initial begin
        #20 $stop;
    end  
endmodule

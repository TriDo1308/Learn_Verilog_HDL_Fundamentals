`timescale 1us/1ns

module tb_shift_left_right_reg();
	// Testbench variables
    reg clk = 0;
	reg reset_n;
	reg [7:0] i;         
	reg load_enable; 
    reg shift_left_right;
	wire [7:0] q;

	// Instantiate the DUT
    shift_left_right_load_reg SRL0
	(
	    .clk             (clk             ),
	    .reset_n         (reset_n         ),
	    .i               (i               ),         
	    .load_enable     (load_enable     ),     
        .shift_left_right(shift_left_right),
	    .q               (q               )
    );
	
	// Create the clock signal
	always begin
	    #0.5 clk = ~clk;
	end
	
    // Create stimulus	  
    initial begin
	    $monitor($time," i = %8b, load_enable = %1b, shift_left_right = %1b, q = %8b", 
		               i, load_enable, shift_left_right, q);

	    #1;                                     // Apply reset to the circuit
        reset_n = 0; i = 0; load_enable = 0; shift_left_right = 0;		
		#1.3; reset_n = 1;                      // Release the reset
		
		// Set the value of i
		@(posedge clk); i = 8'b1111_1111; 
		@(posedge clk); load_enable = 1'b1;     // Enable shifting left
        
		// Wait for the bits to shift left
        repeat (5) @(posedge clk); 
        @(posedge clk); load_enable = 1'b0;	i = 8'b1010_1000;	
		@(posedge clk); load_enable = 1'b1; shift_left_right = 1;
        repeat (5) @(posedge clk); 
		@(posedge clk); 
	end
	
    // This will stop the simulator when the time expires
    initial begin
        #40 $finish;
    end  
endmodule

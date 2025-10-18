`timescale 1us/1ns

module tb_encoder_8to3();
    reg [7:0] d;
    reg enable;
    wire  [2:0] y;
	
	integer i;

    // Instantiate the DUT
    encoder_8to3 ENC3_8
    (
        .d     (d     ),
        .enable(enable),
        .y     (y     )
    );
  
    // Create stimulus
    initial begin
        $monitor($time, " d = %b, y = %d", d, y);
        #1; d = 0; enable = 0;
        for (i = 0; i<8; i=i+1) begin
            #1; d = (1 << i); enable = 1;
        end
        #1; d = 8'b1111_1111;
    end
  
endmodule

/* Output
0 d =  xxxxxxxx, y = xxx
1 d =  00000000, y = 000
2 d =  00000001, y = 000
3 d =  00000010, y = 001
4 d =  00000100, y = 010
5 d =  00001000, y = 011
6 d =  00010000, y = 100
7 d =  00100000, y = 101
8 d =  01000000, y = 110
9 d =  10000000, y = 111
10 d = 11111111, y = 000
*/
`timescale 1us/1ns

module tb_decoder_4to16();
    reg  [3:0]  a;
    wire [15:0] d;
    integer i;
   
    // Instantiate the DUT
    decoder_4to16 DEC4_16
    (
        .a(a),
        .d(d)
    );
  
    // Create stimulus
    initial begin
        $monitor($time, " a = %d, d = %b", a, d);
        #1; a = 0;
        for (i = 0; i < 16; i = i + 1) begin
            #1; a = i;
        end
    end
endmodule

/* Output
0 a =  x,  d = xxxxxxxxxxxxxxxx
1 a =  0,  d = 0000000000000001
2 a =  1,  d = 0000000000000010
3 a =  2,  d = 0000000000000100
4 a =  3,  d = 0000000000001000
5 a =  4,  d = 0000000000010000
6 a =  5,  d = 0000000000100000
7 a =  6,  d = 0000000001000000
8 a =  7,  d = 0000000010000000
9 a =  8,  d = 0000000100000000
10 a =  9, d = 0000001000000000
11 a = 10, d = 0000010000000000
12 a = 11, d = 0000100000000000
13 a = 12, d = 0001000000000000
14 a = 13, d = 0010000000000000
15 a = 14, d = 0100000000000000
16 a = 15, d = 1000000000000000
*/
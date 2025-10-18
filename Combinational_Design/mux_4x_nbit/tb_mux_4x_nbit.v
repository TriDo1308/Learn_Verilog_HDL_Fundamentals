`timescale 1us/1ns

module tb_mux_4x_nbit();
    parameter BUS_WIDTH = 8;
    reg [BUS_WIDTH - 1 : 0] a;
    reg [BUS_WIDTH - 1 : 0] b;
    reg [BUS_WIDTH - 1 : 0] c;
    reg [BUS_WIDTH - 1 : 0] d;
    reg [1:0] sel;
    wire [BUS_WIDTH - 1 : 0] y;
    integer i;

    // Instantiate the DUT 
    mux_4x_nbit
    #(.BUS_WIDTH(BUS_WIDTH))
    MUX0
    (
        .a  (a  ),
        .b  (b  ),
        .c  (c  ),
        .d  (d  ),
        .sel(sel),
        .y  (y  )
    );
  
    // Create stimulus
    initial begin
        $monitor($time, " a = %d, b = %d, c = %d, d = %d, sel = %d, y = %d", 
                 a, b, c, d, sel, y);
        #1; sel = 0; a = 0; b = 0; c = 0; d = 0;
        for (i = 0; i < 8; i = i + 1) begin
            #1; sel = $urandom%4; a = $urandom; b = $urandom; c = $urandom; d = $urandom;
        end
    end
endmodule

/* Output
0 a =   x, b =   x, c =   x, d =   x, sel = x, y =   x
1 a =   0, b =   0, c =   0, d =   0, sel = 0, y =   0
2 a = 204, b =  86, c =  44, d =  55, sel = 3, y =  55
3 a = 145, b =   6, c = 124, d = 231, sel = 3, y = 231
4 a = 179, b = 151, c = 195, d = 185, sel = 2, y = 195
5 a = 171, b = 235, c = 198, d =  66, sel = 3, y =  66
6 a = 127, b =  85, c =  90, d = 106, sel = 3, y = 106
7 a = 156, b =  25, c = 154, d = 241, sel = 3, y = 241
8 a =   4, b =  12, c =  15, d =  30, sel = 3, y =  30
9 a =   0, b = 145, c = 170, d =  12, sel = 2, y = 170
*/
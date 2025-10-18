`timescale 1us/1ns

module tb_logic();
    reg a;
    reg b;
    wire c;
	
    // Instantiate the DUT
    some_logic LOGIC
    (
        .a(a),
        .b(b),
        .c(c)
    );

    // Toggle a and b
    initial begin
        $monitor("a = %b, b = %b, c = %b", a ,b ,c);
        #1; a = 0; b = 0;
        #1; a = 1; b = 0;
        #1; a = 0; b = 1;
        #1; a = 1; b = 1;
        #1;
    end
endmodule

/* Output
a = x, b = x, c = x
a = 0, b = 0, c = 0
a = 1, b = 0, c = 1
a = 0, b = 1, c = 1
a = 1, b = 1, c = 1
*/
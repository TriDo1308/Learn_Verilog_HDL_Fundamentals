module testbench();
    // Declare variables and nets for module ports
    reg [3:0] a;
    reg [3:0] b;
    reg cin;
    wire [3:0]sum;
    wire cout; 
  
    integer i, j; // used for verification
    parameter LOOP_LIMIT = 4;
    
    // Instantiate the module
    ripple_adder_4bit_dataflow RIPPLE_ADD_4BIT
    (
        .a        (a   ),
        .b        (b   ),
        .carry_in (cin ),
        .sum      (sum ),
        .carry_out(cout)
    );
  
    // Generate stimulus and monitor module ports
    always @(*) begin
        $display("a = %0d, b = %0d, carry_in = %0b, sum = %0d, carry_out = %b", a, b, cin, sum, cout);
    end  
  
    initial begin
        // Change the values of a and b and observe the effects
        for (i = 0; i < LOOP_LIMIT; i = i + 1) begin
            for (j = 0; j < LOOP_LIMIT; j = j + 1) begin
                #1 a = i; b = j; cin = i % 2;
            end
        end
        // Change the loops limits observe the effects
    end
endmodule

/* OUTPUT
a = 0, b = 0, carry_in = 0, sum = 0, carry_out = 0
a = 0, b = 1, carry_in = 0, sum = 1, carry_out = 0
a = 0, b = 2, carry_in = 0, sum = 2, carry_out = 0
a = 0, b = 3, carry_in = 0, sum = 3, carry_out = 0
a = 1, b = 0, carry_in = 1, sum = 2, carry_out = 0
a = 1, b = 1, carry_in = 1, sum = 3, carry_out = 0
a = 1, b = 2, carry_in = 1, sum = 4, carry_out = 0
a = 1, b = 3, carry_in = 1, sum = 5, carry_out = 0
a = 2, b = 0, carry_in = 0, sum = 2, carry_out = 0
a = 2, b = 1, carry_in = 0, sum = 3, carry_out = 0
a = 2, b = 2, carry_in = 0, sum = 4, carry_out = 0
a = 2, b = 3, carry_in = 0, sum = 5, carry_out = 0
a = 3, b = 0, carry_in = 1, sum = 4, carry_out = 0
a = 3, b = 1, carry_in = 1, sum = 5, carry_out = 0
a = 3, b = 2, carry_in = 1, sum = 6, carry_out = 0
a = 3, b = 3, carry_in = 1, sum = 7, carry_out = 0
*/
module full_adder_behavioral (
    input a,                // always wire
    input b,
    input carry_in,
    output reg sum,         // reg because it is used in a always procedure
    output reg carry_out
    );
  
    // Implement the circuit using Behavioral style
    always @(a or b or carry_in) begin
        sum         = a ^ b ^ carry_in;
        carry_out   = (a & b) | (carry_in & (a ^ b));
    end
);
endmodule

/* Other possible implementation */
module full_adder_behavioral (
    input a,                // always wire
    input b,
    input carry_in,
    output reg sum,         // reg because it is used in a always procedure
    output reg carry_out
    );
  
    // Implement the circuit using Behavioral style
    always @(*) begin
        {carry_out, sum} = a + b + carry_in;
    end
);
endmodule
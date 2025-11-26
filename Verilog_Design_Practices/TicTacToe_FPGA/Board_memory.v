module Board_Memory (
    input CLK, RST,
    input [3:0] addr,                   // Cell address to write (0 – 8)
    input [1:0] data_in,                // Data to write: 00 = empty, 01 = X, 10 = O
    input we,
    output reg [1:0] board [0:8]
);
    integer i;
    always @(posedge CLK or negedge RST) begin
        if (RST == 0) begin
            for (i = 0; i < 9; i = i + 1)
                board[i] <= 2'b00;
        end else if (we) begin
            board[addr] <= data_in;
        end
    end

endmodule

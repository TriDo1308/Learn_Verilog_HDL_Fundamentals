module Board_Memory (
    input CLK, RST, clear,
    input [3:0] addr,
    input [1:0] data_in,
    input we,
    output reg [17:0] board_flat          // 9 ô × 2 bit = 18 bit + 1 bit d?
);
    integer i;
    always @(posedge CLK or negedge RST) begin
        if (RST == 0) begin
            for (i = 0; i < 9; i = i + 1)
                board_flat[i*2 +: 2] <= 2'b00;
        end 
        else if (clear) begin
            board_flat <= 18'd0;          // clear toàn b? trong 1 cycle
        end
        else if (we) begin
            board_flat[addr*2 +: 2] <= data_in;
        end
    end
    // Helper ?? ??c
    wire [1:0] board [0:8];
    genvar k;
    generate
        for (k = 0; k < 9; k = k + 1) begin
            assign board[k] = board_flat[k*2 +: 2];
        end
    endgenerate
endmodule
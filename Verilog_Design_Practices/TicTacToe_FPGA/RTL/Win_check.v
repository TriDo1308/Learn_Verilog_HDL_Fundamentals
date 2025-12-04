module Win_Check (
    input [17:0] board_flat,
    output reg x_win, o_win, full
);
    wire [1:0] board [0:8];
    genvar i;
    generate
        for (i = 0; i < 9; i = i + 1) begin
            assign board[i] = board_flat[i*2 +: 2];
        end
    endgenerate
    
    integer k;
    
    always @(*) begin
        x_win = 0; o_win = 0; full = 1;
        
        // 8 ways to win
        if ((board[0] == 2'b01 && board[1] == 2'b01 && board[2] == 2'b01) ||
            (board[3] == 2'b01 && board[4] == 2'b01 && board[5] == 2'b01) ||
            (board[6] == 2'b01 && board[7] == 2'b01 && board[8] == 2'b01) ||
            (board[0] == 2'b01 && board[3] == 2'b01 && board[6] == 2'b01) ||
            (board[1] == 2'b01 && board[4] == 2'b01 && board[7] == 2'b01) ||
            (board[2] == 2'b01 && board[5] == 2'b01 && board[8] == 2'b01) ||
            (board[0] == 2'b01 && board[4] == 2'b01 && board[8] == 2'b01) ||
            (board[2] == 2'b01 && board[4] == 2'b01 && board[6] == 2'b01))
            x_win = 1;

        if ((board[0] == 2'b10 && board[1] == 2'b10 && board[2] == 2'b10) ||
            (board[3] == 2'b10 && board[4] == 2'b10 && board[5] == 2'b10) ||
            (board[6] == 2'b10 && board[7] == 2'b10 && board[8] == 2'b10) ||
            (board[0] == 2'b10 && board[3] == 2'b10 && board[6] == 2'b10) ||
            (board[1] == 2'b10 && board[4] == 2'b10 && board[7] == 2'b10) ||
            (board[2] == 2'b10 && board[5] == 2'b10 && board[8] == 2'b10) ||
            (board[0] == 2'b10 && board[4] == 2'b10 && board[8] == 2'b10) ||
            (board[2] == 2'b10 && board[4] == 2'b10 && board[6] == 2'b10))
            o_win = 1;

        // Check full
        for (k = 0; k < 9; k = k + 1)
            if (board[k] == 2'b00) full = 0;
    end

endmodule

module Core (
    input  wire        CLK,
    input  wire        RST,
    input  wire [7:0]  Rx_Byte_in,
    input  wire        Rx_DV_in,
    input  wire        Tx_Done_in,
    output wire        Tx_DV_out,
    output wire [7:0]  Tx_Byte_out,
    output wire [7:0]  board_led
);

    wire we_mem;
    wire [3:0] addr_mem;
    wire [1:0] data_in_mem;
    wire [1:0] board [0:8];
    wire x_win, o_win, full;

    // AI signals
    wire [3:0] ai_move;
    wire       ai_valid;

    wire [1:0] current_state_from_ctrl;

    Controller ctrl 
    (
        .CLK(CLK),
        .RST(RST),
        .Rx_Byte_in(Rx_Byte_in), 
        .Rx_DV_in(Rx_DV_in),
        .Tx_Done_in(Tx_Done_in),
        .board(board),
        .x_win(x_win), 
        .o_win(o_win), 
        .full(full),
        .ai_move(ai_move), 
        .ai_valid(ai_valid),
        .we_mem(we_mem), 
        .addr_mem(addr_mem), 
        .data_in_mem(data_in_mem),
        .Tx_DV(Tx_DV_out), 
        .Tx_Byte(Tx_Byte_out),
        .current_state_out(current_state_from_ctrl)
    );

    Board_Memory mem 
    (
        .CLK(CLK),
        .RST(RST),
        .addr(addr_mem),
        .data_in(data_in_mem),
        .we(we_mem),
        .board_out(board)
    );

    Win_Check checker 
    (
        .board_in(board),
        .x_win(x_win),
        .o_win(o_win),
        .full(full)
    );

    Minimax ai 
    (
        .CLK(CLK),
        .RST(RST),
        .board_in(board),
        .request(current_state_from_ctrl == 2'b10),
        .best_move(ai_move),
        .valid(ai_valid)
    );

    genvar i;
    generate
        for (i = 0; i < 9; i = i + 1) begin
            assign board_led[i < 4 ? i : i - 1] = (board[i] != 2'b00);
        end
    endgenerate

endmodule
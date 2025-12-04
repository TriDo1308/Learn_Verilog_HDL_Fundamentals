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
    wire [17:0] board_flat;
    wire [1:0] board [0:8];
    wire x_win, o_win, full;
    
    // Generate board array t? flat
    genvar g;
    generate
        for (g = 0; g < 9; g = g + 1) begin
            assign board[g] = board_flat[g*2 +: 2];
        end
    endgenerate

    // AI signals
    wire [3:0] ai_move;
    wire       ai_valid;

    wire [1:0] current_state_from_ctrl;
    
    wire clear_board_w;

    Controller ctrl 
    (
        .CLK(CLK),
        .RST(RST),
        .Rx_Byte_in(Rx_Byte_in), 
        .Rx_DV_in(Rx_DV_in),
        .Tx_Done_in(Tx_Done_in),
        .board_flat(board_flat),
        .x_win(x_win), 
        .o_win(o_win), 
        .full(full),
        .ai_move(ai_move), 
        .ai_valid(ai_valid),
        .we_mem(we_mem), 
        .addr_mem(addr_mem), 
        .data_in_mem(data_in_mem),
        .clear_board(clear_board_w),
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
        .clear(clear_board_w),
        .board_flat(board_flat)
    );

    Win_Check checker 
    (
        .board_flat(board_flat),
        .x_win(x_win),
        .o_win(o_win),
        .full(full)
    );

    Minimax ai 
    (
        .CLK(CLK),
        .RST(RST),
        .board_flat(board_flat),
        .request(current_state_from_ctrl == 2'b10),
        .best_move(ai_move),
        .valid(ai_valid)
    );

    assign board_led[0] = (board[0] != 2'b00);
    assign board_led[1] = (board[1] != 2'b00);
    assign board_led[2] = (board[2] != 2'b00);
    assign board_led[3] = (board[3] != 2'b00);
    assign board_led[4] = (board[5] != 2'b00);
    assign board_led[5] = (board[6] != 2'b00);
    assign board_led[6] = (board[7] != 2'b00);
    assign board_led[7] = (board[8] != 2'b00);

endmodule
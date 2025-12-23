module Core (
    input  wire        CLK,
    input  wire        RST,
    /* From RX UART Interface */
    input  wire [7:0]  Rx_Byte_in,
    input  wire        Rx_DV_in,
    /* From TX UART Interface */
    input  wire        Tx_Done_in,
    /* To TX UART Interface */
    output wire        Tx_DV_out,
    output wire [7:0]  Tx_Byte_out,
    /* To LED Display */
    output wire [7:0]  board_led
);

    wire        we_mem;
    wire [3:0]  addr_mem;
    wire [1:0]  data_in_mem;
    wire [17:0] board_flat;
    wire [1:0]  board [0:8];
    wire        x_win, o_win, full;
    
    genvar g;
    generate
        for (g = 0; g < 9; g = g + 1) begin
            assign board[g] = board_flat[g*2 +: 2];
        end
    endgenerate

    // AI signals
    wire [3:0]  ai_move;
    wire        ai_valid;

    wire [1:0]  current_state_from_ctrl;
    
    wire        clear_board_w;

    Controller ctrl 
    (
        .CLK              (CLK                    ),
        .RST              (RST                    ),
        /* From RX UART Interface */
        .Rx_Byte_in       (Rx_Byte_in             ), 
        .Rx_DV_in         (Rx_DV_in               ),
        /* From TX UART Interface */
        .Tx_Done_in       (Tx_Done_in             ),
        /* From Board Memory */
        .board_flat       (board_flat             ),
        /* From Win Check */
        .x_win            (x_win                  ), 
        .o_win            (o_win                  ), 
        .full             (full                   ),
        /* From Minimax */
        .ai_move          (ai_move                ),
        .ai_valid         (ai_valid               ),
        /* To Board Memory */
        .addr_mem         (addr_mem               ),
        .data_in_mem      (data_in_mem            ),
        .we_mem           (we_mem                 ),
        .clear_board      (clear_board_w          ),
        /* To TX UART Interface */
        .Tx_DV            (Tx_DV_out              ), 
        .Tx_Byte          (Tx_Byte_out            ),
        /* To Core */
        .current_state_out(current_state_from_ctrl)
    );

    Board_Memory mem 
    (
        .CLK       (CLK          ),
        .RST       (RST          ),
        /* From Controller */
        .addr      (addr_mem     ),
        .data_in   (data_in_mem  ),
        .we        (we_mem       ),
        .clear     (clear_board_w),
        /* To Win_Check, Minimax, Controller */
        .board_flat(board_flat   )
    );

    Win_Check checker 
    (
        /* From Board Memory */
        .board_flat(board_flat),
        /* To Controller */
        .x_win     (x_win     ),
        .o_win     (o_win     ),
        .full      (full      )
    );

    Minimax ai 
    (
        .CLK       (CLK                             ),
        .RST       (RST                             ),
        /* From Board Memory */
        .board_flat(board_flat                      ),
        /* From Controller */
        .request   (current_state_from_ctrl == 2'b10),
        /* To Controller */
        .best_move (ai_move                         ),
        .valid     (ai_valid                        )
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

module Minimax (
    input  wire        CLK,
    input  wire        RST,                     // active-low
    input  wire [1:0]  board_in [0:8],
    input  wire        request,                 // = 1 when Controller is in state FPGA_MOVE
    output reg  [3:0]  best_move,
    output reg         valid
);

    localparam [1:0] EMPTY = 2'b00;
    localparam [1:0] X     = 2'b01;
    localparam [1:0] O     = 2'b10;

    localparam IDLE     = 2'b00;
    localparam SCAN     = 2'b01;
    localparam WAIT     = 2'b10;
    localparam DONE     = 2'b11;

    reg [1:0] current_state;
    reg [1:0] next_state;

    reg [3:0]  root_pos;
    reg signed [7:0] best_score;
    reg [3:0]  best_pos;
    reg [1:0]  test_board [0:8];

    // Engine interface
    reg             eng_go;
    wire            eng_done;
    wire signed [7:0] eng_score;

    always @(posedge CLK or negedge RST) begin
        if (RST == 0)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    ///==================================================//
    //              Combinational Circuits              //
    //==================================================//
    always @(current_state or request or root_pos or test_board or eng_done) begin
        case (current_state)
            IDLE: begin
                if (request)
                    next_state = SCAN;
                else
                    next_state = IDLE;
            end

            SCAN: begin
                if (root_pos > 8)
                    next_state = DONE;
                else if (test_board[root_pos] == EMPTY)
                    next_state = WAIT;
                else
                    next_state = SCAN;
            end

            WAIT: begin
                if (eng_done)
                    next_state = SCAN;
                else
                    next_state = WAIT;
            end

            DONE: begin
                if (request == 0)
                    next_state = IDLE;
                else
                    next_state = DONE;
            end

            default: next_state = IDLE;
        endcase
    end

    //================================================================//
    // Top-level control
    //================================================================//
    always @(posedge CLK or negedge RST) begin
        if (RST == 0) begin
            valid      <= 1'b0;
            best_move  <= 4'd0;
            best_score <= -8'd100;
            best_pos   <= 4'd0;
            root_pos   <= 4'd0;
            eng_go     <= 1'b0;
        end 
        else begin
            valid  <= 1'b0;
            eng_go <= 1'b0;

            case (current_state)
                IDLE: begin
                    if (request) begin
                        root_pos   <= 4'd0;
                        best_score <= -8'd100;
                        best_pos   <= 4'd0;
                        // Latch board hiện tại
                        for (integer i = 0; i < 9; i = i + 1) test_board[i] <= board_in[i];
                    end
                    else begin
                        valid     <= 1'b0;          // ← Clean up valid when there is no more request
                    end
                end

                SCAN: begin
                    if (root_pos > 8) begin
                        best_move <= best_pos;
                        valid     <= 1'b1;
                    end
                    else if (test_board[root_pos] == EMPTY) begin
                        test_board[root_pos] <= O;     // try to play move O
                        eng_go <= 1'b1;
                    end
                    else begin
                        root_pos <= root_pos + 1;
                    end
                end

                WAIT: begin
                    if (eng_done) begin
                        if (eng_score > best_score) begin
                            best_score <= eng_score;
                            best_pos   <= root_pos;
                        end
                        test_board[root_pos] <= EMPTY;          // rollback
                        root_pos <= root_pos + 1;
                    end
                end

                DONE: begin
                    valid <= 1'b1;
                end
            endcase
        end
    end

    //================================================================//
    // Minimax Engine - Stack-based Iterative
    //================================================================//
    reg [1:0]  board_mem [0:9][0:8];        // [depth][cell] - maximum 10 depth
    reg [3:0]  pos_mem   [0:9];
    reg        is_max    [0:9];             // 1 = O (max), 0 = X (min)
    reg signed [7:0] score_mem [0:9];
    reg [3:0]  depth;
    reg [3:0]  try_pos;
    reg        found_move;
    reg [3:0]  i;

    assign eng_done  = (depth == 0);
    assign eng_score = score_mem[0];

    always @(posedge CLK or negedge RST) begin
        if (RST == 0) begin
            depth <= 0;
        end
        else if (eng_go && depth == 0) begin
            // Start searching after O is set at root
            depth <= 1;
            for (i = 0; i < 9; i = i + 1) board_mem[0][i] <= test_board[i];
            pos_mem[0]   <= 0;
            is_max[0]    <= 0;              // X turns (minimizing)
            score_mem[0] <= 127;            // +inf for min
        end
        else if (depth > 0) begin
            // Check terminal node
            if (check_win(board_mem[depth - 1], O)) begin
                score_mem[depth - 1] <= 100 - (depth - 1);
                depth <= depth - 1;
            end
            else if (check_win(board_mem[depth - 1], X)) begin
                score_mem[depth - 1] <= (depth - 1) - 100;
                depth <= depth - 1;
            end
            else if (is_full(board_mem[depth - 1])) begin
                score_mem[depth - 1] <= 0;
                depth <= depth - 1;
            end
            // Find next move
            else begin
                found_move = 0;
                try_pos = pos_mem[depth - 1];

                // Find the next empty cell
                for (try_pos = pos_mem[depth - 1]; try_pos <= 8; try_pos = try_pos + 1) begin
                    if (board_mem[depth - 1][try_pos] == EMPTY) begin
                        found_move = 1;
                        break;
                    end
                end

                if (found_move) begin
                    // Push new level
                    pos_mem[depth - 1] <= try_pos + 1;          // Try the next location next time
                    depth <= depth + 1;

                    for (i = 0; i < 9; i = i + 1)
                        board_mem[depth - 1][i] <= board_mem[depth - 2][i];

                    board_mem[depth - 1][try_pos] <= is_max[depth - 2] ? O : X;
                    is_max[depth - 1]    <= ~is_max[depth - 2];
                    score_mem[depth - 1] <= is_max[depth - 1] ? -127 : 127;
                    pos_mem[depth - 1]   <= 0;
                end
                else begin
                    // No more moves → backtrack
                    if (depth > 1) begin
                        if (is_max[depth - 2]) begin                            // max node
                            if (score_mem[depth - 1] > score_mem[depth - 2])
                                score_mem[depth - 2] <= score_mem[depth - 1];
                        end else begin                                          // min node
                            if (score_mem[depth - 1] < score_mem[depth - 2])
                                score_mem[depth - 2] <= score_mem[depth - 1];
                        end
                    end
                    depth <= depth - 1;
                end
            end
        end
    end

    function check_win;
        input [1:0] b [0:8];
        input [1:0] p;
        begin
            check_win = (
                (b[0] == p & b[1] == p & b[2] == p) |
                (b[3] == p & b[4] == p & b[5] == p) |
                (b[6] == p & b[7] == p & b[8] == p) |
                (b[0] == p & b[3] == p & b[6] == p) |
                (b[1] == p & b[4] == p & b[7] == p) |
                (b[2] == p & b[5] == p & b[8] == p) |
                (b[0] == p & b[4] == p & b[8] == p) |
                (b[2] == p & b[4] == p & b[6] == p)
            );
        end
    endfunction

    function is_full;
        input [1:0] b [0:8];
        integer k;
        begin
            is_full = 1;
            for (k = 0; k < 9; k = k + 1)
                if (b[k] == EMPTY) is_full = 0;
        end
    endfunction

endmodule

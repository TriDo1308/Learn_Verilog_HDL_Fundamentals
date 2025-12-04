module Minimax (
    input wire CLK,
    input wire RST, // active-low
    input wire [17:0] board_flat, // bits [17:0]
    input wire request,
    output reg [3:0] best_move,
    output reg valid
);
    localparam [1:0] EMPTY = 2'b00;
    localparam [1:0] X = 2'b01;
    localparam [1:0] O = 2'b10;
    localparam IDLE = 2'b00;
    localparam SCAN = 2'b01;
    localparam WAIT = 2'b10;
    localparam DONE = 2'b11;

    reg [1:0] current_state;
    reg [1:0] next_state;
    reg [3:0] root_pos;
    reg signed [7:0] best_score;
    reg [3:0] best_pos;
    reg [17:0] test_board;

    // Engine interface
    reg eng_go;
    reg eng_done;
    reg signed [7:0] eng_score;

    // Debug
    reg signed [7:0] debug_score [0:8]  /* synthesis keep = "true" */;

    // Stack
    reg [17:0] board_stack [0:9];
    reg is_max_stack [0:9];
    reg signed [7:0] best_stack [0:9];
    reg [3:0] try_pos_stack [0:9];
    reg [3:0] sp; // stack pointer, 0 = idle

    // === Temp vars (pure combinatorial trong 1 cycle) ===
    reg        node_backtrack           /* synthesis keep = "true" */;
    reg        move_found               /* synthesis keep = "true" */;
    reg signed [7:0] node_score         /* synthesis keep = "true" */;
    reg [3:0]  loop_pos                 /* synthesis keep = "true" */;

    reg [3:0]  current_level            /* synthesis keep = "true" */;
    reg [17:0] current_board            /* synthesis keep = "true" */;
    reg        current_is_max           /* synthesis keep = "true" */;
    reg signed [7:0] current_best       /* synthesis keep = "true" */;
    reg [3:0]  current_try_pos          /* synthesis keep = "true" */;

    // === Utility functions (gi? nguyên) ===
    function [17:0] set_cell;
        input [17:0] b;
        input [3:0] pos;
        input [1:0] val;
        begin
            case (pos)
                4'd0: set_cell = {b[17:2], val};
                4'd1: set_cell = {b[17:4], val, b[1:0]};
                4'd2: set_cell = {b[17:6], val, b[3:0]};
                4'd3: set_cell = {b[17:8], val, b[5:0]};
                4'd4: set_cell = {b[17:10], val, b[7:0]};
                4'd5: set_cell = {b[17:12], val, b[9:0]};
                4'd6: set_cell = {b[17:14], val, b[11:0]};
                4'd7: set_cell = {b[17:16], val, b[13:0]};
                4'd8: set_cell = {val, b[15:0]};
                default: set_cell = b;
            endcase
        end
    endfunction

    function [1:0] cell_at;
        input [17:0] b;
        input [3:0] pos;
        begin
            case (pos)
                4'd0: cell_at = b[1:0];
                4'd1: cell_at = b[3:2];
                4'd2: cell_at = b[5:4];
                4'd3: cell_at = b[7:6];
                4'd4: cell_at = b[9:8];
                4'd5: cell_at = b[11:10];
                4'd6: cell_at = b[13:12];
                4'd7: cell_at = b[15:14];
                4'd8: cell_at = b[17:16];
                default: cell_at = 2'b00;
            endcase
        end
    endfunction

    function win_x;
        input [17:0] b;
        begin
            win_x = ((cell_at(b,0)==X && cell_at(b,1)==X && cell_at(b,2)==X) ||
                     (cell_at(b,3)==X && cell_at(b,4)==X && cell_at(b,5)==X) ||
                     (cell_at(b,6)==X && cell_at(b,7)==X && cell_at(b,8)==X) ||
                     (cell_at(b,0)==X && cell_at(b,3)==X && cell_at(b,6)==X) ||
                     (cell_at(b,1)==X && cell_at(b,4)==X && cell_at(b,7)==X) ||
                     (cell_at(b,2)==X && cell_at(b,5)==X && cell_at(b,8)==X) ||
                     (cell_at(b,0)==X && cell_at(b,4)==X && cell_at(b,8)==X) ||
                     (cell_at(b,2)==X && cell_at(b,4)==X && cell_at(b,6)==X));
        end
    endfunction

    function win_o;
        input [17:0] b;
        begin
            win_o = ((cell_at(b,0)==O && cell_at(b,1)==O && cell_at(b,2)==O) ||
                     (cell_at(b,3)==O && cell_at(b,4)==O && cell_at(b,5)==O) ||
                     (cell_at(b,6)==O && cell_at(b,7)==O && cell_at(b,8)==O) ||
                     (cell_at(b,0)==O && cell_at(b,3)==O && cell_at(b,6)==O) ||
                     (cell_at(b,1)==O && cell_at(b,4)==O && cell_at(b,7)==O) ||
                     (cell_at(b,2)==O && cell_at(b,5)==O && cell_at(b,8)==O) ||
                     (cell_at(b,0)==O && cell_at(b,4)==O && cell_at(b,8)==O) ||
                     (cell_at(b,2)==O && cell_at(b,4)==O && cell_at(b,6)==O));
        end
    endfunction

    function board_full;
        input [17:0] b;
        integer k;
        begin
            board_full = 1;
            for (k = 0; k < 9; k = k + 1)
                if (cell_at(b, k) == EMPTY) board_full = 0;
        end
    endfunction

    function [3:0] next_empty_pos;
        input [17:0] b;
        input [3:0] start;
        begin
            case (1'b1)
                (start <= 4'd0 && cell_at(b, 4'd0) == EMPTY): next_empty_pos = 4'd0;
                (start <= 4'd1 && cell_at(b, 4'd1) == EMPTY): next_empty_pos = 4'd1;
                (start <= 4'd2 && cell_at(b, 4'd2) == EMPTY): next_empty_pos = 4'd2;
                (start <= 4'd3 && cell_at(b, 4'd3) == EMPTY): next_empty_pos = 4'd3;
                (start <= 4'd4 && cell_at(b, 4'd4) == EMPTY): next_empty_pos = 4'd4;
                (start <= 4'd5 && cell_at(b, 4'd5) == EMPTY): next_empty_pos = 4'd5;
                (start <= 4'd6 && cell_at(b, 4'd6) == EMPTY): next_empty_pos = 4'd6;
                (start <= 4'd7 && cell_at(b, 4'd7) == EMPTY): next_empty_pos = 4'd7;
                (start <= 4'd8 && cell_at(b, 4'd8) == EMPTY): next_empty_pos = 4'd8;
                default: next_empty_pos = 4'd9;
            endcase
        end
    endfunction

    // FSM state register
    always @(posedge CLK or negedge RST) begin
        if (RST == 0) current_state <= IDLE;
        else current_state <= next_state;
    end

    // FSM transition
    always @(*) begin
        case (current_state)
            IDLE: next_state = request ? SCAN : IDLE;
            SCAN: next_state = (root_pos == 4'd9) ? DONE : (cell_at(test_board, root_pos) == EMPTY ? WAIT : SCAN);
            WAIT: next_state = eng_done ? SCAN : WAIT;
            DONE: next_state = request ? DONE : IDLE;
            default: next_state = IDLE;
        endcase
    end

    // === Iterative Minimax Engine - Verilog-2001 thu?n, synthesis clean 100% ===
    always @(posedge CLK or negedge RST) begin
        if (RST == 0) begin
            sp <= 0;
            eng_done <= 0;
        end else begin
            eng_done <= 0;

            // Default blocking cho temp vars (immediate value, tránh mixed assignment)
            node_backtrack = 0;
            move_found     = 0;
            node_score     = 0;
            loop_pos       = 0;

            if (eng_go && sp == 0) begin
                sp <= 1;
                board_stack[0] <= test_board;
                is_max_stack[0] <= 1'b1;
                best_stack[0]   <= -8'sd100;
                try_pos_stack[0] <= 4'd0;
            end

            if (sp > 0) begin
                current_level   = sp - 1;
                current_board   = board_stack[current_level];
                current_is_max  = is_max_stack[current_level];
                current_best    = best_stack[current_level];
                current_try_pos = try_pos_stack[current_level];

                // Terminal checks
                if (win_o(current_board)) begin
                    node_score     = -8'sd99 + sp;
                    node_backtrack = 1;
                end else if (win_x(current_board)) begin
                    node_score     = 8'sd99 - sp;
                    node_backtrack = 1;
                end else if (board_full(current_board)) begin
                    node_score     = 8'sd0;
                    node_backtrack = 1;
                end else begin
                    loop_pos   = next_empty_pos(current_board, current_try_pos);
                    move_found = (loop_pos < 4'd9);

                    if (move_found) begin
                        sp <= sp + 1;
                        board_stack[sp]     <= set_cell(current_board, loop_pos, current_is_max ? X : O);
                        is_max_stack[sp]    <= ~current_is_max;
                        best_stack[sp]      <= is_max_stack[sp] ? -8'sd100 : 8'sd100;
                        try_pos_stack[sp]   <= 4'd0;
                        try_pos_stack[current_level] <= loop_pos + 1;
                    end else begin
                        node_score     = current_best;
                        node_backtrack = 1;
                    end
                end

                // Backtrack (dùng giá tr? immediate)
                if (node_backtrack) begin
                    if (sp == 1) begin
                        eng_score <= node_score;
                        eng_done  <= 1;
                        sp        <= 0;
                    end else begin
                        if (is_max_stack[current_level-1]) begin
                            if (node_score > best_stack[current_level-1])
                                best_stack[current_level-1] <= node_score;
                        end else begin
                            if (node_score < best_stack[current_level-1])
                                best_stack[current_level-1] <= node_score;
                        end
                        sp <= sp - 1;
                    end
                end
            end
        end
    end

    // Top-level control (gi? nguyên)
    integer ii;
    always @(posedge CLK or negedge RST) begin
        if (RST == 0) begin
            valid <= 0;
            best_move <= 0;
            best_score <= 8'sd127;
            best_pos <= 0;
            root_pos <= 4'd4;
            eng_go <= 0;
            test_board <= 0;
            for (ii = 0; ii < 9; ii = ii + 1) debug_score[ii] <= 0;
        end else begin
            eng_go <= 0;
            case (current_state)
                IDLE: begin
                    valid <= 0;
                    if (request) begin
                        root_pos <= 4'd4;
                        best_score <= 8'sd127;
                        best_pos <= 0;
                        test_board <= board_flat[17:0];
                        for (ii = 0; ii < 9; ii = ii + 1) debug_score[ii] <= 0;
                    end
                end
                SCAN: begin
                    if (root_pos == 4'd9) begin
                        best_move <= best_pos;
                        valid <= 1;
                        $display("DEBUG Scores: %d %d %d %d %d %d %d %d %d",
                                 debug_score[0], debug_score[1], debug_score[2],
                                 debug_score[3], debug_score[4], debug_score[5],
                                 debug_score[6], debug_score[7], debug_score[8]);
                    end else if (cell_at(test_board, root_pos) == EMPTY) begin
                        test_board <= set_cell(test_board, root_pos, O);
                        eng_go <= 1;
                    end else begin
                        root_pos <= (root_pos == 4'd4) ? 4'd0 :
                                    (root_pos == 4'd3) ? 4'd5 :
                                    (root_pos == 4'd8) ? 4'd9 : root_pos + 1;
                    end
                end
                WAIT: begin
                    if (eng_done) begin
                        debug_score[root_pos] <= eng_score;
                        if (eng_score < best_score) begin
                            best_score <= eng_score;
                            best_pos <= root_pos;
                        end
                        test_board <= set_cell(test_board, root_pos, EMPTY);
                        root_pos <= (root_pos == 4'd4) ? 4'd0 :
                                      (root_pos == 4'd3) ? 4'd5 :
                                      (root_pos == 4'd8) ? 4'd9 : root_pos + 1;
                    end
                end
                DONE: valid <= 1;
            endcase
        end
    end
endmodule
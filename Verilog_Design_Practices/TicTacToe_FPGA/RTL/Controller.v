module Controller (
    input wire CLK,
    input wire RST,
    input wire [7:0] Rx_Byte_in,
    input wire Rx_DV_in,
    input wire Tx_Done_in,
    input [18:0] board_flat,
    input wire x_win,
    input wire o_win,
    input wire full,
    input wire [3:0] ai_move,
    input wire ai_valid,
    output reg we_mem,
    output reg [3:0] addr_mem,
    output reg [1:0] data_in_mem,
    output reg Tx_DV,
    output reg [7:0] Tx_Byte,
    output reg clear_board,
    // Add output to core know current state (for Minimax)
    output wire [1:0] current_state_out
);
   
    wire [1:0] board [0:8];
    genvar h;
    generate
        for (h = 0; h < 9; h = h + 1) begin
            assign board[h] = board_flat[h*2 +: 2];
        end
    endgenerate
   
    // ==================== State encoding ====================
    localparam IDLE = 2'b00;
    localparam WAIT_MOVE = 2'b01; // Player (X) makes a move
    localparam FPGA_MOVE = 2'b10; // FPGA (O) computes and executes moves
    localparam CHECK = 2'b11;
    reg [1:0] current_state_r;
    reg [1:0] next_state_r;
    always @(posedge CLK or negedge RST) begin
        if (RST == 0)
            current_state_r <= IDLE;
        else
            current_state_r <= next_state_r;
    end
    //==================================================//
    // Combinational Circuits //
    //==================================================//
    always @(current_state_r or Rx_DV_in or Rx_Byte_in or Tx_Done_in or ai_valid or x_win or o_win or full) begin
        if (Rx_DV_in && Rx_Byte_in == 8'hFE)
            next_state_r = IDLE;
        else begin
            case (current_state_r)
                IDLE: begin
                    if (Rx_DV_in && Rx_Byte_in == 8'hFF)
                        next_state_r = WAIT_MOVE;
                    else
                        next_state_r = IDLE;
                end
   
                WAIT_MOVE: begin
                    if (Tx_Done_in)
                        next_state_r = FPGA_MOVE; // After the player moves ?' FPGA calculates
                    else
                        next_state_r = WAIT_MOVE;
                end
   
                FPGA_MOVE: begin
                    if (ai_valid || full)
                        next_state_r = CHECK;
                    else
                        next_state_r = FPGA_MOVE;
                end
   
                CHECK: begin
                    if (Tx_Done_in) begin
                        if (x_win || o_win || full)
                            next_state_r = IDLE; // Game over ?' waiting for reset
                        else
                            next_state_r = WAIT_MOVE; // Not done ?' continue the game
                    end
                    else next_state_r = CHECK;
                end
   
                default: next_state_r = IDLE;
            endcase
        end
    end
    //==================================================//
    // Sequential Circuits //
    //==================================================//
    always @(posedge CLK or negedge RST) begin
        if (RST == 0) begin
            we_mem <= 1'b0;
            addr_mem <= 4'd0;
            data_in_mem <= 2'd0;
            Tx_DV <= 1'b0;
            Tx_Byte <= 8'd0;
            clear_board <= 1'b0;
// current_state_r <= IDLE;
        end
        else begin
            clear_board <= 1'b0;
            we_mem <= 1'b0;
            Tx_DV <= 1'b0;
            Tx_Byte <= 8'd0;
           
            if (Rx_DV_in && Rx_Byte_in == 8'hFE) begin
                clear_board <= 1'b1;
                Tx_DV <= 1'b1;
                Tx_Byte <= 8'hFE;
// current_state_r <= IDLE;
                // c?c reg kh?c kh?ng c?n reset v? clear_board s? x?a mem
            end
            else begin
                case (current_state_r)
                    WAIT_MOVE: begin
                        if (Rx_DV_in) begin
                            if (Rx_Byte_in <= 8 && board[Rx_Byte_in] == 2'b00) begin
                                // Legal move
                                addr_mem <= Rx_Byte_in[3:0];
                                data_in_mem <= 2'b01; // X = 01
                                we_mem <= 1'b1;
                                Tx_Byte <= 8'h30 + Rx_Byte_in; // 0x30 + cell position
                                Tx_DV <= 1'b1;
                            end else begin
                                // Error: invalid move or cell already occupied
                                Tx_Byte <= 8'hEE;
                                Tx_DV <= 1'b1;
                            end
                        end
                    end
   
                    FPGA_MOVE: begin
                        if (ai_valid) begin
                            addr_mem <= ai_move;
                            data_in_mem <= 2'b10; // O = 10
                            we_mem <= 1'b1;
                            Tx_Byte <= 8'h40 + ai_move; // 0x40 + cell position
                            Tx_DV <= 1'b1;
                        end
                    end
   
                    CHECK: begin
                        if (Tx_Done_in) begin
                            if (x_win) begin Tx_Byte <= 8'hA0; Tx_DV <= 1'b1; end // X wins
                            else if (o_win) begin Tx_Byte <= 8'hA1; Tx_DV <= 1'b1; end // O wins
                            else if (full) begin Tx_Byte <= 8'hAA; Tx_DV <= 1'b1; end // Draw
                        end
                    end
                endcase
// current_state_r <= next_state_r;
            end
//            current_state_r <= next_state_r;
        end
    end
    //==================================================//
    // Output //
    //==================================================//
    assign current_state_out = current_state_r;
endmodule
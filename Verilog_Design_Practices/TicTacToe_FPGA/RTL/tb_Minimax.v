`timescale 1ns / 1ps

module tb_TicTacToe_Comprehensive();
    // ==============================================================
    // Signals
    // ==============================================================
    reg CLK = 0;
    reg RST = 0; // active-low
    reg [18:0] board_flat;
    reg request = 0;
    wire [3:0] best_move;
    wire valid;
    
    // ==============================================================
    // DUT
    // ==============================================================
    Minimax dut (
        .CLK (CLK),
        .RST (RST),
        .board_flat (board_flat),
        .request (request),
        .best_move (best_move),
        .valid (valid)
    );
    
    // 25 MHz clock ? 40ns period
    always #20 CLK = ~CLK;
    
    // ==============================================================
    // Counter PASS / FAIL
    // ==============================================================
    integer total_tests = 0;
    integer passed_tests = 0;
    integer test_num = 0;
    
    // ==============================================================
    // Helper task: clear board
    // ==============================================================
    task clear_board;
        begin
            board_flat = 19'b0;
        end
    endtask
    
    // ==============================================================
    // Helper task: set cell (pos 0-8) to value (00=EMPTY/01=X/10=O)
    // ==============================================================
    task set_cell;
        input [3:0] pos;
        input [1:0] val;
        begin
            board_flat[pos*2 +: 2] = val;
        end
    endtask
    
    // ==============================================================
    // Helper task: display board
    // ==============================================================
    task display_board;
        integer r, c, idx;
        reg [1:0] cell_val;
        begin
            $display("     Board State:");
            $display("     -------------");
            for (r = 0; r < 3; r = r + 1) begin
                $write("     | ");
                for (c = 0; c < 3; c = c + 1) begin
                    idx = r * 3 + c;
                    cell_val = board_flat[idx*2 +: 2];
                    case (cell_val)
                        2'b00: $write("  ");
                        2'b01: $write("X ");
                        2'b10: $write("O ");
                        default: $write("? ");
                    endcase
                    $write("| ");
                end
                $display("");
                $display("     -------------");
            end
        end
    endtask
    
    // ==============================================================
    // Task ki?m tra k?t qu? v?i kh? n?ng ch?p nh?n nhi?u ?áp án
    // ==============================================================
    task check_result;
        input [3:0] expected_move;
        input [79:0] test_name;
        begin
            total_tests = total_tests + 1;
            test_num = test_num + 1;
            
            $display("\n[TEST %0d] %0s", test_num, test_name);
            display_board();
            
            if (valid && best_move == expected_move) begin
                $display("? PASS: best_move = %0d (expected %0d)", best_move, expected_move);
                passed_tests = passed_tests + 1;
            end else if (valid) begin
                $display("? FAIL: got %0d, expected %0d", best_move, expected_move);
            end else begin
                $display("? FAIL: valid=0, no move returned");
            end
        end
    endtask
    
    // Task cho các tr??ng h?p ch?p nh?n nhi?u ?áp án ?úng
    task check_result_multi;
        input [3:0] move1, move2, move3;
        input [79:0] test_name;
        begin
            total_tests = total_tests + 1;
            test_num = test_num + 1;
            
            $display("\n[TEST %0d] %0s", test_num, test_name);
            display_board();
            
            if (valid && (best_move == move1 || best_move == move2 || best_move == move3)) begin
                $display("? PASS: best_move = %0d (acceptable: %0d, %0d, %0d)", 
                         best_move, move1, move2, move3);
                passed_tests = passed_tests + 1;
            end else if (valid) begin
                $display("? FAIL: got %0d, expected one of: %0d, %0d, %0d", 
                         best_move, move1, move2, move3);
            end else begin
                $display("? FAIL: valid=0, no move returned");
            end
        end
    endtask
    
    // ==============================================================
    // Main test sequence
    // ==============================================================
    initial begin
        $display("\n??????????????????????????????????????????????????????????");
        $display("?     COMPREHENSIVE MINIMAX TIC-TAC-TOE TESTBENCH       ?");
        $display("??????????????????????????????????????????????????????????\n");
        
        // Reset
        RST = 0;
        #100;
        RST = 1;
        #100;
        
        // ============================================================
        // CATEGORY 1: BASIC SCENARIOS
        // ============================================================
        $display("\n???????????????????????????????????????????????????");
        $display("  CATEGORY 1: BASIC SCENARIOS");
        $display("???????????????????????????????????????????????????");
        
        // Test 1: Empty board
//        clear_board();
//        request = 1;
//        #20_000_000;
//        request = 0;
//        check_result_multi(4, 0, 2, "Empty board - prefer center");
        
        // Test 2: One X in corner
        #5000;
        clear_board();
        set_cell(0, 2'b01); // X at corner
        request = 1;
        #20_000_000;
        request = 0;
        check_result(4, "X at corner - O takes center");
        
        // Test 2: One X in corner
        #5000;
        clear_board();
        set_cell(2, 2'b01); // X at corner
        request = 1;
        #20_000_000;
        request = 0;
        check_result(4, "X at corner - O takes center");

        // Test 2: One X in corner
        #5000;
        clear_board();
        set_cell(6, 2'b01); // X at corner
        request = 1;
        #20_000_000;
        request = 0;
        check_result(4, "X at corner - O takes center");

        // Test 2: One X in corner
        #5000;
        clear_board();
        set_cell(8, 2'b01); // X at corner
        request = 1;
        #20_000_000;
        request = 0;
        check_result(4, "X at corner - O takes center");
        
        // Test 3: One X at center
        #5000;
        clear_board();
        set_cell(4, 2'b01); // X at center
        request = 1;
        #20_000_000;
        request = 0;
        check_result_multi(0, 2, 6, "X at center - O takes corner");
        
        // ============================================================
        // CATEGORY 2: WINNING MOVES FOR O
        // ============================================================
        $display("\n???????????????????????????????????????????????????");
        $display("  CATEGORY 2: O CAN WIN (Must take winning move)");
        $display("???????????????????????????????????????????????????");
        
        // Test 4: O can win horizontally (top row)
        #5000;
        clear_board();
        set_cell(0, 2'b10); // O
        set_cell(1, 2'b10); // O
        set_cell(3, 2'b01); // X
        set_cell(4, 2'b01); // X
        request = 1;
        #20_000_000;
        request = 0;
        check_result(2, "O wins at pos 2 (top row)");
        
        // Test 5: O can win vertically
        #5000;
        clear_board();
        set_cell(0, 2'b10); // O
        set_cell(3, 2'b10); // O
        set_cell(1, 2'b01); // X
        set_cell(2, 2'b01); // X
        request = 1;
        #20_000_000;
        request = 0;
        check_result(6, "O wins at pos 6 (left column)");
        
        // Test 6: O can win diagonally (main diagonal)
        #5000;
        clear_board();
        set_cell(0, 2'b10); // O
        set_cell(4, 2'b10); // O
        set_cell(1, 2'b01); // X
        set_cell(3, 2'b01); // X
        request = 1;
        #20_000_000;
        request = 0;
        check_result(8, "O wins at pos 8 (main diagonal)");
        
        // Test 7: O can win anti-diagonal
        #5000;
        clear_board();
        set_cell(2, 2'b10); // O
        set_cell(4, 2'b10); // O
        set_cell(1, 2'b01); // X
        set_cell(7, 2'b01); // X
        request = 1;
        #20_000_000;
        request = 0;
        check_result(6, "O wins at pos 6 (anti-diagonal)");
        
        // ============================================================
        // CATEGORY 3: BLOCKING MOVES (O must block X from winning)
        // ============================================================
        $display("\n???????????????????????????????????????????????????");
        $display("  CATEGORY 3: BLOCKING MOVES");
        $display("???????????????????????????????????????????????????");
        
        // Test 8: Block X horizontal threat (top row)
        #5000;
        clear_board();
        set_cell(0, 2'b01); // X
        set_cell(1, 2'b01); // X
        set_cell(4, 2'b10); // O
        request = 1;
        #20_000_000;
        request = 0;
        check_result(2, "Block X at pos 2 (top row)");
        
        // Test 9: Block X vertical threat
        #5000;
        clear_board();
        set_cell(1, 2'b01); // X
        set_cell(4, 2'b01); // X
        set_cell(0, 2'b10); // O
        request = 1;
        #20_000_000;
        request = 0;
        check_result(7, "Block X at pos 7 (middle column)");
        
        // Test 10: Block X diagonal threat
        #5000;
        clear_board();
        set_cell(0, 2'b01); // X
        set_cell(4, 2'b01); // X
        set_cell(1, 2'b10); // O
        request = 1;
        #20_000_000;
        request = 0;
        check_result(8, "Block X at pos 8 (main diagonal)");
        
        // Test 11: Block X anti-diagonal
        #5000;
        clear_board();
        set_cell(2, 2'b01); // X
        set_cell(6, 2'b01); // X
        set_cell(0, 2'b10); // O
        request = 1;
        #20_000_000;
        request = 0;
        check_result(4, "Block X at pos 4 (anti-diagonal)");
        
        // ============================================================
        // CATEGORY 4: FORK SCENARIOS
        // ============================================================
        $display("\n???????????????????????????????????????????????????");
        $display("  CATEGORY 4: FORK SITUATIONS");
        $display("???????????????????????????????????????????????????");
        
        // Test 12: O creates fork opportunity
        #5000;
        clear_board();
        set_cell(0, 2'b10); // O
        set_cell(8, 2'b10); // O
        set_cell(1, 2'b01); // X
        request = 1;
        #20_000_000;
        request = 0;
        check_result(4, "O creates fork at center");
        
//        // Test 13: Prevent X fork (opposite corners)
//        #5000;
//        clear_board();
//        set_cell(0, 2'b01); // X
//        set_cell(8, 2'b01); // X
//        request = 1;
//        #20_000_000;
//        request = 0;
//        check_result_multi(1, 3, 5, "Block X fork - take edge");
        
        // Test 14: X threatens fork at two corners
        #5000;
        clear_board();
        set_cell(0, 2'b01); // X
        set_cell(2, 2'b01); // X
        set_cell(4, 2'b10); // O at center
        request = 1;
        #20_000_000;
        request = 0;
        check_result(1, "Block X fork - take edge between");
        
        // ============================================================
        // CATEGORY 5: ENDGAME SCENARIOS
        // ============================================================
        $display("\n???????????????????????????????????????????????????");
        $display("  CATEGORY 5: ENDGAME SCENARIOS");
        $display("???????????????????????????????????????????????????");
        
        // Test 15: Almost full board - one move left
        #5000;
        clear_board();
        set_cell(0, 2'b01); // X
        set_cell(1, 2'b10); // O
        set_cell(2, 2'b01); // X
        set_cell(3, 2'b10); // O
        set_cell(4, 2'b01); // X
        set_cell(5, 2'b10); // O
        set_cell(6, 2'b01); // X
        set_cell(7, 2'b10); // O
        // pos 8 empty
        request = 1;
        #20_000_000;
        request = 0;
        check_result(8, "Only one move left");
        
        // Test 16: Two moves left - choose wisely
        #5000;
        clear_board();
        set_cell(0, 2'b10); // O
        set_cell(1, 2'b01); // X
        set_cell(2, 2'b10); // O
        set_cell(3, 2'b01); // X
        set_cell(5, 2'b10); // O
        set_cell(6, 2'b01); // X
        set_cell(7, 2'b10); // O
        // pos 4, 8 empty
        request = 1;
        #20_000_000;
        request = 0;
        check_result_multi(4, 8, 4, "Choose between two moves");
        
        // ============================================================
        // CATEGORY 6: EDGE CASES
        // ============================================================
        $display("\n???????????????????????????????????????????????????");
        $display("  CATEGORY 6: EDGE CASES");
        $display("???????????????????????????????????????????????????");
        
        // Test 17: X already won (should handle gracefully)
        #5000;
        clear_board();
        set_cell(0, 2'b01);
        set_cell(1, 2'b01);
        set_cell(2, 2'b01);
        set_cell(4, 2'b10);
        total_tests = total_tests + 1;
        test_num = test_num + 1;
        request = 1;
        #20_000_000;
        request = 0;
        $display("\n[TEST %0d] X already won", test_num);
        display_board();
        if (valid) begin
            $display("? PASS: Returned valid result despite X won");
            passed_tests = passed_tests + 1;
        end else begin
            $display("? FAIL: Did not return valid");
        end
        
        // Test 18: O already won (should handle gracefully)
        #5000;
        clear_board();
        set_cell(0, 2'b10);
        set_cell(1, 2'b10);
        set_cell(2, 2'b10);
        set_cell(4, 2'b01);
        total_tests = total_tests + 1;
        test_num = test_num + 1;
        request = 1;
        #20_000_000;
        request = 0;
        $display("\n[TEST %0d] O already won", test_num);
        display_board();
        if (valid) begin
            $display("? PASS: Returned valid result despite O won");
            passed_tests = passed_tests + 1;
        end else begin
            $display("? FAIL: Did not return valid");
        end
        
        // Test 19: Full board (draw)
        #5000;
        clear_board();
        set_cell(0, 2'b01);
        set_cell(1, 2'b10);
        set_cell(2, 2'b01);
        set_cell(3, 2'b01);
        set_cell(4, 2'b10);
        set_cell(5, 2'b10);
        set_cell(6, 2'b10);
        set_cell(7, 2'b01);
        set_cell(8, 2'b01);
        total_tests = total_tests + 1;
        test_num = test_num + 1;
        request = 1;
        #20_000_000;
        request = 0;
        $display("\n[TEST %0d] Full board (draw)", test_num);
        display_board();
        if (valid) begin
            $display("? PASS: Handled full board correctly");
            passed_tests = passed_tests + 1;
        end else begin
            $display("? FAIL: Did not return valid");
        end
        
        // Test 20: X has 4 corners
//        #5000;
//        clear_board();
//        set_cell(0, 2'b01);
//        set_cell(2, 2'b01);
//        set_cell(6, 2'b01);
//        set_cell(8, 2'b01);
//        request = 1;
//        #20_000_000;
//        request = 0;
//        check_result(4, "X has 4 corners - O must take center");
        
        // ============================================================
        // CATEGORY 7: STRATEGIC POSITIONING
        // ============================================================
        $display("\n???????????????????????????????????????????????????");
        $display("  CATEGORY 7: STRATEGIC POSITIONING");
        $display("???????????????????????????????????????????????????");
        
        // Test 21: Prefer corner over edge
        #5000;
        clear_board();
        set_cell(4, 2'b01); // X at center
        set_cell(1, 2'b10); // O at edge
        request = 1;
        #20_000_000;
        request = 0;
        check_result_multi(0, 2, 6, "Prefer corner when center taken");
        
        // Test 22: Double threat scenario
        #5000;
        clear_board();
        set_cell(0, 2'b10); // O
        set_cell(2, 2'b10); // O
        set_cell(4, 2'b01); // X
        request = 1;
        #20_000_000;
        request = 0;
        check_result(1, "Create winning position on edge");
        
        // Test 23: Advanced positioning
        #5000;
        clear_board();
        set_cell(4, 2'b10); // O center
        set_cell(0, 2'b01); // X corner
        set_cell(8, 2'b10); // O opposite corner
        request = 1;
        #20_000_000;
        request = 0;
        check_result_multi(2, 6, 1, "Strategic third move");
        
        // ==============================================================
        // FINAL SUMMARY
        // ==============================================================
        #20000;
        $display("\n");
        $display("??????????????????????????????????????????????????????");
        $display("?                  TEST SUMMARY               ?");
        $display("??????????????????????????????????????????????????????");
        $display("?  Total tests    : %3d                             ?", total_tests);
        $display("?  Passed         : %3d                             ?", passed_tests);
        $display("?  Failed         : %3d                             ?", total_tests - passed_tests);
        $display("?  Success rate   : %3d%%                           ?", (passed_tests * 100) / total_tests);
        $display("??????????????????????????????????????????????????????");
        
        if (passed_tests == total_tests) begin
            $display("?  PERFECT! ALL TESTS PASSED!                    ?");
            $display("?  AI IS UNBEATABLE - READY FOR DEPLOYMENT!      ?");
        end else if (passed_tests >= total_tests * 90 / 100) begin
            $display("?  EXCELLENT! Most tests passed (>90%%)          ?");
            $display("?  Minor fixes needed                            ?");
        end else if (passed_tests >= total_tests * 70 / 100) begin
            $display("?  GOOD! Majority passed (>70%%)                 ?");
            $display("?  Some improvements needed                      ?");
        end else begin
            $display("?  NEEDS WORK! Many tests failed                 ?");
            $display("?  Check algorithm logic                         ?");
        end
        
        $display("??????????????????????????????????????????????????????\n");
        
        $finish;
    end

endmodule
module Board_Memory (
    input CLK, RST,
    /* From Controller */
    input [3:0] addr,
    input [1:0] data_in,
    input we, clear,
    /* To Win_Check, Minimax, Controller */
    output reg [17:0] board_flat
);
    integer i;
    always @(posedge CLK or negedge RST) begin
        if (RST == 0) begin
            for (i = 0; i < 9; i = i + 1)
                board_flat[i*2 +: 2] <= 2'b00;
        end 
        else if (clear) begin
            board_flat <= 18'd0;
        end
        else if (we) begin
            board_flat[addr*2 +: 2] <= data_in;
        end
    end

endmodule

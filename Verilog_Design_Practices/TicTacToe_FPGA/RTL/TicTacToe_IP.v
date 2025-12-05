module TicTacToe_IP (
    input  wire         CLK,
    input  wire         RST,
    input  wire         Rx_in,
    /* To TX UART Pin*/
    output wire         Tx_out,
    /* LED output */
    output wire [7:0]   LED
);

    wire                Rx_DV_w, Tx_Done_w;
    wire                Tx_DV_w;
    wire [7:0]          Rx_Byte_w, Tx_Byte_w;
    wire [7:0]          board_debug;

    receiver
    #(.CLKS_PER_BIT(217))
    RX
    (
        .CLK        (CLK      ),
        .Rx_in      (Rx_in    ),
        .Rx_DV_out  (Rx_DV_w  ),
        .Rx_Byte_out(Rx_Byte_w)
    );

    Core core 
    (
        .CLK        (CLK        ), 
        .RST        (RST        ),
        .Rx_Byte_in (Rx_Byte_w  ), 
        .Rx_DV_in   (Rx_DV_w    ),
        .Tx_Done_in (Tx_Done_w  ),
        .Tx_DV_out  (Tx_DV_w    ), 
        .Tx_Byte_out(Tx_Byte_w  ),
        .board_led  (board_debug)
    );

    transmitter
    #(.CLKS_PER_BIT(217))
    TX
    (
        .CLK          (CLK      ),
        .Tx_DV_in     (Tx_DV_w  ),
        .Tx_Byte_in   (Tx_Byte_w),
        .Tx_Active_out(         ),
        .Tx_out       (Tx_out   ),
        .Tx_Done_out  (Tx_Done_w)
    );

    //==================================================//
    //              		Output			            //
    //==================================================//
    assign LED = board_debug;

endmodule

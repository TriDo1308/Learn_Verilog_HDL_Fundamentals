module Controller (
    input  wire 				CLK,
    input  wire 				RST,        			// active-low synchronous reset
	/* From RX UART Interface*/	
	input  wire	signed [7:0] 	Rx_Byte_in,
    input  wire    				Rx_DV_in,
	/* From TX UART Interface*/	
	input  wire					Tx_Done_in,
	/* From Datapath*/
	input  wire					c_valid_in,
	/* For Datapath*/
    output wire  				En_out,
	/* For Input Memory*/
	output wire  				Load_a_en_out,
	output wire  				Load_b_en_out,
	/* To TX UART Interface*/
	output wire 				Tx_DV_out
);

    // State encoding
    localparam IDLE 			= 3'b000;
	localparam LOAD_A 			= 3'b001;
	localparam LOAD_B 			= 3'b010;
    localparam EXE  			= 3'b011;
    localparam SEND 			= 3'b100;

    //==================================================//
    //                   	Wire                      	//
    //==================================================//


    //==================================================//
    //                   Registers                      //
    //==================================================//
	reg [2:0]					current_state_r, next_state_r;
	
	//==================================================//
    //              Combinational Circuits              //
    //==================================================//
		
	// Next state logic
	always @(current_state_r or Rx_DV_in or c_valid_in or Tx_Done_in) begin
		case(current_state_r)
			IDLE: begin
				if (Rx_DV_in)
					next_state_r = LOAD_A;
				else
					next_state_r = IDLE;
			end
			
			LOAD_A: begin
				if (Rx_DV_in)
					next_state_r = LOAD_B;
				else
					next_state_r = LOAD_A;
			end
			
			LOAD_B: begin
				next_state_r = EXE;
			end

			EXE: begin
				if (c_valid_in)
					next_state_r = SEND;
				else
					next_state_r = EXE;
			end
			
			SEND: begin
				if (Tx_Done_in)
					next_state_r = IDLE;
				else
					next_state_r = SEND;
			end

			default: next_state_r = IDLE;
		endcase
	end

	
	
	//==================================================//
    //              	Sequential Circuits             //
    //==================================================//
	
	// Next state reg
	always @(posedge CLK or negedge RST) begin
		if(RST == 0) begin
			current_state_r	<= IDLE;
		end
		else begin
			current_state_r	<= next_state_r;
		end
	end

	//==================================================//
    //              		Output            		    //
    //==================================================//

	assign En_out 				= (current_state_r == EXE) ? 1'b1: 1'b0; 
	assign Load_a_en_out		= (Rx_DV_in && current_state_r == IDLE) ? 1'b1 : 1'b0;
	assign Load_b_en_out		= (Rx_DV_in && current_state_r == LOAD_A) ? 1'b1 : 1'b0;
	assign Tx_DV_out			= c_valid_in;
	
endmodule

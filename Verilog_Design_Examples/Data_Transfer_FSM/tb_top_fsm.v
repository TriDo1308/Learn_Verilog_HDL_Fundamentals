`timescale 1ns/1ps

module tb_top_fsm();
    localparam DEPTH = 4;
    localparam WIDTH_WR = 8;
    
    reg  clk = 0; 
    reg  rst_n;
    reg  we; 
    reg  [4:0] addr_wr;
    reg  [3:0] addr_rd;     
    reg  [WIDTH_WR - 1 : 0] data_wr;     
    wire [2 * WIDTH_WR - 1 : 0] data_rd;
    reg  [2 * WIDTH_WR - 1 : 0] data_rd_buf;
    wire done;
    reg  opmode;
    reg  [2 * WIDTH_WR - 1 : 0] data_exp;
    
    integer i, loop_no;
    
    // Verification statistics
    integer test_count = 0, success_count = 0, error_count = 0;
       
    // Instantiate the module      
    top_fsm TO
    (
        .clk            (clk    ),
        .rst_n          (rst_n  ),
	 	.ram_in_we      (we     ),
	 	.ram_in_addr_wr (addr_wr), 
	 	.ram_in_data_wr (data_wr),
	 	.ram_out_addr_rd(addr_rd), 
	 	.ram_out_data_rd(data_rd),       
        .opmode_in      (opmode ),
        .done_out       (done   )
    );
 
    // Create the clock signal	
    always begin #0.5 clk = ~clk; end
	
    // Begin test 		   
    initial begin
	    we = 0; 
	    addr_wr = 0;
        opmode = 0;                                                         // store data in RAM_IN
        rst_n = 0;
        #10;
        rst_n = 1;
      
	    for (loop_no = 0; loop_no < 2; loop_no = loop_no + 1) begin
			// Fill RAM_IN with a data pattern
			for (i = 0; i < 32; i = i + 1) begin
				write_data(i, ((i % 2) << 7) + i + loop_no);
			end 
		
			// Trigger the data transfer procedure
			@(posedge clk); opmode = 1;
			@(posedge clk); opmode = 0;
		    
			@(posedge clk); wait (done === 1);                              // wait done is set 	  
			for (i = 0; i < 32; i = i + 2) begin
				read_data(i >> 1);
				data_exp =  ((((i % 2) << 7) + i + loop_no) << 8) | ((((i + 1) % 2) << 7) + (i + loop_no + 1));
				compare_data(data_exp, data_rd_buf);
			end     
        end
 

        #40;
	    $display($time, " test_count = %d, success_count = %d, error_count=%d", 
		                  test_count, success_count, error_count);
	    $stop;
    end
   
    task write_data(input[4:0] address_in, input[WIDTH_WR - 1 : 0] data_in);
    begin
	    @(posedge clk);
	    we = 1;
	    data_wr = data_in;
	    addr_wr = address_in;
        $display($time, " write_address = %d, data_wr = 0x%h", addr_wr, data_wr);
	    @(posedge clk);
	    we = 0;
    end
    endtask
   
    task read_data(input[3:0] address_in);
    begin
	    @(posedge clk);
	    addr_rd = address_in;
	    @(negedge clk);
	    $display($time, " read_address = %d, data_rd = 0x%h", addr_rd, data_rd);
        data_rd_buf = data_rd;  
    end
    endtask  

    task compare_data( input[2 * WIDTH_WR - 1 : 0] expected, input[2 * WIDTH_WR - 1 : 0] observed);
    begin
        test_count = test_count + 1;
	    if (observed != expected) begin
            $display($time,(" test_count = %d  FAIL: expected data_out = %x, observed data_out = %x"), test_count, expected, observed);
            error_count = error_count + 1;			
        end else begin
            $display($time,(" test_count = %d  PASS: expected data_out = %x, observed data_out = %x"), test_count, expected, observed);
	 	    success_count = success_count + 1;
        end
    end
    endtask   
endmodule

/* Output
11 write_address =  0, data_wr = 0x00
13 write_address =  1, data_wr = 0x81
15 write_address =  2, data_wr = 0x02
17 write_address =  3, data_wr = 0x83
19 write_address =  4, data_wr = 0x04
21 write_address =  5, data_wr = 0x85
23 write_address =  6, data_wr = 0x06
25 write_address =  7, data_wr = 0x87
27 write_address =  8, data_wr = 0x08
29 write_address =  9, data_wr = 0x89
31 write_address = 10, data_wr = 0x0a
33 write_address = 11, data_wr = 0x8b
35 write_address = 12, data_wr = 0x0c
37 write_address = 13, data_wr = 0x8d
39 write_address = 14, data_wr = 0x0e
41 write_address = 15, data_wr = 0x8f
43 write_address = 16, data_wr = 0x10
45 write_address = 17, data_wr = 0x91
47 write_address = 18, data_wr = 0x12
49 write_address = 19, data_wr = 0x93
51 write_address = 20, data_wr = 0x14
53 write_address = 21, data_wr = 0x95
55 write_address = 22, data_wr = 0x16
57 write_address = 23, data_wr = 0x97
59 write_address = 24, data_wr = 0x18
61 write_address = 25, data_wr = 0x99
63 write_address = 26, data_wr = 0x1a
65 write_address = 27, data_wr = 0x9b
67 write_address = 28, data_wr = 0x1c
69 write_address = 29, data_wr = 0x9d
71 write_address = 30, data_wr = 0x1e
73 write_address = 31, data_wr = 0x9f
124 read_address =  0, data_rd = 0x0081
124 test_count =           1  PASS: expected data_out = 0081, observed data_out = 0081
125 read_address =  1, data_rd = 0x0283
125 test_count =           2  PASS: expected data_out = 0283, observed data_out = 0283
126 read_address =  2, data_rd = 0x0485
126 test_count =           3  PASS: expected data_out = 0485, observed data_out = 0485
127 read_address =  3, data_rd = 0x0687
127 test_count =           4  PASS: expected data_out = 0687, observed data_out = 0687
128 read_address =  4, data_rd = 0x0889
128 test_count =           5  PASS: expected data_out = 0889, observed data_out = 0889
129 read_address =  5, data_rd = 0x0a8b
129 test_count =           6  PASS: expected data_out = 0a8b, observed data_out = 0a8b
130 read_address =  6, data_rd = 0x0c8d
130 test_count =           7  PASS: expected data_out = 0c8d, observed data_out = 0c8d
131 read_address =  7, data_rd = 0x0e8f
131 test_count =           8  PASS: expected data_out = 0e8f, observed data_out = 0e8f
132 read_address =  8, data_rd = 0x1091
132 test_count =           9  PASS: expected data_out = 1091, observed data_out = 1091
133 read_address =  9, data_rd = 0x1293
133 test_count =          10  PASS: expected data_out = 1293, observed data_out = 1293
134 read_address = 10, data_rd = 0x1495
134 test_count =          11  PASS: expected data_out = 1495, observed data_out = 1495
135 read_address = 11, data_rd = 0x1697
135 test_count =          12  PASS: expected data_out = 1697, observed data_out = 1697
136 read_address = 12, data_rd = 0x1899
136 test_count =          13  PASS: expected data_out = 1899, observed data_out = 1899
137 read_address = 13, data_rd = 0x1a9b
137 test_count =          14  PASS: expected data_out = 1a9b, observed data_out = 1a9b
138 read_address = 14, data_rd = 0x1c9d
138 test_count =          15  PASS: expected data_out = 1c9d, observed data_out = 1c9d
139 read_address = 15, data_rd = 0x1e9f
139 test_count =          16  PASS: expected data_out = 1e9f, observed data_out = 1e9f
140 write_address =  0, data_wr = 0x01
142 write_address =  1, data_wr = 0x82
144 write_address =  2, data_wr = 0x03
146 write_address =  3, data_wr = 0x84
148 write_address =  4, data_wr = 0x05
150 write_address =  5, data_wr = 0x86
152 write_address =  6, data_wr = 0x07
154 write_address =  7, data_wr = 0x88
156 write_address =  8, data_wr = 0x09
158 write_address =  9, data_wr = 0x8a
160 write_address = 10, data_wr = 0x0b
162 write_address = 11, data_wr = 0x8c
164 write_address = 12, data_wr = 0x0d
166 write_address = 13, data_wr = 0x8e
168 write_address = 14, data_wr = 0x0f
170 write_address = 15, data_wr = 0x90
172 write_address = 16, data_wr = 0x11
174 write_address = 17, data_wr = 0x92
176 write_address = 18, data_wr = 0x13
178 write_address = 19, data_wr = 0x94
180 write_address = 20, data_wr = 0x15
182 write_address = 21, data_wr = 0x96
184 write_address = 22, data_wr = 0x17
186 write_address = 23, data_wr = 0x98
188 write_address = 24, data_wr = 0x19
190 write_address = 25, data_wr = 0x9a
192 write_address = 26, data_wr = 0x1b
194 write_address = 27, data_wr = 0x9c
196 write_address = 28, data_wr = 0x1d
198 write_address = 29, data_wr = 0x9e
200 write_address = 30, data_wr = 0x1f
202 write_address = 31, data_wr = 0xa0
253 read_address =  0, data_rd = 0x0182
253 test_count =          17  PASS: expected data_out = 0182, observed data_out = 0182
254 read_address =  1, data_rd = 0x0384
254 test_count =          18  PASS: expected data_out = 0384, observed data_out = 0384
255 read_address =  2, data_rd = 0x0586
255 test_count =          19  PASS: expected data_out = 0586, observed data_out = 0586
256 read_address =  3, data_rd = 0x0788
256 test_count =          20  PASS: expected data_out = 0788, observed data_out = 0788
257 read_address =  4, data_rd = 0x098a
257 test_count =          21  PASS: expected data_out = 098a, observed data_out = 098a
258 read_address =  5, data_rd = 0x0b8c
258 test_count =          22  PASS: expected data_out = 0b8c, observed data_out = 0b8c
259 read_address =  6, data_rd = 0x0d8e
259 test_count =          23  PASS: expected data_out = 0d8e, observed data_out = 0d8e
260 read_address =  7, data_rd = 0x0f90
260 test_count =          24  PASS: expected data_out = 0f90, observed data_out = 0f90
261 read_address =  8, data_rd = 0x1192
261 test_count =          25  PASS: expected data_out = 1192, observed data_out = 1192
262 read_address =  9, data_rd = 0x1394
262 test_count =          26  PASS: expected data_out = 1394, observed data_out = 1394
263 read_address = 10, data_rd = 0x1596
263 test_count =          27  PASS: expected data_out = 1596, observed data_out = 1596
264 read_address = 11, data_rd = 0x1798
264 test_count =          28  PASS: expected data_out = 1798, observed data_out = 1798
265 read_address = 12, data_rd = 0x199a
265 test_count =          29  PASS: expected data_out = 199a, observed data_out = 199a
266 read_address = 13, data_rd = 0x1b9c
266 test_count =          30  PASS: expected data_out = 1b9c, observed data_out = 1b9c
267 read_address = 14, data_rd = 0x1d9e
267 test_count =          31  PASS: expected data_out = 1d9e, observed data_out = 1d9e
268 read_address = 15, data_rd = 0x1fa0
268 test_count =          32  PASS: expected data_out = 1fa0, observed data_out = 1fa0
308 test_count =          32, success_count =          32, error_count=          0
*/
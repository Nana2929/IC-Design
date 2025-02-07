module Lifo #(parameter DATA_WIDTH = 8,
              parameter DEPTH = 16)
             (input clk,                          // clock, active on positive edge
              input reset,                        // synchronous reset; active high
              input rd_enable,                    // read enable
              input wr_enable,                    // write enable
              input [DATA_WIDTH-1:0] data_in,     // data input
              output reg [DATA_WIDTH-1:0] data_out, // data output
              output full, empty);            // full and empty flags
    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] lifo[DEPTH-1:0];        // lifo memory array
    reg [PTR_WIDTH-1:0] sp = 0;                  // lifo pointer

    always@(posedge clk) begin
        if (reset) begin
            sp <= 0;
        end
        else begin
            if (!full && wr_enable) begin
                sp = sp + 1;                     // increment the pointer
                lifo[sp] = data_in;             // push data onto the lifo
            end
            if (!empty && rd_enable) begin
                data_out <= lifo[sp];            // pop data from the lifo
                sp <= sp - 1;                     // decrement the pointer
        end
        end
    end

    // Logic to determine when the lifo is full or empty
    assign full = (sp == DEPTH);                  // lifo is full when pointer equals the depth
    assign empty = (sp == 0);                     // lifo is empty when pointer is zero
endmodule


// testbench
module Lifo_tb;
    reg clk, rst, wr_en, rd_en;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire full, empty;

    Lifo #(8, 16) lifo(.clk(clk), .reset(rst),
    .wr_enable(wr_en),
    .rd_enable(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Clock generation
    end

    initial begin
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        data_in = 8'h0;
        #10 rst = 0;  // Release reset

        // Begin test sequence
        wr_en = 1;
        data_in = 8'hA; #10;
        data_in = 8'hB; #10;
        data_in = 8'hC; #10;
        data_in = 8'hD; #10;

        // Testing ENABLE = 0
        wr_en = 0;
        rd_en = 1;

        #10 $display("time = %d, clk = %d, data_out = %h", $time, clk, data_out);
        #10 $display("time = %d, clk = %d, data_out = %h", $time, clk, data_out);
        #10 $display("time = %d, clk = %d, data_out = %h", $time, clk, data_out);
        #10 $display("time = %d, clk = %d, data_out = %h", $time, clk, data_out);
        #10 $display("time = %d, clk = %d, data_out = %h", $time, clk, data_out);

        $finish;  // End simulation
    end
endmodule

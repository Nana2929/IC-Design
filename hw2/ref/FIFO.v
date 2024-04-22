
module Fifo #(parameter DATA_WIDTH = 8,
              parameter DEPTH = 16)
             (input clk,                          // clock, active when posedge
              input reset,                        // synchronous reset; active high
              input rd_enable,
              input wr_enable,                    // if the data_in is passenger, enable = 1; if the data_in is luggage, enable = 0
              input [DATA_WIDTH-1:0] data_in,
              output reg [DATA_WIDTH-1:0] data_out,
              output reg full, empty);
    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] fifo[DEPTH-1:0];
    reg [PTR_WIDTH-1:0] write_ptr = 0, read_ptr = 0; // pointers to the stack


    always@(posedge clk) begin
        if (reset) begin
            write_ptr <= 0;
            read_ptr  <= 0;
        end
        else begin
            if (!full && wr_enable) begin
                fifo[write_ptr] <= data_in;
                write_ptr       <= ((write_ptr + 1) % DEPTH);
            end
            if (!empty && rd_enable) begin
                data_out <= fifo[read_ptr];
                read_ptr <= ((read_ptr + 1) % DEPTH);
            end
        end
    end
    assign full  = (((write_ptr + 1) % DEPTH) == read_ptr);
    assign empty = (write_ptr == read_ptr);
endmodule


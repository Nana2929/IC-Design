`include "FIFO.v"
`include "FifoController.v"
module CIPU(
input       clk,
input       rst,
input       [7:0]people_thing_in,
input       ready_fifo,
input       ready_lifo,
input       [7:0]thing_in,
input       [3:0]thing_num,
output      valid_fifo,
output      valid_lifo,
output      valid_fifo2,
output     [7:0]people_thing_out,
output      [7:0]thing_out,
output      done_thing,
output      done_fifo,
output      done_lifo,
output      done_fifo2);

    // FIFO
    wire wr_enable, rd_enable;
    wire full_fifo, empty_fifo;

    reg [7:0] prev_people_thing_in;
    always@(posedge clk) begin
        prev_people_thing_in <= people_thing_in;
    end

    FifoController #(8, 4) fifo_controller(.clk(clk),  .reset(rst),
    .ready(ready_fifo), .is_fifo_empty(empty_fifo),
    .people_thing_in(people_thing_in),
    .valid_fifo(valid_fifo), .done_fifo(done_fifo), .wr_enable(wr_enable), .rd_enable(rd_enable));


    Fifo #(8, 16) fifo(.clk(clk), .reset(rst),
    .wr_enable(wr_enable),.rd_enable(rd_enable), .data_in(prev_people_thing_in), .data_out(people_thing_out),
    .full(full_fifo), .empty(empty_fifo));


endmodule
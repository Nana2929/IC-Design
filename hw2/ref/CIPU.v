`include "FIFO.v"
`include "FifoController.v"
`include "LIFO.v"
`include "LifoController.v"
`include "Fifo2Controller.v"
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
    wire wr_enable_fifo, rd_enable_fifo;
    wire full_fifo, empty_fifo;

    reg [7:0] prev_people_thing_in;
    always@(posedge clk) begin
        prev_people_thing_in <= people_thing_in;
    end

    FifoController #(8, 4) fifo_controller(.clk(clk),  .reset(rst),
    .ready(ready_fifo), .is_fifo_empty(empty_fifo),
    .people_thing_in(people_thing_in),
    .valid_fifo(valid_fifo), .done_fifo(done_fifo), .wr_enable(wr_enable_fifo), .rd_enable(rd_enable_fifo));


    Fifo #(8, 16) fifo(.clk(clk), .reset(rst),
    .wr_enable(wr_enable_fifo),.rd_enable(rd_enable_fifo), .data_in(prev_people_thing_in), .data_out(people_thing_out),
    .full(full_fifo), .empty(empty_fifo));

    // LIFO
    wire wr_enable_lifo, rd_enable_lifo;
    wire full_lifo, empty_lifo;
    wire output_zero;
    reg [7:0] prev_thing_in;
    always@(posedge clk) begin
        prev_thing_in <= thing_in;
    end
    parameter ZERO = 8'h30; // "0" in ASCII

    wire [7:0] lifo_data_out;
    Lifo #(8, 16) lifo(.clk(clk), .reset(rst),
    .wr_enable(wr_enable_lifo), .rd_enable(rd_enable_lifo),
    .data_in(prev_thing_in), .data_out(lifo_data_out),
    .full(full_lifo), .empty(empty_lifo));

    LifoController #(8, 4) lifo_controller(.clk(clk), .reset(rst),
    .ready_lifo(ready_lifo),
    .thing_in(thing_in),
    .thing_num(thing_num),
    .is_lifo_empty(empty_lifo),
    .done_thing(done_thing),
    .valid_lifo(valid_lifo),
    .output_zero(output_zero),
    .done_lifo(done_lifo), .wr_enable(wr_enable_lifo), .rd_enable(rd_enable_lifo));


    wire wr_enable_fifo2, rd_enable_fifo2;
    wire full_fifo2, empty_fifo2;
    wire [7:0] fifo2_out;

    // need a Lifo to reverse the order of the data, so it behaves like a Fifo
    Lifo #(8, 16) fifo2(.clk(clk), .reset(rst),
    .wr_enable(wr_enable_fifo2), .rd_enable(rd_enable_fifo2),
    .data_in(lifo_data_out), .data_out(fifo2_out),
    .full(full_fifo2), .empty(empty_fifo2));

    Fifo2Controller #(8, 16) fifo2_controller(.clk(clk), .reset(rst),
    .ready(done_lifo), .is_lifo_empty(empty_lifo), .is_fifo2_empty(empty_fifo2),
    .data_in(lifo_data_out), .wr_enable(wr_enable_fifo2), .rd_enable(rd_enable_fifo2),
    .valid_fifo2(valid_fifo2), .done_fifo2(done_fifo2));
    assign thing_out = (done_lifo != 1) ? ((output_zero) ? ZERO : lifo_data_out) : fifo2_out;


endmodule
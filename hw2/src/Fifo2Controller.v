

module Fifo2Controller#(parameter DATA_WIDTH = 8, parameter DEPTH = 16)(
    input clk,
    input reset,
    input ready,
    input is_lifo_empty,
    input is_fifo2_empty,
    input [DATA_WIDTH-1:0] data_in,
    output reg wr_enable,
    output reg rd_enable,
    output reg valid_fifo2,
    output reg done_fifo2
);
    parameter [2:0] IDLE = 3'b000, PUSH = 3'b001, POP = 3'b010, DONE_INPUT = 3'b011, DONE_OUTPUT = 3'b100;
    reg [2:0] currState, nextState;
    always@(posedge clk) begin
        if (reset) begin
            currState <= IDLE;
        end
        else begin
            currState <= nextState;
        end
    end

    always@(*) begin
        case (currState)
            IDLE: begin
                if (ready) begin
                    if (is_lifo_empty) begin
                        nextState = DONE_INPUT;
                    end
                    else begin
                        nextState = PUSH;
                    end
                end
                else begin
                    nextState = IDLE;
                end
            end
            POP: begin
                if (is_fifo2_empty) begin
                    nextState = DONE_OUTPUT;
                end
                else begin
                    nextState = POP;
                end
            end
            PUSH: begin
                if (ready) begin
                    if (is_lifo_empty) begin
                        nextState = DONE_INPUT;
                    end
                    else begin
                        nextState = PUSH;
                    end
                end
                else begin
                    nextState = IDLE;
                end
            end
            DONE_INPUT: nextState = POP;
            DONE_OUTPUT: nextState = DONE_OUTPUT;
        endcase
    end

    always@(currState) begin
        case (currState)
            IDLE: begin
                wr_enable = 1'b0;
                rd_enable = 1'b0;
            end
            POP: begin
                wr_enable = 1'b0;
                rd_enable = 1'b1;
                valid_fifo2 = 1'b1;
            end
            PUSH: begin
                wr_enable = 1'b1;
                rd_enable = 1'b0;
            end
            DONE_INPUT: begin
                wr_enable = 1'b0;
                rd_enable = 1'b1;
            end
            DONE_OUTPUT: begin
                wr_enable = 1'b0;
                rd_enable = 1'b0;
                done_fifo2 = 1'b1;
                valid_fifo2 = 1'b0;
            end
        endcase
    end

endmodule
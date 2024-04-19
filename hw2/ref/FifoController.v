module TypeCheck #(parameter DATA_WIDTH = 8)(
    input [DATA_WIDTH-1:0] data_in,
    output reg [1:0] y);
    parameter MIN = 8'd49;
    parameter MAX = 8'd57;
    parameter [DATA_WIDTH-1:0] ENDSIGN = 8'h24;
    // parameter [DATA_WIDTH-1:0] SEPSIGN = 8'h3b;
    always @* begin
        if ((data_in >= MIN) && (data_in <= MAX)) begin
            y = 2'b00; // luggage (encoded as "1" to "9" in ASCII: 49 to 57)
        end
        else begin
            if (data_in == ENDSIGN) begin
                y = 2'b10; // end
            end
            else begin
                y = 2'b01;  // passenger
            end
        end
    end
endmodule

module FifoController #(parameter DATA_WIDTH = 8, parameter THING_COUNT=4)(
    input clk,
    input reset,
    input ready, //ready_fifo
    input is_fifo_empty,
    input [DATA_WIDTH-1:0] people_thing_in,
    output reg valid_fifo,
    output reg done_fifo,
    output reg wr_enable,
    output reg rd_enable
);
    // https://www.google.com/url?sa=i&url=https%3A%2F%2Felectronics.stackexchange.com%2Fquestions%2F197795%2Ffinite-state-machine-fsm-that-controls-a-memory-block&psig=AOvVaw1fuxVijm3YOlae2FtKTS_z&ust=1713529559198000&source=images&cd=vfe&opi=89978449&ved=0CBIQjRxqFwoTCPCclZrhy4UDFQAAAAAdAAAAABAE
    reg [2:0] currState, nextState;
    // state parameters
    parameter[2:0] IDLE = 3'b000, PUSH = 3'b001, POP = 3'b010, DONE_INPUT = 3'b011, DONE_OUTPUT = 3'b100;
    wire [1:0] which_type;
    TypeCheck type_check(.data_in(people_thing_in), .y((which_type)));
    // assign to 0 to avoid latches
    // state registers (S.)
    reg _ready; // once "ready" is toggled to 1, '_ready' will stay 1

    always @(posedge clk or posedge reset) begin
    if (reset) begin
        _ready <= 0;  // Reset _ready to low on system reset
    end else if (ready) begin
        _ready <= 1;  // Set _ready high once ready_fifo is high
    end
    end



    always@(posedge clk) begin
        if (reset) begin
            currState <= IDLE;
        end
        else begin
            currState <= nextState;
        end
    end
    // next-state logic (C.)
    always@(*) begin
        case (currState)
            IDLE: begin
                if (_ready) begin
                case (which_type)
                    2'b10: nextState = DONE_INPUT; // end of input
                    2'b01: nextState = PUSH; // passenger
                    2'b00: nextState = IDLE; // luggage
                    default: nextState = IDLE;
                endcase end // if (_ready)
                else begin
                    nextState = IDLE;
                end end
            POP: begin
                if (is_fifo_empty) begin
                    nextState = DONE_OUTPUT;
                end
                else begin
                    nextState = POP;
                end
            end
            DONE_INPUT: nextState = POP;
            PUSH: begin
                if (_ready) begin
                case (which_type)
                    2'b10: nextState = DONE_INPUT; // end of input
                    2'b01: nextState = PUSH; // passenger
                    2'b00: nextState = IDLE; // luggage
                    default: nextState = IDLE;
                endcase end // if (_ready)
                else begin
                    nextState = IDLE;
                end end
            DONE_OUTPUT: nextState = DONE_OUTPUT;
        endcase
    end
    // output logic (C.)
    always@(currState) begin
        case (currState)
            IDLE: begin
                wr_enable=1'b0;
                rd_enable=1'b0; // do nothing
            end
            POP: begin
                wr_enable=1'b0;
                rd_enable=1'b1;
                valid_fifo=1'b1;
            end
            DONE_OUTPUT: begin
                wr_enable=1'b0;
                rd_enable=1'b0;
                done_fifo=1'b1;
                valid_fifo=1'b0;
            end
            DONE_INPUT: begin
                wr_enable=1'b0;
                rd_enable=1'b1;
            end
            PUSH: begin
                wr_enable=1'b1;
                rd_enable=1'b0; // push
            end
        endcase
    end

endmodule

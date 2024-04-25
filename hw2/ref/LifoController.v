module LifoController #(parameter DATA_WIDTH = 8, parameter THING_WIDTH=4)
            (input clk,                          // clock, active when posedge
            input reset,                        // synchronous reset; active high
            input ready_lifo,
            input [DATA_WIDTH-1:0] thing_in,
            input [THING_WIDTH-1:0] thing_num,
            input is_lifo_empty,
            output reg done_thing, // signal to indicate that this passenger's luggage is done
            output reg wr_enable, // lifo write enable
            output reg rd_enable, // lifo read enable
            output reg output_zero, // output zero and do not affect the stack
            output reg valid_lifo,
            output reg done_lifo);

        reg [2:0] currState, nextState;
        parameter[2:0] IDLE = 3'b000, PUSH = 3'b001, POP = 3'b010;
        parameter[2:0] POP_ZERO = 3'b011, DONE_THING_INPUT = 3'b100, DONE_THING_OUTPUT = 3'b101, DONE_LIFO = 3'b110, POP_FIRST = 3'b111;
        parameter [DATA_WIDTH-1:0] ENDSIGN = 8'h24;
        parameter [DATA_WIDTH-1:0] SEPSIGN = 8'h3b;
        // DONE_THING_INPUT: all luggages of the passenger go in and the number of luggages in thing_num are prepared to be popped
        // DONE_THING_OUTPUT: all luggages of the passenger are checked and the correct number of luggages are popped
        // DONE_LIFO: all passengers' luggages are checked and taken away.
        // POP_FIRST: the first luggage of the passenger is popped; this is used for valid_lifo signal
        // POP_ZERO: no luggage is popped; this is used for output_zero signal

        // State Registers: Sequential logic
        reg [THING_WIDTH-1:0] pop_num;
        always@(posedge clk) begin
            if (reset) begin
                currState <= IDLE;
            end
            else begin
                currState <= nextState;
                if (currState == POP || currState == POP_FIRST) begin
                    // !!pop_num needs to be decremented at sequential logic!!
                    pop_num <= pop_num - 1;
                end
            end
        end

        reg _ready_lifo; // once "ready" is toggled to 1, '_ready' will stay 1

        always @(posedge clk or posedge reset) begin
        if (reset) begin
            _ready_lifo <= 0;  // Reset _ready to low on system reset
        end else if (ready_lifo) begin
            _ready_lifo <= 1;  // Set _ready high once ready_fifo is high
        end
        end



        // Next-state logic: Combinational logic
        always@(*) begin
            case (currState)
                IDLE: begin
                if (_ready_lifo) begin
                    case(thing_in)
                        SEPSIGN: nextState = DONE_THING_INPUT;
                        ENDSIGN: nextState = DONE_LIFO;
                        default: nextState = PUSH;
                    endcase end
                end
                PUSH: case(thing_in)
                    SEPSIGN: nextState = DONE_THING_INPUT;
                    ENDSIGN: nextState = DONE_LIFO;
                    default: nextState = PUSH;
                endcase
                DONE_THING_INPUT:
                    if (pop_num == 0) begin
                        nextState = POP_ZERO;
                    end
                    else begin
                        nextState = POP_FIRST;
                    end
                DONE_THING_OUTPUT: nextState = IDLE;
                DONE_LIFO: nextState = DONE_LIFO;
                POP_FIRST: nextState = (pop_num-1 == 0) ? DONE_THING_OUTPUT : POP;
                POP: nextState = (pop_num-1 == 0) ? DONE_THING_OUTPUT : POP;
                POP_ZERO: nextState = DONE_THING_OUTPUT;
                default: nextState = IDLE;
            endcase
        end




        always@(currState) begin
            case (currState)
                IDLE: begin
                    wr_enable = 0;
                    rd_enable = 0;
                    output_zero = 0;
                    valid_lifo = 0;
                    done_thing = 0; // otherwise the testbench does not read some semicolons
                    done_lifo = 0;
                end
                PUSH: begin
                    wr_enable = 1;
                    rd_enable = 0;
                end
                POP_FIRST: begin // because FIFO access delays 1 cycle
                    wr_enable = 0;
                    rd_enable = 1;
                end
                POP: begin
                    wr_enable = 0;
                    rd_enable = 1;
                    output_zero = 0;
                    valid_lifo = 1;
                end
                POP_ZERO: begin
                    wr_enable = 0;
                    rd_enable = 0;
                    output_zero = 1;
                end
                DONE_THING_INPUT: begin
                    wr_enable = 0;
                    rd_enable = 0;
                    pop_num = thing_num;
                end
                DONE_THING_OUTPUT: begin
                    wr_enable = 0;
                    rd_enable = 0;
                    done_thing = 1;
                    valid_lifo = 1;
                end
                DONE_LIFO: begin
                    wr_enable = 0;
                    rd_enable = 1;
                    done_lifo = 1;
                    valid_lifo = 0;
                end
            endcase
        end
endmodule


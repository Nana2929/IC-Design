
// module LifoController3(parameter DATA_WIDTH = 8, parameter THING_COUNT=4)(
//     input clk,
//     input reset,
//     input ready,
//     input [DATA_WIDTH-1:0] peole_thing_in,
//     input [THING_COUNT-1:0] people_thing_out;
//     output [1:0] push_or_pop_or_nothing,);
//     reg [1:0] currState, nextState;
//     parameter [DATA_WIDTH-1:0] ENDSIGN = 8'h24;
//     parameter [DATA_WIDTH-1:0] SEPSIGN = 8'h3b;


//     // state parameters
//     parameter[2:0] IDLE = 3'b000, PUSH = 3'b001, POP = 3'b010, DONE = 3'b011;
//     // output control signal
//     parameter[1:0] DO_NOTHING = 2'b00, DO_PUSH = 2'b01, DO_POP = 2'b10;

//     wire [THING_COUNT-1:0] thing_num_copy;
//     assign thing_num_copy = thing_num;
//     // state registers (S.)
//     always@(posedge clk) begin
//         if (reset) begin
//             currState <= IDLE;
//         end
//         else begin
//             currState <= nextState;
//         end
//     end
//     // next-state logic (C.)
//     always@(currState or ready) begin
//         case (currState)
//             IDLE: begin
//                 if (ready) begin
//                    case (thing_in)
//                     `ENDSIGN: nextState = DONE;
//                     `SEPSIGN: nextState = POP;
//                     default: nextState = PUSH;
//                    endcase
//                 end
//                 else begin
//                     nextState = IDLE;
//                 end
//             end
//             POP: begin
//                 if (thing_num_copy == 0) begin
//                     nextState = IDLE;
//                 end
//                 else begin
//                     nextState = POP;
//                     thing_num_copy = thing_num_copy - 1;
//                 end
//             end
//             DONE: nextState = IDLE;
//             PUSH: nextState = IDLE;

//         endcase
//     end
//     // output logic (C.)
//     always@(currState) begin
//         case (currState)
//             IDLE: push_or_pop_or_nothing = DO_NOTHING; // do nothing
//             POP: push_or_pop_or_nothing = DO_POP; // pop
//             DONE: push_or_pop_or_nothing = DO_NOTHING; // do nothing
//             PUSH: push_or_pop_or_nothing = DO_PUSH; // push
//         endcase
//     end
// endmodule



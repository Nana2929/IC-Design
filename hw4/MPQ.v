module MPQ#(
    parameter DATA_WIDTH = 8, parameter QUEUE_SIZE = 32)
    (clk,rst,data_valid,data,cmd_valid,cmd,index,value,busy,RAM_valid,RAM_A,RAM_D,done); // QUEUE_SIZE = 256 but its hard to debug
    input clk;
    input rst;
    input data_valid;
    input [DATA_WIDTH-1:0] data;
    input cmd_valid;
    input [2:0] cmd;
    input [7:0] index;
    input [DATA_WIDTH-1:0] value;
    output reg busy;
    output reg RAM_valid;
    output reg [7:0]RAM_A;
    output reg [DATA_WIDTH-1:0]RAM_D;
    output reg done;

    reg [DATA_WIDTH:0] heap[QUEUE_SIZE:0]; // A heap with capacity for 16 elements
    reg [7:0] heap_size; // Number of elements in the heap
    reg signed [7:0] outer_i; // index for heap construction
    reg [7:0] i, left, right, largest; // Indices for heap manipulation
    reg [7:0] address; // Address for RAM
    // State machine
    // typedef enum {IDLE, DECREASE_VAL, ADD_DATA, INCREASE_VAL, BUILD_QUEUE, DONE_MAX_HEAPIFY, DONE_COMMAND,_FIND_LARGEST, _EXCHANGE} state_type;
    // state_type curr_state, next_state;
    reg [3:0] IDLE=4'b0000, DECREASE_VAL=4'b0001, ADD_DATA=4'b0010, INCREASE_VAL=4'b0011, BUILD_QUEUE=4'b0100,
        DONE_MAX_HEAPIFY=4'b0101, DONE_COMMAND=4'b0110, _FIND_LARGEST=4'b0111, _EXCHANGE=4'b1000, WRITE_RAM=4'b1001, RESET =4'b1010,WRITE_ARRAY=4'b1011;
    reg [3:0] curr_state, next_state;
    // command signal
    reg [2:0] build_queue = 3'b000, extract_max = 3'b001, increase_value = 3'b010, insert_data = 3'b011, write_RAM = 3'b100;

    // max_heapify: FIND_LARGEST + EXCHANGE
    // build_queue: IDLE->BUILD_QUEUE->(FIND_LARGEST->EXCHANGE->DONE_MAX_HEAPIFY)*n -> BUILD_QUEUE ->IDLE
    // extract_max: IDLE->DECREASE_VAL->(FIND_LARGEST->EXCHANGE->DONE_MAX_HEAPIFY)*1 -> IDLE
    // increase_value: IDLE->INCREASE_VAL->(FIND_LARGEST->EXCHANGE->DONE_MAX_HEAPIFY)*1 -> IDLE
    // insert_data: IDLE->ADD_DATA->(FIND_LARGEST->EXCHANGE->DONE_MAX_HEAPIFY)*1 -> IDLE
    // write_RAM: IDLE->(WRITE_RAM)*n -> IDLE 一次寫出一個資料

    // keep the cmd
    reg need_exchange;
    reg [2:0] curr_cmd;
    // reg [DATA_WIDTH-1:0] _data;
    // reg _data_valid;
    reg done_command;
    reg [2:0] next_cmd;
    always@(negedge clk or posedge rst) begin
        // _data <= data;
        // _data_valid <= data_valid;
        if (cmd_valid) begin
            next_cmd = cmd;
        end
        if (done_command) begin
            curr_cmd = next_cmd;
        end
        if (rst) begin
            curr_state <= RESET;
        end
        else begin
            curr_state <= next_state;
            end
        case (curr_state)
        RESET: begin
            need_exchange=0;
            busy=1; done=0;
            heap_size = 0;
            i         = 0;
            outer_i   = 0;
            address   = 0;
        end
        WRITE_ARRAY: begin
            busy=1;

            if (data_valid) begin
                heap[heap_size] = data;
                heap_size = heap_size + 1;
            end
            else begin
                busy = 0;
            end
        end
        IDLE:begin
            busy = 1;
            RAM_valid = 0;
            done_command = 0;
            if (curr_cmd == build_queue)begin
                outer_i = (heap_size-1) >> 1;end
            if (curr_cmd == write_RAM) begin
                RAM_valid = 1;
                address = 0;
            end
        end
        DECREASE_VAL: begin
            busy=1;
            heap[0] = heap[heap_size-1];
            heap_size = heap_size - 1;
            i       = 0;
        end
        ADD_DATA: begin
            busy=1;
            heap_size         = heap_size + 1;
            heap[heap_size-1] = data;
            i                 = 0;
        end
        INCREASE_VAL: begin
            busy=1;
            if (value < heap[i]) begin
            end
            else begin
                heap[i] = value;
            end
        end
        BUILD_QUEUE:begin
            busy=1;
            if (outer_i >= 0)begin
                i = outer_i;
                outer_i = outer_i - 1;
                next_state = _FIND_LARGEST;
            end
            else begin
                next_state = DONE_COMMAND;
            end
        end
        _FIND_LARGEST:begin
            busy=1;
            largest = i;
            // left shift by 1 to indicate 2*i
            left  = (i << 1)+1;
            right = left+1;
            if (left < heap_size && heap[left] > heap[largest])begin
                largest = left;
            end
            if (right < heap_size && heap[right] > heap[largest])begin
                largest = right;
            end
            need_exchange = (largest != i);
        end
        _EXCHANGE:begin
            busy=1;
            if (need_exchange)begin
                {heap[i], heap[largest]} = {heap[largest], heap[i]};
                i = largest; // Move to new position
            end
        end
        DONE_MAX_HEAPIFY:begin // caller
            busy=1;
            next_state        = IDLE;

        end
        DONE_COMMAND:begin
            busy = 0;
            done_command=1;
            RAM_valid  = 0;
            if (curr_cmd == write_RAM)begin
                done = 1;
            end
        end
        WRITE_RAM:begin
            busy = 1;
            RAM_valid = 1;
            RAM_A     = address;
            RAM_D     = heap[address];
            address   = address + 1;
            end

    endcase
    end
    // Control signals
    always @(*) begin
        case (curr_state)
            RESET: begin
                next_state = WRITE_ARRAY;
            end
            WRITE_ARRAY: begin
                if (data_valid) begin
                    next_state = WRITE_ARRAY;
                end
                else begin
                    next_state = DONE_COMMAND;
                end
            end
            IDLE:begin
            case (next_cmd)
                build_queue: next_state    = BUILD_QUEUE;
                extract_max: next_state    = DECREASE_VAL;
                increase_value: next_state = INCREASE_VAL;
                insert_data: next_state    = ADD_DATA;
                write_RAM: next_state      = WRITE_RAM;
                default: next_state        = IDLE;
            endcase end
            DECREASE_VAL:begin
                next_state = _FIND_LARGEST;end
            ADD_DATA:begin
                next_state = _FIND_LARGEST;end
            INCREASE_VAL:begin
                if (value < heap[i]) begin
                    next_state = DONE_COMMAND;
                end
                else begin
                    next_state = _FIND_LARGEST;
                end
            end
            BUILD_QUEUE:begin
                if (outer_i >= 0)begin
                    next_state = _FIND_LARGEST;
                end
                else begin
                    next_state = DONE_COMMAND;
                end
            end
            DONE_MAX_HEAPIFY: begin // caller
                case (curr_cmd)
                    build_queue: next_state    = BUILD_QUEUE;
                    extract_max: next_state    = DONE_COMMAND;
                    increase_value: next_state = DONE_COMMAND;
                    insert_data: next_state    = DONE_COMMAND;
                    write_RAM: next_state      = DONE_COMMAND;
                    default: next_state        = DONE_COMMAND;
                endcase
            end
            _FIND_LARGEST: begin
                next_state = _EXCHANGE;
            end
            _EXCHANGE: begin
                if (i == largest) begin
                    next_state = DONE_MAX_HEAPIFY;
                end
                else begin
                    next_state = _FIND_LARGEST; // recursive call to find largest
                end
            end
            DONE_COMMAND: begin
                next_state = IDLE;
            end
            WRITE_RAM: begin
                if (address == heap_size) begin
                    next_state = DONE_COMMAND;
                end
                else begin
                    next_state = WRITE_RAM;
                end
            end

        endcase
    end



endmodule

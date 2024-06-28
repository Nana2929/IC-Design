module MPQ#(
    parameter DATA_WIDTH = 8, parameter QUEUE_SIZE = 32)
    (clk,rst,data_valid,data,cmd_valid,cmd,index,value,busy,RAM_valid,RAM_A,RAM_D,done); // QUEUE_SIZE is supposed to be 256 but its hard to debug
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

    reg [DATA_WIDTH:0] heap[QUEUE_SIZE:0]; // A heap with capacity for QUEUE_SIZE elements
    reg [7:0] heap_size; // Number of elements in the heap
    reg signed [7:0] outer_i; // index for heap construction
    reg signed [7:0] i, left, right, largest; // Indices for heap manipulation
    // reg [7:0] i, left, right, largest; // Indices for heap manipulation
    reg [7:0] address; // Address for RAM
    // State machine

    reg [3:0] RESET=4'b0000, WRITE_ARRAY=4'b0001, IDLE=4'b0010, BUILD_QUEUE=4'b0011, EXCHANGE_VAL=4'b0100,
    ADD_DATA=4'b0101, INCREASE_VAL=4'b0110, WRITE_RAM=4'b0111, UP_MAXIFY=4'b1000, _FIND_LARGEST=4'b1001, _EXCHANGE=4'b1010, DONE_MAX_HEAPIFY=4'b1011, DONE_COMMAND=4'b1100,
    DONE_UP_MAXIFY=4'b1101;
    reg [3:0] curr_state, next_state;
    // command signal
    reg [2:0] build_queue = 3'b000, extract_max = 3'b001, increase_value = 3'b010, insert_data = 3'b011, write_RAM = 3'b100;

    // * command state transition
    //

    // keep the cmd
    reg signed [7:0] parent;
    reg need_exchange;
    reg done_upmaxify;
    reg done_command;

    reg [2:0] curr_cmd;
    reg [7:0] curr_value, increase_val_value; // argument
    reg [7:0] curr_index, increase_val_index;
    reg [2:0] next_cmd;
    reg [7:0] next_value;
    reg [7:0] next_index;
    always @(negedge clk or posedge rst) begin
    if (rst) begin
        curr_state <= RESET;
    end
    else begin
        curr_state <= next_state;
        if (cmd_valid) begin
            next_cmd = cmd;
            next_value = value;
            next_index = index;
        end
        if (done_command) begin
            curr_cmd = next_cmd;
            curr_value = next_value;
            curr_index = next_index;
        end
        case (curr_state)
        RESET: begin
            need_exchange=0;
            done_upmaxify=0;
            busy=1; done=0;
            heap_size = 0;
            i         = 0; left = 0; right = 0; largest = 0; parent = 0;
            outer_i   = 0;
            address   = 0;
            need_exchange = 0; done_upmaxify = 0;
            next_cmd = build_queue; next_value = 0; next_index = 0;
            curr_cmd = build_queue; curr_value = 0; curr_index = 0;
            increase_val_index = 0; increase_val_value = 0;
            RAM_A = 0; RAM_D = 0; RAM_valid = 0;
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
            if (curr_cmd == increase_value) begin
                increase_val_value = curr_value;
                increase_val_index = curr_index;
            end
            if (curr_cmd == write_RAM) begin
                RAM_valid = 1;
                address = 0;
            end
        end
        BUILD_QUEUE:begin
            busy=1;
            if (outer_i >= 0)begin
                i = outer_i;
                outer_i = outer_i - 1;
            end

        end
        EXCHANGE_VAL: begin
            busy=1;
            heap[0] = heap[heap_size-1];
            heap_size = heap_size - 1;
            i       = 0;
        end
        ADD_DATA: begin
            busy=1;
            heap_size         = heap_size + 1;
            heap[heap_size-1] = 0;
            increase_val_index                 = heap_size-1;
            increase_val_value                 = curr_value;
        end
        INCREASE_VAL: begin
            busy=1;
            if (increase_val_value < heap[increase_val_index]) begin
            end
            else begin
                heap[increase_val_index] = increase_val_value;
                i = increase_val_index;
            end
        end
        WRITE_RAM:begin
            busy = 1;
            RAM_valid = 1;
            RAM_A     = address;
            RAM_D     = heap[address];
            address   = address + 1;
            end
        UP_MAXIFY:begin
            parent = (i-1) >> 1;
            done_upmaxify = 0;
            if (i >= 0 && parent >= 0 &&  heap[parent] < heap[i]) begin
                {heap[parent], heap[i]} = {heap[i], heap[parent]};
                done_upmaxify = 1;
            end
        end
        DONE_UP_MAXIFY:begin
            busy=1;
            if (done_upmaxify)begin
                i = parent;
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
        end
        DONE_COMMAND:begin
            busy = 0;
            done_command=1;
            RAM_valid  = 0;
            if (curr_cmd == write_RAM)begin
                done = 1;
            end
        end
        default: begin
            busy = 1;
        end
    endcase
    end
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
                extract_max: next_state    = EXCHANGE_VAL;
                increase_value: next_state = INCREASE_VAL;
                insert_data: next_state    = ADD_DATA;
                write_RAM: next_state      = WRITE_RAM;
                default: next_state        = IDLE;
            endcase end
            BUILD_QUEUE:begin
                if (outer_i >= 0)begin
                    next_state = _FIND_LARGEST;
                end
                else begin
                    next_state = DONE_COMMAND;
                end
            end
            EXCHANGE_VAL:begin
                next_state = _FIND_LARGEST;end
            ADD_DATA:begin
                next_state = INCREASE_VAL;end
            INCREASE_VAL:begin
                if (increase_val_value < heap[increase_val_index]) begin
                    next_state = DONE_COMMAND;
                end
                else begin
                    next_state = UP_MAXIFY;
                end
            end
            WRITE_RAM: begin
                if (address == heap_size) begin
                    next_state = DONE_COMMAND;
                end
                else begin
                    next_state = WRITE_RAM;
                end
            end
            UP_MAXIFY:begin
               next_state=DONE_UP_MAXIFY;
            end
            DONE_UP_MAXIFY:begin
                if (done_upmaxify)begin
                    next_state = UP_MAXIFY;
                end
                else begin
                    next_state = DONE_COMMAND;
                end
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
            DONE_COMMAND: begin
                if (curr_cmd == write_RAM)
                    next_state=DONE_COMMAND; // to hold the "done" signal
                else  next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule

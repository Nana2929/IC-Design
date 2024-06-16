module SORT(
    input clk,
    input reset,
    //ROM read only
    output IROM_rd,
    output reg [3:0] IROM_A,
    input [7:0] IROM_Q,
    //RAM write only
    output reg IRAM_valid,
    output reg [3:0] IRAM_A,
    output reg [7:0] IRAM_D,
    output reg done
    );

localparam
    rst      = 0,
    load     = 1,
    build    = 2,
    heapify  = 3,
    write    = 4,
    extract  = 5,
    DONE     = 6;

assign IROM_rd = 1;
reg [7:0]A[1:16];
reg [3:0]state,nxt_state,ret_state;
reg [3:0]build_i;
reg [4:0]num;
//comb
reg [5:0]largest,index;
reg [5:0] left;
reg [5:0] right;

always @(posedge clk or posedge reset) begin
    if(reset) state <= rst;
    else      state <= nxt_state;
end

always @(*) begin
    case (state)
        rst : nxt_state = load;
        load : if(IROM_A == 15) nxt_state = build;
               else             nxt_state = load;
        build : nxt_state = heapify;
        heapify : if(index==largest) nxt_state = ret_state;
                  else                 nxt_state = heapify;
        write : if(IRAM_A==1) nxt_state = DONE;
                else            nxt_state = extract;
        extract : nxt_state = heapify;
        default : nxt_state = rst;
    endcase
end

always @(*) begin //max-heapify
    left = {index,1'b0};
    right = {index,1'b1};
    largest = index;
    if((right <= num) && (A[right] > A[index]))
        largest = right;
    if((left <= num) && (A[left] > A[largest]))
        largest = left;
end

always @(posedge clk) begin
    case (state)
        rst : begin // reset reg
            IROM_A <= 0;
            IRAM_A <= 0;
            IRAM_valid <= 0;
            build_i <= 8;
            done <= 0;
            num <= 0;
        end
        load : begin //load form IROM
            A[IROM_A+1] <= IROM_Q;
            IROM_A <= IROM_A + 1;
            num <= num + 1;
        end
        build : begin //build heap
            index <= build_i;
            build_i <= build_i - 1;
            if(build_i == 1)
                ret_state <= write;
            else
                ret_state <= build;
        end
        heapify : begin // Max-heapify
            if(largest != index) begin
                A[index] <= A[largest];
                A[largest] <= A[index];
                index <= largest;
            end
        end
        write : begin // write to IRAM
            IRAM_valid <= 1;
            IRAM_A <= IRAM_A - 1;
            IRAM_D <= A[1];
        end
        extract : begin // ectract max
            IRAM_valid <= 0;
            A[1] <= A[num];
            num <= num - 1;
            index <= 1;
            ret_state <= write;
        end
        DONE : done <= 1;
    endcase
end


endmodule
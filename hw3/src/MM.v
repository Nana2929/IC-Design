`timescale 1ns/10ps

module MM#(parameter DATA_WIDTH=8, parameter N=4, parameter OUT_DATA_WIDTH=20)(in_data,
          col_end,
          row_end,
          is_legal,
          out_data,
          rst,
          clk,
          change_row,
          valid,
          busy);
    input           clk;
    input           rst;
    input           col_end;
    input           row_end;
    input      [DATA_WIDTH-1:0]     in_data;

    output wire signed [OUT_DATA_WIDTH-1:0] out_data;
    output reg is_legal;
    output reg change_row, valid, busy;
    reg wr_enable, compute_enable, is_first_mat;
    // wr_enable = 1: write to the matrix at (i,j)
    // is_first_mat = 1: write to M1, else write to M2
    // compute_enable = 1: compute the product of M1 and M2 at (i,j)
    reg [N-1:0] i, j;
    reg [2:0] currState, nextState;
    reg reset;
    // INPUT_MAT1: inputs the first matrix
    // INPUT_MAT2: inputs the second matrix
    // COMPUTE: computes 1 element of the output matrix
    // OUTPUT: outputs the computed element
    parameter [2:0] RESET=3'b000, INPUT_MAT1=3'b001, INPUT_MAT2=3'b010, COMPUTE=3'b011, OUTPUT=3'b100;
    reg [N-1:0] M1_height, M1_width, M2_height, M2_width;
    reg [N-1:0] match_dim; // M1 x M2 requires they match in M1's width and M2's height; match_dim records this matching dimension


    reg [DATA_WIDTH-1:0] in_data_;
    reg col_end_, row_end_;

    always@(posedge clk)begin // made the signals arrive at clock posedge
        in_data_ <= in_data;
        col_end_ <= col_end;
        row_end_ <= row_end;
        end

    MMHelper #(DATA_WIDTH, N, OUT_DATA_WIDTH) mm_helper(
        .clk(clk),
        .reset(reset),
        .wr_enable(wr_enable),
        .compute_enable(compute_enable),
        .in_data(in_data_),
        .i(i), .j(j),
        .is_first_mat(is_first_mat),
        .match_dim(match_dim),
        .out_data(out_data));

    always@(*) begin
        if (rst == 1 || currState == RESET) begin
            reset <= 1;
        end
        else begin
            reset <= 0;
        end
    end



    // [Seq.] state register logic
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            i <= 0; j <= 0;
            currState <= RESET;
        end
        else begin
            currState <= nextState;
            if (currState == INPUT_MAT1) begin
                if (col_end_ && row_end_) begin
                    M1_height = i + 1;
                    M1_width = j + 1;
                    i = 0;
                    j = 0;
                end
                else if (col_end_) begin
                    i = i + 1;
                    j = 0;
                end
                else begin
                    j = j + 1;
                end
            end
            if (currState == INPUT_MAT2) begin

                if (col_end_ && row_end_) begin
                    M2_height = i + 1;
                    M2_width = j + 1;
                    i = 0; j = 0;
                end
                else if (col_end_) begin
                    i = i + 1;
                    j = 0;
                end
                else begin
                    j = j + 1;
                end
                if (M1_width == M2_height)begin
                    match_dim = M1_width;
                end
            end
            if (currState == COMPUTE) begin
                if (M1_width == M2_height) begin
                    is_legal = 1;
                    if (i < M1_height) begin
                        if (j+1 < M2_width) begin
                            j = j + 1;
                            change_row <= 0;
                        end
                        else begin
                            i = i + 1;
                            j = 0;
                            change_row = 1;
                        end
                    end
                end
                else begin
                    is_legal = 0;
                end
            end
            if (currState == RESET) begin
                i = 0; j= 0;
                M1_height = 0; M1_width = 0; M2_height = 0; M2_width = 0;
            end
        end
    end
    // [Comb.] Next-State Logic
    always@(*) begin
        case(currState)
            INPUT_MAT1: begin
                nextState = INPUT_MAT1;
                if (col_end_ && row_end_) begin
                    nextState = INPUT_MAT2;
                end
            end
            INPUT_MAT2: begin
                nextState = INPUT_MAT2;
                if (col_end_ && row_end_) begin
                    nextState = COMPUTE;
                end
            end
            COMPUTE: begin
                nextState = OUTPUT;
            end
            RESET: begin
                nextState = INPUT_MAT1;
            end
            OUTPUT: begin
                if (i == M1_height || is_legal == 0) begin
                    nextState = RESET;
                end
                else nextState = COMPUTE;
            end
        endcase
    end
    // [Comb.] Output Logic
    always@(currState) begin
        case(currState)

            RESET: begin
                wr_enable = 0;
                compute_enable = 0;
                is_first_mat = 0;
                valid = 0;
                busy = 0;
            end
            INPUT_MAT1: begin
                wr_enable = 1;
                compute_enable = 0;
                is_first_mat = 1;
                valid = 0;
                busy = 0;
            end
            INPUT_MAT2: begin
                wr_enable = 1;
                compute_enable = 0;
                is_first_mat = 0;
                valid = 0;
                busy = 0;
            end
            COMPUTE: begin
                wr_enable = 0;
                compute_enable = 1;
                is_first_mat = 0; // dont care
                valid = 0;
                busy = 1;
                // should be M1_width == M2_height, if not legal, then don't compute and just pull up valid and is_legal = 0
            end
            OUTPUT: begin
                wr_enable = 0;
                compute_enable = 0;
                is_first_mat = 0; // dont care
                valid = 1;
                busy = 1;
                // simply let the out_data to be sent
            end
        endcase
    end
endmodule


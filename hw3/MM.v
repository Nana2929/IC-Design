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
    reg [N-1:0] i, j;
    reg [N-1:0] next_i, next_j, next_change_row;
    reg [2:0] currState, nextState;
    reg first_mat_end, second_mat_end;
    parameter [2:0] RESET=3'b000, INPUT_MAT1=3'b001, INPUT_MAT2=3'b010, COMPUTE=3'b011, OUTPUT=3'b100, IDLE=3'b101;
    reg [N-1:0] M1_height, M1_width, M2_height, M2_width;
    reg [N-1:0] match_dim;


    reg [DATA_WIDTH-1:0] in_data_;
    reg col_end_, row_end_;
    always@(negedge clk)begin
        in_data_ <= in_data;
        col_end_ <= col_end;
        row_end_ <= row_end;
        end

    MMHelper #(DATA_WIDTH, N, OUT_DATA_WIDTH) mm_helper(
        .clk(clk),
        .reset(rst),
        .wr_enable(wr_enable),
        .compute_enable(compute_enable),
        .in_data(in_data_),
        .i(i), .j(j),
        .is_first_mat(is_first_mat),
        .match_dim(match_dim),
        .out_data(out_data));



    // IDLE: resets the MM_helper's matrices and recorded heights and widths
    // INPUT_MAT1: inputs the first matrix
    // INPUT_MAT2: inputs the second matrix
    // COMPUTE: computes 1 element of the output matrix
    // OUTPUT: outputs the computed element

    // state register logic
    always@(negedge clk or negedge rst) begin
        if (rst) begin
            currState <= RESET;
        end
        else begin
            currState <= nextState;
            i <= next_i; j <= next_j;
            change_row <= next_change_row;
        end
    end

    always@(*) begin
        case(currState)
            INPUT_MAT1: begin
                if (col_end_ && row_end_) begin
                    M1_height = i + 1;
                    M1_width = j + 1;
                    next_i = 0; next_j = 0; first_mat_end = 1;
                end
                else if (col_end_) begin
                    next_i = i + 1;
                    next_j = 0;
                end
                else begin
                    next_j = j + 1;
                end

                if (first_mat_end) begin
                    nextState = INPUT_MAT2;
                end
                else begin
                    nextState = INPUT_MAT1;
                end
            end
            INPUT_MAT2: begin
                if (col_end_ && row_end_) begin
                    M2_height = i + 1;
                    M2_width = j + 1;
                    next_i = 0; next_j = 0;
                    second_mat_end = 1;
                end
                else if (col_end_) begin
                    next_i = i + 1;
                    next_j = 0;
                end
                else begin
                    next_j = j + 1;
                end
                if (second_mat_end) begin
                    nextState = COMPUTE;
                end
                else begin
                    nextState = INPUT_MAT2;
                end
            end
            COMPUTE: begin
                if (M1_width == M2_height) begin
                    match_dim = M1_width;
                    compute_enable = 1;
                    is_legal = 1;
                    if (i < M1_height) begin
                        if (j+1 < M2_width) begin
                            next_j = j + 1;
                            next_change_row = 0;
                        end
                        else begin
                            next_i = i + 1;
                            next_j = 0;
                            next_change_row = 1;
                        end
                    end
                end
                else begin
                    compute_enable = 0;
                    is_legal = 0;
                end
                nextState = OUTPUT;
            end
            RESET: begin
                nextState = IDLE;
            end
            IDLE: begin
                nextState = INPUT_MAT1;
            end
            OUTPUT: begin
                nextState = COMPUTE;
                if (next_i == M1_height) begin
                    nextState = RESET;
                end
            end
        endcase
    end
    // state output logic
    always@(currState) begin
        case(currState)
            IDLE: begin
                wr_enable = 0;
                compute_enable = 0;
            end
            RESET: begin
                wr_enable = 0;
                compute_enable = 0;
                is_first_mat = 0;
                i = 0; j = 0;
                next_i = 0; next_j = 0;
                valid = 0;
                busy = 0;
                first_mat_end = 0;
                second_mat_end = 0;
                M1_height = 0; M1_width = 0; M2_height = 0; M2_width = 0;
            end
            INPUT_MAT1: begin
                busy = 0;
                compute_enable = 0;
                is_first_mat = 1;
                wr_enable = 1;
            end
            INPUT_MAT2: begin
                busy = 0;
                compute_enable = 0;
                is_first_mat = 0;
                wr_enable = 1;
            end
            COMPUTE: begin
                valid = 0;
                busy = 1;
                wr_enable = 0;
                if (is_legal != 1) begin
                    valid = 1;
                end
                // compute_enable = 1;
                // should be M1_width == M2_height, if not legal, then don't compute and just pull up valid and is_legal = 0
            end
            OUTPUT: begin
                wr_enable = 0;
                compute_enable = 0;
                valid = 1;
                // simply let the out_data to be sent
            end
        endcase
    end
endmodule



module MMHelper#(parameter DATA_WIDTH=8, parameter N=4, parameter OUT_DATA_WIDTH=20)(
    clk,
    reset,
    wr_enable,
    compute_enable,
    in_data,
    i, j,
    is_first_mat,
    match_dim,
    out_data);
    input clk, reset;
    input wr_enable, compute_enable;
    input [DATA_WIDTH-1:0] in_data;
    // matrix indexing
    input [N-1:0] i, j;
    // input h, w, // used when reading
    input is_first_mat; // 1 if first matrix, 0 if second matrix; only takes effect in wr_enable mode
    input [N-1:0] match_dim; // the dimension of the matrices to match with
    output reg signed [OUT_DATA_WIDTH-1:0] out_data;
    // N * N matrix
    reg signed [DATA_WIDTH-1:0] M1 [N-1:0][N-1:0];
    reg signed [DATA_WIDTH-1:0] M2 [N-1:0][N-1:0];
    integer x, y, k;
    always@(posedge clk or posedge reset) begin
        if (reset) begin
            for (x = 0; x < N; x = x + 1) begin
                for (y = 0; y < N; y = y + 1) begin
                    M1[x][y] <= 0;
                    M2[x][y] <= 0;
                end
            end
        end
        else begin
            if (wr_enable) begin
                if (is_first_mat) begin
                    M1[i][j] <= in_data;
                end
                else begin
                    M2[i][j] <= in_data;
                end
            end
            else if (compute_enable) begin
                // means compute
                // compute the product sum of i's row in M1 and j's column in M2
                out_data = 0;
                for (k = 0; k < match_dim; k = k + 1) begin
                    // $display("M1[%d][%d] = %d, M2[%d][%d] = %d", i, k, M1[i][k], k, j, M2[k][j]);
                    out_data = out_data + M1[i][k] * M2[k][j];
                end
            end
        end
    end
endmodule


module testbench(
);
    reg clk, reset, wr_enable, compute_enable;
    reg [7:0] in_data;
    reg [3:0] i, j;
    reg is_first_mat;
    wire signed [19:0] out_data;
    integer match_dim;

    MMHelper#(8, 4, 20) mm_helper(
        .clk(clk),
        .reset(reset),
        .wr_enable(wr_enable),
        .compute_enable(compute_enable),
        .in_data(in_data),
        .i(i),
        .j(j),
        .is_first_mat(is_first_mat),
        .match_dim(match_dim),
        .out_data(out_data)
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        reset = 1;
        wr_enable = 0;
        compute_enable = 0;
        in_data = 0;
        i = 0;
        j = 0;

        is_first_mat = 1;
        #10 reset = 0;

        #10 in_data = 20;
        wr_enable = 1;
        $display("in_data = %d", in_data);
        wr_enable = 0;

        #10 is_first_mat = 0;
        #10 i=2;
        #10 j=2;
        #10 in_data = 30;
        wr_enable = 1;
        // $display("in_data = %d", in_data);
        #10 wr_enable = 0;
        #10 i = 3;
        #10 j = 3;
        #10 is_first_mat = 1;
        #10 in_data = 40;
        wr_enable = 1;
        // $display("in_data = %d", in_data);

        #10 wr_enable = 0;

        #10 is_first_mat = 0;
        // let (0,0), (1,0)...(3,0) becomes 1 in M2
        #10 in_data = 1;
        wr_enable = 1;
        #10 j =3;
        #10 i= 0;
        #10 i= 1;
        #10 i= 2;

        #10 wr_enable = 0;
        match_dim = 4;
        i=3;
        j=3;
        #10 compute_enable = 1;
        // calc M3[3,3]
        // #10 $display("out_data = %d", out_data);
        #20 $finish;
    end
endmodule


`timescale 1ns/10ps
module MM( in_data, col_end, row_end, ep,is_legal, out_data, rst, clk , change_row,valid,busy,overflow);
input           clk;
input           rst;
input           col_end;
input           row_end;
input      [7:0]     in_data;
output wire signed [11:0]   out_data;
output wire overflow;
output reg [1:0] ep;
output wire is_legal;
output reg change_row,valid,busy;
reg signed [7:0] mx1[20:0],mx2[20:0];
reg [3:0] mx1_row,mx2_row,mx1_col,mx2_col,cnt,mx1_col_cnt,mx1_row_cnt,mx2_col_cnt,mx2_row_cnt;
reg [3:0] last_col;
reg [4:0] cur,nxt;
reg to_next,mx1_error_flag,mx2_error_flag; // part 1
integer i;
assign is_legal = (mx1_col == mx2_row  && ep == 0  && (!(mx2_row > 1 && last_col != mx2_col))&& !mx2_error_flag); // part 2
wire signed [15:0] temp_sum = mx1[mx1_row_cnt * mx1_col + mx1_col_cnt] * mx2[mx2_row_cnt * mx2_col + mx2_col_cnt];
reg signed [15:0]buffer;
assign overflow = 1'b0; // 這題目前不處理 overflow，故直接設為 0
assign   out_data = buffer[11:0];
parameter
load_mx1 = 0,
load_mx2 = 1,
calculate = 2,
hold = 3,
not_legal = 4,
finish = 5;
// 處理了 mx 的形狀問題（ep）對應到 Q1.Pattern 2
// overflow 還沒有處理
always @(*) begin
    case(cur)
        load_mx1:nxt = (to_next)?load_mx2:load_mx1;
        load_mx2:nxt = (to_next)?(is_legal)?calculate:not_legal:load_mx2;
        calculate:nxt = ((mx1_col_cnt == mx1_col-1 && mx1_row_cnt == mx1_row-1) &&(mx2_col_cnt == mx2_col-1 && mx2_row_cnt == mx2_row-1))?finish:(mx1_col_cnt == mx1_col - 1)?hold:calculate;
        hold:nxt = calculate;
        not_legal:nxt = finish;
        finish:nxt = load_mx1;
    endcase
end
always @(posedge clk or posedge rst) begin
    if(rst)begin
        cur <= load_mx1;
        mx1_row <= 0;
        mx2_row <= 0;
        mx1_col <= 0;
        mx2_col <= 0;
        cnt <= 0;
        mx1_row_cnt <= 0;
        mx1_col_cnt <= 0;
        mx2_row_cnt <= 0;
        mx2_col_cnt <= 0;
        valid <= 0;
        busy <= 0;
        ep <= 2'b00;
        to_next <= 0;
        mx1_error_flag <= 0;
        mx2_error_flag <= 0;
        buffer <= 0;
    end
    else begin
        cur <= nxt;
        case (cur)
            load_mx1:begin
                mx1[cnt] <= in_data;
                if(mx1_row > 1 && last_col != mx1_col)mx1_error_flag <= 1;
                if(col_end)begin
                    mx1_col <= mx1_col_cnt + 1;
                    last_col <= mx1_col;
                    mx1_row <= mx1_row + 1;
                    mx1_col_cnt <= 0;
                end
                else mx1_col_cnt <= mx1_col_cnt + 1;
                if(row_end)begin
                    to_next <= 1;
                    busy <= 1;
                end
                else begin
                    if(to_next)begin
                        cnt <= 0;
                        to_next <= 0;
                        busy <= 0;
                    end
                    else cnt <= cnt + 1;
                end
            end
            load_mx2:begin
                if(mx1_error_flag)ep <= ep + 1; // part 4 
                mx1_error_flag <= 0;
                mx2[cnt] <= in_data;
                if(mx2_row > 1 && last_col != mx2_col)mx2_error_flag <= 1;
                if(col_end)begin
                    mx2_col <= mx2_col_cnt + 1;
                    last_col <= mx2_col;
                    mx2_row <= mx2_row + 1;
                    mx2_col_cnt <= 0;
                end
                else mx2_col_cnt <= mx2_col_cnt + 1;

                if(row_end)begin
                    to_next <= 1;
                    busy <= 1;
                end
                else begin
                    if(to_next)begin
                        cnt <= 0;
                        to_next <= 0;
                        mx1_col_cnt <= 0;
                        mx2_col_cnt <= 0;
                        mx1_row_cnt <= 0;
                        mx2_row_cnt <= 0;
                    end
                    else cnt <= cnt + 1;
                end
            end
            calculate:begin
                buffer <= buffer + temp_sum;
                if(mx2_col_cnt == mx2_col-1 && mx2_row_cnt == mx2_row-1)change_row <= 1;
                else change_row <= 0;

                if(mx2_row_cnt == mx2_row -1 && mx2_col_cnt == mx2_col -1)begin
                    mx2_row_cnt <= 0;
                    mx2_col_cnt <= 0;
                    mx1_row_cnt <= mx1_row_cnt + 1;
                    valid = 1;
                end
                else if(mx2_row_cnt == mx2_row -1)begin
                    mx2_col_cnt <= mx2_col_cnt + 1;
                    mx2_row_cnt <= 0;
                    valid = 1;
                end
                else begin
                    mx2_row_cnt <= mx2_row_cnt + 1;
                end

                if(mx1_col_cnt == mx1_col -1)begin
                    mx1_col_cnt <= 0;
                end
                else mx1_col_cnt <= mx1_col_cnt + 1;
            end
            hold:begin
                buffer <= 0;
                valid <= 0;
            end
            not_legal:begin
                if(mx2_error_flag)ep <= ep + 2;
                mx2_error_flag <= 0;
                valid <= 1;
            end
            finish:begin
                valid <= 0;
                mx1_row <= 0;
                mx2_row <= 0;
                mx1_col <= 0;
                mx2_col <= 0;
                cnt <= 0;
                mx1_row_cnt <= 0;
                mx1_col_cnt <= 0;
                mx2_row_cnt <= 0;
                mx2_col_cnt <= 0;
                buffer <= 0;
                busy <= 0;
                mx1_error_flag <= 0;
                mx2_error_flag <= 0;
                ep <= 0;
                to_next <= 0;
            end
        endcase
    end
end
endmodule

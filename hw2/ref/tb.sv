`timescale 1ns/10ps
`define CYCLE      10.0
`define MAX_CYCLE  1000000
`define PAT        "./pat/pattern.dat"
`define PAT_T      "./pat/pattern_thing.dat"
`define PAT_POP_N  "./pat/pop_num.dat"
`define GOLDEN     "./golden/golden.dat"
`define GOLDEN_T   "./golden/golden_thing.dat"


module textfixture();
reg clk = 0;
reg rst = 1;

reg [7:0]people_thing_in;
reg ready_fifo;
reg ready_lifo;
reg [7:0]thing_in;
reg [3:0]thing_num;
wire valid_fifo;
wire valid_lifo;
wire valid_fifo2;
wire [7:0]people_thing_out;
wire [7:0]thing_out;
wire done_thing;
wire done_fifo;
wire done_lifo;
wire done_fifo2;

reg ready_wait = 0;
reg flag1 = 0;
reg flag2 = 0;
reg flag3 = 0;

integer people_thing_count = 0;
integer thing_count = 0;
integer thing_fifo2_count = 0;
integer err1_count = 0;
integer err2_count = 0;
integer err3_count = 0;
integer pass1_count = 0;
integer pass2_count = 0;
integer pass3_count = 0;
integer pat_num = 0;
integer pat_thing_num = 0;
integer pat_pop_num = 0;
integer score = 0;

reg [7:0]pattern[0:49];
reg [7:0]pattern_thing[0:49];
reg [7:0]golden[0:49];
reg [7:0]golden_thing[0:49];
reg [3:0]pop_num[0:49];

CIPU u_CIPU(.clk(clk),
            .rst(rst),
            .people_thing_in(people_thing_in),
            .ready_fifo(ready_fifo),
            .ready_lifo(ready_lifo),
            .thing_in(thing_in),
            .thing_num(thing_num),
            .valid_fifo(valid_fifo),
            .valid_lifo(valid_lifo),
            .valid_fifo2(valid_fifo2),
            .people_thing_out(people_thing_out),
            .thing_out(thing_out),
            .done_thing(done_thing),
            .done_fifo(done_fifo),
            .done_lifo(done_lifo),
            .done_fifo2(done_fifo2));

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
    $display("**************************************************");
    $display("***********      Simulation Start      ***********");
    $display("**************************************************");
    @(posedge clk);  #2 rst = 1'b1;
    #(`CYCLE*2);
    @(posedge clk);  #2 rst = 1'b0;
end

initial begin
    $readmemh(`PAT, pattern);
    $readmemh(`PAT_T, pattern_thing);
    $readmemh(`GOLDEN, golden);
    $readmemh(`GOLDEN_T, golden_thing);
    $readmemh(`PAT_POP_N, pop_num);
end

always@(posedge clk)begin
    if(!rst)begin
        if(!ready_wait)begin
            ready_fifo <= 1;
            ready_lifo <= 1;
            ready_wait <= 1;
        end
        else begin
            ready_fifo <= 0;
            ready_lifo <= 0;
        end
    end
    else begin
        ready_fifo <= 0;
        ready_lifo <= 0;
    end
end

always@(posedge clk)begin
    if(ready_wait)begin
        people_thing_in <= pattern[pat_num];
        $display("people_thing_in = %h", people_thing_in);
        if(pattern[pat_num] != 8'h24)
            pat_num <= pat_num + 1;
    end
end
// * FIFO *: Passenger Check-in
always@(posedge clk)begin
    if(valid_fifo)begin
        if(people_thing_count >= 15)begin
            $display("\n");
            $display("Failed pulling down valid_fifo signal, Simulation STOP !!!");
            $display("\n");
            $finish;
        end
        else begin
            if(people_thing_out == golden[people_thing_count]) begin
                pass1_count <= pass1_count + 1;
                $display("FIFO: Correct answer = %d, golden = %d", people_thing_out, golden[people_thing_count]); end 
            else begin
                err1_count <= err1_count + 1;
                $display("FIFO: Error at %3dth, your answer is %d but the correct answer is %d", people_thing_count, people_thing_out, golden[people_thing_count]);
            end

        end

        people_thing_count <= people_thing_count + 1;
    end
end

always@(posedge clk)begin
    if(ready_wait && pattern_thing[pat_thing_num] != 8'h24)begin
        if(pattern_thing[pat_thing_num] == 8'h3b && pattern_thing[pat_thing_num + 1] != 8'h3b)begin // ; + A
            if(done_thing)begin
                thing_in <= pattern_thing[pat_thing_num + 1];
                thing_num <= pop_num[pat_pop_num + 1];

                pat_thing_num <= pat_thing_num + 2;
                pat_pop_num <= pat_pop_num + 1;
            end
            else begin
                thing_in <= pattern_thing[pat_thing_num];
                thing_num <= pop_num[pat_pop_num];
            end
        end
        else if(pattern_thing[pat_thing_num] == 8'h3b && pattern_thing[pat_thing_num + 1] == 8'h3b)begin // ; + ;
            if(done_thing)begin
                thing_in <= pattern_thing[pat_thing_num + 1];
                thing_num <= pop_num[pat_pop_num + 1];

                pat_thing_num <= pat_thing_num + 1;
                pat_pop_num <= pat_pop_num + 1;
            end
            else begin
                thing_in <= pattern_thing[pat_thing_num];
                thing_num <= pop_num[pat_pop_num];
            end
        end
        else begin  // A + ; or A + A
            thing_in <= pattern_thing[pat_thing_num];
            thing_num <= pop_num[pat_pop_num];

            pat_thing_num <= pat_thing_num + 1;
        end
    end
end

always@(posedge clk)begin
    if(valid_lifo)begin
        if(thing_count >= 25)begin // why not 15?
            $display("\n");
            $display("!!! Failed pulling down valid_lifo signal, Simulation STOP !!!");
            $display("\n");
            $finish;
        end
        else begin
            if(thing_out == golden_thing[thing_count])begin
                pass2_count <= pass2_count + 1;
                // $display("LIFO: Error at %3dth, your answer is %s but the correct answer is %s", thing_count, thing_out, golden_thing[thing_count]);
            end
            else begin
                err2_count <= err2_count + 1;
                $display("LIFO: Error at %3dth, your answer is %h but the correct answer is %h", thing_count, thing_out, golden_thing[thing_count]);
                // $display("LIFO: Error at %3dth, your answer is %s but the correct answer is %s", thing_count, thing_out, golden_thing[thing_count]);
            end
        end

        thing_count <= thing_count + 1;
    end
end

always@(posedge clk)begin
    if(valid_fifo2)begin
        if(thing_fifo2_count >= 10)begin
            $display("\n");
            $display("!!! Failed pulling down valid_fifo2 signal, Simulation STOP !!!");
            $display("\n");
            $finish;
        end
        else begin
            if(thing_out == golden_thing[25+thing_fifo2_count])begin
                pass3_count <= pass3_count + 1;
                // $display("FIFO2: Error at %3dth, your answer is %s but the correct answer is %s", thing_fifo2_count, thing_out, golden_thing[thing_count]);
            end
            else begin
                err3_count <= err3_count + 1;
                $display("FIFO2: Error at %3dth, your answer is %h but the correct answer is %h", thing_fifo2_count, thing_out, golden_thing[thing_fifo2_count]);
                // $display("FIFO2: Error at %3dth, your answer is %s but the correct answer is %s", thing_fifo2_count, thing_out, golden_thing[thing_count]);
            end
        end

        thing_fifo2_count <= thing_fifo2_count + 1;
    end
end

initial begin
    # (`MAX_CYCLE);
    $display("\n");
    $display("\n");
    $display("        ****************************               ");
    $display("        **                        **       |\__||  ");
    $display("        **  OOPS!!                **      / X,X  | ");
    $display("        **                        **    /_____   | ");
    $display("        **  Simulation Failed!!   **   /^ ^ ^ \\  |");
    $display("        **                        **  |^ ^ ^ ^ |w| ");
    $display("        ****************************   \\m___m__|_|");
    $display("\n");
    $display("!!! Failed waiting done signal, Simulation STOP !!!");
    $stop;
end

always@(posedge clk)begin
    if(done_fifo && !flag1)begin
        if(err1_count == 0 && pass1_count == 15)begin
            score = score + 40;
            $display("\n\nThere are total %3d errors in FIFO  !!", 0);
        end
        else begin
            $display("\n\nThere are total %3d errors in FIFO  !!", 15-pass1_count);
        end
        flag1 = 1;
    end
    if(done_lifo && !flag2)begin
        if(err2_count == 0 && pass2_count == 25)begin
            score = score + 30;
            $display("\n\nThere are total %3d errors in LIFO  !!", 0);
        end
        else begin
            $display("\n\nThere are total %3d errors in LIFO  !!", 25-pass2_count);
        end
        flag2 = 1;
    end
    if(done_fifo2 && !flag3)begin
        if(err3_count == 0 && pass3_count == 10)begin
            score = score + 30;
            $display("\n\nThere are total %3d errors in FIFO2 !!", 0);
        end
        else begin
            $display("\n\nThere are total %3d errors in FIFO2 !!", 10-pass3_count);
        end
        flag3 = 1;
    end

    if(flag1 && flag2 && flag3)begin
        if(err1_count == 0 && err2_count == 0 && err3_count == 0 && pass1_count == 15 && pass2_count == 25 && pass3_count == 10) begin // all pattern pass, show info
            $display("\n");
            $display("        ****************************               ");
            $display("        **                        **       |\__||  ");
            $display("        **  Congratulations!!     **      / O.O  | ");
            $display("        **                        **    /_____   | ");
            $display("        **  Simulation PASS!!     **   /^ ^ ^ \\  |");
            $display("        **                        **  |^ ^ ^ ^ |w| ");
            $display("        ****************************   \\m___m__|_|");
            $display("\n        Correct / Total : %5d / %3d  " , score, 100);
            $display("\n");
        end
        else begin
            // $display("%d, %d, %d", pass1_count, pass2_count, pass3_count);
            $display("\n");
            $display("        ****************************               ");
            $display("        **                        **       |\__||  ");
            $display("        **  OOPS!!                **      / X,X  | ");
            $display("        **                        **    /_____   | ");
            $display("        **  Simulation Failed!!   **   /^ ^ ^ \\  |");
            $display("        **                        **  |^ ^ ^ ^ |w| ");
            $display("        ****************************   \\m___m__|_|");
            $display("\n        Correct / Total : %5d / %3d  " , score, 100);
            $display("\n");
        end
        $finish;
    end
end

endmodule


`timescale 1ns/10ps
`define CYCLE      8.5  
`define End_CYCLE  10000

module tb();


reg clk,rst;
wire[127:0]C;
wire valid;
integer i;
always begin #(`CYCLE/2) clk = ~clk; end

reg [127:0]P_data[0:99];
reg [127:0]K_data[0:99];
reg [127:0]C_data[0:99];
reg [127:0]P,K;
AES u_AES(clk,rst,P,K,C,valid);

initial begin // initial pattern and expected result
    $readmemh("./dat/P.txt", P_data);
    $readmemh("./dat/K.txt", K_data);
    $readmemh("./dat/C.txt", C_data);
    if(P_data[0]!==128'h3243f6a8885a308d313198a2e0370734)begin
        $display("P data not found, please check your data path.");
        $finish;
    end
    if(C_data[0]!==128'h3925841d02dc09fbdc118597196a0b32)begin
        $display("C data not found, please check your data path.");
        $finish;
    end
    if(K_data[0]!==128'h2b7e151628aed2a6abf7158809cf4f3c)begin
        $display("K data not found, please check your data path.");
        $finish;
    end
        
end
initial begin	
    $display("----------------------");
    $display("-- Simulation Start --");
    $display("----------------------");
	clk=0;
    rst = 1'b1;
    @(posedge clk);  #2 rst = 1'b1;
    #(`CYCLE*2);  
    @(posedge clk);  #2 rst = 1'b0;
end
reg [31:0] cycle=0;

reg [31:0] ans_cnt = 0;
reg [31:0] correct = 0;
reg [31:0] error = 0;
always @(posedge clk) begin
    if(rst)
        cycle=0;
    else begin
        cycle=cycle+1;
        
        if(valid)begin
            if(C_data[ans_cnt]==C)begin
                correct = correct + 1;
            end
            else begin
                $display("ERROR@ %02d , Expect Output: %x  Your Output: %x",ans_cnt, C_data[ans_cnt], C);
                error = error + 1;
            end
            ans_cnt = ans_cnt + 1;    
        end
        if(cycle >= 1 )begin
            #1;
            P = P_data[(cycle-1)];
            K = K_data[(cycle-1)];
        end


        if (ans_cnt==100) begin
            $display("Correct: %d", correct);
            if(correct==100)begin
                    $display("#                                            /|__/|");
                    $display("####################################       / O,O  |");
                    $display("###            Pass!             ###     /_____   |");
                    $display("####################################    /^ ^ ^ \\  |");
                    $display("#                                      |^ ^ ^ ^ |w|");
                    $display("#                                       \\m___m__|_|");
            end
            else begin
                $display("Please check your code.");
                $display("ERROR Count: %d\n",error);
            end
            $finish;
        end
        if (cycle > `End_CYCLE) begin
            $display("----------------------");
            $display("--- Run Time ERROR ---");
            $display("--- Simulation End ---");
            $display("----------------------");

        end
end
end
endmodule
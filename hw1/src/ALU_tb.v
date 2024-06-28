`timescale 1ns/10ps
`include "ALU.v"

module ALU_tb;
    reg [19:0] ALU_pattern[0:199];
    integer i, error;
    reg[4:0] ALU_GOLD;
    wire [4:0] ALU_out;
    reg[1:0] flag;
    reg signed [4:0] Din1;
    reg signed [4:0] Din2;
    reg [2:0] Sel;
    wire signed [4:0] temp;
    reg clk;
    reg [23:0] t;

    ALU uut(
        .Din1(Din1),
        .Din2(Din2),
        .Sel(Sel),
        .temp(ALU_out)
    );


    // read in ALU_data.dat
    initial begin
        clk              = 1'b0;
        flag             = 2'b00;
        forever #2.5 clk = ~clk;
    end

    initial begin
        $readmemh("./ALU_data.dat",ALU_pattern);
        $display("----------------------------------------");
        $display("----------------Stage 1-----------------");
        $display("--------- ALU Simulation Begin ---------");
        $display("----------------------------------------");
        error = 0;
        for(i = 0;i<200;i = i+1) begin
            t = ALU_pattern[i];
            @(negedge clk);
            Din1     = {1'b0,t[19:16]};
            Din2     = {1'b0,t[15:12]};
            Sel      = t[9:8];
            ALU_GOLD = t[4:0];

            @(posedge clk);
            if (ALU_out != ALU_GOLD) begin
                if (Sel == 0)
                    $display("ERROR: %d + %d should be %d ,not %d\n",Din1,Din2,ALU_GOLD,ALU_out);
                else if (Sel == 2'b11)
                    $display("ERROR: %d - %d should be %d ,not %d\n",Din1,Din2,ALU_GOLD,ALU_out);
                    error = error+1;
            end
        end
        if (error == 0) begin
            $display("----------------------------------------");
            $display("-------- ALU Simulation Success --------");
            $display("----------------------------------------");
            $display("----------------------------------------");
            $display("--------- ALU Simulation  End  ---------");
            $display("----------------------------------------\n");
            error = 0;
            flag  = 2'b01;
        end
        else begin
            $display("Please check your code.");
            $display("ERROR Count: %d\n",error);
            $display("----------------------------------------");
            $display("--------- ALU Simulation  End  ---------");
            $display("----------------------------------------\n");
            $finish;
        end
        end

    endmodule
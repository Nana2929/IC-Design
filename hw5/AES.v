//
// Designer: P76114511 Ching-Wen Yang
//
// `include "helpers.v"
// `include "round.v"
// `include "aes_sbox.v"
module AES(
    input wire clk,
    input wire rst,
    input wire [127:0] P,
    input wire [127:0] K,
    output reg [127:0] C,
    output reg valid
    );
    localparam NUM_ROUNDS = 10;

    // write your design here //
    reg [127:0] key_mem [0:NUM_ROUNDS];
    reg [127:0] P_mem [0:NUM_ROUNDS];
    wire [127:0] key_result [0:NUM_ROUNDS];
    wire [127:0] P_result [0:NUM_ROUNDS];


    AESRound r1(.rc(4'b0000), .Pi(P_mem[0]), .Ki(key_mem[0]), .Po(P_result[0]), .Ko(key_result[0]));
    AESRound r2(.rc(4'b0001), .Pi(P_mem[1]), .Ki(key_mem[1]), .Po(P_result[1]), .Ko(key_result[1]));
    AESRound r3(.rc(4'b0010), .Pi(P_mem[2]), .Ki(key_mem[2]), .Po(P_result[2]), .Ko(key_result[2]));
    AESRound r4(.rc(4'b0011), .Pi(P_mem[3]), .Ki(key_mem[3]), .Po(P_result[3]), .Ko(key_result[3]));
    AESRound r5(.rc(4'b0100), .Pi(P_mem[4]), .Ki(key_mem[4]), .Po(P_result[4]), .Ko(key_result[4]));
    AESRound r6(.rc(4'b0101), .Pi(P_mem[5]), .Ki(key_mem[5]), .Po(P_result[5]), .Ko(key_result[5]));
    AESRound r7(.rc(4'b0110), .Pi(P_mem[6]), .Ki(key_mem[6]), .Po(P_result[6]), .Ko(key_result[6]));
    AESRound r8(.rc(4'b0111), .Pi(P_mem[7]), .Ki(key_mem[7]), .Po(P_result[7]), .Ko(key_result[7]));
    AESRound r9(.rc(4'b1000), .Pi(P_mem[8]), .Ki(key_mem[8]), .Po(P_result[8]), .Ko(key_result[8]));
    AESLastRound r10(.rc(4'b1001), .Pi(P_mem[9]), .Ki(key_mem[9]), .Po(P_result[9]), .Ko(key_result[9]));
    integer i;
    reg [6:0] r_count;

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            // clean key_mem, P_mem

            for (i = 0; i < NUM_ROUNDS; i = i + 1) begin
                key_mem[i] <= 128'h0;
                P_mem[i] <= 128'h0;
            end
            r_count <= 0;
            valid <= 0;
        end
        else
            r_count <= r_count + 1; // the global round count
            key_mem[0] <= K;
            P_mem[0] <= P ^ K;
            // round 1 ~ 9
            for (i = 1; i <= NUM_ROUNDS; i = i + 1) begin
                key_mem[i] <= key_result[i - 1];
                // add round key 
                P_mem[i] <= P_result[i - 1] ^ key_result[i - 1];
            end
            C <= P_mem[NUM_ROUNDS];
            valid <= 1 & (r_count > NUM_ROUNDS+1);
    end
endmodule
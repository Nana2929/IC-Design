//
// Designer: P76114511 Ching-Wen Yang
// helper functions for AES (steps)
//

module ByteSubstitution(data,
                        scramble);
    //Byte Substitution is the first step to encrypt the information.
    //The 128 bit data is divided into a 4x4 matrix where each element has 1 byte i.e. 8 bis of information.

    input wire [127:0] data;
    output wire [127:0] scramble;

    // The data is scrambled with respect to the S-Box byte-by-byte.
    aes_sbox s0(.sboxw(data[7:0]),.new_sboxw(scramble[7:0]));
    aes_sbox s1(.sboxw(data[15:8]),.new_sboxw(scramble[15:8]));
    aes_sbox s2(.sboxw(data[23:16]),.new_sboxw(scramble[23:16]));
    aes_sbox s3(.sboxw(data[31:24]),.new_sboxw(scramble[31:24]));
    aes_sbox s4(.sboxw(data[39:32]),.new_sboxw(scramble[39:32]));
    aes_sbox s5(.sboxw(data[47:40]),.new_sboxw(scramble[47:40]));
    aes_sbox s6(.sboxw(data[55:48]),.new_sboxw(scramble[55:48]));
    aes_sbox s7(.sboxw(data[63:56]),.new_sboxw(scramble[63:56]));
    aes_sbox s8(.sboxw(data[71:64]),.new_sboxw(scramble[71:64]));
    aes_sbox s9(.sboxw(data[79:72]),.new_sboxw(scramble[79:72]));
    aes_sbox s10(.sboxw(data[87:80]),.new_sboxw(scramble[87:80]));
    aes_sbox s11(.sboxw(data[95:88]),.new_sboxw(scramble[95:88]));
    aes_sbox s12(.sboxw(data[103:96]),.new_sboxw(scramble[103:96]));
    aes_sbox s13(.sboxw(data[111:104]),.new_sboxw(scramble[111:104]));
    aes_sbox s14(.sboxw(data[119:112]),.new_sboxw(scramble[119:112]));
    aes_sbox s15(.sboxw(data[127:120]),.new_sboxw(scramble[127:120]));
endmodule


module ShiftRows(
    input wire [127:0] i_block,
    output wire [127:0] o_block
    );

    wire [31:0]            w0,w1,w2,w3;
    wire [31:0]            mw0,mw1,mw2,mw3;
    assign w0 = i_block[127:96];
    assign w1 = i_block[95:64];
    assign w2 = i_block[63:32];
    assign w3 = i_block[31:0];

    assign mw0 = {{w0[31:24]},{w1[23:16]},{w2[15:8]},{w3[7:0]}};
    assign mw1 = {{w1[31:24]},{w2[23:16]},{w3[15:8]},{w0[7:0]}};
    assign mw2 = {{w2[31:24]},{w3[23:16]},{w0[15:8]},{w1[7:0]}};
    assign mw3 = {{w3[31:24]},{w0[23:16]},{w1[15:8]},{w2[7:0]}};

    assign o_block = {mw0, mw1, mw2, mw3};
endmodule // ShiftRows

module MixColumns(
    input wire [127:0] i_block,
    output wire [127:0] o_block
    );

    wire [31:0] w0,w1,w2,w3;
    wire [31:0] mw0,mw1,mw2,mw3;
    //reg [127:0] o_block_reg;

    assign w0 = i_block[127:96];
    assign w1 = i_block[95:64];
    assign w2 = i_block[63:32];
    assign w3 = i_block[31:0];

    MixWords m1(.w(w0),.mw(mw0));
    MixWords m2(.w(w1),.mw(mw1));
    MixWords m3(.w(w2),.mw(mw2));
    MixWords m4(.w(w3),.mw(mw3));

    //o_block_reg  = {mw0, mw1, mw2, mw3};
    assign o_block = {mw0, mw1, mw2, mw3};
endmodule


module MixWords(input wire [31:0] w, output wire [31:0] mw);
wire[7:0] b0,b1,b2,b3;
wire[7:0] mb0,mb1,mb2,mb3;

function [7:0] gm2(input [7:0] a);

      begin
     gm2 = {a[6:0],1'b0} ^ (8'h1b & {8{a[7]}});
      end
endfunction // gm2

function [7:0] gm3(input [7:0] a);
      begin
     gm3 = gm2(a) ^ a;
      end
endfunction // gm3

     assign b0 = w[31:24];
     assign b1 = w[23:16];
     assign b2 = w[15:8];
     assign b3 = w[7:0];

     assign mb0 = gm2(b0) ^ gm3(b1) ^ b2 ^ b3;
     assign mb1 = b0 ^ gm2(b1) ^ gm3(b2) ^ b3;
     assign mb2 = b0 ^ b1 ^ gm2(b2) ^ gm3(b3);
     assign mb3 = gm3(b0) ^ b1 ^ b2 ^ gm2(b3);

     assign mw = {mb0, mb1, mb2, mb3};

endmodule


module RoundKeyGenerator(rc, i_key, o_key);
    input wire [3:0]  rc;
    input wire [127:0] i_key;
    output wire [127:0] o_key;
    wire [31:0] w0,w1,w2,w3, rotw3;
    wire [31:0] temp;
    assign w0 = i_key[127:96];
    assign w1 = i_key[95:64];
    assign w2 = i_key[63:32];
    assign w3 = i_key[31:0];

    // rotword
    // [a0, a1, a2, a3] -> [a1, a2, a3, a0]
    assign rotw3 = {w3[23:0],w3[31:24]};

    // subword
    aes_sbox s1(.sboxw(rotw3[7:0]),.new_sboxw(temp[7:0]));
    aes_sbox s2(.sboxw(rotw3[15:8]),.new_sboxw(temp[15:8]));
    aes_sbox s3(.sboxw(rotw3[23:16]),.new_sboxw(temp[23:16]));
    aes_sbox s4(.sboxw(rotw3[31:24]),.new_sboxw(temp[31:24]));

    function automatic [31:0] Rcon(input [3:0] rc1);
        case(rc1)
            4'b0000: Rcon = 32'h01_00_00_00;//Underscores are used to improve readability of bytes.
            4'b0001: Rcon = 32'h02_00_00_00;
            4'b0010: Rcon = 32'h04_00_00_00;
            4'b0011: Rcon = 32'h08_00_00_00;
            4'b0100: Rcon = 32'h10_00_00_00;
            4'b0101: Rcon = 32'h20_00_00_00;
            4'b0110: Rcon = 32'h40_00_00_00;
            4'b0111: Rcon = 32'h80_00_00_00;
            4'b1000: Rcon = 32'h1b_00_00_00;
            4'b1001: Rcon = 32'h36_00_00_00;
            default: Rcon = 32'h00_00_00_00;
        endcase
    endfunction

    // xor with rcon
    assign o_key[127:96] = w0 ^ temp ^ Rcon(rc);
    assign o_key[95:64] = w1 ^ o_key[127:96];
    assign o_key[63:32] = w2 ^ o_key[95:64];
    assign o_key[31:0] = w3 ^ o_key[63:32];
endmodule



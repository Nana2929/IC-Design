//
// Designer: P76114511 Ching-Wen Yang
//

module AESRound(rc,
                Pi,
                Ki,
                Po,
                Ko);
    input wire [3:0] rc;
    input wire [127:0] Pi;
    input wire [127:0] Ki;

    output wire [127:0] Po;
    output wire [127:0] Ko;


    wire [127:0] sb,sr,mcl;

    RoundKeyGenerator t0(.rc(rc),.i_key(Ki),.o_key(Ko));
    ByteSubstitution t1(.data(Pi),.scramble(sb));
    ShiftRows t2(.i_block(sb),.o_block(sr));
    MixColumns t3(.i_block(sr),.o_block(mcl));
    assign Po = mcl;
    // can't do Round key here
    // because Ko is not ready yet

endmodule

module AESLastRound(rc, Pi, Ki, Ko, Po);
    input wire [127:0] Pi;
    input wire [127:0] Ki;
    input wire [3:0] rc;

    output wire [127:0] Ko;
    output wire [127:0] Po;

    wire [127:0] sb, sr;

    RoundKeyGenerator t0(.rc(rc), .i_key(Ki), .o_key(Ko));
    ByteSubstitution t1(.data(Pi),.scramble(sb));
    ShiftRows t2(.i_block(sb),.o_block(sr));
    assign Po = sr;
endmodule
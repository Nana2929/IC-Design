`define ADD 2'b00
`define SUB 2'b11


module ALU(Din1, Din2, Sel, temp);
input signed [4:0] Din1;
input signed [4:0] Din2;
input [1:0] Sel;
output reg signed [4:0] temp;

always@(*)
begin
    case (Sel)
        `ADD: temp = Din1 + Din2; // if Din1 and Din2 are both signed, the result will be signed
        `SUB: temp = Din1 - Din2;
    default: temp = Din1;
    endcase
end
endmodule



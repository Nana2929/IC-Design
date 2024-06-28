//
// Designer: <student ID>
//
`include "ALU.v"
`include "QComp.v"

module MAS_2input(
    input signed [4:0]Din1,
    input signed [4:0]Din2,
    input [1:0]Sel,
    input signed[4:0]Q,
    output [1:0]Tcmp,
    output signed [4:0]TDout,
    output signed [3:0]Dout
);
wire signed [4:0] zero = 5'b0;

/*Write your design here*/
ALU alu1(
    .Din1(Din1),
    .Din2(Din2),
    .Sel(Sel),
    .temp(TDout)
);
QComp qcomp(
    .Din1(TDout),
    .Din2(zero),
    .Q(Q),
    .res(Tcmp)
);
ALU alu2(
    .Din1(TDout),
    .Din2(Q),
    .Sel(Tcmp),
    .temp(Dout)
);


endmodule
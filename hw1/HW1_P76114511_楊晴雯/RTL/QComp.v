

module QComp(
    input signed [4:0]Din1,//
    input signed [4:0]Din2,//zero
    input signed [4:0]Q,
    output [1:0]res
);
    //assign lsb to be 1 if Din1 >= Din2
    //assign msb to be 1 if Din1 >= Q
    assign res[0] = (Din1 >= Din2);
    assign res[1] = (Din1 >= Q);
endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/29 19:18:06
// Design Name: 
// Module Name: ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defs.vh"

module ALU(
        input wire clk,
        input wire rst,
        input wire [31:0] a,
        input wire [31:0] b,
        input wire [3:0] alu_op,
        input wire valid,
        input wire ex_stall,
        output wire [31:0] out,
        output wire alu_stall
    );

    wire [31:0] outs [12:0];
    wire [63:0] mul_prod;
    wire mul_finish;

    assign outs[`ALU_OP_ADD] = a + b;
    assign outs[`ALU_OP_SUB] = a - b;
    assign outs[`ALU_OP_SLT] = {31'b0, $signed(a) < $signed(b)};
    assign outs[`ALU_OP_SLTU] = {31'b0, $unsigned(a) < $unsigned(b)};
    assign outs[`ALU_OP_AND] = a & b;
    assign outs[`ALU_OP_OR] = a | b;
    assign outs[`ALU_OP_XOR] = a ^ b;
    assign outs[`ALU_OP_SLL] = a << b[4:0];
    assign outs[`ALU_OP_SRL] = a >> b[4:0];
    assign outs[`ALU_OP_SRA] = $signed(a) >>> b[4:0];
    assign outs[`ALU_OP_RS2] = b;
    assign outs[`ALU_OP_PCADD4] = a + 32'h4;
    assign outs[`ALU_OP_MUL] = mul_prod[31:0];

    reg [2:0] cnt;
    always @ (posedge clk) begin
        if (rst) begin
            cnt <= 3'b0;
        end else if (mul_finish && (~ex_stall)) begin
            cnt <= 3'b0;
        end else if ((~|(alu_op ^ `ALU_OP_MUL)) && (~mul_finish)) begin
            cnt <= (valid)? cnt + 3'b1 : 3'b0;
        end
    end

    mult_gen_0 mul (
        .CLK(clk),
        .A(a),
        .B(b),
        .P(mul_prod)
    );

    assign mul_finish = ~|(cnt ^ 3'b010);

    assign out = outs[alu_op];
    assign alu_stall = (~|(alu_op ^ `ALU_OP_MUL)) & (~mul_finish) & valid;

endmodule

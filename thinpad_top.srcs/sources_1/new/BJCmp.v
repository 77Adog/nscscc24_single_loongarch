`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/13 13:14:27
// Design Name: 
// Module Name: BJCmp
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

module BJCmp(
        input wire [31:0] a_val,
        input wire [31:0] b_val,
        input wire [3:0] op,
        output wire cmp_res
    );

    wire [32:0] temp;
    wire cmp_ress [9:0];

    assign temp = {1'b0, a_val} - {1'b0, b_val};
    assign cmp_ress[`BJUnit_OP_BEQ] = ~|(temp[31:0]);
    assign cmp_ress[`BJUnit_OP_BNE] = (~cmp_ress[`BJUnit_OP_BEQ]);
    assign cmp_ress[`BJUnit_OP_BLT] = (~b_val[31] & (a_val[31] | temp[31])) | (a_val[31] & temp[31]);
    assign cmp_ress[`BJUnit_OP_BGE] = (~cmp_ress[`BJUnit_OP_BLT]);
    assign cmp_ress[`BJUnit_OP_BLTU] = temp[32];
    assign cmp_ress[`BJUnit_OP_BGEU] = ~temp[32];
    assign cmp_ress[`BJUnit_OP_B] = 1'b1;
    assign cmp_ress[`BJUnit_OP_BL] = 1'b1;
    assign cmp_ress[`BJUnit_OP_JIRL] = 1'b1;
    assign cmp_ress[`BJUnit_OP_NOP] = 1'b0;

    assign cmp_res = cmp_ress[op];
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/10 15:38:46
// Design Name: 
// Module Name: ImmGen
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

module ImmGen(
        input wire [31:0] inst,
        input wire [2:0] imm_sel,
        output wire [31:0] imm
    );

    wire [31:0] imms [5:0];

    assign imms[`IMM_SI12_INDEX] = {{20{inst[21]}}, inst[21:10]}; // si12
    assign imms[`IMM_UI12_INDEX] = {20'b0, inst[21:10]}; // ui12
    assign imms[`IMM_OFFS16_INDEX] = {{14{inst[25]}}, inst[25:10], 2'b00}; // offs16
    assign imms[`IMM_OFFS26_INDEX] = {{4{inst[9]}}, inst[9:0], inst[25:10], 2'b00}; // offs26
    assign imms[`IMM_UI5_INDEX] = {27'b0, inst[14:10]}; // ui5
    assign imms[`IMM_SI20_INDEX] = {inst[24:5], 12'b0}; // si20

    assign imm = imms[imm_sel];
endmodule

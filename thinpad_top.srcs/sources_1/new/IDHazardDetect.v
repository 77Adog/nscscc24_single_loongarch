`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/02 10:17:24
// Design Name: 
// Module Name: IDHazardDetect
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


module IDHazardDetect(
        input wire id2_use_rs1,
        input wire id2_use_rs2,

        input wire ifid1_valid,
        input wire ifid2_valid,

        input wire [4:0] id1_rd,
        input wire id1_reg_wen,
        input wire [4:0] id2_rs1,
        input wire [4:0] id2_rs2,

        output wire id2_data_stall
    );

    wire id2_rs1_stall, id2_rs2_stall;
    wire id1_rd_not_zero;

    assign id1_rd_not_zero = (id1_rd != 5'b0);

    assign id2_rs1_stall = (id2_use_rs1 & (~|(id2_rs1 ^ id1_rd)) & id1_rd_not_zero & ifid2_valid & ifid1_valid & id1_reg_wen);

    assign id2_rs2_stall = (id2_use_rs2 & (~|(id2_rs2 ^ id1_rd)) & id1_rd_not_zero & ifid2_valid & ifid1_valid & id1_reg_wen);

    assign id2_data_stall = id2_rs1_stall | id2_rs2_stall;
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/17 12:58:39
// Design Name: 
// Module Name: BranchPredictor
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

/*
direct-mapped BHT and BTB
BHT: 2-bit counter
BTB: 32-bit branch target
byte offset: 2 bits
index: `BRANCH_PREDICTOR_INDEX_LEN
tag: 30 - `BRANCH_PREDICTOR_INDEX_LEN
*/


module BranchPredictor(
        input wire clk,
        input wire rst,

        // Face IF
        input wire [31:0] pc1,
        input wire [31:0] pc2,
        output wire if_do_branch1,
        output wire if_do_branch2,
        output wire [31:0] if_branch_target1,
        output wire [31:0] if_branch_target2,

        // Face EX
        input wire [31:0] ex_pc1,
        input wire [31:0] ex_pc2,
        input wire ex1_do_branch,
        input wire ex2_do_branch,
        input wire ex1_is_branch,
        input wire ex2_is_branch, // is_branch_type & idex_valid & (~ex_stall)
        input wire [31:0] ex1_branch_target,
        input wire [31:0] ex2_branch_target,
        output wire fit_branch1,
        output wire fit_branch2,
        output wire [31:0] fit_branch_target1,
        output wire [31:0] fit_branch_target2
    );

    // BHT and BTB
    (* ram_style = "block" *) reg [1:0] bht [`BRANCH_PREDICTOR_SIZE - 1:0]; // 11: strong taken, 10: weak taken, 01: weak not taken, 00: strong not taken
    (* ram_style = "block" *) reg [31:0] btb [`BRANCH_PREDICTOR_SIZE - 1:0];
    (* ram_style = "block" *) reg [29 - `BRANCH_PREDICTOR_INDEX_LEN:0] tag [`BRANCH_PREDICTOR_SIZE - 1:0];
    (* ram_style = "block" *) reg valid [`BRANCH_PREDICTOR_SIZE - 1:0];

    // Split address
    wire [`BRANCH_PREDICTOR_INDEX_LEN - 1:0] pc1_index, pc2_index, ex_pc1_index, ex_pc2_index;
    wire [29 - `BRANCH_PREDICTOR_INDEX_LEN:0] pc1_tag, pc2_tag, ex_pc1_tag, ex_pc2_tag;

    assign pc1_index = pc1[`BRANCH_PREDICTOR_INDEX_LEN + 1:2];
    assign pc2_index = pc2[`BRANCH_PREDICTOR_INDEX_LEN + 1:2];
    assign ex_pc1_index = ex_pc1[`BRANCH_PREDICTOR_INDEX_LEN + 1:2];
    assign ex_pc2_index = ex_pc2[`BRANCH_PREDICTOR_INDEX_LEN + 1:2];
    assign pc1_tag = pc1[31:2 + `BRANCH_PREDICTOR_INDEX_LEN];
    assign pc2_tag = pc2[31:2 + `BRANCH_PREDICTOR_INDEX_LEN];
    assign ex_pc1_tag = ex_pc1[31:2 + `BRANCH_PREDICTOR_INDEX_LEN];
    assign ex_pc2_tag = ex_pc2[31:2 + `BRANCH_PREDICTOR_INDEX_LEN];

    wire pc1_hit, pc2_hit, ex_pc1_hit, ex_pc2_hit;
    assign pc1_hit = (~|(tag[pc1_index] ^ pc1_tag)) & valid[pc1_index];
    assign pc2_hit = (~|(tag[pc2_index] ^ pc2_tag)) & valid[pc2_index];
    assign ex_pc1_hit = (~|(tag[ex_pc1_index] ^ ex_pc1_tag)) & valid[ex_pc1_index];
    assign ex_pc2_hit = (~|(tag[ex_pc2_index] ^ ex_pc2_tag)) & valid[ex_pc2_index];

    // regs modification
    wire ex1_write_info, ex2_write_info, ex1_update_info, ex2_update_info;

    assign ex1_write_info = ex1_is_branch & (~ex_pc1_hit);
    assign ex2_write_info = ex2_is_branch & (~ex_pc2_hit);
    assign ex1_update_info = ex1_is_branch & ex_pc1_hit;
    assign ex2_update_info = ex2_is_branch & ex_pc2_hit;

    integer i;
    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < `BRANCH_PREDICTOR_SIZE; i = i + 1) begin
                valid[i] <= 1'b0;
                tag[i] <= 0;
                bht[i] <= 0;
                btb[i] <= 0;
            end
        end
        else begin
            for (i = 0; i < `BRANCH_PREDICTOR_SIZE; i = i + 1) begin
                if (ex2_write_info && (~|(ex_pc2_index ^ i[`BRANCH_PREDICTOR_INDEX_LEN - 1:0]))) begin
                    valid[i] <= 1'b1;
                    tag[i] <= ex_pc2_tag;
                    bht[i] <= (ex2_do_branch)? 2'b10: 2'b01;
                    btb[i] <= ex2_branch_target;
                end
                else if (ex1_write_info && (~|(ex_pc1_index ^ i[`BRANCH_PREDICTOR_INDEX_LEN - 1:0]))) begin
                    valid[i] <= 1'b1;
                    tag[i] <= ex_pc1_tag;
                    bht[i] <= (ex1_do_branch)? 2'b10: 2'b01;
                    btb[i] <= ex1_branch_target;
                end
                else if (ex2_update_info && (~|(ex_pc2_index ^ i[`BRANCH_PREDICTOR_INDEX_LEN - 1:0]))) begin
                    case (bht[i])
                        2'b00: bht[i] <= (ex2_do_branch)? 2'b01: 2'b00;
                        2'b01: bht[i] <= (ex2_do_branch)? 2'b10: 2'b00;
                        2'b10: bht[i] <= (ex2_do_branch)? 2'b11: 2'b01;
                        2'b11: bht[i] <= (ex2_do_branch)? 2'b11: 2'b10;
                    endcase
                    btb[i] <= ex2_branch_target;
                end
                else if (ex1_update_info && (~|(ex_pc1_index ^ i[`BRANCH_PREDICTOR_INDEX_LEN - 1:0]))) begin
                    case(bht[i])
                        2'b00: bht[i] <= (ex1_do_branch)? 2'b01: 2'b00;
                        2'b01: bht[i] <= (ex1_do_branch)? 2'b10: 2'b00;
                        2'b10: bht[i] <= (ex1_do_branch)? 2'b11: 2'b01;
                        2'b11: bht[i] <= (ex1_do_branch)? 2'b11: 2'b10;
                    endcase
                    btb[i] <= ex1_branch_target;
                end
            end
        end
    end

    // IF state predict branch
    assign if_do_branch1 = pc1_hit & bht[pc1_index][1];
    assign if_do_branch2 = pc2_hit & bht[pc2_index][1];
    assign if_branch_target1 = btb[pc1_index];
    assign if_branch_target2 = btb[pc2_index];

    // EX state fit branch

    wire ex1_predict_branch, ex2_predict_branch;

    assign ex1_predict_branch = ex_pc1_hit & bht[ex_pc1_index][1];
    assign ex2_predict_branch = ex_pc2_hit & bht[ex_pc2_index][1];

    wire wrong_taken1, wrong_taken2, wrong_not_taken1, wrong_not_taken2, wrong_target1, wrong_target2;

    assign wrong_taken1 = ex1_predict_branch & (~ex1_do_branch) & ex1_is_branch;
    assign wrong_taken2 = ex2_predict_branch & (~ex2_do_branch) & ex2_is_branch;
    assign wrong_not_taken1 = (~ex1_predict_branch) & ex1_do_branch;
    assign wrong_not_taken2 = (~ex2_predict_branch) & ex2_do_branch;
    assign wrong_target1 = (|(ex1_branch_target ^ btb[ex_pc1_index])) & ex1_do_branch;
    assign wrong_target2 = (|(ex2_branch_target ^ btb[ex_pc2_index])) & ex2_do_branch;

    assign fit_branch1 = wrong_taken1 | wrong_not_taken1 | wrong_target1;
    assign fit_branch2 = wrong_taken2 | wrong_not_taken2 | wrong_target2;
    assign fit_branch_target1 = (wrong_taken1)? ex_pc1 + 32'h4: ex1_branch_target;
    assign fit_branch_target2 = (wrong_taken2)? ex_pc2 + 32'h4: ex2_branch_target;

endmodule

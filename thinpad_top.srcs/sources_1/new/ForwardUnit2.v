`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/01 14:32:05
// Design Name: 
// Module Name: ForwardUnit2
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


module ForwardUnit2(
        // ID
        input wire [4:0] id1_rs1,
        input wire [4:0] id1_rs2,
        input wire [4:0] id2_rs1,
        input wire [4:0] id2_rs2,
        input wire [31:0] id1_rs1_val,
        input wire [31:0] id1_rs2_val,
        input wire [31:0] id2_rs1_val,
        input wire [31:0] id2_rs2_val,

        // EX
        input wire ex1_valid,
        input wire ex2_valid,
        input wire [4:0] ex1_rd,
        input wire [4:0] ex2_rd,
        input wire ex1_reg_wen,
        input wire ex2_reg_wen,
        input wire [31:0] ex1_alu_out,
        input wire [31:0] ex2_alu_out,
        input wire ex1_datatoreg,
        input wire ex2_datatoreg,
        input wire [31:0] dmem_rdata,

        // Forward val
        output wire [31:0] id1_rs1_val_f,
        output wire [31:0] id1_rs2_val_f,
        output wire [31:0] id2_rs1_val_f,
        output wire [31:0] id2_rs2_val_f
    );

    wire [31:0] ex1_write_data, ex2_write_data;

    assign ex1_write_data = (ex1_datatoreg)? dmem_rdata: ex1_alu_out;
    assign ex2_write_data = (ex2_datatoreg)? dmem_rdata: ex2_alu_out;

    
    assign id1_rs1_val_f =  ((~|(ex2_rd ^ id1_rs1)) & ex2_reg_wen & ex2_valid)? ex2_write_data:
                            ((~|(ex1_rd ^ id1_rs1)) & ex1_reg_wen & ex1_valid)? ex1_write_data:
                            id1_rs1_val;
    
    assign id1_rs2_val_f =  ((~|(ex2_rd ^ id1_rs2)) & ex2_reg_wen & ex2_valid)? ex2_write_data:
                            ((~|(ex1_rd ^ id1_rs2)) & ex1_reg_wen & ex1_valid)? ex1_write_data:
                            id1_rs2_val;

    assign id2_rs1_val_f =  ((~|(ex2_rd ^ id2_rs1)) & ex2_reg_wen & ex2_valid)? ex2_write_data:
                            ((~|(ex1_rd ^ id2_rs1)) & ex1_reg_wen & ex1_valid)? ex1_write_data:
                            id2_rs1_val;

    assign id2_rs2_val_f =  ((~|(ex2_rd ^ id2_rs2)) & ex2_reg_wen & ex2_valid)? ex2_write_data:
                            ((~|(ex1_rd ^ id2_rs2)) & ex1_reg_wen & ex1_valid)? ex1_write_data:
                            id2_rs2_val;

endmodule

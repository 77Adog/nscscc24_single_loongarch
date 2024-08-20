`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/01 13:47:13
// Design Name: 
// Module Name: RegFile2
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


module RegFile2(
        input wire clk,
        input wire rst,

        input wire [4:0] rs1_line1,
        input wire [4:0] rs2_line1,
        input wire [4:0] rd_line1,
        input wire [31:0] i_data_line1,
        input wire reg_wen_line1,
        output wire [31:0] rs1_val_line1,
        output wire [31:0] rs2_val_line1,

        input wire [4:0] rs1_line2,
        input wire [4:0] rs2_line2,
        input wire [4:0] rd_line2,
        input wire [31:0] i_data_line2,
        input wire reg_wen_line2,
        output wire [31:0] rs1_val_line2,
        output wire [31:0] rs2_val_line2
    );

    reg [31:0] regs [31:0];

    wire [31:0] regs_next [31:0];

    assign regs_next[0] = 32'b0;

    genvar  i;
    generate 
            for(i = 1; i <= 31; i = i + 1) begin
                assign regs_next[i] =   ((~|(rd_line2 ^ i[4:0])) && reg_wen_line2) ? i_data_line2 : 
                                        ((~|(rd_line1 ^ i[4:0])) && reg_wen_line1) ? i_data_line1 : regs[i];
            end
    endgenerate

    assign rs1_val_line1 = regs_next[rs1_line1];
    assign rs2_val_line1 = regs_next[rs2_line1];
    assign rs1_val_line2 = regs_next[rs1_line2];
    assign rs2_val_line2 = regs_next[rs2_line2];

    integer j;
    always @(posedge clk) begin
        if (rst) begin
            for (j = 0; j <= 31; j = j + 1) begin
                regs[j[4:0]] <= 32'b0;
            end
        end else begin
            for (j = 0; j <= 31; j = j + 1) begin
                regs[j[4:0]] <= regs_next[j[4:0]];
            end
        end
    end


    
endmodule

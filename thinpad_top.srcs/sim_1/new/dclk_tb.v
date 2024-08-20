`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/14 10:50:54
// Design Name: 
// Module Name: dclk_tb
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


module dclk_tb(

    );
    
    reg clk;
    reg rst;
    wire neg_clk;

    assign neg_clk = ~clk;

    reg [1:0] data;

    always @ (posedge clk or posedge neg_clk) begin
        if (rst) begin
            data <= 2'b00;
        end else if (clk) begin
            data <= 2'b01;
        end
        else if (neg_clk) begin
            data <= 2'b10;
        end
    end


    always begin
        clk <= 1'b1; #10;
        clk <= 1'b0; #10;
    end

    initial begin
        rst <= 1'b1;
        #40;
        rst <= 1'b0;
    end
endmodule

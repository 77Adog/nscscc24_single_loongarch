`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/16 13:36:36
// Design Name: 
// Module Name: equal
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


module equal(

    );

    reg [31:0] a;
    reg [31:0] b;

    wire e;

    assign e = ~|(a ^ b);

    initial begin
        a <= 32'h80000000;
        b <= 32'h80000000;
        #20;
        a <= 32'h80000000;
        b <= 32'h80000001;
    end
endmodule

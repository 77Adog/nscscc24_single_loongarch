`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/28 15:25:15
// Design Name: 
// Module Name: iMC
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

module iMC(
        input wire clk,
        input wire rst,
        // Face to icache
        input wire [31:0] icache_addr,
        input wire icache_ren,
        output reg [31:0] icache_rdata,
        output wire write_inst_W1,
        output wire write_inst_W2,
        // CPU read
        input wire [31:0] read_addr,
        input wire ren,
        output wire [31:0] rdata,
        output wire read_stall,
        // CPU write
        input wire wen,
        input wire [31:0] wdata,
        input wire [31:0] waddr,
        input wire [3:0] wbe,
        output wire write_stall,
        // Face to sram
        output reg [19:0] addr_o,
        output reg ren_o, // 0 enable, 1 disable
        output reg wen_o, // 0 enable, 1 disable
        output reg [3:0] be_o, // 0 enable, 1 disable
        output reg [31:0] data_in_o,
        output reg ce_o, // 0 enable, 1 disable
        input wire [31:0] data_out_i
    );

    // Memory access control
    reg r_state;
    reg [1:0] icache_state;
    reg w_state;

    // The count of cycles for read, icache, write
    reg [1:0] rcnt;
    reg [1:0] icache_rcnt;
    reg [1:0] wcnt;

    /*
    For r_state
    0: IDLE
    1: read state (when rcnt == `SRAM_ACCESS_CNT, goto finish)

    For icache_state
    0: IDLE
    1: read the first word (when icache_rcnt == `SRAM_ACCESS_CNT, goto read the second word)
    2: read the second word (when icache_rcnt == `SRAM_ACCESS_CNT, return to IDLE)
    3: finish reading

    For w_state
    0: IDLE
    1: write state (when wcnt == `SRAM_ACCESS_CNT, return to IDLE)

    Priority: w > r > icache
    */

    wire w_state_idle, r_state_idle, icache_state_idle;
    wire read_finish, icache_w1_read_finish, icache_w2_read_finish, write_finish;
    wire all_idle;

    assign w_state_idle = ~w_state;
    assign r_state_idle = ~r_state;
    assign icache_state_idle = ~|icache_state;

    assign all_idle = w_state_idle & r_state_idle & icache_state_idle;

    assign write_stall = wen & (~all_idle);
    assign read_stall = ren & ~read_finish;

    assign read_finish = r_state & (rcnt == `SRAM_ACCESS_CNT);
    assign icache_w1_read_finish = (icache_state == 2'b01) & (icache_rcnt == `SRAM_ACCESS_CNT);
    assign icache_w2_read_finish = (icache_state == 2'b10) & (icache_rcnt == `SRAM_ACCESS_CNT);
    assign write_finish = w_state & (wcnt == `SRAM_ACCESS_CNT);

    // For w_state
    always @(posedge clk) begin
        if (rst) begin
            w_state <= 1'b0;
        end
        else if (all_idle && wen) begin
            w_state <= 1'b1;
        end
        else if (write_finish) begin
            w_state <= 1'b0;
        end
    end
    // For wcnt
    always @ (posedge clk) begin
        if (rst) begin
            wcnt <= 2'b00;
        end
        else if (all_idle && wen) begin
            wcnt <= 2'b00;
        end
        else if (w_state) begin
            if (wcnt == `SRAM_ACCESS_CNT) begin
                wcnt <= 2'b00;
            end
            else begin
                wcnt <= wcnt + 1;
            end
        end
    end

    // For r_state
    always @ (posedge clk) begin
        if (rst) begin
            r_state <= 1'b0;
        end
        else if (all_idle && ren && (~wen)) begin
            r_state <= 1'b1;
        end
        else if (read_finish) begin
            r_state <= 1'b0;
        end
    end
    // For rcnt
    always @ (posedge clk) begin
        if (rst) begin
            rcnt <= 2'b00;
        end
        else if (all_idle && ren && (~wen)) begin
            rcnt <= 2'b00;
        end
        else if (r_state) begin
            if (rcnt == `SRAM_ACCESS_CNT) begin
                rcnt <= 2'b00;
            end
            else begin
                rcnt <= rcnt + 1;
            end
        end
    end

    // For icache_state
    always @ (posedge clk) begin
        if (rst) begin
            icache_state <= 1'b0;
        end
        else if (all_idle && icache_ren && (~wen) && (~ren)) begin
            icache_state <= 2'b01;
        end
        else if (icache_w1_read_finish) begin
            icache_state <= 2'b10;
        end
        else if (icache_w2_read_finish) begin
            icache_state <= 2'b11;
        end
        else if (icache_state == 2'b11) begin
            icache_state <= 2'b00;
        end
    end
    // For icache_rcnt
    always @ (posedge clk) begin
        if (rst) begin
            icache_rcnt <= 2'b00;
        end
        else if (all_idle && icache_ren && (~wen) && (~ren)) begin
            icache_rcnt <= 2'b00;
        end
        else if (icache_state[1] ^ icache_state[0]) begin
            if (icache_rcnt == `SRAM_ACCESS_CNT) begin
                icache_rcnt <= 2'b00;
            end
            else begin
                icache_rcnt <= icache_rcnt + 1;
            end
        end 
    end

    // For sram

    // For addr, data_in, be and ce
    always @ (posedge clk) begin
        if (rst) begin
            addr_o <= 20'b0;
            be_o <= 4'b0;
            data_in_o <= 32'b0;
            ce_o <= 1'b1;
        end
        else if (all_idle) begin
            if (wen) begin
                addr_o <= waddr[21:2];
                be_o <= wbe;
                data_in_o <= wdata;
                ce_o <= 1'b0;
            end
            else if (ren) begin
                addr_o <= read_addr[21:2];
                be_o <= 4'b0;
                ce_o <= 1'b0;
            end
            else if (icache_ren) begin
                addr_o <= {icache_addr[21:3], 1'b0};
                be_o <= 4'b0;
                ce_o <= 1'b0;
            end
        end
        else if (icache_w1_read_finish) begin
            addr_o <= {icache_addr[21:3], 1'b1};
        end
        else if (write_finish || read_finish || icache_w2_read_finish) begin
            ce_o <= 1'b1;
        end
    end

    // For ren
    always @ (posedge clk) begin
        if (rst) begin
            ren_o <= 1'b1;
        end
        else if (all_idle && (~wen) && (ren || icache_ren)) begin
            ren_o <= 1'b0;
        end
        else if (icache_w2_read_finish || read_finish) begin
            ren_o <= 1'b1;
        end
    end 

    // For wen
    always @ (posedge clk) begin
        if (rst) begin
            wen_o <= 1'b1;
        end
        else if (all_idle && wen) begin
            wen_o <= 1'b0;
        end
        else if (write_finish) begin
            wen_o <= 1'b1;
        end
    end

    // For rdata
    assign rdata = data_out_i;

    // For icache_rdata
    always @ (posedge clk) begin
        if (rst) begin
            icache_rdata <= 32'b0;
        end
        else if (icache_w1_read_finish || icache_w2_read_finish) begin
            icache_rdata <= data_out_i;
        end
    end
    assign write_inst_W1 = (icache_state == 2'b10) & (icache_rcnt == 2'b00);
    assign write_inst_W2 = (icache_state == 2'b11);

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/02 15:17:52
// Design Name: 
// Module Name: ICache2
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
Direct-mapped cache
two words per line
Inner offset: 2 bits
Word offset: 1 bits
Index: `ICACHE_INDEX_LEN
Tag: 29 - `ICACHE_INDEX_LEN
state 1'b0: IDLE, 1'b1: READ
*/

module ICache2(
        input wire clk,
        input wire rst,

        // Face to CPU
        input wire [31:0] pc1,
        input wire [31:0] pc2,
        input wire imem_ren1,
        input wire imem_ren2,
        output wire [31:0] inst1,
        output wire [31:0] inst2,
        output wire imem_stall,

        // CPU write
        input wire dmem_wen,
        input wire [31:0] dmem_wdata,
        input wire [31:0] dmem_addr,
        input wire [3:0] be,

        // Face to mem
        output wire [31:0] mem_addr,
        output wire icache_ren,
        input wire [31:0] mem_rdata,
        input wire write_inst_W1,
        input wire write_inst_W2
    );

    // Cache lines
    (* ram_style = "block" *) reg [31:0] Word1 [`ICACHE_SIZE - 1:0];
    (* ram_style = "block" *) reg [31:0] Word2 [`ICACHE_SIZE - 1:0];

    // Cache tags
    (* ram_style = "block" *) reg [28 - `ICACHE_INDEX_LEN:0] tags [`ICACHE_SIZE - 1:0];

    // Valid bits
    reg v [`ICACHE_SIZE - 1:0];

    // Split the address
    wire [28 - `ICACHE_INDEX_LEN:0] tag1, tag2;
    wire [`ICACHE_INDEX_LEN - 1:0] index1, index2;
    wire words_offset1, words_offset2;

    assign tag1 = pc1[31:3 + `ICACHE_INDEX_LEN];
    assign index1 = pc1[`ICACHE_INDEX_LEN + 2:3];
    assign words_offset1 = pc1[2];

    assign tag2 = pc2[31:3 + `ICACHE_INDEX_LEN];
    assign index2 = pc2[`ICACHE_INDEX_LEN + 2:3];
    assign words_offset2 = pc2[2];

    // Judge whether the cache hit
    wire hit1, hit2;
    assign hit1 = (~|(tags[index1] ^ tag1)) & v[index1];
    assign hit2 = (~|(tags[index2] ^ tag2)) & v[index2];

    // Stall the CPU
    assign imem_stall = ((~hit1) & imem_ren1) | ((~hit2) & imem_ren2);

    // Get the inst from cache
    assign inst1 = (words_offset1)? Word2[index1]: Word1[index1];
    assign inst2 = (words_offset2)? Word2[index2]: Word1[index2];

    // For write data
    wire [28 - `ICACHE_INDEX_LEN:0] write_tag;
    wire [`ICACHE_INDEX_LEN - 1:0] write_index;
    wire write_words_offset;

    assign write_tag = dmem_addr[31:3 + `ICACHE_INDEX_LEN];
    assign write_index = dmem_addr[`ICACHE_INDEX_LEN + 2:3];
    assign write_words_offset = dmem_addr[2];

    wire write_hit;
    assign write_hit = (~|(tags[write_index] ^ write_tag)) & v[write_index];

    // state 1'b0: IDLE, 1'b1: READ 
    reg state;
    reg [31:0] read_pc;
    wire [28 - `ICACHE_INDEX_LEN:0] read_tag;
    wire [`ICACHE_INDEX_LEN - 1:0] read_index;

    assign read_tag = read_pc[31:3 + `ICACHE_INDEX_LEN];
    assign read_index = read_pc[`ICACHE_INDEX_LEN + 2:3];


    always @ (posedge clk) begin
        if (rst) begin
            state <= 1'b0;
            read_pc <= 32'h0;
        end
        else if ((~state) && imem_stall) begin
            state <= 1'b1;
            read_pc <= ((~hit1) & imem_ren1)? pc1: pc2;
        end
        else if (state && write_inst_W2) begin
            state <= 1'b0;
        end
    end

    // Assignment for v
    integer i;
    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < `ICACHE_SIZE; i = i + 1) begin
                v[i] <= 1'b0;
            end
        end
        else begin
            for (i = 0; i < `ICACHE_SIZE; i = i + 1) begin
                if (write_hit && dmem_wen && (~|(write_index ^ i[`ICACHE_INDEX_LEN - 1:0]))) begin
                    v[i] <= 1'b0;
                end
                else if (write_inst_W2 && (~|(read_index ^ i[`ICACHE_INDEX_LEN - 1:0]))) begin
                    v[i] <= 1'b1;
                end
            end
        end
    end

    // Assignment for tag
    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < `ICACHE_SIZE; i = i + 1) begin
                tags[i] <= 0;
            end
        end
        else if (write_inst_W2) begin
            tags[read_index] <= read_tag;
        end
    end

    // Assignment for Word1
    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < `ICACHE_SIZE; i = i + 1) begin
                Word1[i] <= 0;
            end
        end
        else if (write_inst_W1) begin
            Word1[read_index] <= mem_rdata;
        end
    end

    // Assignment for Word2
    always @ (posedge clk) begin
        if (rst) begin
            for (i = 0; i < `ICACHE_SIZE; i = i + 1) begin
                Word2[i] <= 0;
            end
        end
        else if (write_inst_W2) begin
            Word2[read_index] <= mem_rdata;
        end
    end

    // Assignment for mem_addr
    assign mem_addr = read_pc;
    assign icache_ren = state;

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/10 16:43:01
// Design Name: 
// Module Name: CtrlUnit
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

module CtrlUnit(
        input wire [31:0] inst,
        output wire [4:0] rs1,
        output wire [4:0] rs2,
        output wire [4:0] rd,
        output wire reg_wen,
        output wire [2:0] imm_sel,
        output wire [3:0] alu_op,
        output wire alu_srcA,
        output wire alu_srcB,
        output wire dmem_ren,
        output wire dmem_wen,
        output wire dmem_byte_address,
        output wire [3:0] cmp_op,
        output wire data_to_regfile,
        output wire use_rs1,
        output wire use_rs2,
        output wire is_branch_type
    );

    // Decode

    // alu_type
    wire is_addw;
    wire is_subw;
    wire is_addiw;
    wire is_lu12iw;
    wire is_slt;
    wire is_sltu;
    wire is_slti;
    wire is_sltui;
    wire is_pcaddu12i;
    wire is_andi;
    wire is_and;
    wire is_or;
    wire is_ori;
    wire is_xor;
    wire is_alu_type;

    // mul_type
    wire is_mulw;

    // shift_type
    wire is_sllw;
    wire is_srlw;
    wire is_sraw;
    wire is_srliw;
    wire is_slliw;
    wire is_sraiw;
    wire is_shift_type;

    // branch_type
    wire is_beq;
    wire is_bne;
    wire is_bge;
    wire is_blt;
    wire is_bgeu;
    wire is_bltu;
    wire is_b;
    wire is_bl;
    wire is_jirl;

    // mem_type
    wire is_stw;
    wire is_ldw;
    wire is_stb;
    wire is_ldb;
    wire is_mem_type;

    assign is_addw = ~|(inst[31:15] ^ 17'b0_0000_0000_0010_0000);
    assign is_subw = ~|(inst[31:15] ^ 17'b0_0000_0000_0010_0010);
    assign is_addiw = ~|(inst[31:22] ^ 10'b00_0000_1010);
    assign is_lu12iw = ~|(inst[31:25] ^ 7'b000_1010);
    assign is_slt = ~|(inst[31:15] ^ 17'b0_0000_0000_0010_0100);
    assign is_sltu = ~|(inst[31:15] ^ 17'b0_0000_0000_0010_0101);
    assign is_slti = ~|(inst[31:22] ^ 10'b00_0000_1000);
    assign is_sltui = ~|(inst[31:22] ^ 10'b00_0000_1001);
    assign is_pcaddu12i = ~|(inst[31:25] ^ 7'b000_1110);
    assign is_andi = ~|(inst[31:22] ^ 10'b00_0000_1101);
    assign is_ori = ~|(inst[31:22] ^ 10'b00_0000_1110);
    assign is_and = ~|(inst[31:15] ^ 17'b0_0000_0000_0010_1001);
    assign is_or  = ~|(inst[31:15] ^ 17'b0_0000_0000_0010_1010);
    assign is_xor = ~|(inst[31:15] ^ 17'b0_0000_0000_0010_1011);

    assign is_alu_type = is_addw | is_subw | is_addiw | is_lu12iw | is_slt | is_sltu | is_slti | is_sltui | is_pcaddu12i | is_andi | is_and | is_or | is_ori | is_xor;

    assign is_mulw = ~|(inst[31:15] ^ 17'b0_0000_0000_0011_1000);

    assign is_sllw = ~|(inst[31:15] ^ 17'b0_0000_0000_0010_1110);
    assign is_srlw = ~|(inst[31:15] ^ 17'b0_0000_0000_0010_1111);
    assign is_sraw = ~|(inst[31:15] ^ 17'b0_0000_0000_0011_0000);
    assign is_slliw = ~|(inst[31:15] ^ 17'b0_0000_0000_1000_0001);
    assign is_srliw = ~|(inst[31:15] ^ 17'b0_0000_0000_1000_1001);
    assign is_sraiw = ~|(inst[31:15] ^ 17'b0_0000_0000_1001_0001);

    assign is_shift_type = is_sllw | is_srlw | is_sraw | is_slliw | is_srliw | is_sraiw;

    assign is_beq = ~|(inst[31:26] ^ 6'b01_0110);
    assign is_bne = ~|(inst[31:26] ^ 6'b01_0111);
    assign is_blt = ~|(inst[31:26] ^ 6'b01_1000);
    assign is_bge = ~|(inst[31:26] ^ 6'b01_1001);
    assign is_bltu = ~|(inst[31:26] ^ 6'b01_1010);
    assign is_bgeu = ~|(inst[31:26] ^ 6'b01_1011);
    assign is_b = ~|(inst[31:26] ^ 6'b01_0100);
    assign is_bl = ~|(inst[31:26] ^ 6'b01_0101);
    assign is_jirl = ~|(inst[31:26] ^ 6'b01_0011);

    assign is_branch_type = is_beq | is_bne | is_blt | is_bge | is_bltu | is_bgeu | is_b | is_bl | is_jirl;

    assign is_stb = ~|(inst[31:22] ^ 10'b00_1010_0100);
    assign is_stw = ~|(inst[31:22] ^ 10'b00_1010_0110);
    assign is_ldb = ~|(inst[31:22] ^ 10'b00_1010_0000);
    assign is_ldw = ~|(inst[31:22] ^ 10'b00_1010_0010);

    assign is_mem_type = is_stb | is_stw | is_ldb | is_ldw;

    // Conctrol signal

    // register index
    assign rd  = (is_bl)? 5'd1 : inst[4:0];
    assign rs1 = (is_b | is_bl)? 5'b0: inst[9:5];
    assign rs2 = (is_stb | is_stw | is_beq | is_bne | is_blt | is_bge | is_bltu | is_bgeu) ? inst[4:0]: 
                 (is_addw | is_subw | is_slt | is_sltu | is_and | is_or | is_xor | is_mulw | is_sllw | is_srlw | is_sraw)? inst[14:10]: 5'b0;

    assign use_rs1 = (~(is_b | is_bl)) & (~(is_lu12iw | is_pcaddu12i));
    assign use_rs2 = (~(is_ldb | is_ldw)) & (~(is_b | is_bl | is_jirl)) & (~(is_slliw | is_sraiw | is_srliw)) & (~(is_addiw | is_lu12iw | is_slti | is_sltui | is_andi | is_ori | is_pcaddu12i));


    // register write enable
    assign reg_wen = (is_alu_type | is_shift_type | is_jirl | is_bl | is_ldw | is_ldb | is_mulw) & (rd != 5'b0);

    // immediate select
    assign imm_sel =    (`IMM_SI12 & {3{is_addiw | is_slti | is_sltui | is_ldb | is_ldw | is_stb | is_stw}}) |
                        (`IMM_UI12 & {3{is_andi | is_ori}}) |
                        (`IMM_OFFS16 & {3{is_beq | is_bne | is_blt | is_bge | is_bltu | is_bgeu | is_jirl}}) |
                        (`IMM_OFFS26 & {3{is_b | is_bl}}) |
                        (`IMM_UI5 & {3{is_slliw | is_srliw | is_sraiw}}) |
                        (`IMM_SI20 & {3{is_lu12iw | is_pcaddu12i}});
    // alu operation
    assign alu_op = (is_addw | is_addiw | is_pcaddu12i | is_mem_type)? `ALU_OP_ADD:
                    (is_mulw)? `ALU_OP_MUL:
                    (is_subw)? `ALU_OP_SUB:
                    (is_slt | is_slti)? `ALU_OP_SLT:
                    (is_sltu | is_sltui)? `ALU_OP_SLTU:
                    (is_and | is_andi)? `ALU_OP_AND:
                    (is_or | is_ori)? `ALU_OP_OR:
                    (is_xor)? `ALU_OP_XOR:
                    (is_sllw | is_slliw)? `ALU_OP_SLL:
                    (is_srlw | is_srliw)? `ALU_OP_SRL:
                    (is_sraw | is_sraiw)? `ALU_OP_SRA:
                    (is_bl | is_jirl)? `ALU_OP_PCADD4:
                                    `ALU_OP_RS2;

    // ALU srcA
    assign alu_srcA = (is_pcaddu12i | is_bl | is_jirl);

    // ALU srcB
    assign alu_srcB = (is_addiw | is_slti | is_sltui | is_andi | is_ori | is_lu12iw | is_pcaddu12i | is_slliw | is_srliw | is_sraiw | is_mem_type);
    
    // data memory control
    assign dmem_ren = is_ldw | is_ldb;
    assign dmem_wen = is_stw | is_stb;
    assign dmem_byte_address = is_stb | is_ldb;

    // branch control
    assign cmp_op = (is_beq)? `BJUnit_OP_BEQ:
                    (is_bne)? `BJUnit_OP_BNE:
                    (is_blt)? `BJUnit_OP_BLT:
                    (is_bge)? `BJUnit_OP_BGE:
                    (is_bltu)? `BJUnit_OP_BLTU:
                    (is_bgeu)? `BJUnit_OP_BGEU:
                    (is_b)? `BJUnit_OP_B:
                    (is_bl)? `BJUnit_OP_BL:
                    (is_jirl)? `BJUnit_OP_JIRL:
                              `BJUnit_OP_NOP;

    // Which data to regfile
    assign data_to_regfile = (is_ldw | is_ldb);


endmodule
